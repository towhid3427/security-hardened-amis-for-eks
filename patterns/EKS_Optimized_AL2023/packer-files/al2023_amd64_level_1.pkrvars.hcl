instance_type   = "c6i.large"
ami_name = "EKS_Optimized_AL2023_CIS_Benchmark_Level_1"
ami_description = "EKS_Optimized_AL2023_CIS_Benchmark_Level_1"

ami_block_device_mappings = [
  {
    device_name = "/dev/xvda"
    volume_size = 20
  },
]

launch_block_device_mappings = [
  {
    device_name = "/dev/xvda"
    volume_size = 20
  },
  {
    device_name = "/dev/xvdb"
    volume_size = 64
  },
]


shell_provisioner1 = "sudo /cis-scripts/CIS-LBK/cis_lbk_amazon_linux_2023/amazon_linux_2023_level_1.sh"

file_provisioner1 = "/cis-scripts/CIS-LBK/cis_lbk_amazon_linux_2023/logs/"