output "s3_bucket_url" {
  description = "S3 URL for the Terraform state bucket"
  value       = "s3://${aws_s3_bucket.state_bucket.bucket}"
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.tf_lock.name
}

