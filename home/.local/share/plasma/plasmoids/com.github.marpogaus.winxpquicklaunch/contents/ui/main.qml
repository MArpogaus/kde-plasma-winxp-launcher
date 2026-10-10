/*
    SPDX-License-Identifier: GPL-2.0-or-later

    Windows XP Quick Launch toolbar: 16 px launcher icons in 22 px cells,
    Show Desktop first, a » button for launchers that do not fit and a
    separator towards the task buttons.
*/
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager

PlasmoidItem {
    id: root

    readonly property bool horizontal: Plasmoid.formFactor !== PlasmaCore.Types.Vertical
    readonly property int cell: 22
    readonly property int spacing: 1

    // Entries: Show Desktop (optional) followed by the configured launchers
    readonly property int launcherCount: Plasmoid.configuration.launchers.length
    readonly property int entryCount: launcherCount + (Plasmoid.configuration.showDesktop ? 1 : 0)
    readonly property int shownCount: Math.min(entryCount, Plasmoid.configuration.maximumIcons)
    readonly property bool overflow: entryCount > shownCount

    preferredRepresentation: fullRepresentation

    // TaskManager resolves applications:, preferred:// and .desktop launcher
    // URLs to names and icons and starts them. Windows are filtered out by
    // an activity that does not exist; launchers belong to all activities.
    TaskManager.TasksModel {
        id: launchers

        launcherList: Plasmoid.configuration.launchers
        separateLaunchers: true
        hideActivatedLaunchers: false
        launchInPlace: false
        groupMode: TaskManager.TasksModel.GroupDisabled
        sortMode: TaskManager.TasksModel.SortManual
        filterByActivity: true
        activity: "winxp-quicklaunch-launchers-only"
    }

    P5Support.DataSource {
        id: executable
        engine: "executable"
        onNewData: sourceName => disconnectSource(sourceName)
    }

    function showDesktop() {
        executable.connectSource("dbus-send --session --type=method_call --dest=org.kde.kglobalaccel "
            + "/component/kwin org.kde.kglobalaccel.Component.invokeShortcut string:'Show Desktop'");
    }

    function launch(row) {
        launchers.requestActivate(launchers.makeModelIndex(row));
    }

    fullRepresentation: Item {
        id: bar

        readonly property rect area: root.horizontal ? panelArea.rect : Qt.rect(0, 0, width, height)

        Layout.minimumWidth: root.horizontal ? row.width + 2 + separator.width : -1
        Layout.maximumWidth: Layout.minimumWidth
        Layout.minimumHeight: root.horizontal ? -1 : row.height + 2 + separator.height
        Layout.maximumHeight: Layout.minimumHeight

        PanelArea {
            id: panelArea
            target: bar
        }

        // One row (one column in a vertical panel) that never wraps
        Grid {
            id: row

            x: 2
            y: root.horizontal ? Math.round(bar.area.y + (bar.area.height - root.cell) / 2) : 2
            rows: root.horizontal ? 1 : -1
            columns: root.horizontal ? -1 : 1
            spacing: root.spacing

            LaunchButton {
                visible: Plasmoid.configuration.showDesktop
                iconSource: "user-desktop"
                toolTip: i18n("Show Desktop")
                onClicked: root.showDesktop()
            }

            Repeater {
                model: launchers

                delegate: LaunchButton {
                    required property int index
                    required property var model

                    // Launchers come first in the model, in configuration order
                    visible: model.IsLauncher === true
                        && index + (Plasmoid.configuration.showDesktop ? 1 : 0) < root.shownCount
                    iconSource: model.decoration
                    toolTip: model.display ?? ""
                    onClicked: root.launch(index)
                }
            }

            // XP's » button for the icons that do not fit
            Item {
                visible: root.overflow
                width: 13
                height: root.cell

                Text {
                    anchors.centerIn: parent
                    text: "»"
                    font.family: "Tahoma"
                    font.pixelSize: 13
                    font.bold: true
                    color: "#ffffff"
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: overflowMenu.openRelative()
                }
            }
        }

        // Etched separator towards the task buttons
        Item {
            id: separator

            anchors.right: root.horizontal ? parent.right : undefined
            anchors.bottom: root.horizontal ? undefined : parent.bottom
            y: root.horizontal ? bar.area.y + 3 : 0
            width: root.horizontal ? 4 : bar.width
            height: root.horizontal ? bar.area.height - 6 : 4

            Rectangle {
                x: root.horizontal ? 1 : 0
                y: root.horizontal ? 0 : 1
                width: root.horizontal ? 1 : parent.width
                height: root.horizontal ? parent.height : 1
                color: Qt.rgba(0, 0.05, 0.3, 0.5)
            }
            Rectangle {
                x: root.horizontal ? 2 : 0
                y: root.horizontal ? 0 : 2
                width: root.horizontal ? 1 : parent.width
                height: root.horizontal ? parent.height : 1
                color: Qt.rgba(1, 1, 1, 0.3)
            }
        }

        PlasmaExtras.Menu {
            id: overflowMenu
            visualParent: row
        }

        Instantiator {
            model: launchers
            delegate: PlasmaExtras.MenuItem {
                required property int index
                required property var model

                visible: model.IsLauncher === true
                    && index + (Plasmoid.configuration.showDesktop ? 1 : 0) >= root.shownCount
                text: model.display ?? ""
                icon: model.decoration
                onClicked: root.launch(index)
            }
            onObjectAdded: (index, object) => overflowMenu.addMenuItem(object)
            onObjectRemoved: (index, object) => overflowMenu.removeMenuItem(object)
        }
    }

    // One 22 px Quick Launch button with XP's hover and pressed look
    component LaunchButton: Item {
        id: button

        property var iconSource
        property string toolTip

        signal clicked()

        width: root.cell
        height: root.cell

        Rectangle {
            anchors.fill: parent
            radius: 2
            visible: mouse.containsMouse
            color: mouse.pressed ? Qt.rgba(0, 0.05, 0.3, 0.25) : Qt.rgba(1, 1, 1, 0.18)
            border.width: 1
            border.color: mouse.pressed ? Qt.rgba(0, 0.05, 0.3, 0.5) : Qt.rgba(1, 1, 1, 0.45)
        }

        Kirigami.Icon {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: mouse.pressed ? 1 : 0
            anchors.verticalCenterOffset: mouse.pressed ? 1 : 0
            width: 16
            height: 16
            source: button.iconSource ?? ""
            roundToIconSize: false
            animated: false
        }

        PlasmaCore.ToolTipArea {
            anchors.fill: parent
            mainText: button.toolTip
            location: Plasmoid.location
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: button.clicked()
        }
    }
}
