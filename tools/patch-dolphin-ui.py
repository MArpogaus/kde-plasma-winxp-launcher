#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Turn Dolphin's dolphinui.rc into an XP Explorer layout.

Main toolbar: Back, Forward, Up | Search, Folders | Views, with text next to
Back, Search and Folders (text beside icons, 24 px icons, set in the file
itself); the address bar gets its own row below. The
version attribute is kept, so a newer Dolphin simply ignores the file.
"""
import re
import sys

TOOLBARS = """<ToolBar noMerge="1" name="mainToolBar" iconText="icontextright" iconSize="24" >
        <text context="@title:menu">Main Toolbar</text>
        <Action name="go_back" />
        <Action name="go_forward" />
        <Action name="go_up" />
        <Separator />
        <Action name="toggle_search" />
        <Action name="show_folders_panel" />
        <Separator />
        <Action name="view_mode" />
    </ToolBar>
    <ToolBar noMerge="1" name="addressToolBar" newline="true" >
        <text context="@title:menu">Address Bar</text>
        <Action name="url_navigators" />
    </ToolBar>"""

# QAction::Priority: 0 (Low) = icon only, 128 (Normal) = icon and text in
# "text beside icon" toolbar mode
PRIORITIES = {"go_back": 128, "toggle_search": 128, "show_folders_panel": 128}


def main():
    src, dst = sys.argv[1], sys.argv[2]
    with open(src) as f:
        ui = f.read()
    ui, n = re.subn(r"<ToolBar[^>]*name=\"mainToolBar\".*?</ToolBar>", TOOLBARS, ui, flags=re.S)
    if n != 1:
        sys.exit("mainToolBar not found")

    def prio(match):
        name = match.group(2)
        return f'{match.group(1)}{PRIORITIES.get(name, 0)}" name="{name}"/>'
    ui = re.sub(r'(<Action priority=")\d+" name="([^"]+)"\s*/>', prio, ui)
    for name, value in PRIORITIES.items():
        if f'name="{name}"' not in ui.split("<ActionProperties", 1)[-1]:
            ui = ui.replace("</ActionProperties>", f'    <Action priority="{value}" name="{name}"/>\n    </ActionProperties>', 1)
    with open(dst, "w") as f:
        f.write(ui)


if __name__ == "__main__":
    main()
