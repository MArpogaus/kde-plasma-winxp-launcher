/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property var cfg_launchers: []
    property alias cfg_showDesktop: showDesktop.checked
    property alias cfg_maximumIcons: maximumIcons.value

    Kirigami.FormLayout {
        QQC2.CheckBox {
            id: showDesktop
            Kirigami.FormData.label: i18n("Show Desktop:")
            text: i18n("First icon")
        }
        QQC2.SpinBox {
            id: maximumIcons
            Kirigami.FormData.label: i18n("Icons before »:")
            from: 1
            to: 20
        }
        QQC2.TextArea {
            Kirigami.FormData.label: i18n("Launchers, one per line:")
            Layout.fillWidth: true
            Layout.minimumHeight: Kirigami.Units.gridUnit * 6
            text: cfg_launchers.join("\n")
            onEditingFinished: cfg_launchers = text.split("\n").map(line => line.trim()).filter(line => line.length > 0)
        }
        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            font: Kirigami.Theme.smallFont
            text: i18n("applications:org.kde.dolphin.desktop, preferred://browser, preferred://mailer or a path to a .desktop file.")
        }
    }
}
