
output "vpc_id" {
  description = "ID of the TWK VPC"
  value       = aws_vpc.twk.id
}

output "dev_subnet_id" {
  description = "ID of the development subnet"
  value       = aws_subnet.dev.id
}

output "security_group_id" {
  description = "ID of the development security group"
  value       = aws_security_group.dev-sg.id
}

output "ec2_id" {
  description = "ID of the development EC2 instance"
  value       = aws_instance.dev.id
}

output "ec2_private_ip" {
  description = "Private IPv4 address of the EC2 instance"
  value       = aws_instance.dev.private_ip
}

output "ec2_public_ip" {
  description = "Elastic IP associated with the EC2 instance"
  value       = aws_eip.dev.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.dev.public_dns
}

output "s3_bucket" {
  description = "Name of the private S3 bucket"
  value       = aws_s3_bucket.state.bucket
}
