import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "preferences-desktop-plasma"
        source: "ConfigGeneral.qml"
    }
    ConfigCategory {
        name: i18n("Start Menu")
        icon: "start-here-kde"
        source: "ConfigStartMenu.qml"
    }
}
