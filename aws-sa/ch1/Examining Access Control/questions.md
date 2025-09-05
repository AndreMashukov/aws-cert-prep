# AWS Access Control: Examining Access Control, Leveraging Access Delegation, Considering User Federation

## Questions

**Q1: Your organization has multiple development teams working on different projects across various AWS accounts. You need to implement an access control strategy that allows developers to access only the resources tagged with their team name, without creating separate policies for each team. Which approach should you implement?**

1. Role-Based Access Control (RBAC) with separate IAM roles for each team
2. Attribute-Based Access Control (ABAC) using session tags and condition statements in IAM policies
3. Resource-based policies attached to each AWS resource with team-specific permissions
4. Cross-account IAM roles with trust policies for each development team

**Q2: A Solutions Architect needs to design access delegation for a scenario where an application in Account A requires temporary access to read objects from an S3 bucket in Account B. The access should be limited to a specific time window and should not require long-term credentials. What is the most secure and efficient approach?**

1. Create an IAM user in Account B with programmatic access and share the credentials with Account A
2. Use S3 bucket policies to allow cross-account access from Account A
3. Create an IAM role in Account B with a trust policy allowing Account A to assume it, then use STS AssumeRole
4. Enable S3 Cross-Region Replication to copy objects to Account A

**Q3: Your enterprise organization uses Microsoft Active Directory for user authentication and wants to provide federated access to AWS resources across multiple accounts. Users should retain their existing corporate identities and access should be based on their AD group memberships. Which federation approach provides the best scalability and management efficiency?**

1. AWS IAM with SAML 2.0 identity provider for each individual AWS account
2. AWS IAM Identity Center (AWS SSO) with Microsoft AD as the identity source
3. Amazon Cognito User Pools with Active Directory integration
4. Direct integration using AWS Directory Service AD Connector

**Q4: When implementing Attribute-Based Access Control (ABAC) with IAM Identity Center, a developer should only access EC2 instances tagged with their department and project. The developer's attributes include Department=Engineering and Project=WebApp. Which IAM policy condition correctly implements this requirement?**

1. `"StringEquals": {"ec2:ResourceTag/Department": "${aws:PrincipalTag/Department}", "ec2:ResourceTag/Project": "${aws:PrincipalTag/Project}"}`
2. `"StringLike": {"ec2:ResourceTag/*": "${aws:userid}"}`
3. `"StringEquals": {"aws:RequestedRegion": "${aws:PrincipalTag/Department}"}`
4. `"ForAllValues:StringEquals": {"ec2:ResourceTag/Department": "Engineering"}`

**Q5: A financial services company needs to implement cross-account access for their audit team to review CloudTrail logs stored in a central security account. The audit team should have read-only access and the solution should follow AWS security best practices. What is the recommended approach?**

1. Create IAM users in the security account for each auditor with programmatic access
2. Create a cross-account IAM role in the security account with read permissions, establish trust with the audit account, and use AssumeRole
3. Share the security account root credentials with the audit team for temporary access
4. Use AWS Resource Access Manager (RAM) to share CloudTrail resources with the audit account

**Q6: Your organization uses SAML 2.0 federation with AWS IAM for single sign-on. The identity provider passes user attributes including cost center, department, and job function. You want to ensure that users can only access AWS resources tagged with their cost center. Which component is essential for implementing this ABAC pattern?**

1. AWS Cognito Identity Pools for attribute mapping
2. Session tags that pass user attributes from the SAML assertion to AWS
3. AWS Directory Service for attribute synchronization
4. AWS Resource Access Manager for cross-account attribute sharing

**Q7: A startup company is rapidly growing and frequently reorganizing teams. They want an access control system that automatically grants permissions when new resources are created with appropriate tags, without requiring manual policy updates for each team change. Which approach best addresses this requirement?**

1. Traditional RBAC with job function-based managed policies
2. ABAC with dynamic permission evaluation based on resource and principal tags
3. Resource-based policies with explicit principal ARN lists
4. Cross-account roles with separate AWS accounts for each team

**Q8: When configuring cross-account access using IAM roles, a trust policy in the target account allows an external account to assume the role. However, what additional configuration is required in the external account for users to successfully assume the role?**

1. The external account must have an organization-level Service Control Policy (SCP) allowing sts:AssumeRole
2. Users in the external account must have explicit permissions to assume the role via sts:AssumeRole action
3. The external account must configure a SAML identity provider pointing to the target account
4. AWS Resource Access Manager (RAM) must be enabled between the accounts

**Q9: Your organization wants to implement zero-trust principles for AWS access. Users should authenticate through your corporate identity provider and receive temporary credentials with minimal privileges based on their current role and the specific resources they need to access. Which combination of services best supports this architecture?**

1. AWS IAM users with MFA and restrictive policies
2. AWS IAM Identity Center with SAML federation, ABAC, and session-based permissions
3. Amazon Cognito with OAuth 2.0 and IAM roles
4. AWS Directory Service Simple AD with IAM group-based permissions

**Q10: A multinational corporation has development teams in different regions who need access to region-specific resources. Each team should only access resources in their assigned region and tagged with their team identifier. The company wants to minimize administrative overhead while maintaining security. What is the most efficient approach using AWS best practices?**

1. Create separate AWS accounts for each region and team combination
2. Use IAM Identity Center with ABAC, implementing conditions based on aws:RequestedRegion and resource tags matching team attributes
3. Implement RBAC with separate IAM roles for each team-region combination
4. Use S3 bucket policies and EC2 security groups to control regional access
