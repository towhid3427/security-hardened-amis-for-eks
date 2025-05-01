
data "aws_ssm_parameter" "vpc_id" {
  name = "/${var.name}/vpc_id"
}

data "aws_ssm_parameter" "private_subnets" {
  name = "/${var.name}/private_subnets"
}

################################################################################
# EKS CLUSTER
################################################################################


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.36"

  cluster_name                   = var.name
  cluster_version                = var.cluster_version
  cluster_endpoint_public_access = true

  # Give the Terraform identity admin access to the cluster
  # which will allow resources to be deployed into the cluster
  enable_cluster_creator_admin_permissions = true

  vpc_id = data.aws_ssm_parameter.vpc_id.value

  #subnet_ids =  data.aws_ssm_parameter.private_subnets.value
  subnet_ids = tolist(split(",", data.aws_ssm_parameter.private_subnets.value))


  eks_managed_node_group_defaults = {
    iam_role_additional_policies = {
      # Not required, but used in the example to access the nodes to inspect mounted volumes
      AmazonSSMManagedInstanceCore     = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      AmazonInspector2ManagedCisPolicy = "arn:aws:iam::aws:policy/AmazonInspector2ManagedCisPolicy"
    }
  }

  tags = var.tags

  cluster_addons = var.cluster_addons

}
