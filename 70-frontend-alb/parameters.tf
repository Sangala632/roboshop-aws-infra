resource "aws_ssm_parameter" "frontend_alb_listener_arn" {
  name  = "/${var.project}/${var.environment}/frontend_alb_listener_arn"
  type  = "String"
  value = aws_lb_listener.frontend_alb.arn
}

resource "aws_ssm_parameter" "frontend_alb_dns" {
  name  = "/${var.project}/${var.environment}/frontend_alb_dns"
  type  = "String"
  value = module.frontend_alb.dns_name
}