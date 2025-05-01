terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.96"
    }
  }
  backend "s3" {
    bucket  = "BUCKET_NAME"
    key     = "EKS_Optimized_AL2023"
    region  = "us-west-2"
    encrypt = true
  }
}