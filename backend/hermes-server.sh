#!/data/data/com.termux/files/usr/bin/bash
# Hermes Backend Server — start/stop/status controller
# Usage: hermes-server [start|stop|restart|status]

ACTION="${1:-status}"
PID_FILE="$HOME/hermes-app/backend/hermes-server.pid"
BINARY="$HOME/hermes-app/backend/bin/hermes-server"
LOG_DIR="$HOME/hermes-app/backend/logs"

export PATH="$HOME/go/bin:/system/bin:/system/xbin:$PATH"

case "$ACTION" in
  start)
    mkdir -p "$LOG_DIR"
    cd "$HOME/hermes-app/backend"
    if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
      echo "Hermes server already running (PID $(cat "$PID_FILE"))"
      exit 0
    fi
    nohup "$BINARY" > "$LOG_DIR/server.log" 2>&1 &
    echo $! > "$PID_FILE"
    sleep 1
    if kill -0 $(cat "$PID_FILE") 2>/dev/null; then
      echo "Hermes server started (PID $(cat "$PID_FILE"))"
    else
      echo "Failed to start Hermes server"
      exit 1
    fi
    ;;
  stop)
    if [ -f "$PID_FILE" ]; then
      kill $(cat "$PID_FILE") 2>/dev/null
      rm -f "$PID_FILE"
      echo "Hermes server stopped"
    else
      pkill -f hermes-server 2>/dev/null && echo "Hermes server stopped" || echo "Hermes server not running"
    fi
    ;;
  restart)
    "$0" stop
    sleep 1
    "$0" start
    ;;
  status)
    if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
      echo "Hermes server: RUNNING (PID $(cat "$PID_FILE"))"
    elif pgrep -f hermes-server > /dev/null 2>&1; then
      echo "Hermes server: RUNNING (PID $(pgrep -f hermes-server | head -1), no pidfile)"
    else
      echo "Hermes server: STOPPED"
    fi
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|status}"
    exit 1
    ;;
esac
