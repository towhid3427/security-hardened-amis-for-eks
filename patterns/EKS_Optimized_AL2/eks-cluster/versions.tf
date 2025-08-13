terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.7.0"
    }
  }
  backend "s3" {
    bucket  = "security-hardened-amis-for-eks-terraform-state-file"
    key     = "EKS_Optimized_AL2_nodes"
    region  = "us-west-2"
    encrypt = true
  }
}