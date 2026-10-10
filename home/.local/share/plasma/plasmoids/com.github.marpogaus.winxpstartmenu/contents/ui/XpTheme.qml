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
    // Inner pixel of the 2 px side frame, left and right
    readonly property color frameInnerLeft: "#7693d3"
    readonly property color frameInnerRight: "#2476dd"
    readonly property color bodyTopLine: "#1768cf"
    readonly property color bodyBottomLine: "#1664cb"
    readonly property color orange: "#ea9736"
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
    // The right column darkens over its last 3 px
    readonly property var rightEdgeShade: ["#c5d2ec", "#b9c8eb", "#aec1ec"]

    // Cascading (All Programs) menus
    readonly property color cascadeBackground: "#ffffff"
    // Cascade frame, sampled from XP: 1 px border (lighter at top and
    // bottom) and a 5 px blue band inside the left border
    readonly property color cascadeBorder: "#418be5"
    // Cascades highlight in a slightly different blue than the start menu
    readonly property color cascadeHighlight: "#1664cb"
    readonly property color cascadeBorderLight: "#54a1ff"
    readonly property var cascadeBand: ["#89b4ed", "#2b7ae2", "#2b7ae2", "#307fe4", "#3484e6"]
    readonly property color cascadeSeparator: "#d6d6d3"
    readonly property color disabledText: "#aca899"
    readonly property int cascadeRowHeight: 22

    // Metrics (measured on a native 1024x768 XP screenshot, 96 DPI)
    readonly property int frameWidth: 2
    readonly property int leftWidth: 189
    readonly property int rightWidth: 188
    readonly property int menuWidth: frameWidth + leftWidth + 1 + rightWidth + frameWidth // 382
    readonly property int headerHeight: 64
    readonly property int footerHeight: 40
    readonly property int programRowHeight: 36
    readonly property int programIconSize: 32
    readonly property int placeRowHeight: 30
    readonly property int placeIconSize: 24
    readonly property int separatorHeight: 8
}
