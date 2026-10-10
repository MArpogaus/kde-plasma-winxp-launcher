#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Build an Xcursor theme from PNG images without xcursorgen.

Reads xcursorgen style config files (one image per line:
``<nominal size> <xhot> <yhot> <png path> [<delay ms>]``) and writes one
Xcursor file per config, plus symlinks for alias names.

Two input layouts are supported:

* ``--config-dir DIR``: ``DIR/<name>.cursor`` or ``DIR/<name>.cfg`` files,
  PNG paths relative to ``--png-root``.
* ``--aliases FILE``: lines ``<alias> <target>`` (modernXP ``cursorList``) or
  ``<alias>--><target>`` (xfce-winxp-tc ``mappings``).

Only 8-bit RGBA / RGB non-interlaced PNGs are supported, which is what
Inkscape, rsvg-convert and the theme sources produce.
"""
import argparse
import os
import struct
import sys
import zlib


def read_png(path):
    """Return (width, height, rows) with rows as lists of (r, g, b, a)."""
    with open(path, "rb") as f:
        data = f.read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"{path}: not a PNG")
    pos = 8
    idat = b""
    width = height = None
    while pos < len(data):
        (length,) = struct.unpack(">I", data[pos:pos + 4])
        ctype = data[pos + 4:pos + 8]
        chunk = data[pos + 8:pos + 8 + length]
        pos += 12 + length
        if ctype == b"IHDR":
            width, height, depth, color, _, _, interlace = struct.unpack(">IIBBBBB", chunk)
            if depth != 8 or color not in (2, 6) or interlace:
                raise ValueError(f"{path}: unsupported PNG (depth {depth}, color {color}, interlace {interlace})")
            channels = 4 if color == 6 else 3
        elif ctype == b"IDAT":
            idat += chunk
        elif ctype == b"IEND":
            break
    raw = zlib.decompress(idat)
    stride = width * channels
    rows = []
    prev = bytearray(stride)
    i = 0
    for _ in range(height):
        ftype = raw[i]
        line = bytearray(raw[i + 1:i + 1 + stride])
        i += 1 + stride
        for x in range(stride):
            a = line[x - channels] if x >= channels else 0
            b = prev[x]
            c = prev[x - channels] if x >= channels else 0
            if ftype == 1:
                line[x] = (line[x] + a) & 0xFF
            elif ftype == 2:
                line[x] = (line[x] + b) & 0xFF
            elif ftype == 3:
                line[x] = (line[x] + ((a + b) >> 1)) & 0xFF
            elif ftype == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pred = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
                line[x] = (line[x] + pred) & 0xFF
        prev = line
        if channels == 4:
            rows.append([tuple(line[x:x + 4]) for x in range(0, stride, 4)])
        else:
            rows.append([tuple(line[x:x + 3]) + (255,) for x in range(0, stride, 3)])
    return width, height, rows


def xcursor_bytes(images):
    """images: list of (nominal, xhot, yhot, delay, width, height, rows)."""
    header_size = 16
    toc_size = 12 * len(images)
    out = bytearray()
    out += struct.pack("<4sIII", b"Xcur", header_size, 0x10000, len(images))
    offset = header_size + toc_size
    chunks = []
    for nominal, xhot, yhot, delay, w, h, rows in images:
        pixels = bytearray()
        for row in rows:
            for r, g, b, a in row:
                # Xcursor wants premultiplied ARGB, little endian
                pr, pg, pb = (r * a + 127) // 255, (g * a + 127) // 255, (b * a + 127) // 255
                pixels += struct.pack("<I", (a << 24) | (pr << 16) | (pg << 8) | pb)
        chunk = struct.pack("<IIIIIIIII", 36, 0xFFFD0002, nominal, 1, w, h, xhot, yhot, delay) + bytes(pixels)
        out += struct.pack("<III", 0xFFFD0002, nominal, offset)
        offset += len(chunk)
        chunks.append(chunk)
    for chunk in chunks:
        out += chunk
    return bytes(out)


def resolve_png(png_root, nominal, rel):
    """Find the image for a config line, tolerating common typos in theme
    sources: wrong size directory (e.g. 72/ for 96/) and _ vs - in names."""
    directory, name = os.path.split(rel)
    names = [name, name.replace("_", "-"), name.replace("-", "_")]
    for d in (directory, str(nominal)):
        for n in names:
            candidate = os.path.join(png_root, d, n)
            if os.path.exists(candidate):
                return candidate
    return None


def parse_config(path, png_root):
    images = []
    with open(path) as f:
        for line in f:
            parts = line.split()
            if len(parts) < 4 or line.lstrip().startswith("#"):
                continue
            # "96 /right-arrow.png" style typo: path split by a space
            if len(parts) > 4 and parts[4].startswith("/"):
                parts[3:5] = [parts[3] + parts[4]]
            nominal, xhot, yhot = int(parts[0]), int(parts[1]), int(parts[2])
            delay = int(parts[4]) if len(parts) > 4 else 50  # xcursorgen default
            png = resolve_png(png_root, nominal, parts[3])
            if png is None:
                print(f"warning: {os.path.basename(path)}: missing {parts[3]}, skipped", file=sys.stderr)
                continue
            w, h, rows = read_png(png)
            images.append((nominal, min(xhot, w - 1), min(yhot, h - 1), delay, w, h, rows))
    return images


def parse_aliases(path):
    pairs = []
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "-->" in line:
                alias, target = line.split("-->", 1)
            else:
                alias, target = line.split(None, 1)
            pairs.append((alias.strip(), target.strip()))
    return pairs


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--config-dir", required=True)
    ap.add_argument("--png-root", required=True)
    ap.add_argument("--aliases")
    ap.add_argument("--out", required=True, help="theme directory to create")
    ap.add_argument("--name", required=True, help="theme name for index.theme")
    args = ap.parse_args()

    cursors = os.path.join(args.out, "cursors")
    os.makedirs(cursors, exist_ok=True)
    built = set()
    for entry in sorted(os.listdir(args.config_dir)):
        base, ext = os.path.splitext(entry)
        if ext not in (".cursor", ".cfg"):
            continue
        images = parse_config(os.path.join(args.config_dir, entry), args.png_root)
        if not images:
            continue
        with open(os.path.join(cursors, base), "wb") as f:
            f.write(xcursor_bytes(images))
        built.add(base)

    linked = 0
    if args.aliases:
        for alias, target in parse_aliases(args.aliases):
            link = os.path.join(cursors, alias)
            if target not in built or os.path.lexists(link):
                continue
            os.symlink(target, link)
            linked += 1

    with open(os.path.join(args.out, "index.theme"), "w") as f:
        f.write(f"[Icon Theme]\nName={args.name}\nComment={args.name} cursors\n")
    print(f"{args.name}: {len(built)} cursors, {linked} aliases -> {args.out}")
    return 0 if built else 1


if __name__ == "__main__":
    sys.exit(main())
