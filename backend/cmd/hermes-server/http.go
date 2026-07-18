package main

import (
	"encoding/json"
	"log"
	"net/http"
	"time"

	pb "github.com/prince/hermes-backend/internal/api/grpc/pb"
	"github.com/prince/hermes-backend/internal/config"
	"github.com/prince/hermes-backend/internal/services"
)

func startHTTPServer(cfg *config.Config) {
	mux := http.NewServeMux()

	sysSvc := services.NewSystemService()
	chatSvc := services.NewChatService(cfg.OmniRouteURL, cfg.OmniRouteKey)

	// System status endpoint
	mux.HandleFunc("/system/status", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("Access-Control-Allow-Origin", "*")

		status, err := sysSvc.GetStatus(r.Context(), &pb.StatusRequest{})
		if err != nil {
			http.Error(w, `{"error":"`+err.Error()+`"}`, 500)
			return
		}

		svcs, _ := sysSvc.GetServices(r.Context(), &pb.ServicesRequest{})
		resp := map[string]interface{}{
			"cpu":      status.Cpu,
			"memory":   status.Memory,
			"storage":  status.Storage,
			"uptime":   status.Uptime,
			"kernel":   status.Kernel,
			"services": svcs.Services,
		}

		json.NewEncoder(w).Encode(resp)
	})

	// Chat proxy endpoint
	mux.HandleFunc("/v1/chat", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("Access-Control-Allow-Origin", "*")

		if r.Method != "POST" {
			http.Error(w, `{"error":"method not allowed"}`, 405)
			return
		}

		var req struct {
			Message string `json:"message"`
			Model   string `json:"model"`
		}
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, `{"error":"`+err.Error()+`"}`, 400)
			return
		}

		ctx := r.Context()
		resp, err := chatSvc.Chat(ctx, &pb.ChatRequest{
			Message: req.Message,
			Model:   req.Model,
		})
		if err != nil {
			http.Error(w, `{"error":"`+err.Error()+`"}`, 500)
			return
		}

		json.NewEncoder(w).Encode(resp)
	})

	// Health check
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{"status": "ok", "service": "hermes-backend"})
	})

	server := &http.Server{
		Addr:         ":9091",
		Handler:      mux,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 60 * time.Second,
	}

	log.Printf("[http] Hermes HTTP server listening on :9091")
	if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatalf("[http] server error: %v", err)
	}
}
