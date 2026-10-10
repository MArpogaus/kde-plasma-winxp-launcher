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

    readonly property string timeFormat: Plasmoid.configuration.timeFormat || Qt.locale().timeFormat(Locale.ShortFormat)
    readonly property bool showsSeconds: /s/.test(timeFormat)
    readonly property date now: timeSource.data.Local ? timeSource.data.Local.DateTime : new Date()

    preferredRepresentation: fullRepresentation
    toolTipMainText: Qt.formatDate(now, Qt.locale().dateFormat(Locale.LongFormat))
    toolTipSubText: ""

    // Like Plasma's Digital Clock: wake up once a minute, on the minute,
    // unless the format shows seconds
    P5Support.DataSource {
        id: timeSource
        engine: "time"
        connectedSources: ["Local"]
        interval: root.showsSeconds ? 1000 : 60000
        intervalAlignment: root.showsSeconds ? P5Support.Types.NoAlignment : P5Support.Types.AlignToMinute
    }

    P5Support.DataSource {
        id: executable
        engine: "executable"
        onNewData: sourceName => disconnectSource(sourceName)

        property int launches: 0

        // Reconnecting a source whose process still runs is a no-op, so
        // make every launch a new source (see the start menu's exec()).
        function exec(command) {
            if (command && command.length > 0) {
                connectSource(command + "\n# " + (++launches));
            }
        }
    }

    fullRepresentation: Item {
        Layout.minimumWidth: label.implicitWidth + 2 * 10
        Layout.preferredWidth: Layout.minimumWidth
        Layout.maximumWidth: Layout.minimumWidth

        Text {
            id: label
            anchors.centerIn: parent
            text: Qt.formatTime(root.now, root.timeFormat)
            renderType: Text.NativeRendering
            font.family: Plasmoid.configuration.fontFamily
            font.pixelSize: 11
            color: "#ffffff"
        }

        MouseArea {
            anchors.fill: parent
            onDoubleClicked: executable.exec(Plasmoid.configuration.clickCommand)
        }
    }
}
