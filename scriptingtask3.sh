#!/bin/bash
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# SECURE EXAMINATION BOARD SUBMISSION SYSTEM - BASH VERSION
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SUB_LOG="submission_log.txt"
LOGIN_LOG="login_log.txt"
CORRECT_PASS="secureexam2026"

# Ensure log files exist
touch "$SUB_LOG" "$LOGIN_LOG" 2>/dev/null

# Unix timestamp
get_unix_time() {
  date +%s
}

# Format timestamp for display
format_time() {
  date -d "@$1" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "$1"
}

# Read log into array (one line per element)
read_log() {
  local file="$1"
  if [ ! -s "$file" ]; then
    echo ""  # empty
    return
  fi
  cat "$file"
}
