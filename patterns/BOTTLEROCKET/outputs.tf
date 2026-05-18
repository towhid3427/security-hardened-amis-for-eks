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

output "ecr_repository_url" {
  description = "The URL of the ECR repository for the CIS bootstrap image"
  value       = aws_ecr_repository.bottlerocket_cis_bootstrap_image.repository_url
}

output "ecr_repository_arn" {
  description = "The ARN of the ECR repository for the CIS bootstrap image"
  value       = aws_ecr_repository.bottlerocket_cis_bootstrap_image.arn
}

output "bottlerocket_ami_id" {
  description = "The Bottlerocket AMI ID used for the node group"
  value       = data.aws_ssm_parameter.bottlerocket_ami.value
  sensitive   = true
}

output "ecr_image_tag" {
  description = "The tag of the CIS bootstrap image pushed to ECR (content-hash if image_tag is empty)"
  value       = local.image_tag
}

output "ecr_image_uri" {
  description = "Fully-qualified URI of the CIS bootstrap image in ECR"
  value       = "${aws_ecr_repository.bottlerocket_cis_bootstrap_image.repository_url}:${local.image_tag}"
}
