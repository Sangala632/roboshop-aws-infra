#database security group ids
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

resource "aws_ssm_parameter" "mysql_sg_id" {
  name  = "/${var.project}/${var.environment}/mysql-sg-id"
  type  = "String"
  value = module.mysql.sg_id
}

resource "aws_ssm_parameter" "rabbitmq_sg_id" {
  name  = "/${var.project}/${var.environment}/rabbitmq-sg-id"
  type  = "String"
  value = module.rabbitmq.sg_id
}

#components(app) security group ids
resource "aws_ssm_parameter" "catalogue_sg_id" {
  name  = "/${var.project}/${var.environment}/catalogue-sg-id"
  type  = "String"
  value = module.catalogue.sg_id
}

resource "aws_ssm_parameter" "user_sg_id" {
  name  = "/${var.project}/${var.environment}/user-sg-id"
  type  = "String"
  value = module.user.sg_id
}

resource "aws_ssm_parameter" "cart_sg_id" {
  name  = "/${var.project}/${var.environment}/cart-sg-id"
  type  = "String"
  value = module.cart.sg_id
}

resource "aws_ssm_parameter" "shipping_sg_id" {
  name  = "/${var.project}/${var.environment}/shipping-sg-id"
  type  = "String"
  value = module.shipping.sg_id
}

resource "aws_ssm_parameter" "payment_sg_id" {
  name  = "/${var.project}/${var.environment}/payment-sg-id"
  type  = "String"
  value = module.payment.sg_id
}

resource "aws_ssm_parameter" "frontend_sg_id" {
  name  = "/${var.project}/${var.environment}/frontend-sg-id"
  type  = "String"
  value = module.frontend.sg_id
}

resource "aws_ssm_parameter" "backend_alb_sg_id" {
  name  = "/${var.project}/${var.environment}/backend_alb_sg_id"
  type  = "String"
  value = module.backend_alb.sg_id
}

resource "aws_ssm_parameter" "frontend_sg_id" {
  name  = "/${var.project}/${var.environment}/frontend-sg-id"
  type  = "String"
  value = module.frontend.sg_id
}

resource "aws_ssm_parameter" "frontend_alb_sg_id" {
  name  = "/${var.project}/${var.environment}/frontend-alb-sg-id"
  type  = "String"
  value = module.frontend_alb.sg_id
}

resource "aws_ssm_parameter" "bastion_sg_id" {
  name  = "/${var.project}/${var.environment}/bastion-sg-id"
  type  = "String"
  value = module.bastion.sg_id
}

resource "aws_ssm_parameter" "vpn_sg_id" {
  name  = "/${var.project}/${var.environment}/vpn-sg-id"
  type  = "String"
  value = module.vpn.sg_id
}


