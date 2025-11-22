output "db_instance_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = var.use_aurora ? null : aws_db_instance.standard[0].endpoint
}

output "db_instance_address" {
  description = "The hostname of the RDS instance"
  value       = var.use_aurora ? null : aws_db_instance.standard[0].address
}

output "db_instance_port" {
  description = "The port of the RDS instance"
  value       = var.use_aurora ? null : aws_db_instance.standard[0].port
}

output "db_instance_id" {
  description = "The RDS instance ID"
  value       = var.use_aurora ? null : aws_db_instance.standard[0].id
}

output "aurora_cluster_endpoint" {
  description = "The cluster endpoint for Aurora (writer)"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].endpoint : null
}

output "aurora_reader_endpoint" {
  description = "The reader endpoint for Aurora"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].reader_endpoint : null
}

output "aurora_cluster_port" {
  description = "The port of the Aurora cluster"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].port : null
}

output "aurora_cluster_id" {
  description = "The Aurora cluster ID"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].id : null
}

output "db_host" {
  description = "Database host for application connection"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].endpoint : aws_db_instance.standard[0].address
}

output "db_port" {
  description = "Database port"
  value       = var.use_aurora ? aws_rds_cluster.aurora[0].port : aws_db_instance.standard[0].port
}

output "db_name" {
  description = "Database name"
  value       = var.db_name
}

output "db_username" {
  description = "Database username"
  value       = var.username
}

output "db_password" {
  description = "Database password"
  value       = var.password
  sensitive   = true
}

output "security_group_id" {
  description = "Security group ID for the RDS instance"
  value       = aws_security_group.rds.id
}
