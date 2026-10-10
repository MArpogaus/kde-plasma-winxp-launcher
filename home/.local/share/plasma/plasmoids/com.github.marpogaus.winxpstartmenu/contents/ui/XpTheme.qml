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
    readonly property color frameOutline: "#1854c2"
    readonly property color frame: "#4282d6"
    readonly property color frameHighlight: "#b4d0f8"
    readonly property color frameShade: "#3f74cf"
    readonly property color bodyTopLine: "#2f5aa8"
    readonly property color bodyBottomLine: "#2d73d3"
    readonly property color orange: "#da884a"
    readonly property int cornerRadius: 6

    // Columns
    readonly property color leftBackground: "#ffffff"
    readonly property color leftText: "#000000"
    readonly property color subtitleText: "#737373"
    readonly property color leftSeparator: "#d6d6d6"
    readonly property color rightBackground: "#d3e5fa"
    readonly property color rightBorder: "#95bdee"
    readonly property color rightText: "#071a4f"
    readonly property color rightSeparator: "#9db8e6"

    // Cascading (All Programs) menus
    readonly property color cascadeBackground: "#ffffff"
    // Cascade frame, sampled from XP: 1 px border (lighter at top and
    // bottom) and a 5 px blue band inside the left border
    readonly property color cascadeBorder: "#418be5"
    // Cascades highlight in a slightly different blue than the start menu
    readonly property color cascadeHighlight: "#1664cb"
    readonly property color cascadeBorderLight: "#54a1ff"
    readonly property var cascadeBand: ["#89b4ed", "#2b7ae2", "#2b7ae2", "#307fe4", "#3484e6"]
    readonly property color cascadeSeparator: "#aca899"
    readonly property color disabledText: "#aca899"
    readonly property int cascadeRowHeight: 22

    // Metrics (measured on a real XP start menu at 96 DPI)
    readonly property int frameWidth: 3
    readonly property int leftWidth: 230
    readonly property int rightWidth: 229
    readonly property int menuWidth: frameWidth + leftWidth + 1 + rightWidth + frameWidth // 466
    readonly property int headerHeight: 63
    readonly property int footerHeight: 39
    readonly property int programRowHeight: 40
    readonly property int programIconSize: 32
    readonly property int placeRowHeight: 32
    readonly property int placeIconSize: 24
    readonly property int separatorHeight: 8
}
