#!/usr/bin/python3 -I
# tla-kit experiment 2026.11.21: stands in for /opt/tlaps/lib/tlapm/backends/bin/z3 inside the tla-kit container.
# tlapm runs `z3 -smt2 -v:0 AUTO_CONFIG=false smt.MBQI=true "$file"`; this sends the arguments and the file to the
# Z3 server named by Z3_SERVER (host:port), prints what the server's z3 printed, exits with its code, and appends
# one line per call to Z3_LOG. If tlapm kills the shell that started this, the socket is closed and the server kills
# its z3.
import hashlib, json, os, socket, struct, sys, threading, time

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

def main():
    args = sys.argv[1:]
    host, port = os.environ["Z3_SERVER"].rsplit(":", 1)
    blob, fname = b"", None
    if args and os.path.isfile(args[-1]):
        fname = args[-1]
        with open(fname, "rb") as f:
            blob = f.read()
        args = args[:-1] + ["@FILE@"]
    ppid = os.getppid()
    t0 = time.monotonic()
    sock = socket.create_connection((host, int(port)))
    send(sock, {"args": args}, blob)

    def log(reply, secs):
        path = os.environ.get("Z3_LOG")
        if not path:
            return
        first = (reply["stdout"].strip().split("\n") or [""])[0][:60].replace("\t", " ")
        line = "\t".join([f"{time.time():.3f}", f"{secs:.3f}", f"{reply.get('secs', -1):.3f}", str(reply["code"]),
                          first, str(len(blob)), hashlib.sha256(blob).hexdigest()[:16], str(reply.get("id", "-"))]) + "\n"
        fd = os.open(path, os.O_WRONLY | os.O_APPEND | os.O_CREAT, 0o644)
        os.write(fd, line.encode()); os.close(fd)

    def watch():  # the parent shell died: tlapm gave up on this call
        while True:
            time.sleep(0.2)
            if os.getppid() != ppid:
                try:
                    sock.shutdown(socket.SHUT_RDWR)
                except OSError:
                    pass
                log({"stdout": "killed-by-tlapm", "code": 137}, time.monotonic() - t0)
                os._exit(137)
    threading.Thread(target=watch, daemon=True).start()

    reply, _ = recv(sock)
    secs = time.monotonic() - t0
    sys.stdout.write(reply["stdout"]); sys.stdout.flush()
    sys.stderr.write(reply["stderr"]); sys.stderr.flush()
    log(reply, secs)
    sys.exit(reply["code"])

main()
