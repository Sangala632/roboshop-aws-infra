locals {
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    public_subnet_ids = split(",", data.aws_ssm_parameter.public_subnet_ids.value)
    frontend_alb_sg_id = data.aws_ssm_parameter.frontend_alb_sg_id.value
    acm_ceretificate_arn = data.aws_ssm_parameter.arn.value


    common_tags = {
        project = "roboshop"
        environment = "dev"
        terraform = true
    }

}