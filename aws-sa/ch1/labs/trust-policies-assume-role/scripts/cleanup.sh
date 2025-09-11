#!/bin/bash

# AWS Certification Lab Cleanup Script
# Lab: Trust Policies and AssumeRole

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧹 Cleaning up Trust Policies and AssumeRole Lab${NC}"

# Function to ask for confirmation
confirm() {
    read -p "$1 (y/N): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Navigate to terraform directory
if [ ! -d "terraform" ]; then
    echo -e "${RED}❌ Terraform directory not found. Please run this script from the lab root directory.${NC}"
    exit 1
fi

cd terraform

# Check if terraform state exists
if [ ! -f "terraform.tfstate" ]; then
    echo -e "${YELLOW}⚠️  No terraform state found. Infrastructure may already be cleaned up.${NC}"
else
    # Show what will be destroyed
    echo -e "\n${YELLOW}📋 Resources that will be destroyed:${NC}"
    terraform plan -destroy
    
    echo -e "\n${RED}⚠️  WARNING: This will permanently delete all lab resources!${NC}"
    
    if confirm "Are you sure you want to destroy the lab infrastructure?"; then
        echo -e "\n${YELLOW}🗑️  Destroying Terraform resources...${NC}"
        terraform destroy -auto-approve
        echo -e "${GREEN}✅ Terraform resources destroyed successfully${NC}"
    else
        echo -e "\n${YELLOW}⏸️  Terraform cleanup cancelled${NC}"
    fi
fi

cd ..  # Return to lab root

# Clean up local files
echo -e "\n${YELLOW}🧹 Cleaning up local files...${NC}"

# Remove downloaded files from lab exercises
if [ -f "downloaded-file.txt" ]; then
    rm -f downloaded-file.txt
    echo -e "${GREEN}✅ Removed downloaded-file.txt${NC}"
fi

if [ -f "test-upload.txt" ]; then
    rm -f test-upload.txt
    echo -e "${GREEN}✅ Removed test-upload.txt${NC}"
fi

# Clean up terraform files (optional)
if confirm "Do you want to remove terraform state and plan files?"; then
    cd terraform
    if [ -f "terraform.tfstate" ]; then
        rm -f terraform.tfstate
        echo -e "${GREEN}✅ Removed terraform.tfstate${NC}"
    fi
    if [ -f "terraform.tfstate.backup" ]; then
        rm -f terraform.tfstate.backup
        echo -e "${GREEN}✅ Removed terraform.tfstate.backup${NC}"
    fi
    if [ -f "tfplan" ]; then
        rm -f tfplan
        echo -e "${GREEN}✅ Removed tfplan${NC}"
    fi
    if [ -d ".terraform" ]; then
        rm -rf .terraform
        echo -e "${GREEN}✅ Removed .terraform directory${NC}"
    fi
    cd ..
fi

# Clean up AWS CLI profile
echo -e "\n${YELLOW}🔐 AWS CLI Profile Cleanup${NC}"
if aws configure list --profile lab-developer &> /dev/null; then
    if confirm "Do you want to remove the 'lab-developer' AWS CLI profile?"; then
        # Remove profile sections from AWS config files
        aws configure set aws_access_key_id "" --profile lab-developer
        aws configure set aws_secret_access_key "" --profile lab-developer
        aws configure set region "" --profile lab-developer
        aws configure set output "" --profile lab-developer
        echo -e "${GREEN}✅ AWS CLI profile 'lab-developer' cleared${NC}"
        echo -e "${YELLOW}💡 Note: Profile entry may still exist in ~/.aws/config but credentials are cleared${NC}"
    fi
else
    echo -e "${GREEN}✅ No lab-developer profile found${NC}"
fi

# Clean up environment variables (in case they're still set)
echo -e "\n${YELLOW}🌍 Cleaning up environment variables...${NC}"
if [ -n "$AWS_ACCESS_KEY_ID" ] && [[ "$AWS_ACCESS_KEY_ID" == *"ASIA"* ]]; then
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
    echo -e "${GREEN}✅ Cleared temporary AWS credentials from environment${NC}"
else
    echo -e "${GREEN}✅ No temporary credentials found in environment${NC}"
fi

# Verification
echo -e "\n${BLUE}🔍 Running cleanup verification...${NC}"

# Check for remaining resources (basic check)
echo -e "${YELLOW}Checking for remaining IAM resources...${NC}"
if aws iam list-users --output text | grep -q "trust-policies-assumeRole"; then
    echo -e "${RED}⚠️  Some IAM users may still exist${NC}"
else
    echo -e "${GREEN}✅ No lab IAM users found${NC}"
fi

if aws iam list-roles --output text | grep -q "trust-policies-assumeRole"; then
    echo -e "${RED}⚠️  Some IAM roles may still exist${NC}"
else
    echo -e "${GREEN}✅ No lab IAM roles found${NC}"
fi

echo -e "${YELLOW}Checking for remaining S3 buckets...${NC}"
if aws s3 ls | grep -q "trust-policies-assumeRole"; then
    echo -e "${RED}⚠️  Some S3 buckets may still exist${NC}"
    echo -e "${YELLOW}💡 If buckets remain, they may contain objects. Try: aws s3 rb s3://bucket-name --force${NC}"
else
    echo -e "${GREEN}✅ No lab S3 buckets found${NC}"
fi

# Final summary
echo -e "\n${GREEN}🎉 Lab cleanup completed!${NC}"
echo -e "\n${BLUE}📊 Cleanup Summary:${NC}"
echo "• Terraform infrastructure destroyed"
echo "• Local lab files removed"
echo "• AWS CLI profile cleared"
echo "• Environment variables cleaned"

echo -e "\n${YELLOW}💡 Recommended next steps:${NC}"
echo "• Review your AWS bill to confirm no unexpected charges"
echo "• Check CloudTrail logs if you want to review the lab activities"
echo "• Consider running this lab again with different configurations"

echo -e "\n${BLUE}📚 Thank you for completing the Trust Policies and AssumeRole lab!${NC}"
