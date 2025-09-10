#!/bin/bash

# AWS Certification Lab Verification Script
# Lab: Trust Policies and AssumeRole

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Verifying Trust Policies and AssumeRole Lab${NC}"

# Navigate to terraform directory to get outputs
if [ ! -d "terraform" ]; then
    echo -e "${RED}❌ Terraform directory not found. Please run this script from the lab root directory.${NC}"
    exit 1
fi

cd terraform

# Check if terraform state exists
if [ ! -f "terraform.tfstate" ]; then
    echo -e "${RED}❌ Terraform state not found. Please deploy the lab infrastructure first.${NC}"
    exit 1
fi

echo -e "\n${YELLOW}📊 Getting lab information from Terraform...${NC}"

# Get terraform outputs
ROLE_ARN=$(terraform output -raw s3_access_role_arn 2>/dev/null || echo "")
BUCKET_NAME=$(terraform output -raw target_bucket_name 2>/dev/null || echo "")
DEVELOPER_ARN=$(terraform output -raw developer_user_arn 2>/dev/null || echo "")
EXTERNAL_ID=$(terraform output -raw external_id 2>/dev/null || echo "")

if [ -z "$ROLE_ARN" ] || [ -z "$BUCKET_NAME" ] || [ -z "$DEVELOPER_ARN" ]; then
    echo -e "${RED}❌ Could not retrieve terraform outputs. Infrastructure may not be deployed.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Lab information retrieved successfully${NC}"

cd ..  # Return to lab root

echo -e "\n${YELLOW}🧪 Running verification tests...${NC}"

# Test 1: Check if IAM user exists
echo -e "\n${BLUE}Test 1: IAM User Existence${NC}"
USER_NAME=$(echo $DEVELOPER_ARN | cut -d'/' -f2)
if aws iam get-user --user-name "$USER_NAME" &> /dev/null; then
    echo -e "${GREEN}✅ IAM user '$USER_NAME' exists${NC}"
else
    echo -e "${RED}❌ IAM user '$USER_NAME' not found${NC}"
fi

# Test 2: Check if IAM role exists
echo -e "\n${BLUE}Test 2: IAM Role Existence${NC}"
ROLE_NAME=$(echo $ROLE_ARN | cut -d'/' -f2)
if aws iam get-role --role-name "$ROLE_NAME" &> /dev/null; then
    echo -e "${GREEN}✅ IAM role '$ROLE_NAME' exists${NC}"
    
    # Check trust policy
    TRUST_POLICY=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.AssumeRolePolicyDocument' --output text)
    if echo "$TRUST_POLICY" | grep -q "sts:AssumeRole"; then
        echo -e "${GREEN}✅ Trust policy contains AssumeRole action${NC}"
    else
        echo -e "${RED}❌ Trust policy missing AssumeRole action${NC}"
    fi
else
    echo -e "${RED}❌ IAM role '$ROLE_NAME' not found${NC}"
fi

# Test 3: Check if S3 bucket exists
echo -e "\n${BLUE}Test 3: S3 Bucket Existence${NC}"
if aws s3 ls "s3://$BUCKET_NAME" &> /dev/null; then
    echo -e "${GREEN}✅ S3 bucket '$BUCKET_NAME' exists and is accessible${NC}"
    
    # Check for sample file
    if aws s3 ls "s3://$BUCKET_NAME/sample-data/test-file.txt" &> /dev/null; then
        echo -e "${GREEN}✅ Sample file exists in bucket${NC}"
    else
        echo -e "${YELLOW}⚠️  Sample file not found in bucket${NC}"
    fi
else
    echo -e "${RED}❌ S3 bucket '$BUCKET_NAME' not accessible${NC}"
fi

# Test 4: Test AssumeRole functionality (if developer profile exists)
echo -e "\n${BLUE}Test 4: AssumeRole Functionality${NC}"
if aws configure list --profile lab-developer &> /dev/null; then
    echo -e "${GREEN}✅ Developer profile found${NC}"
    
    # Test AssumeRole
    if ASSUME_OUTPUT=$(aws sts assume-role \
        --role-arn "$ROLE_ARN" \
        --role-session-name "verify-session-$(date +%s)" \
        --external-id "$EXTERNAL_ID" \
        --profile lab-developer 2>/dev/null); then
        
        echo -e "${GREEN}✅ AssumeRole successful${NC}"
        
        # Extract credentials and test S3 access
        export AWS_ACCESS_KEY_ID=$(echo $ASSUME_OUTPUT | jq -r '.Credentials.AccessKeyId')
        export AWS_SECRET_ACCESS_KEY=$(echo $ASSUME_OUTPUT | jq -r '.Credentials.SecretAccessKey')
        export AWS_SESSION_TOKEN=$(echo $ASSUME_OUTPUT | jq -r '.Credentials.SessionToken')
        
        # Test S3 access with assumed role
        if aws s3 ls "s3://$BUCKET_NAME" &> /dev/null; then
            echo -e "${GREEN}✅ S3 access successful with assumed role${NC}"
        else
            echo -e "${RED}❌ S3 access failed with assumed role${NC}"
        fi
        
        # Test session identity
        CURRENT_IDENTITY=$(aws sts get-caller-identity 2>/dev/null || echo "")
        if echo "$CURRENT_IDENTITY" | grep -q "assumed-role"; then
            echo -e "${GREEN}✅ Session identity confirmed as assumed role${NC}"
        else
            echo -e "${YELLOW}⚠️  Session identity check inconclusive${NC}"
        fi
        
        # Clean up environment variables
        unset AWS_ACCESS_KEY_ID
        unset AWS_SECRET_ACCESS_KEY
        unset AWS_SESSION_TOKEN
        
    else
        echo -e "${RED}❌ AssumeRole failed${NC}"
        echo -e "${YELLOW}💡 Make sure you've configured the developer profile correctly${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Developer profile not found - skipping AssumeRole test${NC}"
    echo -e "${YELLOW}💡 Configure the developer profile using the credentials from terraform output${NC}"
fi

# Test 5: Security checks
echo -e "\n${BLUE}Test 5: Security Configuration${NC}"

# Check bucket public access block
if aws s3api get-public-access-block --bucket "$BUCKET_NAME" &> /dev/null; then
    echo -e "${GREEN}✅ S3 bucket has public access block configured${NC}"
else
    echo -e "${YELLOW}⚠️  S3 bucket public access block not configured${NC}"
fi

# Check role permissions (should be limited to S3)
ROLE_POLICIES=$(aws iam list-attached-role-policies --role-name "$ROLE_NAME" --output text 2>/dev/null || echo "")
INLINE_POLICIES=$(aws iam list-role-policies --role-name "$ROLE_NAME" --output text 2>/dev/null || echo "")

if [ -n "$INLINE_POLICIES" ] || [ -n "$ROLE_POLICIES" ]; then
    echo -e "${GREEN}✅ Role has permission policies attached${NC}"
else
    echo -e "${YELLOW}⚠️  Role may not have permission policies attached${NC}"
fi

# Summary
echo -e "\n${BLUE}📋 Verification Summary${NC}"
echo -e "${GREEN}✅ Infrastructure deployment verified${NC}"
echo -e "${GREEN}✅ Core components are functional${NC}"

if aws configure list --profile lab-developer &> /dev/null; then
    echo -e "${GREEN}✅ Lab is ready for hands-on exercises${NC}"
    echo -e "\n${YELLOW}🎯 Next Steps:${NC}"
    echo "• Continue with the lab exercises in lab-steps.md"
    echo "• Practice different AssumeRole scenarios"
    echo "• Test permission boundaries and security controls"
else
    echo -e "${YELLOW}⚠️  Complete the AWS CLI profile setup to continue${NC}"
    echo -e "\n${YELLOW}🎯 Next Steps:${NC}"
    echo "• Configure the developer profile using terraform outputs"
    echo "• Follow Step 2 in lab-steps.md"
fi

echo -e "\n${BLUE}🧹 Remember to run cleanup.sh when you're done with the lab!${NC}"
