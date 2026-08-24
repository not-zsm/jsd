"""Set a property on one instance in a place.

    python3 tools/setprop.py PLACE OUT StarterGui.Emotes ResetOnSpawn bool false

Only touches properties the instance already has -- it will not invent one,
since a property Roblox did not serialise is one this class may not accept.
"""
import sys
import lxml.etree as ET

place, out, path, prop, tag, value = sys.argv[1:7]
want = path.split(".")

def name_of(item):
    props = item.find("Properties")
    if props is None:
        return None
    for el in props:
        if el.get("name") == "Name":
            return el.text
    return None

root = ET.parse(place, ET.XMLParser(strip_cdata=False, huge_tree=True)).getroot()

def walk(node, trail):
    for item in node.findall("Item"):
        here = trail + [name_of(item) or "?"]
        yield item, here
        yield from walk(item, here)

hits = [it for it, here in walk(root, []) if here == want]

if len(hits) != 1:
    sys.exit(f"{path}: matched {len(hits)} instances, expected 1")

props = hits[0].find("Properties")
found = [el for el in props if el.get("name") == prop]

if not found:
    sys.exit(f"{path} has no serialised {prop}")

before = found[0].text
found[0].tag = tag
found[0].text = value
print(f"{path}.{prop}: {before} -> {value}")

ET.ElementTree(root).write(out, xml_declaration=False, encoding="utf-8")
print(f"wrote {out}")
