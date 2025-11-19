variable "ecr_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "scan_on_push" {
  description = "Enable image scan on push"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "enterprise-suite"
  }
}

variable "environment" {
  description = "Environment name to apply as a tag override"
  type        = string
  default     = null
}

