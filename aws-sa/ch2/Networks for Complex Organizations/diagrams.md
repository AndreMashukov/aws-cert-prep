# AWS Topic: Designing Networks for Complex Organizations - Architecture Diagrams

- https://www.youtube.com/watch?v=4ZEKIo56_0Q

## Overview
These diagrams illustrate the most complex networking architectures and decision points that Solutions Architects encounter when designing networks for large-scale organizations. Each diagram focuses on architectural trade-offs, scalability considerations, and integration patterns between multiple AWS networking services.

## Diagram 1: Multi-Region Direct Connect with Transit Gateway Architecture

```
┌─────────────────────── On-Premises Data Center ────────────────────────┐
│                                                                         │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                │
│  │   Router    │    │   Firewall  │    │    Core     │                │
│  │   Core      │────│   Cluster   │────│   Switch    │                │
│  └─────────────┘    └─────────────┘    └─────────────┘                │
│          │                                     │                       │
└──────────┼─────────────────────────────────────┼───────────────────────┘
           │                                     │
           │ Direct Connect                      │ Backup DX
           │ (Primary)                           │ (Different Location)
           v                                     v
┌─────────────────┐                   ┌─────────────────┐
│   DX Location   │                   │   DX Location   │
│   (Primary)     │                   │   (Secondary)   │
└─────────────────┘                   └─────────────────┘
           │                                     │
           │ Dedicated Connection                │ Dedicated Connection
           │ 10 Gbps                            │ 10 Gbps
           v                                     v
┌─────────────────────────────────────────────────────────────────────────┐
│                    AWS Direct Connect Gateway                           │
│                        (Global Resource)                               │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐        │
│  │   Private VIF   │  │   Private VIF   │  │   Public VIF    │        │
│  │   us-east-1     │  │   eu-west-1     │  │   (S3, CF, etc) │        │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘        │
└─────────────────────────────────────────────────────────────────────────┘
           │                         │                         │
           v                         v                         v
┌─────────────────┐         ┌─────────────────┐     ┌─────────────────┐
│   us-east-1     │         │   eu-west-1     │     │  AWS Public     │
│  Transit GW     │         │  Transit GW     │     │   Services      │
│                 │         │                 │     │                 │
│ ┌─────────────┐ │         │ ┌─────────────┐ │     │ • S3            │
│ │    VPC-A    │ │         │ │    VPC-D    │ │     │ • CloudFront    │
│ │ Production  │ │         │ │ Production  │ │     │ • Route 53      │
│ └─────────────┘ │         │ └─────────────┘ │     │ • AWS APIs      │
│ ┌─────────────┐ │         │ ┌─────────────┐ │     └─────────────────┘
│ │    VPC-B    │ │         │ │    VPC-E    │ │
│ │Development  │ │         │ │Development  │ │
│ └─────────────┘ │         │ └─────────────┘ │
│ ┌─────────────┐ │         │ ┌─────────────┐ │
│ │    VPC-C    │ │         │ │    VPC-F    │ │
│ │   Staging   │ │         │ │   Staging   │ │
│ └─────────────┘ │         │ └─────────────┘ │
└─────────────────┘         └─────────────────┘
```

### Key Decision Points
- **Direct Connect Gateway**: Single global resource eliminates need for multiple DX connections per region
- **Redundancy Strategy**: Primary/secondary DX locations prevent single point of failure
- **VIF Types**: Private VIFs for VPC access, Public VIF for AWS service access
- **Regional Isolation**: Transit Gateways provide regional network hubs with local route control
- **Cost Optimization**: Single DX connection serves multiple regions and VPCs

## Diagram 2: VPN CloudHub with Mixed Connectivity Architecture

```
                           ┌─── Branch Office A ───┐
                           │                       │
                           │ ┌─────────────────┐   │
                           │ │ Customer GW     │   │
                           │ │ (BGP Capable)   │   │
                           │ └─────────────────┘   │
                           │   192.168.1.0/24     │
                           └───────────┬───────────┘
                                       │ VPN Tunnel 1
                                       │ (IPsec)
                                       v
┌─── Branch Office B ───┐    ┌─────────────────────────────┐    ┌─── Branch Office C ───┐
│                       │    │                             │    │                       │
│ ┌─────────────────┐   │    │        AWS Region           │    │ ┌─────────────────┐   │
│ │ Customer GW     │   │◄───┤                             ├───►│ │ Customer GW     │   │
│ │ (Static Route)  │   │    │  ┌─────────────────────┐    │    │ │ (BGP Capable)   │   │
│ └─────────────────┘   │    │  │                     │    │    │ └─────────────────┘   │
│   192.168.2.0/24     │    │  │   Virtual Private   │    │    │   192.168.3.0/24     │
└───────────┬───────────┘    │  │     Gateway         │    │    └───────────┬───────────┘
            │ VPN Tunnel 2   │  │                     │    │                │ VPN Tunnel 3
            │ (IPsec)        │  │ ┌─────────────────┐ │    │                │ (IPsec)
            v                │  │ │   Route Table   │ │    │                v
                             │  │ │                 │ │    │
┌─── HQ Data Center ───┐    │  │ │ • 192.168.1.0/24│ │    │
│                       │    │  │ │ • 192.168.2.0/24│ │    │
│ ┌─────────────────┐   │    │  │ │ • 192.168.3.0/24│ │    │
│ │   Direct        │   │◄───┤  │ │ • 10.0.0.0/8    │ │    │
│ │   Connect       │   │    │  │ └─────────────────┘ │    │
│ │   Gateway       │   │    │  └─────────────┬───────┘    │
│ └─────────────────┘   │    │                │            │
│   10.0.0.0/8         │    │                v            │
└───────────┬───────────┘    │        ┌─────────────┐      │
            │ DX Connection   │        │    VPC      │      │
            │ (Private VIF)   │        │ 10.0.1.0/24 │      │
            v                │        └─────────────┘      │
                             └─────────────────────────────┘

Traffic Flow Examples:
Branch A → Branch B: A → VGW → B (through AWS backbone)
Branch A → HQ: A → VGW → DX → HQ (hybrid path)
Branch A → VPC: A → VGW → VPC (direct AWS access)
```

### Explanation
- **Hub-and-Spoke Design**: VPN CloudHub creates secure branch-to-branch communication
- **Mixed Connectivity**: Combines VPN (branches) with Direct Connect (headquarters)
- **BGP vs Static**: BGP provides automatic failover, static routes need manual management
- **Cost Efficiency**: Single VGW serves multiple sites, reducing AWS charges
- **Scalability Limit**: VGW supports up to 10 VPN connections, use Transit Gateway for larger deployments

## Diagram 3: Transit Gateway Route Table Segmentation

```
┌────────────────────────────── Transit Gateway ──────────────────────────────┐
│                                                                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐              │
│  │   Production    │  │  Development    │  │    Shared       │              │
│  │  Route Table    │  │  Route Table    │  │  Route Table    │              │
│  │                 │  │                 │  │                 │              │
│  │ Routes:         │  │ Routes:         │  │ Routes:         │              │
│  │ • 10.1.0.0/16   │  │ • 10.2.0.0/16   │  │ • 10.1.0.0/16   │              │
│  │ • 10.3.0.0/16   │  │ • 10.4.0.0/16   │  │ • 10.2.0.0/16   │              │
│  │ • 192.168.0.0/16│  │ • 192.168.0.0/16│  │ • 10.3.0.0/16   │              │
│  │ (On-premises)   │  │ (On-premises)   │  │ • 10.4.0.0/16   │              │
│  │                 │  │                 │  │ • 192.168.0.0/16│              │
│  │ Blackhole:      │  │ Blackhole:      │  │ (On-premises)   │              │
│  │ • 10.2.0.0/16   │  │ • 10.1.0.0/16   │  │                 │              │
│  │ • 10.4.0.0/16   │  │ • 10.3.0.0/16   │  │                 │              │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘              │
│           │                     │                     │                     │
└───────────┼─────────────────────┼─────────────────────┼─────────────────────┘
            │                     │                     │
            v                     v                     v
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Production     │    │  Development    │    │   Shared        │
│  VPC Subnet     │    │  VPC Subnet     │    │  Services VPC   │
│                 │    │                 │    │                 │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │   Prod-A    │ │    │ │   Dev-A     │ │    │ │  DNS Server │ │
│ │ 10.1.1.0/24 │ │    │ │ 10.2.1.0/24 │ │    │ │ 10.3.1.10   │ │
│ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │
│ ┌─────────────┐ │    │ ┌─────────────┐ │    │ ┌─────────────┐ │
│ │   Prod-B    │ │    │ │   Dev-B     │ │    │ │ Monitoring  │ │
│ │ 10.1.2.0/24 │ │    │ │ 10.2.2.0/24 │ │    │ │ 10.3.2.0/24 │ │
│ └─────────────┘ │    │ └─────────────┘ │    │ └─────────────┘ │
└─────────────────┘    └─────────────────┘    └─────────────────┘
            │                     │                     │
            │                     │                     │
            └──────────┬──────────┴──────────┬──────────┘
                       │                     │
                       v                     v
              ┌─────────────────┐  ┌─────────────────┐
              │   On-Premises   │  │  Direct Connect │
              │    Network      │  │    Gateway      │
              │ 192.168.0.0/16  │  │                 │
              └─────────────────┘  └─────────────────┘

Network Isolation Rules:
✅ Production → On-premises (Allowed)
✅ Development → On-premises (Allowed)
✅ Production → Shared Services (Allowed)
✅ Development → Shared Services (Allowed)
❌ Production → Development (Blocked via Blackhole)
❌ Development → Production (Blocked via Blackhole)
```

### Architectural Benefits
- **Network Segmentation**: Separate route tables provide isolation without separate infrastructure
- **Selective Connectivity**: Shared services accessible from all environments, but environments isolated from each other
- **Centralized Management**: Single Transit Gateway with multiple route tables vs multiple TGWs
- **Cost Optimization**: Reduces need for duplicate shared services in each environment
- **Compliance**: Ensures production and development traffic cannot intermingle

## Diagram 4: VPC Endpoints Decision Matrix and Architecture

```
┌─────────────────────── VPC (10.0.0.0/16) ───────────────────────┐
│                                                                  │
│  ┌─────────────────┐                    ┌─────────────────┐     │
│  │  Private Subnet │                    │  Private Subnet │     │
│  │   10.0.1.0/24   │                    │   10.0.2.0/24   │     │
│  │                 │                    │                 │     │
│  │ ┌─────────────┐ │                    │ ┌─────────────┐ │     │
│  │ │     EC2     │ │                    │ │   Lambda    │ │     │
│  │ │Application  │ │                    │ │  Function   │ │     │
│  │ └─────────────┘ │                    │ └─────────────┘ │     │
│  └─────────────────┘                    └─────────────────┘     │
│           │                                       │             │
│           │ Access to AWS Services                │             │
│           v                                       v             │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              Service Access Decision Tree               │   │
│  │                                                         │   │
│  │  S3 / DynamoDB?  ────┐                                 │   │
│  │       │              │                                 │   │
│  │      YES             NO                                │   │
│  │       │              │                                 │   │
│  │       v              v                                 │   │
│  │  ┌─────────┐    ┌─────────┐                           │   │
│  │  │Gateway  │    │Interface│                           │   │
│  │  │Endpoint │    │Endpoint │                           │   │
│  │  │         │    │         │                           │   │
│  │  │ • Free  │    │• $0.01/hr│                          │   │
│  │  │ • S3    │    │• Most   │                           │   │
│  │  │ • DDB   │    │  Services│                           │   │
│  │  └─────────┘    └─────────┘                           │   │
│  └─────────────────────────────────────────────────────────┘   │
│           │                              │                     │
│           v                              v                     │
│  ┌─────────────────┐            ┌─────────────────┐            │
│  │  Gateway VPC    │            │ Interface VPC   │            │
│  │   Endpoint      │            │   Endpoint      │            │
│  │                 │            │                 │            │
│  │  Target: S3     │            │ Target: EC2     │            │
│  │  Route: Local   │            │ ENI: 10.0.3.10  │            │
│  └─────────────────┘            └─────────────────┘            │
│           │                              │                     │
└───────────┼──────────────────────────────┼─────────────────────┘
            │                              │
            │ Route to S3                  │ Private DNS
            │ via Gateway                  │ Resolution
            v                              v
┌─────────────────┐              ┌─────────────────┐
│      AWS S3     │              │    AWS EC2     │
│    Service      │              │    Service     │
│                 │              │                 │
│ • Bucket Access │              │ • API Calls    │
│ • No Internet   │              │ • No Internet  │
│ • No Data Proc  │              │ • Private IP   │
│   Charges       │              │   Access       │
└─────────────────┘              └─────────────────┘

Service Endpoint Decision Matrix:
┌─────────────────┬─────────────────┬─────────────────┬─────────────────┐
│    Service      │  Gateway        │  Interface      │  Recommended    │
│                 │  Support        │  Support        │  Choice         │
├─────────────────┼─────────────────┼─────────────────┼─────────────────┤
│ S3              │       ✅        │       ✅        │   Gateway       │
│ DynamoDB        │       ✅        │       ✅        │   Gateway       │
│ EC2             │       ❌        │       ✅        │   Interface     │
│ Lambda          │       ❌        │       ✅        │   Interface     │
│ SNS             │       ❌        │       ✅        │   Interface     │
│ SQS             │       ❌        │       ✅        │   Interface     │
│ KMS             │       ❌        │       ✅        │   Interface     │
│ CloudWatch      │       ❌        │       ✅        │   Interface     │
└─────────────────┴─────────────────┴─────────────────┴─────────────────┘
```

### Cost and Performance Considerations
- **Gateway Endpoints**: No hourly charges, no data processing fees, route-based access
- **Interface Endpoints**: $0.01/hour + $0.01/GB processed, ENI-based access with private DNS
- **Security**: Both eliminate internet gateway dependency and provide private access
- **Scalability**: Gateway endpoints scale automatically, Interface endpoints limited by ENI capacity

## Diagram 5: Cross-Account Direct Connect Gateway Sharing

```
┌─────────────────── Account A (DX Gateway Owner) ─────────────────┐
│                                                                  │
│        ┌─────────────────────────────────────────┐              │
│        │      AWS Direct Connect Gateway         │              │
│        │         (Global Resource)               │              │
│        │                                         │              │
│        │  Accepted Associations:                │              │
│        │  • Account B: VGW-123 (10.1.0.0/16)   │              │
│        │  • Account C: VGW-456 (10.2.0.0/16)   │              │
│        │  • Account A: TGW-789 (10.0.0.0/16)   │              │
│        └─────────────────────────────────────────┘              │
│                            │                                    │
│  ┌─────────────────────────┼─────────────────────────┐          │
│  │                         │                         │          │
│  │        Account A owns routing decisions           │          │
│  │        and controls allowed prefixes              │          │
│  └─────────────────────────┼─────────────────────────┘          │
└──────────────────────────────────────────────────────────────────┘
                             │
                             │ Private VIF Connection
                             │ (Cross-account sharing)
         ┌───────────────────┼───────────────────┐
         │                   │                   │
         v                   v                   v
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│   Account A     │ │   Account B     │ │   Account C     │
│   (Owner)       │ │ (Requestor)     │ │ (Requestor)     │
│                 │ │                 │ │                 │
│ ┌─────────────┐ │ │ ┌─────────────┐ │ │ ┌─────────────┐ │
│ │Transit GW   │ │ │ │Virtual      │ │ │ │Virtual      │ │
│ │ TGW-789     │ │ │ │Private GW   │ │ │ │Private GW   │ │
│ │             │ │ │ │ VGW-123     │ │ │ │ VGW-456     │ │
│ └─────────────┘ │ │ └─────────────┘ │ │ └─────────────┘ │
│        │        │ │        │        │ │        │        │
│ ┌─────────────┐ │ │ ┌─────────────┐ │ │ ┌─────────────┐ │
│ │    VPC      │ │ │ │    VPC      │ │ │ │    VPC      │ │
│ │10.0.1.0/24  │ │ │ │10.1.1.0/24  │ │ │ │10.2.1.0/24  │ │
│ └─────────────┘ │ │ └─────────────┘ │ │ └─────────────┘ │
│ ┌─────────────┐ │ │ ┌─────────────┐ │ │ ┌─────────────┐ │
│ │    VPC      │ │ │ │    VPC      │ │ │ │    VPC      │ │
│ │10.0.2.0/24  │ │ │ │10.1.2.0/24  │ │ │ │10.2.2.0/24  │ │
│ └─────────────┘ │ │ └─────────────┘ │ │ └─────────────┘ │
└─────────────────┘ └─────────────────┘ └─────────────────┘

Association Request Flow:
1. Account B → Account A: "Please associate VGW-123"
2. Account A reviews and accepts proposal
3. Account A configures allowed prefixes (optional)
4. Account B can now route to on-premises via DX Gateway
5. Account A maintains full routing control

Inter-Account Communication Rules:
❌ Account B VPC → Account C VPC (Blocked by DX Gateway)
✅ Account B VPC → On-premises (Allowed via DX Gateway)
✅ Account A VPC → Account B VPC (If supernet advertised from on-premises)
```

### Security and Control Model
- **Ownership Model**: DX Gateway owner (Account A) controls all routing decisions
- **Association Proposals**: Requestor accounts must send proposals for gateway access
- **Prefix Control**: Owner can limit which prefixes are advertised to/from each account
- **Isolation**: VPCs in different accounts cannot communicate unless explicitly configured
- **Billing**: DX Gateway owner pays for data transfer charges

## Summary

These diagrams illustrate the key architectural patterns and decision points for designing networks in complex AWS organizations:

1. **Multi-Region Connectivity**: Use Direct Connect Gateway for global reach with regional Transit Gateways
2. **Hybrid VPN Architectures**: VPN CloudHub for branch connectivity with mixed DX for headquarters
3. **Network Segmentation**: Transit Gateway route tables for environment isolation with shared services
4. **Service Access Optimization**: Choose Gateway vs Interface endpoints based on service and cost requirements
5. **Cross-Account Sharing**: Direct Connect Gateway sharing model for enterprise multi-account scenarios

Each pattern addresses specific scalability, cost, and security requirements that Solutions Architects must balance in enterprise networking decisions.
