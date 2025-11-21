variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name (dev/stage/prod)"
  type        = string
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
  description = "GitHub username for repository access"
  type        = string
  default     = ""
}

variable "github_token" {
  description = "GitHub personal access token for repository access"
  type        = string
  sensitive   = true
  default     = ""
}

variable "git_repository_url" {
  description = "Git repository URL for Argo CD to monitor"
  type        = string
  default     = "https://github.com/vladyslav-panchenko280/django-jenkins-app.git"
}

variable "argocd_namespace" {
  description = "Namespace for Argo CD installation"
  type        = string
  default     = "argocd"
}

variable "argocd_admin_password" {
  description = "Admin password for Argo CD (bcrypt hashed)"
  type        = string
  sensitive   = true
  default     = ""
}
