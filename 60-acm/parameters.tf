resource "aws_ssm_parameter" "acm_arn" {
  name  = "/${var.project}/${var.environment}/acn_arn"
  type  = "String"
  value = aws_acm_certificate.hellodevsecops.arn
}