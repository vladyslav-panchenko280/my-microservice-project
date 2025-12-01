output "namespace" {
  description = "Kubernetes namespace where Grafana is deployed"
  value       = var.namespace
}

output "release_name" {
  description = "Helm release name for Grafana"
  value       = helm_release.grafana.name
}

output "chart_version" {
  description = "Version of the deployed Grafana chart"
  value       = helm_release.grafana.version
}

output "grafana_service_name" {
  description = "Kubernetes service name for Grafana"
  value       = "${var.release_name}"
}

output "grafana_url" {
  description = "Grafana access URL (use kubectl port-forward or LoadBalancer URL)"
  value       = "http://${var.release_name}.${var.namespace}.svc.cluster.local"
}

output "grafana_admin_username" {
  description = "Grafana admin username"
  value       = var.grafana_admin_user
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = var.grafana_admin_password
  sensitive   = true
}
