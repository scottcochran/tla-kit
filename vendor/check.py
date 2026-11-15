#!/usr/bin/env python3
"""Check vendored files against their pin (ADR-0007 item 3).

    vendor/check.py [--upstream GIT_DIR]

For every vendor/<name>/VENDOR-PIN:

  - every `file <sha256> <path>` line names a file that exists and has that sha256;
  - no other file is in vendor/<name>/ besides VENDOR-PIN;
  - with --upstream, a git checkout of the pin's `source` that has fetched its `commit`: each file is byte for byte
    the file at `<commit>:<path>/<file>`, and no file upstream, in a directory the pin vendors, is left out.

Prints one line per vendored directory and exits non-zero on any difference. Changes nothing.
"""
import argparse
import hashlib
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


def read_pin(path):
    fields, files = {}, {}
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            key, _, rest = line.partition(" ")
            if key == "file":
                digest, _, name = rest.partition(" ")
                files[name] = digest
            else:
                fields[key] = rest
    return fields, files


def git(upstream, *args):
    return subprocess.run(["git", "-C", upstream, *args], check=True, capture_output=True).stdout


def check(vdir, upstream):
    problems = []
    fields, files = read_pin(os.path.join(vdir, "VENDOR-PIN"))
    for name, digest in files.items():
        path = os.path.join(vdir, name)
        if not os.path.isfile(path):
            problems.append(f"{name}: missing")
            continue
        with open(path, "rb") as f:
            if hashlib.sha256(f.read()).hexdigest() != digest:
                problems.append(f"{name}: sha256 differs from VENDOR-PIN")
    for root, _, names in os.walk(vdir):
        for n in names:
            rel = os.path.relpath(os.path.join(root, n), vdir)
            if rel != "VENDOR-PIN" and rel not in files:
                problems.append(f"{rel}: not in VENDOR-PIN")
    if upstream:
        commit, base = fields.get("commit"), fields.get("path", "").strip("/")
        try:
            git(upstream, "cat-file", "-e", f"{commit}^{{commit}}")
        except subprocess.CalledProcessError:
            return [f"{upstream} does not have commit {commit}; fetch it first"]
        for name in files:
            try:
                blob = git(upstream, "show", f"{commit}:{base}/{name}")
            except subprocess.CalledProcessError:
                problems.append(f"{name}: not at {commit[:12]}:{base}")
                continue
            with open(os.path.join(vdir, name), "rb") as f:
                if f.read() != blob:
                    problems.append(f"{name}: differs from {commit[:12]}")
        dirs = sorted({os.path.dirname(n) for n in files})
        listed = git(upstream, "ls-tree", "-r", "--name-only", commit, "--", *[f"{base}/{d}" for d in dirs]).decode()
        for line in listed.splitlines():
            rel = os.path.relpath(line, base)
            if rel not in files:
                problems.append(f"{rel}: upstream at {commit[:12]} and not vendored")
    return problems


def main(argv):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--upstream", metavar="GIT_DIR")
    a = ap.parse_args(argv)
    vdirs = sorted(os.path.join(HERE, d) for d in os.listdir(HERE)
                   if os.path.isfile(os.path.join(HERE, d, "VENDOR-PIN")))
    if not vdirs:
        print("no vendor/*/VENDOR-PIN")
        return 1
    bad = 0
    for vdir in vdirs:
        fields, files = read_pin(os.path.join(vdir, "VENDOR-PIN"))
        problems = check(vdir, a.upstream)
        where = f"{fields.get('source')} at {fields.get('commit', '?')[:12]}"
        if problems:
            bad += 1
            print(f"{os.path.basename(vdir)}: {len(problems)} problem(s) against {where}")
            print("\n".join(f"  {p}" for p in problems))
        else:
            how = "and upstream" if a.upstream else "(not compared with upstream)"
            print(f"{os.path.basename(vdir)}: {len(files)} files match VENDOR-PIN {how}, {where}")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
