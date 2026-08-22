#!/usr/bin/env python3
"""Run the lean/lerp pose checks against lean.client.luau.

The Luau CLI sandboxes each chunk's globals, so the stubs, the script under
test and the checks are concatenated into a single chunk and run as one.

  tools/leantest.py [--script PATH] [--luau PATH]
"""
import argparse
import os
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
DEFAULT_SCRIPT = os.path.join(REPO, "StarterPlayer/StarterCharacterScripts/stuff/lean.client.luau")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--script", default=DEFAULT_SCRIPT)
    ap.add_argument("--luau", default=shutil.which("luau"))
    args = ap.parse_args()

    if not args.luau or not os.path.exists(args.luau):
        sys.exit("no luau binary; pass --luau PATH")

    def read(name):
        return open(os.path.join(HERE, "leantest", name), encoding="utf-8").read()

    harness = read("harness.luau").replace("return {\n\tworld = world,", "local harness = {\n\tworld = world,", 1)
    script = open(args.script, encoding="utf-8").read()

    # PreRender parallel connections and task.synchronize have no meaning
    # offline; the pose maths either side of them is what is under test
    script = script.replace("RunService.PreRender:ConnectParallel(", "RunService.PreRender:Connect(")
    script = script.replace("\ttask.synchronize()\n", "")

    chunk = "\n".join([harness, "local function leanMain()", script, "end", read("tests.luau")])

    with tempfile.NamedTemporaryFile("w", suffix=".luau", delete=False, encoding="utf-8") as f:
        f.write(chunk)
        path = f.name
    try:
        return subprocess.call([args.luau, path])
    finally:
        os.unlink(path)


if __name__ == "__main__":
    sys.exit(main())
