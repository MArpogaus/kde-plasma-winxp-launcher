/*
    SPDX-License-Identifier: GPL-2.0-or-later

    A folder's contents as a cascading menu ("Display as a menu" for My
    Documents, My Pictures, My Music and My Computer). Uses the desktop
    folder view's model; main.qml creates it at run time, so a Plasma
    without it only loses this option.
*/
import QtQuick
import org.kde.private.desktopcontainment.folder as Folder

Folder.FolderModel {
    parseDesktopFiles: true
}
