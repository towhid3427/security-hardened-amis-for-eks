terraform {
  backend "s3" {
    bucket  = "BUCKET_NAME"
    key     = "BOTTLEROCKET_nodes"
    region  = "us-west-2"
    encrypt = true
  }
}