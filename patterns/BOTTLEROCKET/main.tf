################################################################################
# VPC and Networking Resources
################################################################################
module "vpc" {
  source = "../modules/vpc"
  name   = var.name
  azs    = slice(data.aws_availability_zones.available.names, 0, 3)
}

################################################################################
# Create ECR Repository for CIS Bootstrap Image
################################################################################
resource "aws_ecr_repository" "bottlerocket_cis_bootstrap_image" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "IMMUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  encryption_configuration {
    encryption_type = "KMS"
  }
  force_delete = true
}

################################################################################
# Build and Push Bottlerocket CIS Bootstrap Image to ECR
################################################################################
locals {
  # Content-hash tag: changes only when the Dockerfile changes.
  # Keeps ECR repo IMMUTABLE while avoiding "latest" anti-pattern.
  dockerfile_hash = filemd5("${path.module}/bottlerocket-cis-bootstrap-image/Dockerfile")
  image_tag      = var.image_tag != "" ? var.image_tag : local.dockerfile_hash
}

resource "null_resource" "docker_build_push" {
  triggers = {
    docker_file = local.dockerfile_hash
    aws_region  = var.aws_region
    image_tag   = local.image_tag
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail
      cd "$BUILD_CONTEXT_DIR"
      DOCKER_BUILDKIT=1 docker build \
        --build-arg BUILDKIT_INLINE_CACHE=1 \
        --cache-from "$ECR_REPO_URL:$IMAGE_TAG" \
        --tag "$ECR_REPO_NAME:$IMAGE_TAG" \
        --tag "$ECR_REPO_URL:$IMAGE_TAG" \
        --progress=plain \
        .
      aws ecr get-login-password --region "$AWS_REGION" | \
        docker login --username AWS --password-stdin "$ECR_REPO_URL"
      docker push "$ECR_REPO_URL:$IMAGE_TAG"
    EOT
    environment = {
      AWS_REGION        = var.aws_region
      ECR_REPO_URL      = aws_ecr_repository.bottlerocket_cis_bootstrap_image.repository_url
      ECR_REPO_NAME     = var.ecr_repository_name
      IMAGE_TAG         = local.image_tag
      BUILD_CONTEXT_DIR = "${path.module}/bottlerocket-cis-bootstrap-image"
    }
  }

  depends_on = [aws_ecr_repository.bottlerocket_cis_bootstrap_image]
}

################################################################################
# EKS Cluster
################################################################################
module "eks_cluster" {
  source          = "../modules/eks-cluster"
  depends_on      = [module.vpc, null_resource.docker_build_push]
  name            = var.name
  cluster_version = var.cluster_version
}

################################################################################
# EKS Managed Node Group Modules For CIS Bottlerocket
################################################################################
module "eks_managed_node_group_level_2" {
  source = "../modules/eks_managed_node_group"
  depends_on = [module.eks_cluster,
  null_resource.docker_build_push]

  name                              = "BOTTLEROCKETL2"
  cluster_name                      = module.eks_cluster.cluster_name
  cluster_version                   = module.eks_cluster.cluster_version
  kubernetes_version                = module.eks_cluster.cluster_version
  subnet_ids                        = module.vpc.private_subnets
  cluster_primary_security_group_id = module.eks_cluster.cluster_primary_security_group_id
  vpc_security_group_ids            = [module.eks_cluster.node_security_group_id]
  cluster_service_cidr              = module.eks_cluster.cluster_service_cidr
  ami_id                            = data.aws_ssm_parameter.bottlerocket_ami.value
  ami_type                          = "BOTTLEROCKET_x86_64"
  cluster_endpoint                  = module.eks_cluster.cluster_endpoint
  cluster_auth_base64               = module.eks_cluster.cluster_certificate_authority_data
  bootstrap_extra_args              = <<-EOT
          [settings.bootstrap-containers.cis-bootstrap]
          source = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.ecr_repository_name}:${local.image_tag}"
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
}

################################################################################
# EKS Add-ons
################################################################################
module "eks_blueprints_addons" {
  depends_on = [module.eks_cluster, module.eks_managed_node_group_level_2]
  source     = "../modules/eks-addons"

  cluster_name      = module.eks_cluster.cluster_name
  cluster_endpoint  = module.eks_cluster.cluster_endpoint
  cluster_version   = module.eks_cluster.cluster_version
  oidc_provider_arn = module.eks_cluster.oidc_provider_arn
}
