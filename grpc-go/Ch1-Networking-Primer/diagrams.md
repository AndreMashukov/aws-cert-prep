# gRPC Topic: Chapter 1 - Networking Primer - Architecture Patterns

## Overview
This document provides ASCII diagrams illustrating the core gRPC communication patterns, RPC operations, and lifecycle components discussed in Chapter 1. The diagrams emphasize client-server communication flows, the four fundamental RPC operations, and the various streaming patterns that gRPC supports over HTTP/2.

## Diagram 1: Four Fundamental RPC Operations

```
gRPC Communication Flow - Basic Operations
==========================================

Client                                    Server
  |                                         |
  | 1. Send Header                         |
  |========================================>|
  |   POST /service/Method                 |
  |   content-type: application/grpc       |
  |   End Stream: False                    |
  |                                         |
  | 2. Send Message                        |
  |========================================>|
  |   [Protobuf-encoded request data]      |
  |                                         |
  | 3. Send Half-Close                     |
  |========================================>|
  |   End Stream: True                     |
  |   (Client done sending)                |
  |                                         |
  |                        4. Send Header  |
  |<========================================|
  |                        HTTP 200 OK     |
  |                        End Stream: False|
  |                                         |
  |                       5. Send Message  |
  |<========================================|
  |                [Protobuf response data] |
  |                                         |
  |                       6. Send Trailer  |
  |<========================================|
  |                    grpc-status: 0      |
  |                    End Stream: True    |
  |                                         |
```

### Implementation Details
```go
// Client-side operations (conceptual)
func (c *client) UnaryCall(ctx context.Context, req *Request) (*Response, error) {
    // 1. Send Header: Establish RPC endpoint
    // 2. Send Message: Marshal and send request
    // 3. Send Half-Close: Signal client done
    
    // Receive server operations:
    // 4. Receive Header: Server ready to respond
    // 5. Receive Message: Unmarshal response
    // 6. Receive Trailer: Check status and metadata
    
    return response, nil
}
```

### Sequential Learning Notes
These four operations form the building blocks for all RPC types. Understanding this flow is essential before learning how operations are combined differently in streaming patterns.

## Diagram 2: Unary RPC Flow

```
Unary RPC Pattern (1 Request → 1 Response)
==========================================

Client                                    Server
  |                                         |
  |  Send Header                           |
  |--------------------------------------->|
  |                                         |
  |  Send Message                          |
  |--------------------------------------->|
  |                                         |
  |  Send Half-Close                       |
  |--------------------------------------->|
  |                                         |
  |                          Send Header   |
  |<---------------------------------------|
  |                                         |
  |                         Send Message   |
  |<---------------------------------------|
  |                                         |
  |                         Send Trailer   |
  |<---------------------------------------|
  |                                         |

Time →
```

### Implementation Details
```go
// Server-side unary handler
func (s *server) UnaryMethod(ctx context.Context, req *pb.Request) (*pb.Response, error) {
    // Server automatically handles:
    // - Send Header (200 OK)
    // - Send Message (response)
    // - Send Trailer (status)
    
    return &pb.Response{Data: processRequest(req)}, nil
}
```

## Diagram 3: Server Streaming RPC Flow

```
Server Streaming Pattern (1 Request → N Responses)
=================================================

Client                                    Server
  |                                         |
  |  Send Header                           |
  |--------------------------------------->|
  |                                         |
  |  Send Message                          |
  |--------------------------------------->|
  |                                         |
  |  Send Half-Close                       |
  |--------------------------------------->|
  |                                         |
  |                          Send Header   |
  |<---------------------------------------|
  |                                         |
  |                         Send Message 1 |
  |<---------------------------------------|
  |                                         |
  |                         Send Message 2 |
  |<---------------------------------------|
  |                                         |
  |                         Send Message N |
  |<---------------------------------------|
  |                                         |
  |                         Send Trailer   |
  |<---------------------------------------|
  |                                         |

Time →
```

### Implementation Details
```go
// Server streaming implementation
func (s *server) ServerStreamingMethod(req *pb.Request, stream pb.Service_ServerStreamingMethodServer) error {
    // Server sends multiple responses
    for i := 0; i < 10; i++ {
        response := &pb.Response{
            Id:   int32(i),
            Data: fmt.Sprintf("Response %d for %s", i, req.Query),
        }
        if err := stream.Send(response); err != nil {
            return err
        }
        time.Sleep(100 * time.Millisecond) // Simulate processing
    }
    return nil // Automatically sends trailer
}
```

## Diagram 4: Client Streaming RPC Flow

```
Client Streaming Pattern (N Requests → 1 Response)
=================================================

Client                                    Server
  |                                         |
  |  Send Header                           |
  |--------------------------------------->|
  |                                         |
  |  Send Message 1                        |
  |--------------------------------------->|
  |                                         |
  |  Send Message 2                        |
  |--------------------------------------->|
  |                                         |
  |  Send Message N                        |
  |--------------------------------------->|
  |                                         |
  |  Send Half-Close                       |
  |--------------------------------------->|
  |                                         |
  |                          Send Header   |
  |<---------------------------------------|
  |                                         |
  |                         Send Message   |
  |<---------------------------------------|
  |                                         |
  |                         Send Trailer   |
  |<---------------------------------------|
  |                                         |

Time →
```

### Implementation Details
```go
// Client streaming implementation
func (s *server) ClientStreamingMethod(stream pb.Service_ClientStreamingMethodServer) error {
    var aggregatedData []string
    
    // Receive all client messages
    for {
        req, err := stream.Recv()
        if err == io.EOF {
            // Client sent Half-Close, time to respond
            result := strings.Join(aggregatedData, ", ")
            return stream.SendAndClose(&pb.Response{
                Data: fmt.Sprintf("Processed: %s", result),
            })
        }
        if err != nil {
            return err
        }
        aggregatedData = append(aggregatedData, req.Data)
    }
}
```

## Diagram 5: Bidirectional Streaming RPC Flow

```
Bidirectional Streaming Pattern (N Requests ↔ M Responses)
=========================================================

Client                                    Server
  |                                         |
  |  Send Header                           |
  |--------------------------------------->|
  |                                         |
  |  Send Message 1                        |
  |--------------------------------------->|
  |                          Send Header   |
  |<---------------------------------------|
  |                                         |
  |                         Send Message 1 |
  |<---------------------------------------|
  |  Send Message 2                        |
  |--------------------------------------->|
  |                                         |
  |  Send Message 3                        |
  |--------------------------------------->|
  |                         Send Message 2 |
  |<---------------------------------------|
  |                                         |
  |  Send Half-Close                       |
  |--------------------------------------->|
  |                         Send Message 3 |
  |<---------------------------------------|
  |                                         |
  |                         Send Trailer   |
  |<---------------------------------------|
  |                                         |

Time →
Note: Message timing is application-dependent
```

### Implementation Details
```go
// Bidirectional streaming - chat example
func (s *server) BidirectionalMethod(stream pb.Service_BidirectionalMethodServer) error {
    // Handle both sending and receiving concurrently
    go func() {
        // Send periodic server messages
        ticker := time.NewTicker(2 * time.Second)
        defer ticker.Stop()
        
        for range ticker.C {
            serverMsg := &pb.Response{
                Data: fmt.Sprintf("Server update at %v", time.Now()),
            }
            if err := stream.Send(serverMsg); err != nil {
                return
            }
        }
    }()
    
    // Receive client messages
    for {
        req, err := stream.Recv()
        if err == io.EOF {
            return nil // Client sent Half-Close
        }
        if err != nil {
            return err
        }
        
        // Process and potentially respond immediately
        if req.Data == "urgent" {
            stream.Send(&pb.Response{Data: "Urgent response"})
        }
    }
}
```

## Diagram 6: gRPC Connection Lifecycle

```
gRPC Connection Establishment Flow
=================================

User Code              gRPC Framework           Network Layer
    |                        |                       |
    | grpc.Dial(target)     |                       |
    |---------------------->|                       |
    |                        |                       |
    |                        | Parse URI             |
    |                        | Create Resolver       |
    |                        |                       |
    |                        | Resolve Hostname      |
    |                        |---------------------->|
    |                        |   IP Addresses        |
    |                        |<----------------------|
    |                        |                       |
    |                        | Create Load Balancer  |
    |                        | Select Addresses      |
    |                        |                       |
    |                        | Create Channel        |
    |                        | Create Subchannels    |
    |                        |                       |
    | ClientConn            |                       |
    |<----------------------|                       |
    |                        |                       |
    | client.Method()       |                       |
    |---------------------->|                       |
    |                        | NewStream             |
    |                        | Get Subchannel        |
    |                        | Create Transport      |
    |                        |                       |
    |                        | TCP Connection        |
    |                        |---------------------->|
    |                        |   Connected           |
    |                        |<----------------------|
    |                        |                       |
    | Response              |                       |
    |<----------------------|                       |
```

### Implementation Details
```go
// Connection lifecycle components
type connectionFlow struct {
    resolver     naming.Resolver      // DNS resolution
    loadBalancer balancer.Balancer   // Address selection
    channel      *ClientConn         // User abstraction
    subchannels  []*SubConn          // LB abstractions
}

func establishConnection(target string) (*grpc.ClientConn, error) {
    // 1. Parse target URI (dns:///service.example.com:50051)
    parsedTarget := parseTarget(target)
    
    // 2. Create resolver based on scheme
    resolver := createResolver(parsedTarget.Scheme)
    
    // 3. Resolve addresses
    addrs, err := resolver.Resolve(parsedTarget.Endpoint)
    
    // 4. Create load balancer and subchannels
    lb := createLoadBalancer("pick_first") // or "round_robin"
    subconns := createSubchannels(addrs)
    
    // 5. Return channel (non-blocking)
    return &grpc.ClientConn{
        target:    target,
        resolver:  resolver,
        balancer:  lb,
        subConns:  subconns,
    }, nil
}
```

## Diagram 7: RPC Lifecycle - Data Flow

```
RPC Data Flow Through gRPC Layers
=================================

User Code Layer        gRPC Framework Layer      Transport Layer
      |                        |                       |
      | Call Method           |                       |
      |---------------------->|                       |
      |                        | SendMsg               |
      |                        |---------------------->|
      |                        |                       | Write to
      |                        |                       | io.Writer
      |                        |                       |------>
      |                        |                       |
      |                        |                       | Read from
      |                        |                       | io.Reader
      |                        |                       |<------
      |                        | RcvMsg                |
      |                        |<----------------------|
      | Response              |                       |
      |<----------------------|                       |
      |                        |                       |

Generated Code         ClientStream/             ClientTransport/
(Protocol Buffers)     ServerStream              ServerTransport
                      (Abstraction)              (Network I/O)
```

### Implementation Details
```go
// Data flow representation
type rpcDataFlow struct {
    userCode    UserService           // Business logic
    generated   ServiceClient         // Generated protobuf code
    framework   ClientStream          // gRPC abstraction
    transport   ClientTransport       // Network transport
}

// Example of data flowing through layers
func (c *serviceClient) UnaryCall(ctx context.Context, req *Request) (*Response, error) {
    // User code → Generated code
    
    // Generated code → Framework
    stream, err := c.cc.NewStream(ctx, &desc, "/service/UnaryCall")
    if err != nil {
        return nil, err
    }
    
    // Framework → Transport (SendMsg)
    if err := stream.SendMsg(req); err != nil {
        return nil, err
    }
    
    // Transport → Framework (RcvMsg)
    var resp Response
    if err := stream.RecvMsg(&resp); err != nil {
        return nil, err
    }
    
    // Framework → Generated code → User code
    return &resp, nil
}
```

## Diagram 8: HTTP/2 Multiplexing in gRPC

```
HTTP/2 Stream Multiplexing for Concurrent gRPC Calls
===================================================

Single TCP Connection
        |
        |
┌───────▼────────────────────────────────────────────┐
│              HTTP/2 Connection                     │
├────────────────────────────────────────────────────┤
│ Stream 1 (RPC Call 1)  │ Stream 3 (RPC Call 2)    │
│ ┌─────────┬─────────┐  │ ┌─────────┬─────────┐     │
│ │ HEADERS │  DATA   │  │ │ HEADERS │  DATA   │     │
│ │ Frame   │ Frame   │  │ │ Frame   │ Frame   │     │
│ └─────────┴─────────┘  │ └─────────┴─────────┘     │
├────────────────────────┼────────────────────────────┤
│ Stream 5 (RPC Call 3)  │ Stream 7 (RPC Call 4)    │
│ ┌─────────┬─────────┐  │ ┌─────────┬─────────┐     │
│ │ HEADERS │  DATA   │  │ │ HEADERS │  DATA   │     │
│ │ Frame   │ Frame   │  │ │ Frame   │ Frame   │     │
│ └─────────┴─────────┘  │ └─────────┴─────────┘     │
└────────────────────────────────────────────────────┘
        |
        ▼
   Network Wire

Frame Interleaving on Wire:
Stream 1 HEADERS → Stream 3 HEADERS → Stream 1 DATA → 
Stream 5 HEADERS → Stream 3 DATA → Stream 7 HEADERS → ...
```

### Implementation Details
```go
// Concurrent RPC calls over single connection
func concurrentRPCs(client pb.ServiceClient) {
    var wg sync.WaitGroup
    
    // All these RPCs share the same TCP connection
    // but get separate HTTP/2 stream IDs
    for i := 0; i < 4; i++ {
        wg.Add(1)
        go func(callID int) {
            defer wg.Done()
            
            // Each call gets unique stream ID: 1, 3, 5, 7...
            ctx := context.WithValue(context.Background(), "call_id", callID)
            response, err := client.UnaryCall(ctx, &pb.Request{
                Id: int32(callID),
                Data: fmt.Sprintf("Request from call %d", callID),
            })
            
            if err != nil {
                log.Printf("Call %d failed: %v", callID, err)
                return
            }
            
            log.Printf("Call %d response: %s", callID, response.Data)
        }(i)
    }
    
    wg.Wait()
    // All 4 RPCs completed concurrently over single connection
}
```

### Key Decision Points
- **Stream ID Assignment**: gRPC automatically assigns odd stream IDs (1, 3, 5...) for client-initiated streams
- **Frame Interleaving**: HTTP/2 can interleave frames from different streams, preventing head-of-line blocking
- **Flow Control**: Each stream has independent flow control, allowing optimal bandwidth utilization
- **Connection Reuse**: Single TCP connection eliminates connection establishment overhead for subsequent RPCs

### Sequential Learning Notes
This multiplexing capability is what makes gRPC significantly more efficient than traditional HTTP/1.1 APIs, preparing developers for understanding advanced topics like backpressure, flow control, and connection management in production environments.
