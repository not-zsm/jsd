"""Graft instance subtrees from one place file into another, then sync every
script's Source from the repo.

Instances can reference blobs in the place's <SharedStrings> table (tags, mesh
data) by md5. Those entries live outside the subtree, so a graft that copies
only instances produces dangling references and Studio refuses to open the
file: "Unknown referenced shared string md5 ...".
"""
import argparse, copy, os, sys, uuid
import lxml.etree as ET

SCRIPTS = {"Script", "LocalScript", "ModuleScript"}
SKIP_DIRS = (".git", "tools", "studio", "docs")

GRAFTS = [
 (("ReplicatedStorage","Modules","Player","Replication","VFX","Invincible"),
  ("ReplicatedStorage","Client","Replication","VFX")),
 (("ServerScriptService","Scripts","Game","Modules","Player","Character","Combat","Attacks","List","Invincible"),
  ("ServerStorage","serverCombat","Attacks","List")),
 (("ServerScriptService","Scripts","Game","Modules","Player","Character","Combat","Characters","Invincible"),
  ("ServerStorage","serverCombat","Characters")),
 (("ReplicatedStorage","Animations","Attacks","Invincible"),
  ("ReplicatedStorage","Animations","Attacks")),
 (("ReplicatedStorage","Animations","Attacks","Global","Ultimate","Invincible"),
  ("ReplicatedStorage","Animations","Attacks","Global","Ultimate")),
 (("ReplicatedStorage","Animations","Attacks","Global","Dash","WallCombo","Invincible"),
  ("ReplicatedStorage","Animations","Attacks","Global","Dash","WallCombo")),
]


def name_of(item):
    props = item.find("Properties")
    if props is None:
        return None
    for child in props:
        if child.get("name") == "Name":
            return child.text
    return None


def index(root):
    out = {}
    def walk(item, path):
        n = name_of(item)
        if n is None:
            return
        p = path + (n,)
        out[p] = item
        for c in item.findall("Item"):
            walk(c, p)
    for item in root.findall("Item"):
        walk(item, ())
    return out


def shared_table(root):
    """md5 -> <SharedString> element, plus the container (created if absent)."""
    container = root.find("SharedStrings")
    if container is None:
        container = ET.SubElement(root, "SharedStrings")
    return {e.get("md5"): e for e in container.findall("SharedString")}, container


def referenced_md5s(node):
    """Every shared-string md5 referenced by node or its descendants.

    A reference is <SharedString name="Prop">md5</SharedString>; a table entry
    is <SharedString md5="...">blob</SharedString>. Only the former has name.
    """
    out = set()
    for el in node.iter("SharedString"):
        if el.get("name") is not None and el.text:
            out.add(el.text.strip())
    return out


def refresh_referents(item):
    for node in item.iter("Item"):
        node.set("referent", "RBX" + uuid.uuid4().hex)


def repo_tree(repo):
    out = {}
    for d, _, files in os.walk(repo):
        parts = d.split(os.sep)
        if any(x in parts for x in SKIP_DIRS):
            continue
        for f in files:
            if not f.endswith(".luau"):
                continue
            full = os.path.join(d, f)
            rel = os.path.relpath(full, repo).split(os.sep)
            last = rel[-1]
            for suf in (".server.luau", ".client.luau", ".luau"):
                if last.endswith(suf):
                    last = last[:-len(suf)]
                    break
            key = tuple(rel[:-1]) if last == "init" else tuple(rel[:-1]) + (last,)
            out[key] = open(full, encoding="utf-8", errors="replace").read()
    return out


def validate(root, label):
    table, _ = shared_table(root)
    missing = {}
    for item in root.findall("Item"):
        for el in item.iter("SharedString"):
            if el.get("name") is None or not el.text:
                continue
            key = el.text.strip()
            if key not in table:
                missing[key] = missing.get(key, 0) + 1
    if missing:
        print(f"  {label}: {len(missing)} dangling shared strings")
        for key, count in sorted(missing.items(), key=lambda kv: -kv[1])[:10]:
            print(f"    {key}  x{count}")
        return False
    print(f"  {label}: all shared-string references resolve ({len(table)} entries)")
    return True


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--old", required=True, help="place to graft subtrees from")
    ap.add_argument("--new", required=True, help="place to graft into")
    ap.add_argument("--out", required=True)
    ap.add_argument("--repo", default="/home/user/jsd")
    args = ap.parse_args()

    parser = ET.XMLParser(strip_cdata=False, huge_tree=True)
    old_root = ET.parse(args.old, parser).getroot()
    new_tree = ET.parse(args.new, parser)
    new_root = new_tree.getroot()

    old_shared, _ = shared_table(old_root)
    new_shared, new_shared_el = shared_table(new_root)
    old_index, new_index = index(old_root), index(new_root)

    print("grafting:")
    grafted = copied_blobs = 0
    for src, dst in GRAFTS:
        node, parent = old_index.get(src), new_index.get(dst)
        if node is None:
            print(f"  [missing in old] {'.'.join(src)}"); continue
        if parent is None:
            print(f"  [no destination] {'.'.join(dst)}"); continue
        if new_index.get(dst + (src[-1],)) is not None:
            print(f"  [already present] {'.'.join(dst + (src[-1],))}"); continue

        clone = copy.deepcopy(node)
        refresh_referents(clone)          # referents must be unique within a place
        for key in referenced_md5s(clone):
            if key in new_shared:
                continue
            entry = old_shared.get(key)
            if entry is None:
                print(f"  [!] {'.'.join(src)} references md5 {key}, absent from old table")
                continue
            carried = copy.deepcopy(entry)
            new_shared_el.append(carried)
            new_shared[key] = carried
            copied_blobs += 1
        parent.append(clone)
        size = len(clone.findall(".//Item")) + 1
        print(f"  grafted {size:>5} instances -> {'.'.join(dst + (src[-1],))}")
        grafted += 1

    print(f"\ncarried {copied_blobs} shared-string blobs")

    print("\nsyncing sources from repo:")
    target = repo_tree(args.repo)
    new_index = index(new_root)
    sourced = created = 0

    for path, item in list(new_index.items()):
        if item.get("class") not in SCRIPTS:
            continue
        text = target.get(path)
        if text is None:
            continue
        props = item.find("Properties")
        el = next((c for c in props if c.get("name") == "Source"), None)
        if el is None:
            el = ET.SubElement(props, "ProtectedString", {"name": "Source"})
        el.text = ET.CDATA(text)
        sourced += 1

    for path in sorted(target, key=len):
        if path in new_index:
            continue
        parent = new_index.get(path[:-1])
        if parent is None:
            cursor = None
            for depth in range(1, len(path)):
                prefix = path[:depth]
                if prefix in new_index:
                    cursor = new_index[prefix]; continue
                if cursor is None:
                    break
                folder = ET.Element("Item", {"class": "Folder", "referent": "RBX" + uuid.uuid4().hex})
                props = ET.SubElement(folder, "Properties")
                n = ET.SubElement(props, "string", {"name": "Name"}); n.text = prefix[-1]
                cursor.append(folder); new_index[prefix] = folder; cursor = folder
            parent = new_index.get(path[:-1])
        if parent is None:
            print(f"  [no parent] {'.'.join(path)}"); continue
        item = ET.Element("Item", {"class": "ModuleScript", "referent": "RBX" + uuid.uuid4().hex})
        props = ET.SubElement(item, "Properties")
        n = ET.SubElement(props, "string", {"name": "Name"}); n.text = path[-1]
        s = ET.SubElement(props, "ProtectedString", {"name": "Source"}); s.text = ET.CDATA(target[path])
        parent.append(item); new_index[path] = item
        created += 1
        print(f"  [created] {'.'.join(path)}")

    print(f"\ngrafted {grafted} subtrees, sourced {sourced}, created {created}")

    print("\nvalidating:")
    ok = validate(new_root, "output")
    new_tree.write(args.out, encoding="utf-8", xml_declaration=False)
    print(f"wrote {args.out}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
