# Shared Responsibility

This project produces a hardened EKS node AMI. An AMI is one layer of a secure EKS deployment. The matrix below clarifies which controls this repository provides and which controls remain with the operator. Treat it as a starting point and map it to your own threat model and compliance scope.

| Layer | Scope | Owner |
|---|---|---|
| 1. Base AMI | CIS Marketplace AMI or AWS EKS-optimized AMI | AWS / CIS |
| 2. AMI hardening overlay | EKS components layered onto CIS images, CIS controls layered onto EKS-optimized images, or CIS controls applied at boot for Bottlerocket — packaged in this repo | This project |
| 3. Build environment | Workstation or CI runner, OS, network egress, credentials, secrets, and supply chain used to run Terraform and Packer | **Operator** |
| 4. AWS account and infrastructure | IAM, KMS, VPC design, security groups, EKS cluster endpoint access, CloudTrail, AMI distribution permissions | **Operator** |
| 5. Cluster and workloads | Kubernetes RBAC, Pod Security Admission, NetworkPolicy, image signing, admission control, runtime detection | **Operator** |
| 6. Operations | AMI rebuild cadence, drift detection, vulnerability response, deregistration of superseded AMIs | **Operator** |

## Layer 1 — Base AMI (AWS / CIS)

The starting image is built and maintained outside this project:

- **AWS EKS-optimized AMIs** (`amazon-eks-node-al2023-*`) are produced by AWS, ship the EKS bootstrap components, and receive regular patch releases. AWS is responsible for the kernel, package versions, and EKS-specific binaries shipped in the image.
- **CIS Amazon Linux 2023 Benchmark AMIs** (Level 1 and Level 2) are published by the Center for Internet Security on AWS Marketplace. CIS is responsible for the benchmark controls applied to those images and for republishing when Amazon Linux 2023 is patched upstream.
- **Bottlerocket AMIs** are produced by AWS and ship most CIS controls applied by default.

What this means for the operator:

- Subscribe to release notifications for the base you choose. A patched base AMI does not propagate to your fleet automatically; you must rebuild.
- Treat the base AMI ID as part of your software bill of materials. Record it in build artifacts.

## Layer 2 — AMI hardening overlay (this project)

This repository sits between the base AMI and your cluster. It ships three patterns, each with a distinct base and overlay strategy:

| Pattern | Base AMI | Overlay strategy |
|---|---|---|
| `CIS_AL2023` | CIS Amazon Linux 2023 Benchmark Marketplace AMI | Install EKS node components on top of a CIS-hardened OS — containerd, kubelet, the EKS bootstrap (`nodeadm`), the AWS CLI, the ECR credential provider, the SOCI snapshotter, and SSM Agent. |
| `EKS_Optimized_AL2023` | AWS EKS-optimized AL2023 AMI | Apply the CIS Amazon Linux 2023 Benchmark Build Kit on top of an EKS-ready OS, with an `exclusion_list.txt` for controls that conflict with Kubernetes operation. |
| `BOTTLEROCKET` | AWS EKS-optimized Bottlerocket AMI | Most CIS controls are satisfied out of the box. Remaining Level 2 controls are applied at node launch via Bottlerocket settings (kernel sysctls, lockdown, module restrictions) and a privileged bootstrap container delivered through ECR. |

What this layer guarantees:

- Reproducible Packer builds driven by version-controlled scripts under `patterns/<pattern>/template_files/` (for the `CIS_AL2023` and `EKS_Optimized_AL2023` patterns).
- Kernel and key packages held by `dnf versionlock` so post-build updates do not silently drift the image (AL2023 patterns).
- A content-hash tagged, IMMUTABLE-repository bootstrap container for the Bottlerocket pattern, so identical Dockerfile content always resolves to the same ECR image digest.
- A CIS scan of the resulting node group via AWS Inspector (`null_resource.run_cis_scan`) so you can verify the overlay achieved the expected control coverage.

What this layer does not guarantee:

- That `var.branch` resolves to the same content over time. The `CIS_AL2023` and `EKS_Optimized_AL2023` patterns clone `awslabs/amazon-eks-ami` at build time using this value. Pin it to a release tag (for example `v20260505`) rather than a moving branch like `main`, so rebuilds are reproducible.
- That the overlay covers controls outside the CIS Amazon Linux benchmark scope (Kubernetes-level controls, container runtime hardening beyond defaults, workload identity, etc.). Those belong to Layers 4–6.
- Compatibility with arbitrary base AMI versions. Upstream changes (kernel major version, package renames, SELinux policy updates) can break the overlay; rebuild and test before promoting an AMI.

## Layer 3 — Hardening the build environment

The host that runs `terraform apply` and `packer build` becomes a high-value target. It holds credentials, produces AMIs that downstream workloads will trust, and writes Terraform state that may contain sensitive values.

Minimum expectations:

- **Run from a dedicated, hardened build host or CI runner.** Do not run AMI builds from a shared developer workstation. If a workstation is unavoidable, scope its credentials accordingly.
- **Use short-lived credentials.** Prefer AWS IAM Identity Center, EC2 instance profiles, or OIDC federation from your CI provider. Do not configure long-lived `AKIA...` access keys for build automation.
- **Apply least privilege to the build role.** The role needs EC2, S3 (for the EKS binary bucket), IAM `PassRole` on the Packer instance profile, and EKS permissions. It does not need `AdministratorAccess`.
- **Pin tool versions and verify checksums.** Pin `terraform`, `packer`, and Terraform provider versions. Commit `.terraform.lock.hcl`. Verify SHA256 sums of any binaries downloaded by the build.
- **Protect Terraform state.** Use a remote backend with encryption, versioning, and state locking (S3 + DynamoDB, or Terraform Cloud). State contains resource identifiers and may contain sensitive outputs.
- **Restrict and log network egress.** Builds reach `github.com`, AWS APIs, `awscli.amazonaws.com`, `efa-installer.amazonaws.com`, and the EKS binary bucket. Allow-list those endpoints where you can and log all egress.
- **Control AMI distribution.** Tag every AMI with the source commit SHA. Restrict `ModifyImageAttribute` and scope `ami_users` to accounts that should consume the image.

## Layer 3a — Hardening the CI/CD pipeline

If you automate this build, treat the pipeline itself as a production system:

- Require branch protection and code review on any branch that triggers an AMI build.
- Authenticate the pipeline to AWS via OIDC federation. Constrain the IAM trust policy to the specific repository, branch, and workflow path.
- Pin GitHub Actions (or equivalent) to commit SHAs, not tags. Prefer ephemeral runners.
- Run `terraform validate`, `tflint`, and `checkov` on every change. This repository ships per-pattern `.tflint.hcl` and `.checkov.yml` files (see `patterns/<name>/`) as a starting point.
- Run AWS Inspector against the produced AMI and gate promotion on the results. The included `null_resource.run_cis_scan` in `patterns/CIS_AL2023/main.tf` is one example; adapt it to your release flow.
- Separate the role that builds the AMI from the role that deploys clusters. Each should hold only the permissions it needs.
- Emit and retain build provenance (SLSA, in-toto, or signed metadata) that ties each AMI ID to its source commit, builder identity, and build logs.

## Layer 4–6 — Beyond the AMI

A hardened AMI does not by itself produce a hardened cluster. The operator remains responsible for at least:

- EKS endpoint access controls (private endpoint, allow-listed CIDRs, IAM access entries)
- Audit logging — control plane logs to CloudWatch, CloudTrail, and VPC Flow Logs
- Secrets handling — KMS envelope encryption for Kubernetes secrets, IRSA or EKS Pod Identity for workload credentials
- Workload controls — Pod Security Admission, NetworkPolicy, admission webhooks, runtime detection (e.g. GuardDuty for EKS, Falco)
- Image supply chain — signed container images, registry scanning, signature verification at admission
- AMI lifecycle — rebuild on a defined cadence to absorb upstream patches, then deregister and revoke trust on superseded AMIs

## Compliance scope

CIS Benchmark hardening of the host OS satisfies a subset of controls in frameworks such as NIST 800-53 and PCI DSS. It does not by itself produce compliance with any of them. Map the controls this AMI provides against your audit scope and document the residual controls you implement at higher layers.
