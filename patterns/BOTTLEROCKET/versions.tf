terraform {
  backend "s3" {
    bucket  = "terraform-backend-eks-cis-us-west-2"
    key     = "BOTTLEROCKET"
    region  = "us-west-2"
    encrypt = true
  }
}