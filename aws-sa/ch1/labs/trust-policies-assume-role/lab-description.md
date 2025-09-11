# Lab Description: Trust Policies and AssumeRole

## Overview
This lab demonstrates the implementation of cross-account access patterns using IAM trust policies and the AssumeRole API. You'll create a realistic scenario where a developer in Account A needs to access S3 resources in Account B through a properly configured IAM role. This pattern is fundamental to enterprise AWS architectures and multi-account strategies.

## Architecture Overview

### Diagram 1: Cross-Account Trust Relationship
```
┌─────────────────────────────────────┐    ┌─────────────────────────────────────┐
│            Account A                │    │            Account B                │
│         (111111111111)              │    │         (222222222222)              │
│                                     │    │                                     │
│  ┌─────────────────────────────┐    │    │  ┌─────────────────────────────┐    │
│  │        IAM User             │    │    │  │        IAM Role             │    │
│  │      (Developer)            │    │    │  │     (S3AccessRole)          │    │
│  │                             │    │    │  │                             │    │
│  │  Policies:                  │    │    │  │  Trust Policy:              │    │
│  │  - AssumeRole Permission    │    │    │  │  - Allow Account A          │    │
│  └─────────────────────────────┘    │    │  │  - Principal: arn:aws:iam  │    │
│                │                    │    │  │    ::111111111111:user/dev │    │
│                │                    │    │  │                             │    │
│                │ AssumeRole Request  │    │  │  Permissions Policy:        │    │
│                └────────────────────────────▶│  - S3 Full Access          │    │
│                                     │    │  └─────────────────────────────┘    │
│                ◄────────────────────────────┐                │                │
│           Temporary Credentials     │    │                   │                │
│                                     │    │                   │ Access         │
└─────────────────────────────────────┘    │                   v                │
                                           │  ┌─────────────────────────────┐    │
                                           │  │        S3 Bucket            │    │
                                           │  │     (target-bucket)         │    │
                                           │  │                             │    │
                                           │  │  - Cross-account access     │    │
                                           │  │  - Secure resource sharing  │    │
                                           │  └─────────────────────────────┘    │
                                           └─────────────────────────────────────┘
```

### Diagram 2: AssumeRole Process Flow
```
Developer          AWS CLI           STS Service        Target Role         S3 Service
    │                 │                   │                 │                 │
    │ 1. aws sts      │                   │                 │                 │
    │   assume-role   │                   │                 │                 │
    │────────────────▶│ 2. AssumeRole     │                 │                 │
    │                 │   API Call        │                 │                 │
    │                 │──────────────────▶│ 3. Validate     │                 │
    │                 │                   │   Trust Policy  │                 │
    │                 │                   │────────────────▶│ 4. Check        │
    │                 │                   │                 │   Permissions   │
    │                 │ 5. Temporary      │◄────────────────│                 │
    │                 │   Credentials     │                 │                 │
    │                 │◄──────────────────│                 │                 │
    │ 6. Credentials  │                   │                 │                 │
    │   (AccessKeyId, │                   │                 │                 │
    │   SecretKey,    │                   │                 │                 │
    │   SessionToken) │                   │                 │                 │
    │◄────────────────│                   │                 │                 │
    │                 │                   │                 │                 │
    │ 7. aws s3 ls    │                   │                 │                 │
    │   (with temp    │                   │                 │                 │
    │   credentials)  │                   │                 │                 │
    │────────────────▶│ 8. S3 API Call   │                 │                 │
    │                 │   with temp creds │                 │                 │
    │                 │─────────────────────────────────────────────────────▶│
    │                 │ 9. S3 Response    │                 │                 │
    │ 10. Success     │◄─────────────────────────────────────────────────────│
    │◄────────────────│                   │                 │                 │
```

### Diagram 3: Trust Policy Evaluation Flow
```
AssumeRole Request
        │
        v
┌─────────────────────────────────────────────────────────────┐
│                Trust Policy Evaluation                      │
└─────────────────────────────────────────────────────────────┘
        │
        v
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Principal Check │    │ Condition Check │    │ Action Check    │
│                 │    │                 │    │                 │
│ Is requester    │ AND│ MFA required?   │ AND│ sts:AssumeRole  │
│ from trusted    │    │ Time window?    │    │ allowed?        │
│ account?        │    │ Source IP?      │    │                 │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          v                      v                      v
     ✅ ALLOW              ✅ ALLOW              ✅ ALLOW
          │                      │                      │
          └──────────┬───────────┼──────────────────────┘
                     v           v
              ┌─────────────────────┐
              │   Role Assumed      │
              │ Temporary Creds     │
              │    Generated        │
              └─────────────────────┘
                     │
                     v
              ┌─────────────────────┐
              │ Permission Policy   │
              │    Evaluation       │
              │ (What can the role  │
              │     actually do?)   │
              └─────────────────────┘
```

## Services Used
- **IAM Roles**: Cross-account role with trust policy for secure delegation
- **IAM Users**: Developer identity in source account with AssumeRole permissions
- **AWS STS**: Security Token Service for temporary credential generation
- **S3**: Target service demonstrating cross-account resource access
- **AWS CLI**: Command-line interface for role assumption and resource access

## Learning Outcomes
After completing this lab, you will understand:
- How to structure IAM trust policies for cross-account access
- The AssumeRole API workflow and temporary credential lifecycle
- Security best practices for cross-account delegation
- Troubleshooting common AssumeRole permission issues
- Implementing least-privilege access across AWS accounts

## Real-World Applications
This lab demonstrates patterns commonly used for:
- Multi-account enterprise architectures with centralized resource access
- DevOps automation requiring cross-account deployment capabilities
- Third-party vendor access to specific AWS resources with time-limited permissions
- Compliance scenarios requiring separation of duties across account boundaries
- Disaster recovery and backup strategies across multiple AWS accounts
