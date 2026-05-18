################################################################################
# Outputs
################################################################################

output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.eks_cluster.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS cluster API server"
  value       = module.eks_cluster.cluster_endpoint
}

output "cluster_version" {
  description = "The Kubernetes version of the EKS cluster"
  value       = module.eks_cluster.cluster_version
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for the EKS cluster"
  value       = module.eks_cluster.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_primary_security_group_id" {
  description = "The primary security group ID of the EKS cluster"
  value       = module.eks_cluster.cluster_primary_security_group_id
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC provider for the EKS cluster"
  value       = module.eks_cluster.oidc_provider_arn
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

output "ami_id_level_1" {
  description = "The AMI ID for the EKS Optimized AL2023 Level 1 hardened image"
  value       = data.aws_ami.eks_optimized_al2023_level_1.id
}

output "ami_id_level_2" {
  description = "The AMI ID for the EKS Optimized AL2023 Level 2 hardened image"
  value       = data.aws_ami.eks_optimized_al2023_level_2.id
}
