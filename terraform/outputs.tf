output "ec2_public_ip" {
  description = "Public IP address of the application server."
  value       = aws_instance.app.public_ip
}

output "rds_address" {
  description = "RDS endpoint hostname for DB_HOST."
  value       = aws_db_instance.app.address
}

output "rds_endpoint" {
  description = "RDS endpoint hostname and port."
  value       = aws_db_instance.app.endpoint
}