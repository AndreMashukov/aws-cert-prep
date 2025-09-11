# Lab Steps: Trust Policies and AssumeRole

## Prerequisites Verification
Before starting, ensure you have:
- [ ] AWS CLI configured with sufficient permissions
- [ ] Terraform installed and working (`terraform version`)
- [ ] Basic understanding of IAM roles and policies
- [ ] Two AWS CLI profiles (or ability to switch credentials)

## Step 1: Infrastructure Deployment
### Deploy AWS Resources
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

**Expected Output:**
Terraform should create:
- 1 IAM user (developer)
- 1 IAM role (S3 access role)
- 1 S3 bucket with sample file
- 2 IAM policies (assume role and S3 access)
- 1 access key pair

**Verification:**
```bash
# Verify the resources were created
aws iam get-user --user-name $(terraform output -raw developer_user_arn | cut -d'/' -f2)
aws iam get-role --role-name $(terraform output -raw s3_access_role_arn | cut -d'/' -f2)
aws s3 ls $(terraform output -raw target_bucket_name)
```

## Step 2: Configure AWS CLI with Developer Credentials
### Set up Developer Profile
```bash
# Get the developer credentials from terraform output
DEVELOPER_ACCESS_KEY=$(terraform output -raw developer_access_key_id)
DEVELOPER_SECRET_KEY=$(terraform output -raw developer_secret_access_key)
AWS_REGION=$(terraform output -raw lab_summary | jq -r '.region')

# Configure a new AWS CLI profile for the developer
aws configure set aws_access_key_id $DEVELOPER_ACCESS_KEY --profile lab-developer
aws configure set aws_secret_access_key $DEVELOPER_SECRET_KEY --profile lab-developer
aws configure set region $AWS_REGION --profile lab-developer
aws configure set output json --profile lab-developer
```

**What this does:**
Creates a new AWS CLI profile named 'lab-developer' with the credentials of the IAM user created by Terraform. This simulates being the developer in Account A who needs to access resources in Account B.

**Expected Output:**
No output, but the profile should be created successfully.

**Verification:**
```bash
# Test the developer profile
aws sts get-caller-identity --profile lab-developer
```

**Troubleshooting:**
- If you see "InvalidUserID.NotFound": The IAM user wasn't created properly
- If you see "AccessDenied": Check that the access keys are correct

## Step 3: Test Direct Access (Should Fail)
### Attempt Direct S3 Access
```bash
# Try to access S3 directly with developer credentials (this should fail)
aws s3 ls --profile lab-developer

# Try to access the specific bucket (this should also fail)
BUCKET_NAME=$(terraform output -raw target_bucket_name)
aws s3 ls s3://$BUCKET_NAME --profile lab-developer
```

**What this does:**
Demonstrates that the developer user has no direct permissions to access S3 resources, only permission to assume roles.

**Expected Output:**
You should see an "AccessDenied" error, confirming that direct access is properly restricted.

**Troubleshooting:**
- If the command succeeds: Check that the developer user doesn't have any additional S3 policies attached

## Step 4: Assume the Cross-Account Role
### Use AssumeRole API
```bash
# Get the role ARN and external ID
ROLE_ARN=$(terraform output -raw s3_access_role_arn)
EXTERNAL_ID=$(terraform output -raw external_id)

# Assume the role and capture temporary credentials
ASSUME_ROLE_OUTPUT=$(aws sts assume-role \
  --role-arn $ROLE_ARN \
  --role-session-name lab-session-$(date +%s) \
  --external-id $EXTERNAL_ID \
  --profile lab-developer)

# Extract temporary credentials
export AWS_ACCESS_KEY_ID=$(echo $ASSUME_ROLE_OUTPUT | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $ASSUME_ROLE_OUTPUT | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $ASSUME_ROLE_OUTPUT | jq -r '.Credentials.SessionToken')

echo "✅ Successfully assumed role!"
echo "Session expires at: $(echo $ASSUME_ROLE_OUTPUT | jq -r '.Credentials.Expiration')"
```

**What this does:**
Uses the AWS STS AssumeRole API to obtain temporary credentials for the cross-account role. The external ID provides an additional layer of security against the "confused deputy" problem.

**Expected Output:**
JSON response containing temporary credentials (AccessKeyId, SecretAccessKey, SessionToken) and session information.

**Verification:**
```bash
# Verify you're now using the assumed role
aws sts get-caller-identity
```

**Troubleshooting:**
- If you see "AccessDenied": Check that the trust policy includes the developer user ARN
- If you see "InvalidParameterValue": Verify the external ID matches what's in the trust policy
- If jq is not installed: Install it or extract the credentials manually from the JSON output

## Step 5: Test S3 Access with Assumed Role
### Access S3 Resources
```bash
# List all S3 buckets (should now work)
aws s3 ls

# List contents of the target bucket
aws s3 ls s3://$BUCKET_NAME/

# Download the sample file
aws s3 cp s3://$BUCKET_NAME/sample-data/test-file.txt ./downloaded-file.txt

# Read the downloaded file
cat downloaded-file.txt

# Upload a new test file
echo "Hello from assumed role at $(date)" > test-upload.txt
aws s3 cp test-upload.txt s3://$BUCKET_NAME/uploads/

# Verify the upload
aws s3 ls s3://$BUCKET_NAME/uploads/
```

**What this does:**
Demonstrates successful cross-account access using the temporary credentials from the assumed role. Shows both read and write capabilities.

**Expected Output:**
- Bucket listing should show your target bucket
- File download should succeed and display the sample content
- File upload should succeed and be visible in the bucket listing

**Troubleshooting:**
- If you see "AccessDenied": The role's permission policy may not grant sufficient S3 access
- If uploads fail: Check that the S3 bucket policy doesn't block uploads
- If downloads fail: Verify the sample file exists in the bucket

## Step 6: Explore Role Session Information
### Analyze Temporary Credentials
```bash
# Get detailed information about the current session
aws sts get-caller-identity

# Decode the session information from the assumed role ARN
ASSUMED_ROLE_ARN=$(aws sts get-caller-identity --query 'Arn' --output text)
echo "Current assumed role session: $ASSUMED_ROLE_ARN"

# Check session expiration (credentials should be temporary)
echo $ASSUME_ROLE_OUTPUT | jq '.Credentials.Expiration'

# Test session boundaries by trying to access IAM (should fail)
aws iam list-users 2>/dev/null || echo "❌ IAM access denied (expected - role has no IAM permissions)"
```

**What this does:**
Helps you understand the scope and limitations of the assumed role session, including credential expiration and permission boundaries.

**Expected Output:**
- Caller identity should show the assumed role ARN with session name
- Expiration should show a future timestamp (within the session duration)
- IAM commands should fail, demonstrating least-privilege access

## Verification and Testing
### Confirm Lab Objectives
Run these commands to verify your lab is working correctly:
```bash
# 1. Verify role assumption works
aws sts get-caller-identity | jq '.Arn' | grep -q "assumed-role" && echo "✅ Role assumption successful"

# 2. Verify S3 access works
aws s3 ls s3://$BUCKET_NAME/ | grep -q "test-file.txt" && echo "✅ S3 read access confirmed"

# 3. Verify upload capability
test -f downloaded-file.txt && echo "✅ File download successful"

# 4. Check session expiration
EXPIRY=$(echo $ASSUME_ROLE_OUTPUT | jq -r '.Credentials.Expiration')
echo "Session expires: $EXPIRY"
```

### Test Scenarios
Try these scenarios to deepen understanding:

1. **Session Expiration**: Wait for the session to expire (or modify session duration to 15 minutes) and try accessing S3 again. You should get credential errors.

2. **Permission Boundaries**: Try accessing other AWS services like EC2 or RDS with the assumed role credentials. These should fail, demonstrating the principle of least privilege.

3. **Trust Policy Conditions**: Modify the trust policy to add IP address restrictions or MFA requirements and test how they affect role assumption.

## Learning Questions
Consider these questions as you work through the lab:
- Why did we need to use AssumeRole instead of granting S3 permissions directly to the developer user?
- What would happen if we removed the external ID from the trust policy?
- How does the session duration affect security and usability?
- What are the advantages of temporary credentials vs. long-term access keys?
- How would you implement this pattern for hundreds of developers across multiple accounts?

## Cleanup
**IMPORTANT:** Always clean up resources to avoid charges:
```bash
# Clear environment variables
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN

# Remove downloaded files
rm -f downloaded-file.txt test-upload.txt

# Remove AWS CLI profile
aws configure --profile lab-developer list # Check if profile exists
aws configure --profile lab-developer remove # Remove profile if desired

# Destroy Terraform resources
cd terraform
terraform destroy
```

Verify cleanup completed:
```bash
# Check that IAM resources were deleted
aws iam get-user --user-name trust-policies-assumeRole-developer 2>/dev/null || echo "✅ IAM user deleted"
aws iam get-role --role-name trust-policies-assumeRole-s3-access-role 2>/dev/null || echo "✅ IAM role deleted"

# Check that S3 bucket was deleted
aws s3 ls | grep trust-policies-assumeRole || echo "✅ S3 bucket deleted"
```

## Extensions
To extend this lab, try:

1. **Multi-Account Setup**: If you have access to multiple AWS accounts, modify the Terraform to create the role in a different account and test true cross-account access.

2. **MFA Enforcement**: Add MFA requirements to the trust policy and test role assumption with MFA devices.

3. **Session Duration Testing**: Experiment with different session durations and observe how it affects your workflow.

4. **Conditional Access**: Add time-based or IP-based conditions to the trust policy and test access from different contexts.

5. **Chained Role Assumption**: Create a chain of roles where one assumed role can assume another role, demonstrating multi-hop delegation patterns.

6. **CloudTrail Integration**: Enable CloudTrail and examine the logs generated by AssumeRole operations to understand the audit trail.

7. **Cross-Region Testing**: Test role assumption and resource access across different AWS regions to understand regional boundaries.
