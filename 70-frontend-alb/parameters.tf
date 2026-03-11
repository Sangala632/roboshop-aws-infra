resource "aws_ssm_parameter" "frontend_alb_listener_arn" {
  name  = "/${var.project}/${var.environment}/frontend_alb_listener_arn"
  type  = "String"
  value = aws_lb_listener.frontend_alb.arn
}

resource "aws_ssm_parameter" "frontend_alb_dns_name" {
  name  = "/${var.project}/${var.environment}/frontend_alb_dns_name"
  type  = "String"
  value = aws_route53_record.frontend_alb.fqdn
}