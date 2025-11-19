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
