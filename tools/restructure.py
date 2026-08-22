#!/usr/bin/env python3
"""
Applies a move manifest to the tree and rewrites every reference to match.

Instance paths are written three ways in this codebase -- absolute from a
service, through a local alias (`local Modules = ReplicatedStorage.Modules`),
and relative to `script`. Only the first two need rewriting when something
moves; relative paths survive as long as a subtree moves as a unit.

A move whose source dissolves -- `ReplicatedStorage.Modules` becoming `Client`
and `Shared` at the root -- cannot be handled by repointing an alias, because
there is no single node left to point at. Those are declared DISSOLVED and
their aliases are removed, with every usage rewritten to an absolute path.

Usage:  restructure.py <manifest.json> [--apply]
Without --apply it reports what it would do and changes nothing.
"""
import json
import os
import re
import subprocess
import sys

SERVICES = {"ReplicatedStorage", "ServerScriptService", "ServerStorage",
            "ReplicatedFirst", "StarterGui", "StarterPlayer", "Workspace"}

SKIP = {".git", "tools", "studio", "docs"}

SEGMENT = re.compile(
    r'\.\s*([A-Za-z_][A-Za-z0-9_]*)'
    r'|\[\s*"([^"]+)"\s*\]'
    r'|:\s*(?:WaitForChild|FindFirstChild)\(\s*"([^"]+)"\s*(?:,[^)]*)?\)'
)

# An expression head: a service, `game.Service`, or a bare identifier.
HEAD = re.compile(r'\b(?:game\s*:\s*GetService\(\s*"([A-Za-z]+)"\s*\)|game\s*\.\s*([A-Za-z_]\w*)|([A-Za-z_]\w*))')


def luau_files(root="."):
    for directory, _, files in os.walk(root):
        if any(p in SKIP for p in directory.split(os.sep)):
            continue
        for name in files:
            if name.endswith(".luau"):
                yield os.path.join(directory, name).replace("./", "", 1)


def read_segments(text, pos):
    out = []
    while pos < len(text):
        m = SEGMENT.match(text, pos)
        if not m:
            break
        out.append((next(g for g in m.groups() if g is not None), m.end()))
        pos = m.end()
    return out


class Mover:
    def __init__(self, manifest):
        # Longest source first so nested moves win over their parents.
        self.moves = sorted(
            ((tuple(m["from"].split(".")), tuple(m["to"].split("."))) for m in manifest["moves"]),
            key=lambda kv: -len(kv[0]),
        )
        self.dissolved = {tuple(d.split(".")) for d in manifest.get("dissolved", [])}

    def map_path(self, path):
        """New instance path for an old one, or None if unaffected."""
        for src, dst in self.moves:
            if path[: len(src)] == src:
                return dst + path[len(src):]
        return None

    def is_dissolved(self, path):
        return path in self.dissolved


def rewrite(text, mover):
    """Returns (new_text, changes)."""
    aliases = {}
    changes = 0

    # Pass 1: learn what each local alias points at, before any rewriting.
    for m in re.finditer(r"^([ \t]*local\s+([A-Za-z_]\w*)\s*=\s*)(.+)$", text, re.M):
        expr = m.group(3).strip()
        if expr.startswith("require"):
            continue
        path = resolve(expr, aliases)
        if path:
            aliases[m.group(2)] = path

    # Pass 2: rewrite, longest match first, walking the text once.
    out, pos = [], 0
    while pos < len(text):
        m = HEAD.search(text, pos)
        if not m:
            out.append(text[pos:])
            break

        out.append(text[pos:m.start()])
        head = next(g for g in m.groups() if g is not None)

        # The name being bound in `local X = ...` is a declaration, not a
        # reference. Expanding it produces `local a.b.c = ...`.
        before = text[max(0, m.start() - 8):m.start()]
        is_binding = re.search(r"\blocal\s+$", before) is not None

        if head in SERVICES and not is_binding:
            root, cursor = (head,), m.end()
        elif head in aliases and not is_binding and mover.is_dissolved(aliases[head]):
            # Only expand an alias usage when its target has dissolved and the
            # alias cannot simply be repointed. Otherwise rewriting the alias's
            # own definition is enough, and leaves the code readable.
            root, cursor = aliases[head], m.end()
        else:
            out.append(text[m.start():m.end()])
            pos = m.end()
            continue

        segments = read_segments(text, cursor)
        full = root + tuple(s for s, _ in segments)
        end = segments[-1][1] if segments else cursor

        new = mover.map_path(full)

        if new is None:
            out.append(text[m.start():end])
        else:
            out.append(render(new))
            changes += 1

        pos = end

    return "".join(out), changes


def resolve(expr, aliases):
    m = HEAD.match(expr.strip())
    if not m:
        return None
    head = next(g for g in m.groups() if g is not None)
    if head in SERVICES:
        root = (head,)
    elif head in aliases:
        root = aliases[head]
    else:
        return None
    path = list(root)
    for seg, _ in read_segments(expr.strip(), m.end()):
        if seg == "Parent":
            if path:
                path.pop()
        else:
            path.append(seg)
    return tuple(path)


IDENTIFIER = re.compile(r"^[A-Za-z_]\w*$")


def render(path):
    """Instance path as Luau source.

    A segment that is not a valid identifier -- "Limited Emote Dates",
    "Gebura Red Mist" -- has to keep bracket syntax or the result is a syntax
    error rather than a wrong path, which is at least loud.
    """
    out = path[0]
    for segment in path[1:]:
        out += f".{segment}" if IDENTIFIER.match(segment) else f'["{segment}"]'
    return out


def instance_to_fs(path):
    return os.path.join(*path)


def main():
    manifest = json.load(open(sys.argv[1], encoding="utf-8"))
    apply = "--apply" in sys.argv
    mover = Mover(manifest)

    print("=== moves ===")
    for src, dst in mover.moves:
        s, d = instance_to_fs(src), instance_to_fs(dst)
        exists = os.path.exists(s) or os.path.exists(s + ".luau")
        print(f"  {'' if exists else '[missing] '}{s}  ->  {d}")

    print("\n=== reference rewrites ===")
    touched, total = 0, 0
    edits = {}
    for path in luau_files():
        text = open(path, encoding="utf-8", errors="replace").read()
        new, n = rewrite(text, mover)
        if n:
            touched += 1
            total += n
            edits[path] = new
    print(f"  {total} references across {touched} files")

    if not apply:
        print("\nDry run. Pass --apply to write.")
        return

    for path, new in edits.items():
        open(path, "w", encoding="utf-8").write(new)

    for src, dst in mover.moves:
        s, d = instance_to_fs(src), instance_to_fs(dst)
        for suffix in ("", ".luau", ".server.luau", ".client.luau", ".meta.json"):
            if os.path.exists(s + suffix):
                os.makedirs(os.path.dirname(d + suffix) or ".", exist_ok=True)
                subprocess.run(["git", "mv", s + suffix, d + suffix], check=True)
    # A move across services leaves files naming a service they never declared,
    # which is nil at runtime rather than a syntax error -- so check for it.
    services_used = re.compile(r'(?<![.\w])(' + "|".join(SERVICES) + r')\s*\.')
    missing = []
    for path in luau_files():
        text = open(path, encoding="utf-8", errors="replace").read()
        for service in set(m.group(1) for m in services_used.finditer(text)):
            if not re.search(rf'local\s+{service}\s*=', text):
                missing.append((path, service))

    if missing:
        print("\n=== services referenced but not declared ===")
        for path, service in missing:
            print(f"  {path}  needs  local {service} = game:GetService(\"{service}\")")

    print("\nApplied.")


if __name__ == "__main__":
    main()
