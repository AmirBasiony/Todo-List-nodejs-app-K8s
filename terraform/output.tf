output "vpc_id" {
  value       = aws_vpc.AppVPC_K8s.id
  description = "The ID of the main application VPC"
}
output "aws_region" {
  value       = var.aws_region
  description = "The ID of the main application VPC"
}

output "public_subnet_id" {
  value       = aws_subnet.public_subnet_K8s.id
  description = "ID of the public subnet"
}

output "ec2_public_ip" {
  value = aws_instance.Minikube_K8s.public_ip
}

output "ecr_url" {
  value = data.aws_ecr_repository.app_ecr.repository_url
}

output "ecr_registry" {
  value = data.aws_ecr_repository.app_ecr.registry_id
}

output "instance_type" {
  value = var.instance_type
}