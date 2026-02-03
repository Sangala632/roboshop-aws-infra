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

module "mongo_db" {
    source = "git::https://github.com/Sangala632/terraform-aws-securitygroups.git?ref=main"  
    project= var.project
    environment = var.environment

    vpc_id = local.vpc_id
    sg_name = "mongo-db"
    sg_description = "for mongodb "
}

module "redis" {
    source = "git::https://github.com/Sangala632/terraform-aws-securitygroups.git?ref=main"  
    project= var.project
    environment = var.environment

    vpc_id = local.vpc_id
    sg_name = "redis"
    sg_description = "for redis "
}
module "my_sql" {
    source = "git::https://github.com/Sangala632/terraform-aws-securitygroups.git?ref=main"  
    project= var.project
    environment = var.environment

    vpc_id = local.vpc_id
    sg_name = "my-sql"
    sg_description = "for my-sql "
}
module "rabbit_mq" {
    source = "git::https://github.com/Sangala632/terraform-aws-securitygroups.git?ref=main"  
    project= var.project
    environment = var.environment

    vpc_id = local.vpc_id
    sg_name = "rabbit_mq"
    sg_description = "for rabbit_mq "
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

resource "aws_security_group_rule" "mongodb_vpn_ssh" {
  count             = length(var.mongodb_ports_vpn)
  type              = "ingress"
  from_port         = var.mongodb_ports_vpn[count.index]
  to_port           = var.mongodb_ports_vpn[count.index]
  protocol          = "tcp"
  source_security_group_id = module.vpn.sg_id
  security_group_id = module.mongo_db.sg_id
}

resource "aws_security_group_rule" "redis_vpn_ssh" {
  count             = length(var.redis_ports_vpn)
  type              = "ingress"
  from_port         = var.redis_ports_vpn[count.index]
  to_port           = var.redis_ports_vpn[count.index]
  protocol          = "tcp"
  source_security_group_id = module.vpn.sg_id
  security_group_id = module.redis.sg_id
}

resource "aws_security_group_rule" "my_sql_vpn_ssh" {
  count             = length(var.my_sql_ports_vpn)
  type              = "ingress"
  from_port         = var.my_sql_ports_vpn[count.index]
  to_port           = var.my_sql_ports_vpn[count.index]
  protocol          = "tcp"
  source_security_group_id = module.vpn.sg_id
  security_group_id = module.my_sql.sg_id
}
resource "aws_security_group_rule" "rabbit_mq_vpn_ssh" {
  count             = length(var.rabbit_mq_ports_vpn)
  type              = "ingress"
  from_port         = var.rabbit_mq_ports_vpn[count.index]
  to_port           = var.rabbit_mq_ports_vpn[count.index]
  protocol          = "tcp"
  source_security_group_id = module.vpn.sg_id
  security_group_id = module.rabbit_mq.sg_id
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
