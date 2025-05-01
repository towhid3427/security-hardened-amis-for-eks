provider "aws" {
  region = local.region
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}
data "aws_eks_cluster_auth" "cluster_auth" {
  name = module.eks_cluster.cluster_version
}
data "aws_ssm_parameter" "private_subnets" {
  name = "/${local.name}/private_subnets"
}

# AuthN so Helm Can Install Charts
provider "helm" {
  kubernetes {
    host                   = module.eks_cluster.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_cluster.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks_cluster.cluster_name]
    }

  }
}

provider "kubernetes" {
  host                   = module.eks_cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks_cluster.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks_cluster.cluster_name]
  }

}


data "aws_ssm_parameter" "eks_optimized_al2023_level_1" {
  name = "/cis_ami/${local.name}/EKS_Optimized_AL2023_Level_1/ami_id"
}

data "aws_ssm_parameter" "eks_optimized_al2023_level_2" {
  name = "/cis_ami/${local.name}/EKS_Optimized_AL2023_Level_2/ami_id"
}
module "eks_cluster" {
  source = "../../modules/eks-cluster"
  name   = local.name
}

module "eks_managed_node_group_level_1" {
  depends_on = [module.eks_cluster]
  source     = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "~> 20.36" #ensure to update this to the latest/desired version

  name                              = "EKSOAL2023L1"
  cluster_name                      = module.eks_cluster.cluster_name
  cluster_version                   = module.eks_cluster.cluster_version
  subnet_ids                        = tolist(split(",", data.aws_ssm_parameter.private_subnets.value))
  cluster_primary_security_group_id = module.eks_cluster.cluster_primary_security_group_id
  vpc_security_group_ids = [
    module.eks_cluster.node_security_group_id,
  ]
  cluster_service_cidr = module.eks_cluster.cluster_service_cidr
  iam_role_additional_policies = {
    # Not required, but used in the example to access the nodes to inspect mounted volumes
    AmazonSSMManagedInstanceCore     = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    AmazonInspector2ManagedCisPolicy = "arn:aws:iam::aws:policy/AmazonInspector2ManagedCisPolicy"
  }
  ami_id = data.aws_ssm_parameter.eks_optimized_al2023_level_1.value

  instance_types             = ["m6i.large", "m5.large", "m5zn.large"]
  capacity_type              = "SPOT"
  force_update_version       = true
  enable_bootstrap_user_data = true
  cluster_endpoint           = module.eks_cluster.cluster_endpoint

  cluster_auth_base64 = module.eks_cluster.cluster_certificate_authority_data

  ami_type = "AL2023_x86_64_STANDARD"

  min_size = 1
  max_size = 1
  # This value is ignored after the initial creation
  # https://github.com/bryantbiggs/eks-desired-size-hack
  desired_size = 1
}

module "eks_managed_node_group_level_2" {
  depends_on = [module.eks_cluster]
  source     = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "~> 20.36" #ensure to update this to the latest/desired version

  name                              = "EKSOAL2023L2"
  cluster_name                      = module.eks_cluster.cluster_name
  cluster_version                   = module.eks_cluster.cluster_version
  subnet_ids                        = tolist(split(",", data.aws_ssm_parameter.private_subnets.value))
  cluster_primary_security_group_id = module.eks_cluster.cluster_primary_security_group_id
  vpc_security_group_ids = [
    module.eks_cluster.node_security_group_id,
  ]
  cluster_service_cidr = module.eks_cluster.cluster_service_cidr
  iam_role_additional_policies = {
    # Not required, but used in the example to access the nodes to inspect mounted volumes
    AmazonSSMManagedInstanceCore     = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    AmazonInspector2ManagedCisPolicy = "arn:aws:iam::aws:policy/AmazonInspector2ManagedCisPolicy"
  }
  ami_id = data.aws_ssm_parameter.eks_optimized_al2023_level_2.value

  instance_types             = ["m6i.large", "m5.large", "m5zn.large"]
  capacity_type              = "SPOT"
  force_update_version       = true
  enable_bootstrap_user_data = true
  cluster_endpoint           = module.eks_cluster.cluster_endpoint

  cluster_auth_base64 = module.eks_cluster.cluster_certificate_authority_data
  ami_type            = "AL2023_x86_64_STANDARD"

  min_size = 1
  max_size = 1
  # This value is ignored after the initial creation
  # https://github.com/bryantbiggs/eks-desired-size-hack
  desired_size = 1
}
module "eks_blueprints_addons" {
  depends_on = [module.eks_cluster, module.eks_managed_node_group_level_1, module.eks_managed_node_group_level_2]
  source     = "../../modules/eks-addons"

  cluster_name      = module.eks_cluster.cluster_name
  cluster_endpoint  = module.eks_cluster.cluster_endpoint
  cluster_version   = module.eks_cluster.cluster_version
  oidc_provider_arn = module.eks_cluster.oidc_provider_arn

}
