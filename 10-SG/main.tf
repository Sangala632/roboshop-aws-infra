module "frontend" {
    source = "git::https://github.com/Sangala632/terraform-aws-securitygroups.git?ref=main"  
    project= var.project
    environment = var.environment
    vpc_id = local.vpc_id
    sg_name = var.frontend_sg_name
    sg_description = var.frontend_sg_description
}

module "bastion" {
    source = "git::https://github.com/Sangala632/terraform-aws-securitygroups.git?ref=main"  
    project= var.project
    environment = var.environment
    vpc_id = local.vpc_id
    sg_name = var.bastion_sg_name
    sg_description = var.bastion_sg_description
}

module "backend_alb" {
    source = "git::https://github.com/Sangala632/terraform-aws-securitygroups.git?ref=main"  
    project= var.project
    environment = var.environment
    vpc_id = local.vpc_id
    sg_name = var.backend_alb_sg_name
    sg_description = var.backend_alb_sg_description
}

#bation connections accepting from my laptop
resource "aws_security_group_rule" "bastion_laptop" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.bastion.sg_id
}

#backend-alb connections accepting from my bastion host on port no 80
resource "aws_security_group_rule" "backend_alb_bastion" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  source_security_group_id = module.bastion.sg_id
  security_group_id = module.backend_alb.sg_id
}