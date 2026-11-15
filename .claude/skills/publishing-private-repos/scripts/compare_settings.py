#!/usr/bin/env python3
"""compare_settings.py   where a repository's settings differ from the baseline

Usage: compare_settings.py <baseline.json> <snapshot.json>

Both files have the shape snapshot_settings.sh prints. Reports every setting that differs, every ruleset that is
missing, extra or different (rulesets are matched by name), and every setting either side could not read. Exits 0
when nothing differs, 1 when something does. An unreadable value is reported, never counted as a match.
"""
import json
import sys


def flat(d, prefix=""):
    out = {}
    for k, v in (d or {}).items():
        key = f"{prefix}{k}"
        if isinstance(v, dict):
            out.update(flat(v, key + "."))
        else:
            out[key] = v
    return out


def main():
    if len(sys.argv) != 3:
        print(__doc__.strip().splitlines()[2], file=sys.stderr)
        return 2
    base, snap = (json.load(open(p)) for p in sys.argv[1:])
    diffs, unknown = [], []

    for section in ("repo", "security"):
        b, s = flat(base.get(section)), flat(snap.get(section))
        for k in sorted(set(b) | set(s)):
            bv, sv = b.get(k), s.get(k)
            if bv is None or sv is None:
                if bv != sv:
                    unknown.append(f"{section}.{k}: baseline {json.dumps(bv)}, target {json.dumps(sv)}")
            elif bv != sv:
                diffs.append(f"{section}.{k}: baseline {json.dumps(bv)}, target {json.dumps(sv)}")

    if base.get("default_branch") != snap.get("default_branch"):
        diffs.append(f"default_branch: baseline {base.get('default_branch')}, target {snap.get('default_branch')} "
                     "(rulesets use ~DEFAULT_BRANCH, so they follow whichever it is)")

    br = {r["name"]: r for r in base.get("rulesets", [])}
    sr = {r["name"]: r for r in snap.get("rulesets", [])}
    for name in sorted(set(br) | set(sr)):
        if name not in sr:
            diffs.append(f"ruleset '{name}': missing on target")
        elif name not in br:
            diffs.append(f"ruleset '{name}': on target only (left alone; the custodian decides)")
        elif br[name] != sr[name]:
            for k in ("target", "enforcement", "conditions", "rules", "bypass_actors"):
                if br[name].get(k) != sr[name].get(k):
                    diffs.append(f"ruleset '{name}'.{k}: baseline {json.dumps(br[name].get(k))}, "
                                 f"target {json.dumps(sr[name].get(k))}")

    bu, su = set(base.get("unreadable", [])), set(snap.get("unreadable", []))
    for p in sorted(bu | su):
        sides = " and ".join(n for n, u in (("baseline", bu), ("target", su)) if p in u)
        unknown.append(f"{p}: unreadable on {sides}; compare it by hand in each repository's Settings")

    print(f"baseline {base.get('source')} ({base.get('captured')})  vs  target {snap.get('source')} "
          f"({snap.get('visibility')}, {snap.get('captured')})")
    if diffs:
        print("\nDIFFERS:")
        print("\n".join(f"  {x}" for x in diffs))
    if unknown:
        print("\nNOT COMPARED (one side could not be read):")
        print("\n".join(f"  {x}" for x in sorted(set(unknown))))
    if not diffs:
        print("\nok: every readable setting and ruleset matches the baseline")
    return 1 if diffs else 0


if __name__ == "__main__":
    sys.exit(main())
