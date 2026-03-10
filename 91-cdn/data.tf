data "aws_cloudfront_cache_policy" "cacheEnable" {
  name = "Managed-CachingOptimized"  # Replace with the name of your cache policy
}

data "aws_cloudfront_cache_policy" "cacheDisable" {
  name = "Managed-CachingDisabled"  # Replace with the name of your cache policy
}

data "aws_ssm_parameter" "acm_certificate_arn" {
  name = "/${var.project}/${var.environment}/acm_certificate_arn"
}

data "aws_ssm_parameter" "frontend_alb_dns_name" {
  name = "/${var.project}/${var.environment}/frontend_alb_dns_name"
}