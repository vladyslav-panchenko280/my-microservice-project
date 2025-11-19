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

