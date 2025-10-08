terraform {
  backend "s3" {
    bucket  = "security-hardened-amis-for-eks-terraform-state-file"
    key     = "CIS_AL2"
    region  = "us-west-2"
    encrypt = true
  }
}