data "aws_ssm_parameter" "vpc_id" {
  name = "/${var.project}/${var.environment}/var_id"
}