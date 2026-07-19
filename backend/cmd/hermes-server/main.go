package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"

	"github.com/prince/hermes-backend/internal/api/grpc"
	"github.com/prince/hermes-backend/internal/config"
	"github.com/prince/hermes-backend/internal/db"
)

func main() {
	log.SetFlags(log.Ldate | log.Ltime | log.Lshortfile)
	log.Println("═══ Hermes Backend Server ═══")

	cfg := config.Load()

	// Connect to PostgreSQL (non-fatal if unavailable)
	if d, err := db.Connect(cfg.PostgresDSN); err != nil {
		log.Printf("[main] PostgreSQL not available: %v (continuing)", err)
	} else {
		defer d.Close()
	}

	// Start HTTP server (runs in its own goroutine)
	httpSrv := startHTTPServer(cfg)

	// Build and start gRPC server
	srv, err := grpc.New(cfg.GRPCPort, cfg)
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
	if err := httpSrv.Shutdown(context.Background()); err != nil {
		log.Printf("[main] HTTP shutdown error: %v", err)
	}
	log.Println("[main] Hermes backend stopped")
}
