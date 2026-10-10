/*
    SPDX-License-Identifier: GPL-2.0-or-later

    Windows XP's Alt+Tab: a beige box with up to seven 32 px icons per row,
    a blue frame around the selected one and its title in a sunken field.
*/
import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.kwin as KWin
import org.kde.plasma.core as PlasmaCore

KWin.TabBoxSwitcher {
    id: tabBox

    readonly property int columns: Math.max(1, Math.min(7, grid.count))
    readonly property int cell: 43

    currentIndex: grid.currentIndex

    PlasmaCore.Dialog {
        id: dialog

        location: PlasmaCore.Types.Floating
        visible: tabBox.visible
        flags: Qt.X11BypassWindowManagerHint
        x: tabBox.screenGeometry.x + Math.round((tabBox.screenGeometry.width - frame.width) / 2)
        y: tabBox.screenGeometry.y + Math.round((tabBox.screenGeometry.height - frame.height) / 2)

        backgroundHints: PlasmaCore.Dialog.NoBackground

        mainItem: Rectangle {
            id: frame

            width: grid.width + 2 * 12
            height: grid.height + title.height + 3 * 12
            color: "#ece9d8"
            border.width: 1
            border.color: "#0a246a"

            GridView {
                id: grid

                x: 12
                y: 12
                width: tabBox.columns * tabBox.cell
                height: Math.ceil(count / tabBox.columns) * tabBox.cell
                cellWidth: tabBox.cell
                cellHeight: tabBox.cell
                interactive: false
                highlightMoveDuration: 0
                model: tabBox.model

                highlight: Rectangle {
                    color: "transparent"
                    border.width: 2
                    border.color: "#316ac5"
                }

                delegate: Item {
                    id: entry

                    required property int index
                    required property var model

                    width: tabBox.cell
                    height: tabBox.cell

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: 32
                        height: 32
                        source: entry.model.icon
                        roundToIconSize: false
                        opacity: entry.model.minimized ? 0.6 : 1.0
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            grid.currentIndex = entry.index;
                            tabBox.model.activate(entry.index);
                        }
                    }
                }

                Connections {
                    target: tabBox
                    function onCurrentIndexChanged() {
                        grid.currentIndex = tabBox.currentIndex;
                    }
                }
            }

            // Sunken field with the selected window's title
            Rectangle {
                id: title

                x: 12
                y: grid.y + grid.height + 12
                width: grid.width
                height: 22
                color: "#ece9d8"
                border.width: 1
                border.color: "#aca899"

                Rectangle {
                    x: 1
                    y: 1
                    width: parent.width - 1
                    height: 1
                    color: "#716f64"
                }

                Text {
                    anchors.fill: parent
                    anchors.margins: 4
                    text: grid.currentItem ? grid.currentItem.model.caption : ""
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    renderType: Text.NativeRendering
                    font.family: "Tahoma"
                    font.pixelSize: 11
                    color: "#000000"
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            grid.currentIndex = tabBox.currentIndex;
        }
    }
}
