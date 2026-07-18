package main

import (
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/prince/hermes-backend/internal/api/grpc"
	"github.com/prince/hermes-backend/internal/config"
	"github.com/prince/hermes-backend/internal/db"
)

// serverConfig wraps config.Config to provide the interface grpc.Server expects
type serverConfig struct {
	omniRouteURL string
	omniRouteKey string
	hindsightURL string
}

func (c *serverConfig) OmniRouteURL() string { return c.omniRouteURL }
func (c *serverConfig) OmniRouteKey() string  { return c.omniRouteKey }
func (c *serverConfig) HindsightURL() string  { return c.hindsightURL }

func main() {
	log.SetFlags(log.Ldate | log.Ltime | log.Lshortfile)
	log.Println("═══ Hermes Backend Server ═══")

	cfg := config.Load()

	// Connect to PostgreSQL (non-fatal if unavailable)
	if err := db.Connect(cfg.PostgresDSN); err != nil {
		log.Printf("[main] PostgreSQL not available: %v (continuing)", err)
	} else {
		defer db.Close()
	}

	// Start HTTP server (goroutine — runs alongside gRPC)
	go startHTTPServer(cfg)

	// Build gRPC server
	grpcCfg := &serverConfig{
		omniRouteURL: cfg.OmniRouteURL,
		omniRouteKey: cfg.OmniRouteKey,
		hindsightURL: cfg.HindsightURL,
	}

	srv, err := grpc.New(cfg.GRPCPort, grpcCfg)
	if err != nil {
		log.Fatalf("[main] Failed to create gRPC server: %v", err)
	}

	// Graceful shutdown on SIGINT/SIGTERM
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		if err := srv.Start(); err != nil {
			log.Fatalf("[main] gRPC server error: %v", err)
		}
	}()

	<-quit
	log.Println("[main] Shutting down...")
	srv.Stop()
	log.Println("[main] Hermes backend stopped")
}
