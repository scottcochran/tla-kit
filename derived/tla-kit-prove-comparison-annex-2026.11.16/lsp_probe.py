#!/usr/bin/env python3
"""Drive tlapm_lsp over stdio: open a module, ask it to check one step, and record every message it sends.

    python3 lsp_probe.py MODULE.tla LINE SECONDS > messages.json

LINE is 1-based, as tlapm reports it. Run in the tla-kit image, in the module's directory.
"""
import json
import os
import select
import subprocess
import sys
import time

path, line, wait = os.path.abspath(sys.argv[1]), int(sys.argv[2]), float(sys.argv[3])
uri = "file://" + path
p = subprocess.Popen(["tlapm_lsp", "--stdio"], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                     stderr=open("/tmp/lsp-stderr.txt", "w"))
log, buf = [], b""


def send(msg):
    body = json.dumps(msg).encode()
    try:
        p.stdin.write(b"Content-Length: %d\r\n\r\n" % len(body) + body)
        p.stdin.flush()
        log.append({"t": round(time.time() - t0, 2), "sent": msg})
    except BrokenPipeError:
        log.append({"t": round(time.time() - t0, 2), "not sent, server gone": msg.get("method")})


def pump(seconds):
    global buf
    end = time.time() + seconds
    while time.time() < end:
        r, _, _ = select.select([p.stdout], [], [], 0.2)
        if r:
            chunk = os.read(p.stdout.fileno(), 65536)
            if not chunk:
                return
            buf += chunk
        while b"\r\n\r\n" in buf:
            head, rest = buf.split(b"\r\n\r\n", 1)
            n = int([h for h in head.split(b"\r\n") if h.lower().startswith(b"content-length")][0].split(b":")[1])
            if len(rest) < n:
                break
            log.append({"t": round(time.time() - t0, 2), "got": json.loads(rest[:n])})
            buf = rest[n:]


t0 = time.time()
send({"jsonrpc": "2.0", "id": 1, "method": "initialize",
      "params": {"processId": os.getpid(), "rootUri": "file://" + os.path.dirname(path), "capabilities": {}}})
pump(3)
send({"jsonrpc": "2.0", "method": "initialized", "params": {}})
send({"jsonrpc": "2.0", "method": "textDocument/didOpen", "params": {"textDocument": {
    "uri": uri, "languageId": "tlaplus", "version": 1, "text": open(path).read()}}})
pump(3)
send({"jsonrpc": "2.0", "id": 2, "method": "workspace/executeCommand", "params": {
    "command": "tlaplus.tlaps.check-step.lsp",
    "arguments": [{"uri": uri, "version": 1},
                  {"start": {"line": line - 1, "character": 2}, "end": {"line": line - 1, "character": 2}}]}})
pump(wait)
send({"jsonrpc": "2.0", "id": 3, "method": "shutdown", "params": None})
pump(2)
send({"jsonrpc": "2.0", "method": "exit", "params": None})
try:
    p.wait(timeout=10)
except subprocess.TimeoutExpired:
    p.kill()
log.append({"exit": p.returncode})
json.dump(log, sys.stdout, indent=1)
