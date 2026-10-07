output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer to access the application"
  value = "http://${aws_lb.external_alb.dns_name}"
}
output "rds_endpoint" {
  description = "Connection endpoint for the PostgreSQL RDS database"
  value       = aws_db_instance.postgres.endpoint
}

output "secrets_manager_secret_arn" {
  description = "ARN of the Secrets Manager secret containing database credentials"
  value       = aws_secretsmanager_secret.db_credentials.arn
}

output "vpc_id" {
  description = "The ID of the provisioned 3-tier VPC"
  value       = aws_vpc.main.id
}
