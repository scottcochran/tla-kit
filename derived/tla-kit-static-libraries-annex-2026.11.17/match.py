#!/usr/bin/env python3
"""Which release of a static library is linked into an executable?

    match.py BINARY NAME=ARCHIVE.a [NAME=ARCHIVE.a ...]

Each ARCHIVE is one candidate release of the same library (for example glibc's libc.a from each Ubuntu
libc6-dev). For every executable section of every member, the code is read with each relocated field masked
(the linker fills those in, so they differ in the binary), and with the instruction bytes a GOT or TLS
relaxation may rewrite masked too. A section counts as present when its masked code occurs in the binary's
executable sections.

Prints, for each candidate, how many of its sections are present; then, for every section whose code differs
between candidates, which candidates' code is present; and the candidates consistent with all of them.
Standard library only.
"""
import collections, hashlib, struct, sys

MIN_ANCHOR = 24          # bytes of unmasked code needed to search for a section
SIZES = {1: 8, 2: 4, 4: 4, 9: 4, 10: 4, 11: 4, 22: 4, 23: 4, 24: 8, 26: 4, 41: 4, 42: 4}
RELAXED = {9: 3, 22: 3, 41: 3, 42: 3}   # bytes before the field the linker may rewrite


def ar_members(path):
    d = open(path, "rb").read()
    assert d[:8] == b"!<arch>\n", path
    i, longnames = 8, b""
    while i < len(d):
        h = d[i:i + 60]
        name, size = h[:16].decode().strip(), int(h[48:58])
        body = d[i + 60:i + 60 + size]
        if name == "//":
            longnames = body
        elif name not in ("/", "/SYM64/"):
            if name.startswith("/") and name[1:].isdigit():
                off = int(name[1:])
                name = longnames[off:longnames.index(b"/\n", off)].decode()
            yield name.rstrip("/"), body
        i += 60 + size + (size & 1)


def sections(d):
    shoff, = struct.unpack_from("<Q", d, 0x28)
    shentsize, shnum, shstrndx = struct.unpack_from("<HHH", d, 0x3A)
    secs = [struct.unpack_from("<IIQQQQIIQQ", d, shoff + k * shentsize) for k in range(shnum)]
    so = secs[shstrndx][4]
    out = []
    for s in secs:
        name = d[so + s[0]:d.index(b"\0", so + s[0])].decode()
        out.append(dict(name=name, type=s[1], flags=s[2], off=s[4], size=s[5], info=s[7]))
    return out


def object_code(d):
    """Yield (section name, code, mask) for each executable section of a relocatable object."""
    if d[:4] != b"\x7fELF" or d[4] != 2:
        return
    secs = sections(d)
    masks = {k: bytearray(s["size"]) for k, s in enumerate(secs) if s["type"] == 1 and s["flags"] & 4}
    for s in secs:
        if s["type"] == 4 and s["info"] in masks:               # SHT_RELA for an executable section
            m = masks[s["info"]]
            for k in range(s["size"] // 24):
                r_off, r_info, _ = struct.unpack_from("<QQq", d, s["off"] + 24 * k)
                t = r_info & 0xffffffff
                lo, hi = r_off - RELAXED.get(t, 0), r_off + SIZES.get(t, 4)
                for b in range(max(lo, 0), min(hi, len(m))):
                    m[b] = 1
    for k, m in masks.items():
        s = secs[k]
        if s["size"]:
            yield s["name"], d[s["off"]:s["off"] + s["size"]], bytes(m)


def anchor(code, mask):
    best, start = (0, 0), None
    for b in range(len(code) + 1):
        if b < len(code) and not mask[b]:
            start = b if start is None else start
        elif start is not None:
            best = max(best, (b - start, start))
            start = None
    return best   # (length, start)


def present(text, code, mask):
    n, a = anchor(code, mask)
    if n < MIN_ANCHOR:
        return None
    needle = code[a:a + n]
    i = text.find(needle)
    while i >= 0:
        base = i - a
        if base >= 0 and base + len(code) <= len(text):
            seg = text[base:base + len(code)]
            if all(mask[b] or seg[b] == code[b] for b in range(len(code))):
                return True
        i = text.find(needle, i + 1)
    return False


def key(code, mask):
    return hashlib.sha256(bytes(0 if m else c for c, m in zip(code, mask)) + mask).hexdigest()[:16]


binary = open(sys.argv[1], "rb").read()
text = b"".join(binary[s["off"]:s["off"] + s["size"]] for s in sections(binary) if s["type"] == 1 and s["flags"] & 4)
cands = [a.split("=", 1) for a in sys.argv[2:]]
variants = collections.defaultdict(dict)        # (member, section) -> {candidate: (key, code, mask)}
for name, path in cands:
    for member, body in ar_members(path):
        for sec, code, mask in object_code(body):
            variants[(member, sec)][name] = (key(code, mask), code, mask)

checked = {}                                    # key -> present?
def is_present(v):
    if v[0] not in checked:
        checked[v[0]] = present(text, v[1], v[2])
    return checked[v[0]]

print(f"binary {sys.argv[1]}: {len(text)} bytes of code")
for name, _ in cands:
    secs = [vs[name] for vs in variants.values() if name in vs]
    found = [s for s in secs if is_present(s)]
    testable = [s for s in secs if is_present(s) is not None]
    print(f"  {name}: {len(found)} of {len(testable)} searchable sections present ({len(secs)} sections)")

consistent = {name for name, _ in cands}
print("sections whose code differs between candidates, and whose code is present:")
for k in sorted(variants):
    vs = variants[k]
    if len({v[0] for v in vs.values()}) < 2:
        continue
    hits = sorted((n for n, v in vs.items() if is_present(v)), key=[c[0] for c in cands].index)
    if any(is_present(v) is None for v in vs.values()) or not hits:
        continue
    consistent &= set(hits)
    groups = collections.OrderedDict()
    for n, _ in cands:
        if n in vs:
            groups.setdefault(vs[n][0], []).append(n)
    print(f"  {k[0]} {k[1]}: present = {' '.join(hits)}")
    print(f"      variants: {' | '.join(','.join(g) for g in groups.values())}")
print("consistent with every differing section present: " + " ".join(n for n, _ in cands if n in consistent))
