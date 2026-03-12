# Roboshop AWS Infrastructure

Terraform-based Infrastructure as Code for deploying the [RoboShop](https://github.com/roboshop-devops) e-commerce microservices application on AWS. The project provisions a full production-grade environment including networking, security, databases, load balancers, auto-scaling compute, SSL/TLS, and a CloudFront CDN.

<h1>Roboshop VM Architecture</h1>

![Architecture Diagram](roboshop-infra-dev.drawio.svg)

---

## Architecture Overview

Traffic flows through the following layers:

```
Internet
   │
   ▼
CloudFront (CDN)  ──  geo-restriction, caching, HTTPS-only
   │
   ▼
Frontend ALB (public, HTTPS/443)
   │
   ▼
Frontend EC2 (ASG, private subnet)
   │
   ▼
Backend ALB (internal, HTTP/80)  ──  host-header routing per microservice
   │
   ├── Catalogue  (port 8080, MongoDB)
   ├── User       (port 8080, MongoDB + Redis)
   ├── Cart       (port 8080, Redis + Catalogue)
   ├── Shipping   (port 8080, MySQL)
   └── Payment    (port 8080, RabbitMQ + User + Cart)
         │
         ▼
   Databases (isolated database subnet)
   ├── MongoDB    (port 27017)
   ├── Redis      (port 6379)
   ├── MySQL      (port 3306)
   └── RabbitMQ   (port 5672 / 15672)
```

All backend services and databases are in **private/database subnets**. Administrative access is via a **Bastion host** or **OpenVPN** in the public subnet.

---

## Repository Structure

Each numbered directory is an independent Terraform module/layer, applied in sequence:

| Directory | Purpose |
|---|---|
| `00-VPC` | VPC, public/private/database subnets, NAT gateway, VPC peering |
| `10-SG` | Security groups and ingress rules for every component |
| `20-bastion` | Bastion EC2 instance for emergency SSH access |
| `30-VPN` | OpenVPN EC2 instance for secure developer access |
| `40-databases` | MongoDB, Redis, MySQL, RabbitMQ on EC2 + Route53 DNS |
| `50-backend-alb` | Internal Application Load Balancer for microservices |
| `60-acm` | ACM wildcard SSL certificate with DNS validation |
| `60-catalogue` | Catalogue service — golden AMI + Launch Template + ASG |
| `70-frontend-alb` | Public-facing HTTPS ALB for the frontend |
| `80-components` | All 5 backend microservices + frontend via reusable module |
| `90-user` | Standalone user service (legacy/reference) |
| `91-cdn` | CloudFront distribution + Route53 alias |

---

## Infrastructure Design Patterns

### Golden AMI Pattern (for microservices)

Each microservice follows this immutable infrastructure pattern:

1. Launch a base EC2 instance
2. Run the bootstrap script to install and configure the application
3. Stop the instance
4. Snapshot it into an AMI
5. Terminate the source instance
6. Create a Launch Template from the AMI
7. Deploy an Auto Scaling Group using the Launch Template

This means deployments are fast, consistent, and rollback-friendly — a new AMI version triggers a rolling ASG refresh.

### Auto Scaling

All microservices use **Target Tracking Scaling** with a 75% average CPU utilization target. Rolling instance refresh is configured with a 50% minimum healthy percentage and is triggered automatically on Launch Template changes.

### Networking — Three-Tier Subnet Layout

| Tier | CIDR Range | Resources |
|---|---|---|
| Public | `10.0.1.0/24`, `10.0.2.0/24` | Frontend ALB, Bastion, VPN |
| Private | `10.0.11.0/24`, `10.0.12.0/24` | Microservice ASGs, Backend ALB |
| Database | `10.0.21.0/24`, `10.0.22.0/24` | MongoDB, Redis, MySQL, RabbitMQ |

VPC peering is enabled for cross-environment connectivity.

### Security Group Rules Summary

| Source → Target | Ports Allowed |
|---|---|
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

### CDN Configuration

CloudFront sits in front of the Frontend ALB and is configured with:

- **Default cache behaviour**: caching disabled (suitable for dynamic app content)
- **`/media/*` path**: caching enabled
- **HTTPS-only** viewer protocol
- **Geo-restriction**: US, CA, GB, DE, FR, IN, AU
- **Price class**: PriceClass_200 (North America, Europe, Asia Pacific)
- **ACM certificate** for TLS termination at the edge

---

## Prerequisites

- Terraform >= 1.5
- AWS CLI configured (`aws configure`)
- An existing Route53 hosted zone
- An IAM role named `EC2FORTERRAFORMADMIN` for the Bastion instance
- An IAM instance profile named `ec2fetchssmparameter` for MySQL (SSM access)

---

## Deployment Order

Layers must be applied **in numerical order** because each layer reads outputs from the previous ones via SSM Parameter Store.

```bash
# 1. VPC
cd 00-VPC && terraform init && terraform apply

# 2. Security Groups
cd ../10-SG && terraform init && terraform apply

# 3. Bastion & VPN (can be done in parallel)
cd ../20-bastion && terraform init && terraform apply
cd ../30-VPN     && terraform init && terraform apply

# 4. Databases
cd ../40-databases && terraform init && terraform apply

# 5. Backend ALB
cd ../50-backend-alb && terraform init && terraform apply

# 6. ACM Certificate
cd ../60-acm && terraform init && terraform apply

# 7. All microservices (golden AMI build — takes 10–15 min)
cd ../80-components && terraform init && terraform apply

# 8. Frontend ALB
cd ../70-frontend-alb && terraform init && terraform apply

# 9. CloudFront CDN
cd ../91-cdn && terraform init && terraform apply
```

> **Note:** The `80-components` step builds golden AMIs. Each microservice boots, gets bootstrapped, is snapshotted, and the source instance is terminated automatically. This is the longest step.

---

## Configuration

### Common Variables

Each layer accepts these shared variables:

| Variable | Default | Description |
|---|---|---|
| `project` | `roboshop` | Project name prefix for all resource names |
| `environment` | `dev` | Environment (dev / staging / prod) |
| `zone_name` | — | Route53 hosted zone domain name |
| `zone_id` | — | Route53 hosted zone ID |

These are typically set via `parameters.tf` (SSM) or a `terraform.tfvars` file.

### Microservice Components (80-components)

The `components` variable in `80-components/variables.tf` controls which services are deployed and their ALB listener rule priorities:

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

---

## Remote Modules Used

| Module | Source |
|---|---|
| VPC | `github.com/Sangala632/terraform-aws-vpc` |
| Security Groups | `github.com/daws-84s/terraform-aws-securitygroup` |
| Microservice (ASG + ALB) | `github.com/Sangala632/terraform-infra-aws` |
| ALB | `terraform-aws-modules/alb/aws` v9.16.0 |

---

## DNS Naming Convention

| Record | Resolves To |
|---|---|
| `roboshops.<zone_name>` | CloudFront distribution |
| `<env>.<zone_name>` | Frontend ALB |
| `*.backend-<env>.<zone_name>` | Backend ALB (wildcard) |
| `catalogue.backend-<env>.<zone_name>` | Catalogue service |
| `mongodb-<env>.<zone_name>` | MongoDB EC2 private IP |
| `redis-<env>.<zone_name>` | Redis EC2 private IP |
| `mysql-<env>.<zone_name>` | MySQL EC2 private IP |
| `rabbitmq-<env>.<zone_name>` | RabbitMQ EC2 private IP |

---

## Teardown

Destroy in **reverse order** to avoid dependency errors:

```bash
cd 91-cdn       && terraform destroy
cd 70-frontend-alb && terraform destroy
cd 80-components && terraform destroy
cd 60-acm       && terraform destroy
cd 50-backend-alb && terraform destroy
cd 40-databases  && terraform destroy
cd 30-VPN       && terraform destroy
cd 20-bastion   && terraform destroy
cd 10-SG        && terraform destroy
cd 00-VPC       && terraform destroy
```

> **CloudFront note:** CloudFront distributions must be disabled before they can be deleted. If `terraform destroy` fails on the CDN layer, disable the distribution in the AWS console first, wait for `Status: Deployed`, then re-run destroy.

---

## Cost Considerations

The following resources incur charges even when idle. Shut them down when not in use:

- **NAT Gateway** (~$30/month)
- **Application Load Balancers** (x2 — backend + frontend)
- **EC2 instances** (databases + bastion + VPN)
- **CloudFront** (charged on requests and data transfer)

EC2 instances for microservices are managed by ASGs and can be scaled to zero outside of business hours.
