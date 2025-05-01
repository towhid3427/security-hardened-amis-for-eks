################################################################################
# SSM Parameters
################################################################################

resource "aws_ssm_parameter" "eks_optimized_al2_level_1" {
  name  = "/cis_ami/${local.name}/EKS_Optimized_AL2_Level_1/ami_id"
  type  = "String"
  value = "placeholder"

  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "eks_optimized_al2_level_2" {
  name  = "/cis_ami/${local.name}/EKS_Optimized_AL2_Level_2/ami_id"
  type  = "String"
  value = "placeholder"

  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}