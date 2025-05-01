# Bottlerocket

This pattern provides a fully automated solution to create security-hardened Amazon EKS Bottlerocket AMIs that comply with Level 2 standards.
Please note, Bottlerocket AMI is CIS Level 1 certified out of the box:
"Amazon Web Services’s Bottlerocket has been certified by the Center for Internet Security® (CIS®) to ship secure as hardened to CIS Bottlerocket Benchmark v1.0.0. Organizations that leverage Bottlerocket can now be assured that it will successfully run on a CIS hardened environment."

References: <https://aws.amazon.com/bottlerocket/>

## 🔢 Pre-requisites

1. (Mandatory) Create S3 for storing terraform state files and provide S3 Bucket name on file ``versions.tf`` and ``eks-cluster/versions.tf``
2. (Mandatory) Ensure you provide the correct region where the bucket was created on ``locals.tf``, ``eks-cluster/locals.tf`` and on ``Makefile``
3. (Mandatory) Install [Docker](https://docs.docker.com/engine/install/).
4. (Mandatory) Install Make. make utility is almost universally pre-installed on most Linux distributions.
5. (Mandatory) Install [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).
6. (Optional) For the static tests, install terraform-docs,tflint,checkov,pre-commit and mdl.

## 🚀 How to deploy

**Step 1.** Navigate to the Bottlerocket pattern directory: `cd patterns/BOTTLEROCKET`

**Step 2.** Run `make plan/apply` to deploy VPC resource using Terraform.

**Step 3.** Run `make build-bottlerocket-cis-bootstrap-image` to build and push CIS bootstrap image.

**Step 4.** Run `make cluster-plan/cluster-apply` to create EKS Cluster and create EKS managed node groups for each security-hardened Amazon EKS AMI as part of the same EKS Cluster. This also will deploy several different apps and add-ons and will run tests to see if the workload will run without issues.

**Step 5.** Run `make run-cis-scan` to trigger AWS Inspector CIS scans to scan EKS manages nodes and generate reports about checks which Passed, are Skipped or Failed.

## 🧹 How to terminate resources

**Step 1.** Navigate to the Bottlerocket pattern directory: `cd patterns/BOTTLEROCKET`

**Step 2.** Run `make clean` to Terminate Resources

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
NAME                                       STATUS   ROLES    AGE   VERSION               INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                                KERNEL-VERSION   CONTAINER-RUNTIME
ip-10-0-7-108.us-west-2.compute.internal   Ready    <none>   23m   v1.32.2-eks-677bac1   10.0.7.108    <none>        Bottlerocket OS 1.37.0 (aws-k8s-1.32)   6.1.132          containerd://1.7.27+bottlerocket
```

Check if all the pods are running:

```
#!/bin/bash
kubectl get pods -A
NAMESPACE     NAME                                  READY   STATUS    RESTARTS   AGE
kube-system   aws-node-cptq4                        2/2     Running   0          23m
kube-system   coredns-5594d78cdc-2f7nb              1/1     Running   0          2m36s
kube-system   coredns-5594d78cdc-t9wk4              1/1     Running   0          3m42s
kube-system   ebs-csi-controller-74fb8f9946-jj4n2   6/6     Running   0          6m40s
kube-system   ebs-csi-controller-74fb8f9946-qsxkn   6/6     Running   0          2m36s
kube-system   ebs-csi-node-lfpjl                    3/3     Running   0          23m
kube-system   kube-proxy-mlhbj                      1/1     Running   0          23m
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
| [aws_ecr_repository.bottlerocket_cis_bootstrap_image](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->
