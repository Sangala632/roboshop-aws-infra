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

module "vpn" {
    source = "git::https://github.com/Sangala632/terraform-aws-securitygroups.git?ref=main"  
    project= var.project
    environment = var.environment

    vpc_id = local.vpc_id
    sg_name = "vpn"
    sg_description = "for VPN "
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

resource "aws_security_group_rule" "backend_alb_vpn" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  source_security_group_id = module.vpn.sg_id
  security_group_id = module.backend_alb.sg_id
}
#VPN ports----> 22, 443,  1194, 943
resource "aws_security_group_rule" "vpn_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.vpn.sg_id
}

resource "aws_security_group_rule" "vpn_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.vpn.sg_id
}

resource "aws_security_group_rule" "vpn_1194" {
  type              = "ingress"
  from_port         = 1194
  to_port           = 1194
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.vpn.sg_id
}

resource "aws_security_group_rule" "vpn_943" {
  type              = "ingress"
  from_port         = 943
  to_port           = 943
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.vpn.sg_id
}
