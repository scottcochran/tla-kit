#!/usr/bin/python3 -I
# tla-kit experiment 2026.11.21: a Z3 server for a sidecar container. Each connection carries z3's arguments and
# one SMT-LIB file; the server writes the file, runs Z3_BIN with those arguments, and answers with z3's exit code,
# stdout and stderr. If the client goes away first, z3 is killed. With Z3_KEEP set, every file and output is kept
# there, numbered.
import hashlib, itertools, json, os, socketserver, struct, subprocess, threading, time

Z3 = os.environ["Z3_BIN"]
PORT = int(os.environ.get("Z3_PORT", "7777"))
KEEP = os.environ.get("Z3_KEEP")
WORK = os.environ.get("Z3_WORK", "/tmp/z3work")
os.makedirs(WORK, exist_ok=True)
if KEEP:
    os.makedirs(KEEP, exist_ok=True)
counter = itertools.count(1)

def send(sock, obj, blob=b""):
    hdr = json.dumps(obj).encode()
    sock.sendall(struct.pack("!II", len(hdr), len(blob)) + hdr + blob)

def recv_exact(sock, n):
    buf = bytearray()
    while len(buf) < n:
        chunk = sock.recv(n - len(buf))
        if not chunk:
            raise EOFError
        buf += chunk
    return bytes(buf)

def recv(sock):
    hl, bl = struct.unpack("!II", recv_exact(sock, 8))
    return json.loads(recv_exact(sock, hl)), recv_exact(sock, bl)

class Handler(socketserver.BaseRequestHandler):
    def handle(self):
        s = self.request
        try:
            req, blob = recv(s)
        except (EOFError, OSError):
            return
        n = next(counter)
        args = req["args"]
        path = None
        if "@FILE@" in args:
            path = os.path.join(KEEP or WORK, f"{n:06d}.smt2")
            with open(path, "wb") as f:
                f.write(blob)
            args = [path if a == "@FILE@" else a for a in args]
        t0 = time.monotonic()
        p = subprocess.Popen([Z3] + args, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

        def watch():
            try:
                if s.recv(1) == b"":
                    p.kill()
            except OSError:
                p.kill()
        threading.Thread(target=watch, daemon=True).start()
        out, err = p.communicate()
        secs = time.monotonic() - t0
        if path and KEEP:
            with open(os.path.join(KEEP, f"{n:06d}.out"), "wb") as f:
                f.write(f"# code {p.returncode} secs {secs:.3f}\n".encode() + out + err)
        elif path:
            os.unlink(path)
        first = (out.decode(errors="replace").strip().split("\n") or [""])[0][:60].replace("\t", " ")
        line = "\t".join([f"{n:06d}", f"{secs:.3f}", str(p.returncode), first or "(no output)", str(len(blob)),
                          hashlib.sha256(blob).hexdigest()[:16]]) + "\n"
        fd = os.open(os.path.join(KEEP or WORK, "calls.tsv"), os.O_WRONLY | os.O_APPEND | os.O_CREAT, 0o644)
        os.write(fd, line.encode()); os.close(fd)
        try:
            send(s, {"code": p.returncode, "stdout": out.decode(errors="replace"),
                     "stderr": err.decode(errors="replace"), "secs": secs, "id": n})
        except OSError:
            pass

class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True

print(f"z3server: {Z3} on port {PORT}, keep={KEEP}", flush=True)
Server(("0.0.0.0", PORT), Handler).serve_forever()
