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

# Check if account is locked due to 3+ consecutive failed attempts
is_account_locked() {
  local student_id="$1"
  local attempts=()
  local line
  while IFS='|' read -r ts sid status note; do
    [ "$sid" = "$student_id" ] || continue
    attempts+=("$ts|$status")
  done < <(read_log "$LOGIN_LOG")
  
  [ ${#attempts[@]} -eq 0 ] && return 1  # not locked
  
  # Check consecutive fails from the end
  local consecutive=0
  for ((i=${#attempts[@]}-1; i>=0; i--)); do
    local entry="${attempts[i]}"
    local status="${entry#*|}"
    if [ "$status" = "SUCCESS" ]; then
      break
    fi
    ((consecutive++))
    [ $consecutive -ge 3 ] && return 0  # locked
  done
  return 1  # not locked
}

# Get last attempt timestamp for student activity
get_last_attempt_time() {
  local student_id="$1"
  local last_ts=0
  local line
  while IFS='|' read -r ts sid status note; do
    [ "$sid" = "$student_id" ] || continue
    [ "$ts" -gt "$last_ts" ] && last_ts="$ts"
  done < <(read_log "$LOGIN_LOG")
  [ "$last_ts" -eq 0 ] && echo "" || echo "$last_ts"
}
