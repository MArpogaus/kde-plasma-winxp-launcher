/*
    SPDX-License-Identifier: GPL-2.0-or-later

    Windows XP's Alt+Tab: up to seven 32 px icons per row with the
    selected window's title below, in the Plasma theme's dialog frame,
    highlight and colours.
*/
import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.kwin as KWin
import org.kde.ksvg as KSvg
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
        x: tabBox.screenGeometry.x + Math.round((tabBox.screenGeometry.width - width) / 2)
        y: tabBox.screenGeometry.y + Math.round((tabBox.screenGeometry.height - height) / 2)

        mainItem: Item {
            width: grid.width
            height: grid.height + 12 + title.height

            GridView {
                id: grid

                width: tabBox.columns * tabBox.cell
                height: Math.ceil(count / tabBox.columns) * tabBox.cell
                cellWidth: tabBox.cell
                cellHeight: tabBox.cell
                interactive: false
                highlightMoveDuration: 0
                model: tabBox.model

                highlight: KSvg.FrameSvgItem {
                    imagePath: "widgets/viewitem"
                    prefix: "selected"
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

            // The selected window's title
            Text {
                id: title
                y: grid.height + 12
                width: grid.width
                height: 16
                text: grid.currentItem ? grid.currentItem.model.caption : ""
                textFormat: Text.PlainText
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                renderType: Text.NativeRendering
                font.family: "Tahoma"
                font.pixelSize: 11
                color: Kirigami.Theme.textColor
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            grid.currentIndex = tabBox.currentIndex;
        }
    }
}
