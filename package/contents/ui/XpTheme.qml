/*
    SPDX-License-Identifier: GPL-2.0-or-later

    Luna (Windows XP, blue) colour and metric constants, sampled at 96 DPI.
*/
import QtQuick

QtObject {
    property string fontFamily: "Tahoma"
    property string startFontFamily: "Franklin Gothic Medium"

    readonly property int fontPixelSize: 11

    // Selection
    readonly property color highlight: "#316ac5"
    readonly property color highlightText: "#ffffff"

    // Outer frame
    readonly property color frame: "#4282d6"
    readonly property color frameHighlight: "#72ade9"
    readonly property color orange: "#da884a"
    readonly property int cornerRadius: 7

    // Columns
    readonly property color leftBackground: "#ffffff"
    readonly property color leftText: "#000000"
    readonly property color subtitleText: "#8c8c8c"
    readonly property color leftSeparator: "#cfcfcf"
    readonly property color rightBackground: "#d3e5fa"
    readonly property color rightBorder: "#95bdee"
    readonly property color rightText: "#00136b"
    readonly property color rightSeparator: "#87b3e2"

    // Cascading (All Programs) menus
    readonly property color cascadeBackground: "#ffffff"
    readonly property color cascadeBorder: "#aca899"
    readonly property color cascadeSeparator: "#aca899"
    readonly property color disabledText: "#aca899"
    readonly property int cascadeRowHeight: 22

    // Metrics
    readonly property int menuWidth: 380
    readonly property int leftWidth: 190
    readonly property int headerHeight: 54
    readonly property int footerHeight: 36
}
