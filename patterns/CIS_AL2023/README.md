# CIS Amazon Linux 2023

This pattern provides a fully automated solution to create security-hardened Amazon EKS AL2023 AMIs that comply with either CIS Level 1 or Level 2 standards.

## 🔢 Pre-requisites

1. (Mandatory) Create S3 for storing terraform state files and provide S3 Bucket name and region on file ``versions.tf``.
2. (Mandatory) Install [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).
3. (Mandatory) Install [Packer](https://developer.hashicorp.com/packer/tutorials/docker-get-started/get-started-install-cli).
4. (Mandatory) Subscribe to CIS AMIs from AWS Marketplaces :

For Level 1:

- [CIS Amazon Linux 2023 Benchmark - Level 1](https://aws.amazon.com/marketplace/pp/prodview-fqqp6ebucarnm?sr=0-11&ref_=beagle&applicationId=AWSMPContessa)

For Level 2:

- [CIS Amazon Linux 2023 - Level 2](https://aws.amazon.com/marketplace/pp/prodview-uis4wvkb7g3wq?sr=0-19&ref_=beagle&applicationId=AWSMPContessa)

7. (Optional) For the static tests, install terraform-docs,tflint,checkov,pre-commit and mdl.

## 🚀 How to deploy

### Option 1: Use the guided approach by running the script on the root folder: ``create-hardened-ami.sh``.

or 

### Option 2: Create Complete Infrastructure
**Step 1.** Navigate to the CIS_AL2023 pattern directory: `cd patterns/CIS_AL2023`

**Step 2.** Run `terraform init` ,`terraform plan` and `terraform apply` to deploy Complete Infrastructure using Terraform.
This will include:

- VPC and Subnets
- EKS Cluster 
- EKS managed node groups with EKS CIS Level1 and Level2 Hardened AMIs using CIS AMIs as a base AMI
- Deploy several different add-ons to check if the workload will run without issues.
- Trigger AWS Inspector CIS scans to scan EKS manages nodes and generate reports about checks which Passed, are Skipped or Failed.

or 

### Option 3: Create Only Hardened AMIs

  1. CIS Level 1
```
terraform init
```
and
``` 
terraform plan \
  -var="create_ami_level1=true" \
  -var="public_subnet_id=$subnet_id" \
  -var="aws_region=$aws_region" \
  -target=null_resource.only_create_hardened_ami_level_1
```
and
```
terraform apply \
  -var="create_ami_level1=true" \
  -var="public_subnet_id=$subnet_id" \
  -var="aws_region=$aws_region" \
  -target=null_resource.only_create_hardened_ami_level_1 \
  --auto-approve
```

 2. CIS Level 2
 
```
terraform init
```
and

```     
terraform plan \
  -var="create_ami_level2=true" \
  -var="public_subnet_id=$subnet_id" \
  -var="aws_region=$aws_region" \
  -target=null_resource.only_create_hardened_ami_level_2
```

and

```
terraform apply \
  -var="create_ami_level2=true" \
  -var="public_subnet_id=$subnet_id" \
  -var="aws_region=$aws_region" \
  -target=null_resource.only_create_hardened_ami_level_2 \
  --auto-approve
```

3. Both Level 1 and Level 2

```
terraform init
```

and

```
terraform plan \
  -var="create_ami_level1=true" \
  -var="create_ami_level2=true" \
  -var="public_subnet_id=$subnet_id" \
  -var="aws_region=$aws_region" \
  -target=null_resource.only_create_hardened_ami_level_1 \
  -target=null_resource.only_create_hardened_ami_level_2
```

and

```
terraform apply \
  -var="create_ami_level1=true" \
  -var="create_ami_level2=true" \
  -var="public_subnet_id=$subnet_id" \
  -var="aws_region=$aws_region" \
  -target=null_resource.only_create_hardened_ami_level_1 \
  -target=null_resource.only_create_hardened_ami_level_2 \
  --auto-approve
```

## 🧹 How to terminate resources

**Step 1.** Navigate to the CIS_AL2 pattern directory: `cd patterns/CIS_AL2023`

**Step 2.** Run `make clean` to Terminate Resources

## 🕵️ How to access the EKS Cluster

Step 1. Create EKS Access Entry for your IAM User:

Through the AWS Console:

- Go to EKS Cluster created as part of the solution which is named CIS_AL2023 on the AWS Region from the pipeline.
- Go to Access, Create Access Entry, Select your IAM Role from the list, Type: Standard, Click Next
- Add policy AmazonEKSClusterAdminPolicy *

Click in Next, then Create

Using AWS CLI:

```#!/bin/bash
aws eks create-access-entry --cluster-name CIS_AL2023 --principal-arn <value> --region <Region>
aws eks associate-access-policy --cluster-name CIS_AL2023 --principal-arn <value> --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy --access-scope "type=cluster" --region <Region>
```

Regarding the Policy AmazonEKSClusterAdminPolicy:

"This access policy includes permissions that grant an IAM principal administrator access to a cluster. When associated to an access entry, its access scope is typically the cluster, rather than a Kubernetes namespace. If you want an IAM principal to have a more limited administrative scope, consider associating the AmazonEKSAdminPolicy access policy to your access entry instead."
References: <https://docs.aws.amazon.com/eks/latest/userguide/access-policy-permissions.html#access-policy-permissions-amazoneksclusteradminpolicy>

Step 2. You need to update your kubeconfig in order to run kubectl commands to the cluster

```#!/bin/bash
aws eks update-kubeconfig --name CIS_AL2023 --region <Region>
```

Then you can check nodes that joined the cluster and troubleshoot issues if required.

```#!/bin/bash
kubectl get nodes -o wide
NAME                                        STATUS   ROLES    AGE     VERSION               INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                       KERNEL-VERSION                    CONTAINER-RUNTIME
ip-10-0-1-245.us-west-2.compute.internal    Ready    <none>   6m52s   v1.33.0-eks-802817d   10.0.1.245    <none>        Amazon Linux 2023.7.20250512   6.1.134-152.225.amzn2023.x86_64   containerd://1.7.27
ip-10-0-17-105.us-west-2.compute.internal   Ready    <none>   6m57s   v1.33.0-eks-802817d   10.0.17.105   <none>        Amazon Linux 2023.7.20250512   6.1.134-152.225.amzn2023.x86_64   containerd://1.7.27
```

Check if all the pods are running:

```#!/bin/bash
kubectl get pods -A
NAMESPACE     NAME                                  READY   STATUS    RESTARTS   AGE
kube-system   aws-node-bpjt7                        2/2     Running   0          7m38s
kube-system   aws-node-rwwbp                        2/2     Running   0          7m33s
kube-system   coredns-7bf648ff5d-9txkc              1/1     Running   0          12m
kube-system   coredns-7bf648ff5d-z9ksc              1/1     Running   0          12m
kube-system   ebs-csi-controller-6f76679c5d-5tbrg   6/6     Running   0          5m58s
kube-system   ebs-csi-controller-6f76679c5d-v87vq   6/6     Running   0          5m58s
kube-system   ebs-csi-node-pzrhz                    3/3     Running   0          5m58s
kube-system   ebs-csi-node-tkklq                    3/3     Running   0          5m58s
kube-system   kube-proxy-t6rjv                      1/1     Running   0          7m33s
kube-system   kube-proxy-xr2b2                      1/1     Running   0          7m38s
```

## Troubleshooting

Please refer to the [troubleshooting docs](../../docs/troubleshooting.md)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 6.14.1 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | 2.17.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | 2.38.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | 3.2.4 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.14.1 |
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.4 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eks_blueprints_addons"></a> [eks\_blueprints\_addons](#module\_eks\_blueprints\_addons) | ../modules/eks-addons | n/a |
| <a name="module_eks_cluster"></a> [eks\_cluster](#module\_eks\_cluster) | ../modules/eks-cluster | n/a |
| <a name="module_eks_managed_node_group_level_1"></a> [eks\_managed\_node\_group\_level\_1](#module\_eks\_managed\_node\_group\_level\_1) | ../modules/eks_managed_node_group | n/a |
| <a name="module_eks_managed_node_group_level_2"></a> [eks\_managed\_node\_group\_level\_2](#module\_eks\_managed\_node\_group\_level\_2) | ../modules/eks_managed_node_group | n/a |
| <a name="module_packer_role"></a> [packer\_role](#module\_packer\_role) | ../modules/packer-role | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../modules/vpc | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ssm_parameter.cis_amazon_linux_2023_benchmark_level_1](https://registry.terraform.io/providers/hashicorp/aws/6.14.1/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.cis_amazon_linux_2023_benchmark_level_2](https://registry.terraform.io/providers/hashicorp/aws/6.14.1/docs/resources/ssm_parameter) | resource |
| [null_resource.create_hardened_ami_level_1](https://registry.terraform.io/providers/hashicorp/null/3.2.4/docs/resources/resource) | resource |
| [null_resource.create_hardened_ami_level_2](https://registry.terraform.io/providers/hashicorp/null/3.2.4/docs/resources/resource) | resource |
| [null_resource.only_create_hardened_ami_level_1](https://registry.terraform.io/providers/hashicorp/null/3.2.4/docs/resources/resource) | resource |
| [null_resource.only_create_hardened_ami_level_2](https://registry.terraform.io/providers/hashicorp/null/3.2.4/docs/resources/resource) | resource |
| [null_resource.run_cis_scan](https://registry.terraform.io/providers/hashicorp/null/3.2.4/docs/resources/resource) | resource |
| [null_resource.update_template](https://registry.terraform.io/providers/hashicorp/null/3.2.4/docs/resources/resource) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/6.14.1/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/6.14.1/docs/data-sources/caller_identity) | data source |
| [aws_ssm_parameter.cis_amazon_linux_2023_benchmark_level_1](https://registry.terraform.io/providers/hashicorp/aws/6.14.1/docs/data-sources/ssm_parameter) | data source |
| [aws_ssm_parameter.cis_amazon_linux_2023_benchmark_level_2](https://registry.terraform.io/providers/hashicorp/aws/6.14.1/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region | `string` | `"us-west-2"` | no |
| <a name="input_branch"></a> [branch](#input\_branch) | EKS AMI Branch TAG | `string` | `"v20250920"` | no |
| <a name="input_cis_ami_name_level_1"></a> [cis\_ami\_name\_level\_1](#input\_cis\_ami\_name\_level\_1) | CIS AMI Name which will be use to Search the CIS AMI from Market Place | `string` | `"CIS Amazon Linux 2023 Benchmark - Level 1 - v08*"` | no |
| <a name="input_cis_ami_name_level_2"></a> [cis\_ami\_name\_level\_2](#input\_cis\_ami\_name\_level\_2) | CIS AMI Name which will be use to Search the CIS AMI from Market Place | `string` | `"CIS Amazon Linux 2023 Benchmark - Level 2 - v08*"` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | EKS Cluster Version | `string` | `"1.33"` | no |
| <a name="input_create_ami_level1"></a> [create\_ami\_level1](#input\_create\_ami\_level1) | Flag to create Level 1 Hardened AMI | `bool` | `false` | no |
| <a name="input_create_ami_level2"></a> [create\_ami\_level2](#input\_create\_ami\_level2) | Flag to create Level 2 Hardened AMI | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | Name Prefix | `string` | `"CIS_AL2023"` | no |
| <a name="input_public_subnet_id"></a> [public\_subnet\_id](#input\_public\_subnet\_id) | Public subnet ID for AMI creation | `string` | `""` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
