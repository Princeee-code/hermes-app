package services

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	pb "github.com/prince/hermes-backend/internal/api/grpc/pb"
)

type MemoryService struct {
	pb.UnimplementedMemoryServiceServer
	hindsightURL string
	httpClient   *http.Client
}

func NewMemoryService(hindsightURL string) *MemoryService {
	return &MemoryService{
		hindsightURL: hindsightURL,
		httpClient:   &http.Client{Timeout: 30 * time.Second},
	}
}

func (s *MemoryService) Recall(ctx context.Context, req *pb.RecallRequest) (*pb.RecallResponse, error) {
	payload := map[string]interface{}{
		"query": req.Query,
		"limit": req.Limit,
	}
	if req.Limit == 0 {
		payload["limit"] = 10
	}

	body, _ := json.Marshal(payload)
	httpReq, _ := http.NewRequestWithContext(ctx, "POST",
		s.hindsightURL+"/api/recall",
		bytes.NewReader(body))
	httpReq.Header.Set("Content-Type", "application/json")

	resp, err := s.httpClient.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("hindsight recall: %w", err)
	}
	defer resp.Body.Close()

	respBody, _ := io.ReadAll(resp.Body)

	var result struct {
		Results []struct {
			Content    string   `json:"content"`
			Relevance  float64  `json:"relevance"`
			Timestamp  string   `json:"timestamp"`
			Tags       []string `json:"tags"`
		} `json:"results"`
	}

	if err := json.Unmarshal(respBody, &result); err != nil {
		return nil, fmt.Errorf("parse recall: %w", err)
	}

	pbResults := make([]*pb.RecallResult, 0, len(result.Results))
	for _, r := range result.Results {
		pbResults = append(pbResults, &pb.RecallResult{
			Content:   r.Content,
			Relevance: r.Relevance,
			Timestamp: r.Timestamp,
			Tags:      r.Tags,
		})
	}

	return &pb.RecallResponse{Results: pbResults}, nil
}

func (s *MemoryService) Retain(ctx context.Context, req *pb.RetainRequest) (*pb.RetainResponse, error) {
	payload := map[string]interface{}{
		"content": req.Content,
		"context": req.Context,
		"tags":    req.Tags,
	}

	body, _ := json.Marshal(payload)
	httpReq, _ := http.NewRequestWithContext(ctx, "POST",
		s.hindsightURL+"/api/retain",
		bytes.NewReader(body))
	httpReq.Header.Set("Content-Type", "application/json")

	resp, err := s.httpClient.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("hindsight retain: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		return &pb.RetainResponse{Success: false}, nil
	}

	return &pb.RetainResponse{Success: true}, nil
}

func (s *MemoryService) Reflect(ctx context.Context, req *pb.ReflectRequest) (*pb.ReflectResponse, error) {
	payload := map[string]interface{}{
		"query": req.Query,
	}

	body, _ := json.Marshal(payload)
	httpReq, _ := http.NewRequestWithContext(ctx, "POST",
		s.hindsightURL+"/api/reflect",
		bytes.NewReader(body))
	httpReq.Header.Set("Content-Type", "application/json")

	resp, err := s.httpClient.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("hindsight reflect: %w", err)
	}
	defer resp.Body.Close()

	respBody, _ := io.ReadAll(resp.Body)

	var result struct {
		Synthesis string   `json:"synthesis"`
		Sources   []string `json:"sources"`
	}

	if err := json.Unmarshal(respBody, &result); err != nil {
		return nil, fmt.Errorf("parse reflect: %w", err)
	}

	return &pb.ReflectResponse{
		Synthesis: result.Synthesis,
		Sources:   result.Sources,
	}, nil
}
