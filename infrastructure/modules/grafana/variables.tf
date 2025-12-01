variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for Grafana"
  type        = string
  default     = "monitoring"
}

variable "release_name" {
  description = "Helm release name for Grafana"
  type        = string
  default     = "grafana"
}

variable "chart_version" {
  description = "Version of Grafana Helm chart"
  type        = string
  default     = "7.0.8"
}

variable "values_file" {
  description = "Environment-specific values file name (e.g., values-dev.yaml)"
  type        = string
  default     = ""
}

variable "storage_class" {
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

variable "prometheus_url" {
  description = "Prometheus server URL for Grafana data source"
  type        = string
  default     = "http://prometheus-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090"
}

variable "set_values" {
  description = "Additional Helm chart values to set"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
