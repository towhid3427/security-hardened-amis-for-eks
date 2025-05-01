# CIS Amazon Linux 2023

This pattern provides a fully automated solution to create security-hardened Amazon EKS AL2023 AMIs that comply with either CIS Level 1 or Level 2 standards.

## 🔢 Pre-requisites

1. (Mandatory) Create S3 for storing terraform state files and provide S3 Bucket name on file ``versions.tf`` and ``eks-cluster/versions.tf``.
2. (Mandatory) Update the region in the ``locals.tf``,``eks-cluster/locals.tf`` and on the ``Makefile`` file to specify where the solution should be deployed.
3. (Mandatory) Install make. make utility is almost universally pre-installed on most Linux distributions.
4. (Mandatory) Install [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).
5. (Mandatory) Install [Packer](https://developer.hashicorp.com/packer/tutorials/docker-get-started/get-started-install-cli).
6. (Mandatory) Subscribe to CIS AMIs from AWS Marketplaces :

For Level 1:

- [CIS Amazon Linux 2023 Benchmark - Level 1](https://aws.amazon.com/marketplace/pp/prodview-fqqp6ebucarnm?sr=0-11&ref_=beagle&applicationId=AWSMPContessa)

For Level 2:

- [CIS Amazon Linux 2023 - Level 2](https://aws.amazon.com/marketplace/pp/prodview-uis4wvkb7g3wq?sr=0-19&ref_=beagle&applicationId=AWSMPContessa)

7. (Optional) For the static tests, install terraform-docs,tflint,checkov,pre-commit and mdl.

## 🚀 How to deploy

**Step 1.** Navigate to the CIS_AL2 pattern directory: `cd patterns/CIS_AL2023`

**Step 2.** Run `make plan/apply` to deploy VPC resource using Terraform.

**Step 3.** Run `make create-hardened-ami` to Create EKS CIS Level1 and Level2 Hardened AMIs using CIS AMIs as a base AMI.

**Step 4.** Run `make cluster-plan/cluster-apply` to create EKS Cluster and create EKS managed node groups for each security-hardened Amazon EKS AMI as part of the same EKS Cluster. This also will deploy several different apps and add-ons and will run tests to see if the workload will run without issues.

**Step 5.** Run `make run-cis-scan` to trigger AWS Inspector CIS scans to scan EKS manages nodes and generate reports about checks which Passed, are Skipped or Failed.

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
ip-10-0-14-174.us-west-2.compute.internal   Ready    <none>   9m49s   v1.32.1-eks-5d632ec   10.0.14.174   <none>        Amazon Linux 2023.7.20250414   6.1.132-147.221.amzn2023.x86_64   containerd://1.7.27
ip-10-0-9-31.us-west-2.compute.internal     Ready    <none>   9m44s   v1.32.1-eks-5d632ec   10.0.9.31     <none>        Amazon Linux 2023.7.20250414   6.1.132-147.221.amzn2023.x86_64   containerd://1.7.27
```

Check if all the pods are running:

```#!/bin/bash
kubectl get pods -A
NAMESPACE     NAME                                  READY   STATUS    RESTARTS   AGE
kube-system   aws-node-b4m4k                        2/2     Running   0          10m
kube-system   aws-node-ch98h                        2/2     Running   0          10m
kube-system   coredns-599f7d65c5-gvqgt              1/1     Running   0          2m37s
kube-system   coredns-599f7d65c5-sbrlh              1/1     Running   0          2m37s
kube-system   ebs-csi-controller-64bc98789b-74v4z   6/6     Running   0          2m36s
kube-system   ebs-csi-controller-64bc98789b-8gnm9   6/6     Running   0          2m36s
kube-system   ebs-csi-node-kxlzt                    3/3     Running   0          2m36s
kube-system   ebs-csi-node-wvnr8                    3/3     Running   0          2m36s
kube-system   kube-proxy-84d9f                      1/1     Running   0          10m
kube-system   kube-proxy-bdmqs                      1/1     Running   0          10m
```

## Troubleshooting

Please refer to the [troubleshooting docs](../../docs/troubleshooting.md)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.96 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.96 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ./../modules/vpc | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.packer_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.packer_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.packer_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_ssm_parameter.cis_amazon_linux_2023_benchmark_level_1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.cis_amazon_linux_2023_benchmark_level_2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->
