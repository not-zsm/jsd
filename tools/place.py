#!/usr/bin/env python3
"""Read a .rbxlx and dump or extract its script tree.

  place.py <file> tree [prefix]     print script paths
  place.py <file> dump <outdir>     write every script to disk
  place.py <file> cat <path>        print one script's source
"""
import lxml.etree as ET
import os
import sys

SCRIPTS = {"Script": ".server.luau", "LocalScript": ".client.luau", "ModuleScript": ".luau"}


def name_of(item):
    props = item.find("Properties")
    if props is None:
        return None
    for child in props:
        if child.get("name") == "Name":
            return child.text
    return None


def source_of(item):
    props = item.find("Properties")
    if props is None:
        return None
    for child in props:
        if child.get("name") == "Source":
            return child.text or ""
    return None


def load(path):
    parser = ET.XMLParser(strip_cdata=False, huge_tree=True)
    return ET.parse(path, parser).getroot()


def scripts(root):
    """instance path -> (class, source), in document order."""
    out = {}

    def walk(item, path):
        n = name_of(item)
        if n is None:
            return
        p = path + (n,)
        if item.get("class") in SCRIPTS:
            out[p] = (item.get("class"), source_of(item))
        for child in item.findall("Item"):
            walk(child, p)

    for item in root.findall("Item"):
        walk(item, ())
    return out


if __name__ == "__main__":
    path, mode = sys.argv[1], sys.argv[2]
    found = scripts(load(path))

    if mode == "tree":
        prefix = sys.argv[3] if len(sys.argv) > 3 else ""
        for key in sorted(found):
            joined = ".".join(key)
            if joined.startswith(prefix):
                print(f"{found[key][0][:1]}  {joined}")

    elif mode == "dump":
        out = sys.argv[3]
        for key, (cls, src) in found.items():
            rel = os.path.join(*key) + SCRIPTS[cls]
            full = os.path.join(out, rel)
            os.makedirs(os.path.dirname(full), exist_ok=True)
            open(full, "w", encoding="utf-8").write(src or "")
        print(f"wrote {len(found)} scripts to {out}")

    elif mode == "cat":
        want = tuple(sys.argv[3].split("."))
        entry = found.get(want)
        print(entry[1] if entry else f"not found: {sys.argv[3]}")
