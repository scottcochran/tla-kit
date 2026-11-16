#!/usr/bin/env python3
"""tla-kit's MCP server: the TLA+ tools in the image, offered to an agent over stdio (ADR-0008).

    tla-kit mcp                       as a client starts it, inside the image, with the project mounted at /work
    python3 server/tla_kit_mcp.py     natively, from a checkout, for development (the project is the working directory)

It speaks MCP's stdio transport itself, with the standard library only (ADR-0008 item 1): JSON-RPC 2.0, one message
per line on stdin and stdout, and nothing else on stdout. Logs go to stderr.

What it may write (ADR-0006):
  - `tlc_rows` runs the skill's generator, which writes its results file into the project exactly as it does from
    the command line. No other tool writes into the project.
  - Every other tool returns working output, labelled so. Scratch modules, configurations and TLC's state live in
    temporary directories the server owns, outside the project, and are removed after each call.

Every path a client sends is resolved against the project root (TLA_KIT_PROJECT, else /work when it exists, else the
working directory) and refused if it leads outside it, links included (ADR-0008 item 3).
"""
import json
import os
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import traceback
import xml.etree.ElementTree as ET

sys.dont_write_bytecode = True

HERE = os.path.dirname(os.path.abspath(__file__))
SKILL = os.environ.get("TLA_KIT_SKILL") or os.path.join(os.path.dirname(HERE), "vendor", "writing-tla-specs-and-proofs")
SCRIPTS = os.path.join(SKILL, "scripts")
sys.path.insert(0, SCRIPTS)
import tla_common as t  # noqa: E402  (the skill's library, ADR-0007)

SERVER_NAME = "tla-kit"
PROTOCOL_VERSIONS = ["2025-06-18", "2025-03-26", "2024-11-05"]  # newest first; the first is the one it speaks
DEFAULT_TIMEOUT = 600
WORKING = "working output: not a results file, and not evidence (ADR-0006)"


def project_root():
    root = os.environ.get("TLA_KIT_PROJECT") or ("/work" if os.path.isdir("/work") else os.getcwd())
    return os.path.realpath(root)


def server_version():
    try:
        for line in open("/opt/tla-kit/build-args", encoding="utf-8"):
            k, _, v = line.strip().partition(" ")
            if k == "revision":
                return v
    except OSError:
        pass
    return "dev"


class ToolError(Exception):
    """A refusal or a bad argument: returned to the client as a tool error, never raised to the transport."""


# ---------------------------------------------------------------------------------------------------------------
# Paths, processes, and the pieces shared by the TLC tools

def resolve(path, kind="file"):
    """A client's path, relative to the project root, as a real path inside it. Anything else is refused."""
    if not isinstance(path, str) or not path:
        raise ToolError("a path is required")
    root = project_root()
    real = os.path.realpath(os.path.join(root, path))
    if real != root and not real.startswith(root + os.sep):
        raise ToolError(f"{path} is outside the project ({root}); paths are confined to it")
    if kind == "file" and not os.path.isfile(real):
        raise ToolError(f"no file {path} in the project")
    return real


def module_path(arg):
    """(spec directory, module name) for a client's module argument, with or without .tla."""
    path = arg if arg.endswith(".tla") else arg + ".tla"
    real = resolve(path)
    return os.path.dirname(real), os.path.basename(real)[:-4]


def rel(real):
    return os.path.relpath(real, project_root())


def run(cmd, cwd, timeout, env=None):
    """(exit code, output) of cmd in its own process group, killed whole at the end or on timeout."""
    p = subprocess.Popen(cmd, cwd=cwd, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
                         start_new_session=True)
    try:
        out, _ = p.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        os.killpg(p.pid, signal.SIGKILL)
        p.communicate()
        raise ToolError(f"timed out after {timeout} s: {' '.join(cmd[:4])} ...")
    finally:
        try:
            os.killpg(p.pid, signal.SIGKILL)
        except (ProcessLookupError, PermissionError):
            pass
    return p.returncode, t.quiet(out or "")


def checker_for(spec_dir):
    """The pinned jar, found as the skill finds it (TLA_JAR, else tools/tla2tools.jar above the spec)."""
    try:
        return t.require_checker(t.Layout(spec_dir))
    except SystemExit as e:
        raise ToolError(str(e))


def java(checker, tmp, main, args):
    return ["java", "-XX:+UseParallelGC", f"-Xmx{os.environ.get('TLC_XMX', '2g')}", f"-Djava.io.tmpdir={tmp}",
            "-cp", checker.path, main] + args


def copy_chain(module, spec_dir, tmp):
    """Copy the module and every module of the spec directory it reaches into tmp: tools run on the copy."""
    for m in t.module_chain(module, spec_dir):
        shutil.copy(os.path.join(spec_dir, m + ".tla"), tmp)


def row_meta(module, spec_dir, rows=None):
    """The row list's `# const:` and `# cfg:` lines, found as tlc_run.py finds them, or none."""
    meta = {"const": [], "cfg": []}
    if rows:
        path = resolve(rows)
    else:
        path = None
        for cand in (os.path.join(spec_dir, f"{module}-rows.txt"),
                     os.path.join(spec_dir, "rows", f"{module}-rows.txt")):
            if os.path.exists(cand):
                path = cand
                break
    if path:
        try:
            meta, _ = t.parse_rows(path)
        except SystemExit as e:
            raise ToolError(str(e))
    return meta, (rel(path) if path else None)


def constants_of(meta, mut, constants):
    consts = dict(t.default_consts(meta))
    if mut and mut != "-":
        consts["Mut"] = f'"{mut}"'
    for k, v in (constants or {}).items():
        consts[str(k)] = str(v)
    return consts


def config(spec, consts, meta_cfg, cfg=(), constraint=None, invariants=(), properties=()):
    lines = [f"SPECIFICATION {spec}"]
    if consts:
        lines += ["CONSTANTS"] + [f"  {k} = {v}" for k, v in consts.items()]
    lines += list(meta_cfg) + list(cfg)
    if constraint:
        lines.append(f"CONSTRAINT {constraint}")
    lines += [f"INVARIANT {i}" for i in invariants] + [f"PROPERTY {p}" for p in properties]
    return "\n".join(lines) + "\n"


def pairs_of(constants, options):
    out = []
    for k, v in list((constants or {}).items()) + list((options or {}).items()):
        if v is None:
            continue
        if " " in str(v):
            raise ToolError(f"{k}={v}: a value passed to the skill's scripts may not contain spaces")
        out.append(f"{k}={v}")
    return out


def skill_script(name):
    return [sys.executable, "-B", os.path.join(SCRIPTS, name)]


# ---------------------------------------------------------------------------------------------------------------
# Reading TLC's and SANY's output

ACTION = re.compile(r"^<(\S+) line (\d+), col (\d+) to line (\d+), col (\d+) of module (\w+)>$")


def action_of(desc):
    desc = desc.strip()
    m = ACTION.match(desc)
    if m:
        return {"action": m.group(1), "module": m.group(6), "line": int(m.group(2)), "col": int(m.group(3))}
    return {"action": desc.strip("<>")}


def parse_trace(out):
    """TLC's counterexample as a list of states, each with the action that led to it and its variables."""
    states, cur, last = [], None, None
    for line in out.splitlines():
        m = re.match(r"^State (\d+): (.*)$", line)
        b = re.match(r"^Back to state (\d+): ?(.*)$", line)
        if m:
            cur = dict(index=int(m.group(1)), **action_of(m.group(2)), vars={})
            states.append(cur)
            last = None
            continue
        if b:
            states.append(dict(back_to=int(b.group(1)), **action_of(b.group(2) or "")))
            cur, last = None, None
            continue
        if cur is None:
            continue
        if not line.strip():
            cur, last = None, None
            continue
        v = re.match(r"^(?:/\\ )?([A-Za-z_]\w*) = (.*)$", line)
        if v and (line.startswith("/\\ ") or not cur["vars"]):
            last = v.group(1)
            cur["vars"][last] = v.group(2)
        elif last:
            cur["vars"][last] += "\n" + line
    return states


def tail(text, lines=120):
    rows = text.rstrip().splitlines()
    return "\n".join(rows[-lines:]) if len(rows) > lines else "\n".join(rows)


def sany_messages(out):
    """SANY's errors and warnings, each with its location when SANY gives one."""
    errors, warnings = [], []
    m = re.search(r"\*\*\*Parse Error\*\*\*\n(.*?)(?:\n\n|\Z)", out, re.S)
    if m:
        text = m.group(1).strip()
        loc = re.search(r"at line (\d+), column (\d+)", text)
        mod = re.search(r"Could not parse module (\w+)", out) or re.search(r"In module (\w+)", out)
        errors.append({"kind": "parse", "module": mod.group(1) if mod else None,
                       "line": int(loc.group(1)) if loc else None, "col": int(loc.group(2)) if loc else None,
                       "message": text})
    for section, sink in (("Semantic errors:", errors), ("Semantic warnings:", warnings)):
        i = out.find(section)
        if i < 0:
            continue
        body = out[i + len(section):]
        body = re.split(r"\n(?=Semantic (?:errors|warnings):|Parsing file|Semantic processing|Fatal errors)", body)[0]
        located = r"line (\d+), col (\d+) to line \d+, col \d+ of module (\w+)\n\n(.*?)(?=\n\n\n|\nline \d+, col|\Z)"
        for loc in re.finditer(located, body, re.S):
            sink.append({"kind": "semantic", "module": loc.group(3), "line": int(loc.group(1)),
                         "col": int(loc.group(2)), "message": loc.group(4).strip()})
    if not errors and re.search(r"Fatal errors|\*\*\* Abort messages|Could not parse module", out):
        errors.append({"kind": "fatal", "module": None, "line": None, "col": None, "message": tail(out, 20)})
    return errors, warnings


LEVELS = {"0": "constant", "1": "state", "2": "action", "3": "temporal"}


def xml_symbols(xml_text, modules):
    """Definitions, constants, variables and assumptions of the named modules, from SANY's XML exporter."""
    root = ET.fromstring(xml_text)
    by_uid = {}
    for e in root.find("context").findall("entry"):
        by_uid[e.findtext("UID")] = e[1]
    out = {"constants": [], "variables": [], "definitions": [], "assumptions": [], "theorems": []}

    def where(node):
        loc = node.find("location")
        if loc is None:
            return None, None, None
        line, col = loc.find("line").findtext("begin"), loc.find("column").findtext("begin")
        return loc.findtext("filename"), int(line), int(col)

    for uid, node in by_uid.items():
        fn, line, col = where(node)
        if fn not in modules:
            continue
        name = node.findtext("uniquename")
        if node.tag == "OpDeclNode":
            kind = node.findtext("kind")
            entry = {"name": name, "module": fn, "line": line, "col": col}
            if kind == "2":
                out["constants"].append(dict(entry, arity=int(node.findtext("arity") or 0)))
            elif kind == "3":
                out["variables"].append(entry)
        elif node.tag == "UserDefinedOpKind":
            params = []
            refs = node.findall("params/leibnizparam/FormalParamNodeRef") + node.findall("params/FormalParamNodeRef")
            for ref in refs:
                p = by_uid.get(ref.findtext("UID"))
                if p is not None:
                    params.append(p.findtext("uniquename"))
            out["definitions"].append({"name": name, "module": fn, "line": line, "col": col,
                                       "arity": int(node.findtext("arity") or 0), "params": params,
                                       "level": LEVELS.get(node.findtext("level"), node.findtext("level"))})
        elif node.tag == "AssumeDef":
            out["assumptions"].append({"name": name, "module": fn, "line": line, "col": col})
        elif node.tag == "TheoremDefNode":
            out["theorems"].append({"name": name, "module": fn, "line": line, "col": col})
    for k in out:
        out[k].sort(key=lambda d: (d["module"], d["line"] or 0, d["col"] or 0))
    return out


def parse_coverage(out):
    """TLC's coverage statistics: each action with TLC's two counts, and the lines under it."""
    actions, cur = [], None
    i = out.rfind("The coverage statistics")
    if i < 0:
        return actions
    for line in out[i:].splitlines()[1:]:
        m = re.match(r"^<(\S+) line (\d+), col (\d+) to line \d+, col \d+ of module (\w+)>: (\d+):(\d+)$", line)
        if m:
            cur = {"action": m.group(1), "module": m.group(4), "line": int(m.group(2)), "col": int(m.group(3)),
                   "distinct": int(m.group(5)), "found": int(m.group(6)), "never_fired": int(m.group(6)) == 0,
                   "lines": []}
            actions.append(cur)
            continue
        s = re.match(r"^\s+(?:\|+)?line (\d+), col (\d+) to line \d+, col \d+ of module (\w+): (\d+)", line)
        if s and cur is not None:
            cur["lines"].append({"line": int(s.group(1)), "col": int(s.group(2)), "count": int(s.group(4))})
            continue
        if line.startswith("End of statistics") or (line and not line.startswith((" ", "<", "|"))):
            break
    return actions


def parse_dot(text):
    nodes, edges = {}, []
    for line in text.splitlines():
        e = re.match(r'^(-?\d+) -> (-?\d+) \[label="([^"]*)"', line)
        if e:
            edges.append({"from": e.group(1), "to": e.group(2), "action": e.group(3)})
            continue
        n = re.match(r'^(-?\d+) \[label="((?:[^"\\]|\\.)*)"(.*)\]', line)
        if n:
            label = n.group(2).replace("\\n", "\n").replace('\\"', '"').replace("\\\\", "\\")
            nodes[n.group(1)] = {"id": n.group(1), "state": label, "initial": "filled" in n.group(3)}
    return list(nodes.values()), edges


# ---------------------------------------------------------------------------------------------------------------
# The tools

def tool_info(a):
    """The image's tools with their digests, from tla-kit-info --json; natively, the checker the skill finds."""
    exe = shutil.which("tla-kit-info")
    if exe:
        code, out = run([exe, "--json"], cwd=project_root(), timeout=60)
        if code != 0:
            raise ToolError(f"tla-kit-info exited {code}: {tail(out, 20)}")
        return {"image": json.loads(out)}
    c = checker_for(project_root())
    return {"image": None, "note": "not running in the tla-kit image (no tla-kit-info)",
            "checker": {"path": c.path, "sha256": c.sha, "pinned": c.pinned, "pin": c.pin_label}}


def tool_parse(a):
    spec_dir, module = module_path(a["module"])
    c = checker_for(spec_dir)
    tmp = tempfile.mkdtemp(prefix="tla-kit-parse-")
    try:
        copy_chain(module, spec_dir, tmp)
        code, out = run(java(c, tmp, "tla2sany.SANY", [module + ".tla"]), tmp, a.get("timeout", DEFAULT_TIMEOUT))
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    errors, warnings = sany_messages(out)
    out = out.replace(tmp + os.sep, "")
    return {"module": rel(os.path.join(spec_dir, module + ".tla")), "ok": not errors, "errors": errors,
            "warnings": warnings, "modules_parsed": re.findall(r"Semantic processing of module (\w+)", out),
            "output": tail(out, 60), "label": WORKING}


def tool_symbols(a):
    spec_dir, module = module_path(a["module"])
    c = checker_for(spec_dir)
    tmp = tempfile.mkdtemp(prefix="tla-kit-symbols-")
    try:
        copy_chain(module, spec_dir, tmp)
        chain = t.module_chain(module, spec_dir)
        p = subprocess.run(java(c, tmp, "tla2sany.xml.XMLExporter", ["-o", module + ".tla"]), cwd=tmp,
                           capture_output=True, text=True, timeout=a.get("timeout", DEFAULT_TIMEOUT))
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    start = p.stdout.find("<?xml")
    if p.returncode != 0 or start < 0:
        errors, _ = sany_messages(p.stdout + p.stderr)
        raise ToolError(f"SANY could not export {module}: " + json.dumps(errors or tail(p.stdout + p.stderr, 20)))
    modules = chain if a.get("all_modules") else [module]
    return dict({"module": rel(os.path.join(spec_dir, module + ".tla")), "modules": modules},
                **xml_symbols(p.stdout[start:], set(modules)), label=WORKING)


STANDARD = ["Naturals", "Integers", "Reals", "Sequences", "FiniteSets", "Bags", "TLC"]


def tool_evaluate(a):
    expr = a.get("expression")
    if not isinstance(expr, str) or not expr.strip():
        raise ToolError("an expression is required")
    tmp = tempfile.mkdtemp(prefix="tla-kit-evaluate-")
    try:
        extends = [m for m in STANDARD if m != "Reals"]
        consts, used, var = {}, None, None
        if a.get("module"):
            spec_dir, module = module_path(a["module"])
            copy_chain(module, spec_dir, tmp)
            meta, used = row_meta(module, spec_dir, a.get("rows"))
            consts = constants_of(meta, a.get("mut"), a.get("constants"))
            extends = [module] + [m for m in extends if m != module]
            c = checker_for(spec_dir)
            for m in t.module_chain(module, spec_dir):
                v = re.search(r"\bVARIABLES?\s+(\w+)", t.strip_comments(t.read(os.path.join(spec_dir, m + ".tla"))))
                var = var or (v.group(1) if v else None)
        else:
            c = checker_for(project_root())
            consts = {str(k): str(v) for k, v in (a.get("constants") or {}).items()}
        name = "TlaKitEval"
        # A module with variables needs an initial predicate, at state level. This one is false: TLC evaluates the
        # ASSUME, which prints the value, then finds no initial state and stops.
        body = (f"---- MODULE {name} ----\nEXTENDS {', '.join(extends)}\n"
                f"ASSUME PrintT(<<\"tla-kit-eval-begin\", {expr}, \"tla-kit-eval-end\">>)\n"
                + (f"TlaKitNoInit == FALSE /\\ {var} = {var}\n"
                   f"TlaKitNoNext == FALSE /\\ {var}' = {var}\n" if var else "")
                + "====\n")
        with open(os.path.join(tmp, name + ".tla"), "w", encoding="utf-8") as f:
            f.write(body)
        cfg = "INIT TlaKitNoInit\nNEXT TlaKitNoNext\n" if var else ""
        if consts:
            cfg += "CONSTANTS\n" + "".join(f"  {k} = {v}\n" for k, v in consts.items())
        with open(os.path.join(tmp, name + ".cfg"), "w", encoding="utf-8") as f:
            f.write(cfg)
        code, out = run(java(c, tmp, "tlc2.TLC", ["-config", name + ".cfg", "-workers", "1", "-metadir",
                                                  os.path.join(tmp, "meta"), name + ".tla"]),
                        tmp, a.get("timeout", 120))
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    m = re.search(r'<<"tla-kit-eval-begin", (.*), "tla-kit-eval-end">>', out, re.S)
    if m:
        return {"expression": expr, "value": m.group(1), "constants": consts, "row_list": used, "label": WORKING}
    errors, _ = sany_messages(out)
    err = re.search(r"^Error: .*?(?=\n\S*Finished in|\Z)", out, re.M | re.S)
    why = json.dumps(errors) if errors else (err.group(0).strip() if err else tail(out, 30))
    raise ToolError("could not evaluate: " + why)


def row_fields(line):
    f = [x.strip() for x in line.split(" | ")]
    if len(f) < 6:
        return {"row": line}
    out = {"row": line, "name": f[0], "mut": f[1].split("=", 1)[-1], "spec": f[2], "what": f[3], "verdict": f[4],
           "count": f[5]}
    if len(f) > 6:
        out["as_expected"] = f[6] == "as expected"
        out["note"] = f[6]
    return out


def tlc_script(a, kind, extra_opts):
    """Run the skill's tlc_run.py on one row, with its trace, and read what it prints."""
    spec_dir, module = module_path(a["module"])
    args = [module, a.get("mut") or "-", a["property"]]
    args += pairs_of(a.get("constants"), extra_opts)
    args += ["--kind", kind, "--spec", a.get("spec") or "Spec", "--workers", str(a.get("workers", 1)), "--trace"]
    if a.get("expect"):
        args += ["--expect", a["expect"]]
    if a.get("rows"):
        args += ["--rows", resolve(a["rows"])]
    for line in a.get("cfg") or []:
        args += ["--cfg", line]
    code, out = run(skill_script("tlc_run.py") + args, spec_dir, a.get("timeout", DEFAULT_TIMEOUT))
    lines = out.splitlines()
    first = next((l for l in lines if " | " in l), None)
    if first is None:
        raise ToolError(f"tlc_run.py printed no row (exit {code}): {tail(out, 30)}")
    result = row_fields(first)
    result.update({"module": rel(os.path.join(spec_dir, module + ".tla")), "exit": code,
                   "command": "tlc_run.py " + " ".join(args)})
    result["trace"] = parse_trace(out)
    result["output"] = tail(out, 80)
    return result


def tool_tlc_run(a):
    if not a.get("property"):
        raise ToolError("a property is required")
    kind = a.get("kind") or "INVARIANT"
    if kind == "SIMULATE":
        raise ToolError("a sample is the simulate tool's, so that it is labelled as one")
    opts = {k: a.get(k) for k in ("states", "constraint")}
    r = tlc_script(a, kind, opts)
    r["label"] = WORKING
    return r


def tool_simulate(a):
    if not a.get("property"):
        raise ToolError("an invariant to check while sampling is required (TypeOK, if nothing else)")
    opts = {"depth": a.get("depth", 40), "num": a.get("num", 1000), "seed": a.get("seed", 1)}
    r = tlc_script(a, "SIMULATE", opts)
    r["sampling"] = True
    r["label"] = ("sampling: random behaviours to a depth. NO-ERROR-SAMPLED is not a check of every state, and "
                  "never a HOLDS. " + WORKING)
    return r


def tlc_direct(a, prefix, flags, invariants=()):
    """TLC on a copy of the module chain, configured as the skill configures a row, with extra flags."""
    spec_dir, module = module_path(a["module"])
    c = checker_for(spec_dir)
    meta, used = row_meta(module, spec_dir, a.get("rows"))
    consts = constants_of(meta, a.get("mut"), a.get("constants"))
    tmp = tempfile.mkdtemp(prefix=prefix)
    try:
        copy_chain(module, spec_dir, tmp)
        with open(os.path.join(tmp, "MC.cfg"), "w", encoding="utf-8") as f:
            f.write(config(a.get("spec") or "Spec", consts, meta["cfg"], a.get("cfg") or [], a.get("constraint"),
                           invariants))
        cmd = java(c, tmp, "tlc2.TLC", ["-config", "MC.cfg", "-workers", "1", "-deadlock",
                                         "-metadir", os.path.join(tmp, "meta")] + flags(tmp) + [module + ".tla"])
        code, out = run(cmd, tmp, a.get("timeout", DEFAULT_TIMEOUT))
        extra = {}
        dot = os.path.join(tmp, "graph.dot")
        if os.path.exists(dot):
            extra["dot"] = open(dot, encoding="utf-8").read()
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    states = re.findall(r"([0-9,]+) distinct states found", out)
    return {"module": rel(os.path.join(spec_dir, module + ".tla")), "spec": a.get("spec") or "Spec",
            "constants": consts, "row_list": used, "exit": code,
            "distinct_states": int(states[-1].replace(",", "")) if states else None,
            "complete": "No error has been found" in out}, out, extra


def tool_coverage(a):
    r, out, _ = tlc_direct(a, "tla-kit-coverage-", lambda tmp: ["-coverage", "1"], a.get("invariants") or [])
    actions = parse_coverage(out)
    if not actions:
        raise ToolError("TLC printed no coverage statistics: " + tail(out, 30))
    r.update({"actions": actions, "never_fired": [x["action"] for x in actions if x["never_fired"]],
              "note": "TLC's two counts per action, as it prints them: distinct states, then states found",
              "label": WORKING})
    if not r["complete"]:
        r["output"] = tail(out, 40)
    return r


def tool_state_graph(a):
    limit = int(a.get("max_states", 1000))
    r, out, extra = tlc_direct(a, "tla-kit-graph-", lambda tmp: ["-dump", "dot,actionlabels",
                                                                 os.path.join(tmp, "graph")])
    if not r["complete"]:
        raise ToolError("TLC did not finish the state space: " + tail(out, 30))
    if r["distinct_states"] is not None and r["distinct_states"] > limit:
        raise ToolError(f"{r['distinct_states']} distinct states, more than max_states={limit}; a state graph is "
                        "for a small model")
    nodes, edges = parse_dot(extra.get("dot", ""))
    r.update({"nodes": nodes, "edges": edges, "label": WORKING})
    return r


def tool_tlc_rows(a):
    """The skill's generator: the one tool that writes into the project, and only its results file."""
    rows = resolve(a["rows"])
    root = project_root()
    args = [os.path.relpath(rows, root), "-j", str(a.get("jobs", 1))]
    if a.get("only"):
        only = a["only"] if isinstance(a["only"], str) else ",".join(a["only"])
        args += ["--only", only]
    if a.get("dry_run"):
        args.append("--dry-run")
    if a.get("date"):
        args += ["--date", a["date"]]
    before = set(os.listdir(os.path.dirname(rows)))
    code, out = run(skill_script("tlc_rows.py") + args, root, a.get("timeout", 3600))
    written = sorted(set(os.listdir(os.path.dirname(rows))) - before)
    summary = re.findall(r"^\d+ rows: .*$", out, re.M)
    return {"rows": rel(rows), "exit": code, "summary": summary[-1] if summary else None,
            "results_files_written": [rel(os.path.join(os.path.dirname(rows), w)) for w in written],
            "command": "tlc_rows.py " + " ".join(args), "output": tail(out, 120),
            "label": ("the skill's generator, run as from the command line: a results file it writes is the file "
                      "the script writes (ADR-0006 item 1)")}


# ---------------------------------------------------------------------------------------------------------------
# Tool definitions

MODULE = {"type": "string", "description": "The module, relative to the project root, e.g. spec/Counter.tla"}
MUT = {"type": "string", "description": "The value of the Mut constant (e.g. none), or - for a module without one"}
CONSTS = {"type": "object", "additionalProperties": {"type": "string"},
          "description": "Constant values, as TLA+ text, e.g. {\"Limit\": \"3\"}. They override the row list's"}
SPEC = {"type": "string", "description": "The specification's name (default Spec)"}
ROWS = {"type": "string", "description": "A row list whose # const: and # cfg: lines are the defaults, if not "
                                         "<Module>-rows.txt beside the module or in rows/"}
CFG = {"type": "array", "items": {"type": "string"}, "description": "Extra configuration lines"}
TIMEOUT = {"type": "integer", "description": "Seconds before the run is stopped"}


def schema(props, required=()):
    return {"type": "object", "properties": props, "required": list(required), "additionalProperties": False}


TOOLS = [
    ("info", tool_info, "Every tool in the image with the digest a results file would cite (tla-kit-info).",
     schema({})),
    ("parse", tool_parse, "Parse a module and the modules it extends with SANY. Returns its errors and warnings "
     "with their locations. Working output.", schema({"module": MODULE, "timeout": TIMEOUT}, ["module"])),
    ("symbols", tool_symbols, "A module's constants, variables, definitions (with arity, parameters and level), "
     "assumptions and theorems, from SANY's XML exporter. Working output.",
     schema({"module": MODULE, "all_modules": {"type": "boolean", "description": "Also the modules it extends "
                                                                                 "from the same directory"},
             "timeout": TIMEOUT}, ["module"])),
    ("evaluate", tool_evaluate, "Evaluate a constant expression with TLC, through a scratch module outside the "
     "project. With a module, the expression may use its definitions, at the row list's constants. Working output.",
     schema({"expression": {"type": "string"}, "module": MODULE, "mut": MUT, "constants": CONSTS, "rows": ROWS,
             "timeout": TIMEOUT}, ["expression"])),
    ("tlc_run", tool_tlc_run, "Run TLC on one row, as the skill's tlc_run.py does: the verdict (HOLDS, "
     "COUNTEREXAMPLE, DEADLOCK or ERROR), the state count, and any counterexample as structured states. Writes no "
     "results file. Working output.",
     schema({"module": MODULE, "mut": MUT, "property": {"type": "string"},
             "kind": {"type": "string", "enum": ["INVARIANT", "PROPERTY", "DEADLOCK"]}, "spec": SPEC,
             "expect": {"type": "string", "enum": ["HOLDS", "COUNTEREXAMPLE", "DEADLOCK"]}, "constants": CONSTS,
             "states": {"type": "integer"}, "constraint": {"type": "string"}, "rows": ROWS, "cfg": CFG,
             "workers": {"type": "integer"}, "timeout": TIMEOUT}, ["module", "property"])),
    ("simulate", tool_simulate, "Random behaviours to a depth, checking an invariant, as the skill's SIMULATE row. "
     "Labelled as sampling: NO-ERROR-SAMPLED is not a check.",
     schema({"module": MODULE, "mut": MUT, "property": {"type": "string"}, "spec": SPEC, "constants": CONSTS,
             "depth": {"type": "integer"}, "num": {"type": "integer"}, "seed": {"type": "integer"},
             "expect": {"type": "string", "enum": ["NO-ERROR-SAMPLED", "COUNTEREXAMPLE"]}, "rows": ROWS,
             "cfg": CFG, "timeout": TIMEOUT}, ["module", "property"])),
    ("coverage", tool_coverage, "Run TLC with coverage at the row list's constants and report per-action counts, "
     "naming the actions that never fire. Working output.",
     schema({"module": MODULE, "mut": MUT, "spec": SPEC, "constants": CONSTS, "constraint": {"type": "string"},
             "invariants": {"type": "array", "items": {"type": "string"}}, "rows": ROWS, "cfg": CFG,
             "timeout": TIMEOUT}, ["module"])),
    ("state_graph", tool_state_graph, "The reachable state graph of a small model as JSON: states, the initial "
     "ones marked, and edges labelled by action. Working output.",
     schema({"module": MODULE, "mut": MUT, "spec": SPEC, "constants": CONSTS, "constraint": {"type": "string"},
             "max_states": {"type": "integer"}, "rows": ROWS, "cfg": CFG, "timeout": TIMEOUT}, ["module"])),
    ("tlc_rows", tool_tlc_rows, "Run the skill's generator, tlc_rows.py, on a row list, as from the command line. "
     "It writes a dated results file only when every row is as expected, and never overwrites one; --only and "
     "dry_run write nothing. This is the only tool that writes into the project.",
     schema({"rows": {"type": "string", "description": "The row list, relative to the project root"},
             "jobs": {"type": "integer"}, "only": {"type": "array", "items": {"type": "string"}},
             "dry_run": {"type": "boolean"}, "date": {"type": "string", "description": "YYYY.MM.DD"},
             "timeout": TIMEOUT}, ["rows"])),
]
BY_NAME = {name: (fn, desc, sch) for name, fn, desc, sch in TOOLS}


def call_tool(name, args):
    if name not in BY_NAME:
        return {"content": [{"type": "text", "text": f"unknown tool {name}"}], "isError": True}
    fn, _, sch = BY_NAME[name]
    args = args or {}
    unknown = sorted(set(args) - set(sch["properties"]))
    missing = [k for k in sch["required"] if k not in args]
    try:
        if unknown or missing:
            raise ToolError(f"unknown arguments {unknown}" if unknown else f"missing arguments {missing}")
        result = fn(args)
    except ToolError as e:
        return {"content": [{"type": "text", "text": str(e)}], "isError": True}
    except Exception as e:  # a fault of the server's: reported, never fatal to the session
        print(traceback.format_exc(), file=sys.stderr)
        return {"content": [{"type": "text", "text": f"internal error in {name}: {e!r}"}], "isError": True}
    return {"content": [{"type": "text", "text": json.dumps(result, indent=1)}], "structuredContent": result,
            "isError": False}


# ---------------------------------------------------------------------------------------------------------------
# The transport: JSON-RPC 2.0, one message per line

def handle(msg):
    """The response to one message, or None for a notification."""
    method, mid, params = msg.get("method"), msg.get("id"), msg.get("params") or {}
    is_request = "id" in msg
    if method == "initialize":
        asked = params.get("protocolVersion")
        version = asked if asked in PROTOCOL_VERSIONS else PROTOCOL_VERSIONS[0]
        result = {"protocolVersion": version, "capabilities": {"tools": {"listChanged": False}},
                  "serverInfo": {"name": SERVER_NAME, "version": server_version()},
                  "instructions": ("The TLA+ tools of the tla-kit image, on the project mounted at /work. Every "
                                   "tool but tlc_rows returns working output and writes nothing into the project; "
                                   "tlc_rows runs the skill's generator, which writes the results file.")}
    elif method == "ping":
        result = {}
    elif method == "tools/list":
        result = {"tools": [{"name": n, "description": d, "inputSchema": s} for n, _, d, s in TOOLS]}
    elif method == "tools/call":
        result = call_tool(params.get("name"), params.get("arguments"))
    elif not is_request:
        return None  # notifications/initialized, notifications/cancelled and the like
    else:
        return {"jsonrpc": "2.0", "id": mid, "error": {"code": -32601, "message": f"method not found: {method}"}}
    return {"jsonrpc": "2.0", "id": mid, "result": result} if is_request else None


def serve(stdin=sys.stdin, stdout=sys.stdout):
    print(f"{SERVER_NAME} MCP server: project {project_root()}, skill {SKILL}", file=sys.stderr)
    for line in stdin:
        if not line.strip():
            continue
        try:
            msg = json.loads(line)
        except ValueError as e:
            reply = {"jsonrpc": "2.0", "id": None, "error": {"code": -32700, "message": f"parse error: {e}"}}
        else:
            if not isinstance(msg, dict):
                reply = {"jsonrpc": "2.0", "id": None, "error": {"code": -32600, "message": "invalid request"}}
            else:
                reply = handle(msg)
        if reply is not None:
            stdout.write(json.dumps(reply) + "\n")
            stdout.flush()


if __name__ == "__main__":
    serve()
