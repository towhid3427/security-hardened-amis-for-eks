
################################################################################
# VPC
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.2.0"
  name = var.name
  cidr = var.cidr

  azs             = var.azs
  private_subnets = [for k, v in var.azs : cidrsubnet(var.cidr, 4, k)]
  public_subnets  = [for k, v in var.azs : cidrsubnet(var.cidr, 8, k + 48)]
  intra_subnets   = [for k, v in var.azs : cidrsubnet(var.cidr, 8, k + 52)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = var.tags
}