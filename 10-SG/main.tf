module "frontend" {
    source = "git::https://github.com/Sangala632/terraform-aws-securitygroups.git?ref=main"  
    project= var.project
    environment = var.environment
    vpc_id = local.vpc_id
    sg_name = var.frontend_sg_name
    sg_description = var.frontend_sg_description
}