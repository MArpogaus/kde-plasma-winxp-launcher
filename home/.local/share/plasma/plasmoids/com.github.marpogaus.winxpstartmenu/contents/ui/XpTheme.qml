/*
    SPDX-License-Identifier: GPL-2.0-or-later

    Fonts and metrics of the XP start menu (measured on a native XP
    screenshot, 96 DPI). Colours and artwork come from the Plasma theme.
*/
import QtQuick

QtObject {
    property string fontFamily: "Tahoma"
    property string startFontFamily: "Franklin Gothic Medium"
    // "Small icons" in Customize Start Menu
    property bool smallIcons: false
    property bool classicSmallIcons: false

    readonly property int fontPixelSize: 11

    // Start menu
    readonly property int leftWidth: 189
    readonly property int rightWidth: 188
    readonly property int headerHeight: 64
    readonly property int footerHeight: 40
    readonly property int programRowHeight: smallIcons ? 22 : 36
    readonly property int programIconSize: smallIcons ? 16 : 32
    readonly property int placeRowHeight: 30
    readonly property int placeIconSize: 24
    readonly property int separatorHeight: 8

    // Cascading menus
    readonly property int cascadeRowHeight: 22

    // Classic Start menu
    readonly property int classicRowHeight: classicSmallIcons ? 22 : 32
    readonly property int classicSeparatorHeight: 9
    readonly property int classicBannerWidth: 21
}
