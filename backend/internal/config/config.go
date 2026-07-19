package config

import (
	"os"
)

type Config struct {
	GRPCPort        string
	OmniRouteURL    string
	OmniRouteKey    string
	HindsightURL    string
	PostgresDSN     string
	LogLevel        string
}

func Load() *Config {
	return &Config{
		GRPCPort:     getEnv("HERMES_GRPC_PORT", "9090"),
		OmniRouteURL: getEnv("HERMES_OMNIROUTE_URL", "http://localhost:20128/v1"),
		OmniRouteKey: getEnv("HERMES_OMNIROUTE_KEY", "5f238e76072d7926"),
		HindsightURL: getEnv("HERMES_HINDSIGHT_URL", "http://127.0.0.1:8888"),
		PostgresDSN:  getEnv("HERMES_POSTGRES_DSN", "postgres://postgres@127.0.0.1:5432/hermes?sslmode=disable"),
		LogLevel:     getEnv("HERMES_LOG_LEVEL", "debug"),
	}
}

func getEnv(key, fallback string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return fallback
}

// OmniRouteURL implements the gRPC server config interface.
func (c *Config) OmniRouteURL() string { return c.OmniRouteURL }

// OmniRouteKey implements the gRPC server config interface.
func (c *Config) OmniRouteKey() string { return c.OmniRouteKey }

// HindsightURL implements the gRPC server config interface.
func (c *Config) HindsightURL() string { return c.HindsightURL }
