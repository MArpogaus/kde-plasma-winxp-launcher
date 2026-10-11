/*
    SPDX-License-Identifier: GPL-2.0-or-later

    XP notification area clock: white Tahoma 8 pt, the long date as
    tooltip, double-click opens the date and time settings. Follows the
    Region & Language formats, or XP style formats with own AM/PM symbols.
*/
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root

    readonly property bool regionFormats: Plasmoid.configuration.useRegionFormats
    readonly property string timeFormat: regionFormats
        ? Qt.locale().timeFormat(Locale.ShortFormat) : Plasmoid.configuration.timeFormat
    readonly property bool showsSeconds: /s/.test(timeFormat.replace(/'[^']*'/g, ""))
    readonly property date now: timeSource.data.Local ? timeSource.data.Local.DateTime : new Date()
    readonly property string timeText: regionFormats
        ? now.toLocaleTimeString(Qt.locale(), Locale.ShortFormat) : formatXpTime(now, timeFormat)
    readonly property string dateText: regionFormats
        ? now.toLocaleDateString(Qt.locale(), Locale.LongFormat)
        : now.toLocaleDateString(Qt.locale(), Plasmoid.configuration.longDateFormat)

    // XP time format: h/hh 12 hour, H/HH 24 hour, m/mm, s/ss, t/tt the first
    // letter of / the whole AM or PM symbol, 'quoted' text as is
    function formatXpTime(date, format) {
        const pad = n => (n < 10 ? "0" : "") + n;
        const hours = date.getHours();
        const symbol = hours < 12 ? Plasmoid.configuration.amSymbol : Plasmoid.configuration.pmSymbol;
        const tokens = {
            "HH": () => pad(hours),
            "H": () => hours,
            "hh": () => pad(hours % 12 || 12),
            "h": () => hours % 12 || 12,
            "mm": () => pad(date.getMinutes()),
            "m": () => date.getMinutes(),
            "ss": () => pad(date.getSeconds()),
            "s": () => date.getSeconds(),
            "tt": () => symbol,
            "t": () => symbol.charAt(0)
        };
        return format.replace(/'[^']*'|HH?|hh?|mm?|ss?|tt?/g,
            token => token.charAt(0) === "'" ? token.slice(1, -1) : tokens[token]()).trim();
    }

    preferredRepresentation: fullRepresentation
    toolTipMainText: dateText
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
        id: clock

        Layout.minimumWidth: Plasmoid.configuration.showClock ? label.implicitWidth + 2 * 10 : 1
        Layout.preferredWidth: Layout.minimumWidth
        Layout.maximumWidth: Layout.minimumWidth

        // Centred on the visible taskbar; the applet area inside the panel's
        // padding is not centred on it
        PanelArea {
            id: panelArea
            target: clock
        }

        Text {
            id: label
            anchors.horizontalCenter: parent.horizontalCenter
            // In a vertical panel the visible taskbar spans the whole screen
            // height, so centre on the applet itself there
            readonly property rect area: Plasmoid.formFactor === PlasmaCore.Types.Vertical
                ? Qt.rect(0, 0, clock.width, clock.height) : panelArea.rect
            y: Math.round(area.y + (area.height - height) / 2)
            visible: Plasmoid.configuration.showClock
            text: root.timeText
            renderType: Text.NativeRendering
            font.family: Plasmoid.configuration.fontFamily
            font.pixelSize: 11
            color: Kirigami.Theme.textColor
        }

        MouseArea {
            anchors.fill: parent
            onDoubleClicked: executable.exec(Plasmoid.configuration.clickCommand)
        }
    }
}
