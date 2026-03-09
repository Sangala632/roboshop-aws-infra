locals {
    frontend_alb_certificate_arn = data.aws_ssm_parameter.frontend_alb_certificate_arn.value 
    frontend_alb_dns = data.aws_ssm_parameter.frontend_alb_dns.value
    common_tags = {
        Project = var.project
        Environment = var.environment
        Terraform = "true"
    }
}