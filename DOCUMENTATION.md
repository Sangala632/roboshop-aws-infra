# RoboShop AWS Infrastructure — Documentation

Terraform-based Infrastructure as Code for deploying the RoboShop e-commerce microservices application on AWS.

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Repository Structure](#repository-structure)
- [Traffic Flow](#traffic-flow)
- [Networking](#networking)
- [Security Groups](#security-groups)
- [Infrastructure Patterns](#infrastructure-patterns)
- [Deployment Guide](#deployment-guide)
- [Configuration](#configuration)
- [DNS & Naming](#dns--naming)
- [Teardown](#teardown)
- [Cost Considerations](#cost-considerations)

---

## Architecture Overview

The RoboShop AWS infrastructure is a **production-style 3-tier architecture** with:

| Layer | Components |
|-------|------------|
| **Edge** | CloudFront CDN (geo-restriction, caching, HTTPS) |
| **Presentation** | Frontend ALB (public HTTPS) → Frontend EC2 (ASG) |
| **Application** | Backend ALB (internal) → Microservices (Catalogue, User, Cart, Shipping, Payment) |
| **Data** | MongoDB, Redis, MySQL, RabbitMQ |
| **Access** | Bastion host, OpenVPN |

All backend services and databases run in **private/database subnets**. Administrative access is via Bastion or OpenVPN.

---

## Repository Structure

Each numbered directory is an independent Terraform module, applied in sequence:

| Dir | Purpose |
|-----|---------|
| `00-VPC` | VPC, public/private/database subnets, NAT gateway, VPC peering |
| `10-SG` | Security groups and ingress rules for all components |
| `20-bastion` | Bastion EC2 for emergency SSH access |
| `30-VPN` | OpenVPN EC2 for secure developer access |
| `40-databases` | MongoDB, Redis, MySQL, RabbitMQ on EC2 + Route53 DNS |
| `50-backend-alb` | Internal ALB for microservice host-header routing |
| `60-acm` | ACM wildcard SSL certificate (DNS validation) |
| `60-catalogue` | Catalogue service — golden AMI + Launch Template + ASG |
| `70-frontend-alb` | Public HTTPS ALB for frontend |
| `80-components` | Backend microservices + frontend (reusable module) |
| `90-user` | Standalone User service (legacy/reference) |
| `91-cdn` | CloudFront + Route53 alias |

---

## Traffic Flow

```
Internet
   │
   ▼
CloudFront (CDN)  — geo-restriction, caching, HTTPS-only
   │
   ▼
Frontend ALB (public, HTTPS/443)
   │
   ▼
Frontend EC2 (ASG, private subnet)
   │
   ▼
Backend ALB (internal, HTTP/80)  — host-header routing
   │
   ├── Catalogue  (port 8080) → MongoDB
   ├── User       (port 8080) → MongoDB, Redis
   ├── Cart       (port 8080) → Redis, Catalogue
   ├── Shipping   (port 8080) → MySQL, Cart
   └── Payment    (port 8080) → RabbitMQ, User, Cart
         │
         ▼
   Databases (database subnet)
   ├── MongoDB    (27017)
   ├── Redis      (6379)
   ├── MySQL      (3306)
   └── RabbitMQ   (5672 / 15672)
```

---

## Networking

### Subnet Layout

| Tier | CIDR | Resources |
|------|------|-----------|
| Public | `10.0.1.0/24`, `10.0.2.0/24` | Frontend ALB, Bastion, VPN |
| Private | `10.0.11.0/24`, `10.0.12.0/24` | Microservice ASGs, Backend ALB |
| Database | `10.0.21.0/24`, `10.0.22.0/24` | MongoDB, Redis, MySQL, RabbitMQ |

### VPC Module

- Source: `github.com/Sangala632/terraform-aws-vpc`
- NAT Gateway for outbound traffic from private subnets
- VPC peering enabled for cross-environment connectivity

---

## Security Groups

| Source → Target | Ports |
|-----------------|-------|
| Internet → Frontend ALB | 80, 443 |
| Internet → VPN | 22, 443, 943, 1194 |
| Internet → Bastion | 22 |
| Frontend ALB → Frontend | 80 |
| Frontend / Cart / Shipping / Payment → Backend ALB | 80 |
| Backend ALB → Microservices | 8080 |
| VPN / Bastion → Microservices | 22, 8080 |
| Catalogue / User → MongoDB | 27017 |
| User / Cart → Redis | 6379 |
| Shipping → MySQL | 3306 |
| Payment → RabbitMQ | 5672 |

---

## Infrastructure Patterns

### Golden AMI Pattern (Microservices)

1. Launch base EC2 instance
2. Run bootstrap script to install and configure the app
3. Stop the instance
4. Snapshot into AMI
5. Terminate source instance
6. Create Launch Template from AMI
7. Deploy Auto Scaling Group using Launch Template

Benefits: fast deploys, consistent images, easy rollbacks.

### Auto Scaling

- **Target tracking:** 75% average CPU
- **Rolling refresh:** 50% minimum healthy percentage
- **Trigger:** Launch Template changes

### Databases (40-databases)

- MongoDB, Redis, MySQL, RabbitMQ on t3.micro EC2
- Provisioned via `terraform_data` with `bootstrap.sh`
- Route53 DNS records for each DB host
- MySQL uses IAM instance profile `ec2fetchssmparameter` for SSM parameters

### Components Module (80-components)

- Reusable module: `github.com/Sangala632/terraform-infra-aws`
- Deploys Catalogue, User, Cart, Shipping, Payment, Frontend
- Each component uses its own ALB listener rule and priority

---

## Deployment Guide

### Prerequisites

- Terraform >= 1.5
- AWS CLI configured (`aws configure`)
- Route53 hosted zone
- IAM role `EC2FORTERRAFORMADMIN` (Bastion)
- IAM instance profile `ec2fetchssmparameter` (MySQL/SSM)

### Deployment Order

Layers must be applied in **numerical order** (outputs passed via SSM Parameter Store):

```bash
cd 00-VPC          && terraform init && terraform apply
cd ../10-SG        && terraform init && terraform apply
cd ../20-bastion   && terraform init && terraform apply
cd ../30-VPN       && terraform init && terraform apply
cd ../40-databases && terraform init && terraform apply
cd ../50-backend-alb && terraform init && terraform apply
cd ../60-acm       && terraform init && terraform apply
cd ../80-components && terraform init && terraform apply  # 10–15 min (golden AMI build)
cd ../70-frontend-alb && terraform init && terraform apply
cd ../91-cdn       && terraform init && terraform apply
```

> **Note:** `80-components` builds golden AMIs per microservice — this is the longest step.

---

## Configuration

### Common Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `project` | `roboshop` | Resource name prefix |
| `environment` | `dev` | dev / staging / prod |
| `zone_name` | — | Route53 hosted zone domain |
| `zone_id` | — | Route53 hosted zone ID |

### Components (80-components)

```hcl
variable "components" {
  default = {
    catalogue = { rule_priority = 10 }
    user      = { rule_priority = 20 }
    cart      = { rule_priority = 30 }
    shipping  = { rule_priority = 40 }
    payment   = { rule_priority = 50 }
    frontend  = { rule_priority = 10 }
  }
}
```

### CDN (CloudFront)

- Default behaviour: caching disabled (dynamic content)
- `/media/*`: caching enabled
- HTTPS-only viewer protocol
- Geo-restriction: US, CA, GB, DE, FR, IN, AU
- Price class: PriceClass_200

---

## DNS & Naming

| Record | Resolves To |
|--------|-------------|
| `roboshops.<zone_name>` | CloudFront distribution |
| `<env>.<zone_name>` | Frontend ALB |
| `*.backend-<env>.<zone_name>` | Backend ALB |
| `catalogue.backend-<env>.<zone_name>` | Catalogue service |
| `mongodb-<env>.<zone_name>` | MongoDB private IP |
| `redis-<env>.<zone_name>` | Redis private IP |
| `mysql-<env>.<zone_name>` | MySQL private IP |
| `rabbitmq-<env>.<zone_name>` | RabbitMQ private IP |

---

## Teardown

Destroy in **reverse order**:

```bash
cd 91-cdn            && terraform destroy
cd 70-frontend-alb   && terraform destroy
cd 80-components     && terraform destroy
cd 60-acm            && terraform destroy
cd 50-backend-alb    && terraform destroy
cd 40-databases      && terraform destroy
cd 30-VPN            && terraform destroy
cd 20-bastion        && terraform destroy
cd 10-SG             && terraform destroy
cd 00-VPC            && terraform destroy
```

> **CloudFront:** Disable the distribution in the AWS console first if destroy fails, then retry.

---

## Cost Considerations

Resources that incur charges when idle:

- NAT Gateway (~$30/month)
- Application Load Balancers (x2)
- EC2 (databases, bastion, VPN)
- CloudFront (requests + data transfer)

Microservices are managed by ASGs and can scale to zero when not in use.

---

## Remote Modules

| Module | Source |
|--------|--------|
| VPC | `github.com/Sangala632/terraform-aws-vpc` |
| Security Groups | `github.com/daws-84s/terraform-aws-securitygroup` |
| Microservice (ASG + ALB) | `github.com/Sangala632/terraform-infra-aws` |
| ALB | `terraform-aws-modules/alb/aws` v9.16.0 |
