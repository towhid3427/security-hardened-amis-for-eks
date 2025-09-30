# CIS Amazon Linux 2

This pattern provides a fully automated solution to create security-hardened Amazon EKS AL2 AMIs that comply with either CIS Level 1 or Level 2 standards.

## 🔢 Pre-requisites

1. (Mandatory) Create S3 for storing terraform state files and provide S3 Bucket name and region on file ``versions.tf``.
2. (Mandatory) Install [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).
3. (Mandatory) Install [Packer](https://developer.hashicorp.com/packer/tutorials/docker-get-started/get-started-install-cli).
4. (Mandatory) Subscribe to CIS AMIs from AWS Marketplaces :

For Level 1:

- [CIS Hardened Image Level 1 on Amazon Linux 2 Kernel 5.10](https://aws.amazon.com/marketplace/server/procurement?productId=abcfcbaf-134e-4639-a7b4-fd285b9fcf0a)

For Level 2:

- [CIS Amazon Linux 2 Benchmark - Level 2](https://aws.amazon.com/marketplace/server/procurement?productId=c41d38c4-3f6a-4434-9a86-06dd331d3f9c)

6. (Optional) For the static tests, install terraform-docs,tflint,checkov,pre-commit and mdl.

## 🚀 How to deploy

### Option 1: Use the guided approach by running the script on the root folder: ``create-hardened-ami.sh``.

or 

### Option 2: Create Complete Infrastructure

**Step 1.** Navigate to the CIS_AL2 pattern directory: `cd patterns/CIS_AL2`

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

**Step 1.** Navigate to the CIS_AL2 pattern directory: `cd patterns/CIS_AL2`

**Step 2.** Run `terraform destroy` to Terminate Resources

## 🕵️ How to access the EKS Cluster

Step 1. Create EKS Access Entry for your IAM User:

Through the AWS Console:

- Go to EKS Cluster created as part of the solution which is named CIS_AL2 on the AWS Region from the pipeline.
- Go to Access, Create Access Entry, Select your IAM Role from the list, Type: Standard, Click Next
- Add policy AmazonEKSClusterAdminPolicy *

Click in Next, then Create

Using AWS CLI:

```
#!/bin/bash
aws eks create-access-entry --cluster-name CIS_AL2 --principal-arn <value> --region <Region>
aws eks associate-access-policy --cluster-name CIS_AL2 --principal-arn <value> --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy --access-scope "type=cluster" --region <Region>
```

Regarding the Policy AmazonEKSClusterAdminPolicy:

"This access policy includes permissions that grant an IAM principal administrator access to a cluster. When associated to an access entry, its access scope is typically the cluster, rather than a Kubernetes namespace. If you want an IAM principal to have a more limited administrative scope, consider associating the AmazonEKSAdminPolicy access policy to your access entry instead."
References: <https://docs.aws.amazon.com/eks/latest/userguide/access-policy-permissions.html#access-policy-permissions-amazoneksclusteradminpolicy>

Step 2. You need to update your kubeconfig in order to run kubectl commands to the cluster

```
#!/bin/bash
aws eks update-kubeconfig --name CIS_AL2 --region <Region>
```

Then you can check nodes that joined the cluster and troubleshoot issues if required.

```#!/bin/bash
 kubectl get nodes -o wide
NAME                                        STATUS   ROLES    AGE    VERSION               INTERNAL-IP   EXTERNAL-IP   OS-IMAGE         KERNEL-VERSION                  CONTAINER-RUNTIME
ip-10-0-16-237.us-west-2.compute.internal   Ready    <none>   173m   v1.32.3-eks-473151a   10.0.16.237   <none>        Amazon Linux 2   5.10.237-230.948.amzn2.x86_64   containerd://1.7.27
ip-10-0-34-143.us-west-2.compute.internal   Ready    <none>   173m   v1.32.3-eks-473151a   10.0.34.143   <none>        Amazon Linux 2   5.10.237-230.948.amzn2.x86_64   containerd://1.7.27
```

Check if all the pods are running:

```#!/bin/bash
kubectl get pods -A
NAMESPACE     NAME                                  READY   STATUS    RESTARTS   AGE
kube-system   aws-node-chxxl                        2/2     Running   0          174m
kube-system   aws-node-zrp6f                        2/2     Running   0          174m
kube-system   coredns-579b75d955-226kc              1/1     Running   0          158m
kube-system   coredns-579b75d955-glct8              1/1     Running   0          158m
kube-system   ebs-csi-controller-6b88976559-8pt69   6/6     Running   0          158m
kube-system   ebs-csi-controller-6b88976559-fd5n2   6/6     Running   0          158m
kube-system   ebs-csi-node-hbzl7                    3/3     Running   0          158m
kube-system   ebs-csi-node-j9bgq                    3/3     Running   0          158m
kube-system   kube-proxy-7jpj9                      1/1     Running   0          174m
kube-system   kube-proxy-sbfpx                      1/1     Running   0          174m
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
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../modules/vpc | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ssm_parameter.cis_amazon_linux_2_benchmark_level_1](https://registry.terraform.io/providers/hashicorp/aws/6.14.1/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.cis_amazon_linux_2_benchmark_level_2](https://registry.terraform.io/providers/hashicorp/aws/6.14.1/docs/resources/ssm_parameter) | resource |
| [null_resource.create_hardened_ami_level_1](https://registry.terraform.io/providers/hashicorp/null/3.2.4/docs/resources/resource) | resource |
| [null_resource.create_hardened_ami_level_2](https://registry.terraform.io/providers/hashicorp/null/3.2.4/docs/resources/resource) | resource |
| [null_resource.only_create_hardened_ami_level_1](https://registry.terraform.io/providers/hashicorp/null/3.2.4/docs/resources/resource) | resource |
| [null_resource.only_create_hardened_ami_level_2](https://registry.terraform.io/providers/hashicorp/null/3.2.4/docs/resources/resource) | resource |
| [null_resource.run_cis_scan](https://registry.terraform.io/providers/hashicorp/null/3.2.4/docs/resources/resource) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/6.14.1/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/6.14.1/docs/data-sources/caller_identity) | data source |
| [aws_ssm_parameter.cis_amazon_linux_2_benchmark_level_1](https://registry.terraform.io/providers/hashicorp/aws/6.14.1/docs/data-sources/ssm_parameter) | data source |
| [aws_ssm_parameter.cis_amazon_linux_2_benchmark_level_2](https://registry.terraform.io/providers/hashicorp/aws/6.14.1/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region | `string` | `"us-west-2"` | no |
| <a name="input_branch"></a> [branch](#input\_branch) | EKS AMI Branch TAG | `string` | `"v20250920"` | no |
| <a name="input_cis_ami_name_level_1"></a> [cis\_ami\_name\_level\_1](#input\_cis\_ami\_name\_level\_1) | CIS AMI Name which will be use to Search the CIS AMI from Market Place | `string` | `"CIS Amazon Linux 2 Kernel 5.10 Benchmark - Level 1 - v08*"` | no |
| <a name="input_cis_ami_name_level_2"></a> [cis\_ami\_name\_level\_2](#input\_cis\_ami\_name\_level\_2) | CIS AMI Name which will be use to Search the CIS AMI from Market Place | `string` | `"CIS Amazon Linux 2 Kernel 5.10 Benchmark - Level 2 - v08*"` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | EKS Cluster Version | `string` | `"1.32"` | no |
| <a name="input_create_ami_level1"></a> [create\_ami\_level1](#input\_create\_ami\_level1) | Flag to create Level 1 Hardened AMI | `bool` | `false` | no |
| <a name="input_create_ami_level2"></a> [create\_ami\_level2](#input\_create\_ami\_level2) | Flag to create Level 2 Hardened AMI | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | Name Prefix | `string` | `"CIS_AL2"` | no |
| <a name="input_public_subnet_id"></a> [public\_subnet\_id](#input\_public\_subnet\_id) | Public subnet ID for AMI creation | `string` | `""` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
