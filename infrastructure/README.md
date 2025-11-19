## About project
This project sets up the foundational AWS infrastructure needed to deploy containerized applications securely. It creates a production-ready network with isolated subnets, remote state management to enable team collaboration, and a private container registry for storing Docker images.

## What this does
- Provisions an S3 bucket (versioned) and DynamoDB table for Terraform state and locking
- Builds a production VPC with 3 public and 3 private subnets, IGW, NATs, and routing
- Creates an ECR repository with scan-on-push and a repository policy

## Defaults and naming
- Region: us-east-1
- S3 bucket: es-terraform-state-<account_id>
- DynamoDB table: es-terraform-locks
- VPC name: es-vpc
- ECR name: es-ecr

## Usage
1) Ensure you have AWS credentials configured for us-east-1
2) Initialize backend and providers
   terraform init
3) Review changes
   terraform plan
4) Apply
   terraform apply
5) Destroy
   terraform destroy

## Outputs
- state_bucket_url: s3 URL for the remote state bucket
- dynamodb_table_name: DynamoDB table used for state locking
- vpc_id, public_subnet_ids, private_subnet_ids
- ecr_repository_url

## Module structure
- modules/s3-backend: S3 bucket (versioned), SSE, and DynamoDB lock table
- modules/vpc: VPC, IGW, 3x public + 3x private subnets, NAT gateways, route tables
- modules/ecr: ECR repo with scan-on-push and permissive account policy

