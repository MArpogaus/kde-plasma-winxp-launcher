/*
    SPDX-License-Identifier: GPL-2.0-or-later

    XP's Start Menu tab of Taskbar and Start Menu Properties: the choice
    between the Start menu and the Classic Start menu, and what their
    Customize dialogs offer (General and Advanced for the Start menu).
*/
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.private.kicker as Kicker

KCM.SimpleKCM {
    id: page

    property string cfg_menuStyle
    property alias cfg_smallIcons: smallIcons.checked
    property alias cfg_numFrequentApps: numFrequentApps.value
    property alias cfg_showInternet: showInternet.checked
    property alias cfg_showEmail: showEmail.checked
    property alias cfg_openSubmenusOnHover: openSubmenusOnHover.checked
    property alias cfg_highlightNewPrograms: highlightNewPrograms.checked
    property var cfg_hiddenPlaces: []
    property var cfg_menuPlaces: []
    property alias cfg_dragAndDrop: dragAndDrop.checked
    property alias cfg_scrollPrograms: scrollPrograms.checked
    property alias cfg_classicSmallIcons: classicSmallIcons.checked
    property alias cfg_classicShowRun: classicShowRun.checked
    property alias cfg_classicShowLogOff: classicShowLogOff.checked
    property var cfg_classicExpand: []
    property alias cfg_bannerTitle: bannerTitle.text
    property alias cfg_bannerEdition: bannerEdition.text

    readonly property bool classic: cfg_menuStyle === "classic"

    // A right-column entry is a link, a menu or not shown
    function placeMode(key) {
        return cfg_hiddenPlaces.indexOf(key) >= 0 ? "hidden" : cfg_menuPlaces.indexOf(key) >= 0 ? "menu" : "link";
    }
    function setPlaceMode(key, mode) {
        cfg_hiddenPlaces = cfg_hiddenPlaces.filter(k => k !== key).concat(mode === "hidden" ? [key] : []);
        cfg_menuPlaces = cfg_menuPlaces.filter(k => k !== key).concat(mode === "menu" ? [key] : []);
    }

    // "Clear List" forgets what Plasma's activity tracking remembers
    Kicker.RecentUsageModel {
        id: frequentApps
        shownItems: Kicker.RecentUsageModel.OnlyApps
    }
    Kicker.RecentUsageModel {
        id: recentDocuments
        shownItems: Kicker.RecentUsageModel.OnlyDocs
    }

    // The radio buttons share one parent; keep the two choices apart
    QQC2.ButtonGroup { id: styleGroup }
    QQC2.ButtonGroup { id: iconSizeGroup }

    Kirigami.FormLayout {
        QQC2.RadioButton {
            QQC2.ButtonGroup.group: styleGroup
            Kirigami.FormData.label: i18n("Menu style:")
            text: i18n("Start menu")
            checked: !page.classic
            onToggled: page.cfg_menuStyle = "xp"
        }
        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 20
            wrapMode: Text.Wrap
            font: Kirigami.Theme.smallFont
            text: i18n("Easy access to the Internet, e-mail and your favorite programs.")
        }
        QQC2.RadioButton {
            QQC2.ButtonGroup.group: styleGroup
            text: i18n("Classic Start menu")
            checked: page.classic
            onToggled: page.cfg_menuStyle = "classic"
        }
        QQC2.Label {
            Layout.maximumWidth: Kirigami.Units.gridUnit * 20
            wrapMode: Text.Wrap
            font: Kirigami.Theme.smallFont
            text: i18n("The menu style of earlier versions of Windows.")
        }

        // ---------------- Start menu: General ----------------
        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Start menu: General")
            visible: !page.classic
        }
        QQC2.RadioButton {
            QQC2.ButtonGroup.group: iconSizeGroup
            Kirigami.FormData.label: i18n("Icon size for programs:")
            visible: !page.classic
            text: i18n("Large icons")
            checked: !smallIcons.checked
        }
        QQC2.RadioButton {
            id: smallIcons
            QQC2.ButtonGroup.group: iconSizeGroup
            visible: !page.classic
            text: i18n("Small icons")
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Number of programs on Start menu:")
            visible: !page.classic
            QQC2.SpinBox {
                id: numFrequentApps
                from: 0
                to: 30
            }
            QQC2.Button {
                text: i18n("Clear List")
                // Plasma's "Forget all" also empties KDE's list of recent documents
                QQC2.ToolTip.text: i18n("Also clears the list of recent documents")
                QQC2.ToolTip.visible: hovered
                onClicked: frequentApps.trigger(0, "forgetAll", null)
            }
        }
        QQC2.CheckBox {
            id: showInternet
            Kirigami.FormData.label: i18n("Show on Start menu:")
            visible: !page.classic
            text: i18n("Internet (default web browser)")
        }
        QQC2.CheckBox {
            id: showEmail
            visible: !page.classic
            text: i18n("E-mail (default mail program)")
        }
        QQC2.Button {
            visible: !page.classic
            text: i18n("Choose Programs…")
            icon.name: "preferences-desktop-default-applications"
            onClicked: KCM.KCMLauncher.openSystemSettings("kcm_componentchooser")
        }

        // ---------------- Start menu: Advanced ----------------
        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Start menu: Advanced")
            visible: !page.classic
        }
        QQC2.CheckBox {
            id: openSubmenusOnHover
            Kirigami.FormData.label: i18n("Start menu settings:")
            visible: !page.classic
            text: i18n("Open submenus when I pause on them with my mouse")
        }
        QQC2.CheckBox {
            id: highlightNewPrograms
            visible: !page.classic
            text: i18n("Highlight newly installed programs")
        }

        // Entries XP shows as a link, as a menu or not at all
        Repeater {
            model: page.classic ? [] : [
                { key: "controlpanel", text: i18n("Control Panel:"), menu: true },
                { key: "computer", text: i18n("My Computer:"), menu: true },
                { key: "documents", text: i18n("My Documents:"), menu: true },
                { key: "music", text: i18n("My Music:"), menu: true },
                { key: "pictures", text: i18n("My Pictures:"), menu: true },
                { key: "connections", text: i18n("Network Connections:"), menu: false }
            ]
            delegate: QQC2.ComboBox {
                required property var modelData
                Kirigami.FormData.label: modelData.text
                textRole: "text"
                valueRole: "value"
                model: [
                    { value: "link", text: i18n("Display as a link") },
                    { value: "menu", text: i18n("Display as a menu") },
                    { value: "hidden", text: i18n("Don't display this item") }
                ].filter(option => modelData.menu || option.value !== "menu")
                currentIndex: indexOfValue(page.placeMode(modelData.key))
                onActivated: page.setPlaceMode(modelData.key, currentValue)
            }
        }

        // Entries XP only shows or hides
        Repeater {
            model: page.classic ? [] : [
                { key: "help", text: i18n("Help and Support") },
                { key: "network", text: i18n("My Network Places") },
                { key: "recent", text: i18n("My Recent Documents") },
                { key: "printers", text: i18n("Printers and Faxes") },
                { key: "run", text: i18n("Run command") },
                { key: "search", text: i18n("Search") },
                { key: "defaults", text: i18n("Set Program Access and Defaults") },
                { key: "admintools", text: i18n("System Administrative Tools") }
            ]
            delegate: QQC2.CheckBox {
                required property var modelData
                required property int index
                Kirigami.FormData.label: index === 0 ? i18n("Show:") : ""
                text: modelData.text
                checked: page.placeMode(modelData.key) !== "hidden"
                onToggled: page.setPlaceMode(modelData.key, checked ? "link" : "hidden")
            }
        }
        QQC2.Button {
            Kirigami.FormData.label: i18n("Recent documents:")
            visible: !page.classic
            text: i18n("Clear List")
            onClicked: recentDocuments.trigger(0, "forgetAll", null)
        }

        // ---------------- Classic Start menu ----------------
        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Classic Start menu")
            visible: page.classic
        }
        QQC2.CheckBox {
            id: classicSmallIcons
            Kirigami.FormData.label: i18n("Advanced Start menu options:")
            visible: page.classic
            text: i18n("Show Small Icons in Start menu")
        }
        QQC2.CheckBox {
            id: classicShowLogOff
            visible: page.classic
            text: i18n("Display Log Off")
        }
        QQC2.CheckBox {
            id: classicShowRun
            visible: page.classic
            text: i18n("Display Run")
        }
        Repeater {
            model: page.classic ? [
                { key: "controlpanel", text: i18n("Expand Control Panel") },
                { key: "documents", text: i18n("Expand My Documents") },
                { key: "music", text: i18n("Expand My Music") },
                { key: "pictures", text: i18n("Expand My Pictures") }
            ] : []
            delegate: QQC2.CheckBox {
                required property var modelData
                text: modelData.text
                checked: page.cfg_classicExpand.indexOf(modelData.key) >= 0
                onToggled: page.cfg_classicExpand = page.cfg_classicExpand.filter(k => k !== modelData.key)
                    .concat(checked ? [modelData.key] : [])
            }
        }
        RowLayout {
            Kirigami.FormData.label: i18n("Banner:")
            visible: page.classic
            QQC2.TextField {
                id: bannerTitle
                placeholderText: i18n("bold")
            }
            QQC2.TextField {
                id: bannerEdition
                placeholderText: i18n("regular")
            }
        }
        QQC2.Button {
            Kirigami.FormData.label: i18n("Recent documents:")
            visible: page.classic
            text: i18n("Clear")
            onClicked: recentDocuments.trigger(0, "forgetAll", null)
        }

        // ---------------- Both ----------------
        Item {
            Kirigami.FormData.isSection: true
        }
        QQC2.CheckBox {
            id: dragAndDrop
            Kirigami.FormData.label: i18n("Both menus:")
            text: i18n("Enable dragging and dropping")
        }
        QQC2.CheckBox {
            id: scrollPrograms
            text: i18n("Scroll Programs")
        }
    }
}
