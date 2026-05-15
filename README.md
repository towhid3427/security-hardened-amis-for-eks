# Security Hardened AMIs for EKS

This project provides a fully automated solution to create security-hardened Amazon EKS AMIs that comply with either CIS Level 1 or Level 2 standards.

There are three types of guidance generally being requested from AWS Customers:

1. Customers seeking guidance on how to generate a CIS-hardened AMI for EKS.
2. Customers encountering issues with workloads running on their custom, CIS-hardened AMIs.
3. Customers requesting the EKS team to prioritize the release of an official CIS-hardened EKS AMI.

**This solution address the topics 1 and 2 above.**

## 💪 Motivation

Currently, information is spread across different resources and there isn't a central location that explain how to apply CIS scripts for each of the available AMIs. In other words, there is no existent holistic mechanism that can measure the impact of changes in any of the different sources - CIS Scripts, CIS AMIs and EKS Optimized AMIs.

As we can see from the table on the Further Resources Section, guidance available are spread across different resources(Workshops/Blog Posts) using different tech and there is no single solution that cover a single process for all the base AMIs available.

## 🤯 Why is this problem space complex?
- There are more than 200 CIS Scripts/Checks
- There are Multiple AMI Variants(EKS + CIS L1 and L2) - AL2023, Bottlerocket OS
- A change from one side(EKS or CIS) can break the other side = no integrated tests exists
- There are different release cadence schedule from CIS Scripts, CIS AMIs and EKS AMIs
- It is hard to measure downstream impact on workloads

## 🕵 Overview of the solution

A fully automated solution that enables customers to create security-hardened EKS AMIs compliant with Center for Internet Security (CIS) benchmarks.
The solution will consider the following base AMIs(depending on the pattern you choose) and apply Level 1 and Level 2 CIS Benchmark Hardening where applicable.

- EKS_Optimized_AL2023
- BOTTLEROCKET
- CIS_Amazon_Linux_2023_Benchmark_Level_1
- CIS_Amazon_Linux_2023_Benchmark_Level_2

Currently solution uses base AMIs with x86_64 architecture.

Solution Diagram

![](./docs/images/solution.png)

Detailed steps are provided within each pattern folder. For a guided experience, follow the prompts when running the file ``create-hardened-ami.sh.``

There are different approaches for hardening the Amazon EKS AMI for CIS Benchmark Level 1 or Level 2 profiles which this automation takes care of:

**Method 1.** Use the standard Amazon EKS Amazon Linux 2023 Optimized AMI as a base and add hardening on top of it. This process requires to apply all configuration mentioned in the Amazon Linux CIS Benchmark specification.

![](./docs/images/method1.png)

This process is part of following patterns:
- [EKS_Optimized_AL2023](./patterns/EKS_Optimized_AL2023/)

**Method 2.** Use the Amazon Linux 2023 CIS Benchmark Level 1 or Level 2 AMI from the AWS Marketplace as a base, and add Amazon EKS specific components on top of it.

![](./docs/images/method2.png)


This process is part of following patterns:
- [CIS_AL2023](./patterns/CIS_AL2023/)

**Method 3.** Use the Amazon EKS optimized Bottlerocket AMI (as of this writing) which supports 18 out of 28 Level 1 and 2 recommendations specified in the CIS Benchmark for Bottlerocket, without a need for any additional configuration effort. For the remaining 10 recommendations to adhere to Level 2, six recommendations can be addressed via a bootstrap container and four recommendations can be addressed via kernel sysctl configurations in the user data of the Amazon EKS worker nodes.

![](./docs/images/method3.png)

This process is part of following pattern:
- [BOTTLEROCKET](./patterns/BOTTLEROCKET/)

The benefits of this solution includes:

- Automation will allow scripts and tests run through with no effort after every new AMI release from AWS or from CIS.
- We are going to have a central place for compare impact of changes from EKS Optimized AMI or scripts provided by CIS in regards CIS Hardening compliance on EKS.
- Resources can be used for learning and guide our AWS Internal/External community to support customers through their hardening requirements.

## 🤝 Shared Responsibility

This project produces a hardened EKS node AMI. An AMI is one layer of a secure EKS deployment. The matrix below clarifies which controls this repository provides and which controls remain with the operator. Treat it as a starting point and map it to your own threat model and compliance scope.

| Layer | Scope | Owner |
|---|---|---|
| 1. Base AMI | CIS Marketplace AMI or AWS EKS-optimized AMI | AWS / CIS |
| 2. AMI hardening overlay | CIS controls layered onto EKS-optimized images, or EKS components layered onto CIS images, packaged via Packer in this repo | This project |
| 3. Build environment | Workstation or CI runner, OS, network egress, credentials, secrets, and supply chain used to run Terraform and Packer | **Operator** |
| 4. AWS account and infrastructure | IAM, KMS, VPC design, security groups, EKS cluster endpoint access, CloudTrail, AMI distribution permissions | **Operator** |
| 5. Cluster and workloads | Kubernetes RBAC, Pod Security Admission, NetworkPolicy, image signing, admission control, runtime detection | **Operator** |
| 6. Operations | AMI rebuild cadence, drift detection, vulnerability response, deregistration of superseded AMIs | **Operator** |

### Layer 1 — Base AMI (AWS / CIS)

The starting image is built and maintained outside this project:

- **AWS EKS-optimized AMIs** (`amazon-eks-node-al2023-*`) are produced by AWS, ship the EKS bootstrap components, and receive regular patch releases. AWS is responsible for the kernel, package versions, and EKS-specific binaries shipped in the image.
- **CIS Amazon Linux 2023 Benchmark AMIs** (Level 1 and Level 2) are published by the Center for Internet Security on AWS Marketplace. CIS is responsible for the benchmark controls applied to those images and for republishing when Amazon Linux 2023 is patched upstream.
- **Bottlerocket AMIs** are produced by AWS and ship most CIS controls applied by default.

What this means for the operator:

- Subscribe to release notifications for the base you choose. A patched base AMI does not propagate to your fleet automatically; you must rebuild.
- Treat the base AMI ID as part of your software bill of materials. Record it in build artifacts.

### Layer 2 — AMI hardening overlay (this project)

This repository sits between the base AMI and your cluster. It uses Packer to apply one of two transformations:

- **EKS-on-CIS** — start from a CIS Marketplace AMI, install containerd, kubelet, the EKS bootstrap (`nodeadm`), the AWS CLI, the ECR credential provider, the SOCI snapshotter, and SSM Agent. Used by the `CIS_AL2023` pattern.
- **CIS-on-EKS** — start from an AWS EKS-optimized AMI and apply CIS controls. Used by the `EKS_Optimized_AL2023` pattern.

The Bottlerocket pattern is the exception: most CIS controls are satisfied out of the box, and the remaining controls are applied at node launch via user data and a bootstrap container.

What this layer guarantees:

- Reproducible Packer builds driven by version-controlled scripts under `patterns/<pattern>/template_files/`.
- Kernel and key packages held by `dnf versionlock` so post-build updates do not silently drift the image.
- A CIS scan of the resulting node group via AWS Inspector (`null_resource.run_cis_scan`) so you can verify the overlay achieved the expected control coverage.

What this layer does not guarantee:

- That the upstream `awslabs/amazon-eks-ami` repo is at a safe revision. Pin `var.branch` to a tag or commit SHA you have reviewed.
- That the overlay covers controls outside the CIS Amazon Linux benchmark scope (Kubernetes-level controls, container runtime hardening beyond defaults, workload identity, etc.). Those belong to Layers 4–6.
- Compatibility with arbitrary base AMI versions. Upstream changes (kernel major version, package renames, SELinux policy updates) can break the overlay; rebuild and test before promoting an AMI.

### Layer 3 — Hardening the build environment

The host that runs `terraform apply` and `packer build` becomes a high-value target. It holds credentials, produces AMIs that downstream workloads will trust, and writes Terraform state that may contain sensitive values.

Minimum expectations:

- **Run from a dedicated, hardened build host or CI runner.** Do not run AMI builds from a shared developer workstation. If a workstation is unavoidable, scope its credentials accordingly.
- **Use short-lived credentials.** Prefer AWS IAM Identity Center, EC2 instance profiles, or OIDC federation from your CI provider. Do not configure long-lived `AKIA...` access keys for build automation.
- **Apply least privilege to the build role.** The role needs EC2, S3 (for the EKS binary bucket), IAM `PassRole` on the Packer instance profile, and EKS permissions. It does not need `AdministratorAccess`.
- **Pin tool versions and verify checksums.** Pin `terraform`, `packer`, and Terraform provider versions. Commit `.terraform.lock.hcl`. Verify SHA256 sums of any binaries downloaded by the build.
- **Pin upstream sources.** This repository clones `awslabs/amazon-eks-ami` at build time. Set `var.branch` to a tag or commit SHA, not a moving branch.
- **Protect Terraform state.** Use a remote backend with encryption, versioning, and state locking (S3 + DynamoDB, or Terraform Cloud). State contains resource identifiers and may contain sensitive outputs.
- **Restrict and log network egress.** Builds reach `github.com`, AWS APIs, `awscli.amazonaws.com`, `efa-installer.amazonaws.com`, and the EKS binary bucket. Allow-list those endpoints where you can and log all egress.
- **Control AMI distribution.** Tag every AMI with the source commit SHA. Restrict `ModifyImageAttribute` and scope `ami_users` to accounts that should consume the image.

### Layer 3a — Hardening the CI/CD pipeline

If you automate this build, treat the pipeline itself as a production system:

- Require branch protection and code review on any branch that triggers an AMI build.
- Authenticate the pipeline to AWS via OIDC federation. Constrain the IAM trust policy to the specific repository, branch, and workflow path.
- Pin GitHub Actions (or equivalent) to commit SHAs, not tags. Prefer ephemeral runners.
- Run `terraform validate`, `tflint`, and `checkov` on every change. This repository ships `.tflint.hcl` and `.checkov.yml` as a starting point.
- Run AWS Inspector against the produced AMI and gate promotion on the results. The included `null_resource.run_cis_scan` in `patterns/CIS_AL2023/main.tf` is one example; adapt it to your release flow.
- Separate the role that builds the AMI from the role that deploys clusters. Each should hold only the permissions it needs.
- Emit and retain build provenance (SLSA, in-toto, or signed metadata) that ties each AMI ID to its source commit, builder identity, and build logs.

### Layer 4–6 — Beyond the AMI

A hardened AMI does not by itself produce a hardened cluster. The operator remains responsible for at least:

- EKS endpoint access controls (private endpoint, allow-listed CIDRs, IAM access entries)
- Audit logging — control plane logs to CloudWatch, CloudTrail, and VPC Flow Logs
- Secrets handling — KMS envelope encryption for Kubernetes secrets, IRSA or EKS Pod Identity for workload credentials
- Workload controls — Pod Security Admission, NetworkPolicy, admission webhooks, runtime detection (e.g. GuardDuty for EKS, Falco)
- Image supply chain — signed container images, registry scanning, signature verification at admission
- AMI lifecycle — rebuild on a defined cadence to absorb upstream patches, then deregister and revoke trust on superseded AMIs

### Compliance scope

CIS Benchmark hardening of the host OS satisfies a subset of controls in frameworks such as NIST 800-53, PCI DSS, and HIPAA. It does not by itself produce compliance with any of them. Map the controls this AMI provides against your audit scope and document the residual controls you implement at higher layers.

## 👯 Dependencies

Terraform Modules:
- [terraform-aws-modules/vpc/aws](https://github.com/terraform-aws-modules/terraform-aws-vpc)
- [terraform-aws-modules/eks/aws](https://github.com/terraform-aws-modules/terraform-aws-eks)
- [terraform-aws-modules/eks/aws//modules/eks-managed-node-group](https://github.com/terraform-aws-modules/terraform-aws-eks/tree/master/modules/eks-managed-node-group)
- [aws-ia/eks-blueprints-addons/aws](https://github.com/aws-ia/terraform-aws-eks-blueprints-addons)

EKS Optimized AMI Packer Scripts
- [amazon-eks-ami](https://github.com/awslabs/amazon-eks-ami.git)

## ⑂ Forked to be part of the solution

- [cis-bottlerocket-benchmark-eks](https://github.com/aws-samples/containers-blog-maelstrom/tree/main/cis-bottlerocket-benchmark-eks)
- [amazon-eks-custom-amis](https://github.com/aws-samples/amazon-eks-custom-amis.git)

## 💻 Support & Feedback

This project is maintained by AWS engineers. It is not part of an AWS
service and support is provided as a best-effort by the EKS community. To provide feedback,
please use the [issues templates](issues)
provided. If you are interested in contributing to this project, see the
[Contribution guide](CONTRIBUTING.md).

## 🔒 Security

For the boundary between what this project secures and what the operator secures, see [Shared Responsibility](#-shared-responsibility) above. To report a vulnerability, see [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications).

## 📄 License

Apache-2.0 Licensed. See [LICENSE](LICENSE).

## 📚 Further Resources

Please see the link below for AWS resources that were used as references for this repository's solution. It includes detailed steps for achieving either Level 1 or Level 2 compliance based on each base AMI:

| Base AMI | Level 1 | Level 2 |
| --- | --- | --- |
| EKS Optimized AL 2023 | [https://aws.amazon.com/blogs/security/how-to-create-a-pipeline-for-hardening-amazon-eks-nodes-and-automate-updates/](https://aws.amazon.com/blogs/security/how-to-create-a-pipeline-for-hardening-amazon-eks-nodes-and-automate-updates/) | [https://aws.amazon.com/blogs/security/how-to-create-a-pipeline-for-hardening-amazon-eks-nodes-and-automate-updates/](https://aws.amazon.com/blogs/security/how-to-create-a-pipeline-for-hardening-amazon-eks-nodes-and-automate-updates/) |
| Bottlerocket AMI | Out of the box compliant | [ https://aws.amazon.com/blogs/containers/validating-amazon-eks-optimized-bottlerocket-ami-against-the-cis-benchmark/]( https://aws.amazon.com/blogs/containers/validating-amazon-eks-optimized-bottlerocket-ami-against-the-cis-benchmark/) and [EKS Security Workshop](https://catalog.workshops.aws/eks-security-immersionday/en-US/10-regulatory-compliance/2-cis-bottlerocket-eks) |
| CIS Amazon Linux 2023 Benchmark - Level 1 | No existent resource available so far | No existent resource available so far |
| CIS Amazon Linux 2023 Benchmark - Level 2 | No existent resource available so far | [https://aws.amazon.com/blogs/containers/automating-al2023-custom-hardened-ami-updates-for-amazon-eks-managed-nodes/](https://aws.amazon.com/blogs/containers/automating-al2023-custom-hardened-ami-updates-for-amazon-eks-managed-nodes/) |

