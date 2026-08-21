#!/usr/bin/env python3
"""
Inventory of modules and who requires them.

Prints, per module, its line count and how many other files require it, so
duplicate implementations of one capability can be compared on usage rather
than on which one was found first.
"""
import os
import re
import sys
import collections

SKIP_DIRS = {".git", "tools", "studio"}

def modules(root="."):
    """Every ModuleScript in the tree, as (instance name, path, lines)."""
    found = []
    for directory, dirnames, filenames in os.walk(root):
        parts = directory.split(os.sep)
        if any(p in SKIP_DIRS for p in parts):
            continue
        for name in filenames:
            if not name.endswith(".luau") or name.endswith(".server.luau") or name.endswith(".client.luau"):
                continue
            path = os.path.join(directory, name).replace("./", "", 1)
            stem = name[: -len(".luau")]
            instance = os.path.basename(directory) if stem == "init" else stem
            lines = sum(1 for _ in open(path, encoding="utf-8", errors="replace"))
            found.append((instance, path, lines))
    return found

def require_counts(root="."):
    """How many distinct files mention each identifier in a require()."""
    counts = collections.defaultdict(set)
    pattern = re.compile(r"require\s*\(([^)]*)\)")
    for directory, dirnames, filenames in os.walk(root):
        parts = directory.split(os.sep)
        if any(p in SKIP_DIRS for p in parts):
            continue
        for name in filenames:
            if not name.endswith(".luau"):
                continue
            path = os.path.join(directory, name).replace("./", "", 1)
            text = open(path, encoding="utf-8", errors="replace").read()
            for match in pattern.finditer(text):
                expr = match.group(1)
                # last dotted or ["quoted"] segment names the module
                names = re.findall(r'\.\s*([A-Za-z_][A-Za-z0-9_]*)|\[\s*"([^"]+)"\s*\]', expr)
                if names:
                    last = next(g for g in reversed(names[-1]) if g)
                    counts[last].add(path)
    return counts

if __name__ == "__main__":
    counts = require_counts()
    rows = []
    for instance, path, lines in modules():
        rows.append((len(counts.get(instance, ())), lines, instance, path))

    keyword = sys.argv[1].lower() if len(sys.argv) > 1 else None
    rows.sort(key=lambda r: (-r[0], -r[1]))

    print(f"{'used by':>8}  {'lines':>6}  module / path")
    for used, lines, instance, path in rows:
        if keyword and keyword not in instance.lower() and keyword not in path.lower():
            continue
        print(f"{used:>8}  {lines:>6}  {instance:<24} {path}")
