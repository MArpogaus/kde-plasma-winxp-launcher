/*
    SPDX-License-Identifier: GPL-2.0-or-later

    Windows XP taskbar: one button per window, equal widths up to
    the configured width, click to activate / minimize, XP window menu on right click.
    Buttons do not get narrower than the minimum width; the windows that
    do not fit are in a » menu at the end, like Quick Launch's.
*/
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import org.kde.ksvg as KSvg
import org.kde.taskmanager as TaskManager

PlasmoidItem {
    id: root

    // XP's artwork in the Plasma theme, if it has it (checked again when
    // the theme changes)
    KSvg.Svg {
        id: winxp
        imagePath: "widgets/winxp"
        property bool present: hasElement("overflow-normal")
        onRepaintNeeded: present = hasElement("overflow-normal")
    }
    // Text on the taskbar: XP's taskbar is blue, so with XP's artwork the
    // colour set for contrasting areas; otherwise the panel's own
    readonly property int panelColorSet: winxp.present ? Kirigami.Theme.Complementary : Kirigami.Theme.Window

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
        readonly property int rows: root.horizontal ? Math.max(1, Math.floor((area.height - 2) / 28)) : 1
        readonly property real rowPitch: root.horizontal ? (area.height - 2) / rows : 25 + spacing
        readonly property real buttonHeight: rowPitch - spacing

        readonly property int count: buttons.count
        // Overflow: how many buttons of the minimum width fit per row
        // (shownCount below leaves room for the » at the end)
        readonly property int minimumWidth: Math.min(Plasmoid.configuration.minimumButtonWidth,
                                                     Plasmoid.configuration.maximumButtonWidth)
        readonly property int overflowWidth: 13
        readonly property int fitPerRow: Math.max(1, Math.floor((width + spacing) / (minimumWidth + spacing)))
        // On a vertical taskbar: how many buttons fit in the column
        readonly property int fitPerColumn: Math.max(1, Math.floor((height + spacing) / rowPitch))
        readonly property bool overflow: root.horizontal ? count > rows * fitPerRow : count > fitPerColumn
        // Each button with its spacing, then the » (below them when vertical)
        readonly property int shownCount: !overflow ? count
            : root.horizontal ? rows * Math.max(1, Math.floor((width - overflowWidth) / (minimumWidth + spacing)))
            : Math.max(1, fitPerColumn - 1)
        readonly property int perRow: root.horizontal ? Math.max(1, Math.ceil(shownCount / rows)) : 1
        readonly property real buttonWidth: count > 0
            ? Math.max(1, Math.min(Plasmoid.configuration.maximumButtonWidth,
                                   Math.floor((width - (overflow ? overflowWidth + spacing : 0) - (perRow - 1) * spacing) / perRow)))
            : 0

        PanelArea {
            id: panelArea
            target: bar
        }

        // Where the bar is on screen; changes when other widgets or the
        // panel move it, so the buttons publish their geometry again
        readonly property point screenPosition: {
            for (let p = bar; p; p = p.parent) {
                p.x;
                p.y;
            }
            const window = bar.Window.window;
            if (!window) {
                return Qt.point(0, 0);
            }
            window.x;
            window.y;
            return bar.mapToGlobal(0, 0);
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

                visible: index < bar.shownCount
                x: root.horizontal ? (index % bar.perRow) * (bar.buttonWidth + bar.spacing) : 0
                y: Math.round(root.horizontal ? bar.area.y + bar.spacing + Math.floor(index / bar.perRow) * bar.rowPitch : index * bar.rowPitch)
                width: root.horizontal ? bar.buttonWidth : bar.width
                height: Math.round(bar.buttonHeight)

                icon: model.decoration
                text: model.display ?? ""
                fontFamily: Plasmoid.configuration.fontFamily
                textColorSet: root.panelColorSet
                active: model.IsActive === true && model.IsMinimized !== true
                attention: model.IsDemandingAttention === true
                minimized: model.IsMinimized === true
                hovered: mouse.containsMouse
                pressed: mouse.pressed && mouse.pressedButtons === Qt.LeftButton

                // Tell KWin where the button is so minimize animations land
                // on it (on the » for the windows in its menu); on Wayland
                // the item given counts, not the rectangle
                function publishGeometry() {
                    if (!Window.window) {
                        return;
                    }
                    const target = visible ? task : overflowButton;
                    const p = target.mapToGlobal(0, 0);
                    tasksModel.requestPublishDelegateGeometry(modelIndex, Qt.rect(p.x, p.y, target.width, target.height), target);
                }
                onVisibleChanged: geometryTimer.restart()
                onXChanged: geometryTimer.restart()
                onYChanged: geometryTimer.restart()
                onWidthChanged: geometryTimer.restart()
                onHeightChanged: geometryTimer.restart()
                Component.onCompleted: geometryTimer.restart()

                Connections {
                    target: bar
                    function onScreenPositionChanged() {
                        geometryTimer.restart();
                    }
                }

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
                            windowMenu.show(task, event.x, event.y);
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

        // » for the windows that do not fit, at the end of the taskbar,
        // drawn like Quick Launch's: 13 px wide at the top of the taskbar,
        // a tool button (theme's widgets/button) only under the pointer
        Item {
            id: overflowButton
            visible: bar.overflow
            x: root.horizontal ? bar.width - width : Math.round((bar.width - width) / 2)
            y: root.horizontal ? Math.round(bar.area.y + 3) : Math.round(bar.shownCount * bar.rowPitch + (bar.rowPitch - height) / 2)
            width: bar.overflowWidth
            height: 12

            // XP's » from the Plasma theme (widgets/winxp), else a tool
            // button with a » in the text colour
            readonly property bool xpChevrons: winxp.present
            KSvg.SvgItem {
                anchors.fill: parent
                visible: parent.xpChevrons
                svg: winxp
                elementId: "overflow-" + (overflowMouse.pressed ? "pressed" : overflowMouse.containsMouse ? "hover" : "normal")
            }
            KSvg.FrameSvgItem {
                anchors.fill: parent
                visible: !parent.xpChevrons && overflowMouse.containsMouse
                imagePath: "widgets/button"
                prefix: overflowMouse.pressed ? "toolbutton-pressed" : "toolbutton-hover"
            }
            Text {
                visible: !parent.xpChevrons
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -1
                text: "»"
                font.family: Plasmoid.configuration.fontFamily
                font.pixelSize: 11
                font.bold: true
                Kirigami.Theme.colorSet: root.panelColorSet
                Kirigami.Theme.inherit: false
                color: Kirigami.Theme.textColor
            }
            MouseArea {
                id: overflowMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: overflowPopup.toggle()
            }
        }

        // The windows that do not fit: click activates, right-click opens
        // the window menu
        PlasmaCore.Dialog {
            id: overflowPopup

            visible: false
            type: PlasmaCore.Dialog.PopupMenu
            flags: Qt.WindowStaysOnTopHint
            location: PlasmaCore.Types.Floating
            hideOnWindowDeactivate: windowMenu.status === PlasmaExtras.Menu.Closed && !refocus.running

            function toggle() {
                if (visible) {
                    visible = false;
                    return;
                }
                visible = true;
                place();
                requestActivate();
            }

            // Above the », left edges aligned (kept on the screen); below
            // the taskbar when it is at the top of the screen
            function place() {
                const p = overflowButton.mapToGlobal(0, 0);
                const location = Plasmoid.location;
                if (location === PlasmaCore.Types.LeftEdge || location === PlasmaCore.Types.RightEdge) {
                    // Beside a vertical taskbar, top edges aligned (kept on
                    // the screen)
                    const left = location === PlasmaCore.Types.LeftEdge;
                    const edge = bar.mapToGlobal(left ? bar.width : 0, 0).x;
                    x = left ? Math.round(edge) : Math.round(edge) - width;
                    y = Math.round(Math.max(bar.Screen.virtualY, Math.min(p.y, bar.Screen.virtualY + bar.Screen.height - height)));
                    return;
                }
                x = Math.round(Math.min(p.x, bar.Screen.virtualX + bar.Screen.width - width));
                y = location === PlasmaCore.Types.TopEdge
                    ? Math.round(bar.mapToGlobal(0, bar.area.y + bar.area.height).y)
                    : Math.round(p.y) - height;
            }
            onHeightChanged: if (visible) place()
            onWidthChanged: if (visible) place()

            // As wide as the longest title (hidden rows do not count)
            mainItem: ColumnLayout {
                width: Math.min(400, Math.max(160, implicitWidth))
                spacing: 0

                Repeater {
                    model: tasksModel

                    delegate: Item {
                        id: overflowRow

                        required property int index
                        required property var model
                        readonly property var modelIndex: tasksModel.makeModelIndex(index)

                        visible: index >= bar.shownCount
                        Layout.fillWidth: true
                        implicitWidth: 28 + rowText.implicitWidth + 12
                        implicitHeight: 22

                        // XP's menu highlight (white text), else the theme's
                        KSvg.FrameSvgItem {
                            anchors.fill: parent
                            visible: rowMouse.containsMouse
                            imagePath: winxp.present ? "widgets/winxp" : "widgets/viewitem"
                            prefix: winxp.present ? "menu-highlight" : "hover"
                        }

                        Kirigami.Icon {
                            x: 4
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16
                            height: 16
                            source: overflowRow.model.decoration
                            roundToIconSize: false
                        }
                        Text {
                            id: rowText
                            x: 28
                            width: parent.width - x - 6
                            anchors.verticalCenter: parent.verticalCenter
                            text: overflowRow.model.display ?? ""
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            font.family: Plasmoid.configuration.fontFamily
                            font.pixelSize: 11
                            font.bold: overflowRow.model.IsActive === true
                            renderType: Text.NativeRendering
                            color: rowMouse.containsMouse && winxp.present ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                        }
                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton) {
                                    windowMenu.show(overflowRow, mouse.x, mouse.y, true);
                                } else {
                                    overflowPopup.visible = false;
                                    tasksModel.requestActivate(overflowRow.modelIndex);
                                }
                            }
                        }
                    }
                }
            }
        }

        // Keep the popup open (and focused) when its window menu closes
        // without an action; an action (which may activate the window)
        // closes it. Close it too once nothing overflows.
        Timer {
            id: refocus
            interval: 200
        }
        Connections {
            target: windowMenu
            function onStatusChanged() {
                if (windowMenu.status === PlasmaExtras.Menu.Closed && windowMenu.fromPopup && overflowPopup.visible) {
                    refocus.restart();
                    overflowPopup.requestActivate();
                }
            }
            function onActionTriggered() {
                if (windowMenu.fromPopup) {
                    refocus.stop();
                    overflowPopup.visible = false;
                }
            }
        }
        Connections {
            target: bar
            function onOverflowChanged() {
                if (!bar.overflow) {
                    overflowPopup.visible = false;
                }
            }
        }
    }

    // XP's window menu: Restore, Move, Size, Minimize, Maximize, Close
    PlasmaExtras.Menu {
        id: windowMenu

        property Item task: null
        property bool fromPopup: false
        signal actionTriggered
        readonly property bool minimized: task ? task.model.IsMinimized === true : false
        readonly property bool maximized: task ? task.model.IsMaximized === true : false
        // What the window allows (greyed out otherwise, as XP's)
        function can(role) {
            return !task || task.model[role] !== false;
        }

        // At the pointer like XP's; at the bottom of the screen it opens
        // upwards with its left edge at the pointer
        function show(item, x, y, popup) {
            task = item;
            fromPopup = popup === true;
            visualParent = item;
            open(x, y);
        }

        function request(action) {
            if (task) {
                action(task.modelIndex);
            }
            actionTriggered();
        }

        PlasmaExtras.MenuItem {
            text: i18n("Restore")
            icon: "window-restore"
            enabled: windowMenu.minimized || (windowMenu.maximized && windowMenu.can("IsMaximizable"))
            onClicked: windowMenu.request(index => windowMenu.minimized
                ? tasksModel.requestActivate(index) : tasksModel.requestToggleMaximized(index))
        }
        PlasmaExtras.MenuItem {
            text: i18n("Move")
            icon: "transform-move"
            enabled: !windowMenu.minimized && windowMenu.can("IsMovable")
            onClicked: windowMenu.request(index => tasksModel.requestMove(index))
        }
        PlasmaExtras.MenuItem {
            text: i18n("Size")
            icon: "transform-scale"
            enabled: !windowMenu.minimized && !windowMenu.maximized && windowMenu.can("IsResizable")
            onClicked: windowMenu.request(index => tasksModel.requestResize(index))
        }
        PlasmaExtras.MenuItem {
            text: i18n("Minimize")
            icon: "window-minimize"
            enabled: !windowMenu.minimized && windowMenu.can("IsMinimizable")
            onClicked: windowMenu.request(index => tasksModel.requestToggleMinimized(index))
        }
        PlasmaExtras.MenuItem {
            text: i18n("Maximize")
            icon: "window-maximize"
            enabled: !windowMenu.maximized && windowMenu.can("IsMaximizable")
            onClicked: windowMenu.request(index => tasksModel.requestToggleMaximized(index))
        }
        PlasmaExtras.MenuItem {
            separator: true
        }
        PlasmaExtras.MenuItem {
            text: i18n("Close")
            icon: "window-close"
            enabled: windowMenu.can("IsClosable")
            onClicked: windowMenu.request(index => tasksModel.requestClose(index))
        }
    }
}
