terraform {
  required_version = ">= 1.3"

  backend "s3" {
    bucket  = "BUCKET_NAME"
    key     = "BOTTLEROCKET"
    region  = "us-west-2"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.44.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.4"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.38.0"
    }
  }
}
