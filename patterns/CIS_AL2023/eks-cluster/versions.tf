terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.100.0"
    }
  }
  backend "s3" {
    bucket  = "BUCKET_NAME"
    key     = "CIS_AL2023_nodes"
    region  = "us-west-2"
    encrypt = true
  }
}