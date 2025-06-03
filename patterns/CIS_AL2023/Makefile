.PHONY: plan apply create-hardened-ami create-eks-cluster run-cis-scan run-static-tests

# Variables
NAME = CIS_AL2023
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

create-hardened-ami:
	@echo "Creating Hardened AMIs..."
	@if [ ! -d "amazon-eks-ami" ]; then \
		git clone https://github.com/awslabs/amazon-eks-ami.git --branch v20250519; \
	fi
	@packer plugins install github.com/hashicorp/amazon || true
	@cd amazon-eks-ami && { \
		echo "Waiting for PR https://github.com/awslabs/amazon-eks-ami/pull/1922"; \
		cp ../template.json templates/al2023/template.json; \
		cp ../cleanup.sh templates/shared/provisioners/cleanup.sh; \
		timestamp=$$(date +%s); \
		\
		echo "Building Level 1 AMI..."; \
		ami_name="CIS_Amazon_Linux_2023_Benchmark_Level_1-$$timestamp"; \
        sed -i -e 's#sudo chmod +x $$binary#sudo chmod 755 $$binary#g' templates/al2023/provisioners/install-worker.sh; \
        sed -i -e 's#aws --version#sudo /bin/aws --version#g' templates/shared/provisioners/generate-version-info.sh; \
        sed -i -e 's#aws #sudo /bin/aws #g' templates/shared/runtime/bin/cache-pause-container; \
        sed -i -e 's#/tmp#/home/ec2-user#g' templates/al2023/variables-default.json; \
        sed -i -e 's#cache-pause-container#sudo cache-pause-container#g' templates/al2023/provisioners/cache-pause-container.sh; \
		AMI_ID=$$(aws ec2 describe-images \
			--owners aws-marketplace \
			--filters "Name=architecture,Values=x86_64" "Name=name,Values=CIS Amazon Linux 2023 Benchmark - Level 1 - v05*" \
			--query 'sort_by(Images, &CreationDate)[-1].ImageId' \
			--region $(AWS_REGION) \
			--output text); \
		PACKER_BINARY=packer make k8s=1.33 \
			os_distro=al2023 \
			aws_region=$(AWS_REGION) \
			source_ami_id=$$AMI_ID \
			source_ami_owners=679593333241 \
			source_ami_filter_name="CIS Amazon Linux 2023 Benchmark - Level 1 - v05**" \
			subnet_id=$(SUBNET_ID) \
			associate_public_ip_address=true \
			remote_folder=/home/ec2-user \
			ami_name=$$ami_name \
			pause_container_image=602401143452.dkr.ecr.$(AWS_REGION).amazonaws.com/eks/pause:3.10 \
			iam_instance_profile=packer-role-CIS_AL2023 \
			run_tags={Name=$(NAME)} || exit 1; \
		\
		LEVEL1_AMI_ID=$$(jq -r '.builds[-1].artifact_id | split(":") | .[1]' manifest.json); \
		echo "Level 1 AMI ID: $$LEVEL1_AMI_ID"; \
		aws ssm put-parameter \
			--name "/cis_ami/CIS_AL2023/CIS_Amazon_Linux_2023_Benchmark_Level_1/ami_id" \
			--type "String" \
			--value "$$LEVEL1_AMI_ID" \
			--region $(AWS_REGION) \
			--overwrite; \
		\
		echo "Building Level 2 AMI..."; \
		timestamp=$$(date +%s); \
		ami_name="CIS_Amazon_Linux_2023_Benchmark_Level_2-$$timestamp"; \
		AMI_ID=$$(aws ec2 describe-images \
			--owners aws-marketplace \
			--filters "Name=architecture,Values=x86_64" "Name=name,Values=CIS Amazon Linux 2023 Benchmark - Level 2 - v05*" \
			--query 'sort_by(Images, &CreationDate)[-1].ImageId' \
			--region $(AWS_REGION) \
			--output text) && \
		\
		PACKER_BINARY=packer make k8s=1.33 \
			os_distro=al2023 \
			aws_region=$(AWS_REGION) \
			source_ami_id=$$AMI_ID \
			source_ami_owners=679593333241 \
			source_ami_filter_name="CIS Amazon Linux 2023 Benchmark - Level 2 - v05*" \
			subnet_id=$(SUBNET_ID) \
			associate_public_ip_address=true \
			remote_folder=/home/ec2-user \
			ami_name=$$ami_name \
			pause_container_image=602401143452.dkr.ecr.$(AWS_REGION).amazonaws.com/eks/pause:3.10 \
			iam_instance_profile=packer-role-CIS_AL2023 \
			run_tags={Name=$(NAME)} || exit 1; \
		\
		LEVEL2_AMI_ID=$$(jq -r '.builds[-1].artifact_id | split(":") | .[1]' manifest.json); \
		echo "Level 2 AMI ID: $$LEVEL2_AMI_ID"; \
		aws ssm put-parameter \
			--name "/cis_ami/CIS_AL2023/CIS_Amazon_Linux_2023_Benchmark_Level_2/ami_id" \
			--type "String" \
			--value "$$LEVEL2_AMI_ID" \
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
