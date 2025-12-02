variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for Prometheus stack"
  type        = string
  default     = "monitoring"
}

variable "release_name" {
  description = "Helm release name for Prometheus"
  type        = string
  default     = "prometheus"
}

variable "chart_version" {
  description = "Version of kube-prometheus-stack Helm chart"
  type        = string
  default     = "55.5.0"
}

variable "values_file" {
  description = "Environment-specific values file name (e.g., values-dev.yaml)"
  type        = string
  default     = ""
}

variable "storage_class" {
  description = "Storage class for Prometheus persistent volumes"
  type        = string
  default     = "gp3"
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
