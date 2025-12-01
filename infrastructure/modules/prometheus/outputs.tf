output "namespace" {
  description = "Kubernetes namespace where Prometheus is deployed"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "release_name" {
  description = "Helm release name for Prometheus"
  value       = helm_release.prometheus.name
}

output "chart_version" {
  description = "Version of the deployed Prometheus chart"
  value       = helm_release.prometheus.version
}

output "prometheus_service_name" {
  description = "Kubernetes service name for Prometheus"
  value       = "${var.release_name}-kube-prometheus-prometheus"
}

output "grafana_service_name" {
  description = "Kubernetes service name for Grafana"
  value       = "${var.release_name}-grafana"
}

output "alertmanager_service_name" {
  description = "Kubernetes service name for Alertmanager"
  value       = "${var.release_name}-kube-prometheus-alertmanager"
}
