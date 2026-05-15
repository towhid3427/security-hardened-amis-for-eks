################################################################################
# Data Sources
################################################################################

# Get AWS account ID
data "aws_caller_identity" "current" {}

# Get list of available AZs in the current region
data "aws_availability_zones" "available" {}

# Bottlerocket AMI ID for the EKS cluster version
data "aws_ssm_parameter" "bottlerocket_ami" {
  name = "/aws/service/bottlerocket/aws-k8s-${module.eks_cluster.cluster_version}/x86_64/latest/image_id"
}
