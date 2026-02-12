module "components" {
  for_each =var.components
  #source = "../../terraform-infra-aws" local path
  source = "git::https://github.com/Sangala632/terraform-infra-aws.git?ref=main" # remote path
  component = each.key
  rule_priority = each.value.rule_priority  
}