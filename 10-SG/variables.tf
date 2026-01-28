variable "project" {
    default = "roboshop"
}

variable "environment" {
    default ="dev"
}

variable "frontend_sg_name" {
    default ="frontend"
}

variable "frontend_sg_description" {
    default ="created frontend security group"
}

variable "bastion_sg_name" {
    default ="bastion"
}

variable "bastion_sg_description" {
    default ="created bastion security group"
}

variable "backend_alb_sg_name" {
    default ="backend_alb"
}

variable "backend_alb_sg_description" {
    default ="created backend_alb security group"
}




