################################################################################
# Data Sources
################################################################################

# Get AWS account ID
data "aws_caller_identity" "current" {}

# Get list of available AZs in the current region
data "aws_availability_zones" "available" {}

# Latest CIS Level 1 hardened AMI built by Packer (filtered by Name prefix).
# Both build paths (full-stack and AMI-only) tag with the same prefix, so the
# data source resolves the freshest matching AMI regardless of which path
# created it. Replaces the SSM placeholder anti-pattern.
data "aws_ami_ids" "cis_amazon_linux_2023_benchmark_level_1" {
  depends_on = [
    null_resource.create_hardened_ami_level_1,
    null_resource.only_create_hardened_ami_level_1,
  ]
  owners         = ["self"]
  sort_ascending = false # Newest first

  filter {
    name   = "name"
    values = ["CIS_Amazon_Linux_2023_Benchmark_Level_1-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Latest CIS Level 2 hardened AMI built by Packer.
data "aws_ami_ids" "cis_amazon_linux_2023_benchmark_level_2" {
  depends_on = [
    null_resource.create_hardened_ami_level_2,
    null_resource.only_create_hardened_ami_level_2,
  ]
  owners         = ["self"]
  sort_ascending = false

  filter {
    name   = "name"
    values = ["CIS_Amazon_Linux_2023_Benchmark_Level_2-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}
