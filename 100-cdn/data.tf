data "aws_cloudfront_cache_policy" "cachingOptimised" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "cachingDisabled" {
  name = "Managed-CachingDisabled"
}

data "aws_ssm_parameter" "frontend_alb_certificate_arn" {
  name = "/${var.project}/${var.environment}/frontend_alb_certificate_arn"
}

data "aws_ssm_parameter" "frontend_alb_dns" {
  name = "/${var.project}/${var.environment}/frontend_alb_dns"
}