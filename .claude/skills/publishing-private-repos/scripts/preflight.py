#!/usr/bin/env python3
"""preflight.py   what making a repository public would publish that nobody meant to

Usage: preflight.py <path to a clone> [--accept REGEX ...]
       (run it on a fresh `git clone --mirror`, so every ref is in it)

--accept REGEX drops SECRETS and PATHS findings whose line matches REGEX. Use it only for a finding the custodian has
looked at and ruled harmless, and say which in the report; it is never a way to get a clean run.

Going public publishes every reachable commit on every branch and tag, and every pull request's commits (GitHub
keeps them under refs/pull/*), not just the default branch's tip. A secret removed in a later commit is still public.
So this reads all of history. It changes nothing.

Reports, in order:
  SECRETS    added lines anywhere in history that look like credentials (masked); gitleaks is used instead if installed
  PATHS      files ever committed whose names say they should not be public (keys, env files, PDFs, archives, exports)
  LARGE      blobs over 50 MB
  SUBMODULES .gitmodules entries, each of which must itself be public or the checkout breaks for everyone
  IDENTITIES every distinct author and committer email in history: they become public with the commits
  FILES      LICENSE, README, SECURITY.md and CODEOWNERS at HEAD (the baseline's code-owner review needs CODEOWNERS)
  REFS       how many branches, tags and pull-request refs will become visible

Exits 1 if SECRETS, PATHS or FILES found anything, 0 otherwise. IDENTITIES, LARGE, SUBMODULES and REFS are for the
custodian to read, not failures.
"""
import os
import re
import shutil
import subprocess
import sys

SECRET_PATTERNS = [
    ("aws-access-key", r"AKIA[0-9A-Z]{16}"),
    ("github-token", r"\b(?:ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{36}\b"),
    ("github-fine-grained-pat", r"\bgithub_pat_[A-Za-z0-9_]{60,}"),
    ("anthropic-key", r"\bsk-ant-[A-Za-z0-9_-]{20,}"),
    ("openai-style-key", r"\bsk-(?:proj-)?[A-Za-z0-9_-]{32,}"),
    ("slack-token", r"\bxox[abposr]-[A-Za-z0-9-]{10,}"),
    ("private-key-block", r"-----BEGIN (?:[A-Z]+ )?PRIVATE KEY-----"),
    ("google-api-key", r"\bAIza[0-9A-Za-z_-]{35}\b"),
    ("gitlab-token", r"\bglpat-[A-Za-z0-9_-]{20,}"),
    ("npm-token", r"\bnpm_[A-Za-z0-9]{36}\b"),
    ("credential-assignment",
     r"(?i)\b(?:password|passwd|secret|api[_-]?key|access[_-]?token|auth[_-]?token)\b\s*[:=]\s*['\"][^'\"\s]{8,}['\"]"),
]
SENSITIVE_PATHS = [
    r"(^|/)\.env(\.|$)", r"\.pem$", r"\.key$", r"\.p12$", r"\.pfx$", r"(^|/)id_(rsa|dsa|ecdsa|ed25519)$",
    r"(^|/)\.npmrc$", r"(^|/)\.pypirc$", r"(^|/)credentials(\.json)?$", r"\.kdbx$",
    # TOPAK's .gitignore names these as not ours to redistribute, or as chat exports that never belong in the corpus
    r"\.pdf$", r"\.zip$", r"(^|/)doc/", r"(^|/)sessions/", r"(^|/)cloud\.ai\.exports/",
]
REQUIRED = {
    "LICENSE": ["LICENSE", "LICENSE.md", "LICENSE.txt"],
    "README": ["README.md", "README", "README.rst"],
    "SECURITY.md": ["SECURITY.md", ".github/SECURITY.md", "docs/SECURITY.md"],
    "CODEOWNERS": ["CODEOWNERS", ".github/CODEOWNERS", "docs/CODEOWNERS"],
}
LARGE = 50 * 1024 * 1024


def git(repo, *args):
    return subprocess.run(["git", "-C", repo, *args], check=True, capture_output=True, text=True,
                          errors="replace").stdout


def mask(s):
    return s[:6] + "…" + f"({len(s)} chars)"


def scan_secrets(repo):
    if shutil.which("gitleaks"):
        r = subprocess.run(["gitleaks", "git", "--redact", "--no-banner", "-v", repo], capture_output=True, text=True)
        out = (r.stdout + r.stderr).strip()
        return ([f"gitleaks: {line}" for line in out.splitlines() if line.strip()] if r.returncode else []), "gitleaks"
    pats = [(n, re.compile(p)) for n, p in SECRET_PATTERNS]
    hits, seen = [], set()
    proc = subprocess.Popen(["git", "-C", repo, "log", "--all", "-p", "--no-color", "--no-ext-diff",
                             "--format=commit %H"], stdout=subprocess.PIPE, text=True, errors="replace")
    commit = path = None
    for line in proc.stdout:
        if line.startswith("commit "):
            commit = line.split()[1][:12]
        elif line.startswith("+++ "):
            path = line[6:].rstrip("\n") if line.startswith("+++ b/") else None
        elif line.startswith("+") and path:
            for name, rx in pats:
                m = rx.search(line)
                if m:
                    key = (name, path, m.group(0))
                    if key not in seen:
                        seen.add(key)
                        hits.append(f"{name}: {path} @ {commit}: {mask(m.group(0))}")
    proc.wait()
    return hits, "built-in patterns (text diffs only; install gitleaks for binaries and more rules)"


def main():
    args, accept = sys.argv[1:], []
    while "--accept" in args:
        i = args.index("--accept")
        if i + 1 >= len(args):
            print("--accept needs a REGEX", file=sys.stderr)
            return 2
        accept.append(re.compile(args[i + 1]))
        del args[i:i + 2]
    if len(args) != 1:
        print("usage: preflight.py <path to a clone> [--accept REGEX ...]", file=sys.stderr)
        return 2
    repo = args[0]
    accepted = lambda line: any(a.search(line) for a in accept)
    git(repo, "rev-parse", "--git-dir")
    status = 0

    secrets, how = scan_secrets(repo)
    n_acc = sum(map(accepted, secrets))
    secrets = [h for h in secrets if not accepted(h)]
    print(f"SECRETS ({how}): {len(secrets)}" + (f"  ({n_acc} accepted by --accept)" if n_acc else ""))
    for h in secrets:
        print(f"  {h}")
    status |= bool(secrets)

    rx = re.compile("|".join(SENSITIVE_PATHS), re.I)
    every_path = set(git(repo, "log", "--all", "--format=", "--name-only", "--diff-filter=AMR").split("\n")) - {""}
    flagged = sorted(p for p in every_path if rx.search(p))
    p_acc = sum(map(accepted, flagged))
    flagged = [p for p in flagged if not accepted(p)]
    print(f"\nPATHS ever committed that should not be public: {len(flagged)}"
          + (f"  ({p_acc} accepted by --accept)" if p_acc else ""))
    by_dir = {}
    for p in flagged:
        by_dir.setdefault(os.path.dirname(p) or ".", []).append(p)
    for d, ps in sorted(by_dir.items()):
        if len(ps) > 5:
            print(f"  {d}/: {len(ps)} files ({os.path.basename(ps[0])} … {os.path.basename(ps[-1])})")
        else:
            print("\n".join(f"  {p}" for p in ps))
    status |= bool(flagged)

    large = []
    objs = git(repo, "rev-list", "--all", "--objects")
    batch = subprocess.run(["git", "-C", repo, "cat-file", "--batch-check=%(objecttype) %(objectsize) %(rest)"],
                           input=objs, capture_output=True, text=True).stdout
    for line in batch.splitlines():
        t, size, *rest = line.split(" ", 2) + [""]
        if t == "blob" and int(size) > LARGE:
            large.append(f"{int(size) // (1024 * 1024)} MB  {rest[0]}")
    print(f"\nLARGE blobs over 50 MB: {len(large)}")
    for x in large:
        print(f"  {x}")

    try:
        mods = git(repo, "config", "--blob", "HEAD:.gitmodules", "--get-regexp", r"submodule\..*\.url").strip()
    except subprocess.CalledProcessError:
        mods = ""
    print(f"\nSUBMODULES: {len(mods.splitlines()) if mods else 0}")
    for m in mods.splitlines():
        print(f"  {m}")

    ids = sorted(set(git(repo, "log", "--all", "--format=%an <%ae>%n%cn <%ce>").splitlines()) - {""})
    print(f"\nIDENTITIES that become public with the history: {len(ids)}")
    for i in ids:
        print(f"  {i}")

    head = set(git(repo, "ls-tree", "-r", "--name-only", "HEAD").splitlines())
    missing = [k for k, names in REQUIRED.items() if not any(n in head for n in names)]
    print(f"\nFILES at HEAD: {'missing ' + ', '.join(missing) if missing else 'LICENSE, README, SECURITY.md, CODEOWNERS present'}")
    status |= bool(missing)

    refs = git(repo, "for-each-ref", "--format=%(refname)").splitlines()
    count = lambda pre: sum(r.startswith(pre) for r in refs)
    heads = count("refs/heads/") + count("refs/remotes/origin/") - (1 if "refs/remotes/origin/HEAD" in refs else 0)
    print(f"\nREFS that become visible: {heads} branches, {count('refs/tags/')} tags, "
          f"{count('refs/pull/')} pull-request refs")
    if not count("refs/pull/") and not os.path.isfile(os.path.join(repo, "packed-refs")) and count("refs/remotes/"):
        print("  (no refs/pull/*: this looks like an ordinary clone; `git clone --mirror` to see pull-request history)")

    print("\n" + ("STOP: resolve the findings above before any visibility change" if status
                  else "ok: nothing found that blocks going public"))
    return 1 if status else 0


if __name__ == "__main__":
    sys.exit(main())
