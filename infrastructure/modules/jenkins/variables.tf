variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, production"
  }
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider for EKS"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the OIDC provider for EKS"
  type        = string
}

variable "github_username" {
  description = "GitHub username for Jenkins credentials"
  type        = string
  default     = ""
}

variable "github_token" {
  description = "GitHub personal access token for Jenkins"
  type        = string
  sensitive   = true
  default     = ""
}

variable "chart_version" {
  description = "Version of the Jenkins Helm chart"
  type        = string
  default     = "0.1.0"
}

variable "jenkins_admin_username" {
  description = "Admin username for Jenkins"
  type        = string
  default     = "admin"
}

variable "jenkins_admin_password" {
  description = "Admin password for Jenkins"
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
