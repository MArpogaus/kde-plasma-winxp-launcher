#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Assemble xfce-winxp-tc's XP icons into a freedesktop icon theme.

The source keeps one PNG per icon and size in ``res/<size>/<name>.png`` and a
``mappings`` file with lines ``<context>/<freedesktop name>--><name>``. The
theme is written as ``<size>/<context>/<freedesktop name>.png`` copies, with
an index.theme that inherits the given fallback themes.

KIconLoader prefers an exact size from any theme, the fallbacks included,
over a near size from this one. XP only has 16, 24, 32 and 48 px bitmaps, so
each size directory is declared scalable over a range of sizes (22 px panel
icons use the 24 px images, 64 px and larger the 48 px ones); otherwise Breeze
would fill in every 22, 64 or 128 px request.

KDE_ALIASES adds names Plasma and KDE applications use that xfce-winxp-tc
does not map.
"""
import argparse
import os
import re
import shutil
import sys


# Size directory -> (MinSize, MaxSize)
RANGES = {16: (8, 19), 24: (20, 27), 32: (28, 39), 48: (40, 512)}

CONTEXTS = {"actions": "Actions", "apps": "Applications", "categories": "Categories",
            "devices": "Devices", "emblems": "Emblems", "mimetypes": "MimeTypes",
            "places": "Places", "status": "Status"}

KDE_ALIASES = """
apps/internet-web-browser-->net_internet
apps/system-file-manager-->folder_open
apps/org.kde.dolphin-->folder_open
apps/mail-client-->mail
apps/org.kde.konsole-->cli
apps/systemsettings-->control_panel
apps/preferences-desktop-color-->control_appearance
apps/preferences-desktop-theme-global-->control_appearance
apps/preferences-desktop-theme-applications-->control_appearance
apps/preferences-desktop-plasma-theme-->control_appearance
apps/preferences-desktop-icons-->control_appearance
apps/preferences-desktop-cursors-->mouse
apps/preferences-desktop-sound-->volume_on
apps/preferences-desktop-notification-->control_notifications
apps/preferences-desktop-notification-bell-->bell
apps/preferences-desktop-mouse-->mouse
apps/preferences-desktop-touchpad-->laptop
apps/preferences-desktop-display-color-->monitor
apps/preferences-desktop-animations-->control_display
apps/preferences-desktop-virtual-->default_window
apps/preferences-desktop-text-->folder_fonts
apps/preferences-desktop-user-->user
apps/preferences-desktop-filetype-association-->mimetypes
apps/preferences-desktop-launch-feedback-->run
apps/preferences-system-windows-actions-->default_window
apps/preferences-system-windows-effect-->default_window
apps/preferences-system-power-management-->ac_power
apps/preferences-system-bluetooth-->bluetooth
apps/preferences-system-users-->people
apps/preferences-system-time-->calendar
apps/preferences-system-login-->user
apps/preferences-system-splash-->control_display
apps/preferences-system-network-proxy-->net_internet
apps/preferences-system-disks-->drive_disk
apps/preferences-devices-printer-->printer
apps/preferences-security-->secure_safe
apps/preferences-online-accounts-->people
apps/preferences-web-browser-shortcuts-->net_search
apps/preferences-kde-connect-->phone
apps/preferences-desktop-wallpaper-->control_display
apps/applications-system-->settings
apps/help-about-->help
apps/org.kde.kate-->file_txt
apps/org.kde.kwrite-->file_txt
apps/accessories-text-editor-->file_txt
apps/firefox-->firefox
apps/thunderbird-->thunderbird
actions/system-lock-screen-->lock
actions/system-switch-user-->people
actions/system-suspend-->shutdown
actions/system-reboot-->shutdown
actions/view-refresh-->refresh
actions/edit-delete-->delete
actions/configure-->settings
places/folder-desktop-->desktop
places/folder-home-->folder
places/folder-root-->drive_disk
places/folder-network-->net_places
places/network-workgroup-->net_places
places/folder-favorites-->fave
places/folder-recent-->recent_docs
places/folder-images-->folder_pictures
places/folder-image-->folder_pictures
places/folder-video-->folder_videos
places/folder-sound-->folder_music
places/folder-text-->folder_documents
places/folder-downloads-->folder
places/folder-public-->folder_shared
places/folder-locked-->folder
places/folder-cloud-->folder_network
places/trash-empty-->bin
places/user-trash-full-->bin_full
mimetypes/unknown-->file_unknown
mimetypes/application-octet-stream-->file_unknown
mimetypes/application-x-zerosize-->file_generic
mimetypes/text-x-script-->file_generic_script
mimetypes/application-x-shellscript-->file_generic_shell
mimetypes/text-x-python-->file_generic_script
mimetypes/text-markdown-->file_txt
mimetypes/application-json-->file_generic_markup
mimetypes/text-xml-->file_generic_markup
mimetypes/application-x-desktop-->shortcut
mimetypes/inode-symlink-->shortcut
devices/drive-harddisk-solidstate-->drive_disk
devices/drive-removable-media-usb-->drive_external
devices/drive-removable-media-usb-pendrive-->drive_external
devices/network-wireless-connected-100-->net_wireless
status/audio-volume-high-->volume_on
status/audio-volume-medium-->volume_on
status/audio-volume-low-->volume_on
status/audio-volume-muted-->volume_off
"""


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--source", required=True, help="xfce-winxp-tc icons/luna directory")
    ap.add_argument("--out", required=True)
    ap.add_argument("--name", default="Windows XP (Luna)")
    ap.add_argument("--inherits", default="breeze,hicolor")
    args = ap.parse_args()

    res = os.path.join(args.source, "res")
    sizes = sorted(d for d in os.listdir(res) if re.fullmatch(r"\d+x\d+", d))
    written = 0
    with open(os.path.join(args.source, "mappings")) as f:
        lines = [line.strip() for line in f]
    mapped = {line.split("-->", 1)[0].split("/", 1)[-1] for line in lines if "-->" in line}
    lines += [line for line in KDE_ALIASES.split()
              if line.split("-->", 1)[0].split("/", 1)[1] not in mapped]
    for line in lines:
        if "-->" not in line:
            continue
        target, name = (part.strip() for part in line.split("-->", 1))
        context, fdo = target.split("/", 1)
        available = [size for size in sizes if os.path.exists(os.path.join(res, size, name + ".png"))]
        if not available:
            continue
        for size in sizes:
            # A size the icon lacks gets the nearest one, preferring larger
            # images, so that every size range finds the XP icon
            nearest = min(available, key=lambda a: (abs(int(a.split("x")[0]) - int(size.split("x")[0])),
                                                     -int(a.split("x")[0])))
            src = os.path.join(res, nearest, name + ".png")
            dst_dir = os.path.join(args.out, size, context)
            os.makedirs(dst_dir, exist_ok=True)
            shutil.copyfile(src, os.path.join(dst_dir, fdo + ".png"))
            written += 1

    symbolic = os.path.join(res, "svg")
    if os.path.isdir(symbolic):
        shutil.copytree(symbolic, os.path.join(args.out, "symbolic", "ui"), dirs_exist_ok=True)

    dirs = sorted(os.path.relpath(root, args.out) for root, _, files in os.walk(args.out) if files)
    index = [f"[Icon Theme]\nName={args.name}\nComment=Windows XP icons from xfce-winxp-tc\n"
             f"Inherits={args.inherits}\nDirectories={','.join(dirs)}\n"]
    for d in dirs:
        size_dir, context = d.split("/", 1)
        if size_dir == "symbolic":
            index.append(f"\n[{d}]\nSize=16\nMinSize=8\nMaxSize=512\nType=Scalable\n")
            continue
        size = int(size_dir.split("x")[0])
        low, high = RANGES.get(size, (size, size))
        index.append(f"\n[{d}]\nSize={size}\nMinSize={low}\nMaxSize={high}\n"
                     f"Context={CONTEXTS.get(context, context.capitalize())}\nType=Scalable\n")
    with open(os.path.join(args.out, "index.theme"), "w") as f:
        f.write("".join(index))
    print(f"{args.name}: {written} icons -> {args.out}")
    return 0 if written else 1


if __name__ == "__main__":
    sys.exit(main())
