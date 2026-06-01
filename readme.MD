# roboshop-aws-infra

Overview
Complete Terraform and documentation for deploying Roboshop onto AWS, including diagrams.

Why this exists
Provides a reproducible cloud environment for running and testing the Roboshop microservices.

Workflows
- Review architecture diagrams
- Configure environment variables and TF backend
- terraform apply to create infra

Actions (quick start)
1. Install Terraform and AWS CLI.
2. Review DOCUMENTATION.md and readme.MD for environment specifics.
3. terraform init && terraform apply

Key files
- 00-VPC..91-cdn, DOCUMENTATION.md, readme.MD, roboshop-infra-dev.drawio.svg

Notes
- Verify IAM permissions before applying.
