output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecr.repository_url
}

output "eks_cluster_endpoint" {
  description = "EKS API endpoint for connecting to the cluster"
  value       = module.eks.eks_cluster_endpoint
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.eks_cluster_name
}

output "eks_node_role_arn" {
  description = "IAM role ARN for EKS Worker Nodes"
  value       = module.eks.eks_node_role_arn
}

output "jenkins_release" {
  value = module.jenkins.jenkins_release_name
}

output "jenkins_namespace" {
  value = module.jenkins.jenkins_namespace
}

output "jenkins_admin_username" {
  description = "Jenkins admin username"
  value       = module.jenkins.jenkins_admin_username
}

output "jenkins_admin_password" {
  description = "Jenkins admin password (use 'terraform output -raw jenkins_admin_password' to view)"
  value       = module.jenkins.jenkins_admin_password
  sensitive   = true
}

output "argocd_namespace" {
  description = "Namespace where Argo CD is installed"
  value       = module.argocd.argocd_namespace
}

output "argocd_server_service" {
  description = "Argo CD server service name"
  value       = module.argocd.argocd_server_service
}

output "argocd_url" {
  description = "Command to access Argo CD UI"
  value       = module.argocd.argocd_url
}

output "argocd_admin_username" {
  description = "ArgoCD admin username"
  value       = module.argocd.argocd_admin_username
}

output "argocd_admin_password" {
  description = "ArgoCD admin password (use 'terraform output -raw argocd_admin_password' to view)"
  value       = module.argocd.argocd_admin_password
  sensitive   = true
}

output "db_host" {
  description = "Database hostname for Django connection"
  value       = module.rds.db_host
}

output "db_port" {
  description = "Database port"
  value       = module.rds.db_port
}

output "db_name" {
  description = "Database name"
  value       = module.rds.db_name
}

output "db_connection_string" {
  description = "Django DATABASE_URL format connection string"
  value       = "postgres://${module.rds.db_username}:****@${module.rds.db_host}:${module.rds.db_port}/${module.rds.db_name}"
  sensitive   = false
}

output "prometheus_namespace" {
  description = "Kubernetes namespace where Prometheus is deployed"
  value       = module.prometheus.namespace
}

output "prometheus_service_name" {
  description = "Kubernetes service name for Prometheus"
  value       = module.prometheus.prometheus_service_name
}

output "grafana_namespace" {
  description = "Kubernetes namespace where Grafana is deployed"
  value       = module.grafana.namespace
}

output "grafana_service_name" {
  description = "Kubernetes service name for Grafana"
  value       = module.grafana.grafana_service_name
}

output "grafana_url" {
  description = "Grafana access URL (use kubectl port-forward or LoadBalancer URL)"
  value       = module.grafana.grafana_url
}

output "grafana_admin_username" {
  description = "Grafana admin username"
  value       = module.grafana.grafana_admin_username
}

output "grafana_admin_password" {
  description = "Grafana admin password (use 'terraform output -raw grafana_admin_password' to view)"
  value       = module.grafana.grafana_admin_password
  sensitive   = true
}

