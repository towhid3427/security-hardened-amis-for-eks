# EKS Optimized AL2023

This pattern provides a fully automated solution to create security-hardened Amazon EKS AL2023 AMIs that comply with either CIS Level 1 or Level 2 standards.

## 🔢 Pre-requisites

1. (Mandatory) Create S3 for storing terraform state files and provide S3 Bucket name on file ``versions.tf`` and ``eks-cluster/versions.tf``.
2. (Mandatory) Update the region in the ``locals.tf``,``eks-cluster/locals.tf``,``variables.pkr.hcl`` and on the ``Makefile`` file to specify where the solution should be deployed.
3. (Mandatory) Install make. make utility is almost universally pre-installed on most Linux distributions.
4. (Mandatory) Install [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).
5. (Mandatory) Install [Packer](https://developer.hashicorp.com/packer/tutorials/docker-get-started/get-started-install-cli).
6. (Mandatory) Become a member of Center for Interner Security(<https://www.cisecurity.org/>).

In order to download Build Kit scripts for Amazon Linux 2023.
This scripts will be applied on top of EKS-Optimized AMIs.
More info on Technical details section below.

7. (Optional) For the static tests, install terraform-docs,tflint,checkov,pre-commit and mdl.

## 🚀 How to deploy

**Step 1.** Navigate to the EKS_Optimized_AL2023 pattern directory: `cd patterns/EKS_Optimized_AL2023`

**Step 2.** Follow steps from the section [CIS Scripts](##🔒-cis-cripts)

**Step 3.** Run `make plan and make apply` to deploy VPC resource using Terraform.

**Step 4.** Run `make create-hardened-ami` to Create EKS CIS Level1 and Level2 Hardened AMIs using EKS AMIs as a base AMI.

**Step 5.** Run `make cluster-plan and make cluster-apply` to create EKS Cluster and create EKS managed node groups for each security-hardened Amazon EKS AMI as part of the same EKS Cluster. This also will deploy several different apps and add-ons and will run tests to see if the workload will run without issues.

**Step 6.** Run `make run-cis-scan` to trigger AWS Inspector CIS scans to scan EKS manages nodes and generate reports about checks which Passed, are Skipped or Failed.

## 🧹 How to terminate resources

**Step 1.** Navigate to the EKS_Optimized_AL2023 pattern directory: `cd patterns/EKS_Optimized_AL2023`

**Step 2.** Run `make clean` to Terminate Resources

## Technical details

## 🔒 CIS Scripts

CIS scripts needs to be downloaded from the following website: <https://www.cisecurity.org/cis-securesuite/cis-securesuite-build-kit-content>
In order to download the scripts, you need to be a CIS SecureSuite Member.

**Step 1.** Once you become a member, Click in "CIS WorkBench Sign In", and provide your username and password.

**Step 2.** Navigate to Benchmarks: <https://workbench.cisecurity.org/benchmarks>.

**Step 3.** Select "CIS Amazon Linux 2023 Benchmark" v1.0.0.

**Step 4.** Go to Files on the left side.

**Step 5.** Select "CIS Amazon Linux 2023 Benchmark v1.0.0 - Build Kit".

**Step 6.** Click in Latest Version on the right side, to Download amazon_linux_2023.tar.gz file.

**Step 7.** unzip the file and store the content on the folder [cis-scripts](./patterns/EKS_Optimized_2023/cis-scripts/).

**Step 8.**
Some changes need to be performed on the scripts in order to allow it to be executed from the pipeline.
Please find below detailed information about the changes.

Changes performed on CIS-LBK scripts:

1. Copied script `cis-scripts/CIS-LBK/cis_lbk_amazon_linux_2023/amazon_linux_2023.sh` to:
  `cis-scripts/CIS-LBK/cis_lbk_amazon_linux_2023/amazon_linux_2023_level_1.sh` and configure it to run Level 1 Hardening only:
   `run_profile=L1S`
   on the line 107.
   and `cis-scripts/CIS-LBK/cis_lbk_amazon_linux_2023/amazon_linux_2023_level_2.sh` and configure it to run Level 2 Hardening only:
   `run_profile=L2S`
   on the line 107.

2. add `mkdir $BDIR/logs` on Line 31 of `amazon_linux_2023_level_1.sh` and `amazon_linux_2023_level_2.sh` to create logs directory on the Instance

3. Disable prompt by commenting out on line 106

`#WARBNR`

4. disable checks that can cause operational impact on the file `exclusion_list.txt`:

You need to add to the file the following checks:

```#txt
1.4.1 #Ensure permissions on bootloader config are configured
1.6.1.6 #Ensure no unconfined services exist
3.2.1 #Ensure IP forwarding is disabled
3.4.2.4 #Ensure host based firewall loopback traffic is configured
3.3.1 #nix_ensure_source_routed_packets_not_accepted
3.3.2 #Ensure ICMP redirects are not accepted"
3.3.9 #Ensure IPv6 router advertisements are not accepted
3.4.2.7 #Ensure nftables default deny firewall policy
3.4.2.5 #Ensure firewalld drops unnecessary services and ports
3.4.4.2.3 #Ensure iptables rules exist for all open ports
3.4.4.2.4 #Ensure iptables default deny firewall policy
3.4.4.3.3 #Ensure ip6tables firewall rules exist for all open ports
6.1.11 #Ensure world writable files and directories are secured
6.1.12 #Ensure no unowned or ungrouped files or directories exist
3.4.1.1 #Ensure nftables is installed
```

Please find below more information about why the above checks needs to be skipped on EKS:

## CIS Scan Results and Exceptions for failed controls

Some configuration changes required for Kubernetes operation override settings applied during hardening. Below are failed findings, possible reasons, and recommendations where available. Organizations can re-apply controls according to their security and compliance requirements, then re-test to confirm application functionality.

| CIS ID | CIS Description | Reason | Alternative control |
|---------|-----------------|---------|-------------------|
| 3.4.4.2.3 | Ensure iptables rules exist for all open ports | iptables are managed by kube-proxy | Please use network policies to manage communication between pods |
| 3.4.4.2.4 | Ensure iptables default deny firewall policy | iptables are managed by kube-proxy | Please use network policies to manage communication between pods |
| 3.4.4.3.3 | Ensure ip6tables firewall rules exist for all open ports | iptables are managed by kube-proxy | Please use network policies to manage communication between pods |
| 6.1.11 | Ensure world writable files and directories are secured | Directories used by containerd | This is the standard behavior of Kubernetes, you can get more background here: [kubernetes/kubernetes#76158](https://github.com/kubernetes/kubernetes/issues/76158) |
| 6.1.12 | Ensure no unowned or ungrouped files or directories exist | Directories used by containerd | This is the standard behavior of Kubernetes, you can get more background here: [kubernetes/kubernetes#76158](https://github.com/kubernetes/kubernetes/issues/76158) |
| 3.2.1 | Ensure IP forwarding is disabled | IP forwarding is required by Kubernetes | N/A |
| 1.4.1 | Ensure permissions on bootloader config are configured | | |
| 1.6.1.6 | Ensure no unconfined services exist | Processes flagged in these findings are container processes. | Investigate any unconfined processes. They may need to have an existing security context assigned to them or a policy built for them. <https://aws.github.io/aws-eks-best-practices/security/docs/runtime/#runtime-security> |
| 3.4.2.4 | Ensure host based firewall loopback traffic is configured | Currently kube-proxy on EKS relies on iptables. | Once the FR is actioned on <https://github.com/aws/containers-roadmap/issues/2313>, then this check can be allowed. |
| 3.3.1 | nix_ensure_source_routed_packets_not_accepted | Pending | Pending |
| 3.3.2 | Ensure ICMP redirects are not accepted | Pending | Pending |
| 3.3.9 | Ensure IPv6 router advertisements are not accepted | Pending | Pending |
| 3.4.2.7 | Ensure nftables default deny firewall policy | Currently kube-proxy on EKS relies on iptables. | Once the FR is actioned on <https://github.com/aws/containers-roadmap/issues/2313>, then this check can be allowed. |
| 3.4.2.5 | Ensure firewalld drops unnecessary services and ports | Currently kube-proxy on EKS relies on iptables. | Once the FR is actioned on <https://github.com/aws/containers-roadmap/issues/2313>, then this check can be allowed. |
| 3.4.1.1 | Ensure nftables is installed | Currently kube-proxy on EKS relies on iptables. | Once the FR is actioned on <https://github.com/aws/containers-roadmap/issues/2313>, then this check can be allowed. |

## 🧑🏿‍💻 Packer scripts

`al2023_amd64_level_1.pkrvars.hcl` has specific settings to EKS_Optimized_AL2023_CIS_Benchmark_Level_1
`al2023_amd64_level_2.pkrvars.hcl` has specific settings to EKS_Optimized_AL2023_CIS_Benchmark_Level_2
`amazon-eks.pkr.hcl` has the source,build and provisioner components for  the following AMIs:

- EKS_Optimized_AL2023_CIS_Benchmark_Level_1
- EKS_Optimized_AL2023_CIS_Benchmark_Level_2

## 🕵️ How to access the EKS Cluster

Step 1. Create EKS Access Entry for your IAM User:

Through the AWS Console:

- Go to EKS Cluster created as part of the solution which is named EKS_Optimized_AL2023 on the AWS Region from the pipeline.
- Go to Access, Create Access Entry, Select your IAM Role from the list, Type: Standard, Click Next
- Add policy AmazonEKSClusterAdminPolicy *

Click in Next, then Create

Using AWS CLI:

```#!/bin/bash
aws eks create-access-entry --cluster-name EKS_Optimized_AL2023 --principal-arn <value> --region <Region>
aws eks associate-access-policy --cluster-name EKS_Optimized_AL2023 --principal-arn <value> --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy --access-scope "type=cluster" --region <Region>
```

Regarding the Policy AmazonEKSClusterAdminPolicy:

"This access policy includes permissions that grant an IAM principal administrator access to a cluster. When associated to an access entry, its access scope is typically the cluster, rather than a Kubernetes namespace. If you want an IAM principal to have a more limited administrative scope, consider associating the AmazonEKSAdminPolicy access policy to your access entry instead."
References: <https://docs.aws.amazon.com/eks/latest/userguide/access-policy-permissions.html#access-policy-permissions-amazoneksclusteradminpolicy>

Step 2. You need to update your kubeconfig in order to run kubectl commands to the cluster

```#!/bin/bash
aws eks update-kubeconfig --name EKS_Optimized_AL2023 --region <Region>
```

Then you can check nodes that joined the cluster and troubleshoot issues if required.

```#!/bin/bash
kubectl get nodes -o wide
NAME                                        STATUS   ROLES    AGE     VERSION               INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                       KERNEL-VERSION                    CONTAINER-RUNTIME
ip-10-0-36-199.us-west-2.compute.internal   Ready    <none>   4m33s   v1.33.0-eks-802817d   10.0.36.199   <none>        Amazon Linux 2023.7.20250512   6.1.134-152.225.amzn2023.x86_64   containerd://1.7.27
ip-10-0-5-42.us-west-2.compute.internal     Ready    <none>   4m31s   v1.33.0-eks-802817d   10.0.5.42     <none>        Amazon Linux 2023.7.20250512   6.1.134-152.225.amzn2023.x86_64   containerd://1.7.27
```

Check if all the pods are running:

```#!/bin/bash
kubectl get pods -A
NAMESPACE     NAME                                  READY   STATUS    RESTARTS   AGE
kube-system   aws-node-477kf                     2/2     Running   0          5m19s
kube-system   aws-node-bzxgx                     2/2     Running   0          5m21s
kube-system   coredns-7bf648ff5d-dj57w           1/1     Running   0          9m51s
kube-system   coredns-7bf648ff5d-m5pz8           1/1     Running   0          9m51s
kube-system   ebs-csi-controller-c78859b-rm5fd   6/6     Running   0          4m3s
kube-system   ebs-csi-controller-c78859b-v66fb   6/6     Running   0          4m3s
kube-system   ebs-csi-node-59w2d                 3/3     Running   0          4m3s
kube-system   ebs-csi-node-r5cnj                 3/3     Running   0          4m3s
kube-system   kube-proxy-ntlb2                   1/1     Running   0          5m21s
kube-system   kube-proxy-vdhd6                   1/1     Running   0          5m19s
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
| <a name="provider_amazon-parameterstore"></a> [amazon-parameterstore](#provider\_amazon-parameterstore) | n/a |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.96 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ./../modules/vpc | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ssm_parameter.eks_optimized_al2023_level_1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.eks_optimized_al2023_level_2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [amazon-parameterstore_amazon-parameterstore.eks_optimized_ami_al2023](https://registry.terraform.io/providers/hashicorp/amazon-parameterstore/latest/docs/data-sources/amazon-parameterstore) | data source |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_key"></a> [access\_key](#input\_access\_key) | The access key used to communicate with AWS | `string` | `null` | no |
| <a name="input_ami_block_device_mappings"></a> [ami\_block\_device\_mappings](#input\_ami\_block\_device\_mappings) | The block device mappings attached when booting a new instance from the AMI created | `list(map(string))` | <pre>[<br/>  {<br/>    "delete_on_termination": true,<br/>    "device_name": "/dev/xvda",<br/>    "volume_size": 10,<br/>    "volume_type": "gp3"<br/>  }<br/>]</pre> | no |
| <a name="input_ami_description"></a> [ami\_description](#input\_ami\_description) | The description to use when creating the AMI | `string` | `"Amazon EKS Kubernetes AMI based on AmazonLinux2 OS"` | no |
| <a name="input_ami_groups"></a> [ami\_groups](#input\_ami\_groups) | A list of groups that have access to launch the resulting AMI(s). By default no groups have permission to launch the AMI. `all` will make the AMI publicly accessible. AWS currently doesn't accept any value other than `all` | `list(string)` | `null` | no |
| <a name="input_ami_name"></a> [ami\_name](#input\_ami\_name) | The AMI name | `string` | `""` | no |
| <a name="input_ami_name_prefix"></a> [ami\_name\_prefix](#input\_ami\_name\_prefix) | The prefix to use when creating the AMI name. i.e. - `<ami_name_prefix>-<eks_version>-<timestamp>` | `string` | `"amazon-eks"` | no |
| <a name="input_ami_org_arns"></a> [ami\_org\_arns](#input\_ami\_org\_arns) | A list of Amazon Resource Names (ARN) of AWS Organizations that have access to launch the resulting AMI(s). By default no organizations have permission to launch the AMI | `list(string)` | `null` | no |
| <a name="input_ami_ou_arns"></a> [ami\_ou\_arns](#input\_ami\_ou\_arns) | A list of Amazon Resource Names (ARN) of AWS Organizations organizational units (OU) that have access to launch the resulting AMI(s). By default no organizational units have permission to launch the AMI | `list(string)` | `null` | no |
| <a name="input_ami_regions"></a> [ami\_regions](#input\_ami\_regions) | A list of regions to copy the AMI to. Tags and attributes are copied along with the AMI. AMI copying takes time depending on the size of the AMI, but will generally take many minutes | `list(string)` | `null` | no |
| <a name="input_ami_type"></a> [ami\_type](#input\_ami\_type) | The type of AMI to create. Valid values are `amazon-linux-2` or `amazon-linux-2-arm64` | `string` | `"amazon-linux-2"` | no |
| <a name="input_ami_users"></a> [ami\_users](#input\_ami\_users) | A list of account IDs that have access to launch the resulting AMI(s). By default no additional users other than the user creating the AMI has permissions to launch it | `list(string)` | `null` | no |
| <a name="input_ami_virtualization_type"></a> [ami\_virtualization\_type](#input\_ami\_virtualization\_type) | The type of virtualization used to create the AMI. Can be one of `hvm` or `paravirtual` | `string` | `"hvm"` | no |
| <a name="input_associate_public_ip_address"></a> [associate\_public\_ip\_address](#input\_associate\_public\_ip\_address) | If using a non-default VPC, public IP addresses are not provided by default. If this is true, your new instance will get a Public IP | `bool` | `true` | no |
| <a name="input_assume_role"></a> [assume\_role](#input\_assume\_role) | If provided with a role ARN, Packer will attempt to assume this role using the supplied credentials | `map(string)` | `{}` | no |
| <a name="input_aws_polling"></a> [aws\_polling](#input\_aws\_polling) | Polling configuration for the AWS waiter. Configures the waiter for resources creation or actions like attaching volumes or importing image | `map(string)` | `{}` | no |
| <a name="input_capacity_reservation_group_arn"></a> [capacity\_reservation\_group\_arn](#input\_capacity\_reservation\_group\_arn) | Provide the EC2 Capacity Reservation Group ARN that will be used by Packer | `string` | `null` | no |
| <a name="input_capacity_reservation_id"></a> [capacity\_reservation\_id](#input\_capacity\_reservation\_id) | Provide the specific EC2 Capacity Reservation ID that will be used by Packer | `string` | `null` | no |
| <a name="input_capacity_reservation_preference"></a> [capacity\_reservation\_preference](#input\_capacity\_reservation\_preference) | Set the preference for using a capacity reservation if one exists. Either will be `open` or `none`. Defaults to `none` | `string` | `null` | no |
| <a name="input_communicator"></a> [communicator](#input\_communicator) | The communicator to use to communicate with the EC2 instance. Valid values are `none`, `ssh`, `winrm`, and `ssh+winrm` | `string` | `"ssh"` | no |
| <a name="input_custom_endpoint_ec2"></a> [custom\_endpoint\_ec2](#input\_custom\_endpoint\_ec2) | This option is useful if you use a cloud provider whose API is compatible with aws EC2 | `string` | `null` | no |
| <a name="input_decode_authorization_messages"></a> [decode\_authorization\_messages](#input\_decode\_authorization\_messages) | Enable automatic decoding of any encoded authorization (error) messages using the sts:DecodeAuthorizationMessage API | `bool` | `null` | no |
| <a name="input_deprecate_at"></a> [deprecate\_at](#input\_deprecate\_at) | The date and time to deprecate the AMI, in UTC, in the following format: YYYY-MM-DDTHH:MM:SSZ. If you specify a value for seconds, Amazon EC2 rounds the seconds to the nearest minute | `string` | `null` | no |
| <a name="input_disable_stop_instance"></a> [disable\_stop\_instance](#input\_disable\_stop\_instance) | If this is set to true, Packer will not stop the instance but will assume that you will send the stop signal yourself through your final provisioner | `bool` | `null` | no |
| <a name="input_ebs_optimized"></a> [ebs\_optimized](#input\_ebs\_optimized) | Mark instance as EBS Optimized. Default `false` | `bool` | `null` | no |
| <a name="input_eks_version"></a> [eks\_version](#input\_eks\_version) | The EKS cluster version associated with the AMI created | `string` | `"1.32"` | no |
| <a name="input_ena_support"></a> [ena\_support](#input\_ena\_support) | Enable enhanced networking (ENA but not SriovNetSupport) on HVM-compatible AMIs | `bool` | `null` | no |
| <a name="input_enable_nitro_enclave"></a> [enable\_nitro\_enclave](#input\_enable\_nitro\_enclave) | Enable support for Nitro Enclaves on the instance | `bool` | `null` | no |
| <a name="input_enable_unlimited_credits"></a> [enable\_unlimited\_credits](#input\_enable\_unlimited\_credits) | Enabling Unlimited credits allows the source instance to burst additional CPU beyond its available CPU Credits for as long as the demand exists | `bool` | `null` | no |
| <a name="input_encrypt_boot"></a> [encrypt\_boot](#input\_encrypt\_boot) | Whether or not to encrypt the resulting AMI when copying a provisioned instance to an AMI. By default, Packer will keep the encryption setting to what it was in the source image | `bool` | `null` | no |
| <a name="input_file_provisioner1"></a> [file\_provisioner1](#input\_file\_provisioner1) | Values passed to the first file provisioner | `string` | `"dummy"` | no |
| <a name="input_fleet_tags"></a> [fleet\_tags](#input\_fleet\_tags) | Key/value pair tags to apply tags to the fleet that is issued | `map(string)` | `null` | no |
| <a name="input_force_delete_snapshot"></a> [force\_delete\_snapshot](#input\_force\_delete\_snapshot) | Force Packer to delete snapshots associated with AMIs, which have been deregistered by force\_deregister. Default `false` | `bool` | `null` | no |
| <a name="input_force_deregister"></a> [force\_deregister](#input\_force\_deregister) | Force Packer to first deregister an existing AMI if one with the same name already exists. Default `false` | `bool` | `null` | no |
| <a name="input_iam_instance_profile"></a> [iam\_instance\_profile](#input\_iam\_instance\_profile) | The name of an IAM instance profile to launch the EC2 instance with | `string` | `null` | no |
| <a name="input_imds_support"></a> [imds\_support](#input\_imds\_support) | Enforce version of the Instance Metadata Service on the built AMI. Valid options are `unset` (legacy) and `v2.0` | `string` | `"v2.0"` | no |
| <a name="input_insecure_skip_tls_verify"></a> [insecure\_skip\_tls\_verify](#input\_insecure\_skip\_tls\_verify) | This allows skipping TLS verification of the AWS EC2 endpoint. The default is `false` | `bool` | `null` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | The EC2 instance type to use while building the AMI, such as `m5.large` | `string` | `"c5.xlarge"` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | ID, alias or ARN of the KMS key to use for AMI encryption. This only applies to the main `region` -- any regions the AMI gets copied to copied will be encrypted by the default EBS KMS key for that region, unless you set region-specific keys in `region_kms_key_ids` | `string` | `null` | no |
| <a name="input_launch_block_device_mappings"></a> [launch\_block\_device\_mappings](#input\_launch\_block\_device\_mappings) | The block device mappings to use when creating the AMI. If you add instance store volumes or EBS volumes in addition to the root device volume, the created AMI will contain block device mapping information for those volumes. Amazon creates snapshots of the source instance's root volume and any other EBS volumes described here. When you launch an instance from this new AMI, the instance automatically launches with these additional volumes, and will restore them from snapshots taken from the source instance | `list(map(string))` | <pre>[<br/>  {<br/>    "delete_on_termination": true,<br/>    "device_name": "/dev/xvda",<br/>    "volume_size": 10,<br/>    "volume_type": "gp3"<br/>  }<br/>]</pre> | no |
| <a name="input_max_retries"></a> [max\_retries](#input\_max\_retries) | This is the maximum number of times an API call is retried, in the case where requests are being throttled or experiencing transient failures. The delay between the subsequent API calls increases exponentially | `number` | `null` | no |
| <a name="input_metadata_options"></a> [metadata\_options](#input\_metadata\_options) | Configures the metadata options for the instance launched | `map(string)` | <pre>{<br/>  "http_endpoint": "enabled",<br/>  "http_put_response_hop_limit": 1,<br/>  "http_tokens": "required"<br/>}</pre> | no |
| <a name="input_mfa_code"></a> [mfa\_code](#input\_mfa\_code) | The MFA TOTP code. This should probably be a user variable since it changes all the time | `string` | `null` | no |
| <a name="input_pause_before_connecting"></a> [pause\_before\_connecting](#input\_pause\_before\_connecting) | We recommend that you enable SSH or WinRM as the very last step in your guest's bootstrap script, but sometimes you may have a race condition where you need Packer to wait before attempting to connect to your guest | `string` | `null` | no |
| <a name="input_pause_before_ssm"></a> [pause\_before\_ssm](#input\_pause\_before\_ssm) | The time to wait before establishing the Session Manager session | `string` | `null` | no |
| <a name="input_placement"></a> [placement](#input\_placement) | Describes the placement of an instance | `map(string)` | `{}` | no |
| <a name="input_profile"></a> [profile](#input\_profile) | The profile to use in the shared credentials file for AWS | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | The name of the region, such as us-east-1, in which to launch the EC2 instance to create the AMI | `string` | `"us-west-2"` | no |
| <a name="input_region_kms_key_ids"></a> [region\_kms\_key\_ids](#input\_region\_kms\_key\_ids) | regions to copy the ami to, along with the custom kms key id (alias or arn) to use for encryption for that region. Keys must match the regions provided in `ami_regions` | `map(string)` | `null` | no |
| <a name="input_run_tags"></a> [run\_tags](#input\_run\_tags) | Key/value pair tags to apply to the generated key-pair, security group, iam profile and role, snapshot, network interfaces and instance that is launched to create the EBS volumes. The resulting AMI will also inherit these tags | `map(string)` | `null` | no |
| <a name="input_run_volume_tags"></a> [run\_volume\_tags](#input\_run\_volume\_tags) | Tags to apply to the volumes that are launched to create the AMI. These tags are not applied to the resulting AMI | `map(string)` | `null` | no |
| <a name="input_secret_key"></a> [secret\_key](#input\_secret\_key) | The secret key used to communicate with AWS | `string` | `null` | no |
| <a name="input_security_group_filter"></a> [security\_group\_filter](#input\_security\_group\_filter) | Filters used to populate the `security_group_ids` field. `security_group_ids` take precedence over this | `list(map(string))` | `[]` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | A list of security group IDs to assign to the instance. By default this is not set and Packer will automatically create a new temporary security group to allow SSH access | `list(string)` | `null` | no |
| <a name="input_session_manager_port"></a> [session\_manager\_port](#input\_session\_manager\_port) | Which port to connect the local end of the session tunnel to. If left blank, Packer will choose a port for you from available ports. This option is only used when `ssh_interface` is set `session_manager` | `number` | `null` | no |
| <a name="input_shared_credentials_file"></a> [shared\_credentials\_file](#input\_shared\_credentials\_file) | Path to a credentials file to load credentials from | `string` | `null` | no |
| <a name="input_shell_provisioner1"></a> [shell\_provisioner1](#input\_shell\_provisioner1) | Values passed to the first shell provisioner | `string` | `"dummy"` | no |
| <a name="input_shutdown_behavior"></a> [shutdown\_behavior](#input\_shutdown\_behavior) | Automatically terminate instances on shutdown in case Packer exits ungracefully. Possible values are `stop` and `terminate`. Defaults to `stop` | `string` | `null` | no |
| <a name="input_skip_credential_validation"></a> [skip\_credential\_validation](#input\_skip\_credential\_validation) | Set to true if you want to skip validating AWS credentials before runtime | `bool` | `null` | no |
| <a name="input_skip_metadata_api_check"></a> [skip\_metadata\_api\_check](#input\_skip\_metadata\_api\_check) | Skip Metadata Api Check | `bool` | `null` | no |
| <a name="input_skip_profile_validation"></a> [skip\_profile\_validation](#input\_skip\_profile\_validation) | Whether or not to check if the IAM instance profile exists. Defaults to `false` | `bool` | `null` | no |
| <a name="input_skip_region_validation"></a> [skip\_region\_validation](#input\_skip\_region\_validation) | Set to `true` if you want to skip validation of the `ami_regions` configuration option. Default `false` | `bool` | `null` | no |
| <a name="input_skip_save_build_region"></a> [skip\_save\_build\_region](#input\_skip\_save\_build\_region) | If true, Packer will not check whether an AMI with the ami\_name exists in the region it is building in. It will use an intermediary AMI name, which it will not convert to an AMI in the build region. Default `false` | `bool` | `null` | no |
| <a name="input_snapshot_groups"></a> [snapshot\_groups](#input\_snapshot\_groups) | A list of groups that have access to create volumes from the snapshot(s). By default no groups have permission to create volumes from the snapshot(s). all will make the snapshot publicly accessible | `list(string)` | `null` | no |
| <a name="input_snapshot_tags"></a> [snapshot\_tags](#input\_snapshot\_tags) | Key/value pair tags to apply to snapshot. They will override AMI tags if already applied to snapshot | `map(string)` | `null` | no |
| <a name="input_snapshot_users"></a> [snapshot\_users](#input\_snapshot\_users) | A list of account IDs that have access to create volumes from the snapshot(s). By default no additional users other than the user creating the AMI has permissions to create volumes from the backing snapshot(s) | `list(string)` | `null` | no |
| <a name="input_sriov_support"></a> [sriov\_support](#input\_sriov\_support) | Enable enhanced networking (SriovNetSupport but not ENA) on HVM-compatible AMIs | `bool` | `null` | no |
| <a name="input_ssh_agent_auth"></a> [ssh\_agent\_auth](#input\_ssh\_agent\_auth) | If true, the local SSH agent will be used to authenticate connections to the source instance. No temporary keypair will be created, and the values of `ssh_password` and `ssh_private_key_file` will be ignored. The environment variable `SSH_AUTH_SOCK` must be set for this option to work properly | `bool` | `null` | no |
| <a name="input_ssh_bastion_agent_auth"></a> [ssh\_bastion\_agent\_auth](#input\_ssh\_bastion\_agent\_auth) | If `true`, the local SSH agent will be used to authenticate with the bastion host. Defaults to `false` | `bool` | `null` | no |
| <a name="input_ssh_bastion_certificate_file"></a> [ssh\_bastion\_certificate\_file](#input\_ssh\_bastion\_certificate\_file) | Path to user certificate used to authenticate with bastion host. The ~ can be used in path and will be expanded to the home directory of current user | `string` | `null` | no |
| <a name="input_ssh_bastion_host"></a> [ssh\_bastion\_host](#input\_ssh\_bastion\_host) | A bastion host to use for the actual SSH connection | `string` | `null` | no |
| <a name="input_ssh_bastion_interactive"></a> [ssh\_bastion\_interactive](#input\_ssh\_bastion\_interactive) | If `true`, the keyboard-interactive used to authenticate with bastion host | `bool` | `null` | no |
| <a name="input_ssh_bastion_password"></a> [ssh\_bastion\_password](#input\_ssh\_bastion\_password) | The password to use to authenticate with the bastion host | `string` | `null` | no |
| <a name="input_ssh_bastion_port"></a> [ssh\_bastion\_port](#input\_ssh\_bastion\_port) | The port of the bastion host. Defaults to `22` | `number` | `null` | no |
| <a name="input_ssh_bastion_private_key_file"></a> [ssh\_bastion\_private\_key\_file](#input\_ssh\_bastion\_private\_key\_file) | Path to a PEM encoded private key file to use to authenticate with the bastion host. The `~` can be used in path and will be expanded to the home directory of current user | `string` | `null` | no |
| <a name="input_ssh_bastion_username"></a> [ssh\_bastion\_username](#input\_ssh\_bastion\_username) | The username to connect to the bastion host | `string` | `null` | no |
| <a name="input_ssh_certificate_file"></a> [ssh\_certificate\_file](#input\_ssh\_certificate\_file) | Path to user certificate used to authenticate with SSH. The `~` can be used in path and will be expanded to the home directory of current user | `string` | `null` | no |
| <a name="input_ssh_ciphers"></a> [ssh\_ciphers](#input\_ssh\_ciphers) | This overrides the value of ciphers supported by default by Golang. The default value is `["aes128-gcm@openssh.com", "chacha20-poly1305@openssh.com", "aes128-ctr", "aes192-ctr", "aes256-ctr"]` | `list(string)` | `null` | no |
| <a name="input_ssh_clear_authorized_keys"></a> [ssh\_clear\_authorized\_keys](#input\_ssh\_clear\_authorized\_keys) | If true, Packer will attempt to remove its temporary key from `~/.ssh/authorized_keys` and `/root/.ssh/authorized_keys` | `bool` | `null` | no |
| <a name="input_ssh_disable_agent_forwarding"></a> [ssh\_disable\_agent\_forwarding](#input\_ssh\_disable\_agent\_forwarding) | If `true`, SSH agent forwarding will be disabled. Defaults to `false` | `bool` | `null` | no |
| <a name="input_ssh_file_transfer_method"></a> [ssh\_file\_transfer\_method](#input\_ssh\_file\_transfer\_method) | How to transfer files, Secure copy (`scp` default) or SSH File Transfer Protocol (`sftp`) | `string` | `null` | no |
| <a name="input_ssh_handshake_attempts"></a> [ssh\_handshake\_attempts](#input\_ssh\_handshake\_attempts) | The number of handshakes to attempt with SSH once it can connect. This defaults to `10`, unless a `ssh_timeout` is set | `number` | `null` | no |
| <a name="input_ssh_host"></a> [ssh\_host](#input\_ssh\_host) | The address to SSH to. This usually is automatically configured by the builder | `string` | `null` | no |
| <a name="input_ssh_interface"></a> [ssh\_interface](#input\_ssh\_interface) | One of `public_ip`, `private_ip`, `public_dns`, `private_dns` or `session_manager`. If set, either the public IP address, private IP address, public DNS name or private DNS name will be used as the host for SSH. The default behavior if inside a VPC is to use the public IP address if available, otherwise the private IP address will be used. If not in a VPC the public DNS name will be used | `string` | `"public_dns"` | no |
| <a name="input_ssh_keep_alive_interval"></a> [ssh\_keep\_alive\_interval](#input\_ssh\_keep\_alive\_interval) | How often to send "keep alive" messages to the server. Set to a negative value (`-1s`) to disable. Defaults to `5s` | `string` | `null` | no |
| <a name="input_ssh_key_exchange_algorithms"></a> [ssh\_key\_exchange\_algorithms](#input\_ssh\_key\_exchange\_algorithms) | If set, Packer will override the value of key exchange (kex) algorithms supported by default by Golang. Acceptable values include: `curve25519-sha256@libssh.org`, `ecdh-sha2-nistp256`, `ecdh-sha2-nistp384`, `ecdh-sha2-nistp521`, `diffie-hellman-group14-sha1`, and `diffie-hellman-group1-sha1` | `list(string)` | `null` | no |
| <a name="input_ssh_keypair_name"></a> [ssh\_keypair\_name](#input\_ssh\_keypair\_name) | If specified, this is the key that will be used for SSH with the machine. The key must match a key pair name loaded up into the remote | `string` | `null` | no |
| <a name="input_ssh_local_tunnels"></a> [ssh\_local\_tunnels](#input\_ssh\_local\_tunnels) | A list of local tunnels to use when connecting to the host | `list(string)` | `null` | no |
| <a name="input_ssh_password"></a> [ssh\_password](#input\_ssh\_password) | A plaintext password to use to authenticate with SSH | `string` | `null` | no |
| <a name="input_ssh_port"></a> [ssh\_port](#input\_ssh\_port) | The port to connect to SSH. This defaults to `22` | `number` | `null` | no |
| <a name="input_ssh_private_key_file"></a> [ssh\_private\_key\_file](#input\_ssh\_private\_key\_file) | Path to a PEM encoded private key file to use to authenticate with SSH. The ~ can be used in path and will be expanded to the home directory of current user | `string` | `null` | no |
| <a name="input_ssh_proxy_host"></a> [ssh\_proxy\_host](#input\_ssh\_proxy\_host) | A SOCKS proxy host to use for SSH connection | `string` | `null` | no |
| <a name="input_ssh_proxy_password"></a> [ssh\_proxy\_password](#input\_ssh\_proxy\_password) | The optional password to use to authenticate with the proxy server | `string` | `null` | no |
| <a name="input_ssh_proxy_port"></a> [ssh\_proxy\_port](#input\_ssh\_proxy\_port) | A port of the SOCKS proxy. Defaults to `1080` | `number` | `null` | no |
| <a name="input_ssh_proxy_username"></a> [ssh\_proxy\_username](#input\_ssh\_proxy\_username) | The optional username to authenticate with the proxy server | `string` | `null` | no |
| <a name="input_ssh_pty"></a> [ssh\_pty](#input\_ssh\_pty) | If `true`, a PTY will be requested for the SSH connection. This defaults to `false` | `bool` | `null` | no |
| <a name="input_ssh_read_write_timeout"></a> [ssh\_read\_write\_timeout](#input\_ssh\_read\_write\_timeout) | The amount of time to wait for a remote command to end. This might be useful if, for example, packer hangs on a connection after a reboot. Example: `5m`. Disabled by default | `string` | `null` | no |
| <a name="input_ssh_remote_tunnels"></a> [ssh\_remote\_tunnels](#input\_ssh\_remote\_tunnels) | A list of remote tunnels to use when connecting to the host | `list(string)` | `null` | no |
| <a name="input_ssh_timeout"></a> [ssh\_timeout](#input\_ssh\_timeout) | The time to wait for SSH to become available. Packer uses this to determine when the machine has booted so this is usually quite long. This defaults to `5m`, unless `ssh_handshake_attempts` is set | `string` | `null` | no |
| <a name="input_ssh_username"></a> [ssh\_username](#input\_ssh\_username) | The username to connect to SSH with. Required if using SSH | `string` | `"ec2-user"` | no |
| <a name="input_subnet_filter"></a> [subnet\_filter](#input\_subnet\_filter) | Filters used to populate the subnet\_id field. `subnet_id` take precedence over this | `list(map(string))` | `[]` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | f using VPC, the ID of the subnet, such as subnet-12345def, where Packer will launch the EC2 instance. This field is required if you are using an non-default VPC | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Key/value pair tags applied to the AMI | `map(string)` | `{}` | no |
| <a name="input_temporary_key_pair_bits"></a> [temporary\_key\_pair\_bits](#input\_temporary\_key\_pair\_bits) | Specifies the number of bits in the key to create. For RSA keys, the minimum size is 1024 bits and the default is 4096 bits. Generally, 3072 bits is considered sufficient | `number` | `null` | no |
| <a name="input_temporary_key_pair_type"></a> [temporary\_key\_pair\_type](#input\_temporary\_key\_pair\_type) | Specifies the type of key to create. The possible values are 'dsa', 'ecdsa', 'ed25519', or 'rsa'. Default is `rsa` | `string` | `null` | no |
| <a name="input_temporary_security_group_source_cidrs"></a> [temporary\_security\_group\_source\_cidrs](#input\_temporary\_security\_group\_source\_cidrs) | A list of IPv4 CIDR blocks to be authorized access to the instance, when packer is creating a temporary security group. The default is `[0.0.0.0/0]` | `list(string)` | `null` | no |
| <a name="input_temporary_security_group_source_public_ip"></a> [temporary\_security\_group\_source\_public\_ip](#input\_temporary\_security\_group\_source\_public\_ip) | When enabled, use public IP of the host (obtained from https://checkip.amazonaws.com) as CIDR block to be authorized access to the instance, when packer is creating a temporary security group. Defaults to `false` | `bool` | `null` | no |
| <a name="input_token"></a> [token](#input\_token) | The access token to use. This is different from the access key and secret key | `string` | `null` | no |
| <a name="input_user_data"></a> [user\_data](#input\_user\_data) | User data to apply when launching the instance | `string` | `null` | no |
| <a name="input_user_data_file"></a> [user\_data\_file](#input\_user\_data\_file) | Path to a file that will be used for the user data when launching the instance | `string` | `null` | no |
| <a name="input_vpc_filter"></a> [vpc\_filter](#input\_vpc\_filter) | Filters used to populate the `vpc_id` field. `vpc_id` take precedence over this | `list(map(string))` | `[]` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | If launching into a VPC subnet, Packer needs the VPC ID in order to create a temporary security group within the VPC. Requires `subnet_id` to be set. If this field is left blank, Packer will try to get the VPC ID from the `subnet_id` | `string` | `null` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->
