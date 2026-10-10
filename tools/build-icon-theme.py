#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Assemble xfce-winxp-tc's XP icons into a freedesktop icon theme.

The source keeps one PNG per icon and size in ``res/<size>/<name>.png`` and a
``mappings`` file with lines ``<context>/<freedesktop name>--><name>``. The
theme is written as ``<size>/<context>/<freedesktop name>.png`` copies, with
an index.theme that inherits the given fallback themes.
"""
import argparse
import os
import re
import shutil
import sys


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--source", required=True, help="xfce-winxp-tc icons/luna directory")
    ap.add_argument("--out", required=True)
    ap.add_argument("--name", default="Windows XP (Luna)")
    ap.add_argument("--inherits", default="Luna,breeze,hicolor")
    args = ap.parse_args()

    res = os.path.join(args.source, "res")
    sizes = sorted(d for d in os.listdir(res) if re.fullmatch(r"\d+x\d+", d))
    written = 0
    with open(os.path.join(args.source, "mappings")) as f:
        for line in f:
            line = line.strip()
            if "-->" not in line:
                continue
            target, name = (part.strip() for part in line.split("-->", 1))
            context, fdo = target.split("/", 1)
            for size in sizes:
                src = os.path.join(res, size, name + ".png")
                if not os.path.exists(src):
                    continue
                dst_dir = os.path.join(args.out, size, context)
                os.makedirs(dst_dir, exist_ok=True)
                shutil.copyfile(src, os.path.join(dst_dir, fdo + ".png"))
                written += 1

    symbolic = os.path.join(res, "svg")
    if os.path.isdir(symbolic):
        shutil.copytree(symbolic, os.path.join(args.out, "symbolic", "ui"), dirs_exist_ok=True)

    with open(os.path.join(args.source, "index.theme")) as f:
        index = f.read()
    index = re.sub(r"(?m)^Name=.*$", f"Name={args.name}", index, count=1)
    if re.search(r"(?m)^Inherits=", index):
        index = re.sub(r"(?m)^Inherits=.*$", f"Inherits={args.inherits}", index, count=1)
    else:
        index = index.replace("[Icon Theme]\n", f"[Icon Theme]\nInherits={args.inherits}\n", 1)
    with open(os.path.join(args.out, "index.theme"), "w") as f:
        f.write(index)
    print(f"{args.name}: {written} icons -> {args.out}")
    return 0 if written else 1


if __name__ == "__main__":
    sys.exit(main())
