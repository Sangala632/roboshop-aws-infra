locals {
    common_name_suffix = "${var.project}-${var.environment}" # roboshop-dev
    common_tags = {
        project = "roboshop"
        environment = "dev"
        terraform = true
    }

}