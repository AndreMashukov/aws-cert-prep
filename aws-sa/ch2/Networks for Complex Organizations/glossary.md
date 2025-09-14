https://claude.ai/public/artifacts/4093d194-c2ed-4847-a64b-80fa6a19d285
# AWS Networking Glossary for Complex Organizations

## Core Networking Services

### AWS Direct Connect
**Definition**: A dedicated network connection from your premises to AWS that bypasses the internet, providing consistent bandwidth, low latency, and reduced data transfer costs.
**Key Features**:
- Private connectivity to AWS
- Consistent network performance
- Reduced data transfer costs
- Supports 1Gbps and 10Gbps connections
**Relationships**:
- Connects to → Direct Connect Gateway
- Uses → Virtual Interfaces (VIFs)
- Alternative to → Site-to-Site VPN

### AWS Direct Connect Gateway
**Definition**: A globally available resource that enables connectivity between Direct Connect connections and multiple VPCs across different AWS regions and accounts.
**Key Features**:
- Global resource (works across all regions)
- Supports cross-account sharing
- Acts as BGP route reflector
- Eliminates need for multiple DX connections
**Relationships**:
- Connects → Multiple VPCs across regions
- Associated with → Virtual Private Gateways or Transit Gateways
- Uses → Private/Public VIFs

### AWS Transit Gateway
**Definition**: A regional network transit hub that interconnects VPCs and on-premises networks using a hub-and-spoke architecture.
**Key Features**:
- Regional service (per region)
- Supports up to 5,000 VPC attachments
- Multiple route tables for segmentation
- Inter-region peering capability
**Relationships**:
- Connects → Multiple VPCs within region
- Attaches to → Direct Connect Gateway
- Uses → Route tables for traffic control

### AWS Site-to-Site VPN
**Definition**: An IPsec VPN connection between your network and AWS VPC over the internet.
**Key Features**:
- Encrypted connectivity
- Quick to set up
- Supports static and dynamic (BGP) routing
- Lower cost than Direct Connect
**Relationships**:
- Uses → Virtual Private Gateway (AWS side)
- Uses → Customer Gateway (customer side)
- Alternative to → Direct Connect

## VPN Components

### Virtual Private Gateway (VGW)
**Definition**: The AWS-side component of a VPN connection that terminates the IPsec tunnels.
**Key Features**:
- AWS-managed VPN endpoint
- Supports BGP routing
- Can be attached to VPCs
- Used in VPN CloudHub architecture
**Relationships**:
- Terminates → VPN connections
- Associated with → VPC
- Used in → VPN CloudHub

### Customer Gateway (CGW)
**Definition**: The customer-side component representing the physical device or software appliance that terminates the VPN connection.
**Key Features**:
- Represents customer VPN device
- Requires public IP address
- Supports BGP configuration
- Must be compatible with AWS VPN
**Relationships**:
- Connects to → Virtual Private Gateway
- Represents → Customer network equipment

### AWS VPN CloudHub
**Definition**: A hub-and-spoke VPN architecture that enables secure communication between multiple remote sites through AWS.
**Key Features**:
- Single VGW with multiple CGWs
- Enables branch-to-branch communication
- Uses BGP for dynamic routing
- Cost-effective for multiple sites
**Relationships**:
- Uses → Single Virtual Private Gateway
- Connects → Multiple Customer Gateways
- Enables → Site-to-site communication

## VPC Connectivity

### VPC Endpoints
**Definition**: Private connections between your VPC and supported AWS services without using internet gateways, NAT devices, or VPN connections.

#### Gateway VPC Endpoint
**Definition**: A route-based endpoint for specific services (S3, DynamoDB) that doesn't require ENIs.
**Key Features**:
- Free to use
- No data processing charges
- Route table based
- Supports S3 and DynamoDB only
**Relationships**:
- For → S3 and DynamoDB services
- Alternative to → Interface Endpoints

#### Interface VPC Endpoint
**Definition**: An ENI-based endpoint that uses AWS PrivateLink for private connectivity to AWS services.
**Key Features**:
- $0.01/hour per AZ + data processing
- Uses Elastic Network Interfaces (ENIs)
- Private DNS support
- Supports most AWS services
**Relationships**:
- For → Most AWS services (EC2, Lambda, etc.)
- Uses → AWS PrivateLink technology

### NAT Gateway
**Definition**: A managed NAT service that allows instances in private subnets to connect to the internet or other AWS services.
**Key Features**:
- Managed service (no maintenance)
- Highly available within AZ
- Supports up to 10Gbps bandwidth
- Charges for data processing
**Relationships**:
- Used in → Private subnets
- Provides → Outbound internet access
- Alternative to → VPC Endpoints for some scenarios

### Internet Gateway
**Definition**: A horizontally scaled, redundant VPC component that allows communication between instances in your VPC and the internet.
**Key Features**:
- Provides internet connectivity
- NAT for instances with public IPs
- No additional charges
- Required for public subnets
**Relationships**:
- Attached to → VPC
- Enables → Internet access

## Advanced Networking Concepts

### Virtual Interface (VIF)
**Definition**: A virtual connection on a Direct Connect connection that enables access to AWS services.

#### Private VIF
**Definition**: A VIF that provides access to resources within VPCs through a Virtual Private Gateway or Direct Connect Gateway.
**Key Features**:
- Access to VPC resources
- Uses private IP space
- Requires BGP configuration
**Relationships**:
- Connects to → VPC resources
- Used with → Private services

#### Public VIF
**Definition**: A VIF that provides access to AWS public services (S3, CloudFront, etc.) over Direct Connect.
**Key Features**:
- Access to public AWS services
- Bypasses internet for AWS services
- Reduced data transfer costs
**Relationships**:
- Connects to → AWS public services
- Alternative to → Internet access for AWS services

### BGP (Border Gateway Protocol)
**Definition**: A standardized exterior gateway protocol used to exchange routing information between networks.
**Key Features**:
- Dynamic routing protocol
- Supports automatic failover
- Used in VPN and Direct Connect
- Requires ASN configuration
**Relationships**:
- Used by → VPN connections
- Used by → Direct Connect
- Enables → Dynamic route propagation

### IPsec (Internet Protocol Security)
**Definition**: A protocol suite for securing Internet Protocol communications by authenticating and encrypting each IP packet.
**Key Features**:
- VPN encryption standard
- Provides data confidentiality
- Supports authentication
- Used in Site-to-Site VPN
**Relationships**:
- Used by → Site-to-Site VPN
- Provides → Secure tunnel encryption

## Network Segmentation & Security

### Route Tables
**Definition**: A set of rules that determines where network traffic from your subnet or gateway is directed.
**Key Features**:
- Controls traffic flow
- Supports static and dynamic routes
- Used in VPC and Transit Gateway
- Enables network segmentation
**Relationships**:
- Associated with → Subnets
- Used in → Transit Gateway for segmentation

### Security Groups
**Definition**: A stateful virtual firewall that controls inbound and outbound traffic for AWS resources.
**Key Features**:
- Instance-level security
- Stateful (return traffic allowed)
- Supports allow rules only
- VPC-specific
**Relationships**:
- Applied to → EC2 instances, ENIs
- Works with → Network ACLs

### Blackhole Routes
**Definition**: Routes that intentionally drop traffic matching specific CIDR blocks, used for traffic isolation.
**Key Features**:
- Prevents unwanted traffic
- Used in Transit Gateway route tables
- Maintains other connectivity
**Relationships**:
- Used in → Transit Gateway segmentation
- Prevents → Unauthorized communication

## Cross-Account Concepts

### Cross-Account Sharing
**Definition**: The ability to share AWS resources between different AWS accounts.

#### Direct Connect Gateway Sharing
**Definition**: The process where multiple accounts can use a single Direct Connect Gateway owned by another account.
**Key Features**:
- Owner account controls routing
- Requestor accounts send proposals
- Owner accepts/manages associations
- Maintains security boundaries
**Relationships**:
- Uses → Association proposals
- Controlled by → Gateway owner account

#### AWS Resource Access Manager (RAM)
**Definition**: A service that enables resource sharing between AWS accounts within an organization.
**Key Features**:
- Centralized resource sharing
- Supports VPC subnets, Transit Gateways
- Not used for Direct Connect Gateway sharing
**Relationships**:
- Alternative to → Direct sharing methods
- Used for → Other AWS resource types

## Architectural Patterns

### Hub-and-Spoke Architecture
**Definition**: A network topology where all traffic passes through a central hub (like Transit Gateway or VPN CloudHub).
**Key Features**:
- Centralized management
- Reduced connection complexity
- Scalable design
- Single point of control
**Relationships**:
- Implemented by → Transit Gateway
- Implemented by → VPN CloudHub

### Multi-Region Architecture
**Definition**: A design pattern that spans multiple AWS regions for redundancy, latency optimization, or compliance.
**Key Features**:
- Global connectivity
- Regional isolation
- Disaster recovery capability
- Increased complexity
**Relationships**:
- Uses → Direct Connect Gateway (global)
- Uses → Transit Gateway (regional)
- Requires → Inter-region peering

### Hybrid Connectivity
**Definition**: A network architecture that connects on-premises infrastructure with AWS cloud resources.
**Key Features**:
- Combines cloud and on-premises
- Multiple connectivity options
- Security considerations
- Bandwidth management
**Relationships**:
- Implemented via → Direct Connect
- Implemented via → Site-to-Site VPN
- Can use → Both (redundancy)

## Service Relationships Matrix

| Service | Primary Use Case | Key Features | Cost Model | Scalability |
|---------|------------------|--------------|------------|-------------|
| **Direct Connect** | High-performance hybrid connectivity | Consistent bandwidth, low latency | Connection + data transfer | 1-10Gbps per connection |
| **Site-to-Site VPN** | Internet-based secure connectivity | Quick setup, encrypted | Hourly + data transfer | Limited by internet bandwidth |
| **Transit Gateway** | Regional VPC interconnection | Hub-and-spoke, segmentation | Per attachment + data processing | 5,000 VPCs per region |
| **Direct Connect Gateway** | Global hybrid connectivity | Cross-region, cross-account | Data transfer only | Global scale |
| **VPN CloudHub** | Multi-site VPN connectivity | Branch-to-branch communication | Per VPN connection | Up to 10 VPN connections |
| **Gateway Endpoints** | Private S3/DynamoDB access | Free, route-based | No additional cost | Automatic scaling |
| **Interface Endpoints** | Private AWS service access | ENI-based, PrivateLink | Hourly + data processing | Limited by ENI capacity |

## Decision Framework

### When to Use Direct Connect vs VPN
- **Use Direct Connect when**: Consistent performance, low latency, high bandwidth, reduced data costs are critical
- **Use VPN when**: Quick setup, temporary connectivity, lower bandwidth requirements, internet-based OK

### When to Use Gateway vs Interface Endpoints
- **Use Gateway Endpoints for**: S3 and DynamoDB (free, no data charges)
- **Use Interface Endpoints for**: All other AWS services (EC2, Lambda, etc.)

### When to Use Transit Gateway vs VPC Peering
- **Use Transit Gateway when**: Multiple VPCs, need segmentation, cross-account sharing, regional hub
- **Use VPC Peering when**: Simple 1:1 VPC connectivity, no transit routing needed

### Multi-Region Strategy
- **Direct Connect Gateway**: Single global resource for all regions
- **Transit Gateway**: Regional hubs with inter-region peering
- **Combination**: Most scalable approach for large enterprises

This glossary provides a comprehensive reference for AWS networking services and patterns used in complex organizational designs, helping Solutions Architects make informed decisions about network architecture.