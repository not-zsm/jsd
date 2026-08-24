"""Rename instances in a place, addressed by full dotted path.

    python3 tools/rename.py PLACE OUT renames.json

renames.json is a list of {"path": "A.B.C", "name": "c"}. Every path must
match exactly one instance -- an ambiguous or missing path is an error, not
a skip, so a typo cannot silently leave the place half-renamed.

Deeper paths are applied first, so renaming a parent never invalidates the
path of a child listed alongside it.
"""
import json
import sys
import lxml.etree as ET

place, out, manifest = sys.argv[1:4]
renames = json.load(open(manifest, encoding="utf-8"))

def name_of(item):
    props = item.find("Properties")
    if props is None:
        return None
    for el in props:
        if el.get("name") == "Name":
            return el.text
    return None

root = ET.parse(place, ET.XMLParser(strip_cdata=False, huge_tree=True)).getroot()

index = {}
def walk(node, trail):
    for item in node.findall("Item"):
        here = trail + [name_of(item) or "?"]
        index.setdefault(".".join(here), []).append(item)
        walk(item, here)
walk(root, [])

problems = []
for entry in renames:
    hits = index.get(entry["path"], [])
    if len(hits) != 1:
        problems.append(f'{entry["path"]}: matched {len(hits)}, expected 1')

if problems:
    sys.exit("\n".join(problems))

# deepest first, so a parent rename never breaks a child's path
for entry in sorted(renames, key=lambda e: e["path"].count("."), reverse=True):
    item = index[entry["path"]][0]
    for el in item.find("Properties"):
        if el.get("name") == "Name":
            el.text = entry["name"]
    print(f'  {entry["path"]} -> {entry["name"]}')

ET.ElementTree(root).write(out, xml_declaration=False, encoding="utf-8")
print(f"\nrenamed {len(renames)} instances, wrote {out}")
