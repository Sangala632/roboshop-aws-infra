resource "aws_ssm_parameter" "frontend_sg_id" {
  name  = "/${var.project}/${var.environment}/frontend-sg-id"
  type  = "String"
  value = module.frontend.sg_id
}

resource "aws_ssm_parameter" "bastion_sg_id" {
  name  = "/${var.project}/${var.environment}/bastion-sg-id"
  type  = "String"
  value = module.bastion.sg_id
}

resource "aws_ssm_parameter" "backend_alb_sg_id" {
  name  = "/${var.project}/${var.environment}/backend-alb-sg-id"
  type  = "String"
  value = module.backend_alb.sg_id
}

resource "aws_ssm_parameter" "vpn_sg_id" {
  name  = "/${var.project}/${var.environment}/vpn-sg-id"
  type  = "String"
  value = module.vpn.sg_id
}

resource "aws_ssm_parameter" "mongodb_sg_id" {
  name  = "/${var.project}/${var.environment}/mongodb-sg-id"
  type  = "String"
  value = module.mongo_db.sg_id
}

resource "aws_ssm_parameter" "redis_sg_id" {
  name  = "/${var.project}/${var.environment}/redis-sg-id"
  type  = "String"
  value = module.redis.sg_id
}

resource "aws_ssm_parameter" "my_sql_sg_id" {
  name  = "/${var.project}/${var.environment}/mysql-sg-id"
  type  = "String"
  value = module.my_sql.sg_id
}

resource "aws_ssm_parameter" "rabbit_mq_sg_id" {
  name  = "/${var.project}/${var.environment}/rabbitmq-sg-id"
  type  = "String"
  value = module.rabbit_mq.sg_id
}