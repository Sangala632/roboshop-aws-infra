module "user" {
    source = "../../terraform-infra-aws"
    component = "user"
    rule_priority = 20
}