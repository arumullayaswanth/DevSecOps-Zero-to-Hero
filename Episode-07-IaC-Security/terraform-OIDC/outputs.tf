# outputs.tf
# Values that are displayed after terraform apply
# Useful for getting instance IPs, ARNs, etc.

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "instance_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.web.private_ip
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.app_data.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.web.id
}
