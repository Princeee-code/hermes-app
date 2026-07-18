package grpc

import (
	"fmt"
	"log"
	"net"

	pb "github.com/prince/hermes-backend/internal/api/grpc/pb"
	"github.com/prince/hermes-backend/internal/services"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
)

type Server struct {
	server   *grpc.Server
	port     string
}

func New(port string, cfg interface {
	OmniRouteURL() string
	OmniRouteKey() string
	HindsightURL() string
}) (*Server, error) {
	lis, err := net.Listen("tcp", ":"+port)
	if err != nil {
		return nil, fmt.Errorf("listen :%s: %w", port, err)
	}
	lis.Close()

	s := &Server{
		server: grpc.NewServer(
			grpc.MaxRecvMsgSize(10 * 1024 * 1024),
			grpc.MaxSendMsgSize(10 * 1024 * 1024),
		),
		port: port,
	}

	// Register services
	pb.RegisterChatServiceServer(s.server, services.NewChatService(cfg.OmniRouteURL(), cfg.OmniRouteKey()))
	pb.RegisterMemoryServiceServer(s.server, services.NewMemoryService(cfg.HindsightURL()))
	pb.RegisterSystemServiceServer(s.server, services.NewSystemService())

	// Enable reflection for grpcurl and debugging
	reflection.Register(s.server)

	return s, nil
}

func (s *Server) Start() error {
	lis, err := net.Listen("tcp", ":"+s.port)
	if err != nil {
		return fmt.Errorf("listen :%s: %w", s.port, err)
	}

	log.Printf("[grpc] Hermes gRPC server listening on :%s", s.port)
	log.Printf("[grpc] Available services:")
	log.Printf("[grpc]   - hermes.ChatService")
	log.Printf("[grpc]   - hermes.MemoryService")
	log.Printf("[grpc]   - hermes.SystemService")

	return s.server.Serve(lis)
}

func (s *Server) Stop() {
	log.Println("[grpc] Shutting down Hermes gRPC server...")
	s.server.GracefulStop()
}
