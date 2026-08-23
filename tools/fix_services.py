#!/usr/bin/env python3
"""Add missing `local X = game:GetService("X")` declarations, and drop ones
nothing uses.

Moving something across services leaves files naming a service they never
declared. Luau compiles it fine -- the global is just nil -- so it only shows up
at runtime, and only on the line that touches it.

  fix_services.py [--apply]
"""
import os
import re
import sys

# Workspace is deliberately absent: `workspace` is a global, so a file that
# says workspace.Map needs no declaration and adding one would shadow it.
SERVICES = ["ReplicatedStorage", "ServerScriptService", "ServerStorage",
            "ReplicatedFirst", "StarterGui", "StarterPlayer",
            "Players", "RunService", "TweenService", "Debris", "CollectionService"]
SKIP = {".git", "tools", "studio", "docs", "Packages"}

# a declaration counts wherever it is -- the system wrappers put theirs inside
# Start -- but a new one is only ever inserted at file level
# either quote style: the ported jjk helpers use single
DECLARE = re.compile(r'^[ \t]*local\s+(\w+)\s*=\s*game:GetService\(\s*[\'"](\w+)[\'"]\s*\)\s*$', re.M)
TOP_LEVEL = re.compile(r'^local\s+(\w+)\s*=\s*game:GetService\(\s*[\'"](\w+)[\'"]\s*\)\s*$', re.M)


def files(root="."):
    for d, _, names in os.walk(root):
        if any(p in SKIP for p in d.split(os.sep)):
            continue
        for n in names:
            if n.endswith(".luau"):
                yield os.path.join(d, n)


BLOCK_COMMENT = re.compile(r'--\[(=*)\[.*?\]\1\]', re.S)


def local_name(text, service):
    """What this file calls the service, honouring its prevailing convention.

    The codebase moved its service locals to camelCase, so a file may declare
    `local replicatedStorage = game:GetService("ReplicatedStorage")`. A new
    declaration should match whichever style the file already uses.
    """
    for m in TOP_LEVEL.finditer(text):
        if m.group(1)[:1].islower():
            return service[0].lower() + service[1:]

    return service


def uses(text, service):
    """Is the service actually indexed or called here?

    Three things read as a use to a naive match and none of them wants a
    GetService call: `RunService: RunService,` in a type, the word inside a
    comment, and a module that happens to name its own table after a service --
    DebrisPool's `local Debris = {}` would be shadowed into a broken state.
    """
    names = {service, service[0].lower() + service[1:]}

    for name in names:
        if re.search(rf'local\s+{name}\b(?!\s*=\s*game\s*:\s*GetService)', text):
            return False

    alternation = "|".join(sorted(names, key=len, reverse=True))
    pattern = re.compile(rf'(?<![.\w])(?:{alternation})\s*(?:\.\s*\w|\[|:\s*\w+\s*\()')

    for line in BLOCK_COMMENT.sub("", text).splitlines():
        if pattern.search(line.split("--", 1)[0]):
            return True

    return False


def main():
    apply = "--apply" in sys.argv
    added = removed = 0

    for path in files():
        text = open(path, encoding="utf-8", errors="replace").read()
        declared = {m.group(1): m.group(2) for m in DECLARE.finditer(text)}
        new = text

        for service in SERVICES:
            used = uses(new, service)

            if used and service not in declared.values():
                name = local_name(new, service)
                line = f'local {name} = game:GetService("{service}")'
                last = None
                for m in TOP_LEVEL.finditer(new):
                    last = m
                if last:
                    new = new[:last.end()] + "\n" + line + new[last.end():]
                else:
                    new = line + "\n" + new
                declared[name] = service
                added += 1
                print(f"  + {name:<22} {path}")

        # a declaration whose name appears nowhere else is dead weight
        for name, service in list(declared.items()):
            if len(re.findall(rf'(?<![.\w]){name}(?![\w])', new)) == 1 and TOP_LEVEL.search(new):
                new = re.sub(rf'^local\s+{name}\s*=\s*game:GetService\(\s*[\'"]{service}[\'"]\s*\)\s*\n', "", new, count=1, flags=re.M)
                removed += 1
                print(f"  - {service:<22} {path}")

        if new != text and apply:
            open(path, "w", encoding="utf-8").write(new)

    print(f"\n{added} added, {removed} removed" + ("" if apply else "  (dry run, pass --apply)"))


if __name__ == "__main__":
    main()
