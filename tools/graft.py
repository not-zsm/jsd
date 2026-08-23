"""Graft instance subtrees from one place file into another, then sync every
script's Source from the repo.

Instances can reference blobs in the place's <SharedStrings> table (tags, mesh
data) by md5. Those entries live outside the subtree, so a graft that copies
only instances produces dangling references and Studio refuses to open the
file: "Unknown referenced shared string md5 ...".
"""
import argparse, collections, copy, json, os, sys, uuid
import lxml.etree as ET

SCRIPTS = {"Script", "LocalScript", "ModuleScript"}
SKIP_DIRS = (".git", "tools", "studio", "docs")


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


ZERO_ID = "0" * 32


def unique_ids(root):
    """Every non-zero <UniqueId name="UniqueId"> value in a tree."""
    out = set()
    for el in root.iter("UniqueId"):
        if el.get("name") != "UniqueId":
            continue
        value = (el.text or "").strip()
        if value and value != ZERO_ID:
            out.add(value)
    return out


def refresh_unique_ids(item, taken):
    """Give every instance in the subtree a UniqueId nothing else is using.

    Separate from the referent: Studio refuses to open a place whose data model
    holds the same UniqueId twice, and grafting a subtree out of the place it is
    already in duplicates every one of them.

    Roblox lays these out as machine bytes, then time, then an index, so a fresh
    24-hex prefix with a counter underneath both looks native and cannot collide
    with anything already in the file.
    """
    prefix = None
    while prefix is None or any(value.startswith(prefix) for value in taken):
        prefix = uuid.uuid4().hex[:24]

    issued = 0
    for node in item.iter("Item"):
        props = node.find("Properties")
        if props is None:
            continue
        for el in props:
            if el.tag != "UniqueId" or el.get("name") != "UniqueId":
                continue
            value = f"{prefix}{issued:08x}"
            el.text = value
            taken.add(value)
            issued += 1
    return issued


def refresh_referents(item):
    """Give every instance in the subtree a fresh referent, and repoint the
    <Ref> properties that named the old ones.

    Referents have to be unique within a place, so a graft has to regenerate
    them -- but PrimaryPart, Part0/Part1, Attachment0/Attachment1 and every
    ObjectValue name an instance by its referent. Renumbering without rewriting
    those leaves a Motor6D joined to nothing and a camera rig with no attach
    part, silently: Studio opens the place and the effect just does not work.
    """
    mapping = {}
    for node in item.iter("Item"):
        old = node.get("referent")
        new = "RBX" + uuid.uuid4().hex
        if old:
            mapping[old] = new
        node.set("referent", new)

    outside = []
    for el in item.iter("Ref"):
        value = (el.text or "").strip()
        if not value or value == "null":
            continue
        if value in mapping:
            el.text = mapping[value]
        else:
            # names something the graft is not copying; nothing in the
            # destination can satisfy it
            outside.append(el.get("name"))
            el.text = "null"
    return outside


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


def sync_sources(root, repo):
    """Point every script in the place at the repo's copy, creating any the
    place does not have yet.

    Runs before the grafts as well as after: a graft destination can be a
    module that only exists in the repo, and a grafted subtree can carry a
    script whose source in the place it came from is stale.
    """
    print("\nsyncing sources from repo:")
    target = repo_tree(repo)
    tree = index(root)
    sourced = created = 0

    for path, item in list(tree.items()):
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
        if path in tree:
            continue
        parent = tree.get(path[:-1])
        if parent is None:
            cursor = None
            for depth in range(1, len(path)):
                prefix = path[:depth]
                if prefix in tree:
                    cursor = tree[prefix]; continue
                if cursor is None:
                    break
                folder = ET.Element("Item", {"class": "Folder", "referent": "RBX" + uuid.uuid4().hex})
                props = ET.SubElement(folder, "Properties")
                n = ET.SubElement(props, "string", {"name": "Name"}); n.text = prefix[-1]
                cursor.append(folder); tree[prefix] = folder; cursor = folder
            parent = tree.get(path[:-1])
        if parent is None:
            print(f"  [no parent] {'.'.join(path)}"); continue
        item = ET.Element("Item", {"class": "ModuleScript", "referent": "RBX" + uuid.uuid4().hex})
        props = ET.SubElement(item, "Properties")
        n = ET.SubElement(props, "string", {"name": "Name"}); n.text = path[-1]
        src = ET.SubElement(props, "ProtectedString", {"name": "Source"}); src.text = ET.CDATA(target[path])
        parent.append(item); tree[path] = item
        created += 1
        print(f"  [created] {'.'.join(path)}")

    return sourced, created


def validate(root, label):
    ok = True

    table, _ = shared_table(root)
    missing = collections.Counter()
    for item in root.findall("Item"):
        for el in item.iter("SharedString"):
            if el.get("name") is None or not el.text:
                continue
            key = el.text.strip()
            if key not in table:
                missing[key] += 1
    if missing:
        ok = False
        print(f"  {label}: {len(missing)} dangling shared strings")
        for key, count in missing.most_common(10):
            print(f"    {key}  x{count}")
    else:
        print(f"  {label}: all shared-string references resolve ({len(table)} entries)")

    referents = {i.get("referent") for i in root.iter("Item")}
    dangling = collections.Counter()
    total = 0
    for el in root.iter("Ref"):
        value = (el.text or "").strip()
        if not value or value == "null":
            continue
        total += 1
        if value not in referents:
            dangling[el.get("name")] += 1
    if dangling:
        ok = False
        print(f"  {label}: {sum(dangling.values())} dangling instance refs")
        for name, count in dangling.most_common(10):
            print(f"    {name}  x{count}")
    else:
        print(f"  {label}: all {total} instance refs resolve")

    duplicates = collections.Counter(i.get("referent") for i in root.iter("Item"))
    clashes = [r for r, n in duplicates.items() if n > 1]
    if clashes:
        ok = False
        print(f"  {label}: {len(clashes)} duplicate referents")
    else:
        print(f"  {label}: all {len(duplicates)} referents unique")

    ids = collections.Counter()
    for el in root.iter("UniqueId"):
        if el.get("name") != "UniqueId":
            continue
        value = (el.text or "").strip()
        if value and value != ZERO_ID:
            ids[value] += 1
    repeated = {value: n for value, n in ids.items() if n > 1}
    if repeated:
        ok = False
        print(f"  {label}: {len(repeated)} duplicate UniqueIds")
        for value, n in list(repeated.items())[:10]:
            print(f"    {value}  x{n}")
    else:
        print(f"  {label}: all {len(ids)} UniqueIds unique")

    return ok


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--source", action="append", default=[], metavar="NAME=PATH",
                    help="a place to graft subtrees out of; repeatable")
    ap.add_argument("--grafts", required=True,
                    help="JSON list of {from, src, dst, name?}, paths as dotted strings; "
                         "name renames the subtree as it lands")
    ap.add_argument("--moves", help="JSON list of {src, dst} to reparent within the place")
    ap.add_argument("--deletes", help="JSON list of dotted paths to remove from the place")
    ap.add_argument("--new", required=True, help="place to graft into")
    ap.add_argument("--out", required=True)
    ap.add_argument("--repo", default="/home/user/jsd")
    args = ap.parse_args()

    manifest = json.load(open(args.grafts, encoding="utf-8"))
    wanted = {entry["from"] for entry in manifest}

    parser = ET.XMLParser(strip_cdata=False, huge_tree=True)
    new_tree = ET.parse(args.new, parser)
    new_root = new_tree.getroot()
    new_shared, new_shared_el = shared_table(new_root)
    new_index = index(new_root)

    sources = {}
    for spec in args.source:
        name, _, path = spec.partition("=")
        if name not in wanted:
            continue                      # don't parse a place nothing needs
        root = ET.parse(path, parser).getroot()
        shared, _ = shared_table(root)
        sources[name] = (index(root), shared)
        print(f"loaded source {name} from {path}")

    missing = wanted - set(sources)
    if missing:
        sys.exit(f"no --source given for: {', '.join(sorted(missing))}")

    sync_sources(new_root, args.repo)
    new_index = index(new_root)
    taken_ids = unique_ids(new_root)

    print("\ngrafting:")
    grafted = copied_blobs = 0
    for entry in manifest:
        src = tuple(entry["src"].split("."))
        dst = tuple(entry["dst"].split("."))
        landed = entry.get("name") or src[-1]
        old_index, old_shared = sources[entry["from"]]

        node, parent = old_index.get(src), new_index.get(dst)
        if node is None:
            print(f"  [missing in {entry['from']}] {'.'.join(src)}"); continue
        if parent is None:
            print(f"  [no destination] {'.'.join(dst)}"); continue
        if new_index.get(dst + (landed,)) is not None:
            print(f"  [already present] {'.'.join(dst + (landed,))}"); continue

        clone = copy.deepcopy(node)

        if landed != src[-1]:
            for el in clone.find("Properties"):
                if el.get("name") == "Name":
                    el.text = landed
                    break
        refresh_unique_ids(clone, taken_ids)
        outside = refresh_referents(clone)
        if outside:
            counts = collections.Counter(outside)
            print(f"  [!] {'.'.join(src)}: {len(outside)} refs point outside the "
                  f"subtree and were cleared ({dict(counts)})")
        for key in referenced_md5s(clone):
            if key in new_shared:
                continue
            blob = old_shared.get(key)
            if blob is None:
                print(f"  [!] {'.'.join(src)} references md5 {key}, absent from its table")
                continue
            carried = copy.deepcopy(blob)
            new_shared_el.append(carried)
            new_shared[key] = carried
            copied_blobs += 1
        parent.append(clone)
        new_index = index(new_root)       # a later graft may target this subtree
        size = len(clone.findall(".//Item")) + 1
        print(f"  grafted {size:>5} instances -> {'.'.join(dst + (landed,))}")
        grafted += 1

    print(f"\ncarried {copied_blobs} shared-string blobs")

    if args.moves:
        print("\nmoving:")
        tree = index(new_root)
        for entry in json.load(open(args.moves, encoding="utf-8")):
            src, dst = tuple(entry["src"].split(".")), tuple(entry["dst"].split("."))
            node, parent = tree.get(src), tree.get(dst)
            if node is None:
                print(f"  [not there] {entry['src']}"); continue
            if parent is None:
                print(f"  [no destination] {entry['dst']}"); continue
            # lxml detaches from the old parent on append, so a move keeps the
            # instance's referent and UniqueId -- nothing is duplicated
            parent.append(node)
            print(f"  {entry['src']}  ->  {entry['dst']}.{src[-1]}")
            tree = index(new_root)

    sourced, created = sync_sources(new_root, args.repo)
    print(f"\ngrafted {grafted} subtrees, sourced {sourced}, created {created}")

    if args.deletes:
        print("\ndeleting:")
        tree = index(new_root)
        for dotted in json.load(open(args.deletes, encoding="utf-8")):
            path = tuple(dotted.split("."))
            node = tree.get(path)
            if node is None:
                print(f"  [not there] {dotted}"); continue
            size = len(node.findall(".//Item")) + 1
            node.getparent().remove(node)
            print(f"  removed {size:>4} instances at {dotted}")
            tree = index(new_root)

    print("\nvalidating:")
    ok = validate(new_root, "output")
    new_tree.write(args.out, encoding="utf-8", xml_declaration=False)
    print(f"wrote {args.out}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
