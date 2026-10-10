/*
    SPDX-License-Identifier: GPL-2.0-or-later

    Windows XP Quick Launch toolbar: 16 px launcher icons in 22 px cells,
    Show Desktop first, a » button for launchers that do not fit and a
    separator towards the task buttons. Like XP's: drop applications on it
    to add them, drag icons to reorder them, right-click to remove them.
    The start menu's "Add to Quick Launch" writes the same launcher list.
*/
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import org.kde.taskmanager as TaskManager
import org.kde.draganddrop as DragAndDrop

PlasmoidItem {
    id: root

    readonly property bool horizontal: Plasmoid.formFactor !== PlasmaCore.Types.Vertical
    readonly property int cell: 22
    readonly property int spacing: 1

    // Entries: Show Desktop (optional) followed by the launchers the
    // TasksModel kept (it drops duplicates, invalid URLs and preferred://
    // apps that are not set), so positions are counted and edited on its
    // list. Counted here: TasksModel's launcherCount and count only notify
    // changes after its first fill, while an Instantiator follows the rows.
    readonly property int launcherCount: {
        let n = 0;
        for (let i = 0; i < launcherRows.count; ++i) {
            if (launchers.data(launchers.makeModelIndex(i), TaskManager.AbstractTasksModel.IsLauncher) === true) {
                ++n;
            }
        }
        return n;
    }
    readonly property int entryCount: launcherCount + (Plasmoid.configuration.showDesktop ? 1 : 0)
    readonly property int shownCount: Math.min(entryCount, Plasmoid.configuration.maximumIcons)
    readonly property bool overflow: entryCount > shownCount

    preferredRepresentation: fullRepresentation

    // TaskManager resolves applications:, preferred:// and .desktop launcher
    // URLs to names and icons and starts them. Launchers come first; an
    // activity that does not exist filters out most windows, and the
    // delegates skip the rest (windows on all activities or demanding
    // attention) by IsLauncher.
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

    Instantiator {
        id: launcherRows
        model: launchers
        delegate: QtObject {}
    }

    P5Support.DataSource {
        id: executable
        engine: "executable"
        onNewData: sourceName => disconnectSource(sourceName)

        property int launches: 0

        // Reconnecting a source whose process still runs is a no-op, so
        // make every launch a new source
        function exec(command) {
            connectSource(command + "\n# " + (++launches));
        }
    }

    function showDesktop() {
        executable.exec("dbus-send --session --type=method_call --dest=org.kde.kglobalaccel "
            + "/component/kwin org.kde.kglobalaccel.Component.invokeShortcut string:'Show Desktop'");
    }

    function launch(row) {
        launchers.requestActivate(launchers.makeModelIndex(row));
    }

    // Launcher list editing; the TasksModel follows the configuration
    function editLaunchers(edit) {
        const list = Array.from(launchers.launcherList);
        edit(list);
        Plasmoid.configuration.launchers = list;
    }

    // The launcher URL for a dropped URL, or "" when the TasksModel would
    // ignore it (it only takes local files, applications: and preferred://;
    // anything else would shift the config indices against the model rows).
    // An installed application's .desktop file becomes the applications: URL
    // the start menu's "Add to Quick Launch" writes, so both match.
    function launcherUrl(url) {
        const text = url.toString();
        const app = text.match(/^file:\/\/.*\/share\/applications\/([^/]+\.desktop)$/);
        if (app) {
            return "applications:" + app[1];
        }
        // Other local files (documents, folders) would make dead launchers
        return /^(applications|preferred):/.test(text) || /^file:.*\.desktop$/.test(text) ? text : "";
    }

    // Returns whether anything was added
    function addLaunchers(urls, position) {
        const added = urls.map(launcherUrl).filter(url => url.length > 0);
        if (added.length === 0) {
            return false;
        }
        editLaunchers(list => {
            let at = Math.max(0, Math.min(position, list.length));
            added.forEach(url => {
                if (!list.includes(url)) {
                    list.splice(at++, 0, url);
                }
            });
        });
        return true;
    }

    function removeLauncher(position) {
        editLaunchers(list => list.splice(position, 1));
    }

    function moveLauncher(from, to) {
        if (from !== to) {
            editLaunchers(list => list.splice(to, 0, list.splice(from, 1)[0]));
        }
    }

    // Launcher position (insertion point) for a point in the bar
    property Item iconRow: null
    function launcherIndexAt(x, y) {
        const along = horizontal ? x - iconRow.x : y - iconRow.y;
        const first = Plasmoid.configuration.showDesktop ? 1 : 0;
        const slot = Math.round(along / (cell + spacing)) - first;
        return Math.max(0, Math.min(slot, shownCount - first));
    }

    // Widest launcher name in the overflow menu
    property real overflowTextWidth: 0

    // Insertion marker position while something is dragged over the bar
    property int dropIndex: -1

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

        Component.onCompleted: root.iconRow = row

        // Applications dragged from menus, Dolphin or the desktop
        DragAndDrop.DropArea {
            anchors.fill: parent
            // Otherwise the panel's own drop area (for adding widgets)
            // takes the drop
            preventStealing: true
            onDragEnter: event => root.dropIndex = event.mimeData.hasUrls ? root.launcherIndexAt(event.x, event.y) : -1
            onDragMove: event => root.dropIndex = event.mimeData.hasUrls ? root.launcherIndexAt(event.x, event.y) : -1
            onDragLeave: root.dropIndex = -1
            onDrop: event => {
                if (root.addLaunchers(event.mimeData.urls, root.dropIndex)) {
                    event.accept(Qt.CopyAction);
                }
                root.dropIndex = -1;
            }
        }

        // Where a dropped or dragged launcher goes
        Rectangle {
            visible: root.dropIndex >= 0
            readonly property real offset: (root.dropIndex + (Plasmoid.configuration.showDesktop ? 1 : 0)) * (root.cell + root.spacing) - 2
            x: root.horizontal ? row.x + offset : 0
            y: root.horizontal ? row.y : row.y + offset
            width: root.horizontal ? 2 : bar.width
            height: root.horizontal ? root.cell : 2
            color: "#ffffff"
            z: 1
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

                    launcherIndex: index

                    // Launchers come first in the model, in configuration order
                    visible: model.IsLauncher === true
                        && index + (Plasmoid.configuration.showDesktop ? 1 : 0) < root.shownCount
                    iconSource: model.decoration
                    toolTip: model.display ?? ""
                    onClicked: root.launch(index)
                }
            }

            // XP's » for the icons that do not fit, in the top half of the
            // taskbar; it only looks like a button under the pointer
            Item {
                visible: root.overflow
                width: 13
                height: root.cell

                Rectangle {
                    id: overflowButton
                    // the row is centred on the taskbar; XP's button starts
                    // 3 px below the taskbar's top
                    y: root.horizontal ? Math.round(bar.area.y + 3 - row.y) : 0
                    width: parent.width
                    height: 12
                    radius: 2
                    color: overflowMouse.pressed ? "#1d5fd0" : overflowMouse.containsMouse ? "#5a9cf8" : "transparent"
                    border.color: overflowMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.35) : "transparent"

                    Text {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -1
                        text: "»"
                        font.family: "Tahoma"
                        font.pixelSize: 11
                        font.bold: true
                        // XP's » is light blue, white under the pointer
                        color: overflowMouse.containsMouse ? "#ffffff" : "#70acff"
                    }
                    MouseArea {
                        id: overflowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: overflowPopup.toggle()
                    }
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

        // The launchers that do not fit, in an XP style menu above the »:
        // click starts one, right-click offers to remove it
        PlasmaCore.Dialog {
            id: overflowPopup

            visible: false
            type: PlasmaCore.Dialog.PopupMenu
            flags: Qt.WindowStaysOnTopHint
            location: PlasmaCore.Types.Floating
            // stay open while its context menu has the focus
            hideOnWindowDeactivate: overflowContext.status === PlasmaExtras.Menu.Closed

            function toggle() {
                if (visible) {
                    visible = false;
                    return;
                }
                visible = true;
                place();
                requestActivate();
            }

            // Above the », left edges aligned
            function place() {
                const p = overflowButton.mapToGlobal(0, 0);
                x = Math.round(p.x);
                y = Math.round(p.y) - height;
            }
            onHeightChanged: if (visible) place()

            Component.onCompleted: {
                if ("backgroundHints" in overflowPopup) {
                    overflowPopup.backgroundHints = PlasmaCore.Dialog.NoBackground;
                }
            }

            mainItem: Rectangle {
                width: overflowList.width + 6
                height: overflowList.height + 6
                color: "#ffffff"
                border.color: "#aca899"

                Column {
                    id: overflowList
                    x: 3
                    y: 3
                    width: Math.max(120, root.overflowTextWidth + 28 + 24)

                    Repeater {
                        model: launchers

                        delegate: Rectangle {
                            id: overflowRow

                            required property int index
                            required property var model

                            visible: model.IsLauncher === true
                                && index + (Plasmoid.configuration.showDesktop ? 1 : 0) >= root.shownCount
                            width: overflowList.width
                            height: visible ? 22 : 0
                            color: rowMouse.containsMouse ? "#316ac5" : "transparent"

                            Kirigami.Icon {
                                x: 4
                                anchors.verticalCenter: parent.verticalCenter
                                width: 16
                                height: 16
                                source: overflowRow.model.decoration
                                roundToIconSize: false
                            }
                            Text {
                                x: 28
                                anchors.verticalCenter: parent.verticalCenter
                                text: overflowRow.model.display ?? ""
                                font.family: "Tahoma"
                                font.pixelSize: 11
                                renderType: Text.NativeRendering
                                color: rowMouse.containsMouse ? "#ffffff" : "#000000"
                                onImplicitWidthChanged: root.overflowTextWidth = Math.max(root.overflowTextWidth, implicitWidth)
                            }
                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton) {
                                        overflowContext.launcherIndex = overflowRow.index;
                                        overflowContext.visualParent = overflowRow;
                                        overflowContext.open(mouse.x, mouse.y);
                                    } else {
                                        overflowPopup.visible = false;
                                        root.launch(overflowRow.index);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Connections {
            target: root
            function onOverflowChanged() {
                if (!root.overflow) {
                    overflowPopup.visible = false;
                }
            }
        }

        PlasmaExtras.Menu {
            id: overflowContext

            property int launcherIndex: -1

            PlasmaExtras.MenuItem {
                text: i18n("Open")
                icon: "system-run"
                onClicked: {
                    overflowPopup.visible = false;
                    root.launch(overflowContext.launcherIndex);
                }
            }
            PlasmaExtras.MenuItem {
                text: i18n("Remove from Quick Launch")
                icon: "list-remove"
                onClicked: root.removeLauncher(overflowContext.launcherIndex)
            }
        }
    }

    // One 22 px Quick Launch button with XP's hover and pressed look
    component LaunchButton: Item {
        id: button

        property var iconSource
        property string toolTip
        // Position in the launcher list; -1 for Show Desktop
        property int launcherIndex: -1
        property bool dragging: false

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

        // Click starts it; dragging along the bar moves it; right-click
        // offers to remove it
        MouseArea {
            id: mouse

            property point pressPoint

            anchors.fill: parent
            hoverEnabled: true
            // Show Desktop leaves the right button to the applet's own menu
            acceptedButtons: button.launcherIndex >= 0 ? Qt.LeftButton | Qt.RightButton : Qt.LeftButton
            onPressed: mouse => {
                pressPoint = Qt.point(mouse.x, mouse.y);
                button.dragging = false;
            }
            onPositionChanged: mouse => {
                // only the left button drags
                if (!(pressedButtons & Qt.LeftButton) || button.launcherIndex < 0) {
                    return;
                }
                const moved = Math.abs(mouse.x - pressPoint.x) + Math.abs(mouse.y - pressPoint.y);
                if (moved > 6) {
                    button.dragging = true;
                }
                if (button.dragging) {
                    const p = mapToItem(root.iconRow.parent, mouse.x, mouse.y);
                    root.dropIndex = root.launcherIndexAt(p.x, p.y);
                }
            }
            onReleased: mouse => {
                // dragging stays set until the next press so that this
                // release does not count as a click
                if (button.dragging) {
                    const to = root.dropIndex;
                    root.dropIndex = -1;
                    if (to >= 0) {
                        root.moveLauncher(button.launcherIndex, to > button.launcherIndex ? to - 1 : to);
                    }
                }
            }
            onCanceled: {
                button.dragging = false;
                root.dropIndex = -1;
            }
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    if (button.launcherIndex >= 0) {
                        contextMenu.open(mouse.x, mouse.y);
                    }
                } else if (!button.dragging) {
                    button.clicked();
                }
            }
        }

        PlasmaExtras.Menu {
            id: contextMenu
            visualParent: button

            PlasmaExtras.MenuItem {
                text: i18n("Remove from Quick Launch")
                icon: "list-remove"
                onClicked: root.removeLauncher(button.launcherIndex)
            }
            PlasmaExtras.MenuItem {
                text: i18n("Configure Quick Launch…")
                icon: "configure"
                onClicked: Plasmoid.internalAction("configure").trigger()
            }
        }
    }
}
