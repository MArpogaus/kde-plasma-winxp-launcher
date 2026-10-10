/*
    SPDX-License-Identifier: GPL-2.0-or-later

    XP's clock settings: "Show the clock" from Taskbar Properties and the
    Time and Date tabs of Regional Options (format, AM/PM symbols, long
    date), plus what double-clicking the clock runs.
*/
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_showClock: showClock.checked
    property alias cfg_useRegionFormats: regionFormats.checked
    // Editable combo boxes set their text to the first entry when they are
    // completed, so the saved values are copied in afterwards
    property string cfg_timeFormat
    property string cfg_amSymbol
    property string cfg_pmSymbol
    property string cfg_longDateFormat
    property bool loaded: false

    Component.onCompleted: {
        timeFormat.editText = cfg_timeFormat;
        amSymbol.editText = cfg_amSymbol;
        pmSymbol.editText = cfg_pmSymbol;
        longDateFormat.editText = cfg_longDateFormat;
        loaded = true;
    }
    // Defaults and Reset change the values from outside
    onCfg_timeFormatChanged: if (loaded && timeFormat.editText !== cfg_timeFormat) timeFormat.editText = cfg_timeFormat
    onCfg_amSymbolChanged: if (loaded && amSymbol.editText !== cfg_amSymbol) amSymbol.editText = cfg_amSymbol
    onCfg_pmSymbolChanged: if (loaded && pmSymbol.editText !== cfg_pmSymbol) pmSymbol.editText = cfg_pmSymbol
    onCfg_longDateFormatChanged: if (loaded && longDateFormat.editText !== cfg_longDateFormat) longDateFormat.editText = cfg_longDateFormat
    property alias cfg_fontFamily: fontFamily.text
    property alias cfg_clickCommand: clickCommand.text

    Kirigami.FormLayout {
        QQC2.CheckBox {
            id: showClock
            Kirigami.FormData.label: i18n("Notification area:")
            text: i18n("Show the clock")
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.RadioButton {
            id: regionFormats
            Kirigami.FormData.label: i18n("Formats:")
            text: i18n("Use Region && Language settings")
        }
        QQC2.RadioButton {
            id: customFormats
            text: i18n("Customize (like XP's Regional Options)")
            checked: !regionFormats.checked
        }

        QQC2.ComboBox {
            id: timeFormat
            onEditTextChanged: if (loaded) cfg_timeFormat = editText
            Kirigami.FormData.label: i18n("Time format:")
            enabled: customFormats.checked
            editable: true
            model: ["h:mm tt", "hh:mm tt", "H:mm", "HH:mm", "h:mm:ss tt", "HH:mm:ss"]
        }
        QQC2.ComboBox {
            id: amSymbol
            onEditTextChanged: if (loaded) cfg_amSymbol = editText
            Kirigami.FormData.label: i18n("AM symbol:")
            enabled: customFormats.checked
            editable: true
            model: ["AM", "am", "a.m."]
        }
        QQC2.ComboBox {
            id: pmSymbol
            onEditTextChanged: if (loaded) cfg_pmSymbol = editText
            Kirigami.FormData.label: i18n("PM symbol:")
            enabled: customFormats.checked
            editable: true
            model: ["PM", "pm", "p.m."]
        }
        QQC2.ComboBox {
            id: longDateFormat
            onEditTextChanged: if (loaded) cfg_longDateFormat = editText
            Kirigami.FormData.label: i18n("Long date (tooltip):")
            enabled: customFormats.checked
            editable: true
            model: ["dddd, MMMM dd, yyyy", "MMMM dd, yyyy", "dddd, dd MMMM, yyyy", "dddd, d. MMMM yyyy", "dd MMMM yyyy"]
        }
        QQC2.Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            font: Kirigami.Theme.smallFont
            text: i18n("h = hour, hh = hour with leading zero, H/HH = 24 hour, mm = minute, ss = second, tt = AM/PM symbol; d, dd, ddd, dddd = day, M, MM, MMM, MMMM = month, yy, yyyy = year. Put other text in 'single quotes'.")
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.TextField {
            id: fontFamily
            Kirigami.FormData.label: i18n("Font:")
        }
        QQC2.TextField {
            id: clickCommand
            Kirigami.FormData.label: i18n("Double-click runs:")
            Layout.fillWidth: true
        }
    }
}
