instance_type   = "c6i.large"
ami_name = "EKS_Optimized_AL2_Level_2"
ami_description = "EKS_Optimized_AL2_CIS_Benchmark_Level_2"

ami_block_device_mappings = [
  {
    device_name = "/dev/xvda"
    volume_size = 10
  },
]

launch_block_device_mappings = [
  {
    device_name = "/dev/xvda"
    volume_size = 10
  },
  {
    device_name = "/dev/xvdb"
    volume_size = 64
  },
]


shell_provisioner1 = "sudo /cis-scripts/CIS-LBK/cis_lbk_amazon_linux_2/amazon_linux_2_level_2.sh"

file_provisioner1 = "/cis-scripts/CIS-LBK/cis_lbk_amazon_linux_2/logs/"