# Bottlerocket

This pattern provides a fully automated solution to create security-hardened Amazon EKS Bottlerocket AMIs that comply with Level 2 standards.
Please note, Bottlerocket AMI is CIS Level 1 certified out of the box:
"Amazon Web Services’s Bottlerocket has been certified by the Center for Internet Security® (CIS®) to ship secure as hardened to CIS Bottlerocket Benchmark v1.0.0. Organizations that leverage Bottlerocket can now be assured that it will successfully run on a CIS hardened environment."

References: <https://aws.amazon.com/bottlerocket/>

## 🔢 Pre-requisites

1. (Mandatory) Create S3 for storing terraform state files and provide S3 Bucket name and region on file ``versions.tf``.
2. (Mandatory) Install [Docker](https://docs.docker.com/engine/install/).
3. (Mandatory) Install [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).
4. (Optional) For the static tests, install terraform-docs,tflint,checkov,pre-commit and mdl.

## 🚀 How to deploy

### Option 1: Use the guided approach by running the script on the root folder: ``create-hardened-ami.sh``.

or 

### Option 2: Create Complete Infrastructure

**Step 1.** Navigate to the Bottlerocket pattern directory: `cd patterns/BOTTLEROCKET`

**Step 2.** Run `terraform init` ,`terraform plan` and `terraform apply` to deploy Complete Infrastructure using Terraform.
This will include:

- VPC and Subnets
- EKS Cluster 
- EKS managed node groups with hardened AMI
- Deploy several different add-ons to check if the workload will run without issues.
- Trigger AWS Inspector CIS scans to scan EKS manages nodes and generate reports about checks which Passed, are Skipped or Failed.

or 

### Option 3: Create Only CIS Bootstrape Image

```
terraform init
```

and

```
terraform plan \
    -var="cis_bootstrape_image=true" \
    -var="aws_region=$aws_region" \
    -target=null_resource.docker_build_push-image-only
```

and

```
terraform apply \
    -var="cis_bootstrape_image=true" \
    -var="aws_region=$aws_region" \
    -target=null_resource.docker_build_push-image-only \
    --auto-approve
```

## 🧹 How to terminate resources

**Step 1.** Navigate to the Bottlerocket pattern directory: `cd patterns/BOTTLEROCKET`

**Step 2.** Run `terraform destroy` to Terminate Resources

## 🕵️ How to access the EKS Cluster

Step 1. Create EKS Access Entry for your IAM User:

Through the AWS Console:

- Go to EKS Cluster created as part of the solution which is named BOTTLEROCKET on the AWS Region from the pipeline.
- Go to Access, Create Access Entry, Select your IAM Role from the list, Type: Standard, Click Next
- Add policy AmazonEKSClusterAdminPolicy *

Click in Next, then Create

Using AWS CLI:

```
#!/bin/bash
aws eks create-access-entry --cluster-name BOTTLEROCKET --principal-arn <value> --region <Region>
aws eks associate-access-policy --cluster-name BOTTLEROCKET --principal-arn <value> --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy --access-scope "type=cluster" --region <Region>
```

Regarding the Policy AmazonEKSClusterAdminPolicy:

"This access policy includes permissions that grant an IAM principal administrator access to a cluster. When associated to an access entry, its access scope is typically the cluster, rather than a Kubernetes namespace. If you want an IAM principal to have a more limited administrative scope, consider associating the AmazonEKSAdminPolicy access policy to your access entry instead."
References: <https://docs.aws.amazon.com/eks/latest/userguide/access-policy-permissions.html#access-policy-permissions-amazoneksclusteradminpolicy>

Step 2. You need to update your kubeconfig in order to run kubectl commands to the cluster

```
#!/bin/bash
aws eks update-kubeconfig --name BOTTLEROCKET --region <Region>
```

Then you can check nodes that joined the cluster and troubleshoot issues if required.

```
#!/bin/bash
kubectl get nodes -o wide
NAME                                       STATUS   ROLES    AGE     VERSION               INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                                KERNEL-VERSION   CONTAINER-RUNTIME
ip-10-0-5-251.us-west-2.compute.internal   Ready    <none>   3m53s   v1.35.0-eks-ac2d5a0   10.0.5.251    <none>        Bottlerocket OS 1.56.0 (aws-k8s-1.35)   6.12.68          containerd://2.1.6+bottlerocket
```

Check if all the pods are running:

```
#!/bin/bash
kubectl get pods -A
NAMESPACE     NAME                                  READY   STATUS    RESTARTS   AGE
kube-system   aws-node-8h54b                        2/2     Running   0          4m30s
kube-system   coredns-74d7449c-6c6kx                1/1     Running   0          2m55s
kube-system   coredns-74d7449c-dw74t                1/1     Running   0          2m55s
kube-system   ebs-csi-controller-64d4cbb6f8-klw2c   6/6     Running   0          2m55s
kube-system   ebs-csi-controller-64d4cbb6f8-msxw5   6/6     Running   0          2m55s
kube-system   ebs-csi-node-th5cv                    3/3     Running   0          2m55s
kube-system   kube-proxy-7lddw                      1/1     Running   0          4m30s
```

## Troubleshooting

Please refer to the [troubleshooting docs](../../docs/troubleshooting.md)

<!-- BEGIN_TF_DOCS -->
## Providers

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | 6.35.1 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | 2.17.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | 2.38.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | 3.2.4 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_eks_blueprints_addons"></a> [eks\_blueprints\_addons](#module\_eks\_blueprints\_addons) | ../modules/eks-addons | n/a |
| <a name="module_eks_cluster"></a> [eks\_cluster](#module\_eks\_cluster) | ../modules/eks-cluster | n/a |
| <a name="module_eks_managed_node_group_level_2"></a> [eks\_managed\_node\_group\_level\_2](#module\_eks\_managed\_node\_group\_level\_2) | ../modules/eks_managed_node_group | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../modules/vpc | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ecr_repository.bottlerocket_cis_bootstrap_image](https://registry.terraform.io/providers/hashicorp/aws/6.35.1/docs/resources/ecr_repository) | resource |
| [null_resource.docker_build_push](https://registry.terraform.io/providers/hashicorp/null/3.2.4/docs/resources/resource) | resource |
| [null_resource.docker_build_push_image_only](https://registry.terraform.io/providers/hashicorp/null/3.2.4/docs/resources/resource) | resource |
| [null_resource.run_cis_scan](https://registry.terraform.io/providers/hashicorp/null/3.2.4/docs/resources/resource) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/6.35.1/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/6.35.1/docs/data-sources/caller_identity) | data source |
| [aws_ssm_parameter.bottlerocket_ami](https://registry.terraform.io/providers/hashicorp/aws/6.35.1/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region | `string` | `"us-west-2"` | no |
| <a name="input_cis_bootstrape_image"></a> [cis\_bootstrape\_image](#input\_cis\_bootstrape\_image) | Flag to create CIS Hardened Bootstrap Image | `bool` | `false` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | EKS Cluster Version | `string` | `"1.35"` | no |
| <a name="input_ecr_repository_name"></a> [ecr\_repository\_name](#input\_ecr\_repository\_name) | ECR Repository Name | `string` | `"bottlerocket-cis-bootstrap-image"` | no |
| <a name="input_image_tag"></a> [image\_tag](#input\_image\_tag) | CIS Level 2 Bootstrape Image Tag | `string` | `"latest"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name Prefix | `string` | `"BOTTLEROCKET"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
