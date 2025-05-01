################################################################################
# SSM Parameters
################################################################################
resource "aws_ssm_parameter" "cis_amazon_linux_2_kernel_4_benchmark_level_1" {
  name  = "/cis_ami/${local.name}/CIS_Amazon_Linux_2_Benchmark_Level_1/ami_id"
  type  = "String"
  value = "placeholder"

  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_ssm_parameter" "cis_amazon_linux_2_benchmark_level_2" {
  name  = "/cis_ami/${local.name}/CIS_Amazon_Linux_2_Benchmark_Level_2/ami_id"
  type  = "String"
  value = "placeholder"

  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}