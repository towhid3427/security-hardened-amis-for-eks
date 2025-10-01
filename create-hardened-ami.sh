#!/bin/bash

# Colors and formatting
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'  # No Color
CLEANUP_TEXT="${RED}${BOLD}3. Clean up Resources${NC}"

# Default aws_region
DEFAULT_AWS_REGION="us-west-2"

# Function to select AMI type
select_ami_type() {
    echo -e "${BLUE}Select AMI Type:${NC}"
    echo "-------------------------------------------"
    echo "1. BOTTLEROCKET"
    echo "2. CIS_AL2"
    echo "3. CIS_AL2023"
    echo "4. EKS_Optimized_AL2"
    echo "5. EKS_Optimized_AL2023"
    echo "-------------------------------------------"
    echo -n "Enter your choice (1/2/3/4/5): "
    read -r ami_type_choice

    case "$ami_type_choice" in
        1)
            AMI_TYPE="BOTTLEROCKET"
            ;;
        2)
            AMI_TYPE="CIS_AL2"
            ;;
        3)
            AMI_TYPE="CIS_AL2023"
            ;;
        4)
            AMI_TYPE="EKS_Optimized_AL2"
            ;;
        5)
            AMI_TYPE="EKS_Optimized_AL2023"
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            exit 1
            ;;
    esac

    # Verify if directory exists
    if [ ! -d "patterns/$AMI_TYPE" ]; then
        echo -e "${RED}Error: Directory patterns/$AMI_TYPE does not exist${NC}"
        exit 1
    fi

    echo -e "${GREEN}Selected AMI Type: $AMI_TYPE${NC}"
    cd "patterns/$AMI_TYPE" || exit 1
}

initialize_terraform() {
        # Run terraform init -upgrade
    echo -e "\n${YELLOW}Initializing Terraform...${NC}"
    if terraform init -upgrade; then
        echo -e "${GREEN}Terraform initialization successful!${NC}"
    else
        echo -e "${RED}Terraform initialization failed!${NC}"
        exit 1
    fi
}

# Function to confirm operation
confirm_operation() {
    local operation=$1
    echo -e "\n${YELLOW}Do you want to proceed with the $operation?${NC}"
    echo -e "${RED}${BOLD}Warning: This action will create/modify/delete infrastructure resources${NC}"
    echo -n "Enter 'yes' to continue or any other key to abort: "
    read -r confirm
    if [[ "$confirm" != "yes" ]]; then
        echo -e "${RED}Operation aborted${NC}"
        exit 0
    fi
}

# Function to validate aws_region
validate_aws_region() {
    local aws_region=$1
    if aws ec2 describe-regions --region-names "$aws_region" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to validate if subnet exists and is public
validate_subnet() {
    local subnet_id=$1
    local aws_region=$2
    
    echo -e "${BLUE}Validating subnet ID in region ${aws_region}...${NC}"
    
    if ! aws ec2 describe-subnets --subnet-ids "$subnet_id" --region "$aws_region" >/dev/null 2>&1; then
        echo -e "${RED}Error: Invalid subnet ID or subnet doesn't exist in region ${aws_region}.${NC}"
        return 1
    fi

    local vpc_id=$(aws ec2 describe-subnets --subnet-ids "$subnet_id" --region "$aws_region" --query 'Subnets[0].VpcId' --output text)
    local route_table_id=$(aws ec2 describe-route-tables --region "$aws_region" \
        --filters "Name=association.subnet-id,Values=$subnet_id" \
        --query 'RouteTables[0].RouteTableId' --output text)

    if [ "$route_table_id" == "None" ]; then
        route_table_id=$(aws ec2 describe-route-tables --region "$aws_region" \
            --filters "Name=vpc-id,Values=$vpc_id" "Name=association.main,Values=true" \
            --query 'RouteTables[0].RouteTableId' --output text)
    fi

    local has_igw=$(aws ec2 describe-route-tables --region "$aws_region" \
        --route-table-ids "$route_table_id" \
        --query 'RouteTables[0].Routes[?GatewayId!=`null` && starts_with(GatewayId, `igw-`)]' \
        --output text)

    if [ -z "$has_igw" ]; then
        echo -e "${RED}Error: Subnet is not public (no route to Internet Gateway).${NC}"
        return 1
    fi

    echo -e "${GREEN}Subnet ID is valid and public.${NC}"
    return 0
}

# Function to get state values from S3 backend
get_state_values() {
    echo -e "${BLUE}Checking Terraform state from S3 backend...${NC}"
    
    # Get S3 backend configuration from versions.tf
    local s3_bucket=$(grep -A 5 'backend "s3"' versions.tf | grep 'bucket' | awk -F'"' '{print $2}')
    local s3_key=$(grep -A 5 'backend "s3"' versions.tf | grep 'key' | awk -F'"' '{print $2}')
    local s3_region=$(grep -A 5 'backend "s3"' versions.tf | grep 'region' | awk -F'"' '{print $2}')

    #echo "Debug: S3 Bucket: $s3_bucket, Key: $s3_key, Region: $s3_region"


    if [ -z "$s3_bucket" ] || [ -z "$s3_key" ] || [ -z "$s3_region" ]; then
        echo -e "${YELLOW}Unable to find complete S3 backend configuration${NC}"
        return 1
    fi

    echo -e "${BLUE}Retrieving state from S3 bucket: ${s3_bucket}${NC}"

    # Try to get terraform state JSON with error handling
    if ! terraform_output=$(terraform show -json 2>/dev/null); then
        echo -e "${YELLOW}Unable to read terraform state from S3${NC}"
        return 1
    fi

    # Check if terraform output is valid JSON
    if ! echo "$terraform_output" | jq empty 2>/dev/null; then
        echo -e "${YELLOW}Invalid terraform state format${NC}"
        return 1
    fi

    # Try to extract values
     state_values=$(echo "$terraform_output" | jq -r '
         .values.root_module | .. | 
         select(.resources?) | 
         .resources[] | 
         select(.name == "only_create_hardened_ami_level_1" or 
                .name == "only_create_hardened_ami_level_2" or 
                .name == "create_hardened_ami_level_2" or
                .name == "docker_build_push-image-only" or
                .name == "docker_build_push") | 
        {aws_region: .values.triggers.aws_region} | 

        select(.aws_region != null)
     ')

    #echo "Debug: Extracted state values: $state_values"

    if [ -n "$state_values" ] && [ "$state_values" != "null" ]; then
        state_aws_region=$(echo "$state_values" | jq -r '.aws_region')

        if [ -n "$state_aws_region" ] && 
           [ "$state_aws_region" != "null" ]; then
            #echo -e "${GREEN}Region Found in state file: ${state_aws_region}${NC}"
            echo -e "${BLUE}State file location: s3://${s3_bucket}/${s3_key}${NC}"
            return 0
        fi
    fi
    
    echo -e "${YELLOW}No values found in Terraform state${NC}"
    return 1
}

# First, select AMI type
select_ami_type

# Main menu

# If AMI_TYPE is BOTTLEROCKET, show limited menu options
if [ "$AMI_TYPE" = "BOTTLEROCKET" ]; then
    echo -e "\n${BLUE}Select Operation for ${GREEN}${AMI_TYPE}${BLUE} AMI:${NC}"
    echo "-------------------------------------------"
    echo "1. Create Complete Infrastructure"
    echo "2. Create Only CIS Bootstrape Image"
    echo "3. Cleanup Resources"
    echo "-------------------------------------------"
    echo -e "${YELLOW}Note: Option 1 will create VPC, Subnets, and other required resources${NC}"
    echo -n "Enter your choice (1/2/3): "
    read -r choice

case "$choice" in
    1)
        while true; do
            echo -n "Enter AWS region (Default Region: us-west-2): "
            read -r aws_region
            aws_region=${aws_region:-$DEFAULT_AWS_REGION}
            if validate_aws_region "$aws_region"; then
                echo -e "${GREEN}Planning infrastructure creation in ${aws_region}...${NC}"
                initialize_terraform
                terraform plan -var="aws_region=${aws_region}"
                confirm_operation "infrastructure creation"
                echo -e "${GREEN}Creating infrastructure in ${aws_region}...${NC}"
                terraform apply -var="aws_region=${aws_region}" --auto-approve
                break
            else
                echo -e "${RED}Invalid region. Please try again.${NC}"
            fi
        done
        ;;
    2)
        # Get aws_region first
        while true; do
            echo -n "Enter AWS region (default: ${DEFAULT_AWS_REGION}): "
            read -r aws_region
            aws_region=${aws_region:-$DEFAULT_AWS_REGION}
            if validate_aws_region "$aws_region"; then
                break
            else
                echo -e "${RED}Invalid region. Please try again.${NC}"
            fi
        done
        
        echo -e "${GREEN}Planning CIS Bootstrape Image creation in ${aws_region}...${NC}"
        initialize_terraform
        terraform plan \
            -var="cis_bootstrape_image=true" \
            -var="aws_region=$aws_region" \
            -target=null_resource.docker_build_push-image-only
        confirm_operation "CIS Bootstrape Image"
        echo -e "${GREEN}Creating CIS Bootstrape Image in ${aws_region}...${NC}"
        terraform apply \
            -var="cis_bootstrape_image=true" \
            -var="aws_region=$aws_region" \
            -target=null_resource.docker_build_push-image-only \
            --auto-approve
        ;;
    3)
        echo -e "${RED}Select Operation for Cleanup? ${NC}"
        echo "-------------------------------------------"
        echo -e "${RED}1. Complete Infrastructure ${NC}"
        echo "2. CIS Bootstrape Image"
        echo "-------------------------------------------"
        echo -e "${YELLOW}Note: Option 2 will only delete the resource from terraform state file. Also none of the options will delete the Docker Image and ECR Repository. You would need to manually delete those resources${NC}"

        echo -ne "${RED}Enter your choice (1/2): ${NC}"
        read -r cleanup_choice

        case "$cleanup_choice" in
            1)
                # For entire stack cleanup, we only need the region
                echo -e "${BLUE}Checking state for AWS region...${NC}"
                if get_state_values; then
                    echo -e "${GREEN}Available region in state: $state_aws_region ${NC}"
                else
                    echo -e "${RED}Error: No AWS region found in state file. Cannot proceed with cleanup.${NC}"                   
                fi
                # Get aws_region first
                while true; do
                    echo -n "Enter AWS region (default: ${DEFAULT_AWS_REGION}): "
                    read -r aws_region
                    aws_region=${aws_region:-$DEFAULT_AWS_REGION}
                    if validate_aws_region "$aws_region"; then
                       break
                    else
                       echo -e "${RED}Invalid region. Please try again.${NC}"
                    fi
                done 
                echo -e "${RED}Planning destruction of all Infrastructure in ${aws_region} created using this terraform...${NC}"
                terraform plan -destroy -var="aws_region=${aws_region}"
                confirm_operation "stack deletion"
                echo -e "${RED}Destroying all Infrastructure in ${aws_region}...${NC}"
                terraform destroy -var="aws_region=${aws_region}" --auto-approve
                ;;

            2)
                # For AMI resource cleanup, we need region
                echo -e "${BLUE}Checking state for AWS region...${NC}"
                if get_state_values; then
                    echo -e "${GREEN}Available region in state: $state_aws_region ${NC}"
                else
                    echo -e "${RED}Error: No AWS region found in state file. Cannot proceed with cleanup.${NC}"                   
                fi
                # Get aws_region first
                while true; do
                    echo -n "Enter AWS region (default: ${DEFAULT_AWS_REGION}): "
                    read -r aws_region
                    aws_region=${aws_region:-$DEFAULT_AWS_REGION}
                    if validate_aws_region "$aws_region"; then
                       break
                    else
                       echo -e "${RED}Invalid region. Please try again.${NC}"
                    fi
                done 

                if [ "$cleanup_choice" == "2" ]; then
                    echo -e "${RED}Planning destruction of CIS Bootstrape Image resources. This will not delete the ECR Repository / Image..${NC}"
                    terraform plan -destroy \
                        -var="cis_bootstrape_image=true" \
                        -var="aws_region=$aws_region" \
                        -target=null_resource.docker_build_push-image-only
                    confirm_operation "CIS Bootstrape Image"
                    echo -e "${RED}Destroying CIS Bootstrape Image resources. This will not delete the ECR Repository / Image....${NC}"
                    terraform destroy \
                        -var="cis_bootstrape_image=true" \
                        -var="aws_region=$aws_region" \
                        -target=null_resource.docker_build_push-image-only \
                        --auto-approve
                fi
                ;;
            *)
                echo "Invalid choice"
                exit 1
                ;;
        esac
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

else

echo -e "\n${BLUE}Select Operation for ${GREEN}${AMI_TYPE}${BLUE} AMI:${NC}"
echo "-------------------------------------------"
echo "1. Create Complete Infrastructure"
echo "2. Create Only Hardened AMI"
echo -e "$CLEANUP_TEXT"
echo "-------------------------------------------"
echo -e "${YELLOW}Note: Option 1 & 2 will create VPC, Subnets, and other required resources${NC}"
echo -n "Enter your choice (1/2/3): "
read -r choice

case "$choice" in
    1)
        while true; do
            echo -n "Enter AWS region (Default Region: us-west-2): "
            read -r aws_region
            aws_region=${aws_region:-$DEFAULT_AWS_REGION}
            if validate_aws_region "$aws_region"; then
                echo -e "${GREEN}Planning infrastructure creation in ${aws_region}...${NC}"
                initialize_terraform
                terraform plan -var="aws_region=${aws_region}"
                confirm_operation "infrastructure creation"
                echo -e "${GREEN}Creating infrastructure in ${aws_region}...${NC}"
                terraform apply -var="aws_region=${aws_region}" --auto-approve
                break
            else
                echo -e "${RED}Invalid region. Please try again.${NC}"
            fi
        done
        ;;
    2)
        echo -e "${BLUE}Which Hardened AMI Level do you want to create?${NC}"
        echo "1. CIS Level 1"
        echo "2. CIS Level 2"
        echo "3. Both Level 1 and Level 2"
        echo -n "Enter your choice (1/2/3): "
        read -r ami_level

        # Get aws_region first
        while true; do
            echo -n "Enter AWS region (default: ${DEFAULT_AWS_REGION}): "
            read -r aws_region
            aws_region=${aws_region:-$DEFAULT_AWS_REGION}
            if validate_aws_region "$aws_region"; then
                break
            else
                echo -e "${RED}Invalid region. Please try again.${NC}"
            fi
        done

        # Then get subnet ID
        while true; do
            echo -n "Enter public subnet ID: "
            read -r subnet_id
            if validate_subnet "$subnet_id" "$aws_region"; then
                break
            else
                echo -e "${BLUE}Please enter a valid public subnet ID or press Ctrl+C to exit${NC}"
            fi
        done
        
        case "$ami_level" in
            1)
                echo -e "${GREEN}Planning CIS Level 1 Hardened AMI creation in ${aws_region}...${NC}"
                initialize_terraform
                terraform plan \
                    -var="create_ami_level1=true" \
                    -var="public_subnet_id=$subnet_id" \
                    -var="aws_region=$aws_region" \
                    -target=null_resource.only_create_hardened_ami_level_1
                confirm_operation "Level 1 AMI creation"
                echo -e "${GREEN}Creating CIS Level 1 Hardened AMI in ${aws_region}...${NC}"
                terraform apply \
                    -var="create_ami_level1=true" \
                    -var="public_subnet_id=$subnet_id" \
                    -var="aws_region=$aws_region" \
                    -target=null_resource.only_create_hardened_ami_level_1 \
                    --auto-approve
                ;;
            2)
                echo -e "${GREEN}Planning CIS Level 2 Hardened AMI creation in ${aws_region}...${NC}"
                initialize_terraform
                terraform plan \
                    -var="create_ami_level2=true" \
                    -var="public_subnet_id=$subnet_id" \
                    -var="aws_region=$aws_region" \
                    -target=null_resource.only_create_hardened_ami_level_2
                confirm_operation "Level 2 AMI creation"
                echo -e "${GREEN}Creating CIS Level 2 Hardened AMI in ${aws_region}...${NC}"
                terraform apply \
                    -var="create_ami_level2=true" \
                    -var="public_subnet_id=$subnet_id" \
                    -var="aws_region=$aws_region" \
                    -target=null_resource.only_create_hardened_ami_level_2 \
                    --auto-approve
                ;;
            3)
                echo -e "${GREEN}Creating Both CIS Level 1 and CIS Level 2 Hardened AMIs in ${aws_region}...${NC}"
                initialize_terraform
                terraform plan \
                    -var="create_ami_level1=true" \
                    -var="create_ami_level2=true" \
                    -var="public_subnet_id=$subnet_id" \
                    -var="aws_region=$aws_region" \
                    -target=null_resource.only_create_hardened_ami_level_1 \
                    -target=null_resource.only_create_hardened_ami_level_2
                confirm_operation "Both Level 1 and Level 2 AMI creation"
                echo -e "${GREEN}Creating Both CIS Level 1 and CIS Level 2 Hardened AMIs in ${aws_region}...${NC}"
                initialize_terraform
                terraform apply \
                    -var="create_ami_level1=true" \
                    -var="create_ami_level2=true" \
                    -var="public_subnet_id=$subnet_id" \
                    -var="aws_region=$aws_region" \
                    -target=null_resource.only_create_hardened_ami_level_1 \
                    -target=null_resource.only_create_hardened_ami_level_2 \
                    --auto-approve
                ;;
            *)
                echo "Invalid choice"
                exit 1
                ;;
        esac
        ;;
    3)
        echo -e "${RED}Select Operation for Cleanup? ${NC}"
        echo "-------------------------------------------"
        echo -e "${RED}1. Complete Infrastructure ${NC}"
        echo "2. CIS Level 1 AMI Resources"
        echo "3. CIS Level 2 AMI Resources"
        echo "4. Both CIS Level 1 and CIS Level 2"
        echo "-------------------------------------------"
        echo -e "${YELLOW}Note: Option 2,3,4 will only delete the resource from terraform state file. Also none of the options will delete the CIS AMI which was created. You would need to manually delete those AMIs${NC}"

        echo -ne "${RED}Enter your choice (1/2/3/4): ${NC}"
        read -r cleanup_choice

        case "$cleanup_choice" in
            1)
                # For entire stack cleanup, we only need the region
                echo -e "${BLUE}Checking state for AWS region...${NC}"
                if get_state_values; then
                    echo -e "${GREEN}Available region in state: $state_aws_region ${NC}"
                else
                    echo -e "${RED}Error: No AWS region found in state file. Cannot proceed with cleanup.${NC}"                   
                fi
                # Get aws_region first
                while true; do
                    echo -n "Enter AWS region (default: ${DEFAULT_AWS_REGION}): "
                    read -r aws_region
                    aws_region=${aws_region:-$DEFAULT_AWS_REGION}
                    if validate_aws_region "$aws_region"; then
                       break
                    else
                       echo -e "${RED}Invalid region. Please try again.${NC}"
                    fi
                done                    
                echo -e "${RED}Planning destruction of all Infrastructure in ${aws_region} created using this terraform...${NC}"
                terraform plan -destroy -var="aws_region=${aws_region}"
                confirm_operation "stack deletion"
                echo -e "${RED}Destroying all Infrastructure in ${aws_region}...${NC}"
                terraform destroy -var="aws_region=${aws_region}" --auto-approve
                ;;

            2|3|4)
                # For AMI resource cleanup, we need region.
                echo -e "${BLUE}Checking state for required values...${NC}"
                if get_state_values; then
                    echo -e "${GREEN}Available region in state: $state_aws_region ${NC}"
                else
                    echo -e "${RED}Error: No AWS region found in state file. Cannot proceed with cleanup.${NC}"                   
                fi
                # Get aws_region first
                while true; do
                    echo -n "Enter AWS region (default: ${DEFAULT_AWS_REGION}): "
                    read -r aws_region
                    aws_region=${aws_region:-$DEFAULT_AWS_REGION}
                    if validate_aws_region "$aws_region"; then
                       break
                    else
                       echo -e "${RED}Invalid region. Please try again.${NC}"
                    fi
                done 

                if [ "$cleanup_choice" == "2" ]; then
                    echo -e "${RED}Planning destruction of CIS Level 1 AMI resources...${NC}"
                    terraform plan -destroy \
                        -var="create_ami_level1=true" \
                        -var="aws_region=$aws_region" \
                        -target=null_resource.only_create_hardened_ami_level_1
                    confirm_operation "Level 1 AMI resource deletion"
                    echo -e "${RED}Destroying CIS Level 1 AMI resources...${NC}"
                    terraform destroy \
                        -var="create_ami_level1=true" \
                        -var="aws_region=$aws_region" \
                        -target=null_resource.only_create_hardened_ami_level_1 \
                        --auto-approve
                elif [ "$cleanup_choice" == "3" ]; then
                    echo -e "${RED}Planning destruction of CIS Level 2 AMI resources...${NC}"
                    terraform plan -destroy \
                        -var="create_ami_level2=true" \
                        -var="aws_region=$aws_region" \
                        -target=null_resource.only_create_hardened_ami_level_2
                    confirm_operation "Level 2 AMI resource deletion"
                    echo -e "${RED}Destroying CIS Level 2 AMI resources...${NC}"
                    terraform destroy \
                        -var="create_ami_level2=true" \
                        -var="aws_region=$aws_region" \
                        -target=null_resource.only_create_hardened_ami_level_2 \
                        --auto-approve
                else
                    echo -e "${RED}Planning destruction of both CIS Level 1 and CIS Level 2 AMI resources...${NC}"
                    terraform plan -destroy \
                        -var="create_ami_level1=true" \
                        -var="create_ami_level2=true" \
                        -var="aws_region=$aws_region" \
                        -target=null_resource.only_create_hardened_ami_level_1 \
                        -target=null_resource.only_create_hardened_ami_level_2
                    confirm_operation "Both Level 1 and Level 2 AMI resource deletion"
                    echo -e "${RED}Destroying both CIS Level 1 and CIS Level 2 AMI resources...${NC}"
                    terraform destroy \
                        -var="create_ami_level1=true" \
                        -var="create_ami_level2=true" \
                        -var="aws_region=$aws_region" \
                        -target=null_resource.only_create_hardened_ami_level_1 \
                        -target=null_resource.only_create_hardened_ami_level_2 \
                        --auto-approve
                fi
                ;;
            *)
                echo "Invalid choice"
                exit 1
                ;;
        esac
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac
fi