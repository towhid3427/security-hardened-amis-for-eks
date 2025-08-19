terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.7.0"
    }
  }
  backend "s3" {
    bucket  = "BUCKET_NAME"
    key     = "CIS_AL2"
    region  = "us-west-2"
    encrypt = true
  }
}