# AWS Networking Glossary Answers

## Core Networking Services

**Q1: What is the primary advantage of AWS Direct Connect over Site-to-Site VPN for enterprise connectivity?**
**Answer: 2**
Direct Connect provides consistent bandwidth, lower latency, and reduced data transfer costs by using dedicated network connections that bypass the internet, unlike VPN which relies on internet connectivity with variable performance.

**Q2: How does AWS Direct Connect Gateway differ from a standard Direct Connect connection?**
**Answer: 2**
Direct Connect Gateway enables connectivity to multiple VPCs across regions and accounts through a single global resource, acting as a BGP route reflector, while standard Direct Connect provides point-to-point connectivity to a single VPC.

**Q3: What architectural pattern does AWS Transit Gateway implement?**
**Answer: 2**
Transit Gateway implements a hub-and-spoke topology with centralized routing and segmentation, allowing multiple VPCs and on-premises networks to connect through a central hub with multiple route tables for traffic control.

**Q4: In which scenario would Site-to-Site VPN be preferred over Direct Connect?**
**Answer: 1**
Site-to-Site VPN is preferred when quick setup and temporary connectivity over the internet is acceptable, as it provides encrypted connectivity without requiring dedicated physical connections or long-term commitments.

## VPN Components

**Q5: What is the primary function of a Virtual Private Gateway (VGW) in AWS networking?**
**Answer: 2**
The Virtual Private Gateway serves as the AWS-managed endpoint that terminates IPsec VPN tunnels from customer networks, providing the AWS-side component of Site-to-Site VPN connections.

**Q6: How does AWS VPN CloudHub facilitate communication between multiple branch offices?**
**Answer: 4**
VPN CloudHub uses a central Virtual Private Gateway with multiple Customer Gateways in a hub-and-spoke architecture, enabling branch-to-branch communication through the AWS hub using BGP for dynamic routing between sites.

## VPC Connectivity

**Q7: Which AWS services can be accessed using Gateway VPC Endpoints?**
**Answer: 3**
Gateway VPC Endpoints specifically support S3 and DynamoDB services, providing free, route-based private connectivity without using ENIs or incurring hourly charges.

**Q8: What is the primary use case for a NAT Gateway in AWS VPC architecture?**
**Answer: 1**
NAT Gateway enables instances in private subnets to initiate outbound internet connections while preventing inbound connections from the internet, providing secure outbound internet access.

## Advanced Networking Concepts

**Q9: What is the key difference between Private VIF and Public VIF in Direct Connect?**
**Answer: 2**
Private VIFs provide access to VPC resources using private IP space through Virtual Private Gateways, while Public VIFs provide access to AWS public services (S3, CloudFront) over Direct Connect, bypassing the internet.

**Q10: Why is BGP routing essential for AWS hybrid connectivity solutions?**
**Answer: 2**
BGP enables dynamic routing with automatic failover and route propagation, allowing networks to automatically adapt to topology changes and providing redundancy without manual route updates in both VPN and Direct Connect implementations.

## Network Segmentation & Security

**Q11: How do blackhole routes enhance security in Transit Gateway?**
**Answer: 4**
Blackhole routes intentionally drop traffic to specific CIDR blocks, preventing unauthorized communication between network segments while maintaining other connectivity through the Transit Gateway, enabling effective network segmentation.

**Q12: What is a key characteristic of AWS Security Groups?**
**Answer: 1**
Security Groups are stateful virtual firewalls that only support allow rules at the instance level, requiring explicit permission for all traffic rather than providing default encryption or automatic blocking of inbound traffic.

## Cross-Account Concepts

**Q13: How is Direct Connect Gateway sharing typically implemented between AWS accounts?**
**Answer: 2**
Direct Connect Gateway sharing uses association proposals where requestor accounts send proposals to the gateway owner account, which maintains control over routing and security boundaries while allowing cross-account access.

**Q14: Which networking resources can be shared using AWS Resource Access Manager (RAM)?**
**Answer: 3**
RAM can share VPC subnets, Transit Gateways, and other AWS resources, but notably cannot share Direct Connect Gateway connections, which use a different sharing mechanism through association proposals.

## Architectural Patterns

**Q15: What is the main benefit of hub-and-spoke architecture for large enterprises?**
**Answer: 2**
Hub-and-spoke architecture offers centralized management and reduced connection complexity by funneling all traffic through central hubs (Transit Gateway or VPN CloudHub), making large networks more manageable and scalable.

**Q16: How do Direct Connect Gateway and Transit Gateway work together in multi-region designs?**
**Answer: 4**
Transit Gateway acts as regional hubs for intra-region VPC connectivity, while Direct Connect Gateway provides global hybrid connectivity, enabling a comprehensive multi-region strategy with both regional and global components working together.

## Decision Framework

**Q17: What is the primary cost difference between Gateway and Interface VPC Endpoints?**
**Answer: 2**
Gateway endpoints are free with no additional charges, while interface endpoints have hourly costs per AZ plus data processing charges, making gateway endpoints more cost-effective for supported services (S3, DynamoDB).

**Q18: When might an organization use both Direct Connect and Site-to-Site VPN simultaneously?**
**Answer: 1**
Organizations use both services for redundancy where Site-to-Site VPN serves as a backup for Direct Connect primary connectivity, ensuring business continuity if the dedicated connection fails while maintaining performance benefits.