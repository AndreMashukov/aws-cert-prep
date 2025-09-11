#!/bin/bash

# AWS Certification Lab Setup Script
# Lab: Trust Policies and AssumeRole

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Setting up Trust Policies and AssumeRole Lab${NC}"

# Check prerequisites
echo -e "\n${YELLOW}📋 Checking prerequisites...${NC}"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ AWS CLI found: $(aws --version)${NC}"

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform is not installed. Please install it first.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Terraform found: $(terraform version | head -1)${NC}"

# Check if jq is installed (needed for JSON parsing)
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}⚠️  jq is not installed. Installing jq for JSON parsing...${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install jq
        else
            echo -e "${RED}❌ Please install jq manually: https://stedolan.github.io/jq/download/${NC}"
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        sudo apt-get update && sudo apt-get install -y jq
    else
        echo -e "${RED}❌ Please install jq manually: https://stedolan.github.io/jq/download/${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}✅ jq found: $(jq --version)${NC}"

# Check AWS credentials
echo -e "\n${YELLOW}🔐 Checking AWS credentials...${NC}"
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured. Please run 'aws configure' first.${NC}"
    exit 1
fi

CURRENT_IDENTITY=$(aws sts get-caller-identity)
ACCOUNT_ID=$(echo $CURRENT_IDENTITY | jq -r '.Account')
echo -e "${GREEN}✅ AWS credentials configured for account: $ACCOUNT_ID${NC}"

# Check permissions (basic test)
echo -e "\n${YELLOW}🔍 Testing AWS permissions...${NC}"
if ! aws iam list-users --max-items 1 &> /dev/null; then
    echo -e "${YELLOW}⚠️  Limited IAM permissions detected. Lab may require additional permissions.${NC}"
else
    echo -e "${GREEN}✅ Basic IAM permissions confirmed${NC}"
fi

# Navigate to terraform directory
if [ ! -d "terraform" ]; then
    echo -e "${RED}❌ Terraform directory not found. Please run this script from the lab root directory.${NC}"
    exit 1
fi

cd terraform

# Check if terraform.tfvars exists, if not create from example
if [ ! -f "terraform.tfvars" ]; then
    echo -e "\n${YELLOW}📝 Creating terraform.tfvars from example...${NC}"
    cp terraform.tfvars.example terraform.tfvars
    echo -e "${GREEN}✅ terraform.tfvars created. You may customize it if needed.${NC}"
fi

# Initialize Terraform
echo -e "\n${YELLOW}🏗️  Initializing Terraform...${NC}"
terraform init

# Validate Terraform configuration
echo -e "\n${YELLOW}✅ Validating Terraform configuration...${NC}"
terraform validate

# Plan the deployment
echo -e "\n${YELLOW}📋 Planning Terraform deployment...${NC}"
terraform plan -out=tfplan

# Ask for confirmation
echo -e "\n${YELLOW}❓ Ready to deploy the lab infrastructure?${NC}"
read -p "Do you want to proceed with 'terraform apply'? (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "\n${YELLOW}🚀 Deploying infrastructure...${NC}"
    terraform apply tfplan
    
    # Show important outputs
    echo -e "\n${GREEN}🎉 Lab infrastructure deployed successfully!${NC}"
    echo -e "\n${YELLOW}📊 Important Information:${NC}"
    echo "Lab Summary:"
    terraform output lab_summary
    echo
    echo "Developer User ARN:"
    terraform output developer_user_arn
    echo
    echo "S3 Access Role ARN:"
    terraform output s3_access_role_arn
    echo
    echo "Target Bucket Name:"
    terraform output target_bucket_name
    echo
    echo -e "${GREEN}✅ Setup complete! You can now follow the lab-steps.md instructions.${NC}"
else
    echo -e "\n${YELLOW}⏸️  Deployment cancelled. You can run 'terraform apply' manually when ready.${NC}"
fi

echo -e "\n${GREEN}🔗 Next Steps:${NC}"
echo "1. Follow the instructions in lab-steps.md"
echo "2. Start with Step 2 (Configure AWS CLI with Developer Credentials)"
echo "3. Remember to run the cleanup script when finished"

cd ..  # Return to lab root directory
