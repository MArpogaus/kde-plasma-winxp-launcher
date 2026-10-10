/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_maximumButtonWidth: maximumButtonWidth.value
    property alias cfg_showOnlyCurrentScreen: showOnlyCurrentScreen.checked
    property alias cfg_showOnlyCurrentDesktop: showOnlyCurrentDesktop.checked
    property alias cfg_fontFamily: fontFamily.text

    Kirigami.FormLayout {
        QQC2.SpinBox {
            id: maximumButtonWidth
            Kirigami.FormData.label: i18n("Widest button:")
            from: 40
            to: 400
            textFromValue: value => i18n("%1 px", value)
        }
        QQC2.CheckBox {
            id: showOnlyCurrentScreen
            Kirigami.FormData.label: i18n("Show:")
            text: i18n("Only windows on this screen")
        }
        QQC2.CheckBox {
            id: showOnlyCurrentDesktop
            text: i18n("Only windows on the current desktop")
        }
        QQC2.TextField {
            id: fontFamily
            Kirigami.FormData.label: i18n("Font:")
        }
    }
}
