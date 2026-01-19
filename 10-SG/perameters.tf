resource "aws_ssm_parameter" "frontend_sg_id" {
  name  = "/${var.project}/${var.environment}/frontend-sg-id"
  type  = "String"
  value = module.frontend.sg_id
}