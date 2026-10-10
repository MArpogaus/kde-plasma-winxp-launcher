/*
    SPDX-License-Identifier: GPL-2.0-or-later

    XP notification area clock: white Tahoma 8 pt, the date as tooltip,
    double-click opens the date and time settings.
*/
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root

    property date now: new Date()

    preferredRepresentation: fullRepresentation
    toolTipMainText: Qt.formatDate(now, Qt.locale().dateFormat(Locale.LongFormat))
    toolTipSubText: ""

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    P5Support.DataSource {
        id: executable
        engine: "executable"
        onNewData: sourceName => disconnectSource(sourceName)
    }

    fullRepresentation: Item {
        Layout.minimumWidth: label.implicitWidth + 2 * 10
        Layout.preferredWidth: Layout.minimumWidth
        Layout.maximumWidth: Layout.minimumWidth

        Text {
            id: label
            anchors.centerIn: parent
            text: Plasmoid.configuration.timeFormat
                ? Qt.formatTime(root.now, Plasmoid.configuration.timeFormat)
                : Qt.formatTime(root.now, Qt.locale().timeFormat(Locale.ShortFormat))
            renderType: Text.NativeRendering
            font.family: Plasmoid.configuration.fontFamily
            font.pixelSize: 11
            color: "#ffffff"
        }

        MouseArea {
            anchors.fill: parent
            onDoubleClicked: {
                if (Plasmoid.configuration.clickCommand) {
                    executable.connectSource(Plasmoid.configuration.clickCommand);
                }
            }
        }
    }
}
