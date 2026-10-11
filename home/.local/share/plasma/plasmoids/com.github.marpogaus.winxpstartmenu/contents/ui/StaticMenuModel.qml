/*
    SPDX-License-Identifier: GPL-2.0-or-later

    A menu put together by main.qml (the Classic Start menu's Documents,
    Settings and Search menus). Each row says what it does in `action`;
    `sourceRow` points into the recent documents for their icons.
*/
import QtQuick

ListModel {
    readonly property bool isStaticMenu: true

    function add(display, decoration, action, hasChildren) {
        append({ display: display, decoration: decoration, action: action, hasChildren: hasChildren === true,
                 isSeparator: false, url: "", sourceRow: -1 });
    }

    function addSeparator() {
        append({ display: "", decoration: "", action: "", hasChildren: false,
                 isSeparator: true, url: "", sourceRow: -1 });
    }

    function addRecentDocument(row, display) {
        append({ display: display, decoration: "", action: "recentdocument", hasChildren: false,
                 isSeparator: false, url: "", sourceRow: row });
    }
}
