output "aws_region" {
  description = "AWS region used by the project"
  value       = var.aws_region
}

output "cluster_name" {
  description = "Amazon EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Amazon EKS Kubernetes API endpoint"
  value       = module.eks.cluster_endpoint
}

output "vpc_id" {
  description = "VPC created for the EKS cluster"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs used by the project"
  value       = module.vpc.public_subnets
}

output "configure_kubectl" {
  description = "Command used to create/update the local kubeconfig entry"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}
