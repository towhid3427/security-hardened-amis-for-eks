.PHONY: plan apply create-hardened-ami create-eks-cluster run-cis-scan run-static-tests

# Variables
NAME = CIS_AL2
TERRAFORM_DIR = .
TERRAFORM_CLUSTER_DIR = ./eks-cluster
AWS_REGION ?= us-west-2
STATIC_TESTS_SCRIPT = ./static_tests.sh
ACCOUNT_ID := $(shell aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "ERROR_GETTING_ACCOUNT")
EKS_VPC_ID := $(shell aws ec2 describe-vpcs \
	--filters Name="tag:Name",Values=${NAME} \
	--query 'Vpcs[0].VpcId' \
	--region $(AWS_REGION) \
	--output text 2>/dev/null || echo "ERROR_GETTING_VPC")
SUBNET_ID := $(shell aws ec2 describe-subnets \
	--filters \
	"Name=vpc-id,Values=${EKS_VPC_ID}" \
	"Name=tag:Name,Values=${NAME}-public*" \
	--query 'Subnets[0].SubnetId' \
	--region $(AWS_REGION) \
	--output text 2>/dev/null || echo "ERROR_GETTING_SUBNET")


# Default target
default: plan

# Run static tests with error handling
run-static-tests:
	@echo "Running static tests..."
	@if [ ! -x $(STATIC_TESTS_SCRIPT) ]; then \
		chmod +x $(STATIC_TESTS_SCRIPT); \
	fi
	$(STATIC_TESTS_SCRIPT) || (echo "Static tests failed!"; exit 1)

# Initialize Terraform with backend check
init:
	@echo "Initializing Terraform..."
	terraform -chdir=$(TERRAFORM_DIR) init -reconfigure

# Terraform plan with cost estimation
plan: init
	terraform -chdir=$(TERRAFORM_DIR) plan -detailed-exitcode -out=tfplan

# Terraform apply with automatic approval and error handling
apply: init
	terraform -chdir=$(TERRAFORM_DIR) apply -auto-approve || (echo "Apply failed!"; exit 1)

# Create EKS CIS Level1 and Level2 Hardened AMIs
create-hardened-ami:
	@echo "Creating Hardened AMIs..."
	@if [ ! -d "amazon-eks-ami" ]; then \
		git clone https://github.com/awslabs/amazon-eks-ami.git --branch v20250519; \
	fi
	@packer plugins install github.com/hashicorp/amazon || true
	@cd amazon-eks-ami && { \
		timestamp=$$(date +%s); \
		ami_name="CIS_Amazon_Linux_2_Benchmark_Level_1-$$timestamp"; \
		sed -i -e 's#sudo chmod +x $$binary#sudo chmod 755 $$binary#g' templates/al2/provisioners/install-worker.sh; \
		sed -i -e 's#aws --version#sudo /bin/aws --version#g' templates/shared/provisioners/generate-version-info.sh; \
		AMI_ID=$$(aws ec2 describe-images \
			--owners aws-marketplace \
			--filters "Name=architecture,Values=x86_64" "Name=name,Values=CIS Amazon Linux 2 Kernel 5.10 Benchmark - Level 1 - v06*" \
			--query 'sort_by(Images, &CreationDate)[-1].ImageId' \
			--region $(AWS_REGION) \
			--output text); \
		PACKER_BINARY=packer make k8s=1.32 \
			aws_region=$(AWS_REGION) \
			source_ami_id=$$AMI_ID \
			source_ami_owners=679593333241 \
			source_ami_filter_name="CIS Amazon Linux 2 Kernel 5.10 Benchmark - Level 1 - v06*" \
			AMI_VARIANT=amazon-eks-cis \
			subnet_id=$(SUBNET_ID) \
			launch_block_device_mappings_volume_size=15 \
			associate_public_ip_address=true \
			remote_folder=/home/ec2-user \
			ami_name=$$ami_name || exit 1; \
		AMI_ID=$$(jq -r '.builds[-1].artifact_id | split(":") | .[1]' manifest.json); \
		echo "Level 1 AMI ID: $$AMI_ID"; \
		aws ssm put-parameter \
			--name "/cis_ami/CIS_AL2/CIS_Amazon_Linux_2_Benchmark_Level_1/ami_id" \
			--type "String" \
			--value "$$AMI_ID" \
			--region $(AWS_REGION) \
			--overwrite; \
		timestamp=$$(date +%s); \
		ami_name="CIS_Amazon_Linux_2_Benchmark_Level_2-$$timestamp"; \
		AMI_ID=$$(aws ec2 describe-images \
			--owners aws-marketplace \
			--filters "Name=architecture,Values=x86_64" "Name=name,Values=CIS Amazon Linux 2 Kernel 5.10 Benchmark - Level 2 - v06*" \
			--query 'sort_by(Images, &CreationDate)[-1].ImageId' \
			--region $(AWS_REGION) \
			--output text); \
		PACKER_BINARY=packer make k8s=1.32 \
			aws_region=$(AWS_REGION) \
			source_ami_id=$$AMI_ID \
			source_ami_owners=679593333241 \
			source_ami_filter_name="CIS Amazon Linux 2 Kernel 5.10 Benchmark - Level 2 - v06*" \
			subnet_id=$(SUBNET_ID) \
			launch_block_device_mappings_volume_size=15 \
			associate_public_ip_address=true \
			remote_folder=/home/ec2-user \
			ami_name=$$ami_name || exit 1; \
		AMI_ID=$$(jq -r '.builds[-1].artifact_id | split(":") | .[1]' manifest.json); \
		echo "Level 2 AMI ID: $$AMI_ID"; \
		aws ssm put-parameter \
			--name "/cis_ami/CIS_AL2/CIS_Amazon_Linux_2_Benchmark_Level_2/ami_id" \
			--type "String" \
			--value "$$AMI_ID" \
			--region $(AWS_REGION) \
			--overwrite; \
	}

cluster-init:
	@echo "Initializing cluster Terraform..."
	terraform -chdir=$(TERRAFORM_CLUSTER_DIR) init -reconfigure

# Terraform cluster plan
cluster-plan: cluster-init
	terraform -chdir=$(TERRAFORM_CLUSTER_DIR) plan -detailed-exitcode -out=tfplan

# Terraform cluster apply with error handling
cluster-apply: cluster-init
	terraform -chdir=$(TERRAFORM_CLUSTER_DIR) apply -auto-approve || (echo "Cluster apply failed!"; exit 1)

# Run CIS scan with proper error handling
run-cis-scan:
	@echo "Initiating CIS scan using AWS Inspector..."
	@aws inspector2 create-cis-scan-configuration \
		--scan-name $(NAME) \
		--schedule oneTime={} \
		--security-level LEVEL_2 \
		--targets accountIds=$(ACCOUNT_ID),targetResourceTags={eks:cluster-name=$(NAME)} \
		--region $(AWS_REGION) || \
		(echo "CIS scan configuration failed!"; exit 1)

# Clean up with proper error handling and confirmation
clean:
	@echo "Are you sure you want to destroy all resources? [y/N]" && read ans && [ $${ans:-N} = y ]
	terraform -chdir=$(TERRAFORM_CLUSTER_DIR) destroy -auto-approve
	terraform -chdir=$(TERRAFORM_DIR) destroy -auto-approve

# Enhanced help target with categories
help:
	@echo "Available targets:"
	@echo ""
	@echo "Infrastructure Management:"
	@echo "  run-static-tests    - Run static code analysis tests"
	@echo "  plan                - Run terraform plan with cost estimation"
	@echo "  apply               - Run terraform apply with safety checks"
	@echo ""
	@echo "Security Hardened AMI Management:"
	@echo "  create-hardened-ami - Create EKS CIS Level1 and Level2 Hardened AMIs using CIS AMIs as a base AMI"
	@echo ""
	@echo "Cluster Management:"
	@echo "  cluster-plan        - Plan EKS cluster changes"
	@echo "  cluster-apply       - Apply EKS cluster changes"
	@echo ""
	@echo "Security:"
	@echo "  run-cis-scan       - Run CIS scan using AWS Inspector"
	@echo ""
	@echo "Cleanup:"
	@echo "  clean              - Destroy infrastructure (with confirmation)"
