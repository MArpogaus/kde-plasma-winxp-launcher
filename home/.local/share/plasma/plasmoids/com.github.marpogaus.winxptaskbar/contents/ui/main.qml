/*
    SPDX-License-Identifier: GPL-2.0-or-later

    Windows XP taskbar: one Luna button per window, equal widths up to
    160 px, click to activate / minimize, XP window menu on right click.
*/
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.taskmanager as TaskManager

PlasmoidItem {
    id: root

    readonly property bool horizontal: Plasmoid.formFactor !== PlasmaCore.Types.Vertical

    preferredRepresentation: fullRepresentation
    Plasmoid.constraintHints: Plasmoid.CanFillArea

    TaskManager.VirtualDesktopInfo {
        id: virtualDesktopInfo
    }

    TaskManager.ActivityInfo {
        id: activityInfo
    }

    TaskManager.TasksModel {
        id: tasksModel

        groupMode: TaskManager.TasksModel.GroupDisabled
        sortMode: TaskManager.TasksModel.SortManual
        separateLaunchers: true
        hideActivatedLaunchers: true
        launchInPlace: false
        filterByVirtualDesktop: Plasmoid.configuration.showOnlyCurrentDesktop
        filterByScreen: Plasmoid.configuration.showOnlyCurrentScreen
        filterByActivity: true
        virtualDesktop: virtualDesktopInfo.currentDesktop
        activity: activityInfo.currentActivity
        screenGeometry: Plasmoid.containment.screenGeometry
    }

    fullRepresentation: Item {
        id: bar

        // Laid out on the visible taskbar: buttons start 3 px below its top
        // and end 2 px above its bottom (25 px on XP's 30 px taskbar). A
        // taller taskbar holds more rows of buttons, filled row by row.
        readonly property rect area: root.horizontal ? panelArea.rect : Qt.rect(0, 0, width, height)
        readonly property int spacing: 3
        readonly property int rows: root.horizontal ? Math.max(1, Math.floor((area.height - 2) / 28)) : buttons.count
        readonly property real rowPitch: root.horizontal ? (area.height - 2) / rows : 25 + spacing
        readonly property real buttonHeight: rowPitch - spacing

        readonly property int count: buttons.count
        readonly property int perRow: root.horizontal ? Math.max(1, Math.ceil(count / rows)) : 1
        readonly property real buttonWidth: count > 0
            ? Math.max(1, Math.min(Plasmoid.configuration.maximumButtonWidth, Math.floor((width - (perRow - 1) * spacing) / perRow)))
            : 0

        PanelArea {
            id: panelArea
            target: bar
        }

        // The applet takes its layout hints from this representation
        Layout.minimumWidth: root.horizontal ? 60 : -1
        Layout.fillWidth: root.horizontal
        Layout.fillHeight: !root.horizontal

        Repeater {
            id: buttons
            model: tasksModel

            delegate: TaskButton {
                id: task

                required property int index
                required property var model

                readonly property var modelIndex: tasksModel.makeModelIndex(index)

                x: root.horizontal ? (index % bar.perRow) * (bar.buttonWidth + bar.spacing) : 0
                y: Math.round(root.horizontal ? bar.area.y + bar.spacing + Math.floor(index / bar.perRow) * bar.rowPitch : index * bar.rowPitch)
                width: root.horizontal ? bar.buttonWidth : bar.width
                height: Math.round(bar.buttonHeight)

                icon: model.decoration
                text: model.display ?? ""
                fontFamily: Plasmoid.configuration.fontFamily
                active: model.IsActive === true && model.IsMinimized !== true
                attention: model.IsDemandingAttention === true
                hovered: mouse.containsMouse
                pressed: mouse.pressed && mouse.pressedButtons === Qt.LeftButton

                // Tell KWin where the button is so minimize animations land on it
                function publishGeometry() {
                    if (!Window.window) {
                        return;
                    }
                    const p = mapToGlobal(0, 0);
                    tasksModel.requestPublishDelegateGeometry(modelIndex, Qt.rect(p.x, p.y, width, height), task);
                }
                onXChanged: geometryTimer.restart()
                onYChanged: geometryTimer.restart()
                onWidthChanged: geometryTimer.restart()
                onHeightChanged: geometryTimer.restart()
                Component.onCompleted: geometryTimer.restart()

                Timer {
                    id: geometryTimer
                    interval: 250
                    onTriggered: task.publishGeometry()
                }

                PlasmaCore.ToolTipArea {
                    anchors.fill: parent
                    mainText: task.text
                    active: task.truncated
                    location: Plasmoid.location
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

                    onClicked: event => {
                        if (event.button === Qt.RightButton) {
                            windowMenu.show(task);
                        } else if (event.button === Qt.MiddleButton) {
                            tasksModel.requestNewInstance(task.modelIndex);
                        } else if (task.model.IsActive === true && task.model.IsMinimized !== true) {
                            tasksModel.requestToggleMinimized(task.modelIndex);
                        } else {
                            tasksModel.requestActivate(task.modelIndex);
                        }
                    }
                }
            }
        }
    }

    // XP's window menu: Restore, Move, Size, Minimize, Maximize, Close
    PlasmaExtras.Menu {
        id: windowMenu

        property Item task: null
        readonly property bool minimized: task ? task.model.IsMinimized === true : false
        readonly property bool maximized: task ? task.model.IsMaximized === true : false

        function show(item) {
            task = item;
            visualParent = item;
            openRelative();
        }

        function request(action) {
            if (task) {
                action(task.modelIndex);
            }
        }

        PlasmaExtras.MenuItem {
            text: i18n("Restore")
            icon: "window-restore"
            enabled: windowMenu.minimized || windowMenu.maximized
            onClicked: windowMenu.request(index => windowMenu.minimized
                ? tasksModel.requestActivate(index) : tasksModel.requestToggleMaximized(index))
        }
        PlasmaExtras.MenuItem {
            text: i18n("Move")
            icon: "transform-move"
            enabled: !windowMenu.minimized
            onClicked: windowMenu.request(index => tasksModel.requestMove(index))
        }
        PlasmaExtras.MenuItem {
            text: i18n("Size")
            icon: "transform-scale"
            enabled: !windowMenu.minimized && !windowMenu.maximized
            onClicked: windowMenu.request(index => tasksModel.requestResize(index))
        }
        PlasmaExtras.MenuItem {
            text: i18n("Minimize")
            icon: "window-minimize"
            enabled: !windowMenu.minimized
            onClicked: windowMenu.request(index => tasksModel.requestToggleMinimized(index))
        }
        PlasmaExtras.MenuItem {
            text: i18n("Maximize")
            icon: "window-maximize"
            enabled: !windowMenu.maximized
            onClicked: windowMenu.request(index => tasksModel.requestToggleMaximized(index))
        }
        PlasmaExtras.MenuItem {
            separator: true
        }
        PlasmaExtras.MenuItem {
            text: i18n("Close")
            icon: "window-close"
            onClicked: windowMenu.request(index => tasksModel.requestClose(index))
        }
    }
}
