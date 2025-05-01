resource "aws_ecr_repository" "bottlerocket_cis_bootstrap_image" {
  name                 = "bottlerocket-cis-bootstrap-image"
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration {
   scan_on_push = true
  }
  encryption_configuration {
    encryption_type = "KMS"
  }
  force_delete         = true
}