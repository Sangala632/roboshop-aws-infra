module "components" {
  for_each =var.components
  source = "https://github.com/Sangala632/terraform-infra-aws.git?ref=main"
  component = each.key
  rule_priority = each.value.rule_priority  
}