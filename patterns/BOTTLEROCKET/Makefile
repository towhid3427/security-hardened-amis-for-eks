.PHONY: plan apply build-bottlerocket-cis-bootstrap-image create-eks-cluster run-cis-scan run-static-tests

# Variables
NAME = BOTTLEROCKET
TERRAFORM_DIR = .
TERRAFORM_CLUSTER_DIR = ./eks-cluster
AWS_REGION ?= us-west-2
STATIC_TESTS_SCRIPT = ./static_tests.sh
ACCOUNT_ID := $(shell aws sts get-caller-identity --query Account --output text)
ECR_REPO = $(ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com
IMAGE_NAME = bottlerocket-cis-bootstrap-image
IMAGE_TAG = latest

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

# Build and push container image with caching and parallel builds
build-bottlerocket-cis-bootstrap-image:
	@echo "Building bottlerocket bootstrap container image..."
	@cd bottlerocket-cis-bootstrap-image && \
	DOCKER_BUILDKIT=1 docker build \
		--build-arg BUILDKIT_INLINE_CACHE=1 \
		--cache-from $(ECR_REPO)/$(IMAGE_NAME):$(IMAGE_TAG) \
		--tag $(IMAGE_NAME):$(IMAGE_TAG) \
		--tag $(ECR_REPO)/$(IMAGE_NAME):$(IMAGE_TAG) \
		--progress=plain \
		. || (echo "Docker build failed!"; exit 1)
	@aws ecr get-login-password --region $(AWS_REGION) | \
		docker login --username AWS --password-stdin $(ECR_REPO)
	@docker push $(ECR_REPO)/$(IMAGE_NAME):$(IMAGE_TAG) || (echo "Docker push failed!"; exit 1)

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
		--targets accountIds=$(ACCOUNT_ID),targetResourceTags={eks:cluster-name=$(NAME)} || \
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
	@echo "Container Management:"
	@echo "  build-bottlerocket-cis-bootstrap-image - Build and push CIS bootstrap image"
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
