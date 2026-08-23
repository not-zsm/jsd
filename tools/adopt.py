import sys, os, importlib.util
import lxml.etree as ET
spec = importlib.util.spec_from_file_location("graft", "/home/user/jsd/tools/graft.py")
g = importlib.util.module_from_spec(spec); spec.loader.exec_module(g)

root = ET.parse(sys.argv[1], ET.XMLParser(strip_cdata=False, huge_tree=True)).getroot()
tree = g.index(root)
repo = g.repo_tree("/home/user/jsd")

place = {p: it for p, it in tree.items() if it.get("class") in g.SCRIPTS}

def src_of(item):
    props = item.find("Properties")
    for c in props:
        if c.get("name") == "Source":
            return c.text or ""
    return ""

added   = sorted(set(place) - set(repo))
removed = sorted(set(repo) - set(place))
edited  = [p for p in sorted(set(repo) & set(place)) if src_of(place[p]) != repo[p][0]]

print(f"place {len(place)}  repo {len(repo)}")
print(f"\nIN PLACE, NOT IN REPO ({len(added)}):")
for p in added: print("   ", ".".join(p), place[p].get("class"))
print(f"\nIN REPO, NOT IN PLACE ({len(removed)}):")
for p in removed: print("   ", ".".join(p))
print(f"\nSOURCE DIFFERS ({len(edited)}):")
for p in edited: print("   ", ".".join(p))

if len(sys.argv) > 2 and sys.argv[2] == "--apply":
    SUF = {"Script": ".server.luau", "LocalScript": ".client.luau", "ModuleScript": ".luau"}
    for p in edited + added:
        cls = place[p].get("class")
        # this repo writes a parent module as X.luau beside X/, not X/init.luau,
        # and repo_tree maps both spellings to the same instance. Follow whichever
        # form is already on disk rather than assuming one.
        rel = os.path.join(*p)
        init = os.path.join(rel, "init" + SUF[cls])
        path = init if os.path.exists(init) else rel + SUF[cls]
        os.makedirs(os.path.dirname(path), exist_ok=True)
        open(path, "w", encoding="utf-8").write(src_of(place[p]))
    print(f"\nwrote {len(edited)} edited, {len(added)} added")
