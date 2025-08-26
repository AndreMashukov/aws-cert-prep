# gRPC Topic: Chapter 1 - Networking Primer - Code Examples

## Complete Implementation Examples

This document provides complete, working Go code examples that demonstrate the key concepts from Chapter 1, including RPC operations, RPC types, and the lifecycle of an RPC. All examples are production-ready and can be executed to understand gRPC behavior.

### Example 1: Unary RPC Implementation

```go
// File: proto/greet.proto
syntax = "proto3";

package greet;
option go_package = "example/greet";

service GreetService {
    rpc Greet(GreetRequest) returns (GreetResponse);
}

message GreetRequest {
    string name = 1;
}

message GreetResponse {
    string message = 1;
    int64 timestamp = 2;
}
```

```go
// File: server/main.go
package main

import (
    "context"
    "fmt"
    "log"
    "net"
    "time"

    "google.golang.org/grpc"
    pb "example/greet"
)

// Server implements the GreetService
type server struct {
    pb.UnimplementedGreetServiceServer
}

// Greet implements the unary RPC method
func (s *server) Greet(ctx context.Context, req *pb.GreetRequest) (*pb.GreetResponse, error) {
    log.Printf("Received unary request: name=%s", req.Name)
    
    // Simulate processing time
    time.Sleep(100 * time.Millisecond)
    
    response := &pb.GreetResponse{
        Message:   fmt.Sprintf("Hello %s! Welcome to gRPC.", req.Name),
        Timestamp: time.Now().Unix(),
    }
    
    log.Printf("Sending unary response: %s", response.Message)
    return response, nil
}

func main() {
    // Listen on port 50051
    lis, err := net.Listen("tcp", ":50051")
    if err != nil {
        log.Fatalf("Failed to listen: %v", err)
    }

    // Create gRPC server
    s := grpc.NewServer()
    
    // Register our service
    pb.RegisterGreetServiceServer(s, &server{})
    
    log.Println("gRPC server listening on :50051")
    log.Println("RPC Operations: Send Header → Send Message → Send Trailer")
    
    if err := s.Serve(lis); err != nil {
        log.Fatalf("Failed to serve: %v", err)
    }
}
```

```go
// File: client/main.go
package main

import (
    "context"
    "log"
    "time"

    "google.golang.org/grpc"
    "google.golang.org/grpc/credentials/insecure"
    pb "example/greet"
)

func main() {
    // Connect to server (non-blocking)
    conn, err := grpc.Dial("localhost:50051", 
        grpc.WithTransportCredentials(insecure.NewCredentials()))
    if err != nil {
        log.Fatalf("Failed to connect: %v", err)
    }
    defer conn.Close()

    // Create client
    client := pb.NewGreetServiceClient(conn)

    // Make unary RPC call
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()

    log.Println("Making unary RPC call...")
    log.Println("Client Operations: Send Header → Send Message → Send Half-Close")

    response, err := client.Greet(ctx, &pb.GreetRequest{
        Name: "World",
    })
    if err != nil {
        log.Fatalf("RPC failed: %v", err)
    }

    log.Printf("Response: %s (timestamp: %d)", response.Message, response.Timestamp)
}
```

**Explanation:** This example demonstrates the basic unary RPC pattern where the client sends one request and receives one response. The four RPC operations (Send Header, Send Message, Send Half-Close, Send Trailer) happen automatically.

**Sequential Dependencies:** This is the foundation pattern that must be understood before moving to streaming patterns.

### Example 2: Server Streaming RPC

```go
// File: proto/stream.proto
syntax = "proto3";

package stream;
option go_package = "example/stream";

service StreamService {
    rpc ServerStreaming(StreamRequest) returns (stream StreamResponse);
}

message StreamRequest {
    string query = 1;
    int32 count = 2;
}

message StreamResponse {
    string data = 1;
    int32 sequence = 2;
    int64 timestamp = 3;
}
```

```go
// File: server/stream_server.go
package main

import (
    "fmt"
    "log"
    "net"
    "time"

    "google.golang.org/grpc"
    pb "example/stream"
)

type streamServer struct {
    pb.UnimplementedStreamServiceServer
}

// ServerStreaming implements server streaming RPC
func (s *streamServer) ServerStreaming(req *pb.StreamRequest, stream pb.StreamService_ServerStreamingServer) error {
    log.Printf("Received streaming request: query=%s, count=%d", req.Query, req.Count)
    
    // Server sends multiple responses
    for i := int32(0); i < req.Count; i++ {
        response := &pb.StreamResponse{
            Data:      fmt.Sprintf("Response %d for query '%s'", i+1, req.Query),
            Sequence:  i + 1,
            Timestamp: time.Now().Unix(),
        }
        
        log.Printf("Sending stream response %d/%d", i+1, req.Count)
        
        if err := stream.Send(response); err != nil {
            log.Printf("Error sending response: %v", err)
            return err
        }
        
        // Simulate processing time between responses
        time.Sleep(500 * time.Millisecond)
    }
    
    log.Println("Server streaming completed")
    return nil // Automatically sends trailer
}

func main() {
    lis, err := net.Listen("tcp", ":50052")
    if err != nil {
        log.Fatalf("Failed to listen: %v", err)
    }

    s := grpc.NewServer()
    pb.RegisterStreamServiceServer(s, &streamServer{})
    
    log.Println("Server streaming service listening on :50052")
    log.Println("Pattern: Client(Header→Message→Half-Close) Server(Header→Message*N→Trailer)")
    
    if err := s.Serve(lis); err != nil {
        log.Fatalf("Failed to serve: %v", err)
    }
}
```

```go
// File: client/stream_client.go
package main

import (
    "context"
    "io"
    "log"
    "time"

    "google.golang.org/grpc"
    "google.golang.org/grpc/credentials/insecure"
    pb "example/stream"
)

func main() {
    conn, err := grpc.Dial("localhost:50052", 
        grpc.WithTransportCredentials(insecure.NewCredentials()))
    if err != nil {
        log.Fatalf("Failed to connect: %v", err)
    }
    defer conn.Close()

    client := pb.NewStreamServiceClient(conn)

    ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
    defer cancel()

    log.Println("Starting server streaming RPC...")
    
    // Initiate server streaming call
    stream, err := client.ServerStreaming(ctx, &pb.StreamRequest{
        Query: "weather",
        Count: 5,
    })
    if err != nil {
        log.Fatalf("Failed to start stream: %v", err)
    }

    log.Println("Receiving streaming responses...")
    
    // Receive multiple responses
    for {
        response, err := stream.Recv()
        if err == io.EOF {
            log.Println("Server finished streaming (received trailer)")
            break
        }
        if err != nil {
            log.Fatalf("Error receiving response: %v", err)
        }
        
        log.Printf("Received: %s (seq: %d, time: %d)", 
            response.Data, response.Sequence, response.Timestamp)
    }
    
    log.Println("Client streaming completed")
}
```

**Explanation:** Server streaming allows the server to send multiple responses for a single client request. This is useful for scenarios like real-time updates, file downloads, or data feeds.

**Sequential Dependencies:** Builds on unary RPC understanding and introduces the concept of multiple Send Message operations from the server.

### Example 3: Client Streaming RPC

```go
// File: proto/upload.proto
syntax = "proto3";

package upload;
option go_package = "example/upload";

service UploadService {
    rpc ClientStreaming(stream UploadChunk) returns (UploadResponse);
}

message UploadChunk {
    bytes data = 1;
    string filename = 2;
    int32 sequence = 3;
}

message UploadResponse {
    string message = 1;
    int64 total_bytes = 2;
    int32 total_chunks = 3;
}
```

```go
// File: server/upload_server.go
package main

import (
    "io"
    "log"
    "net"

    "google.golang.org/grpc"
    pb "example/upload"
)

type uploadServer struct {
    pb.UnimplementedUploadServiceServer
}

// ClientStreaming handles client streaming upload
func (s *uploadServer) ClientStreaming(stream pb.UploadService_ClientStreamingServer) error {
    var totalBytes int64
    var totalChunks int32
    var filename string
    
    log.Println("Starting client streaming RPC...")
    
    // Receive all chunks from client
    for {
        chunk, err := stream.Recv()
        if err == io.EOF {
            // Client sent Half-Close, time to respond
            log.Printf("Client finished sending. Total: %d bytes in %d chunks", 
                totalBytes, totalChunks)
            
            response := &pb.UploadResponse{
                Message:     "Upload completed successfully",
                TotalBytes:  totalBytes,
                TotalChunks: totalChunks,
            }
            
            // Send single response and close
            return stream.SendAndClose(response)
        }
        if err != nil {
            log.Printf("Error receiving chunk: %v", err)
            return err
        }
        
        // Process chunk
        totalBytes += int64(len(chunk.Data))
        totalChunks++
        filename = chunk.Filename
        
        log.Printf("Received chunk %d: %d bytes (total: %d bytes)", 
            chunk.Sequence, len(chunk.Data), totalBytes)
    }
}

func main() {
    lis, err := net.Listen("tcp", ":50053")
    if err != nil {
        log.Fatalf("Failed to listen: %v", err)
    }

    s := grpc.NewServer()
    pb.RegisterUploadServiceServer(s, &uploadServer{})
    
    log.Println("Client streaming service listening on :50053")
    log.Println("Pattern: Client(Header→Message*N→Half-Close) Server(Header→Message→Trailer)")
    
    if err := s.Serve(lis); err != nil {
        log.Fatalf("Failed to serve: %v", err)
    }
}
```

```go
// File: client/upload_client.go
package main

import (
    "context"
    "log"
    "time"

    "google.golang.org/grpc"
    "google.golang.org/grpc/credentials/insecure"
    pb "example/upload"
)

func main() {
    conn, err := grpc.Dial("localhost:50053", 
        grpc.WithTransportCredentials(insecure.NewCredentials()))
    if err != nil {
        log.Fatalf("Failed to connect: %v", err)
    }
    defer conn.Close()

    client := pb.NewUploadServiceClient(conn)

    ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
    defer cancel()

    log.Println("Starting client streaming RPC...")
    
    // Start streaming call
    stream, err := client.ClientStreaming(ctx)
    if err != nil {
        log.Fatalf("Failed to start stream: %v", err)
    }

    // Simulate file chunks
    chunks := [][]byte{
        []byte("Hello, "),
        []byte("this is "),
        []byte("a streaming "),
        []byte("upload test!"),
    }

    log.Println("Sending file chunks...")
    
    // Send multiple chunks
    for i, chunkData := range chunks {
        chunk := &pb.UploadChunk{
            Data:     chunkData,
            Filename: "test.txt",
            Sequence: int32(i + 1),
        }
        
        log.Printf("Sending chunk %d: %d bytes", i+1, len(chunkData))
        
        if err := stream.Send(chunk); err != nil {
            log.Fatalf("Error sending chunk: %v", err)
        }
        
        time.Sleep(100 * time.Millisecond) // Simulate network delay
    }

    log.Println("Closing client stream and waiting for response...")
    
    // Close client stream and receive response
    response, err := stream.CloseAndRecv()
    if err != nil {
        log.Fatalf("Error closing stream: %v", err)
    }

    log.Printf("Upload result: %s", response.Message)
    log.Printf("Server received: %d bytes in %d chunks", 
        response.TotalBytes, response.TotalChunks)
}
```

**Explanation:** Client streaming allows the client to send multiple requests and receive a single response. This is useful for file uploads, batch data submission, or aggregation scenarios.

**Sequential Dependencies:** Combines understanding of multiple Send Message operations (from server streaming) with the Half-Close operation that triggers server response.

### Example 4: Bidirectional Streaming RPC

```go
// File: proto/chat.proto
syntax = "proto3";

package chat;
option go_package = "example/chat";

service ChatService {
    rpc Chat(stream ChatMessage) returns (stream ChatMessage);
}

message ChatMessage {
    string user = 1;
    string text = 2;
    int64 timestamp = 3;
    string message_id = 4;
}
```

```go
// File: server/chat_server.go
package main

import (
    "fmt"
    "io"
    "log"
    "net"
    "sync"
    "time"

    "github.com/google/uuid"
    "google.golang.org/grpc"
    pb "example/chat"
)

type chatServer struct {
    pb.UnimplementedChatServiceServer
    clients sync.Map // map[stream]bool
}

// Chat implements bidirectional streaming
func (s *chatServer) Chat(stream pb.ChatService_ChatServer) error {
    // Register client
    s.clients.Store(stream, true)
    defer s.clients.Delete(stream)
    
    log.Println("New client connected to chat")
    
    // Send welcome message
    welcome := &pb.ChatMessage{
        User:      "System",
        Text:      "Welcome to the chat!",
        Timestamp: time.Now().Unix(),
        MessageId: uuid.New().String(),
    }
    stream.Send(welcome)
    
    // Handle incoming messages
    for {
        msg, err := stream.Recv()
        if err == io.EOF {
            log.Println("Client disconnected from chat")
            return nil
        }
        if err != nil {
            log.Printf("Error receiving message: %v", err)
            return err
        }
        
        log.Printf("Chat message from %s: %s", msg.User, msg.Text)
        
        // Broadcast to all connected clients
        s.broadcast(msg)
        
        // Send acknowledgment
        ack := &pb.ChatMessage{
            User:      "System",
            Text:      fmt.Sprintf("Message received from %s", msg.User),
            Timestamp: time.Now().Unix(),
            MessageId: uuid.New().String(),
        }
        
        if err := stream.Send(ack); err != nil {
            log.Printf("Error sending acknowledgment: %v", err)
            return err
        }
    }
}

func (s *chatServer) broadcast(msg *pb.ChatMessage) {
    s.clients.Range(func(key, value interface{}) bool {
        stream := key.(pb.ChatService_ChatServer)
        
        // Create broadcast message
        broadcast := &pb.ChatMessage{
            User:      msg.User,
            Text:      fmt.Sprintf("[BROADCAST] %s", msg.Text),
            Timestamp: time.Now().Unix(),
            MessageId: uuid.New().String(),
        }
        
        if err := stream.Send(broadcast); err != nil {
            log.Printf("Error broadcasting to client: %v", err)
            s.clients.Delete(stream)
        }
        return true
    })
}

func main() {
    lis, err := net.Listen("tcp", ":50054")
    if err != nil {
        log.Fatalf("Failed to listen: %v", err)
    }

    s := grpc.NewServer()
    pb.RegisterChatServiceServer(s, &chatServer{})
    
    log.Println("Chat service listening on :50054")
    log.Println("Pattern: Client(Header→Message*N→Half-Close) Server(Header→Message*M→Trailer)")
    log.Println("Both can send messages at any time (unpredictable flow)")
    
    if err := s.Serve(lis); err != nil {
        log.Fatalf("Failed to serve: %v", err)
    }
}
```

```go
// File: client/chat_client.go
package main

import (
    "bufio"
    "context"
    "io"
    "log"
    "os"
    "strings"
    "time"

    "github.com/google/uuid"
    "google.golang.org/grpc"
    "google.golang.org/grpc/credentials/insecure"
    pb "example/chat"
)

func main() {
    conn, err := grpc.Dial("localhost:50054", 
        grpc.WithTransportCredentials(insecure.NewCredentials()))
    if err != nil {
        log.Fatalf("Failed to connect: %v", err)
    }
    defer conn.Close()

    client := pb.NewChatServiceClient(conn)

    ctx, cancel := context.WithCancel(context.Background())
    defer cancel()

    log.Println("Starting bidirectional streaming chat...")
    
    // Start chat stream
    stream, err := client.Chat(ctx)
    if err != nil {
        log.Fatalf("Failed to start chat: %v", err)
    }

    // Goroutine to receive messages
    go func() {
        for {
            msg, err := stream.Recv()
            if err == io.EOF {
                log.Println("Server closed the chat")
                return
            }
            if err != nil {
                log.Printf("Error receiving message: %v", err)
                return
            }
            
            log.Printf("[%s] %s (ID: %s, Time: %d)", 
                msg.User, msg.Text, msg.MessageId, msg.Timestamp)
        }
    }()

    // Main thread for sending messages
    log.Println("Chat started! Type messages (or 'quit' to exit):")
    scanner := bufio.NewScanner(os.Stdin)
    
    for scanner.Scan() {
        text := strings.TrimSpace(scanner.Text())
        if text == "quit" {
            break
        }
        if text == "" {
            continue
        }
        
        msg := &pb.ChatMessage{
            User:      "Client",
            Text:      text,
            Timestamp: time.Now().Unix(),
            MessageId: uuid.New().String(),
        }
        
        if err := stream.Send(msg); err != nil {
            log.Printf("Error sending message: %v", err)
            break
        }
    }

    log.Println("Closing chat...")
    stream.CloseSend()
    time.Sleep(1 * time.Second) // Give time for final messages
}
```

**Explanation:** Bidirectional streaming allows both client and server to send multiple messages simultaneously. This demonstrates the most complex RPC pattern with unpredictable message flow.

**Sequential Dependencies:** This is the most advanced pattern, requiring understanding of all previous RPC types and the concept of concurrent message flows.

### Example 5: Connection Lifecycle and Error Handling

```go
// File: examples/lifecycle.go
package main

import (
    "context"
    "log"
    "time"

    "google.golang.org/grpc"
    "google.golang.org/grpc/connectivity"
    "google.golang.org/grpc/credentials/insecure"
    "google.golang.org/grpc/status"
    "google.golang.org/grpc/codes"
)

// ConnectionLifecycleDemo demonstrates the gRPC connection lifecycle
func ConnectionLifecycleDemo() {
    log.Println("=== gRPC Connection Lifecycle Demo ===")
    
    // 1. Non-blocking Dial
    log.Println("1. Calling grpc.Dial() - non-blocking operation")
    conn, err := grpc.Dial("localhost:50051",
        grpc.WithTransportCredentials(insecure.NewCredentials()),
        grpc.WithBlock(),           // Make it blocking for demo
        grpc.WithTimeout(5*time.Second))
    
    if err != nil {
        log.Printf("Failed to connect: %v", err)
        return
    }
    defer conn.Close()
    
    // 2. Check connection state
    state := conn.GetState()
    log.Printf("2. Initial connection state: %v", state)
    
    // 3. Wait for connection to be ready
    log.Println("3. Waiting for connection to be ready...")
    for state != connectivity.Ready {
        if !conn.WaitForStateChange(context.Background(), state) {
            log.Println("Connection state change timeout")
            break
        }
        state = conn.GetState()
        log.Printf("Connection state changed to: %v", state)
    }
    
    // 4. Create client and make call
    log.Println("4. Connection ready, making RPC call...")
    client := pb.NewGreetServiceClient(conn)
    
    response, err := client.Greet(context.Background(), &pb.GreetRequest{
        Name: "Lifecycle Demo",
    })
    
    if err != nil {
        // Demonstrate error handling
        st := status.Convert(err)
        log.Printf("RPC failed - Code: %v, Message: %s", st.Code(), st.Message())
        return
    }
    
    log.Printf("5. RPC succeeded: %s", response.Message)
}

// ErrorHandlingDemo shows how to handle different gRPC errors
func ErrorHandlingDemo() {
    log.Println("\n=== gRPC Error Handling Demo ===")
    
    conn, err := grpc.Dial("localhost:50051",
        grpc.WithTransportCredentials(insecure.NewCredentials()))
    if err != nil {
        log.Fatalf("Failed to connect: %v", err)
    }
    defer conn.Close()

    client := pb.NewGreetServiceClient(conn)
    
    // Test different error scenarios
    testCases := []struct {
        name    string
        request *pb.GreetRequest
        timeout time.Duration
    }{
        {"Valid Request", &pb.GreetRequest{Name: "World"}, 5 * time.Second},
        {"Empty Name", &pb.GreetRequest{Name: ""}, 5 * time.Second},
        {"Timeout Test", &pb.GreetRequest{Name: "Slow"}, 100 * time.Millisecond},
    }
    
    for _, tc := range testCases {
        log.Printf("\nTesting: %s", tc.name)
        
        ctx, cancel := context.WithTimeout(context.Background(), tc.timeout)
        response, err := client.Greet(ctx, tc.request)
        cancel()
        
        if err != nil {
            st := status.Convert(err)
            log.Printf("Error - Code: %v (%s), Message: %s", 
                st.Code(), st.Code().String(), st.Message())
                
            // Handle specific error codes
            switch st.Code() {
            case codes.InvalidArgument:
                log.Println("Client should validate input before sending")
            case codes.DeadlineExceeded:
                log.Println("Request took too long, client should retry or increase timeout")
            case codes.Unavailable:
                log.Println("Server unavailable, client should implement exponential backoff")
            default:
                log.Printf("Unhandled error code: %v", st.Code())
            }
        } else {
            log.Printf("Success: %s", response.Message)
        }
    }
}

// ConcurrentRPCDemo shows HTTP/2 multiplexing benefits
func ConcurrentRPCDemo() {
    log.Println("\n=== Concurrent RPC Demo (HTTP/2 Multiplexing) ===")
    
    conn, err := grpc.Dial("localhost:50051",
        grpc.WithTransportCredentials(insecure.NewCredentials()))
    if err != nil {
        log.Fatalf("Failed to connect: %v", err)
    }
    defer conn.Close()

    client := pb.NewGreetServiceClient(conn)
    
    log.Println("Making 5 concurrent RPC calls over single connection...")
    
    type result struct {
        id       int
        response *pb.GreetResponse
        err      error
        duration time.Duration
    }
    
    results := make(chan result, 5)
    
    // Launch 5 concurrent RPCs
    for i := 0; i < 5; i++ {
        go func(id int) {
            start := time.Now()
            
            response, err := client.Greet(context.Background(), &pb.GreetRequest{
                Name: fmt.Sprintf("Client-%d", id),
            })
            
            results <- result{
                id:       id,
                response: response,
                err:      err,
                duration: time.Since(start),
            }
        }(i)
    }
    
    // Collect results
    for i := 0; i < 5; i++ {
        res := <-results
        if res.err != nil {
            log.Printf("Call %d failed: %v", res.id, res.err)
        } else {
            log.Printf("Call %d completed in %v: %s", 
                res.id, res.duration, res.response.Message)
        }
    }
    
    log.Println("All concurrent RPCs completed over single TCP connection")
}

func main() {
    ConnectionLifecycleDemo()
    ErrorHandlingDemo()
    ConcurrentRPCDemo()
}
```

**Explanation:** This comprehensive example demonstrates the complete gRPC lifecycle, from connection establishment to error handling and concurrent operations. It shows how gRPC leverages HTTP/2 multiplexing for efficient communication.

**Production Considerations:** 
- Connection pooling and reuse
- Proper error handling and retry logic
- Context timeouts and cancellation
- Health checking and circuit breakers
- Observability and monitoring

**Sequential Dependencies:** This example ties together all concepts from Chapter 1, showing how the four RPC operations, different RPC types, and connection lifecycle work together in a production environment.
