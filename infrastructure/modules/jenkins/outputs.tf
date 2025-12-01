output "jenkins_release_name" {
  description = "Name of the Jenkins Helm release"
  value       = helm_release.jenkins.name
}

output "jenkins_namespace" {
  description = "Namespace where Jenkins is deployed"
  value       = helm_release.jenkins.namespace
}

output "jenkins_service_account_name" {
  description = "Name of the Jenkins service account"
  value       = kubernetes_service_account.jenkins_sa.metadata[0].name
}

output "jenkins_iam_role_arn" {
  description = "ARN of the IAM role used by Jenkins"
  value       = aws_iam_role.jenkins_kaniko_role.arn
}

output "jenkins_environment" {
  description = "Environment for this Jenkins deployment"
  value       = var.environment
}

output "jenkins_admin_username" {
  description = "Jenkins admin username"
  value       = var.jenkins_admin_username
}

output "jenkins_admin_password" {
  description = "Jenkins admin password"
  value       = var.jenkins_admin_password
  sensitive   = true
}
