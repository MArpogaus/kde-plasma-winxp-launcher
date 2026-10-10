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
    Layout.fillWidth: horizontal
    Layout.fillHeight: !horizontal

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

        // Like the start button, use the full taskbar height regardless of
        // the panel theme's margins: buttons sit 3 px below the top edge and
        // 2 px above the bottom edge (25 px on a 30 px taskbar).
        readonly property point windowPos: {
            x; y; width; height; Window.width; Window.height;
            return Window.window ? mapToItem(null, 0, 0) : Qt.point(0, 0);
        }
        readonly property real top: root.horizontal && Window.window ? -windowPos.y + 3 : 2
        readonly property real buttonHeight: root.horizontal && Window.window ? Window.height - 5 : 25

        readonly property int count: buttons.count
        readonly property int spacing: 3
        readonly property real buttonWidth: count > 0
            ? Math.min(Plasmoid.configuration.maximumButtonWidth, Math.floor((width - (count - 1) * spacing) / count))
            : 0

        Layout.minimumWidth: root.horizontal ? 60 : -1
        Layout.fillWidth: root.horizontal

        Repeater {
            id: buttons
            model: tasksModel

            delegate: TaskButton {
                id: task

                required property int index
                required property var model

                readonly property var modelIndex: tasksModel.makeModelIndex(index)

                x: root.horizontal ? index * (bar.buttonWidth + bar.spacing) : 0
                y: root.horizontal ? bar.top : index * (25 + bar.spacing)
                width: root.horizontal ? bar.buttonWidth : bar.width
                height: root.horizontal ? bar.buttonHeight : 25

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
