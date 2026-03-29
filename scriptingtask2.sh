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
