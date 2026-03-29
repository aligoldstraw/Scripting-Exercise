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

