# Lab: Trust Policies and AssumeRole

## Quick Start
This lab teaches cross-account access patterns using IAM trust policies and the AssumeRole API. You'll learn how to securely delegate permissions between AWS accounts. Estimated time: 45 minutes.

## Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform installed (version 1.0+)
- Two AWS accounts (or ability to simulate cross-account scenario)
- Basic understanding of IAM roles and policies

## Learning Objectives
- Understand IAM trust policy structure and evaluation
- Configure cross-account role assumption
- Implement secure delegation patterns
- Troubleshoot AssumeRole permission issues

## Estimated Cost
$0.00 - This lab uses only IAM resources which are free

## Quick Commands
```bash
# Deploy infrastructure
cd terraform && terraform apply

# Follow lab steps
# See lab-steps.md for detailed instructions

# Cleanup
terraform destroy
```

## Security Note
This lab creates cross-account access patterns. Always follow the principle of least privilege and clean up resources when complete.
