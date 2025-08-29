# gRPC Topic: Introduction to gRPC - Architecture Patterns

## Overview
This chapter focuses on understanding how gRPC works internally, covering the code generation process, client-server communication patterns, and the read/write flow specialization for gRPC. The diagrams emphasize the separation between user code and generated code, and how gRPC abstracts communication complexity.

## Diagram 1: gRPC Code Generation Flow

```
┌─────────────────┐
│   .proto File   │
│                 │
│ service         │
│ AccountService  │
│ {               │
│   rpc Logout()  │
│ }               │
└─────────┬───────┘
          │
          v
┌─────────────────┐
│  protoc + Go    │
│    plugins      │
│                 │
│ --go_out        │
│ --go-grpc_out   │
└─────────┬───────┘
          │
          v
┌─────────────────────────────────────────────────────────┐
│              Generated Go Code                          │
│                                                         │
│  ┌─────────────────┐  ┌─────────────────────────────┐  │
│  │   Server Side   │  │        Client Side          │  │
│  │                 │  │                             │  │
│  │ ServiceServer   │  │ ServiceClient interface     │  │
│  │ interface       │  │                             │  │
│  │                 │  │ serviceClient struct        │  │
│  │ ServiceDesc     │  │                             │  │
│  │ metadata        │  │ NewServiceClient()          │  │
│  │                 │  │                             │  │
│  │ Handler funcs   │  │ method implementations      │  │
│  │                 │  │ (use cc.Invoke)             │  │
│  └─────────────────┘  └─────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Implementation Details
```go
// Generated server interface
type AccountServiceServer interface {
    Logout(context.Context, *LogoutRequest) (*LogoutResponse, error)
    mustEmbedUnimplementedAccountServiceServer()
}

// Generated client interface
type AccountServiceClient interface {
    Logout(ctx context.Context, in *LogoutRequest, opts ...grpc.CallOption) (*LogoutResponse, error)
}

// Generated client implementation
func (c *accountServiceClient) Logout(ctx context.Context, in *LogoutRequest, opts ...grpc.CallOption) (*LogoutResponse, error) {
    out := new(LogoutResponse)
    err := c.cc.Invoke(ctx, "/AccountService/Logout", in, out, opts...)
    return out, nil
}
```

### Sequential Learning Notes
This pattern builds on Protobuf code generation from Chapter 2, extending it to include gRPC communication code for both client and server sides.

## Diagram 2: gRPC Request-Response Flow

```
Client Application                              Server Application
        │                                               │
        │ 1. Call client.Logout(req)                   │
        v                                               │
┌────────────────┐                               ┌─────────────────┐
│ Generated      │                               │ Generated       │
│ Client Code    │                               │ Server Code     │
│                │                               │                 │
│ cc.Invoke()    │ ── 2. HTTP/2 Request ──────▶ │ Handler Route   │
│ - Serialize    │    "/AccountService/Logout"   │ - Deserialize   │
│ - Send         │                               │ - Route         │
└────────────────┘                               └─────────┬───────┘
        │                                                  │
        │                                                  │ 3. Call user impl
        │                                                  v
        │                                          ┌─────────────────┐
        │                                          │ User Server     │
        │                                          │ Implementation  │
        │                                          │                 │
        │                                          │ func Logout()   │
        │                                          │ { business      │
        │                                          │   logic }       │
        │                                          └─────────┬───────┘
        │                                                    │
        │                                                    │ 4. Return response
        │                                                    v
┌────────────────┐                               ┌─────────────────┐
│ User Client    │                               │ Generated       │
│ Code           │                               │ Server Code     │
│                │ ◀── 5. HTTP/2 Response ───── │                 │
│ response obj   │                               │ - Serialize     │
│ available      │                               │ - Send          │
└────────────────┘                               └─────────────────┘
```

### Key Decision Points
- **Separation of Concerns**: Generated code handles all communication boilerplate
- **Route Construction**: "/ServiceName/MethodName" pattern for gRPC routing
- **Serialization Abstraction**: Protobuf serialization/deserialization hidden from user

## Diagram 3: Read/Write Flow Specialization for gRPC

```
Chapter 1 Generic Flow          Chapter 3 gRPC Specialization
                               
┌──────────────┐               ┌─────────────────────────────────────┐
│  User Code   │               │           User Code Layer          │
│              │               │                                     │
│              │               │ ┌─────────────┐ ┌─────────────────┐ │
│              │               │ │Client Code  │ │Server Impl      │ │
│              │               │ │             │ │                 │ │
│              │               │ │client.      │ │func Logout() {  │ │
│              │               │ │Logout(req)  │ │  // business    │ │
│              │               │ │             │ │  // logic       │ │
│              │               │ │             │ │}                │ │
│              │               │ └─────────────┘ └─────────────────┘ │
└──────┬───────┘               └─────────────┬───────────────────────┘
       │                                     │
       │                                     │
       v                                     v
┌──────────────┐               ┌─────────────────────────────────────┐
│  Framework   │               │        Generated Code Layer        │
│              │               │                                     │
│              │               │ ┌─────────────┐ ┌─────────────────┐ │
│              │               │ │Client Stub  │ │Server Handler   │ │
│              │               │ │             │ │                 │ │
│              │               │ │cc.Invoke()  │ │Route & Handle   │ │
│              │               │ │Serialize    │ │Deserialize      │ │
│              │               │ │             │ │Call User Impl   │ │
│              │               │ │             │ │Serialize Result │ │
│              │               │ └─────────────┘ └─────────────────┘ │
└──────┬───────┘               └─────────────┬───────────────────────┘
       │                                     │
       │                                     │
       v                                     v
┌──────────────┐               ┌─────────────────────────────────────┐
│  Transport   │               │         HTTP/2 Transport            │
│              │               │                                     │
│              │               │ • HTTP/2 Frames                    │
│              │               │ • Connection Management            │
│              │               │ • Multiplexing                     │
│              │               │ • Flow Control                     │
└──────────────┘               └─────────────────────────────────────┘
```

### Implementation Focus
```go
// User Code Layer - Client Side
response, err := client.Logout(ctx, &LogoutRequest{
    Account: &Account{Id: 123, Username: "user"},
})

// User Code Layer - Server Side  
func (s *Server) Logout(ctx context.Context, req *LogoutRequest) (*LogoutResponse, error) {
    // Pure business logic - no communication concerns
    return &LogoutResponse{}, nil
}

// Generated Code Layer (hidden from user)
func (c *accountServiceClient) Logout(ctx context.Context, in *LogoutRequest, opts ...grpc.CallOption) (*LogoutResponse, error) {
    out := new(LogoutResponse)
    err := c.cc.Invoke(ctx, "/AccountService/Logout", in, out, opts...)
    return out, nil
}
```

### Sequential Learning Connection
This diagram builds directly on the generic read/write flow from Chapter 1, showing how gRPC specifically implements each layer.

## Diagram 4: Forward Compatibility Pattern with UnimplementedServer

```
Service Evolution Timeline
    
    v1.0                        v2.0                        v3.0
┌─────────────┐              ┌─────────────┐              ┌─────────────┐
│ Service A   │              │ Service A   │              │ Service A   │
│             │              │             │              │             │
│ methods:    │              │ methods:    │              │ methods:    │
│ - Logout()  │              │ - Logout()  │              │ - Logout()  │
│             │              │ - Login()   │              │ - Login()   │
│             │              │             │              │ - Register()│
└─────────────┘              └─────────────┘              └─────────────┘
       │                            │                            │
       │                            │                            │
       v                            v                            v
┌─────────────┐              ┌─────────────┐              ┌─────────────┐
│Implementation│              │Implementation│              │Implementation│
│             │              │             │              │             │
│type Server  │              │type Server  │              │type Server  │
│struct {     │              │struct {     │              │struct {     │
│  Unimpl...  │              │  Unimpl...  │              │  Unimpl...  │
│}            │              │}            │              │}            │
│             │              │             │              │             │
│func Logout()│              │func Logout()│              │func Logout()│
│{ impl }     │              │{ impl }     │              │{ impl }     │
│             │              │func Login() │              │func Login() │
│             │              │{ impl }     │              │{ impl }     │
│             │              │             │              │func Register│
│             │              │             │              │{ impl }     │
└─────────────┘              └─────────────┘              └─────────────┘

Backward Compatibility:
┌─────────────────────────────────────────────────────────────────────┐
│ v1.0 Client calling v3.0 Server                                    │
│                                                                     │
│ Client calls: Logout() ────────────▶ Server responds: OK           │
│ Client calls: Login()  ────────────▶ Server responds: OK           │
│ Client calls: Register() ──────────▶ Server responds: UNIMPLEMENTED│
│                                      (via UnimplementedServer)     │
│                                                                     │
│ Result: No crashes, graceful degradation                           │
└─────────────────────────────────────────────────────────────────────┘
```

### Key Decision Points
- **Embedding Strategy**: Using Go's type embedding for default implementations
- **Graceful Degradation**: Returning errors instead of crashing for unknown methods
- **Version Independence**: Older clients can work with newer servers

### Implementation Details
```go
// Generated base with forward compatibility
type UnimplementedAccountServiceServer struct {}

func (UnimplementedAccountServiceServer) Logout(context.Context, *LogoutRequest) (*LogoutResponse, error) {
    return nil, status.Errorf(codes.Unimplemented, "method Logout not implemented")
}

func (UnimplementedAccountServiceServer) Login(context.Context, *LoginRequest) (*LoginResponse, error) {
    return nil, status.Errorf(codes.Unimplemented, "method Login not implemented")
}

// User implementation
type Server struct {
    UnimplementedAccountServiceServer
}

// Override only what you implement
func (s *Server) Logout(ctx context.Context, req *LogoutRequest) (*LogoutResponse, error) {
    // Custom implementation
    return &LogoutResponse{}, nil
}

// Login() automatically returns "not implemented" via embedding
```

### Production Considerations
This pattern ensures that services can evolve independently without breaking existing clients, which is crucial for microservices architecture and distributed systems deployment.
