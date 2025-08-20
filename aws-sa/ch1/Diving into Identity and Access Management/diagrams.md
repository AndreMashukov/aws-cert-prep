# AWS Identity and Access Management (IAM) - Architecture Diagrams

## Overview
These diagrams illustrate the most complex and critical IAM concepts that Solutions Architects must master, focusing on policy evaluation logic, cross-account access patterns, and enterprise-scale identity management architectures.

## Diagram 1: IAM Policy Evaluation Logic Flow

```
                        Request Initiated
                              |
                              v
                    ┌─────────────────┐
                    │  Authentication │
                    │    (Who?)       │
                    └─────────┬───────┘
                              |
                              v
                    ┌─────────────────┐
                    │ Request Context │
                    │  Processing     │
                    │ (What/Where?)   │
                    └─────────┬───────┘
                              |
                              v
            ┌─────────────────────────────────────┐
            │       Policy Evaluation Order       │
            └─────────────────┬───────────────────┘
                              |
        ┌─────────────────────┼─────────────────────┐
        |                     |                     |
        v                     v                     v
┌─────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Identity-   │    │ Resource-Based  │    │ Permission      │
│ Based       │    │ Policies        │    │ Boundaries      │
│ Policies    │    │                 │    │                 │
└──────┬──────┘    └─────────┬───────┘    └─────────┬───────┘
       |                     |                      |
       v                     v                      v
┌─────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Allow/    │    │    Allow/       │    │  Max Allowed    │
│   Deny      │    │    Deny         │    │  Permissions    │
└──────┬──────┘    └─────────┬───────┘    └─────────┬───────┘
       |                     |                      |
       └─────────────────────┼──────────────────────┘
                             |
                             v
                ┌─────────────────────────┐
                │    Organizations        │
                │  Service Control        │
                │  Policies (SCPs)        │
                └─────────┬───────────────┘
                          |
                          v
                ┌─────────────────────────┐
                │   Final Decision        │
                │                         │
                │  EXPLICIT DENY = DENY   │
                │  ANY ALLOW = ALLOW      │
                │  NO ALLOW = DENY        │
                └─────────────────────────┘
```

### Explanation
This diagram shows the critical IAM policy evaluation logic that every Solutions Architect must understand. The evaluation follows a specific order where explicit denies always override allows, and the effective permissions are the intersection of all applicable policies. Understanding this flow is essential for troubleshooting access issues and designing secure access controls.

### Key Decision Points
- **Policy Order Matters**: Identity-based and resource-based policies are evaluated together (union), then intersected with permission boundaries
- **Explicit Deny Wins**: Any explicit deny in any policy overrides all allow statements
- **Organizations SCPs**: Provide account-level guardrails that can restrict permissions across member accounts
- **Default Deny**: If no policy explicitly allows an action, it's denied by default

## Diagram 2: Cross-Account Access Architecture

```
                    Account A (Source)                         Account B (Target)
    ┌─────────────────────────────────────┐      ┌─────────────────────────────────────┐
    │                                     │      │                                     │
    │  ┌─────────────────────────────┐    │      │    ┌─────────────────────────────┐  │
    │  │       IAM User/Role         │    │      │    │      Cross-Account Role     │  │
    │  │                             │    │      │    │                             │  │
    │  │  User: developer@company    │    │      │    │  Role: CrossAccountAccess   │  │
    │  │  Policy: AssumeRole         │    │      │    │  Trust Policy: Account A    │  │
    │  └─────────────┬───────────────┘    │      │    │  Permission Policy: S3Read  │  │
    │                │                    │      │    └─────────────┬───────────────┘  │
    │                │                    │      │                  │                  │
    │                │ 1. AssumeRole      │      │                  │ 3. Access       │
    │                │ sts:AssumeRole     │      │                  │ Resources       │
    │                │ ExternalId         │      │                  │                  │
    │                └────────────────────┼──────┼──────────────────┘                  │
    │                                     │      │                  │                  │
    │                     │               │      │                  │                  │
    │                     │ 2. Temporary  │      │                  v                  │
    │                     │ Credentials   │      │    ┌─────────────────────────────┐  │
    │                     │ (AssumeRole   │      │    │         S3 Bucket           │  │
    │                     │  Response)    │      │    │                             │  │
    │                     v               │      │    │  Resource-Based Policy:     │  │
    │  ┌─────────────────────────────┐    │      │    │  - Allow Account A Role     │  │
    │  │    Application/Service      │    │      │    │  - Require MFA              │  │
    │  │                             │    │      │    │  - Source IP Restrictions   │  │
    │  │  Temporary Credentials:     │    │      │    └─────────────────────────────┘  │
    │  │  - AccessKeyId             │    │      │                                     │
    │  │  - SecretAccessKey         │    │      │                                     │
    │  │  - SessionToken            │    │      │                                     │
    │  │  - Expiration (1-12 hours) │    │      │                                     │
    │  └─────────────────────────────┘    │      │                                     │
    │                                     │      │                                     │
    └─────────────────────────────────────┘      └─────────────────────────────────────┘

    ┌─────────────────────────────────────────────────────────────────────────────────┐
    │                              Trust Policy Example                                │
    │                                                                                 │
    │  {                                                                              │
    │    "Version": "2012-10-17",                                                     │
    │    "Statement": [                                                               │
    │      {                                                                          │
    │        "Effect": "Allow",                                                       │
    │        "Principal": {                                                           │
    │          "AWS": "arn:aws:iam::ACCOUNT-A:root"                                   │
    │        },                                                                       │
    │        "Action": "sts:AssumeRole",                                              │
    │        "Condition": {                                                           │
    │          "StringEquals": {                                                      │
    │            "sts:ExternalId": "unique-external-id-12345"                         │
    │          },                                                                     │
    │          "Bool": {                                                              │
    │            "aws:MultiFactorAuthPresent": "true"                                 │
    │          }                                                                      │
    │        }                                                                        │
    │      }                                                                          │
    │    ]                                                                            │
    │  }                                                                              │
    └─────────────────────────────────────────────────────────────────────────────────┘
```

### Explanation
This diagram illustrates secure cross-account access patterns essential for enterprise multi-account strategies. The architecture shows how temporary credentials are issued through role assumption, providing secure access without sharing long-term credentials across account boundaries.

### Security Considerations
- **External ID**: Prevents confused deputy attacks by requiring a unique identifier
- **MFA Requirement**: Adds additional security layer for sensitive cross-account operations
- **Temporary Credentials**: Automatically expire, reducing exposure window
- **Least Privilege**: Cross-account role has minimal required permissions

## Diagram 3: Enterprise Identity Federation Architecture

```
    ┌─────────────────────────────────────────────────────────────────────────────┐
    │                        Corporate Identity Provider                           │
    │                          (Active Directory)                                 │
    └─────────────────────────────┬───────────────────────────────────────────────┘
                                  │
                                  │ SAML 2.0 / OIDC
                                  │ Authentication
                                  │
                                  v
    ┌─────────────────────────────────────────────────────────────────────────────┐
    │                    AWS IAM Identity Center                                   │
    │                                                                             │
    │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐  │
    │  │  Permission     │  │    Account      │  │      User Groups           │  │
    │  │     Sets        │  │  Assignments    │  │                            │  │
    │  │                 │  │                 │  │  - Developers              │  │
    │  │ - Developer     │  │ Account 1:      │  │  - DevOps Engineers        │  │
    │  │ - DevOps        │  │  Dev Team       │  │  - Security Team           │  │
    │  │ - SecurityAudit │  │ Account 2:      │  │  - Finance Team            │  │
    │  │ - ReadOnly      │  │  Staging        │  │                            │  │
    │  │                 │  │ Account 3:      │  │                            │  │
    │  └─────────────────┘  │  Production     │  └─────────────────────────────┘  │
    │                       └─────────────────┘                                   │
    └─────────────────────────────┬───────────────────────────────────────────────┘
                                  │
                                  │ Temporary Credentials
                                  │ (AssumeRoleWithSAML)
                                  │
                ┌─────────────────┼─────────────────┐
                │                 │                 │
                v                 v                 v
    ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
    │   Account 1     │ │   Account 2     │ │   Account 3     │
    │  Development    │ │    Staging      │ │   Production    │
    │                 │ │                 │ │                 │
    │ ┌─────────────┐ │ │ ┌─────────────┐ │ │ ┌─────────────┐ │
    │ │ IAM Roles   │ │ │ │ IAM Roles   │ │ │ │ IAM Roles   │ │
    │ │             │ │ │ │             │ │ │ │             │ │
    │ │ - DevAccess │ │ │ │ - StgAccess │ │ │ │ - ProdRead  │ │
    │ │ - TestAccess│ │ │ │ - TestAccess│ │ │ │ - ProdAdmin │ │
    │ └─────────────┘ │ │ └─────────────┘ │ │ └─────────────┘ │
    │                 │ │                 │ │                 │
    │ Resources:      │ │ Resources:      │ │ Resources:      │
    │ - EC2, RDS     │ │ - EC2, RDS      │ │ - EC2, RDS      │
    │ - S3, Lambda   │ │ - S3, Lambda    │ │ - S3, Lambda    │
    └─────────────────┘ └─────────────────┘ └─────────────────┘

    ┌─────────────────────────────────────────────────────────────────────────────┐
    │                         Access Flow Example                                  │
    │                                                                             │
    │  1. User authenticates to Corporate AD                                      │
    │  2. User accesses AWS access portal (Identity Center)                       │
    │  3. SAML assertion sent to AWS                                             │
    │  4. Identity Center maps user to permission sets                           │
    │  5. User assumes role in target account                                    │
    │  6. Temporary credentials issued (1-12 hours)                              │
    │  7. User accesses AWS resources with assumed role                          │
    └─────────────────────────────────────────────────────────────────────────────┘
```

### Explanation
This enterprise federation architecture demonstrates how large organizations can maintain centralized identity management while providing secure, scalable access to multiple AWS accounts. The design eliminates the need for individual IAM users while maintaining fine-grained access control.

### Architectural Benefits
- **Centralized Identity Management**: Single source of truth for user identities
- **Scalable Access Control**: Permission sets can be reused across accounts
- **Audit and Compliance**: Centralized logging and access tracking
- **Reduced Operational Overhead**: No need to manage individual IAM users

## Diagram 4: IAM Permission Boundaries Implementation

```
                        User with Permission Boundary
    ┌─────────────────────────────────────────────────────────────────────────────┐
    │                                                                             │
    │  ┌─────────────────────────────────────────────────────────────────┐        │
    │  │                Identity-Based Policy                            │        │
    │  │                                                                 │        │
    │  │  {                                                              │        │
    │  │    "Version": "2012-10-17",                                     │        │
    │  │    "Statement": [                                               │        │
    │  │      {                                                          │        │
    │  │        "Effect": "Allow",                                       │        │
    │  │        "Action": [                                              │        │
    │  │          "s3:*",                                                │        │
    │  │          "ec2:*",                                               │        │
    │  │          "lambda:*",                                            │        │
    │  │          "iam:CreateRole",                                      │        │
    │  │          "iam:AttachRolePolicy"                                 │        │
    │  │        ],                                                       │        │
    │  │        "Resource": "*"                                          │        │
    │  │      }                                                          │        │
    │  │    ]                                                            │        │
    │  │  }                                                              │        │
    │  └─────────────────────────────────────────────────────────────────┘        │
    │                                    │                                        │
    │                                    │ INTERSECTION                           │
    │                                    │ (AND Logic)                            │
    │                                    │                                        │
    │  ┌─────────────────────────────────────────────────────────────────┐        │
    │  │                Permission Boundary                              │        │
    │  │                                                                 │        │
    │  │  {                                                              │        │
    │  │    "Version": "2012-10-17",                                     │        │
    │  │    "Statement": [                                               │        │
    │  │      {                                                          │        │
    │  │        "Effect": "Allow",                                       │        │
    │  │        "Action": [                                              │        │
    │  │          "s3:GetObject",                                        │        │
    │  │          "s3:PutObject",                                        │        │
    │  │          "ec2:DescribeInstances",                               │        │
    │  │          "lambda:InvokeFunction"                                │        │
    │  │        ],                                                       │        │
    │  │        "Resource": "*"                                          │        │
    │  │      }                                                          │        │
    │  │    ]                                                            │        │
    │  │  }                                                              │        │
    │  └─────────────────────────────────────────────────────────────────┘        │
    │                                                                             │
    └─────────────────────────────────────────────────────────────────────────────┘
                                         │
                                         v
                    ┌─────────────────────────────────────┐
                    │        Effective Permissions        │
                    │                                     │
                    │  Allowed Actions:                   │
                    │  - s3:GetObject                     │
                    │  - s3:PutObject                     │
                    │  - ec2:DescribeInstances           │
                    │  - lambda:InvokeFunction           │
                    │                                     │
                    │  Denied Actions:                    │
                    │  - s3:DeleteObject                  │
                    │  - ec2:RunInstances                │
                    │  - iam:CreateRole                   │
                    │  - iam:AttachRolePolicy            │
                    │  - All other S3, EC2, Lambda      │
                    └─────────────────────────────────────┘

    ┌─────────────────────────────────────────────────────────────────────────────┐
    │                    Permission Boundary Use Cases                            │
    │                                                                             │
    │  1. Delegated Administration:                                               │
    │     - Allow developers to create roles but limit permissions               │
    │     - Prevent privilege escalation beyond boundary                         │
    │                                                                             │
    │  2. Compliance Requirements:                                                │
    │     - Ensure users cannot exceed organizational policies                   │
    │     - Maintain security guardrails regardless of policy changes           │
    │                                                                             │
    │  3. Multi-tenant Environments:                                             │
    │     - Isolate different teams or projects within same account             │
    │     - Prevent cross-team resource access                                  │
    └─────────────────────────────────────────────────────────────────────────────┘
```

### Explanation
Permission boundaries provide a powerful mechanism for delegating permission management while maintaining security controls. They define the maximum permissions that identity-based policies can grant, creating an additional security layer that prevents privilege escalation.

### Implementation Strategy
- **Start Broad, Narrow Down**: Begin with comprehensive permission boundaries and refine based on actual usage
- **Automate Boundary Assignment**: Use AWS Organizations SCPs to require permission boundaries for specific roles
- **Monitor Boundary Violations**: Use CloudTrail to identify attempts to exceed boundary permissions
- **Regular Review**: Periodically assess if boundaries are appropriately scoped

## Diagram 5: Cost Optimization for IAM at Scale

```
    ┌─────────────────────────────────────────────────────────────────────────────┐
    │                    Traditional IAM User Management                          │
    │                           (High Cost)                                      │
    │                                                                             │
    │  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐          │
    │  │ IAM User 1  │ │ IAM User 2  │ │ IAM User 3  │ │    ...      │          │
    │  │             │ │             │ │             │ │             │          │
    │  │ - Policies  │ │ - Policies  │ │ - Policies  │ │ - Policies  │          │
    │  │ - Groups    │ │ - Groups    │ │ - Groups    │ │ - Groups    │          │
    │  │ - Access    │ │ - Access    │ │ - Access    │ │ - Access    │          │
    │  │   Keys      │ │   Keys      │ │   Keys      │ │   Keys      │          │
    │  │ - MFA       │ │ - MFA       │ │ - MFA       │ │ - MFA       │          │
    │  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘          │
    │                                                                             │
    │  Operational Costs:                                                        │
    │  - User provisioning/deprovisioning                                        │
    │  - Access key rotation                                                     │
    │  - Password management                                                     │
    │  - MFA device management                                                   │
    │  - Individual user auditing                                               │
    │  - Policy management per user                                             │
    └─────────────────────────────────────────────────────────────────────────────┘
                                         │
                                         │ OPTIMIZATION
                                         │
                                         v
    ┌─────────────────────────────────────────────────────────────────────────────┐
    │                    Optimized Identity Federation                            │
    │                           (Low Cost)                                       │
    │                                                                             │
    │  ┌─────────────────────────────────────────────────────────────────┐        │
    │  │                 External Identity Provider                      │        │
    │  │                      (Existing System)                         │        │
    │  └─────────────────────────┬───────────────────────────────────────┘        │
    │                            │                                                │
    │                            │ Federation                                     │
    │                            │                                                │
    │  ┌─────────────────────────v───────────────────────────────────────┐        │
    │  │              AWS IAM Identity Center                            │        │
    │  │                                                                 │        │
    │  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │        │
    │  │  │ Permission  │  │  Account    │  │    Automated            │  │        │
    │  │  │    Sets     │  │ Assignment  │  │   Provisioning          │  │        │
    │  │  │             │  │             │  │                         │  │        │
    │  │  │ 5-10 sets   │  │ Group-based │  │ - SCIM Protocol         │  │        │
    │  │  │ cover most  │  │ assignments │  │ - Just-in-time          │  │        │
    │  │  │ use cases   │  │             │  │ - Lifecycle management  │  │        │
    │  │  └─────────────┘  └─────────────┘  └─────────────────────────┘  │        │
    │  └─────────────────────────────────────────────────────────────────┘        │
    │                                                                             │
    │  Cost Savings:                                                              │
    │  - Eliminate individual IAM user management                                 │
    │  - Reduce policy proliferation                                             │
    │  - Automated provisioning/deprovisioning                                   │
    │  - Centralized audit and compliance                                        │
    │  - Reduced support overhead                                                │
    │  - Leverage existing identity infrastructure                               │
    │                                                                             │
    │  ROI Calculation:                                                           │
    │  - Users: 500                                                              │
    │  - Management time saved: 20 hours/month                                   │
    │  - Average hourly rate: $100                                               │
    │  - Monthly savings: $2,000                                                 │
    │  - Annual savings: $24,000                                                 │
    └─────────────────────────────────────────────────────────────────────────────┘
```

### Explanation
This diagram illustrates the cost optimization strategy for IAM at enterprise scale. By moving from individual IAM users to federated access through Identity Center, organizations can significantly reduce operational overhead while improving security posture.

### Key Cost Factors
- **Operational Overhead**: Time spent managing individual users, passwords, and access keys
- **Compliance Costs**: Auditing and reporting for numerous individual accounts
- **Security Incidents**: Costs associated with compromised credentials or over-privileged access
- **Infrastructure Duplication**: Maintaining separate identity systems vs. leveraging existing investments

This comprehensive set of diagrams provides Solutions Architects with visual understanding of the most complex IAM concepts, from policy evaluation logic to enterprise-scale cost optimization strategies.
