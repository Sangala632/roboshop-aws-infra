locals {
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    private_subnet_id   = split(",", data.aws_ssm_parameter.private_subnet_ids.value) [0]
    private_subnet_ids  = split(",", data.aws_ssm_parameter.private_subnet_ids.value) 
    ami_id              = data.aws_ami.Roboshop-project.id
    catalogue_sg_id     = data.aws_ssm_parameter.catalogue_sg_id.value

    common_tags = {
        project = "roboshop"
        environment = "dev"
        terraform = true
    }

}