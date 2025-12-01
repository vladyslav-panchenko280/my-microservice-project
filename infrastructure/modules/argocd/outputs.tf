output "argocd_namespace" {
  description = "Namespace where Argo CD is installed"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "argocd_server_service" {
  description = "Argo CD server service name"
  value       = "argocd-server"
}

output "argocd_role_arn" {
  description = "IAM Role ARN for Argo CD"
  value       = aws_iam_role.argocd_role.arn
}

output "argocd_url" {
  description = "URL to access Argo CD (via port-forward or LoadBalancer)"
  value       = "kubectl port-forward svc/argocd-server -n ${var.argocd_namespace} 8080:443"
}

output "argocd_admin_username" {
  description = "ArgoCD admin username"
  value       = "admin"
}

output "argocd_admin_password" {
  description = "ArgoCD admin password"
  value       = var.argocd_admin_password
  sensitive   = true
}
