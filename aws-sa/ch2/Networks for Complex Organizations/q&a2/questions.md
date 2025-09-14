# AWS Networking Glossary Q&A

## Core Networking Services

**Q1: What is the primary advantage of AWS Direct Connect over Site-to-Site VPN for enterprise connectivity?**
1. It provides automatic encryption for all network traffic
2. It offers consistent bandwidth and lower latency with reduced data transfer costs
3. It requires no BGP configuration and uses static routing
4. It supports unlimited bandwidth without any capacity planning

**Q2: How does AWS Direct Connect Gateway differ from a standard Direct Connect connection?**
1. It provides internet-based connectivity instead of dedicated connections
2. It enables connectivity to multiple VPCs across regions and accounts through a single global resource
3. It uses static routing instead of BGP for simplicity
4. It automatically creates site-to-site VPN connections

**Q3: What architectural pattern does AWS Transit Gateway implement?**
1. Full mesh connectivity between all VPCs
2. Hub-and-spoke topology with centralized routing and segmentation
3. Point-to-point direct connections between VPCs
4. Star topology with internet gateway as the central point

**Q4: In which scenario would Site-to-Site VPN be preferred over Direct Connect?**
1. When quick setup and temporary connectivity over the internet is acceptable
2. When you need guaranteed 10Gbps bandwidth with sub-millisecond latency
3. When you require physical fiber connections to AWS data centers
4. When you need to bypass all internet routing for compliance reasons

## VPN Components

**Q5: What is the primary function of a Virtual Private Gateway (VGW) in AWS networking?**
1. To represent customer-side networking equipment (Customer Gateway)
2. To serve as the AWS-managed endpoint that terminates IPsec VPN tunnels
3. To provide internet connectivity for public subnets (Internet Gateway)
4. To enable private connectivity to AWS services without internet access (VPC Endpoint)

**Q6: How does AWS VPN CloudHub facilitate communication between multiple branch offices?**
1. By establishing direct site-to-site connections between all branches
2. By creating dedicated Direct Connect connections between each branch location
3. By using a central VGW with multiple Customer Gateways for hub-and-spoke communication
4. By leveraging public internet routing with enhanced security protocols

## VPC Connectivity

**Q7: Which AWS services can be accessed using Gateway VPC Endpoints?**
1. All AWS services including EC2, S3, and DynamoDB
2. Only compute services like EC2 and Lambda
3. S3 and DynamoDB specifically
4. Any service that supports AWS PrivateLink technology

**Q8: What is the primary use case for a NAT Gateway in AWS VPC architecture?**
1. To enable instances in private subnets to initiate outbound internet connections
2. To provide private connectivity to AWS services without internet exposure
3. To encrypt all traffic between VPCs and on-premises networks
4. To replace the need for internet gateways in public subnets

## Advanced Networking Concepts

**Q9: What is the key difference between Private VIF and Public VIF in Direct Connect?**
1. Private VIFs use encryption while Public VIFs do not
2. Private VIFs access VPC resources, Public VIFs access AWS public services
3. Public VIFs are free while Private VIFs have hourly charges
4. Private VIFs require internet connectivity while Public VIFs use dedicated connections

**Q10: Why is BGP routing essential for AWS hybrid connectivity solutions?**
1. It provides automatic IPsec encryption for VPN tunnels
2. It enables dynamic routing with automatic failover and route propagation
3. It reduces data transfer costs through traffic compression
4. It automatically synchronizes security policies across networks

## Network Segmentation & Security

**Q11: How do blackhole routes enhance security in Transit Gateway?**
1. They encrypt all traffic passing through the Transit Gateway
2. They automatically detect and block malicious network patterns
3. They provide SSL termination for all VPC-to-VPC communication
4. They intentionally drop traffic to specific CIDR blocks to prevent unauthorized communication

**Q12: What is a key characteristic of AWS Security Groups?**
1. They are stateful firewalls that only support allow rules at the instance level
2. They operate at the subnet level like network ACLs
3. They automatically allow all outbound traffic by default
4. They provide automatic DDoS protection for all instances

## Cross-Account Concepts

**Q13: How is Direct Connect Gateway sharing typically implemented between AWS accounts?**
1. Through automatic sharing via AWS Organizations
2. Using association proposals where requestor accounts send proposals to the gateway owner
3. By using IAM roles that grant full access to all accounts
4. Through automatic VPC peering connections between accounts

**Q14: Which networking resources can be shared using AWS Resource Access Manager (RAM)?**
1. Direct Connect Gateway connections and Virtual Interfaces
2. Only compute resources like EC2 instances across accounts
3. VPC subnets, Transit Gateways, but not Direct Connect Gateway
4. All AWS networking services through unified sharing

## Architectural Patterns

**Q15: What is the main benefit of hub-and-spoke architecture for large enterprises?**
1. It provides the lowest possible latency for all network connections
2. It offers centralized management and reduced connection complexity
3. It eliminates the need for any routing configuration
4. It automatically scales to handle unlimited VPC connections

**Q16: How do Direct Connect Gateway and Transit Gateway work together in multi-region designs?**
1. Direct Connect Gateway provides regional connectivity while Transit Gateway enables global access
2. They are mutually exclusive and cannot be used together
3. Direct Connect Gateway replaces the need for Transit Gateway in multi-region designs
4. Transit Gateway acts as regional hubs while Direct Connect Gateway provides global hybrid connectivity

## Decision Framework

**Q17: What is the primary cost difference between Gateway and Interface VPC Endpoints?**
1. Gateway endpoints charge per GB of data processed
2. Gateway endpoints are free while interface endpoints have hourly + data processing charges
3. Both have identical pricing based on data transfer volume
4. Interface endpoints are completely free for all AWS services

**Q18: When might an organization use both Direct Connect and Site-to-Site VPN simultaneously?**
1. For redundancy where VPN serves as backup for Direct Connect primary connectivity
2. To reduce data transfer costs for internet-based traffic
3. To comply with regulatory requirements for encrypted backup links
4. When they need different bandwidth limits for various traffic types