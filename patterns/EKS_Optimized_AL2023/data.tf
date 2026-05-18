################################################################################
# Data Sources
################################################################################

# Get AWS account ID
data "aws_caller_identity" "current" {}

# Get list of available AZs in the current region
data "aws_availability_zones" "available" {}

# Latest CIS Level 1 hardened AMI built by Packer (filtered by Name tag prefix).
# Both build paths (full-stack and AMI-only) tag with the same prefix, so the
# data source resolves the freshest matching AMI regardless of which path
# created it.
data "aws_ami" "eks_optimized_al2023_level_1" {
  depends_on = [
    null_resource.create_hardened_ami_level_1,
    null_resource.only_create_hardened_ami_level_1,
  ]
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["${local.ami_name_level_1}-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Latest CIS Level 2 hardened AMI built by Packer.
data "aws_ami" "eks_optimized_al2023_level_2" {
  depends_on = [
    null_resource.create_hardened_ami_level_2,
    null_resource.only_create_hardened_ami_level_2,
  ]
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["${local.ami_name_level_2}-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}
