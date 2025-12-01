output "namespace" {
  description = "Kubernetes namespace where Grafana is deployed"
  value       = kubernetes_namespace.monitoring.metadata[0].name
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
