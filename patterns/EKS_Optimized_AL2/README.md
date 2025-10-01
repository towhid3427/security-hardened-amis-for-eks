# EKS Optimized Amazon Linux 2

This pattern provides a fully automated solution to create security-hardened Amazon EKS AL2 AMIs that comply with either CIS Level 1 or Level 2 standards.

## 🔢 Pre-requisites

1. (Mandatory) Create S3 for storing terraform state files and provide S3 Bucket name and region on file ``versions.tf``.
2. (Mandatory) Install [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).
3. (Mandatory) Install [Packer](https://developer.hashicorp.com/packer/tutorials/docker-get-started/get-started-install-cli).
4. (Mandatory) Become a member of Center for Interner Security <https://www.cisecurity.org/>.

In order to download Build Kit scripts for Amazon Linux 2.
This scripts will be applied on top of EKS-Optimized AMIs.
More info on Technical details section below.

7. (Optional) For the static tests, install terraform-docs,tflint,checkov,pre-commit and mdl.

## 🚀 How to deploy

### Option 1: Use the guided approach by running the script on the root folder: ``create-hardened-ami.sh``.

or 

### Option 2: Create Complete Infrastructure

**Step 1.** Navigate to the EKS_Optimized_AL2 pattern directory: `cd patterns/EKS_Optimized_AL2`

**Step 2.** Follow steps from the section [CIS Scripts](##🔒-cis-cripts)

**Step 3.** Run `terraform init` ,`terraform plan` and `terraform apply` to deploy Complete Infrastructure using Terraform.
This will include:

- VPC and Subnets
- EKS Cluster 
- EKS managed node groups with EKS CIS Level1 and Level2 Hardened AMIs using EKS AMIs as a base AMI
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

**Step 1.** Navigate to the EKS_Optimized_AL2 pattern directory: `cd patterns/EKS_Optimized_AL2`

**Step 2.** Run `terraform destroy` to Terminate Resources

## Technical details

## 🔒 CIS Scripts

CIS scripts needs to be downloaded from the following website:
<https://www.cisecurity.org/cis-securesuite/cis-securesuite-build-kit-content>
In order to download the scripts, you need to be a CIS SecureSuite Member.

**Step 1.** Once you become a member, Click in "CIS WorkBench Sign In", and provide your username and password.

**Step 2.** Navigate to Benchmarks: <https://workbench.cisecurity.org/benchmarks>.

**Step 3.** Select "CIS Amazon Linux 2 Benchmark" v3.0.0.

**Step 4.** Go to Files on the left side.

**Step 5.** Select "CIS Amazon Linux 2 Benchmark v3.0.0 - Build Kit".

**Step 6.** Click in Latest Version on the right side, to Download amazon_linux_2.tar.gz file.

**Step 7.** unzip the file and store the content on the folder [cis-scripts](./patterns/EKS_Optimized_2/cis-scripts/).

**Step 8.**
Some changes need to be performed on the scripts in order to allow it to be executed from the pipeline.
Please find below detailed information about the changes.

Changes performed on CIS-LBK scripts:

1. Copied script `cis-scripts/CIS-LBK/cis_lbk_amazon_linux_2/amazon_linux_2.sh` to:

`cis-scripts/CIS-LBK/cis_lbk_amazon_linux_2/amazon_linux_2_level_1.sh` and configure it to run Level 1 Hardening only:
`run_profile=L1S`
on line 107.
and `cis-scripts/CIS-LBK/cis_lbk_amazon_linux_2/amazon_linux_2_level_2.sh` and configure it to run Level 2 Hardening only:
`run_profile=L2S`
on line 107.

2. add `mkdir $BDIR/logs` on Line 31 of `amazon_linux_2_level_1.sh` and `amazon_linux_2_level_2.sh` to create logs directory on the Instance

3. Disable prompt by commenting out on line 106

`#WARBNR`

4. Disable checks that can cause operational impact on the file `exclusion_list.txt`  

You need to add to the file the following checks:

```#txt
1.5.1.6 #Ensure no unconfined services exist
3.3.1 #Ensure IP forwarding is disabled
3.4.4.2.3 #Ensure iptables rules exist for all open ports
3.4.4.2.4 #Ensure iptables default deny firewall policy
3.4.4.3.3 #Ensure ip6tables firewall rules exist for all open ports
6.1.11 #Ensure world writable files and directories are secured
6.1.12 #Ensure no unowned or ungrouped files or directories exist
```

Please find below more information about why the above checks needs to be skipped on EKS:

## CIS Scan Results and Exceptions for failed controls

Some configuration changes required for Kubernetes operation override settings applied during hardening. Below are failed findings, possible reasons, and recommendations where available. Organizations can re-apply controls according to their security and compliance requirements, then re-test to confirm application functionality.

| CIS ID | CIS Description | Reason | Alternative control |
|---------|-----------------|---------|-------------------|
| 1.5.1.6 | Ensure no unconfined services exist | Processes flagged in these findings are container processes. | Investigate any unconfined processes. They may need to have an existing security context assigned to them or a policy built for them. https://docs.aws.amazon.com/eks/latest/best-practices/runtime-security.html |
| 3.3.1 | Ensure IP forwarding is disabled | IP forwarding is required by Kubernetes | N/A |
| 3.4.4.2.3 | Ensure iptables rules exist for all open ports | iptables are managed by kube-proxy | Please use network policies to manage communication between pods |
| 3.4.4.2.4 | Ensure iptables default deny firewall policy | iptables are managed by kube-proxy | Please use network policies to manage communication between pods |
| 3.4.4.3.3 | Ensure ip6tables firewall rules exist for all open ports | iptables are managed by kube-proxy | Please use network policies to manage communication between pods |
| 6.1.11 | Ensure world writable files and directories are secured | Directories used by containerd | This is the standard behavior of Kubernetes, you can get more background here: [kubernetes/kubernetes#76158](https://github.com/kubernetes/kubernetes/issues/76158) |
| 6.1.12 | Ensure no unowned or ungrouped files or directories exist | Directories used by containerd | This is the standard behavior of Kubernetes, you can get more background here: [kubernetes/kubernetes#76158](https://github.com/kubernetes/kubernetes/issues/76158) |

## 🧑🏿‍💻 Packer scripts

Packer scripts were created to apply CIS Scripts on top of EKS Optimized AMIS.
The file `packer-files/al2_amd64_level_1.pkrvars.hcl` has specific settings to EKS_Optimized_AL2_CIS_Benchmark_Level_1
and`packer-files/al2_amd64_level_2.pkrvars.hcl` has specific settings to EKS_Optimized_AL2_CIS_Benchmark_Level_2

`packer-files/amazon-eks.pkr.hcl` has the source,build and provisioner components for  the following AMIs:

- EKS_Optimized_AL2_CIS_Benchmark_Level_1
- EKS_Optimized_AL2_CIS_Benchmark_Level_2

## 🕵️ How to access the EKS Cluster

Step 1. Create EKS Access Entry for your IAM User:

Through the AWS Console:

- Go to EKS Cluster created as part of the solution which is named EKS_Optimized_AL2 on the AWS Region from the pipeline.
- Go to Access, Create Access Entry, Select your IAM Role from the list, Type: Standard, Click Next
- Add policy AmazonEKSClusterAdminPolicy *

Click in Next, then Create

Using AWS CLI:

```#!/bin/bash
aws eks create-access-entry --cluster-name EKS_Optimized_AL2 --principal-arn <value> --region <Region>
aws eks associate-access-policy --cluster-name EKS_Optimized_AL2 --principal-arn <value> --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy --access-scope "type=cluster" --region <Region>
```

Regarding the Policy AmazonEKSClusterAdminPolicy:

"This access policy includes permissions that grant an IAM principal administrator access to a cluster. When associated to an access entry, its access scope is typically the cluster, rather than a Kubernetes namespace. If you want an IAM principal to have a more limited administrative scope, consider associating the AmazonEKSAdminPolicy access policy to your access entry instead."
References: <https://docs.aws.amazon.com/eks/latest/userguide/access-policy-permissions.html#access-policy-permissions-amazoneksclusteradminpolicy>

Step 2. You need to update your kubeconfig in order to run kubectl commands to the cluster

```#!/bin/bash
aws eks update-kubeconfig --name EKS_Optimized_AL2 --region <Region>
```

Then you can check nodes that joined the cluster and troubleshoot issues if required.

```#!/bin/bash
kubectl get nodes -o wide
NAME                                        STATUS   ROLES    AGE     VERSION               INTERNAL-IP   EXTERNAL-IP   OS-IMAGE         KERNEL-VERSION                  CONTAINER-RUNTIME
ip-10-0-39-122.us-west-2.compute.internal   Ready    <none>   6m2s    v1.32.3-eks-473151a   10.0.39.122   <none>        Amazon Linux 2   5.10.236-228.935.amzn2.x86_64   containerd://1.7.27
ip-10-0-6-254.us-west-2.compute.internal    Ready    <none>   5m53s   v1.32.3-eks-473151a   10.0.6.254    <none>        Amazon Linux 2   5.10.236-228.935.amzn2.x86_64   containerd://1.7.27
```

Check if all the pods are running:

```#!/bin/bash
kubectl get pods -A
NAMESPACE     NAME                                 READY   STATUS    RESTARTS   AGE
kube-system   aws-node-2qczp                       2/2     Running   0          6m26s
kube-system   aws-node-5k47r                       2/2     Running   0          6m17s
kube-system   coredns-579b75d955-8wzrk             1/1     Running   0          5m
kube-system   coredns-579b75d955-lw4qt             1/1     Running   0          5m
kube-system   ebs-csi-controller-645d45577-7nw4v   6/6     Running   0          4m59s
kube-system   ebs-csi-controller-645d45577-tlczj   6/6     Running   0          4m59s
kube-system   ebs-csi-node-hjl7r                   3/3     Running   0          4m59s
kube-system   ebs-csi-node-rl9tt                   3/3     Running   0          4m59s
kube-system   kube-proxy-7hphm                     1/1     Running   0          6m17s
kube-system   kube-proxy-897jn                     1/1     Running   0          6m26s
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
| [aws_ssm_parameter.eks_optimized_al2_level_1](https://registry.terraform.io/providers/hashicorp/aws/6.14.1/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.eks_optimized_al2_level_2](https://registry.terraform.io/providers/hashicorp/aws/6.14.1/docs/resources/ssm_parameter) | resource |
| [null_resource.create_hardened_ami_level_1](https://registry.terraform.io/providers/hashicorp/null/3.2.4/docs/resources/resource) | resource |
| [null_resource.create_hardened_ami_level_2](https://registry.terraform.io/providers/hashicorp/null/3.2.4/docs/resources/resource) | resource |
| [null_resource.only_create_hardened_ami_level_1](https://registry.terraform.io/providers/hashicorp/null/3.2.4/docs/resources/resource) | resource |
| [null_resource.only_create_hardened_ami_level_2](https://registry.terraform.io/providers/hashicorp/null/3.2.4/docs/resources/resource) | resource |
| [null_resource.run_cis_scan](https://registry.terraform.io/providers/hashicorp/null/3.2.4/docs/resources/resource) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/6.14.1/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/6.14.1/docs/data-sources/caller_identity) | data source |
| [aws_ssm_parameter.eks_optimized_al2_level_1](https://registry.terraform.io/providers/hashicorp/aws/6.14.1/docs/data-sources/ssm_parameter) | data source |
| [aws_ssm_parameter.eks_optimized_al2_level_2](https://registry.terraform.io/providers/hashicorp/aws/6.14.1/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region | `string` | `"us-west-2"` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | EKS Cluster Version | `string` | `"1.32"` | no |
| <a name="input_create_ami_level1"></a> [create\_ami\_level1](#input\_create\_ami\_level1) | Flag to create Level 1 Hardened AMI | `bool` | `false` | no |
| <a name="input_create_ami_level2"></a> [create\_ami\_level2](#input\_create\_ami\_level2) | Flag to create Level 2 Hardened AMI | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | Name Prefix | `string` | `"EKS_Optimized_AL2"` | no |
| <a name="input_public_subnet_id"></a> [public\_subnet\_id](#input\_public\_subnet\_id) | Public subnet ID for AMI creation | `string` | `""` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
