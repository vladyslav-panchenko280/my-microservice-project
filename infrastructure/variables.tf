variable "environment" {
  description = "Environment name (dev/stage/prod)"
  type        = string
}

variable "backend_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
}

variable "backend_key" {
  description = "S3 key for Terraform state"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "ecr_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "scan_on_push" {
  description = "Enable image scanning on push"
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for EKS nodes"
  type        = string
}

variable "desired_size" {
  description = "Desired number of EKS nodes"
  type        = number
}

variable "max_size" {
  description = "Maximum number of EKS nodes"
  type        = number
}

variable "min_size" {
  description = "Minimum number of EKS nodes"
  type        = number
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets (cost optimization for dev)"
  type        = bool
  default     = false
}

variable "jenkins_github_username" {
  description = "GitHub username for Jenkins CI/CD"
  type        = string
  default     = ""
}

variable "jenkins_github_token" {
  description = "GitHub personal access token for Jenkins CI/CD"
  type        = string
  sensitive   = true
  default     = ""
}

variable "jenkins_admin_password" {
  description = "Admin password for Jenkins (use only for dev, use secrets for staging/prod)"
  type        = string
  sensitive   = true
  default     = "admin123"
}

variable "aws_account_id" {
  description = "AWS Account ID for Jenkins credentials"
  type        = string
  sensitive   = true
  default     = ""
}

variable "argocd_github_username" {
  description = "GitHub username for Argo CD repository access"
  type        = string
  default     = ""
}

variable "argocd_github_token" {
  description = "GitHub personal access token for Argo CD repository access"
  type        = string
  sensitive   = true
  default     = ""
}

variable "argocd_git_repository_url" {
  description = "Git repository URL for Argo CD to monitor"
  type        = string
  default     = "https://github.com/vladyslav-panchenko280/django-jenkins-app.git"
}

variable "argocd_admin_password" {
  description = "Admin password for Argo CD (bcrypt hashed). Generate with: htpasswd -nbBC 10 '' $PASSWORD | tr -d ':\\n' | sed 's/$2y/$2a/'"
  type        = string
  sensitive   = true
  default     = ""
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Name identifier for the RDS/Aurora instance"
  type        = string
  default     = "myapp-db"
}

variable "db_database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "myapp"
}

variable "db_use_aurora" {
  description = "Use Aurora PostgreSQL instead of standard RDS"
  type        = bool
  default     = true
}

variable "db_aurora_instance_count" {
  description = "Number of Aurora instances (writer + readers)"
  type        = number
  default     = 2
}

variable "db_instance_class" {
  description = "Instance class for the database"
  type        = string
  default     = "db.t3.medium"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB (only for standard RDS)"
  type        = number
  default     = 20
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment for high availability"
  type        = bool
  default     = false
}

variable "db_publicly_accessible" {
  description = "Make database publicly accessible"
  type        = bool
  default     = false
}

variable "db_backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "db_parameters" {
  description = "Database parameters"
  type        = map(string)
  default = {
    log_min_duration_statement = "500"
  }
}

