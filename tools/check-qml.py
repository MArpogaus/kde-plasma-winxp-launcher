#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Flag QML property declarations that shadow built-in Item/Window
properties (e.g. "top", "palette"), which Qt rejects with
"Cannot override FINAL property" when the widget loads.

Needs PySide6 (pip install pyside6-essentials); run from the repo root.
"""
import pathlib
import re
import sys

from PySide6.QtQuick import QQuickItem, QQuickWindow


def names(cls):
    mo = cls.staticMetaObject
    return {mo.property(i).name() for i in range(mo.propertyCount())}


# Item's anchor lines are QML-only properties, not in the C++ meta object
item = names(QQuickItem) | {"top", "bottom", "left", "right", "horizontalCenter", "verticalCenter",
                            "baseline", "anchors", "palette", "states", "transitions", "layer"}
window = names(QQuickWindow)
# Root types of our files that are windows rather than items
window_roots = re.compile(r"^(?:\w+\.)?(?:Dialog|SubMenu|Window|ApplicationWindow)\s*\{", re.M)
decl = re.compile(r"^\s*(?:required\s+|readonly\s+|default\s+)*property\s+[\w.<>]+\s+(\w+)")
problems = 0
for path in sorted(pathlib.Path(".").glob("**/*.qml")):
    text = path.read_text()
    body = re.sub(r"(?s)/\*.*?\*/", "", text)
    root = re.search(r"^[A-Z][\w.]*\s*\{", body, re.M)
    builtin = window if root and window_roots.match(root.group(0)) else item
    for number, line in enumerate(text.splitlines(), 1):
        m = decl.match(line)
        if m and m.group(1) in builtin:
            print(f"{path}:{number}: property '{m.group(1)}' shadows a built-in property")
            problems += 1
sys.exit(1 if problems else 0)
