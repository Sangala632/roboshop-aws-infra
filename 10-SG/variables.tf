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

/* variable "backend_alb_sg_name" {
    default ="backend-alb"
}

variable "backend_alb_sg_description" {
    default ="created backend-alb security group"
} */

variable "mongodb_ports_vpn" {
    default = [22, 27017] # just keep as mongodb_ports
}

variable "redis_ports_vpn" {
    default = [22, 6379] # just keep as redis_ports
}

variable "mysql_ports_vpn" {
    default = [22, 3306] # just keep as mysql_ports
}

variable "rabbitmq_ports_vpn" {
    default = [22, 5672] # just keep as rabbitmq_ports
}




