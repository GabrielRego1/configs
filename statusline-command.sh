#!/usr/bin/env bash
# Status line global: modelo, session, contexto, custo, path+branch, limites 5h/7d.
# python3 em vez de jq: jq nao esta instalado no WSL.
exec python3 -c '
import json, os, subprocess, sys, time

try:
    d = json.load(sys.stdin)
except ValueError:
    d = {}

def g(o, *keys):
    for k in keys:
        o = o.get(k) if isinstance(o, dict) else None
    return o

def pct(v):
    return "--" if v is None else "%.0f%%" % v

def left(ts):
    s = int(ts - time.time())
    if s <= 0: return "agora"
    m = s // 60
    if m < 60: return "%dm" % m
    if m < 1440: return "%dh%02dm" % (m // 60, m % 60)
    return "%dd%dh" % (m // 1440, m % 1440 // 60)

def limit(label, w):
    p = g(w, "used_percentage")
    if p is None:
        return "%s --" % label
    n = min(5, int(p / 20 + 0.5))
    c = 31 if p >= 85 else 33 if p >= 60 else 32
    out = "%s \033[%dm%s%s %s\033[0m" % (label, c, "▰" * n, "▱" * (5 - n), pct(p))
    ts = g(w, "resets_at")
    return out + (" ↻ %s" % left(ts) if ts else "")

def tok(n):
    n = n or 0
    if n >= 1_000_000: return "%gm" % round(n / 1_000_000, 1)
    if n >= 1000: return "%gk" % round(n / 1000, 1)
    return str(n)

cwd = g(d, "workspace", "current_dir") or d.get("cwd") or os.getcwd()
branch = ""
for args in (["symbolic-ref", "--short", "HEAD"], ["rev-parse", "--short", "HEAD"]):
    r = subprocess.run(["git", "-C", cwd, "--no-optional-locks", *args], capture_output=True, text=True)
    if r.returncode == 0:
        branch = r.stdout.strip()
        break

home = os.path.expanduser("~")
path = "~" + cwd[len(home):] if cwd.startswith(home) else cwd
cost = g(d, "cost", "total_cost_usd") or 0
used = g(d, "context_window", "total_input_tokens")
size = g(d, "context_window", "context_window_size")

line1 = " | ".join(filter(None, [
    "\033[36m%s\033[0m" % (g(d, "model", "display_name") or "?"),
    "session: %s" % (d.get("session_name") or "-"),
    "ctx %s/%s (%s)" % (tok(used), tok(size), pct(g(d, "context_window", "used_percentage"))),
    "$%.2f" % cost,
]))
line2 = "\033[33m%s\033[0m%s │ %s │ %s" % (
    path,
    " (%s)" % branch if branch else "",
    limit("5h", g(d, "rate_limits", "five_hour")),
    limit("7d", g(d, "rate_limits", "seven_day")),
)
print(line1)
print(line2)
'
