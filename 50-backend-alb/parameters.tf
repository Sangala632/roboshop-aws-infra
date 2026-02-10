resource "aws_ssm_parameter" "backend_alb_listener_arn" {
  name      = "/${var.project}/${var.environment}/backend-alb-listener-arn"
  type      = "String"
  value     = aws_lb_listener.backend_alb.arn
  overwrite = true
}