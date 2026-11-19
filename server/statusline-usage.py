#!/usr/bin/env python3
"""Claude Code status line helper.

Claude Code pipes a JSON blob into the status line command on every refresh. It includes `rate_limits`
(five_hour / seven_day, each with used_percentage and resets_at). This script writes just those numbers to
~/.kindle-desk/usage.json for usage-server.mjs to serve. It writes nothing else: no keys, no session content.

Use it from your status line command, for example:
    input=$(cat); echo "$input" | python3 /path/to/statusline-usage.py >/dev/null
and keep printing your normal status line afterwards. It prints a short "5h 14% / week 38%" line you can ignore.
"""
import json, os, sys, time

try:
    data = json.load(sys.stdin)
except Exception:
    data = {}

limits = data.get("rate_limits") or {}
out = {}
for src, dst in (("five_hour", "nam_gio"), ("seven_day", "tuan")):   # key names are what the Kindle plugin reads
    v = limits.get(src) or {}
    if v.get("used_percentage") is not None:
        out[dst] = {"pt": round(float(v["used_percentage"])), "reset": v.get("resets_at")}

if out:
    out["luc"] = int(time.time())
    folder = os.path.expanduser("~/.kindle-desk")
    os.makedirs(folder, exist_ok=True)
    tmp = os.path.join(folder, "usage.json.tmp")
    with open(tmp, "w") as f:
        json.dump(out, f)
    os.replace(tmp, os.path.join(folder, "usage.json"))
    parts = []
    if "nam_gio" in out: parts.append("5h %d%%" % out["nam_gio"]["pt"])
    if "tuan" in out: parts.append("week %d%%" % out["tuan"]["pt"])
    print(" / ".join(parts))
