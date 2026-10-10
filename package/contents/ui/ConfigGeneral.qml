/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_startText: startText.text
    property alias cfg_startIcon: startIcon.text
    property alias cfg_startFontFamily: startFontFamily.text
    property alias cfg_fontFamily: fontFamily.text
    property alias cfg_numFrequentApps: numFrequentApps.value
    property var cfg_hiddenPlaces: []
    property alias cfg_myComputerUrl: myComputerUrl.text
    property alias cfg_networkUrl: networkUrl.text
    property alias cfg_controlPanelCommand: controlPanelCommand.text
    property alias cfg_defaultsCommand: defaultsCommand.text
    property alias cfg_printersCommand: printersCommand.text
    property alias cfg_helpCommand: helpCommand.text
    property alias cfg_searchCommand: searchCommand.text
    property alias cfg_runCommand: runCommand.text

    Kirigami.FormLayout {
        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Start button")
        }
        QQC2.TextField {
            id: startText
            Kirigami.FormData.label: i18n("Label:")
        }
        QQC2.TextField {
            id: startIcon
            Kirigami.FormData.label: i18n("Icon:")
            placeholderText: i18n("Built-in flag")
        }
        QQC2.TextField {
            id: startFontFamily
            Kirigami.FormData.label: i18n("Font:")
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Menu")
        }
        QQC2.TextField {
            id: fontFamily
            Kirigami.FormData.label: i18n("Font:")
        }
        QQC2.SpinBox {
            id: numFrequentApps
            Kirigami.FormData.label: i18n("Frequently used programs:")
            from: 0
            to: 12
        }
        Repeater {
            model: [
                { key: "recent", text: i18n("My Recent Documents") },
                { key: "pictures", text: i18n("My Pictures") },
                { key: "music", text: i18n("My Music") },
                { key: "network", text: i18n("My Network Places") },
                { key: "defaults", text: i18n("Set Program Access and Defaults") },
                { key: "printers", text: i18n("Printers and Faxes") }
            ]

            delegate: QQC2.CheckBox {
                required property var modelData
                required property int index

                Kirigami.FormData.label: index === 0 ? i18n("Show:") : ""
                text: modelData.text
                checked: cfg_hiddenPlaces.indexOf(modelData.key) < 0
                onToggled: {
                    const hidden = cfg_hiddenPlaces.filter(key => key !== modelData.key);
                    if (!checked) {
                        hidden.push(modelData.key);
                    }
                    cfg_hiddenPlaces = hidden;
                }
            }
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Locations and commands")
        }
        QQC2.TextField {
            id: myComputerUrl
            Kirigami.FormData.label: i18n("My Computer:")
            Layout.fillWidth: true
        }
        QQC2.TextField {
            id: networkUrl
            Kirigami.FormData.label: i18n("My Network Places:")
            Layout.fillWidth: true
        }
        QQC2.TextField {
            id: controlPanelCommand
            Kirigami.FormData.label: i18n("Control Panel:")
            Layout.fillWidth: true
        }
        QQC2.TextField {
            id: defaultsCommand
            Kirigami.FormData.label: i18n("Program Access and Defaults:")
            Layout.fillWidth: true
        }
        QQC2.TextField {
            id: printersCommand
            Kirigami.FormData.label: i18n("Printers and Faxes:")
            Layout.fillWidth: true
        }
        QQC2.TextField {
            id: helpCommand
            Kirigami.FormData.label: i18n("Help and Support:")
            Layout.fillWidth: true
        }
        QQC2.TextField {
            id: searchCommand
            Kirigami.FormData.label: i18n("Search:")
            Layout.fillWidth: true
        }
        QQC2.TextField {
            id: runCommand
            Kirigami.FormData.label: i18n("Run…:")
            Layout.fillWidth: true
        }
    }
}
