# AWS Access Control: Examining Access Control, Leveraging Access Delegation, Considering User Federation - Answers

**Q1: Your organization has multiple development teams working on different projects across various AWS accounts. You need to implement an access control strategy that allows developers to access only the resources tagged with their team name, without creating separate policies for each team. Which approach should you implement?**

**Answer: 2**
**Explanation:** Attribute-Based Access Control (ABAC) using session tags and condition statements in IAM policies is the correct approach. ABAC allows you to create fewer, more dynamic policies that use attributes (like team name) to control access. With ABAC, you can create a single policy that grants access to resources where the resource tag matches the user's session tag, eliminating the need for separate policies per team. This approach scales well as teams change and grow, reducing administrative overhead compared to traditional RBAC approaches.

**Q2: A Solutions Architect needs to design access delegation for a scenario where an application in Account A requires temporary access to read objects from an S3 bucket in Account B. The access should be limited to a specific time window and should not require long-term credentials. What is the most secure and efficient approach?**

**Answer: 3**
**Explanation:** Creating an IAM role in Account B with a trust policy allowing Account A to assume it, then using STS AssumeRole is the most secure approach. This method provides temporary credentials with configurable session duration, follows AWS security best practices by avoiding long-term credentials, and allows precise control over permissions and access timing. The trust policy establishes the secure relationship between accounts, while AssumeRole provides the temporary access mechanism with built-in expiration.

**Q3: Your enterprise organization uses Microsoft Active Directory for user authentication and wants to provide federated access to AWS resources across multiple accounts. Users should retain their existing corporate identities and access should be based on their AD group memberships. Which federation approach provides the best scalability and management efficiency?**

**Answer: 2**
**Explanation:** AWS IAM Identity Center (AWS SSO) with Microsoft AD as the identity source is the optimal solution for multi-account environments. IAM Identity Center is specifically designed for centralized access management across multiple AWS accounts within AWS Organizations. It integrates natively with Microsoft AD, preserves existing user identities and group memberships, and provides centralized permission management. This approach scales efficiently across multiple accounts and reduces administrative overhead compared to configuring SAML federation in each individual account.

**Q4: When implementing Attribute-Based Access Control (ABAC) with IAM Identity Center, a developer should only access EC2 instances tagged with their department and project. The developer's attributes include Department=Engineering and Project=WebApp. Which IAM policy condition correctly implements this requirement?**

**Answer: 1**
**Explanation:** The condition `"StringEquals": {"ec2:ResourceTag/Department": "${aws:PrincipalTag/Department}", "ec2:ResourceTag/Project": "${aws:PrincipalTag/Project}"}` correctly implements ABAC by comparing resource tags with principal (user) tags. This condition ensures that access is granted only when both the Department and Project tags on the EC2 resource match the corresponding attributes of the authenticated user. The `${aws:PrincipalTag/TagName}` variable substitution allows dynamic comparison with the user's session tags passed during federation.

**Q5: A financial services company needs to implement cross-account access for their audit team to review CloudTrail logs stored in a central security account. The audit team should have read-only access and the solution should follow AWS security best practices. What is the recommended approach?**

**Answer: 2**
**Explanation:** Creating a cross-account IAM role in the security account with read permissions, establishing trust with the audit account, and using AssumeRole follows AWS security best practices. This approach provides temporary credentials, allows precise permission control (read-only), enables audit trails of who accessed what and when, and avoids sharing long-term credentials. The cross-account role approach is the recommended pattern for providing external account access to sensitive resources like audit logs.

**Q6: Your organization uses SAML 2.0 federation with AWS IAM for single sign-on. The identity provider passes user attributes including cost center, department, and job function. You want to ensure that users can only access AWS resources tagged with their cost center. Which component is essential for implementing this ABAC pattern?**

**Answer: 2**
**Explanation:** Session tags that pass user attributes from the SAML assertion to AWS are essential for implementing ABAC with SAML federation. When users authenticate through SAML, the identity provider can pass user attributes as session tags in the SAML assertion. These session tags become available as `${aws:PrincipalTag/TagName}` variables in IAM policy conditions, allowing dynamic access control based on user attributes. This enables the cost center attribute to be used in policy conditions to match against resource tags.

**Q7: A startup company is rapidly growing and frequently reorganizing teams. They want an access control system that automatically grants permissions when new resources are created with appropriate tags, without requiring manual policy updates for each team change. Which approach best addresses this requirement?**

**Answer: 2**
**Explanation:** ABAC with dynamic permission evaluation based on resource and principal tags is ideal for rapidly changing organizations. Unlike RBAC, which requires updating policies for each organizational change, ABAC policies remain static while permissions dynamically adjust based on current user attributes and resource tags. When teams reorganize or new resources are created, access is automatically determined by tag matching, eliminating the need for manual policy updates and reducing administrative overhead.

**Q8: When configuring cross-account access using IAM roles, a trust policy in the target account allows an external account to assume the role. However, what additional configuration is required in the external account for users to successfully assume the role?**

**Answer: 2**
**Explanation:** Users in the external account must have explicit permissions to assume the role via the sts:AssumeRole action. The trust policy alone only defines who CAN assume the role, but users still need explicit permissions to actually perform the AssumeRole action. This requires an identity-based policy attached to the user or role in the external account that grants the sts:AssumeRole permission for the specific target role ARN. This two-way permission model ensures that both accounts explicitly authorize the cross-account access.

**Q9: Your organization wants to implement zero-trust principles for AWS access. Users should authenticate through your corporate identity provider and receive temporary credentials with minimal privileges based on their current role and the specific resources they need to access. Which combination of services best supports this architecture?**

**Answer: 2**
**Explanation:** AWS IAM Identity Center with SAML federation, ABAC, and session-based permissions best supports zero-trust principles. This combination provides: external authentication through corporate IdP (never trust), temporary credentials (minimize exposure), dynamic permission evaluation based on current user context (verify continuously), and attribute-based access control for minimal privilege access to specific resources. IAM Identity Center integrates these components seamlessly and supports the scale and complexity required for enterprise zero-trust implementations.

**Q10: A multinational corporation has development teams in different regions who need access to region-specific resources. Each team should only access resources in their assigned region and tagged with their team identifier. The company wants to minimize administrative overhead while maintaining security. What is the most efficient approach using AWS best practices?**

**Answer: 2**
**Explanation:** Using IAM Identity Center with ABAC, implementing conditions based on aws:RequestedRegion and resource tags matching team attributes is the most efficient approach. This solution uses a single, dynamic policy that restricts access based on both the requested region and team attributes passed as session tags. The policy automatically enforces regional and team-based access without requiring separate policies for each team-region combination, significantly reducing administrative overhead while maintaining granular security controls.
