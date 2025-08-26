# gRPC Topic: Chapter 1 - Networking Primer

## Prerequisites
- Basic understanding of HTTP/1.1 and HTTP/2 protocols
- Familiarity with client-server architecture concepts
- Basic knowledge of TCP connections and networking
- Understanding of binary vs text-based protocols

## Questions

**Q1: Which four RPC operations form the foundation of all gRPC communication patterns?**

```go
// Example gRPC service flow showing operation sequence
func (s *GreetService) Greet(ctx context.Context, req *pb.GreetRequest) (*pb.GreetResponse, error) {
    // What operations happen under the hood here?
    return &pb.GreetResponse{Message: "Hello " + req.Name}, nil
}
```

1. Send Header, Send Message, Send Half-Close, Send Trailer
2. Connect, Authenticate, Transfer, Disconnect
3. Request, Process, Response, Close
4. Initialize, Serialize, Transmit, Finalize

**Q2: In the following Wireshark capture of a gRPC call, what does the "End Stream: False" flag in the Send Header operation indicate?**

```
HyperText Transfer Protocol 2
Stream: HEADERS, Stream ID: 1, Length 67, POST
/greet.GreetService/Greet
Flags: 0x04, End Headers
.... .1.. = End Headers: True
.... ...0 = End Stream: False
```

1. The client will send additional headers after this one
2. The client has not finished sending its request data yet
3. The server must wait before processing the request
4. The HTTP/2 connection will remain open for more streams

**Q3: What is the primary purpose of the Send Half-Close operation in gRPC communication?**

```go
// Client-side streaming example
stream, err := client.ClientStreamingCall(ctx)
for _, data := range inputData {
    stream.Send(data)
}
// What operation happens here?
response, err := stream.CloseAndRecv()
```

1. To terminate the entire RPC connection permanently
2. To signal that one actor is done sending messages while keeping the stream open for the other actor
3. To compress the remaining data before transmission
4. To authenticate the client before allowing further communication

**Q4: In a Server Streaming RPC, which operations does the client perform?**

```go
// Server streaming call
stream, err := client.ServerStreamingCall(ctx, request)
for {
    response, err := stream.Recv()
    if err == io.EOF {
        break
    }
    // Process response
}
```

1. Send Header, Send Message, Send Trailer
2. Send Header, Send Message, Send Half-Close
3. Send Header, Send Half-Close, Send Trailer
4. Send Message, Send Half-Close, Send Trailer

**Q5: What distinguishes a Bidirectional Streaming RPC from other RPC types in terms of message flow predictability?**

```go
// Bidirectional streaming
stream, err := client.BidirectionalStreamingCall(ctx)
go func() {
    for _, req := range requests {
        stream.Send(req)
    }
    stream.CloseSend()
}()
for {
    resp, err := stream.Recv()
    if err == io.EOF {
        break
    }
    // Process response
}
```

1. It always maintains a 1:1 request-response ratio
2. The server must respond to each client message immediately
3. There is no defined order for when each actor sends messages
4. It requires authentication before each message exchange

**Q6: In the gRPC connection lifecycle, what is the role of the Resolver component?**

```go
// Client connection setup
conn, err := grpc.Dial("dns:///service.example.com:50051", 
    grpc.WithTransportCredentials(insecure.NewCredentials()))
```

1. To parse the target address and return a list of IP addresses that can be connected to
2. To establish the actual TCP connection to the server
3. To handle load balancing between multiple server instances
4. To manage the HTTP/2 stream multiplexing

**Q7: What is the default behavior of grpc.Dial() regarding connection establishment?**

```go
conn, err := grpc.Dial(target, opts...)
if err != nil {
    log.Fatal(err)
}
// Can we immediately make RPC calls here?
client := pb.NewGreetServiceClient(conn)
```

1. It blocks until a connection is established and verified
2. It returns immediately without waiting for connection establishment (non-blocking)
3. It establishes connections only when the first RPC is made
4. It requires manual connection confirmation before use

**Q8: In the client-side RPC lifecycle, what does the NewStream function create regardless of whether it's a streaming or unary RPC?**

```go
// Both calls internally use NewStream
// Unary call
response, err := client.UnaryCall(ctx, request)

// Streaming call  
stream, err := client.StreamingCall(ctx)
```

1. A new HTTP/2 stream for each RPC call
2. A ClientStream object that abstracts all RPC types
3. A direct TCP connection to the server
4. A new goroutine for handling the RPC

**Q9: What is the difference between a Channel and a Subchannel in gRPC Go?**

```go
// This creates a channel
conn, err := grpc.Dial(target)

// Internally, subchannels are managed by the load balancer
// Which abstraction does the user code interact with?
```

1. Channel is for client connections, Subchannel is for server connections
2. Channel abstracts connections for RPCs, Subchannel abstracts connections for load balancers
3. Channel handles streaming RPCs, Subchannel handles unary RPCs
4. They are identical abstractions with different names

**Q10: In a Unary RPC flow, what information does the Send Trailer operation contain?**

```go
// Server-side unary handler
func (s *server) UnaryCall(ctx context.Context, req *pb.Request) (*pb.Response, error) {
    // Process request
    if someError {
        return nil, status.Errorf(codes.InvalidArgument, "error message")
    }
    return &pb.Response{}, nil
    // What gets sent in the trailer?
}
```

1. The actual response data and payload
2. Authentication tokens and session information
3. Status code, error message, and optional metadata key-value pairs
4. Compression settings and encoding information

**Q11: Which RPC type is most suitable for a real-time chat application where both users can send and receive messages simultaneously?**

```go
// Chat service implementation
service ChatService {
    rpc Chat(stream ChatMessage) returns (stream ChatMessage);
}

// What RPC type is this?
```

1. Unary RPC
2. Server Streaming RPC
3. Client Streaming RPC
4. Bidirectional Streaming RPC

**Q12: In the HTTP/2 frame analysis shown in the book, what does the "grpc-status: 0" header in the Send Trailer indicate?**

```
Header: grpc-status: 0
Header: grpc-message:
```

1. The RPC call was successful (OK status)
2. The connection will be closed after this message
3. No more messages will be sent
4. The client should retry the request

**Q13: What happens in the server-side RPC lifecycle when ServerTransport receives a header from a client?**

```go
// Server setup
s := grpc.NewServer()
pb.RegisterGreetServiceServer(s, &server{})
// When client sends header, what's the flow?
```

1. It immediately calls the user-defined RPC handler function
2. It creates a ServerStream object and passes it to generated code
3. It sends back an acknowledgment header to the client
4. It establishes a new TCP connection for the RPC

**Q14: In Client Streaming RPC, when does the server send its response?**

```go
// Client streaming implementation
func (s *server) ClientStreaming(stream pb.Service_ClientStreamingServer) error {
    var aggregatedData Data
    for {
        req, err := stream.Recv()
        if err == io.EOF {
            // When does the server respond?
            return stream.SendAndClose(&pb.Response{Result: aggregatedData})
        }
        // Process req
        aggregatedData = process(req)
    }
}
```

1. After receiving each client message
2. Only after the client sends Send Half-Close
3. At regular time intervals
4. When the client explicitly requests a response

**Q15: What is the main advantage of HTTP/2's multiplexing capability that gRPC leverages?**

```go
// Multiple concurrent RPC calls
go client.Call1(ctx, req1)
go client.Call2(ctx, req2) 
go client.Call3(ctx, req3)
// How does this benefit from HTTP/2?
```

1. It reduces the total bandwidth required for communication
2. It allows multiple requests and responses to be interleaved over a single TCP connection
3. It automatically compresses all data before transmission
4. It provides built-in authentication and encryption
