#!/usr/bin/env python3 -I
# tla-kit experiment 2026.11.21: compare the legs. Reads logs/<leg>/summary.tsv and keep/<leg>/calls.tsv.
import collections, os, statistics, sys
S = "/private/tmp/claude-501/-Users-scott-dev-sandbox-tla-kit/90e76ea0-1116-4f6a-9c5c-54e6b0824870/scratchpad"
legs = sys.argv[1:] or sorted(d for d in os.listdir(f"{S}/logs") if os.path.isdir(f"{S}/logs/{d}") and d[:1] in "ABC")

def summary(leg):
    rows = {}
    p = f"{S}/logs/{leg}/summary.tsv"
    if not os.path.exists(p): return rows
    for line in open(p).read().splitlines()[1:]:
        m, want, got, secs, verdict = line.split("\t")
        rows[m] = (want, got, float(secs), verdict)
    return rows

def calls(leg):
    p = f"{S}/keep/{leg}/calls.tsv"
    out = []
    if not os.path.exists(p): return out
    for line in open(p).read().splitlines():
        n, secs, code, first, size, h = line.split("\t")
        if int(size) == 0: continue  # -version calls
        v = first if first in ("unsat", "sat", "unknown") else ("killed" if code == "-9" else f"other:{first[:20]}")
        out.append((h, float(secs), v, int(size), n))
    return out

sums = {l: summary(l) for l in legs}
mods = sorted(set().union(*[s.keys() for s in sums.values()]))
print("## Modules: obligations proved and wall seconds per leg\n")
print("| module | committed | " + " | ".join(f"{l} obl | {l} s" for l in legs) + " |")
print("|---|---|" + "---|---|" * len(legs))
tot = {l: 0.0 for l in legs}
for m in mods:
    cells = []
    want = "-"
    for l in legs:
        r = sums[l].get(m)
        if r:
            want = r[0]; cells += [f"{r[1]}{'' if r[3] in ('SAME','NO BASELINE') else ' **'+r[3]+'**'}", f"{r[2]:.1f}"]; tot[l] += r[2]
        else: cells += ["-", "-"]
    print(f"| {m} | {want} | " + " | ".join(cells) + " |")
print("| **total** | | " + " | ".join(f" | **{tot[l]:.0f}**" for l in legs) + " |")

C = {l: calls(l) for l in legs}
print("\n## Z3 calls per leg (from the sidecar's log; -version calls excluded)\n")
print("| leg | calls | unsat | killed at budget | unknown | sat | other | z3 CPU-ish s (sum) | median s | p90 s | max s |")
print("|---|---|---|---|---|---|---|---|---|---|---|")
for l in legs:
    c = C[l]
    if not c: continue
    cnt = collections.Counter(v for _, _, v, _, _ in c)
    ts = sorted(t for _, t, _, _, _ in c)
    print(f"| {l} | {len(c)} | {cnt['unsat']} | {cnt['killed']} | {cnt['unknown']} | {cnt['sat']} | {sum(n for k,n in cnt.items() if k.startswith('other'))} | {sum(ts):.1f} | {statistics.median(ts):.3f} | {ts[int(len(ts)*0.9)]:.3f} | {ts[-1]:.2f} |")

# join by obligation hash
withcalls = [l for l in legs if C[l]]
if len(withcalls) >= 2:
    by = {l: collections.defaultdict(list) for l in withcalls}
    for l in withcalls:
        for h, t, v, sz, n in C[l]: by[l][h].append((t, v, n))
    allh = set().union(*[set(by[l]) for l in withcalls])
    common = [h for h in allh if all(h in by[l] for l in withcalls)]
    print(f"\n## Obligations by SMT-LIB content hash\n\n{len(allh)} distinct files in all; {len(common)} seen in every leg.")
    for l in withcalls:
        only = [h for h in allh if h in by[l] and any(h not in by[k] for k in withcalls)]
        print(f"- {l}: {len(by[l])} distinct, {len(only)} not in every other leg")
    print("\n### Verdict differences on common obligations\n")
    diffs = []
    for h in common:
        vs = {l: sorted(v for _, v, _ in by[l][h]) for l in withcalls}
        if len({tuple(x) for x in vs.values()}) > 1:
            diffs.append((h, vs))
    print(f"{len(diffs)} obligations whose verdicts differ between legs.\n")
    if diffs:
        print("| hash | " + " | ".join(withcalls) + " | ids |")
        print("|---|" + "---|" * (len(withcalls) + 1))
        for h, vs in sorted(diffs)[:60]:
            ids = "; ".join(f"{l}:" + ",".join(n for _, _, n in by[l][h]) for l in withcalls)
            print(f"| {h} | " + " | ".join(",".join(f"{v} {t:.2f}s" for t, v, _ in by[l][h]) for l in withcalls) + f" | {ids} |")
    print("\n### Time on common obligations proved (unsat) by every leg\n")
    allunsat = [h for h in common if all(all(v == "unsat" for _, v, _ in by[l][h]) for l in withcalls)]
    print(f"{len(allunsat)} obligations unsat in every leg.\n")
    print("| leg | sum s | median s | p90 s | max s |")
    print("|---|---|---|---|---|")
    for l in withcalls:
        ts = sorted(min(t for t, _, _ in by[l][h]) for h in allunsat)
        print(f"| {l} | {sum(ts):.1f} | {statistics.median(ts):.3f} | {ts[int(len(ts)*0.9)]:.3f} | {ts[-1]:.2f} |")
    if len(withcalls) >= 2:
        a, *rest = withcalls
        for b in rest:
            r = [min(t for t,_,_ in by[b][h]) / max(1e-4, min(t for t,_,_ in by[a][h])) for h in allunsat]
            print(f"\n{b} / {a} per-obligation time ratio: median {statistics.median(r):.2f}, geometric-mean-ish (median of log) ; faster in {sum(1 for x in r if x < 1)} of {len(r)}")
