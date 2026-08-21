#!/usr/bin/env python3
"""
Finds require() calls that do not resolve to a module in the tree.

Rojo maps folders to instances, so a require path like
`ReplicatedStorage.Modules.Shared.Utilities.Utility` is a filesystem path once
the service name is mapped to its top-level directory. Anything that does not
resolve is a module that will not exist at runtime.

Plenty of requires legitimately point at instances built in Studio rather than
checked into the tree (Animations, Remotes, ...). Those are unresolvable both
before and after an edit, so run this against two trees and diff:

    tools/check_requires.py <tree> [<tree> ...]

Prints one line per unresolved require as `path:line -> require path`.
"""
import os
import re
import sys

SERVICES = {
    "ReplicatedStorage", "ServerScriptService", "ServerStorage",
    "ReplicatedFirst", "StarterGui", "StarterPlayer", "Workspace",
    "StarterPack", "Lighting", "SoundService", "Chat", "Teams",
}

# require( <path> ) up to the matching paren on one line.
REQUIRE = re.compile(r"require\s*\(\s*([^)]*?)\s*\)")

# A leading `game:GetService("X")` / `game.X`, then dotted or ["quoted"] segments.
SEGMENT = re.compile(r'\.\s*([A-Za-z_][A-Za-z0-9_]*)|\[\s*"([^"]+)"\s*\]|:\s*WaitForChild\(\s*"([^"]+)"\s*\)')


def module_paths(root):
    """Every instance path the tree provides, as tuples of names."""
    provided = set()

    for directory, dirnames, filenames in os.walk(root):
        if ".git" in directory.split(os.sep):
            continue

        relative = os.path.relpath(directory, root)
        base = () if relative == "." else tuple(relative.split(os.sep))

        if base:
            provided.add(base)

        for name in filenames:
            for suffix in (".server.luau", ".client.luau", ".luau"):
                if name.endswith(suffix):
                    stem = name[: -len(suffix)]
                    if stem == "init":
                        provided.add(base)
                    else:
                        provided.add(base + (stem,))
                    break

    return provided


def parse_path(expression):
    """The instance path a require expression names, or None if not static."""
    expression = expression.strip()

    if expression.startswith(("'", '"')):
        return None  # relative string require; resolved separately

    head = re.match(r'game\s*:\s*GetService\(\s*"([A-Za-z]+)"\s*\)', expression)
    if head:
        root, rest = head.group(1), expression[head.end():]
    else:
        head = re.match(r"(?:game\s*\.\s*)?([A-Za-z_][A-Za-z0-9_]*)", expression)
        if not head:
            return None
        root, rest = head.group(1), expression[head.end():]

    if root not in SERVICES:
        return None  # a local alias (script, Modules, ...) -- not resolvable statically

    segments = [root]
    position = 0

    while position < len(rest):
        match = SEGMENT.match(rest, position)
        if not match:
            # Something dynamic (a variable index, a call). Stop and check the
            # prefix we did understand.
            break
        segments.append(next(g for g in match.groups() if g is not None))
        position = match.end()

    return tuple(segments)


def check(root):
    provided = module_paths(root)
    problems = []

    for directory, dirnames, filenames in os.walk(root):
        if ".git" in directory.split(os.sep):
            continue

        for name in sorted(filenames):
            if not name.endswith(".luau"):
                continue

            path = os.path.join(directory, name)
            relative = os.path.relpath(path, root)

            with open(path, encoding="utf-8", errors="replace") as handle:
                for number, line in enumerate(handle, 1):
                    stripped = line.lstrip()
                    if stripped.startswith("--"):
                        continue

                    for match in REQUIRE.finditer(line):
                        target = parse_path(match.group(1))

                        if target and target not in provided:
                            problems.append(f"{relative}:{number} -> {'.'.join(target)}")

    return problems


if __name__ == "__main__":
    roots = sys.argv[1:] or ["."]

    for root in roots:
        found = check(root)
        print(f"=== {root}: {len(found)} unresolved ===")
        for line in found:
            print(f"  {line}")
