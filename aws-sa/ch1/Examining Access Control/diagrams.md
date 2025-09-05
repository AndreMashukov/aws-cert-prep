# AWS Access Control: Architecture Diagrams

## Overview
This document provides ASCII diagrams focused on the most challenging aspects of AWS access control for Solutions Architects, covering RBAC vs ABAC, cross-account access delegation, and user federation patterns.

## Diagram 1: RBAC vs ABAC Comparison

### Traditional RBAC Approach
```
┌─────────────────────────────────────────────────────────────────┐
│                        RBAC Approach                            │
├─────────────────────────────────────────────────────────────────┤
│  User Groups           IAM Policies           AWS Resources      │
│                                                                 │
│ ┌─────────────┐      ┌─────────────────┐    ┌─────────────────┐ │
│ │ Developers  │────▶ │ DeveloperPolicy │───▶│ S3: dev-bucket  │ │
│ │   - Alice   │      │ Allow: s3:*     │    │ EC2: dev-*      │ │
│ │   - Bob     │      │ Resource:       │    │ RDS: dev-db     │ │
│ └─────────────┘      │ arn:aws:s3:::   │    └─────────────────┘ │
│                      │   dev-*         │                        │
│ ┌─────────────┐      └─────────────────┘    ┌─────────────────┐ │
│ │ QA Team     │      ┌─────────────────┐    │ S3: qa-bucket   │ │
│ │   - Carol   │────▶ │ QAPolicy        │───▶│ EC2: qa-*       │ │
│ │   - Dave    │      │ Allow: s3:Get*  │    │ RDS: qa-db      │ │
│ └─────────────┘      │ Resource:       │    └─────────────────┘ │
│                      │ arn:aws:s3:::   │                        │
│                      │   qa-*          │                        │
│                      └─────────────────┘                        │
│                                                                 │
│ Problem: Need separate policy for each team × environment       │
│ Result: Policy explosion as organization grows                  │
└─────────────────────────────────────────────────────────────────┘
```

### ABAC Approach
```
┌─────────────────────────────────────────────────────────────────┐
│                        ABAC Approach                            │
├─────────────────────────────────────────────────────────────────┤
│   Users + Attributes    Single Dynamic Policy    Tagged Resources│
│                                                                 │
│ ┌─────────────────┐    ┌───────────────────────┐ ┌─────────────┐ │
│ │ Alice           │    │ Universal Policy      │ │ S3 Bucket   │ │
│ │ Team: Dev       │───▶│ Allow: s3:*          │▶│ Team: Dev   │ │
│ │ Env: Staging    │    │ Condition:           │ │ Env: Staging│ │
│ └─────────────────┘    │ StringEquals:        │ └─────────────┘ │
│                        │ "s3:ResourceTag/     │                 │
│ ┌─────────────────┐    │  Team":             │ ┌─────────────┐ │
│ │ Bob             │    │ "${aws:PrincipalTag/ │ │ EC2 Instance│ │
│ │ Team: Dev       │───▶│  Team}"             │▶│ Team: Dev   │ │
│ │ Env: Prod       │    │ "s3:ResourceTag/     │ │ Env: Prod   │ │
│ └─────────────────┘    │  Env":              │ └─────────────┘ │
│                        │ "${aws:PrincipalTag/ │                 │
│ ┌─────────────────┐    │  Env}"              │ ┌─────────────┐ │
│ │ Carol           │    │                     │ │ RDS Database│ │
│ │ Team: QA        │───▶│ (Same policy for    │▶│ Team: QA    │ │
│ │ Env: Test       │    │  all users!)        │ │ Env: Test   │ │
│ └─────────────────┘    └───────────────────────┘ └─────────────┘ │
│                                                                 │
│ Benefit: One policy scales with any number of teams/envs       │
│ Result: Dynamic access based on user and resource attributes   │
└─────────────────────────────────────────────────────────────────┘
```

### Key Decision Points
- **RBAC**: Best for stable organizations with well-defined roles
- **ABAC**: Ideal for dynamic organizations with frequent reorganizations  
- **Cost**: ABAC reduces policy management overhead at scale
- **Complexity**: RBAC simpler initially, ABAC pays off over time

## Diagram 2: Cross-Account Access Delegation Flow

```
┌────────────────────────────────────────────────────────────────────────┐
│                   Cross-Account Access Delegation                      │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  Account A (Source)                    Account B (Target)              │
│  ┌─────────────────────┐               ┌─────────────────────┐          │
│  │                     │               │                     │          │
│  │ ┌─────────────────┐ │               │ ┌─────────────────┐ │          │
│  │ │   IAM User      │ │      1        │ │   IAM Role      │ │          │
│  │ │    UserA        │ │ ──────────────▶│ │   CrossRole     │ │          │
│  │ │                 │ │ STS:AssumeRole │ │                 │ │          │
│  │ │ Permissions:    │ │               │ │ Trust Policy:   │ │          │
│  │ │ - sts:AssumeRole│ │               │ │ {               │ │          │
│  │ │   Resource:     │ │               │ │   "Principal": {│ │          │
│  │ │   arn:aws:iam:: │ │               │ │     "AWS": "arn:│ │          │
│  │ │   AccountB:role/│ │               │ │     aws:iam::   │ │          │
│  │ │   CrossRole     │ │               │ │     AccountA:   │ │          │
│  │ └─────────────────┘ │               │ │     user/UserA" │ │          │
│  │                     │               │ │   }             │ │          │
│  └─────────────────────┘               │ │ }               │ │          │
│                                        │ └─────────────────┘ │          │
│                                        │         │           │          │
│                                        │         │ 2         │          │
│                                        │         ▼           │          │
│  ┌─────────────────────┐               │ ┌─────────────────┐ │          │
│  │ Temporary Creds     │      3        │ │   S3 Bucket     │ │          │
│  │ - AccessKeyId       │◀──────────────  │   target-bucket │ │          │
│  │ - SecretAccessKey   │  STS Response   │                 │ │          │
│  │ - SessionToken      │               │ │ IAM Policy on   │ │          │
│  │ - Expiration        │               │ │ CrossRole:      │ │          │
│  │   (1-12 hours)      │               │ │ - s3:GetObject  │ │          │
│  └─────────────────────┘               │ │ - s3:PutObject  │ │          │
│                                        │ └─────────────────┘ │          │
│                                        │                     │          │
│                                        └─────────────────────┘          │
└────────────────────────────────────────────────────────────────────────┘

Flow Steps:
1. UserA calls STS:AssumeRole with CrossRole ARN
2. STS validates trust policy and UserA permissions
3. STS returns temporary credentials with limited lifetime
4. UserA uses temporary credentials to access S3 bucket
```

### Architecture Considerations
- **Security**: No long-term credentials shared between accounts
- **Auditability**: All cross-account access logged in CloudTrail
- **Principle of Least Privilege**: Role has minimal required permissions
- **Scalability**: Pattern works for any number of trusting relationships

## Diagram 3: User Federation with SAML and Session Tags

```
┌────────────────────────────────────────────────────────────────────────┐
│                    SAML Federation with ABAC                           │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│ Corporate IdP          AWS IAM Identity Center/SAML        AWS Resources│
│                                                                        │
│ ┌─────────────┐  1    ┌─────────────────────┐    4   ┌─────────────┐   │
│ │   User      │──────▶│    SAML IdP         │───────▶│   AWS STS   │   │
│ │             │ Login │    (ADFS/Okta)      │ SAML   │             │   │
│ │ Attributes: │       │                     │Response│ Session     │   │
│ │ - Dept: Eng │       │ SAML Assertion:     │        │ Tags:       │   │
│ │ - Team: Web │       │ <Attribute Name=    │        │ - Dept: Eng │   │
│ │ - Role: Dev │       │  "Department"       │        │ - Team: Web │   │
│ │ - Cost: 1001│       │  Value="Eng"/>      │        │ - Role: Dev │   │
│ └─────────────┘       │ <Attribute Name=    │        │ - Cost: 1001│   │
│                       │  "Team"             │        └─────────────┘   │
│        │              │  Value="Web"/>      │              │           │
│        │2             │ <Attribute Name=    │              │5          │
│        ▼              │  "Role"             │              ▼           │
│ ┌─────────────┐       │  Value="Dev"/>      │    ┌─────────────────┐   │
│ │   Browser   │       │ <Attribute Name=    │    │ Temporary AWS   │   │
│ │             │  3    │  "CostCenter"       │    │ Credentials     │   │
│ │ Redirected  │──────▶│  Value="1001"/>     │    │ with Session    │   │
│ │ to AWS      │       │                     │    │ Tags            │   │
│ │ Console     │       └─────────────────────┘    └─────────────────┘   │
│ └─────────────┘                                            │           │
│                                                            │6          │
│                                                            ▼           │
│                      ┌─────────────────────────────────────────────┐   │
│                      │            IAM Policy Engine                │   │
│                      │                                             │   │
│                      │ Policy Condition:                          │   │
│                      │ "StringEquals": {                          │   │
│                      │   "ec2:ResourceTag/Department":            │   │
│                      │     "${aws:PrincipalTag/Department}",      │   │
│                      │   "ec2:ResourceTag/CostCenter":            │   │
│                      │     "${aws:PrincipalTag/CostCenter}"       │   │
│                      │ }                                          │   │
│                      └─────────────────────────────────────────────┘   │
│                                                │                       │
│                                                │7 Access Decision      │
│                                                ▼                       │
│                      ┌─────────────────────────────────────────────┐   │
│                      │              AWS Resources                  │   │
│                      │                                             │   │
│                      │ ┌─────────────┐  ┌─────────────┐  ┌─────────│   │
│                      │ │EC2 Instance │  │S3 Bucket    │  │RDS DB   │   │
│                      │ │Dept: Eng    │  │Dept: Finance│  │Dept: Eng│   │
│                      │ │Cost: 1001   │  │Cost: 2002   │  │Cost: 1001│  │
│                      │ │✅ ALLOW     │  │❌ DENY      │  │✅ ALLOW │   │
│                      │ └─────────────┘  └─────────────┘  └─────────│   │
│                      └─────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────┘

Process Flow:
1. User authenticates with corporate IdP
2. IdP redirects to AWS SAML endpoint
3. Browser posts SAML response to AWS
4. AWS STS validates SAML assertion
5. STS creates session with user attributes as tags
6. IAM evaluates policies with session tag substitution
7. Access granted/denied based on resource tag matching
```

### Key Decision Points
- **Centralized Identity**: Single source of truth for user attributes
- **Dynamic Access**: Permissions change automatically with user attributes
- **Scalability**: No need to provision users in AWS accounts
- **Compliance**: Centralized deprovisioning when user leaves organization

## Diagram 4: IAM Identity Center Multi-Account ABAC

```
┌────────────────────────────────────────────────────────────────────────┐
│              IAM Identity Center Multi-Account ABAC                    │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│ ┌─────────────────────────────────────────────────────────────────────┐ │
│ │                    AWS Organizations                                │ │
│ │                                                                     │ │
│ │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐ │ │
│ │  │   Dev Account   │    │  Staging Account │    │  Prod Account   │ │ │
│ │  │   111111111111  │    │   222222222222   │    │  333333333333   │ │ │
│ │  │                 │    │                  │    │                 │ │ │
│ │  │ Resources:      │    │ Resources:       │    │ Resources:      │ │ │
│ │  │ • EC2: Env=Dev  │    │ • EC2: Env=Stage │    │ • EC2: Env=Prod │ │ │
│ │  │ • S3: Env=Dev   │    │ • S3: Env=Stage  │    │ • S3: Env=Prod  │ │ │
│ │  │ • RDS: Env=Dev  │    │ • RDS: Env=Stage │    │ • RDS: Env=Prod │ │ │
│ │  └─────────────────┘    └─────────────────┘    └─────────────────┘ │ │
│ └─────────────────────────────────────────────────────────────────────┘ │
│                                      ▲                                  │
│                                      │ Federated Access                 │
│                                      │                                  │
│ ┌─────────────────────────────────────────────────────────────────────┐ │
│ │                    IAM Identity Center                              │ │
│ │                                                                     │ │
│ │  ┌─────────────────────────────────────────────────────────────────┐│ │
│ │  │               Permission Set: DeveloperAccess                   ││ │
│ │  │                                                                 ││ │
│ │  │ Inline Policy:                                                  ││ │
│ │  │ {                                                               ││ │
│ │  │   "Version": "2012-10-17",                                     ││ │
│ │  │   "Statement": [                                               ││ │
│ │  │     {                                                          ││ │
│ │  │       "Effect": "Allow",                                       ││ │
│ │  │       "Action": ["ec2:*", "s3:*", "rds:*"],                   ││ │
│ │  │       "Resource": "*",                                         ││ │
│ │  │       "Condition": {                                           ││ │
│ │  │         "StringEquals": {                                      ││ │
│ │  │           "${aws:PrincipalTag/Environment}":                   ││ │
│ │  │             "${aws:ResourceTag/Environment}",                  ││ │
│ │  │           "${aws:PrincipalTag/Team}":                          ││ │
│ │  │             "${aws:ResourceTag/Team}"                          ││ │
│ │  │         }                                                      ││ │
│ │  │       }                                                        ││ │
│ │  │     }                                                          ││ │
│ │  │   ]                                                            ││ │
│ │  │ }                                                              ││ │
│ │  └─────────────────────────────────────────────────────────────────┘│ │
│ └─────────────────────────────────────────────────────────────────────┘ │
│                                      ▲                                  │
│                                      │ SCIM Sync                        │
│                                      │                                  │
│ ┌─────────────────────────────────────────────────────────────────────┐ │
│ │                     External Identity Provider                      │ │
│ │                          (Active Directory)                        │ │
│ │                                                                     │ │
│ │  Users:                                                             │ │
│ │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐     │ │
│ │  │ Alice Smith     │  │ Bob Johnson     │  │ Carol Davis     │     │ │
│ │  │ Dept: Eng       │  │ Dept: Eng       │  │ Dept: Ops       │     │ │
│ │  │ Team: WebApp    │  │ Team: Mobile    │  │ Team: Platform  │     │ │
│ │  │ Env: Dev        │  │ Env: Dev        │  │ Env: Prod       │     │ │
│ │  │ Role: Developer │  │ Role: Developer │  │ Role: SysAdmin  │     │ │
│ │  └─────────────────┘  └─────────────────┘  └─────────────────┘     │ │
│ └─────────────────────────────────────────────────────────────────────┘ │
│                                                                        │
│ Access Examples:                                                       │ │
│ • Alice can access Dev account resources tagged Team=WebApp           │ │
│ • Bob can access Dev account resources tagged Team=Mobile             │ │
│ • Carol can access Prod account resources tagged Team=Platform        │ │
│ • Cross-team access automatically denied by attribute mismatch        │ │
└────────────────────────────────────────────────────────────────────────┘
```

### Architecture Benefits
- **Centralized Management**: Single permission set scales across all accounts
- **Automatic Compliance**: Users automatically lose access when attributes change
- **Reduced Complexity**: No need for separate roles per team/environment combination
- **Audit Trail**: Centralized logging of all access decisions and attribute changes

## Cost and Performance Trade-offs

### RBAC vs ABAC Cost Analysis
```
┌──────────────────┬─────────────────┬─────────────────┐
│   Metric         │      RBAC       │      ABAC       │
├──────────────────┼─────────────────┼─────────────────┤
│ Setup Complexity │     LOW         │     MEDIUM      │
│ Ongoing Mgmt     │     HIGH        │     LOW         │
│ Policy Count     │ Teams × Envs    │     O(1)        │
│ Change Velocity  │     SLOW        │     FAST        │
│ Audit Complexity │     HIGH        │     LOW         │
│ Learning Curve   │     LOW         │     MEDIUM      │
└──────────────────┴─────────────────┴─────────────────┘

Break-even Point: ~5 teams × 3 environments = 15+ policies
```

This architectural guidance helps Solutions Architects choose the optimal access control strategy based on organizational scale, change velocity, and complexity requirements.
