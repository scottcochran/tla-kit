#!/usr/bin/env python3
"""Check the agent's repair, apart from what the agent says.

    examples/agent-repair/check.py PROJECT PLUGIN_DIR TRANSCRIPT

1. The session had the plugin's tla-kit server, connected, with its fourteen tools, and ended without an error.
2. The last prove the agent ran on the whole module succeeded.
3. In the project, only spec/Counter_proof.tla changed, and only in its proofs: with every proof taken out, the
   module before and after is the same, so no statement or definition changed, and Counter.tla did not.
4. tlapm --cleanfp --strict, run directly in the image the plugin names, outside the server and with no cache,
   proves the repaired module.
Prints a summary of the session and exits 1 if any check fails.
"""
import json, os, re, shutil, subprocess, sys, tempfile

project, plugin, transcript = sys.argv[1:4]
SERVER = "plugin:writing-tla-specs-and-proofs:tla-kit"
PREFIX = "mcp__plugin_writing-tla-specs-and-proofs_tla-kit__"
TOOLS = {"info", "parse", "symbols", "evaluate", "tlc_run", "simulate", "coverage", "state_graph", "tlc_rows",
         "prove", "proof_check", "proof_results", "flip_test", "proof_sync"}
failures = []


def check(ok, what):
    print(("ok    " if ok else "FAIL  ") + what, flush=True)
    if not ok:
        failures.append(what)


init, result, calls, last_module_prove = None, None, {}, None
for line in open(transcript):
    m = json.loads(line)
    if m.get("subtype") == "init":
        init = m
    elif m.get("type") == "result":
        result = m
    elif m.get("type") == "assistant":
        for c in m["message"]["content"]:
            if c["type"] == "tool_use":
                calls[c["id"]] = (c["name"], c["input"])
                args = {k: v for k, v in c["input"].items() if k not in ("old_string", "new_string")}
                print(f"      call {c['name'].replace(PREFIX, 'tla-kit:')} {json.dumps(args)}")
    elif m.get("type") == "user":
        for c in m["message"].get("content", []):
            if isinstance(c, dict) and c.get("type") == "tool_result":
                name, args = calls.get(c["tool_use_id"], ("?", {}))
                body = c["content"]
                body = " ".join(x.get("text", "") for x in body) if isinstance(body, list) else str(body)
                if name == PREFIX + "prove" and set(args) <= {"module", "timeout", "threads", "stretch", "nofp"}:
                    try:
                        last_module_prove = json.loads(body)
                    except ValueError:
                        last_module_prove = {"verdict": "unreadable"}
                    print(f"        -> {last_module_prove.get('verdict')} {last_module_prove.get('counts')}")

check(init is not None, "the session started")
servers = {s["name"]: s["status"] for s in (init or {}).get("mcp_servers", [])}
check(servers.get(SERVER) == "connected", f"the plugin's server is connected ({servers.get(SERVER)})")
have = {t[len(PREFIX):] for t in (init or {}).get("tools", []) if t.startswith(PREFIX)}
check(have == TOOLS, f"it offers the fourteen tools ({len(have)})")
check(result is not None and result.get("subtype") == "success" and not result.get("is_error"),
      "the session ended without an error")
if result:
    print(f"      {result.get('num_turns')} turns, {result.get('duration_ms', 0) / 1000:.0f} s, "
          f"${result.get('total_cost_usd') or 0:.2f}, refused: {[d.get('tool_name') for d in result.get('permission_denials') or []]}")
check(bool(last_module_prove and last_module_prove.get("success")),
      "the last prove of the whole module succeeded")

status = subprocess.run(["git", "-C", project, "status", "--porcelain"], capture_output=True, text=True).stdout
check(status.splitlines() == [" M spec/Counter_proof.tla"], f"only spec/Counter_proof.tla changed ({status.split()})")
diff = subprocess.run(["git", "-C", project, "diff", "-U0", "--", "spec/Counter_proof.tla"],
                      capture_output=True, text=True).stdout
for l in diff.splitlines():
    if l[:1] in "+-" and not l.startswith(("+++", "---")):
        print("      " + l)

PROOF_START = re.compile(r"^\s*(BY|OBVIOUS|OMITTED|PROOF)\b|^\s*<\d+>")


def outside_proofs(text):
    """The module with every proof taken out: what is left is its statements, definitions and the rest. A proof
    starts at BY, OBVIOUS, OMITTED, PROOF or a step <n>, and runs over blank lines, indented lines and further
    steps, to the next line that starts at the margin with anything else."""
    kept, in_proof = [], False
    for line in text.splitlines():
        if PROOF_START.match(line):
            in_proof = True
        elif in_proof and (not line.strip() or line[0].isspace()):
            pass
        else:
            in_proof = False
            if line.strip():
                kept.append(line.rstrip())
    return kept


before = subprocess.run(["git", "-C", project, "show", "HEAD:spec/Counter_proof.tla"],
                        capture_output=True, text=True).stdout
after = open(os.path.join(project, "spec", "Counter_proof.tla")).read()
check(before != after and outside_proofs(before) == outside_proofs(after),
      "only proofs changed: outside them the module is as it was")

image = re.search(r"ghcr\.io/scottcochran/tla-kit@sha256:[0-9a-f]{64}", open(os.path.join(plugin, ".mcp.json")).read())
check(image is not None, "the plugin names the image by digest")
if image:
    scratch = tempfile.mkdtemp(prefix="agent-repair-check-")
    for f in ("Counter.tla", "Counter_proof.tla"):
        shutil.copy(os.path.join(project, "spec", f), scratch)
    os.chmod(scratch, 0o777)
    r = subprocess.run(["docker", "run", "--rm", "--user", f"{os.getuid()}:{os.getgid()}", "-v", f"{scratch}:/work",
                        image.group(0), "tlapm", "--cleanfp", "--strict", "Counter_proof.tla"],
                       capture_output=True, text=True)
    out = r.stdout + r.stderr
    proved = re.search(r"All (\d+) obligations? proved", out)
    check(r.returncode == 0 and proved is not None,
          f"tlapm, run directly in {image.group(0)[-71:]}, proves the module"
          + (f" ({proved.group(1)} obligations)" if proved else ""))
    if not proved:
        print(out[-2000:])

print("agent-repair: " + ("every check passed" if not failures else f"{len(failures)} failed"))
sys.exit(1 if failures else 0)
