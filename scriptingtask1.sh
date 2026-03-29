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

# Main menu
while true; do
    clear
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "    Hello, Welcome to this Kali Linux Intelligent System Monitor Tool"
    echo "            University Data Centre Administration Simulator"
    echo "                              Main Menu:                             "
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "1. Display current CPU and memory usage"
    echo "2. List of top 10 memory consuming processes"
    echo "3. Terminate a process (with confirmation)"
    echo "4. Inspect disk usage of a directory"
    echo "5. Detect and archive large log files (>50MB)"
    echo "6. View system monitor log"
    echo "0. Bye (Exit with confirmation)"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    read -p "What task would you like to choose? " choice

case $choice in
        1)  # Displays current CPU and memory usage
            echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
            echo "CURRENT CPU AND MEMORY USAGE"
            echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
            
            # CPU Usage
            echo "CPU Usage = "
            top -bn1 | awk '/^%Cpu/ {printf "   Total used: %.1f%%\n", 100-$8}'
            
            # Memory Usage
            echo -e "\nMemory Usage:"
            free -h | grep -E 'Mem:|Swap:'
            
            log_action "Viewed current CPU and memory usage"
            echo -e "\nAction logged to $LOG_FILE"
            ;;

	2)  # List of top 10 memory consuming processes
            echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
            echo "TOP 10 MEMORY CONSUMING PROCESSES"
            echo "PID      USER       %CPU       %MEM     COMMAND"
            echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
            ps -eo pid,user,%cpu,%mem,comm --sort=-%mem | head -n 11
            log_action "User viewed top 10 memory consuming processes in University"
            echo -e "\nAction logged to $LOG_FILE"
            ;;

	3)  # Terminates a selected process
            echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
            echo "TERMINATE PROCESS"
            echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
            
            # Shows top processes again for easy selection
            echo "Current top memory processes = "
            ps -eo pid,user,%cpu,%mem,comm --sort=-%mem | head -n 11
            
            read -p "Enter PID to terminate: " pid
            
            if ! [[ "$pid" =~ ^[0-9]+$ ]]; then
                echo "Error: PID must be a number!"
                sleep 2
                continue
            fi
            
            if ! ps -p "$pid" > /dev/null 2>&1; then
                echo "Error: Process with PID $pid does not exist!"
                sleep 2
                continue
            fi
            
            if is_critical_process "$pid"; then
                echo "ERROR: Unable to terminate critical system process (PID $pid)!"
                log_action "ATTEMPTED to terminate critical process PID $pid (blocked)"
                sleep 2
                continue
            fi
            
            proc_name=$(ps -p "$pid" -o comm=)
            echo "You are about to terminate: PID=$pid  Name=$proc_name"
            read -p "Are you sure you want to terminate? (Y/N): " confirm
            
            if [[ "$confirm" == "Y" || "$confirm" == "y" ]]; then
                if kill "$pid" 2>/dev/null; then
                    echo "Process PID $pid terminated successfully."
                    log_action "TERMINATED process PID $pid (Name: $proc_name)"
                else
                    echo "Failed to terminate process (permission denied or already gone)."
                    log_action "FAILED to terminate process PID $pid"
                fi
            else
                echo "Termination cancelled."
                log_action "CANCELLED termination of PID $pid"
            fi
            ;;
