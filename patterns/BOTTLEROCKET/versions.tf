terraform {
  backend "s3" {
    bucket  = "BUCKET"
    key     = "BOTTLEROCKET"
    region  = "us-west-2"
    encrypt = true
  }
}