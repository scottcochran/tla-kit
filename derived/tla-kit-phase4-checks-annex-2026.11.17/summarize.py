#!/usr/bin/env python3
"""Summarize a claude -p stream-json transcript: each tool call, its key arguments, and what came back."""
import json, sys

calls = {}
for line in open(sys.argv[1]):
    m = json.loads(line)
    t = m.get("type")
    if t == "assistant":
        for c in m["message"]["content"]:
            if c["type"] == "tool_use":
                calls[c["id"]] = c["name"]
                args = {k: v for k, v in c["input"].items() if k not in ("old_string", "new_string")}
                print(f"CALL {c['name']} {json.dumps(args)}")
                if c["name"] == "Edit":
                    print(f"     - {c['input']['old_string']!r}\n     + {c['input']['new_string']!r}")
            elif c["type"] == "text" and c["text"].strip():
                print("SAY  " + c["text"].strip().replace("\n", "\n     "))
    elif t == "user":
        for c in m["message"].get("content", []):
            if isinstance(c, dict) and c.get("type") == "tool_result":
                body = c["content"]
                if isinstance(body, list):
                    body = " ".join(x.get("text", "") for x in body if isinstance(x, dict))
                body = str(body)
                name = calls.get(c["tool_use_id"], "?")
                verdict = ""
                try:
                    verdict = json.loads(body).get("verdict", "")
                except Exception:
                    pass
                err = " ERROR" if c.get("is_error") else ""
                print(f"  => {name}{err} {verdict} {body[:300]!r}")
    elif t == "result":
        print(f"RESULT {m.get('subtype')} turns={m.get('num_turns')} ms={m.get('duration_ms')} "
              f"cost={m.get('total_cost_usd')} denials={m.get('permission_denials')}")
