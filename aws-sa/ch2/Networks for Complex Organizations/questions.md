# AWS Topic: Designing Networks for Complex Organizations

## Questions

**Q1: A large enterprise with multiple branch offices needs to establish secure connectivity between all locations and their AWS environment. They want a simple, cost-effective solution that allows branch offices to communicate with each other and with AWS resources. What AWS solution should they implement?**
1. AWS Site-to-Site VPN with individual connections from each branch to a Virtual Private Gateway
2. AWS VPN CloudHub with multiple Customer Gateways connected to a single Virtual Private Gateway
3. AWS Direct Connect with dedicated connections from each branch office
4. Software VPN appliances running on EC2 instances in each region

**Q2: An organization is designing a network architecture that requires connecting 15 VPCs across 3 AWS regions to their on-premises data center via AWS Direct Connect. They need the most scalable and cost-effective solution. What combination of AWS services should they use?**
1. Direct Connect Gateway with Virtual Private Gateways attached to each VPC
2. Direct Connect Gateway with Transit Gateways in each region
3. Individual Direct Connect connections to each VPC
4. Site-to-Site VPN connections with Transit Gateway attachments

**Q3: A company has deployed a software VPN appliance on an EC2 instance to connect their on-premises network to AWS. What are the primary operational concerns they must address that would not be present with AWS Managed VPN?**
1. BGP routing configuration and tunnel redundancy
2. Single point of failure, OS patching, and software updates management
3. Internet connectivity reliability and bandwidth limitations
4. Customer Gateway device compatibility and IPsec configuration

**Q4: An organization needs to provide private connectivity from their VPC to AWS services without routing traffic over the internet. They want to access both S3 and DynamoDB from their private subnets. What is the most appropriate solution?**
1. Configure NAT Gateway for outbound internet access to AWS services
2. Create Interface VPC Endpoints for both S3 and DynamoDB
3. Create a Gateway VPC Endpoint for S3 and Interface VPC Endpoint for DynamoDB
4. Create Gateway VPC Endpoints for both S3 and DynamoDB

**Q5: A Solutions Architect is designing a multi-account environment where Account A owns a Direct Connect Gateway and Accounts B and C need to connect their VPCs to on-premises networks through this gateway. What is the correct approach for cross-account Direct Connect Gateway sharing?**
1. Account A creates VPC attachments on behalf of Accounts B and C
2. Account A shares the Direct Connect Gateway using AWS Resource Access Manager (RAM)
3. Accounts B and C send association proposals to Account A, who accepts and manages routing
4. Accounts B and C must create their own Direct Connect Gateways and peer them with Account A

**Q6: A company is evaluating AWS Direct Connect vs Site-to-Site VPN for their hybrid connectivity requirements. In which scenario would AWS Direct Connect be the preferred choice over VPN?**
1. When the organization needs to quickly establish connectivity with minimal configuration changes
2. When consistent bandwidth, low latency, and reduced data transfer costs are critical business requirements
3. When the organization requires encrypted connectivity over the internet
4. When connecting a single on-premises location to one VPC in AWS

**Q7: An enterprise has implemented Transit Gateway to connect 50 VPCs across development, staging, and production environments. They need to ensure that development VPCs cannot communicate with production VPCs. What is the most effective approach?**
1. Use separate route tables and associate different VPC attachments with appropriate route tables
2. Create separate Transit Gateways for each environment
3. Implement Security Groups to block traffic between environments
4. Use VPC Peering instead of Transit Gateway for better isolation

**Q8: A multinational corporation needs to connect their AWS environment in us-east-1 to VPCs in ap-southeast-1 and eu-west-1 through their on-premises data center. What is the most appropriate AWS networking solution?**
1. Direct Connect Gateway with Transit Gateway attachments in each region
2. VPC Peering connections between regions through the on-premises network
3. Site-to-Site VPN connections from each region to on-premises
4. Transit Gateway Peering between regions with Direct Connect to on-premises

**Q9: A company using AWS Direct Connect with a private Virtual Interface (VIF) needs to access AWS public services like S3 and CloudFront from their on-premises network. What additional component do they need to implement?**
1. Create an Internet Gateway and modify their routing tables
2. Implement a NAT Gateway in their VPC and route traffic through it
3. Use VPC Endpoints to access public services privately
4. Configure a public Virtual Interface (VIF) on the same Direct Connect connection

**Q10: An organization has a Transit Gateway with multiple VPC attachments and wants to prevent VPC-to-VPC communication while still allowing all VPCs to communicate with on-premises networks through Direct Connect. What is the most effective configuration approach?**
1. Disable route propagation between VPC attachments
2. Associate VPC attachments with route tables that have blackhole routes for other VPC CIDRs
3. Use separate Transit Gateways for each VPC
4. Implement Security Groups at the VPC level to block inter-VPC traffic
