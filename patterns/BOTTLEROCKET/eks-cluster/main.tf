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

module "eks_cluster" {
  source = "../../modules/eks-cluster"
  name   = local.name
}


module "eks_managed_node_group" {
  source = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "~> 20.36" #ensure to update this to the latest/desired version

  name            = "BOTTLEROCKETL2"
  cluster_name    = module.eks_cluster.cluster_name
  cluster_version = module.eks_cluster.cluster_version
  subnet_ids      = tolist(split(",", data.aws_ssm_parameter.private_subnets.value))

  // The following variables are necessary if you decide to use the module outside of the parent EKS module context.
  // Without it, the security groups of the nodes are empty and thus won't join the cluster.
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

  ami_type = "BOTTLEROCKET_x86_64"

  instance_types             = ["m6i.large", "m5.large", "m5zn.large"]
  capacity_type              = "SPOT"
  force_update_version       = true
  enable_bootstrap_user_data = true
  cluster_endpoint           = module.eks_cluster.cluster_endpoint
  cluster_auth_base64        = module.eks_cluster.cluster_certificate_authority_data

  bootstrap_extra_args = <<-EOT
          [settings.bootstrap-containers.cis-bootstrap]
          source = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${local.region}.amazonaws.com/bottlerocket-cis-bootstrap-image:latest"
          mode = "always"

          [settings.kernel]
          lockdown = "integrity"
          [settings.kernel.modules.udf]
          allowed = false
          [settings.kernel.modules.sctp]
          allowed = false
          [settings.kernel.sysctl]
          "net.ipv4.conf.all.send_redirects" = "0"
          "net.ipv4.conf.default.send_redirects" = "0"
          "net.ipv4.conf.all.accept_redirects" = "0"
          "net.ipv4.conf.default.accept_redirects" = "0"
          "net.ipv6.conf.all.accept_redirects" = "0"
          "net.ipv6.conf.default.accept_redirects" = "0"
          "net.ipv4.conf.all.secure_redirects" = "0"
          "net.ipv4.conf.default.secure_redirects" = "0"
          "net.ipv4.conf.all.log_martians" = "1"
          "net.ipv4.conf.default.log_martians" = "1"
        EOT

  min_size = 1
  max_size = 1
  # This value is ignored after the initial creation
  # https://github.com/bryantbiggs/eks-desired-size-hack
  desired_size = 1

}

module "eks_blueprints_addons" {
  depends_on = [module.eks_cluster, module.eks_managed_node_group]
  source     = "../../modules/eks-addons"

  cluster_name      = module.eks_cluster.cluster_name
  cluster_endpoint  = module.eks_cluster.cluster_endpoint
  cluster_version   = module.eks_cluster.cluster_version
  oidc_provider_arn = module.eks_cluster.oidc_provider_arn
}