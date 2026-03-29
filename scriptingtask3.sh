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
# Submit assignment
submit_assignment() {
  echo "~~~~~ SUBMIT ASSIGNMENT ~~~~~"
  read -p "Enter Student ID: " student_id
  student_id="${student_id//|/}"
  [ -z "$student_id" ] && { echo "Invalid Student ID."; return; }
  
  read -p "Enter full path to assignment file: " file_path
  file_path="${file_path//|/}"
  
  [ ! -f "$file_path" ] && { echo "File does not exist."; return; }
  
  # Extension check
  ext="${file_path##*.}"
  ext="${ext,,}"
  if [[ "$ext" != "pdf" && "$ext" != "docx" ]]; then
    echo "Invalid file format. Only .pdf and .docx allowed."
    return
  fi
  
  # Size check (5MB = 5242880 bytes)
  size=$(stat -c %s "$file_path" 2>/dev/null || stat -f %z "$file_path" 2>/dev/null)
  if [ "$size" -gt 5242880 ]; then
    echo "File too large. Maximum 5MB allowed."
    return
  fi
  
  # Compute MD5
  md5=$(md5sum "$file_path" 2>/dev/null | cut -d' ' -f1)
  [ -z "$md5" ] && { echo "Could not compute file hash."; return; }
  
  filename=$(basename "$file_path")

 # Duplicate check (identical filename AND content)
  local duplicate=false
  local line
  while IFS='|' read -r ts sid fname hash sz; do
    if [ "$fname" = "$filename" ] && [ "$hash" = "$md5" ]; then
      duplicate=true
      break
    fi
  done < <(read_log "$SUB_LOG")
  
  if $duplicate; then
    echo "Duplicate submission detected (identical filename and content)."
    return
  fi
  
  # Log submission for assignment
  ts=$(get_unix_time)
  echo "$ts|$student_id|$filename|$md5|$size" >> "$SUB_LOG"
  
  echo "Assignment submitted successfully."
  echo ""
}

# Check if file has already been submitted
check_file_submitted() {
  echo "~~~~~ CHECK SUBMITTED FILE ~~~~~"
  read -p "Enter filename to check (e.g. report.pdf): " filename
  filename="${filename//|/}"

local found=()
  local line
  while IFS='|' read -r ts sid fname hash sz; do
    [ "$fname" = "$filename" ] || continue
    local dt=$(format_time "$ts")
    found+=("Submitted by $sid on $dt")
  done < <(read_log "$SUB_LOG")
  
  if [ ${#found[@]} -gt 0 ]; then
    echo "'$filename' has been submitted:"
    for entry in "${found[@]}"; do
      echo "  - $entry"
    done
  else
    echo "No submissions found for '$filename'."
  fi
  echo ""
}

# List all submitted assignments
list_submitted() {
  echo "~~~~~ ALL SUBMITTED ASSIGNMENTS ~~~~~"
  if [ ! -s "$SUB_LOG" ]; then
    echo "No submitted assignments yet."
    echo ""
    return
  fi
  
  printf "%-15s | %-25s | %-10s | %-20s\n" "Student ID" "Filename" "Size (MB)" "Submitted At"
  echo "-------------------------------------------------------------------------------"
  
  local line
  while IFS='|' read -r ts sid fname hash sz; do
    local size_mb=$(awk "BEGIN {print sprintf(\"%.2f\", $sz / 1048576)}")
    local dt=$(format_time "$ts")
    printf "%-15s | %-25s | %-10s | %-20s\n" "$sid" "$fname" "$size_mb" "$dt"
  done < "$SUB_LOG"
  echo ""
}

# Simulating login attempt
simulate_login() {
  echo "=== SIMULATE LOGIN ATTEMPT ==="
  read -p "Enter Student ID: " student_id
  student_id="${student_id//|/}"
  [ -z "$student_id" ] && { echo "Invalid Student ID."; return; }
  
  if is_account_locked "$student_id"; then
    echo "Account is locked due to multiple failed login attempts."
    ts=$(get_unix_time)
    echo "$ts|$student_id|FAILED|account locked" >> "$LOGIN_LOG"
    echo ""
    return
  fi
  
read -s -p "Enter password: " password
  echo ""
  
  ts=$(get_unix_time)
  last_ts=$(get_last_attempt_time "$student_id")
  repeated=false
  if [ -n "$last_ts" ] && [ $((ts - last_ts)) -lt 60 ]; then
    repeated=true
  fi
  
  if [ "$password" = "$CORRECT_PASS" ]; then
    status="SUCCESS"
    msg="Login successful."
    note=""
  else
    status="FAILED"
    msg="Login failed. Incorrect password."
    note="wrong password"
  fi
  
  if $repeated; then
    note="SUSPICIOUS - repeated login attempt within 60 seconds"
    echo "Suspicious activity detected: repeated login attempt within 60 seconds."
  fi
  
  # Log each attempt
  log_entry="$ts|$student_id|$status"
  [ -n "$note" ] && log_entry="$log_entry|$note"
  echo "$log_entry" >> "$LOGIN_LOG"
  
  echo "$msg"
  echo ""

# Main menu
main_menu() {
  while true; do
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "     SECURE EXAMINATION BOARD SUBMISSION SYSTEM         "
    echo "                     Bash version                       "
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "1. Submit an assignment"
    echo "2. Check if a file has already been submitted"
    echo "3. List all submitted assignments"
    echo "4. Simulate login attempt"
    echo "5. Exit system"
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    read -p "Please choose your task (1-5): " choice
    
    case "$choice" in
      1) submit_assignment ;;
      2) check_file_submitted ;;
      3) list_submitted ;;
      4) simulate_login ;;
      5)
        read -p "Confirm exit? (Y/N): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
          echo "Exiting Menu. Logs are remembered."
          exit 0
        fi
        ;;
      *) echo "Invalid option. Please choose 1-5." ;;
    esac
  done
}

echo "Starting Secure Submission System (Bash)..."
main_menu
