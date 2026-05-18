################################################################################
# Local Values
################################################################################
locals {
  # Common tags applied to all resources for cost allocation, ownership tracking,
  # and resource discovery. Override or extend via var.additional_tags.
  common_tags = merge(
    {
      ManagedBy   = "Terraform"
      Pattern     = "EKS_Optimized_AL2023"
      Environment = var.environment
    },
    var.additional_tags
  )

  # AMI name prefix passed to Packer and used in the aws_ami filter.
  # Including var.name lets multiple deployments coexist without collision.
  ami_name_level_1 = "${var.name}_CIS_Benchmark_Level_1"
  ami_name_level_2 = "${var.name}_CIS_Benchmark_Level_2"
}

################################################################################
# VPC and Networking Resources
################################################################################
module "vpc" {
  source = "../modules/vpc"
  name   = var.name
  azs    = slice(data.aws_availability_zones.available.names, 0, 3)
  tags   = local.common_tags
}

################################################################################
# Create Hardened AMI EKS_Optimized_AL2023_Level_1
#
# Packer builds and tags the AMI; the aws_ami data source in data.tf reads it
# back via filter on the Name tag. No SSM placeholder is needed.
################################################################################
resource "null_resource" "create_hardened_ami_level_1" {
  depends_on = [module.vpc]
  triggers = {
    packer_file_sha1 = filesha1("${path.module}/packer-files/amazon-eks.pkr.hcl")
    aws_region       = var.aws_region
    name             = var.name
    ami_name         = local.ami_name_level_1
  }

  provisioner "local-exec" {
    working_dir = "${path.module}/packer-files"
    command     = <<-EOT
      set -euo pipefail
      packer init -upgrade .
      packer build -only 'eks_optimized_ami_al2023.*' \
        -var-file=al2023_amd64_level_1.pkrvars.hcl \
        -var "subnet_id=$SUBNET_ID" \
        -var "aws_region=$AWS_REGION" \
        -var "ami_name=$AMI_NAME" \
        .
      AMI_ID_Level_1=$(jq -r '(.builds | reverse[]) | select(.custom_data.hardened_ami_name | strings | contains("Level_1")) | .artifact_id | split(":")[1]' manifest.json | head -n1)
      echo "Built Level 1 AMI: $AMI_ID_Level_1"
    EOT
    environment = {
      AWS_REGION = var.aws_region
      SUBNET_ID  = module.vpc.public_subnets[0]
      AMI_NAME   = local.ami_name_level_1
    }
  }
}

################################################################################
# Create Hardened AMI EKS_Optimized_AL2023_Level_2
################################################################################
resource "null_resource" "create_hardened_ami_level_2" {
  depends_on = [module.vpc]
  triggers = {
    packer_file_sha1 = filesha1("${path.module}/packer-files/amazon-eks.pkr.hcl")
    aws_region       = var.aws_region
    name             = var.name
    ami_name         = local.ami_name_level_2
  }

  provisioner "local-exec" {
    working_dir = "${path.module}/packer-files"
    command     = <<-EOT
      set -euo pipefail
      packer init -upgrade .
      packer build -only 'eks_optimized_ami_al2023.*' \
        -var-file=al2023_amd64_level_2.pkrvars.hcl \
        -var "subnet_id=$SUBNET_ID" \
        -var "aws_region=$AWS_REGION" \
        -var "ami_name=$AMI_NAME" \
        .
      AMI_ID_Level_2=$(jq -r '(.builds | reverse[]) | select(.custom_data.hardened_ami_name | strings | contains("Level_2")) | .artifact_id | split(":")[1]' manifest.json | head -n1)
      echo "Built Level 2 AMI: $AMI_ID_Level_2"
    EOT
    environment = {
      AWS_REGION = var.aws_region
      SUBNET_ID  = module.vpc.public_subnets[0]
      AMI_NAME   = local.ami_name_level_2
    }
  }
}

################################################################################
# EKS Cluster
################################################################################
module "eks_cluster" {
  source          = "../modules/eks-cluster"
  depends_on      = [module.vpc]
  name            = var.name
  cluster_version = var.cluster_version
  tags            = local.common_tags
}

################################################################################
# EKS Managed Node Group For AL2023 CIS Level 1
################################################################################
module "eks_managed_node_group_level_1" {
  source     = "../modules/eks_managed_node_group"
  depends_on = [module.eks_cluster, null_resource.create_hardened_ami_level_1]

  name                              = "EKSOAL2023L1"
  cluster_name                      = module.eks_cluster.cluster_name
  cluster_version                   = module.eks_cluster.cluster_version
  kubernetes_version                = module.eks_cluster.cluster_version
  subnet_ids                        = module.vpc.private_subnets
  cluster_primary_security_group_id = module.eks_cluster.cluster_primary_security_group_id
  vpc_security_group_ids            = [module.eks_cluster.node_security_group_id]
  cluster_service_cidr              = module.eks_cluster.cluster_service_cidr
  ami_id                            = data.aws_ami.eks_optimized_al2023_level_1.id
  cluster_endpoint                  = module.eks_cluster.cluster_endpoint
  cluster_auth_base64               = module.eks_cluster.cluster_certificate_authority_data
  instance_types                    = var.instance_types
  capacity_type                     = var.capacity_type
  tags                              = merge(local.common_tags, { CISLevel = "Level_1" })
}

################################################################################
# EKS Managed Node Group For AL2023 CIS Level 2
################################################################################
module "eks_managed_node_group_level_2" {
  source     = "../modules/eks_managed_node_group"
  depends_on = [module.eks_cluster, null_resource.create_hardened_ami_level_2]

  name                              = "EKSOAL2023L2"
  cluster_name                      = module.eks_cluster.cluster_name
  cluster_version                   = module.eks_cluster.cluster_version
  kubernetes_version                = module.eks_cluster.cluster_version
  subnet_ids                        = module.vpc.private_subnets
  cluster_primary_security_group_id = module.eks_cluster.cluster_primary_security_group_id
  vpc_security_group_ids            = [module.eks_cluster.node_security_group_id]
  cluster_service_cidr              = module.eks_cluster.cluster_service_cidr
  ami_id                            = data.aws_ami.eks_optimized_al2023_level_2.id
  cluster_endpoint                  = module.eks_cluster.cluster_endpoint
  cluster_auth_base64               = module.eks_cluster.cluster_certificate_authority_data
  instance_types                    = var.instance_types
  capacity_type                     = var.capacity_type
  tags                              = merge(local.common_tags, { CISLevel = "Level_2" })
}

################################################################################
# EKS Add-ons
################################################################################
module "eks_blueprints_addons" {
  depends_on = [module.eks_cluster, module.eks_managed_node_group_level_1, module.eks_managed_node_group_level_2]
  source     = "../modules/eks-addons"

  cluster_name      = module.eks_cluster.cluster_name
  cluster_endpoint  = module.eks_cluster.cluster_endpoint
  cluster_version   = module.eks_cluster.cluster_version
  oidc_provider_arn = module.eks_cluster.oidc_provider_arn
  tags              = local.common_tags
}

################################################################################
# Run CIS SCAN AWS Inspector
#
# Triggers are tied to meaningful state (node group identities) rather than
# timestamp() so the scan only re-runs when the thing being scanned actually
# changes. To force an ad-hoc scan, taint the resource:
#   terraform apply -replace=null_resource.run_cis_scan
################################################################################
resource "null_resource" "run_cis_scan" {
  depends_on = [module.eks_managed_node_group_level_1, module.eks_managed_node_group_level_2]
  triggers = {
    cluster_name     = var.name
    node_group_id_l1 = module.eks_managed_node_group_level_1.node_group_id
    node_group_id_l2 = module.eks_managed_node_group_level_2.node_group_id
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail
      echo "Initiating CIS scan using AWS Inspector..."
      echo "Account ID: $ACCOUNT_ID"
      SCAN_ARN=$(aws inspector2 create-cis-scan-configuration \
        --scan-name "$RESOURCE_NAME" \
        --schedule "oneTime={}" \
        --security-level LEVEL_2 \
        --targets "accountIds=$ACCOUNT_ID,targetResourceTags={eks:cluster-name=$RESOURCE_NAME}" \
        --region "$AWS_REGION" \
        --query 'scanArn' \
        --output text)

      if [ -z "$SCAN_ARN" ]; then
        echo "Error: Failed to create CIS scan configuration"
        exit 1
      fi

      echo "Successfully created CIS scan"
    EOT
    environment = {
      AWS_REGION    = var.aws_region
      RESOURCE_NAME = var.name
      ACCOUNT_ID    = data.aws_caller_identity.current.account_id
    }
  }
}

################################################################################
# Standalone AMI-only builds
#
# These resources build hardened AMIs WITHOUT creating a VPC or EKS cluster.
# Use them when you only want to produce an AMI for use elsewhere, e.g.:
#
#   terraform apply -var=create_ami_level1=true \
#                   -var=public_subnet_id=subnet-abc123 \
#                   -target=null_resource.only_create_hardened_ami_level_1
#
# Both create_ami_levelN and a valid public_subnet_id must be supplied. The
# AMI ends up in ECR with the same name pattern as the inline build path, so
# the data.aws_ami.* filters resolve it the same way.
################################################################################

resource "null_resource" "only_create_hardened_ami_level_1" {
  count = var.create_ami_level1 ? 1 : 0

  triggers = {
    packer_file_sha1 = filesha1("${path.module}/packer-files/amazon-eks.pkr.hcl")
    aws_region       = var.aws_region
    name             = var.name
    ami_name         = local.ami_name_level_1
    subnet_id        = var.public_subnet_id
  }

  provisioner "local-exec" {
    working_dir = "${path.module}/packer-files"
    command     = <<-EOT
      set -euo pipefail
      if [ -z "$SUBNET_ID" ]; then
        echo "Error: public_subnet_id must be provided for AMI-only builds."
        exit 1
      fi
      packer init -upgrade .
      packer build -only 'eks_optimized_ami_al2023.*' \
        -var-file=al2023_amd64_level_1.pkrvars.hcl \
        -var "subnet_id=$SUBNET_ID" \
        -var "aws_region=$AWS_REGION" \
        -var "ami_name=$AMI_NAME" \
        .
      AMI_ID_Level_1=$(jq -r '(.builds | reverse[]) | select(.custom_data.hardened_ami_name | strings | contains("Level_1")) | .artifact_id | split(":")[1]' manifest.json | head -n1)
      echo "Built Level 1 AMI: $AMI_ID_Level_1"
    EOT
    environment = {
      AWS_REGION = var.aws_region
      SUBNET_ID  = var.public_subnet_id
      AMI_NAME   = local.ami_name_level_1
    }
  }
}

resource "null_resource" "only_create_hardened_ami_level_2" {
  count = var.create_ami_level2 ? 1 : 0

  triggers = {
    packer_file_sha1 = filesha1("${path.module}/packer-files/amazon-eks.pkr.hcl")
    aws_region       = var.aws_region
    name             = var.name
    ami_name         = local.ami_name_level_2
    subnet_id        = var.public_subnet_id
  }

  provisioner "local-exec" {
    working_dir = "${path.module}/packer-files"
    command     = <<-EOT
      set -euo pipefail
      if [ -z "$SUBNET_ID" ]; then
        echo "Error: public_subnet_id must be provided for AMI-only builds."
        exit 1
      fi
      packer init -upgrade .
      packer build -only 'eks_optimized_ami_al2023.*' \
        -var-file=al2023_amd64_level_2.pkrvars.hcl \
        -var "subnet_id=$SUBNET_ID" \
        -var "aws_region=$AWS_REGION" \
        -var "ami_name=$AMI_NAME" \
        .
      AMI_ID_Level_2=$(jq -r '(.builds | reverse[]) | select(.custom_data.hardened_ami_name | strings | contains("Level_2")) | .artifact_id | split(":")[1]' manifest.json | head -n1)
      echo "Built Level 2 AMI: $AMI_ID_Level_2"
    EOT
    environment = {
      AWS_REGION = var.aws_region
      SUBNET_ID  = var.public_subnet_id
      AMI_NAME   = local.ami_name_level_2
    }
  }
}
