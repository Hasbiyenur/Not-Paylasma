#!/usr/bin/env python3
"""Check current tracked/untracked source files; never print matched values."""
from pathlib import Path
import re
import subprocess
import sys

root = Path(__file__).resolve().parent.parent
result = subprocess.run(['git', 'ls-files', '--cached', '--others', '--exclude-standard', '-z'], cwd=root, check=True, capture_output=True)
patterns = [
    re.compile(r'AIza[0-9A-Za-z_-]{35}'),
    re.compile(r'-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----'),
    re.compile(r'gh[pousr]_[A-Za-z0-9]{30,}'),
    re.compile(r'github_pat_[A-Za-z0-9_]{40,}'),
    re.compile(r'"type"\s*:\s*"service_account"'),
]
failed = False
for raw in set(result.stdout.split(b'\0')):
    if not raw:
        continue
    relative = raw.decode('utf-8', errors='surrogateescape')
    file = root / relative
    if not file.is_file() or file.stat().st_size > 2 * 1024 * 1024:
        continue
    try:
        content = file.read_text(encoding='utf-8')
    except (UnicodeDecodeError, OSError):
        continue
    for number, line in enumerate(content.splitlines(), 1):
        if any(pattern.search(line) for pattern in patterns):
            print(f'{relative}:{number}: credential pattern detected (value redacted)')
            failed = True
if failed:
    sys.exit(1)
print('OK: current non-ignored source files contain no matching credential literals.')