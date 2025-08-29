# gRPC Topic: Introduction to gRPC - Code Examples

## Complete Implementation Examples

### Example 1: AccountService Proto Definition and Code Generation

**Proto Definition (account.proto):**
```proto
syntax = "proto3";

option go_package = "github.com/PacktPublishing/gRPC-Go-for-Professionals";

// User account message
message Account {
    uint64 id = 1;
    string username = 2;
}

// Request message for logout operation
message LogoutRequest {
    Account account = 1;
}

// Response message for logout operation (empty response)
message LogoutResponse {}

// AccountService defines the gRPC service
service AccountService {
    rpc Logout(LogoutRequest) returns (LogoutResponse);
}
```

**Code Generation Command:**
```bash
$ protoc --go_out=. \
  --go_opt=module=github.com/PacktPublishing/gRPC-Go-for-Professionals \
  --go-grpc_out=. \
  --go-grpc_opt=module=github.com/PacktPublishing/gRPC-Go-for-Professionals \
  proto/account.proto
```

**Explanation:** This example demonstrates the foundation of gRPC - defining services in Protocol Buffers and generating Go code. The proto file defines the data structures and service interface, while protoc generates both Protobuf message code and gRPC communication code.

**Sequential Dependencies:** Builds on Protobuf knowledge from Chapter 2, adding service definitions for RPC communication.

---

### Example 2: Generated Server-Side Code Structure

**Generated Server Interface (account_grpc.pb.go):**
```go
// AccountServiceServer is the server API for AccountService service.
// All implementations must embed UnimplementedAccountServiceServer
// for forward compatibility
type AccountServiceServer interface {
    Logout(context.Context, *LogoutRequest) (*LogoutResponse, error)
    mustEmbedUnimplementedAccountServiceServer()
}

// UnimplementedAccountServiceServer must be embedded to have forward compatible implementations.
type UnimplementedAccountServiceServer struct {}

func (UnimplementedAccountServiceServer) Logout(context.Context, *LogoutRequest) (*LogoutResponse, error) {
    return nil, status.Errorf(codes.Unimplemented, "method Logout not implemented")
}

func (UnimplementedAccountServiceServer) mustEmbedUnimplementedAccountServiceServer() {}

// Service descriptor containing metadata
var AccountService_ServiceDesc = grpc.ServiceDesc{
    ServiceName: "AccountService",
    HandlerType: (*AccountServiceServer)(nil),
    Methods: []grpc.MethodDesc{
        {
            MethodName: "Logout",
            Handler:    _AccountService_Logout_Handler,
        },
    },
    Streams:  []grpc.StreamDesc{},
    Metadata: "account.proto",
}

// Generated handler function
func _AccountService_Logout_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
    in := new(LogoutRequest)
    if err := dec(in); err != nil {
        return nil, err
    }
    if interceptor == nil {
        return srv.(AccountServiceServer).Logout(ctx, in)
    }
    info := &grpc.UnaryServerInfo{
        Server:     srv,
        FullMethod: "/AccountService/Logout",
    }
    handler := func(ctx context.Context, req interface{}) (interface{}, error) {
        return srv.(AccountServiceServer).Logout(ctx, req.(*LogoutRequest))
    }
    return interceptor(ctx, in, info, handler)
}
```

**User Server Implementation:**
```go
package main

import (
    "context"
    "log"
    "net"

    "google.golang.org/grpc"
)

// Server implements the AccountServiceServer interface
type Server struct {
    // Embed for forward compatibility
    UnimplementedAccountServiceServer
}

// Logout implements the business logic for user logout
func (s *Server) Logout(ctx context.Context, req *LogoutRequest) (*LogoutResponse, error) {
    // Business logic implementation
    log.Printf("User logout: %s (ID: %d)", req.Account.Username, req.Account.Id)
    
    // In a real implementation, you would:
    // - Validate the session
    // - Invalidate user tokens
    // - Log the logout event
    // - Clean up resources
    
    return &LogoutResponse{}, nil
}

func main() {
    // Create gRPC server
    s := grpc.NewServer()
    
    // Register our service implementation
    RegisterAccountServiceServer(s, &Server{})
    
    // Listen on port 50051
    lis, err := net.Listen("tcp", ":50051")
    if err != nil {
        log.Fatalf("Failed to listen: %v", err)
    }
    
    log.Println("AccountService server listening on :50051")
    if err := s.Serve(lis); err != nil {
        log.Fatalf("Failed to serve: %v", err)
    }
}
```

**Explanation:** This example shows how gRPC generates server-side code and how developers implement the business logic. The generated code handles all communication boilerplate, while user code focuses on business logic.

**Production Considerations:** The UnimplementedAccountServiceServer embedding ensures forward compatibility when new methods are added to the service.

---

### Example 3: Generated Client-Side Code and Usage

**Generated Client Interface (account_grpc.pb.go):**
```go
// AccountServiceClient is the client API for AccountService service.
type AccountServiceClient interface {
    Logout(ctx context.Context, in *LogoutRequest, opts ...grpc.CallOption) (*LogoutResponse, error)
}

type accountServiceClient struct {
    cc grpc.ClientConnInterface
}

func NewAccountServiceClient(cc grpc.ClientConnInterface) AccountServiceClient {
    return &accountServiceClient{cc}
}

func (c *accountServiceClient) Logout(ctx context.Context, in *LogoutRequest, opts ...grpc.CallOption) (*LogoutResponse, error) {
    out := new(LogoutResponse)
    err := c.cc.Invoke(ctx, "/AccountService/Logout", in, out, opts...)
    if err != nil {
        return nil, err
    }
    return out, nil
}
```

**Client Implementation:**
```go
package main

import (
    "context"
    "log"
    "time"

    "google.golang.org/grpc"
    "google.golang.org/grpc/credentials/insecure"
)

func main() {
    // Connect to the gRPC server
    conn, err := grpc.Dial("localhost:50051", grpc.WithTransportCredentials(insecure.NewCredentials()))
    if err != nil {
        log.Fatalf("Failed to connect: %v", err)
    }
    defer conn.Close()

    // Create client
    client := NewAccountServiceClient(conn)

    // Prepare request
    req := &LogoutRequest{
        Account: &Account{
            Id:       123,
            Username: "john_doe",
        },
    }

    // Make the call with timeout
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()

    // Call the Logout method
    resp, err := client.Logout(ctx, req)
    if err != nil {
        log.Fatalf("Logout failed: %v", err)
    }

    log.Printf("Logout successful: %+v", resp)
}
```

**Advanced Client with Error Handling:**
```go
package main

import (
    "context"
    "log"
    "time"

    "google.golang.org/grpc"
    "google.golang.org/grpc/codes"
    "google.golang.org/grpc/credentials/insecure"
    "google.golang.org/grpc/status"
)

type AccountClient struct {
    client AccountServiceClient
    conn   *grpc.ClientConn
}

func NewAccountClient(address string) (*AccountClient, error) {
    conn, err := grpc.Dial(address, grpc.WithTransportCredentials(insecure.NewCredentials()))
    if err != nil {
        return nil, err
    }
    
    return &AccountClient{
        client: NewAccountServiceClient(conn),
        conn:   conn,
    }, nil
}

func (ac *AccountClient) Close() error {
    return ac.conn.Close()
}

func (ac *AccountClient) Logout(userID uint64, username string) error {
    ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
    defer cancel()

    req := &LogoutRequest{
        Account: &Account{
            Id:       userID,
            Username: username,
        },
    }

    _, err := ac.client.Logout(ctx, req)
    if err != nil {
        // Handle gRPC errors
        if st, ok := status.FromError(err); ok {
            switch st.Code() {
            case codes.Unimplemented:
                return fmt.Errorf("logout not supported by server: %v", st.Message())
            case codes.InvalidArgument:
                return fmt.Errorf("invalid logout request: %v", st.Message())
            case codes.DeadlineExceeded:
                return fmt.Errorf("logout request timed out")
            default:
                return fmt.Errorf("logout failed: %v", st.Message())
            }
        }
        return fmt.Errorf("unexpected error: %v", err)
    }

    return nil
}

func main() {
    client, err := NewAccountClient("localhost:50051")
    if err != nil {
        log.Fatalf("Failed to create client: %v", err)
    }
    defer client.Close()

    // Use the client
    if err := client.Logout(123, "john_doe"); err != nil {
        log.Fatalf("Logout failed: %v", err)
    }

    log.Println("Logout completed successfully")
}
```

**Explanation:** This example demonstrates client-side usage, showing both basic and advanced patterns with proper error handling. The generated client code abstracts all HTTP/2 communication details.

**Sequential Dependencies:** Uses the gRPC connection and communication patterns, building on the protocol understanding from Chapter 1.

---

### Example 4: Complete Service with Multiple Methods

**Enhanced Proto Definition (enhanced_account.proto):**
```proto
syntax = "proto3";

option go_package = "github.com/example/enhanced-account";

message Account {
    uint64 id = 1;
    string username = 2;
    string email = 3;
    int64 created_at = 4;
}

message LoginRequest {
    string username = 1;
    string password = 2;
}

message LoginResponse {
    Account account = 1;
    string session_token = 2;
}

message LogoutRequest {
    string session_token = 1;
}

message LogoutResponse {
    bool success = 1;
}

message GetAccountRequest {
    uint64 account_id = 1;
}

message GetAccountResponse {
    Account account = 1;
}

service EnhancedAccountService {
    rpc Login(LoginRequest) returns (LoginResponse);
    rpc Logout(LogoutRequest) returns (LogoutResponse);
    rpc GetAccount(GetAccountRequest) returns (GetAccountResponse);
}
```

**Complete Server Implementation:**
```go
package main

import (
    "context"
    "fmt"
    "log"
    "net"
    "sync"
    "time"

    "google.golang.org/grpc"
    "google.golang.org/grpc/codes"
    "google.golang.org/grpc/status"
)

// EnhancedServer implements EnhancedAccountServiceServer
type EnhancedServer struct {
    UnimplementedEnhancedAccountServiceServer
    
    // In-memory storage for demo
    accounts map[uint64]*Account
    sessions map[string]*Account
    mu       sync.RWMutex
}

func NewEnhancedServer() *EnhancedServer {
    return &EnhancedServer{
        accounts: make(map[uint64]*Account),
        sessions: make(map[string]*Account),
    }
}

func (s *EnhancedServer) Login(ctx context.Context, req *LoginRequest) (*LoginResponse, error) {
    log.Printf("Login attempt for user: %s", req.Username)
    
    // Validate input
    if req.Username == "" || req.Password == "" {
        return nil, status.Error(codes.InvalidArgument, "username and password required")
    }
    
    // Simulate authentication (in production, check against database)
    s.mu.RLock()
    var account *Account
    for _, acc := range s.accounts {
        if acc.Username == req.Username {
            account = acc
            break
        }
    }
    s.mu.RUnlock()
    
    if account == nil {
        return nil, status.Error(codes.NotFound, "account not found")
    }
    
    // Generate session token (simplified for demo)
    sessionToken := fmt.Sprintf("session_%d_%d", account.Id, time.Now().Unix())
    
    s.mu.Lock()
    s.sessions[sessionToken] = account
    s.mu.Unlock()
    
    return &LoginResponse{
        Account:      account,
        SessionToken: sessionToken,
    }, nil
}

func (s *EnhancedServer) Logout(ctx context.Context, req *LogoutRequest) (*LogoutResponse, error) {
    log.Printf("Logout attempt with token: %s", req.SessionToken)
    
    if req.SessionToken == "" {
        return nil, status.Error(codes.InvalidArgument, "session token required")
    }
    
    s.mu.Lock()
    _, exists := s.sessions[req.SessionToken]
    if exists {
        delete(s.sessions, req.SessionToken)
    }
    s.mu.Unlock()
    
    return &LogoutResponse{
        Success: exists,
    }, nil
}

func (s *EnhancedServer) GetAccount(ctx context.Context, req *GetAccountRequest) (*GetAccountResponse, error) {
    log.Printf("GetAccount request for ID: %d", req.AccountId)
    
    if req.AccountId == 0 {
        return nil, status.Error(codes.InvalidArgument, "account ID required")
    }
    
    s.mu.RLock()
    account, exists := s.accounts[req.AccountId]
    s.mu.RUnlock()
    
    if !exists {
        return nil, status.Error(codes.NotFound, "account not found")
    }
    
    return &GetAccountResponse{
        Account: account,
    }, nil
}

// Helper method to add test accounts
func (s *EnhancedServer) addTestAccount(id uint64, username, email string) {
    s.mu.Lock()
    s.accounts[id] = &Account{
        Id:        id,
        Username:  username,
        Email:     email,
        CreatedAt: time.Now().Unix(),
    }
    s.mu.Unlock()
}

func main() {
    server := NewEnhancedServer()
    
    // Add some test accounts
    server.addTestAccount(1, "john_doe", "john@example.com")
    server.addTestAccount(2, "jane_smith", "jane@example.com")
    
    s := grpc.NewServer()
    RegisterEnhancedAccountServiceServer(s, server)
    
    lis, err := net.Listen("tcp", ":50052")
    if err != nil {
        log.Fatalf("Failed to listen: %v", err)
    }
    
    log.Println("EnhancedAccountService server listening on :50052")
    if err := s.Serve(lis); err != nil {
        log.Fatalf("Failed to serve: %v", err)
    }
}
```

**Complete Client Usage:**
```go
package main

import (
    "context"
    "log"
    "time"

    "google.golang.org/grpc"
    "google.golang.org/grpc/credentials/insecure"
)

func main() {
    conn, err := grpc.Dial("localhost:50052", grpc.WithTransportCredentials(insecure.NewCredentials()))
    if err != nil {
        log.Fatalf("Failed to connect: %v", err)
    }
    defer conn.Close()

    client := NewEnhancedAccountServiceClient(conn)
    ctx := context.Background()

    // 1. Login
    log.Println("=== Login ===")
    loginResp, err := client.Login(ctx, &LoginRequest{
        Username: "john_doe",
        Password: "password123",
    })
    if err != nil {
        log.Fatalf("Login failed: %v", err)
    }
    log.Printf("Login successful. Account: %+v", loginResp.Account)
    log.Printf("Session token: %s", loginResp.SessionToken)

    // 2. Get Account
    log.Println("\n=== Get Account ===")
    accountResp, err := client.GetAccount(ctx, &GetAccountRequest{
        AccountId: loginResp.Account.Id,
    })
    if err != nil {
        log.Fatalf("GetAccount failed: %v", err)
    }
    log.Printf("Account details: %+v", accountResp.Account)

    // 3. Logout
    log.Println("\n=== Logout ===")
    logoutResp, err := client.Logout(ctx, &LogoutRequest{
        SessionToken: loginResp.SessionToken,
    })
    if err != nil {
        log.Fatalf("Logout failed: %v", err)
    }
    log.Printf("Logout successful: %v", logoutResp.Success)
}
```

**Explanation:** This comprehensive example shows a complete gRPC service with multiple methods, proper error handling, and state management. It demonstrates how gRPC scales from simple services to more complex business logic.

**Production Considerations:** 
- Thread-safe operations with proper mutex usage
- Proper gRPC error codes for different scenarios
- Context-aware operations for timeout handling
- Structured logging for debugging and monitoring

**Sequential Learning Connection:** This example brings together all concepts from the chapter: code generation, client-server patterns, error handling, and the separation between generated code and business logic.
