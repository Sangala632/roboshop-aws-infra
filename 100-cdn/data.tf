
data "aws_cloudfront_cache_policy" "cachingOptimised" {
  name = "Managed-CachingOptimized"  # Replace with the name of your cache policy
}

data "aws_cloudfront_cache_policy" "cachingDisabled" {
  name = "Managed-CachingDisabled"  # Replace with the name of your cache policy
}

data "aws_ssm_parameter" "frontend_alb_certificate_arn" {
  name = "/${var.project}/${var.environment}/frontend_alb_certificate_arn"
}