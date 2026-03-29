#!/bin/bash

# Menu-driven interface for university data centre simulation

# Configuration
LOG_FILE="$HOME/system_monitor_log.txt"
ARCHIVE_DIR="$HOME/LogArchive"
LOG_SEARCH_DIR="/var/log"          # Normal location for system logs on Linux servers

# Create necessary directories and log file
mkdir -p "$ARCHIVE_DIR"
touch "$LOG_FILE"

# Function that logs all administrative actions with timestamp for evidence
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Function to check whether a process is critical and cannot be terminated
is_critical_process() {
    local pid=$1
    if [ "$pid" -le 10 ]; then
        return 0  # Critical system PID (kernel, init, etc.)
    fi
    
    local proc_name=$(ps -p "$pid" -o comm= 2>/dev/null)
    if [ -z "$proc_name" ]; then
        return 1
    fi
    
    # List of critical system processes (preventing termination)
    case "$proc_name" in
        systemd|init|kthreadd|ksoftirqd*|kworker*|migration*|rcu*|dbus*|sshd|agetty|cron|rsyslogd|journald|login|bash|sh)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}
