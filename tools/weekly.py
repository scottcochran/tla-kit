#!/usr/bin/env python3
"""The weekly check of upstream (ADR-0013 items 4, 5, 7 and 8). It reports, and moves nothing.

    tools/weekly.py [--scan FILE] > report.md

For each pin in PINS.json it asks upstream, and prints one Markdown report:
  - whether upstream still serves the pinned value as pinned: the jar and the TLAPS tarball are downloaded and
    their sha256 compared, the base's digest is looked up in its registry, and the apt snapshot's index fetched;
  - whether the kept copy of the TLAPS tarball is still in this repository's release, with its sha256;
  - a new tla2tools.jar release, a change to what the tlapm tag serves, and a new digest behind the base's tag;
  - how long ago the runtime pins were taken, against the 90-day refresh (ADR-0013 item 5);
  - each project's tla-kit pin, from the file CONSUMERS.md names for it (ADR-0014 item 6);
  - with --scan, the vulnerability scan of the current release.
A change in what upstream serves is a served-state change: the report gives the entry to add to the pin's served
log, by a pull request that moves nothing (ADR-0013 item 7). Needs `gh` (authenticated), `docker buildx` and
network access. Exits 0 whatever it finds, and non-zero only if it could not run.
"""
import datetime
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TODAY = datetime.date.today()
UA = {"User-Agent": "tla-kit-weekly-check"}


def sh(*cmd):
    p = subprocess.run(cmd, capture_output=True, text=True)
    return p.returncode, p.stdout.strip(), p.stderr.strip()


def fetch_sha256(url):
    """(status, sha256) of what url serves now; status is 'ok', or the HTTP error."""
    try:
        with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=300) as r:
            h = hashlib.sha256()
            for chunk in iter(lambda: r.read(1 << 20), b""):
                h.update(chunk)
            return "ok", h.hexdigest()
    except urllib.error.HTTPError as e:
        return f"HTTP {e.code}", None
    except OSError as e:
        return f"error: {e}", None


def reachable(url):
    try:
        with urllib.request.urlopen(urllib.request.Request(url, headers=UA, method="HEAD"), timeout=60) as r:
            return f"HTTP {r.status}"
    except urllib.error.HTTPError as e:
        return f"HTTP {e.code}"
    except OSError as e:
        return f"error: {e}"


def pdate(s):
    return datetime.date(*map(int, s.split(".")))


def served_line(pin, now_served, name, value):
    last = pin["served"][-1]
    if bool(last["upstream"]) == now_served:
        return f"no change since {last['from']} ({'served' if now_served else 'not served'})", None
    entry = {"from": TODAY.strftime("%Y.%m.%d"), name: value, "upstream": now_served}
    return "**changed**: " + ("served again" if now_served else "upstream no longer serves it"), entry


def main(argv):
    scan = argv[argv.index("--scan") + 1] if "--scan" in argv else None
    pins = {p["tool"]: p for p in json.load(open(os.path.join(ROOT, "PINS.json")))["pins"]}
    out, entries, moves = [], [], []
    out.append(f"## Weekly check, {TODAY.strftime('%Y.%m.%d')}\n")
    out.append("| Pin | Pinned value | What upstream serves now | Served log |")
    out.append("|---|---|---|---|")

    jar = pins["tla2tools.jar"]
    status, got = fetch_sha256(jar["upstream"])
    ok = status == "ok" and got == jar["download_sha256"]
    note = "the same bytes" if ok else (f"{status}" if status != "ok" else f"**different bytes**, sha256 {got}")
    line, e = served_line(jar, ok, "sha256", jar["download_sha256"])
    out.append(f"| tla2tools.jar | {jar['version']}, `{jar['download_sha256'][:12]}` | {note} | {line} |")
    if e:
        entries.append(("tla2tools.jar", e))
    code, latest, _ = sh("gh", "api", "repos/tlaplus/tlaplus/releases/latest", "-q", ".tag_name")
    if code == 0 and latest and latest != jar["version"]:
        moves.append(f"A new tla2tools.jar release: {latest} (pinned {jar['version']}). A checker move, by its own pull request.")

    tl = pins["tlapm"]
    status, got = fetch_sha256(tl["upstream"])
    ok = status == "ok" and got == tl["download_sha256"]
    note = "the same bytes" if ok else (f"{status}" if status != "ok" else f"**different bytes**, sha256 {got}")
    line, e = served_line(tl, ok, "sha256", tl["download_sha256"])
    out.append(f"| tlapm | {tl['version']}, `{tl['download_sha256'][:12]}` | {note} | {line} |")
    if e:
        entries.append(("tlapm", e))
    if status == "ok" and not ok:
        moves.append(f"The `{tl['set_by']['TLAPM_TAG']}` tag now serves a different build (sha256 {got}). A prover move "
                     "needs its own kept release first (ADR-0005 item 2), then a pull request with ADR-0005 item 4's runs.")
    with tempfile.TemporaryDirectory() as d:
        code, _, err = sh("gh", "release", "download", tl["kept_release"], "--pattern",
                          os.path.basename(tl["kept_copy"]), "--dir", d)
        if code == 0:
            h = hashlib.sha256(open(os.path.join(d, os.path.basename(tl["kept_copy"])), "rb").read()).hexdigest()
            kept = "the same bytes" if h == tl["download_sha256"] else f"**different bytes**, sha256 {h}"
        else:
            kept = f"**missing**: {err.splitlines()[-1] if err else 'not found'}"
    out.append(f"| tlapm, the kept copy | release `{tl['kept_release']}` | {kept} | kept here; no log |")

    base = pins["base"]
    r = base["resolved"]
    code, _, err = sh("docker", "buildx", "imagetools", "inspect", f"{r['tag'].split(':')[0]}@{r['digest']}")
    ok = code == 0
    line, e = served_line(base, ok, "sha256", r["digest"].split(":", 1)[1])
    out.append(f"| base | `{r['digest'][:19]}` ({r['platform']}) | {'served' if ok else '**not served**: ' + err[:80]} | {line} |")
    if e:
        entries.append(("base", e))
    code, raw, _ = sh("docker", "buildx", "imagetools", "inspect", "--raw", r["tag"])
    if code == 0:
        idx = json.loads(raw)
        now = next((m["digest"] for m in idx.get("manifests", [])
                    if m.get("platform", {}).get("os") == "linux" and m.get("platform", {}).get("architecture") == "amd64"),
                   None)
        if now and now != r["digest"]:
            moves.append(f"A new digest behind `{r['tag']}`: `{now}` (pinned `{r['digest']}`). A runtime refresh, "
                         "with the apt snapshot, by one pull request (ADR-0013 item 2).")

    apt = pins["apt"]
    snap = apt["set_by"]["APT_SNAPSHOT"]
    st = reachable(f"https://snapshot.ubuntu.com/ubuntu/{snap}/dists/noble/InRelease")
    ok = st == "HTTP 200"
    line, e = served_line(apt, ok, "snapshot", snap)
    out.append(f"| apt | snapshot `{snap}` | {'served' if ok else '**not served**: ' + st} | {line} |")
    if e:
        entries.append(("apt", e))

    age = (TODAY - pdate(base["pinned"]["date"])).days
    out.append("")
    out.append(f"The runtime pins were taken on {base['pinned']['date']}, {age} day{'' if age == 1 else 's'} ago. A refresh is due at 90 days "
               "if the base or the snapshot has moved, and at once for a critical vulnerability with a fix available "
               "in a package the image uses (ADR-0013 item 5).")

    out.append("\n### Moves upstream offers\n")
    out += [f"- {m}" for m in moves] or ["None."]
    out.append("\n### Served-state changes\n")
    if entries:
        out.append("Add each entry to its pin's `served` log in PINS.json, by a pull request that moves nothing. "
                   "If the pin has moved since, close the pull request with nothing filed (ADR-0013 item 7).\n")
        for tool, e in entries:
            out.append(f"- {tool}: `{json.dumps(e)}`")
    else:
        out.append("None: every pinned value is served as it was.")

    out.append("\n### Projects' pins (CONSUMERS.md)\n")
    out += consumers()

    out.append("\n### Vulnerability scan of the current release\n")
    if scan and os.path.isfile(scan):
        with open(scan, encoding="utf-8") as f:
            out.append("```\n" + f.read().strip()[-6000:] + "\n```")
    else:
        out.append("Not run: no release has been published yet.")
    print("\n".join(out))
    return 0


def consumers():
    lines = []
    path = os.path.join(ROOT, "CONSUMERS.md")
    rows = re.findall(r"^\| \[([^\]]+)\]\(https://github\.com/([^)]+)\) \| `([^`]+)` \|", open(path).read(), re.M)
    for name, repo, pinfile in rows:
        code, body, err = sh("gh", "api", f"repos/{repo}/contents/{pinfile}", "-H", "Accept: application/vnd.github.raw")
        if code == 0:
            digest = re.search(r"sha256:[0-9a-f]{64}", body)
            lines.append(f"- {name}: `{pinfile}` names {('`' + digest.group(0) + '`') if digest else 'no digest'}")
        else:
            lines.append(f"- {name}: no `{pinfile}` readable ({'private or absent' if '404' in err else err[:60]})")
    return lines or ["No project is listed."]


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
