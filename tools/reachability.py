#!/usr/bin/env python3
"""
Classifies every ReplicatedStorage module by which side actually reaches it.

Seeds from the scripts each side runs, follows requires, and reports whether a
module is reached by the server only, the client only, both, or neither. That
is the evidence for what has to be replicated and what does not.
"""
import os
import re
import sys
import collections

SERVICES = {"ReplicatedStorage", "ServerScriptService", "ServerStorage",
            "ReplicatedFirst", "StarterGui", "StarterPlayer", "Workspace"}

SERVER_ROOTS = ("ServerScriptService", "ServerStorage")
CLIENT_ROOTS = ("StarterPlayer", "StarterGui", "ReplicatedFirst")

SKIP = {".git", "tools", "studio", "docs"}


def instance_path(file_path):
    """Filesystem path -> tuple of instance names."""
    parts = file_path.split(os.sep)
    last = parts[-1]
    for suffix in (".server.luau", ".client.luau", ".luau"):
        if last.endswith(suffix):
            last = last[: -len(suffix)]
            break
    return tuple(parts[:-1]) if last == "init" else tuple(parts[:-1]) + (last,)


def build():
    provides, sources = {}, {}
    for directory, _, files in os.walk("."):
        if any(p in SKIP for p in directory.split(os.sep)):
            continue
        for name in files:
            if not name.endswith(".luau"):
                continue
            path = os.path.join(directory, name).replace("./", "", 1)
            provides[instance_path(path)] = path
            sources[path] = open(path, encoding="utf-8", errors="replace").read()
    return provides, sources


# WaitForChild and FindFirstChild take an optional second argument, so the
# closing paren may be preceded by ", 100" or ", true".
SEGMENT = re.compile(
    r'\.\s*([A-Za-z_][A-Za-z0-9_]*)'
    r'|\[\s*"([^"]+)"\s*\]'
    r'|:\s*(?:WaitForChild|FindFirstChild)\(\s*"([^"]+)"\s*(?:,[^)]*)?\)'
)


def _segments(rest):
    out, pos = [], 0
    while pos < len(rest):
        m = SEGMENT.match(rest, pos)
        if not m:
            break
        out.append(next(g for g in m.groups() if g is not None))
        pos = m.end()
    return out


def _resolve(expr, aliases, here=None):
    """Instance path an expression names, or None.

    Handles a service root, `game.Service`, and local aliases -- the client
    boots through `local M = RS:WaitForChild("Modules")` then `require(M.X)`,
    so without alias resolution the whole client tree looks unreachable.
    """
    expr = expr.strip()

    head = re.match(r'game\s*:\s*GetService\(\s*"([A-Za-z]+)"\s*\)', expr)
    if head:
        root, rest = (head.group(1),), expr[head.end():]
    else:
        head = re.match(r"(?:game\s*\.\s*)?([A-Za-z_][A-Za-z0-9_]*)", expr)
        if not head:
            return None
        name = head.group(1)
        rest = expr[head.end():]
        if name in SERVICES:
            root = (name,)
        elif name == "script" and here is not None:
            root = here
        elif name in aliases:
            root = aliases[name]
        else:
            return None

    # `script.Parent` walks up; everything else walks down.
    path = list(root)
    for segment in _segments(rest):
        if segment == "Parent":
            if path:
                path.pop()
        else:
            path.append(segment)

    return tuple(path)


def required_paths(text, here=None):
    """Instance paths named by require() calls.

    `here` is the requiring module's own instance path, needed because
    `require(script.X)` and `require(script.Parent.Y)` are how most of this
    codebase refers to its neighbours.
    """
    aliases = {}
    # Two passes: locals first, since a require may precede a later alias but
    # the common case is declare-then-use.
    for _ in range(2):
        for m in re.finditer(r"^\s*local\s+([A-Za-z_][A-Za-z0-9_]*)\s*=\s*([^\n]+)$", text, re.M):
            name, expr = m.group(1), m.group(2)
            if expr.lstrip().startswith("require"):
                continue
            path = _resolve(expr, aliases, here)
            if path:
                aliases[name] = path

    out = []
    for match in re.finditer(r"require\s*\(([^)]*)\)", text):
        path = _resolve(match.group(1), aliases, here)
        if path and path[0] in SERVICES:
            out.append(path)
    return out


# Trees the engine loads by name rather than by require, so the require graph
# never reaches them. Each maps a path prefix to the side that dispatches it.
#   Replication:ConnectToVFXRemotes walks VFX by a "Folder/Name" string.
#   Combat:GetAttackModule / GetCharacterModule scan their folders by name.
DYNAMIC = {
    "ReplicatedStorage/Client/Replication/VFX": "client",
    "ReplicatedStorage/Client/Replication/Maps": "client",
    "ServerStorage/serverCombat/Attacks/List": "server",
    "ServerStorage/serverCombat/Characters": "server",
}


def dynamic_seeds(side, sources):
    return [p for p in sources
            for prefix, owner in DYNAMIC.items()
            if owner == side and p.startswith(prefix)]


def reach(seed_paths, provides, sources):
    seen, stack = set(), list(seed_paths)
    while stack:
        path = stack.pop()
        if path in seen or path not in sources:
            continue
        seen.add(path)
        for target in required_paths(sources[path], instance_path(path)):
            hit = provides.get(target)
            if hit:
                stack.append(hit)
    return seen


if __name__ == "__main__":
    provides, sources = build()

    server_seed = [p for p in sources if p.startswith(SERVER_ROOTS)]
    client_seed = [p for p in sources if p.startswith(CLIENT_ROOTS)]

    server = reach(server_seed + dynamic_seeds("server", sources), provides, sources)
    client = reach(client_seed + dynamic_seeds("client", sources), provides, sources)

    buckets = collections.defaultdict(list)
    for path in sorted(sources):
        if not path.startswith("ReplicatedStorage"):
            continue
        s, c = path in server, path in client
        buckets[("both" if s and c else "server only" if s else "client only" if c else "neither")].append(path)

    if len(sys.argv) == 1:
        for label in ("both", "client only", "server only", "neither"):
            files = buckets[label]
            lines = sum(len(sources[p].split("\n")) for p in files)
            print(f"{label:>12}: {len(files):>4} files, {lines:>7} lines")

    if len(sys.argv) > 1:
        want = sys.argv[1]
        try:
            print(f"\n=== {want} ===")
            for p in buckets[want]:
                print(f"  {p}")
        except BrokenPipeError:
            os._exit(0)   # piped into head; not an error
