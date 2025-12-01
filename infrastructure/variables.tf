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
variable "prometheus_namespace" {
  description = "Kubernetes namespace for Prometheus stack"
  type        = string
  default     = "monitoring"
}

variable "prometheus_release_name" {
  description = "Helm release name for Prometheus"
  type        = string
  default     = "prometheus"
}

variable "prometheus_chart_version" {
  description = "Version of kube-prometheus-stack Helm chart"
  type        = string
  default     = "55.5.0"
}

variable "prometheus_values_file" {
  description = "Environment-specific values file name (e.g., values-dev.yaml)"
  type        = string
  default     = ""
}

variable "prometheus_storage_class" {
  description = "Storage class for Prometheus persistent volumes"
  type        = string
  default     = "gp3"
}

variable "prometheus_set_values" {
  description = "Additional Helm chart values to set for Prometheus"
  type        = map(string)
  default     = {}
}

variable "grafana_namespace" {
  description = "Kubernetes namespace for Grafana"
  type        = string
  default     = "monitoring"
}

variable "grafana_release_name" {
  description = "Helm release name for Grafana"
  type        = string
  default     = "grafana"
}

variable "grafana_chart_version" {
  description = "Version of Grafana Helm chart"
  type        = string
  default     = "7.0.8"
}

variable "grafana_values_file" {
  description = "Environment-specific values file name for Grafana (e.g., values-dev.yaml)"
  type        = string
  default     = ""
}

variable "grafana_storage_class" {
  description = "Storage class for Grafana persistent volumes"
  type        = string
  default     = "gp3"
}

variable "grafana_admin_user" {
  description = "Admin username for Grafana"
  type        = string
  sensitive   = true
  default     = "admin"
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana (use AWS Secrets Manager in production)"
  type        = string
  sensitive   = true
}

variable "grafana_prometheus_url" {
  description = "Prometheus server URL for Grafana data source"
  type        = string
  default     = "http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090"
}

variable "grafana_set_values" {
  description = "Additional Helm chart values to set for Grafana"
  type        = map(string)
  default     = {}
}

