variable "aws_region" {
  description = "AWS region used for the project"
  type        = string
  default     = "ca-central-1"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "automate-kubernetes-deployment"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "Amazon EKS cluster name"
  type        = string
  default     = "ansible-capstone-eks"
}

variable "kubernetes_version" {
  description = "Kubernetes version for Amazon EKS"
  type        = string
  default     = "1.36"
}

variable "vpc_cidr" {
  description = "CIDR block for the project VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "node_instance_types" {
  description = "EC2 instance types used by the EKS managed node group"
  type        = list(string)
  default     = ["t3.small"]
}
