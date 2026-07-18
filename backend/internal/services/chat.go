package services

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"strings"
	"time"

	pb "github.com/prince/hermes-backend/internal/api/grpc/pb"
)

type ChatService struct {
	pb.UnimplementedChatServiceServer
	omniRouteURL string
	apiKey       string
	httpClient   *http.Client
}

func NewChatService(omniRouteURL, apiKey string) *ChatService {
	return &ChatService{
		omniRouteURL: omniRouteURL,
		apiKey:       apiKey,
		httpClient:   &http.Client{Timeout: 120 * time.Second},
	}
}

type openAIMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type openAIRequest struct {
	Model     string          `json:"model"`
	Messages  []openAIMessage `json:"messages"`
	Stream    bool            `json:"stream,omitempty"`
	MaxTokens int             `json:"max_tokens,omitempty"`
}

type openAIChoice struct {
	Message openAIMessage `json:"message"`
	Delta   struct {
		Content string `json:"content"`
	} `json:"delta"`
	FinishReason *string `json:"finish_reason"`
}

type openAIUsage struct {
	TotalTokens int `json:"total_tokens"`
}

type openAIResponse struct {
	Model   string         `json:"model"`
	Choices []openAIChoice `json:"choices"`
	Usage   openAIUsage    `json:"usage"`
}

type openAIChunk struct {
	Model   string         `json:"model"`
	Choices []openAIChoice `json:"choices"`
}

func (s *ChatService) Chat(ctx context.Context, req *pb.ChatRequest) (*pb.ChatResponse, error) {
	start := time.Now()

	messages := buildMessages(req)
	model := req.Model
	if model == "" {
		model = "auto/best-free"
	}

	body := openAIRequest{Model: model, Messages: messages, Stream: false}
	payload, _ := json.Marshal(body)

	httpReq, _ := http.NewRequestWithContext(ctx, "POST",
		s.omniRouteURL+"/chat/completions",
		bytes.NewReader(payload))
	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("Authorization", "Bearer "+s.apiKey)

	resp, err := s.httpClient.Do(httpReq)
	if err != nil {
		return nil, fmt.Errorf("request: %w", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("read: %w", err)
	}
	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("status %d: %s", resp.StatusCode, string(respBody))
	}

	// OmniRoute sometimes returns SSE format even when stream=false
	// Detect and handle both formats
	reply, modelUsed, tokens := parseOmniResponse(respBody)

	latency := time.Since(start).Seconds() * 1000
	log.Printf("[chat] model=%s tokens=%d latency=%.0fms reply_len=%d",
		modelUsed, tokens, latency, len(reply))

	return &pb.ChatResponse{
		Reply:      reply,
		ModelUsed:  modelUsed,
		TokensUsed: int64(tokens),
		LatencyMs:  latency,
	}, nil
}

func (s *ChatService) ChatStream(req *pb.ChatRequest, stream pb.ChatService_ChatStreamServer) error {
	start := time.Now()

	messages := buildMessages(req)
	model := req.Model
	if model == "" {
		model = "auto/best-free"
	}

	body := openAIRequest{Model: model, Messages: messages, Stream: true}
	payload, _ := json.Marshal(body)

	httpReq, _ := http.NewRequestWithContext(stream.Context(), "POST",
		s.omniRouteURL+"/chat/completions",
		bytes.NewReader(payload))
	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("Authorization", "Bearer "+s.apiKey)

	resp, err := s.httpClient.Do(httpReq)
	if err != nil {
		return fmt.Errorf("stream request: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("stream status %d: %s", resp.StatusCode, string(body))
	}

	scanner := bufio.NewScanner(resp.Body)
	scanner.Buffer(make([]byte, 0, 64*1024), 256*1024)

	for scanner.Scan() {
		select {
		case <-stream.Context().Done():
			return stream.Context().Err()
		default:
		}

		line := scanner.Text()
		if !strings.HasPrefix(line, "data: ") {
			continue
		}

		data := line[6:]
		if data == "[DONE]" {
			elapsed := time.Since(start).Seconds() * 1000
			log.Printf("[chat/stream] done latency=%.0fms", elapsed)
			return stream.Send(&pb.ChatStreamChunk{Done: true})
		}

		var chunk openAIChunk
		if err := json.Unmarshal([]byte(data), &chunk); err != nil {
			continue
		}
		for _, c := range chunk.Choices {
			if c.Delta.Content != "" {
				if err := stream.Send(&pb.ChatStreamChunk{Content: c.Delta.Content}); err != nil {
					return err
				}
			}
			if c.FinishReason != nil && *c.FinishReason == "stop" {
				return stream.Send(&pb.ChatStreamChunk{Done: true})
			}
		}
	}

	return stream.Send(&pb.ChatStreamChunk{Done: true})
}

func buildMessages(req *pb.ChatRequest) []openAIMessage {
	msgs := make([]openAIMessage, 0, len(req.History)+1)
	for _, m := range req.History {
		msgs = append(msgs, openAIMessage{Role: m.Role, Content: m.Content})
	}
	msgs = append(msgs, openAIMessage{Role: "user", Content: req.Message})
	return msgs
}

// parseOmniResponse handles both standard JSON and SSE-streamed responses
func parseOmniResponse(body []byte) (reply, model string, tokens int) {
	text := strings.TrimSpace(string(body))

	// Case 1: SSE format (data: {...}\n\ndata: {...}\n\ndata: [DONE])
	if strings.HasPrefix(text, "data: ") {
		var fullContent strings.Builder
		scanner := bufio.NewScanner(strings.NewReader(text))
		for scanner.Scan() {
			line := scanner.Text()
			if !strings.HasPrefix(line, "data: ") {
				continue
			}
			data := line[6:]
			if data == "[DONE]" {
				break
			}
			if data == "" {
				continue
			}
			var chunk openAIChunk
			if err := json.Unmarshal([]byte(data), &chunk); err != nil {
				continue
			}
			if model == "" {
				model = chunk.Model
			}
			for _, c := range chunk.Choices {
				fullContent.WriteString(c.Delta.Content)
			}
		}
		return fullContent.String(), model, 0
	}

	// Case 2: Standard JSON response
	var resp openAIResponse
	if err := json.Unmarshal(body, &resp); err != nil {
		log.Printf("[chat/parse] json error: %v, body(200): %s", err, string(body[:min(len(body), 200)]))
		return "", "", 0
	}
	if len(resp.Choices) > 0 {
		reply = resp.Choices[0].Message.Content
	}
	return reply, resp.Model, resp.Usage.TotalTokens
}
