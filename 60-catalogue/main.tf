#  creating target group for catalogue service.
resource "aws_lb_target_group" "catalouge" {
  name     = "${var.project}-${var.environment}-catalouge"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = local.vpc_id
  health_check {
    healthy_threshold   = 2
    interval            = 5
    matcher             = "200-299"
    path                = "/health"
    port                = 8080
    timeout             = 2
    unhealthy_threshold = 3
  }
}

#  creating security group for catalogue service.
resource "aws_instance" "catalogue" {
  ami                    = local.ami_id
  instance_type          = "t3.micro"
  vpc_security_group_ids = [local.catalogue_sg_id]
  subnet_id              = local.private_subnet_id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}-catalogue"
    }
  )
}

#  using terraform data resource to execute the script on the instance which we created.
resource "terraform_data" "catalogue" {
  triggers_replace = [
    aws_instance.catalogue.id
  ]
  provisioner "file" {
    source      = "catalogue.sh"
    destination = "/tmp/catalogue.sh"
  }
  # make sure you have aws configure in your laptop and have access to the aws account where you are creating the infrastructure
  connection {
    type     = "ssh"
    user     = "ec2-user"
    password = "DevOps321"
    host     = aws_instance.catalogue.private_ip
  }
  # we are executing the script on the instance which we created, and this script will install the catalogue service on the instance.
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/catalogue.sh",
      "sudo sh /tmp/catalogue.sh catalogue ${var.environment}"
    ]
  }
}

#catalogue instance state is stopped because we will create AMI from this instance and then we will use this AMI in ASG and whenever ASG will create new instance it will use this AMI and all the configuration will be same as the instance which we created and then created AMI from it.
resource "aws_ec2_instance_state" "catalogue" {
  instance_id = aws_instance.catalogue.id
  state       = "stopped"
  depends_on = [terraform_data.catalogue]
}

# taking AMI ID from the instance.
resource "aws_ami_from_instance" "catalogue" {
  name               = "${var.project}-${var.environment}-catalogue"
  source_instance_id = aws_instance.catalogue.id
  depends_on = [aws_ec2_instance_state.catalogue]
  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}-catalogue"
    }
  )
}

#  terminating the instance after TAKING THE AMI ID.
resource "terraform_data" "catalogue_delete" {
  triggers_replace = [
    aws_instance.catalogue.id
  ]
  
  # make sure you have aws configure in your laptop and have access to the aws account where you are creating the infrastructure
  provisioner "local-exec" {
    command ="aws ec2 terminate-instances --instance-ids ${aws_instance.catalogue.id}"
  }
  depends_on = [aws_ami_from_instance.catalogue]
}

# creating launch template.
resource "aws_launch_template" "catalogue" {
  name = "${var.project}-${var.environment}-catalogue"
  image_id = aws_ami_from_instance.catalogue.id
  instance_initiated_shutdown_behavior = "terminate"
  update_default_version = true # each time u update ,new version will be default
  instance_type = "t3.micro"
  vpc_security_group_ids = [local.catalogue.id]

  #instance tags created by ASG
  tag_specifications {
    resource_type = "instance"

    tags = merge(
      local.common_tags,
      {
        Name = "${var.project}-${var.environment}-catalogue"
      }
    )
  }

#volume tags created by ASG
  tag_specifications {
    resource_type = "volume"

    tags = merge(
      local.common_tags,
      {
        Name = "${var.project}-${var.environment}-catalogue"
      }
    )
  }
  #lunch template tags
  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}-catalogue"
    }
  )
}

# creating ASG for catalogue service.
resource "aws_autoscaling_group" "catalogue" {
  name                      = "${var.project}-${var.environment}-catalogue"
  max_size                  = 5
  min_size                  = 1
  health_check_grace_period = 90
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = true
  target_group_arns         = [aws_lb_target_group.catalogue.arn]
  vpc_zone_identifier       = [local.private_subnet_ids]

  launch_template {
    id      = aws_launch_template.catalogue.id
    version = aws_launch_template.catalogue.latest_version
  } 

  dynamic "tag" {
      for_each     = merge(
        {
          Name ="${var.project}-${var.environment}-catalogue"
        }
      )
      content {
        key                 = tag.key
        value               = tag.value
        propagate_at_launch = true
      }
  }
  #  instance refresh to update the instances .
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    } 
    triggers = ["launch_template"] 
  }

  timeouts {
    delete = "15m"
  }

}

# creating scaling policy for catalogue service.
resource "aws_autoscaling_policy" "catalogue" {
  name                   = "${var.project}-${var.environment}-catalogue"
  autoscaling_group_name = aws_autoscaling_group.catalogue.name
  policy_type            = "TargetTrackingScaling"
   target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 75.0
  }
}

# creating listener rule for catalogue service.
resource "aws_lb_listener_rule" "host_based_routing" {
  listener_arn = local.backend_alb_listener_arn
  priority     = 10

  action {
    type = "forward"
      target_group_arn = aws_lb_target_group.catalogue.arn
      }
  condition {
    host_header {
      values = ["catalogue.backend-${var.environment}.${var.zone_name}"]
    }
  }
}

