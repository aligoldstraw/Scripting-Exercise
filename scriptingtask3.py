#!/usr/bin/env python3

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# SECURE EXAMINATION BOARD SUBMISSION SYSTEM - PYTHON VERSION
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

import os
import hashlib
import time
from datetime import datetime

SUB_LOG = "submission_log.txt"
LOGIN_LOG = "login_log.txt"
CORRECT_PASS = "secureexam2026"

def ensure_files():
    for f in [SUB_LOG, LOGIN_LOG]:
        if not os.path.exists(f):
            open(f, 'a').close()

def get_unix_time():
    return int(time.time())

def format_time(ts):
    return datetime.fromtimestamp(ts).strftime('%Y-%m-%d %H:%M:%S')

def read_log(filename):
    if not os.path.exists(filename):
        return []
    with open(filename, 'r', encoding='utf-8') as f:
        return f.readlines()

def is_account_locked(student_id):
    attempts = []
    for line in read_log(LOGIN_LOG):
        parts = line.strip().split('|')
        if len(parts) >= 3 and parts[1] == student_id:
            ts = int(parts[0])
            status = parts[2]
            attempts.append((ts, status))
    if not attempts:
        return False

 # Sort by time (oldest first) and check consecutive fails from the end
    attempts.sort(key=lambda x: x[0])
    consecutive = 0
    for ts, status in reversed(attempts):
        if status == "SUCCESS":
            break
        consecutive += 1
        if consecutive >= 3:
            return True
    return False

def get_last_attempt_time(student_id):
    attempts = []
    for line in read_log(LOGIN_LOG):
        parts = line.strip().split('|')
        if len(parts) >= 3 and parts[1] == student_id:
            try:
                attempts.append(int(parts[0]))
            except ValueError:
                pass
    return max(attempts) if attempts else None

def submit_assignment():
    print("~~~~~ SUBMIT ASSIGNMENT ~~~~~")
    student_id = input("Enter Student ID: ").strip().replace('|', '')
    if not student_id:
        print("Invalid Student ID.")
        return
    file_path = input("Enter full path to assignment file: ").strip().replace('|', '')
    if not os.path.isfile(file_path):
        print("File does not exist.")
        return
    # Extension
    ext = os.path.splitext(file_path)[1].lower()
    if ext not in ['.pdf', '.docx']:
        print("Invalid file format. Only .pdf and .docx allowed.")
        return
    # Size
    size = os.path.getsize(file_path)
    if size > 5 * 1024 * 1024:
        print("File too large. Maximum 5MB allowed.")
        return
    # MD5
    with open(file_path, 'rb') as f:
        file_md5 = hashlib.md5(f.read()).hexdigest()
    filename = os.path.basename(file_path)

    # Duplicate check
    is_duplicate = False
    for line in read_log(SUB_LOG):
        parts = line.strip().split('|')
        if len(parts) >= 4 and parts[2] == filename and parts[3] == file_md5:
            is_duplicate = True
            break
    if is_duplicate:
        print("Duplicate submission detected (identical filename and content).")
        return
    # Log
    ts = get_unix_time()
    with open(SUB_LOG, 'a', encoding='utf-8') as f:
        f.write(f"{ts}|{student_id}|{filename}|{file_md5}|{size}\n")
    print("Assignment submitted successfully.")
    print("")

def check_file_submitted():
    print("~~~~~ CHECK SUBMITTED FILE ~~~~~")
    filename = input("Enter filename to check (e.g. report.pdf): ").strip().replace('|', '')
    found = []
    for line in read_log(SUB_LOG):
        parts = line.strip().split('|')
        if len(parts) >= 3 and parts[2] == filename:
            ts = int(parts[0])
            sid = parts[1]
            found.append(f"Submitted by {sid} on {format_time(ts)}")
    if found:
        print(f"Yes, the file '{filename}' has been submitted:")
        for entry in found:
            print(f"  - {entry}")
    else:
        print(f"No submissions found for filename '{filename}'.")
    print("")

def list_submitted():
    print("~~~~~ ALL SUBMITTED ASSIGNMENTS ~~~~~")
    logs = read_log(SUB_LOG)
    if not logs:
        print("No submitted assignments yet.")
        print("")
        return
    print(f"{'Student ID':<15} | {'Filename':<25} | {'Size (MB)':<10} | {'Submitted At':<20}")
    print("-" * 75)
    for line in logs:
        parts = line.strip().split('|')
        if len(parts) < 5:
            continue
        sid = parts[1]
        fname = parts[2]
        size_mb = round(int(parts[4]) / (1024 * 1024), 2)
        dt = format_time(int(parts[0]))
        print(f"{sid:<15} | {fname:<25} | {size_mb:<10} | {dt:<20}")
    print("")

def simulate_login():
    print("~~~~~ SIMULATE LOGIN ATTEMPT ~~~~~")
    student_id = input("Enter Student ID: ").strip().replace('|', '')
    if not student_id:
        print("Invalid Student ID.")
        return
    if is_account_locked(student_id):
        print("Account is locked due to multiple failed login attempts.")
        ts = get_unix_time()
        with open(LOGIN_LOG, 'a', encoding='utf-8') as f:
            f.write(f"{ts}|{student_id}|FAILED|account locked\n")
        print("")
        return

    password = input("Enter password: ")
    ts = get_unix_time()
    last_ts = get_last_attempt_time(student_id)
    repeated = last_ts is not None and (ts - last_ts) < 60
    if password == CORRECT_PASS:
        status = "SUCCESS"
        msg = "Login successful."
        note = ""
    else:
        status = "FAILED"
        msg = "Login failed. Incorrect password."
        note = "wrong password"
    if repeated:
        note = "SUSPICIOUS - repeated login attempt within 60 seconds"
        print("Suspicious activity detected: repeated login attempt within 60 seconds.")
    # Log
    log_entry = f"{ts}|{student_id}|{status}"
    if note:
        log_entry += f"|{note}"
    with open(LOGIN_LOG, 'a', encoding='utf-8') as f:
        f.write(log_entry + "\n")
    print(msg)
    print("")
