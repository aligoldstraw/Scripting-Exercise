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
