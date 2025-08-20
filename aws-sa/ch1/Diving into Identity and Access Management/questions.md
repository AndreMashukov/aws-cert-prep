# AWS Identity and Access Management (IAM) - Questions

## Questions

**Q1: A Solutions Architect needs to implement a cross-account access strategy for a large enterprise with 50+ AWS accounts. The security team requires centralized access management and wants to ensure that developers can only access resources in their designated development accounts. What is the MOST secure and scalable approach?**
1. Create IAM users in each account and share credentials through a secure password manager
2. Implement AWS IAM Identity Center (successor to AWS SSO) with permission sets and account assignments
3. Use AWS Organizations with Service Control Policies (SCPs) only
4. Create cross-account IAM roles and distribute role ARNs to developers

**Q2: An organization has implemented IAM permission boundaries for developer roles. A developer has an identity-based policy allowing "s3:*" actions and a permission boundary allowing "s3:GetObject" and "s3:PutObject". What actions can the developer perform on S3?**
1. All S3 actions as specified in the identity-based policy
2. Only s3:GetObject and s3:PutObject actions
3. No S3 actions due to policy conflict
4. s3:GetObject, s3:PutObject, and s3:ListBucket actions

**Q3: A company needs to grant temporary access to external auditors for reviewing security configurations across multiple AWS accounts. The auditors should have read-only access for 30 days and access should be automatically revoked. What is the MOST appropriate solution?**
1. Create IAM users with ReadOnlyAccess managed policy and set password expiration to 30 days
2. Use AWS STS AssumeRoleWithWebIdentity with external identity provider and session duration limits
3. Create IAM roles with ReadOnlyAccess policy and manually delete after 30 days
4. Use AWS IAM Access Analyzer to generate temporary access tokens

**Q4: In a multi-tier application architecture, an EC2 instance in the web tier needs to access DynamoDB tables and S3 buckets, while an EC2 instance in the application tier needs access to RDS and SQS. What is the BEST practice for implementing least privilege access?**
1. Create one IAM role with all required permissions and attach to both instances
2. Create separate IAM roles for each tier with specific permissions and use instance profiles
3. Use IAM users with access keys stored in AWS Systems Manager Parameter Store
4. Implement resource-based policies on DynamoDB, S3, RDS, and SQS

**Q5: A financial services company requires that all API calls to sensitive resources be made with MFA. They have implemented a condition in their IAM policies requiring MFA, but developers are reporting issues accessing resources programmatically. What is the MOST likely cause and solution?**
1. MFA cannot be used with programmatic access; remove the MFA condition
2. Developers need to use GetSessionToken API with MFA before making resource API calls
3. The MFA condition should only apply to console access, not programmatic access
4. IAM roles automatically satisfy MFA requirements for EC2 instances

**Q6: An organization wants to implement a cost optimization strategy for IAM. They have 200 IAM users, 50 IAM roles, and 300 IAM policies. What approach would provide the MOST cost benefit?**
1. Consolidate IAM policies to reduce policy storage costs
2. Replace IAM users with federated access using AWS IAM Identity Center
3. Use IAM groups instead of individual user policies
4. Implement permission boundaries to reduce policy complexity

**Q7: A company has implemented AWS Organizations with multiple accounts. They want to prevent member accounts from leaving the organization and restrict the creation of IAM users. Which AWS Organizations feature should they use?**
1. AWS Config rules for compliance monitoring
2. Service Control Policies (SCPs) with explicit deny statements
3. AWS CloudTrail for audit logging
4. IAM permission boundaries at the organization level

**Q8: A developer needs to debug why their application is receiving "Access Denied" errors when trying to access an S3 bucket. The bucket has a resource-based policy, the user has an identity-based policy allowing S3 access, and the account is part of AWS Organizations with SCPs. What tool would be MOST helpful for troubleshooting?**
1. AWS CloudTrail event history
2. IAM Policy Simulator
3. AWS Config compliance reports
4. Amazon CloudWatch Logs

**Q9: A startup is growing rapidly and needs to scale their access management. They currently have 20 developers with individual IAM users but expect to grow to 200+ employees across multiple teams. What is the MOST scalable long-term solution?**
1. Create IAM groups for each team and add users to appropriate groups
2. Implement AWS IAM Identity Center with external identity provider integration
3. Use AWS Cognito for user management
4. Create department-specific AWS accounts with cross-account roles

**Q10: An organization has implemented a policy that requires all IAM users to have MFA enabled. However, some automated scripts and CI/CD pipelines are failing. What is the BEST approach to maintain security while ensuring automation works?**
1. Disable MFA requirement for automated processes
2. Use IAM roles for automated processes and require MFA only for human users
3. Create service accounts without MFA for automation
4. Use AWS Systems Manager Session Manager for all automation

**Q11: A company wants to implement just-in-time (JIT) access for privileged operations. Administrators should only have elevated permissions when needed and for a limited time. What AWS services combination would BEST achieve this?**
1. AWS IAM with time-based conditions in policies
2. AWS Systems Manager Session Manager with temporary elevated permissions
3. Custom application using AWS STS AssumeRole with short-duration tokens
4. AWS IAM Access Analyzer with automated policy updates

**Q12: An organization has multiple AWS accounts and wants to centrally manage cross-account access. They need developers in Account A to access resources in Account B, but only specific resources. What is the MOST secure approach?**
1. Create IAM users in Account B and share credentials with Account A developers
2. Use AWS Organizations trusted access with resource-based policies
3. Implement cross-account IAM roles with least privilege permissions and external ID
4. Set up VPC peering and use security groups for access control

**Q13: A company is migrating from on-premises Active Directory to AWS. They want to maintain their existing user identities and group structures while providing AWS access. What is the BEST approach?**
1. Create IAM users matching each Active Directory user
2. Use AWS Directory Service AD Connector with IAM role mapping
3. Implement SAML 2.0 federation with Active Directory Federation Services (ADFS)
4. Use AWS IAM Identity Center with Active Directory integration

**Q14: An application needs to access AWS services from an on-premises server. The security team prohibits storing long-term credentials on the server. What is the MOST secure solution?**
1. Use IAM user with access keys rotated daily
2. Implement AWS IAM Roles Anywhere with X.509 certificates
3. Use temporary credentials from AWS STS with AssumeRole
4. Store credentials in AWS Systems Manager Parameter Store

**Q15: A company has implemented resource-based policies on their S3 buckets and identity-based policies on IAM users. A user is denied access to an S3 bucket despite having Allow permissions in both policies. What could be the cause?**
1. Resource-based policies override identity-based policies
2. An explicit Deny in either policy overrides Allow permissions
3. S3 bucket policies require additional authentication
4. Cross-account access requires external ID validation

**Q16: An organization wants to implement automated compliance checking for IAM policies. They need to ensure policies follow security best practices and flag potential over-privileged access. What AWS service would be MOST appropriate?**
1. AWS Config with custom compliance rules
2. AWS IAM Access Analyzer policy validation
3. AWS Security Hub with compliance standards
4. Amazon GuardDuty for threat detection

**Q17: A financial institution needs to implement separation of duties for sensitive operations. No single person should be able to both create and approve financial transactions. How can this be implemented using IAM?**
1. Use IAM groups with different permissions for each role
2. Implement approval workflows using AWS Step Functions
3. Use IAM permission boundaries to limit individual user capabilities
4. Create separate IAM policies requiring multiple principals for sensitive actions

**Q18: A company has 100+ IAM roles and wants to identify which roles are unused to reduce security surface area. What is the MOST efficient approach?**
1. Manually review CloudTrail logs for role usage
2. Use IAM Access Analyzer unused access findings
3. Implement custom Lambda function to analyze role last used data
4. Use AWS Config rules to track role activity

**Q19: An application running on EC2 needs different permissions during business hours vs. off-hours for cost optimization. During off-hours, it should only have read permissions. What is the BEST implementation?**
1. Use multiple IAM roles and switch roles based on time
2. Implement time-based conditions in IAM policies using DateGreaterThan/DateLessThan
3. Use AWS Lambda to modify permissions based on schedule
4. Create separate environments for business hours and off-hours

**Q20: A company is implementing a multi-region disaster recovery strategy. They need to ensure IAM configurations are consistent across regions and can quickly replicate access controls. What approach should they take?**
1. Manually configure IAM in each region
2. Use AWS CloudFormation to deploy IAM resources across regions
3. IAM is global; no region-specific configuration needed
4. Use AWS Organizations to replicate IAM configurations

**Q21: An organization has implemented AWS IAM Identity Center but some legacy applications cannot use SAML or OIDC federation. These applications need programmatic access to AWS services. What is the BEST solution?**
1. Create dedicated IAM users for legacy applications
2. Use AWS IAM Identity Center application assignments with custom identity sources
3. Implement API gateway with custom authentication
4. Use AWS Cognito identity pools for legacy application authentication

**Q22: A company wants to implement attribute-based access control (ABAC) to grant permissions based on user attributes like department, project, and clearance level. What IAM feature enables this?**
1. IAM user groups with attribute-based naming
2. IAM policy conditions using principal tags and resource tags
3. AWS IAM Access Analyzer attribute analysis
4. IAM permission boundaries with attribute filters

**Q23: A startup needs to minimize AWS costs while maintaining security. They have 10 developers who need different levels of AWS access. What is the MOST cost-effective approach?**
1. Use AWS IAM Identity Center free tier with built-in identity store
2. Create IAM users and groups with AWS managed policies
3. Implement external identity provider with high-availability setup
4. Use AWS Cognito for user management and authentication

**Q24: An enterprise wants to implement a zero-trust security model for AWS access. Users should be authenticated and authorized for each resource access based on current context. What combination of AWS services would BEST support this?**
1. AWS IAM with MFA and VPC security groups
2. AWS IAM Identity Center with adaptive authentication and context-aware policies
3. AWS Cognito with device tracking and geolocation
4. AWS GuardDuty with automated remediation actions

**Q25: A company has discovered that an IAM role has broader permissions than needed. The role is used by multiple applications and they're concerned about breaking functionality. What is the SAFEST approach to reduce permissions?**
1. Immediately remove all unnecessary permissions
2. Use IAM Access Analyzer policy generation based on actual usage
3. Create a new role with minimal permissions and gradually migrate applications
4. Implement permission boundaries to limit the role's effective permissions
