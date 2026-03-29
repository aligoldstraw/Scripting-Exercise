!/bin/bash

# HPC Job Scheduler Script for University High Performance Computing Laboratory
# Developed with Bash

# Configuration - data files (these are created automatically if they are missing)
QUEUE_FILE="job_queue.txt"
COMPLETED_FILE="completed_jobs.txt"
LOG_FILE="scheduler_log.txt"

# Ensure that files exist (touch is safe and idempotent)
touch "$QUEUE_FILE" "$COMPLETED_FILE" "$LOG_FILE" 2>/dev/null

# Logging function
# Records: timestamp | student ID | job name | scheduling type | action (submitted/executed)
log_event() {
  local student_id="$1"
  local job_name="$2"
  local sched_type="$3"
  local action="$4"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "$timestamp | StudentID: $student_id | Job: $job_name | Scheduler: $sched_type | Action: $action" >> "$LOG_FILE"
}

# View pending jobs (in a formatted table)
view_pending() {
  echo "~~~~~ PENDING JOBS ~~~~~"
  if [ ! -s "$QUEUE_FILE" ]; then
    echo "There are no pending jobs in the queue."
    return
  fi
  printf "%-15s | %-25s | %-12s | %-8s | %-12s\n" "Student ID" "Job Name" "Est Time (s)" "Priority" "Remaining (s)"
  echo "--------------------------------------------------------------------------------"
  while IFS='|' read -r sid jname etime prio rem; do
    printf "%-15s | %-25s | %-12s | %-8s | %-12s\n" "$sid" "$jname" "$etime" "$prio" "$rem"
  done < "$QUEUE_FILE"
  echo ""
}

# View all completed jobs
view_completed() {
  echo "~~~~~ COMPLETED JOBS ~~~~~"
  if [ ! -s "$COMPLETED_FILE" ]; then
    echo "No jobs have been completed yet."
    return
  fi
  printf "%-15s | %-25s | %-12s | %-8s | %-12s\n" "Student ID" "Job Name" "Est Time (s)" "Priority" "Status"
  echo "--------------------------------------------------------------------------------"
  while IFS='|' read -r sid jname etime prio rem; do
    printf "%-15s | %-25s | %-12s | %-8s | %-12s\n" "$sid" "$jname" "$etime" "$prio" "COMPLETED"
  done < "$COMPLETED_FILE"
  echo ""
}

# Submit a new job
submit_job() {
  echo "~~~~~ SUBMIT JOB REQUEST ~~~~~"
  
  read -p "Enter Student ID: " sid
  # Basic sanitisation: strip any pipe characters to protect file format
  sid="${sid//|/}"
  
  read -p "Enter Job Name (can contain spaces): " jname
  jname="${jname//|/}"
  
  read -p "Enter Estimated Execution Time (seconds, positive integer): " etime
  while ! [[ "$etime" =~ ^[0-9]+$ ]] || [ "$etime" -le 0 ]; do
    read -p "Invalid input. Enter positive integer seconds: " etime
  done
  
  read -p "Enter Priority (1-10, lower number = higher priority): " prio
  while ! [[ "$prio" =~ ^[0-9]+$ ]] || [ "$prio" -lt 1 ] || [ "$prio" -gt 10 ]; do
    read -p "Invalid input. Enter integer 1-10: " prio
  done
  
  # Remaining time starts equal to estimated time
  echo "$sid|$jname|$etime|$prio|$etime" >> "$QUEUE_FILE"
  
  log_event "$sid" "$jname" "N/A" "submitted"
  echo "Job submitted successfully and added to queue."
  echo ""
}

# Process job queue with chosen scheduler
process_queue() {
  echo "~~~~~ PROCESS JOB QUEUE ~~~~~"
  
  if [ ! -s "$QUEUE_FILE" ]; then
    echo "No pending jobs to process."
    return
  fi
  
  read -p "Choose scheduler: 1 = Round Robin (quantum 5s), 2 = Priority: " choice
  case "$choice" in
    1) sched="RoundRobin"; quantum=5 ;;
    2) sched="Priority" ;;
    *) echo "Invalid choice. Operation cancelled."; return ;;
  esac
  
  echo "Starting $sched scheduling..."
  
  if [ "$sched" = "Priority" ]; then
    # Priority scheduling (non-preemptive)
    # Lower priority number = higher priority (standard OS convention)
    # Sort by priority field (column 4) ascending numeric
    echo "Processing in priority order (highest priority first)..."
    
    sort -t'|' -k4,4n "$QUEUE_FILE" > "/tmp/temp_sorted_$$.txt" 2>/dev/null
    
    while IFS='|' read -r sid jname etime prio rem; do
      if [ "$rem" -gt 0 ]; then
        echo "▶ Executing '$jname' (Student: $sid, Priority: $prio) for $rem seconds..."
        sleep "$rem"  # Simulate full non-preemptive execution
        log_event "$sid" "$jname" "$sched" "executed"
        echo "$sid|$jname|$etime|$prio|0" >> "$COMPLETED_FILE"
      fi
    done < "/tmp/temp_sorted_$$.txt"
    
    rm -f "/tmp/temp_sorted_$$.txt"
    > "$QUEUE_FILE"  # All jobs completed and removed
    echo "Priority scheduling is complete. Queue cleared."
    
  else
    # Round Robin scheduling (preemptive, quantum=5s)
    echo "Processing with Round Robin (quantum = 5 seconds)..."
    
    # Load current queue into memory array for efficient manipulation
    mapfile -t jobs < "$QUEUE_FILE"
    
    while true; do
      all_done=true
      declare -a new_jobs=()
      
      for job in "${jobs[@]}"; do
        [ -z "$job" ] && continue
        
        IFS='|' read -r sid jname etime prio rem <<< "$job"
        
        if [ "${rem:-0}" -gt 0 ]; then
          all_done=false
          run_time=$(( rem < quantum ? rem : quantum ))
          echo "▶ Running '$jname' (Student: $sid) for $run_time seconds (quantum)..."
          sleep "$run_time"  # Simulate preemptive slice
          
          new_rem=$(( rem - run_time ))
          if [ "$new_rem" -gt 0 ]; then
            new_jobs+=("$sid|$jname|$etime|$prio|$new_rem")
          else
            log_event "$sid" "$jname" "$sched" "executed"
            echo "$sid|$jname|$etime|$prio|0" >> "$COMPLETED_FILE"
          fi
        else
          new_jobs+=("$job")
        fi
      done
      
      jobs=("${new_jobs[@]}")
      
      if [ "$all_done" = true ]; then
        break
      fi
    done
