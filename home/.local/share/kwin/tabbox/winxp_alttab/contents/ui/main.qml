/*
    SPDX-License-Identifier: GPL-2.0-or-later

    Windows XP's Alt+Tab: up to seven 32 px icons per row with the
    selected window's title below. XP's beige box, selection frame and
    sunken title field come from the Plasma theme (widgets/winxp,
    alttab-*); without them its dialog frame and highlight stand in.
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

    readonly property bool xpBox: winxp.present

    PlasmaCore.Dialog {
        id: dialog

        location: PlasmaCore.Types.Floating
        visible: tabBox.visible
        flags: Qt.X11BypassWindowManagerHint
        x: tabBox.screenGeometry.x + Math.round((tabBox.screenGeometry.width - width) / 2)
        y: tabBox.screenGeometry.y + Math.round((tabBox.screenGeometry.height - height) / 2)

        backgroundHints: tabBox.xpBox ? PlasmaCore.Dialog.NoBackground : PlasmaCore.Dialog.StandardBackground

        mainItem: Item {
            // XP's box keeps 12 px around the icons and the title
            readonly property real pad: tabBox.xpBox ? box.margins.left : 0

            // (inside the dialog: the switcher itself takes a single item)
            KSvg.Svg {
                id: winxp
                imagePath: "widgets/winxp"
                // Checked again when the Plasma theme changes
                property bool present: hasElement("alttab-center")
                onRepaintNeeded: present = hasElement("alttab-center")
            }
            width: grid.width + 2 * pad
            height: grid.height + 12 + title.height + 2 * pad

            KSvg.FrameSvgItem {
                id: box
                anchors.fill: parent
                visible: tabBox.xpBox
                imagePath: "widgets/winxp"
                prefix: "alttab"
            }

            GridView {
                id: grid
                x: parent.pad
                y: parent.pad

                width: tabBox.columns * tabBox.cell
                height: Math.ceil(count / tabBox.columns) * tabBox.cell
                cellWidth: tabBox.cell
                cellHeight: tabBox.cell
                interactive: false
                highlightMoveDuration: 0
                model: tabBox.model
                // Arrow keys move the selection (KWin passes them on)
                focus: true
                keyNavigationEnabled: true
                keyNavigationWraps: true

                highlight: KSvg.FrameSvgItem {
                    imagePath: tabBox.xpBox ? "widgets/winxp" : "widgets/viewitem"
                    prefix: tabBox.xpBox ? "alttab-selection" : "selected"
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

            // The selected window's title, in XP's sunken field
            Item {
                id: title
                x: grid.x
                y: grid.y + grid.height + 12
                width: grid.width
                height: tabBox.xpBox ? 22 : 16

                KSvg.FrameSvgItem {
                    id: field
                    anchors.fill: parent
                    visible: tabBox.xpBox
                    imagePath: "widgets/winxp"
                    prefix: "alttab-title"
                }
                Text {
                    anchors.fill: parent
                    anchors.margins: tabBox.xpBox ? field.margins.left : 0
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
    }

    onVisibleChanged: {
        if (visible) {
            grid.currentIndex = tabBox.currentIndex;
        }
    }
}
