package services

import (
	"context"
	"fmt"
	"log"
	"net"
	"os"
	"strings"
	"time"

	"golang.org/x/sys/unix"

	pb "github.com/prince/hermes-backend/internal/api/grpc/pb"
)

type SystemService struct {
	pb.UnimplementedSystemServiceServer
}

func NewSystemService() *SystemService {
	return &SystemService{}
}

func (s *SystemService) GetStatus(ctx context.Context, req *pb.StatusRequest) (*pb.StatusResponse, error) {
	return &pb.StatusResponse{
		Cpu:     getCPUInfo(),
		Memory:  getMemoryInfo(),
		Storage: getStorageInfo(),
		Uptime:  getUptime(),
		Kernel:  getKernel(),
	}, nil
}

func (s *SystemService) GetServices(ctx context.Context, req *pb.ServicesRequest) (*pb.ServicesResponse, error) {
	services := []*pb.ServiceInfo{
		checkTCP("OmniRoute", "localhost:20128"),
		checkTCP("Hindsight", "127.0.0.1:8888"),
		checkProc("PostgreSQL", "postgres"),
		checkProc("Roblox Keeper", "roblox-keeper"),
	}
	return &pb.ServicesResponse{Services: services}, nil
}

func getCPUInfo() *pb.CpuInfo {
	info := &pb.CpuInfo{}

	// Count cores (only cpuN directories where N is a digit)
	entries, err := os.ReadDir("/sys/devices/system/cpu/")
	if err != nil {
		log.Printf("[services] getCPUInfo: read cpu dir: %v", err)
	} else {
		for _, e := range entries {
			name := e.Name()
			if len(name) > 3 && name[:3] == "cpu" {
				isCore := true
				for _, c := range name[3:] {
					if c < '0' || c > '9' {
						isCore = false
						break
					}
				}
				if isCore {
					info.Cores++
				}
			}
		}
	}

	// Read model from /proc/cpuinfo
	data, err := os.ReadFile("/proc/cpuinfo")
	if err != nil {
		log.Printf("[services] getCPUInfo: read /proc/cpuinfo: %v", err)
	} else {
		for _, line := range strings.Split(string(data), "\n") {
			if strings.Contains(line, "Hardware") {
				parts := strings.SplitN(line, ":", 2)
				if len(parts) == 2 {
					info.Model = strings.TrimSpace(parts[1])
					break
				}
			}
		}
	}

	// Governor
	gov, err := os.ReadFile("/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor")
	if err != nil {
		log.Printf("[services] getCPUInfo: read governor: %v", err)
	} else {
		info.Governor = strings.TrimSpace(string(gov))
	}

	// Load
	load, err := os.ReadFile("/proc/loadavg")
	if err != nil {
		log.Printf("[services] getCPUInfo: read /proc/loadavg: %v", err)
	} else {
		parts := strings.Fields(string(load))
		if len(parts) >= 3 {
			fmt.Sscanf(parts[0], "%f", &info.Load_1M)
			fmt.Sscanf(parts[1], "%f", &info.Load_5M)
			fmt.Sscanf(parts[2], "%f", &info.Load_15M)
		}
	}

	return info
}

func getMemoryInfo() *pb.MemoryInfo {
	mi := &pb.MemoryInfo{}
	data, err := os.ReadFile("/proc/meminfo")
	if err != nil {
		log.Printf("[services] getMemoryInfo: read /proc/meminfo: %v", err)
		return mi
	}
	var swapFree int64
	for _, line := range strings.Split(string(data), "\n") {
		var key string
		var val int64
		if n, _ := fmt.Sscanf(line, "%s %d kB", &key, &val); n == 2 {
			key = strings.TrimSuffix(key, ":")
			switch key {
			case "MemTotal":
				mi.TotalKb = val
			case "MemFree":
				mi.FreeKb = val
			case "MemAvailable":
				mi.AvailableKb = val
			case "SwapTotal":
				mi.SwapTotalKb = val
			case "SwapFree":
				swapFree = val
			}
		}
	}
	mi.SwapUsedKb = mi.SwapTotalKb - swapFree
	return mi
}

func getStorageInfo() *pb.StorageInfo {
	si := &pb.StorageInfo{Mount: "/data"}
	var stat unix.Statfs_t
	if err := unix.Statfs("/data", &stat); err == nil {
		si.TotalBytes = int64(stat.Blocks) * int64(stat.Bsize)
		si.FreeBytes = int64(stat.Bavail) * int64(stat.Bsize)
	} else {
		log.Printf("[services] getStorageInfo: statfs /data: %v", err)
	}
	return si
}

func getUptime() string {
	data, err := os.ReadFile("/proc/uptime")
	if err != nil {
		log.Printf("[services] getUptime: read /proc/uptime: %v", err)
		return "unknown"
	}
	parts := strings.Fields(string(data))
	if len(parts) == 0 {
		return "unknown"
	}
	var seconds float64
	fmt.Sscanf(parts[0], "%f", &seconds)
	d := time.Duration(seconds) * time.Second
	days := int(d.Hours() / 24)
	hours := int(d.Hours()) % 24
	mins := int(d.Minutes()) % 60
	return fmt.Sprintf("%dd %dh %dm", days, hours, mins)
}

func getKernel() string {
	data, err := os.ReadFile("/proc/version")
	if err != nil {
		log.Printf("[services] getKernel: read /proc/version: %v", err)
		return "Linux (aarch64)"
	}
	return strings.TrimSpace(string(data))
}

func checkTCP(name, addr string) *pb.ServiceInfo {
	si := &pb.ServiceInfo{Name: name, Endpoint: addr}
	conn, err := net.DialTimeout("tcp", addr, 3*time.Second)
	if err != nil {
		log.Printf("[services] checkTCP(%s): dial %s: %v", name, addr, err)
		si.Status = "stopped"
		return si
	}
	conn.Close()
	si.Status = "running"
	return si
}

func checkProc(name, procName string) *pb.ServiceInfo {
	si := &pb.ServiceInfo{Name: name}
	entries, err := os.ReadDir("/proc")
	if err != nil {
		log.Printf("[services] checkProc(%s): read /proc: %v", procName, err)
		si.Status = "stopped"
		return si
	}
	for _, e := range entries {
		if !e.IsDir() {
			continue
		}
		cmdline, err := os.ReadFile("/proc/" + e.Name() + "/cmdline")
		if err != nil {
			continue
		}
		if strings.Contains(string(cmdline), procName) {
			si.Status = "running"
			fmt.Sscanf(e.Name(), "%d", &si.Pid)
			return si
		}
	}
	si.Status = "stopped"
	return si
}
