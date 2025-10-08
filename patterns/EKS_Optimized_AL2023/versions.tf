terraform {
  backend "s3" {
    bucket  = "security-hardened-amis-for-eks-terraform-state-file"
    key     = "EKS_Optimized_AL2023"
    region  = "us-west-2"
    encrypt = true
  }
}