/*
    SPDX-License-Identifier: GPL-2.0-or-later

    Contents of a cascading menu (All Programs, its folders, My Recent
    Documents). Long menus wrap into additional columns, like on XP.
*/
import QtQuick

Item {
    id: view

    required property QtObject xp
    required property QtObject controller

    property var model: null
    property int level: 0
    property int maxRows: 30
    // Row whose child cascade is currently open (kept highlighted).
    property int openIndex: -1

    readonly property int rowHeight: xp.cascadeRowHeight
    readonly property int itemCount: grid.count
    readonly property int shownRows: Math.max(1, Math.min(itemCount, maxRows))
    readonly property int columns: Math.max(1, Math.ceil(itemCount / Math.max(1, maxRows)))
    readonly property int shadow: 3
    // The menu itself, without its drop shadow (cascades open next to it)
    readonly property alias frameItem: frame
    property int columnWidth: 160

    // Frame: left border and band (6 px), rows, right border (1 px); rows
    // directly below the top border and above the bottom one
    readonly property int frameLeft: 1 + xp.cascadeBand.length
    width: frameLeft + columns * columnWidth + 1 + shadow
    height: 1 + shownRows * rowHeight + 1 + shadow

    function computeColumnWidth() {
        let widest = 0;
        const m = view.model;
        if (m && m.rowCount) {
            const n = m.rowCount();
            for (let i = 0; i < n; ++i) {
                const text = m.data(m.index(i, 0), Qt.DisplayRole);
                if (text) {
                    widest = Math.max(widest, metrics.advanceWidth(text));
                }
            }
        } else {
            widest = metrics.advanceWidth(emptyLabel.title);
        }
        // As XP's: the text starts 23 px into the row (29 px into the menu,
        // icon at 10 px) and 23 px follow the longest name (room for the
        // cascade arrow)
        view.columnWidth = Math.min(Math.max(Math.ceil(widest) + 23 + 23, 130), 380);
    }

    property int hoverIndex: -1
    // Row under the pointer right now (-1 when none); the row whose
    // cascade is open stays highlighted only while no other row is
    property int pointerIndex: -1
    property bool hoverHasChildren: false
    property Item hoverItem: null

    function hoverEntered(index, hasChildren, item) {
        hoverIndex = index;
        hoverHasChildren = hasChildren;
        hoverItem = item;
        hoverTimer.restart();
    }

    function activate(index, hasChildren, item) {
        hoverTimer.stop();
        if (hasChildren) {
            openChild(index, item);
            return;
        }
        if (view.model && view.model.trigger) {
            view.model.trigger(index, "", null);
        }
        view.controller.closeMenu();
    }

    function openChild(index, item) {
        if (openIndex === index) {
            return;
        }
        view.controller.openCascade(view.level + 1, item, view.model.modelForRow(index), view, index);
    }

    onModelChanged: Qt.callLater(computeColumnWidth)
    onItemCountChanged: Qt.callLater(computeColumnWidth)
    Component.onCompleted: computeColumnWidth()

    FontMetrics {
        id: metrics
        font.family: view.xp.fontFamily
        font.pixelSize: view.xp.fontPixelSize
    }

    Timer {
        id: hoverTimer
        interval: 350
        onTriggered: {
            if (view.hoverIndex < 0) {
                return;
            }
            if (view.hoverHasChildren) {
                view.openChild(view.hoverIndex, view.hoverItem);
            } else {
                view.controller.closeCascadesFrom(view.level + 1);
            }
        }
    }

    // Drop shadow (right and bottom), as drawn by XP for menus.
    Rectangle {
        x: view.shadow
        y: view.shadow
        width: frame.width
        height: frame.height
        color: Qt.rgba(0, 0, 0, 0.18)
    }
    Rectangle {
        x: view.shadow - 1
        y: view.shadow - 1
        width: frame.width
        height: frame.height
        color: Qt.rgba(0, 0, 0, 0.12)
    }

    Rectangle {
        id: frame
        width: view.width - view.shadow
        height: view.height - view.shadow
        color: view.xp.cascadeBackground

        Rectangle {
            width: parent.width
            height: 1
            color: view.xp.cascadeBorderLight
        }
        Rectangle {
            y: parent.height - 1
            width: parent.width
            height: 1
            color: view.xp.cascadeBorderLight
        }
        Rectangle {
            width: 1
            height: parent.height
            color: view.xp.cascadeBorder
        }
        Rectangle {
            x: parent.width - 1
            width: 1
            height: parent.height
            color: view.xp.cascadeBorder
        }
        Row {
            x: 1
            y: 1
            Repeater {
                model: view.xp.cascadeBand
                Rectangle {
                    required property color modelData
                    width: 1
                    height: frame.height - 2
                    color: modelData
                }
            }
        }

        GridView {
            id: grid
            x: view.frameLeft
            y: 1
            width: view.columns * view.columnWidth
            height: view.shownRows * view.rowHeight
            flow: GridView.FlowTopToBottom
            interactive: false
            cellWidth: view.columnWidth
            cellHeight: view.rowHeight
            model: view.model

            delegate: Item {
                id: cell

                required property int index
                required property var model

                readonly property bool isSeparator: cell.model.isSeparator === true
                readonly property bool hasChildren: cell.model.hasChildren === true

                width: grid.cellWidth
                height: grid.cellHeight

                MenuSeparator {
                    anchors.fill: parent
                    anchors.leftMargin: 2
                    anchors.rightMargin: 2
                    visible: cell.isSeparator
                    color: view.xp.cascadeSeparator
                    fade: false

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: view.hoverEntered(-1, false, null)
                    }
                }

                MenuEntry {
                    id: cellEntry
                    anchors.fill: parent
                    visible: !cell.isSeparator
                    xp: view.xp
                    iconSource: cell.model.decoration
                    title: cell.model.display ?? ""
                    dragUrl: cell.hasChildren ? "" : cell.model.url ?? ""
                    dragController: view.controller
                    iconSize: 16
                    leftPadding: 4
                    textSpacing: 3
                    showArrow: cell.hasChildren
                    highlightColor: view.xp.cascadeHighlight
                    forceHighlight: view.openIndex === cell.index
                        && (view.pointerIndex < 0 || view.pointerIndex === cell.index)

                    onHoveredChanged: {
                        if (hovered) {
                            view.pointerIndex = cell.index;
                            view.hoverEntered(cell.index, cell.hasChildren, cellEntry);
                        } else if (view.pointerIndex === cell.index) {
                            view.pointerIndex = -1;
                        }
                    }
                    onClicked: view.activate(cell.index, cell.hasChildren, cellEntry)
                    onContextMenuRequested: (x, y) => {
                        if (!cell.hasChildren) {
                            view.controller.showItemContextMenu(view.model, cell.index, cell.model.favoriteId ?? "", cell.model.actionList, cellEntry, x, y);
                        }
                    }
                }
            }
        }

        MenuEntry {
            id: emptyLabel
            x: view.frameLeft
            y: 1
            width: view.columnWidth
            height: view.rowHeight
            visible: view.itemCount === 0
            xp: view.xp
            title: i18n("(Empty)")
            iconSize: 16
            leftPadding: 4
            textSpacing: 3
            interactive: false
        }
    }
}
