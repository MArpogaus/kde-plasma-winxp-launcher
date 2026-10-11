/*
    SPDX-License-Identifier: GPL-2.0-or-later

    Horizontal separator: an XP element of the Plasma theme (widgets/winxp,
    e.g. the start menu's faded lines) or the theme's line, centred in its
    height.
*/
import QtQuick
import org.kde.ksvg as KSvg

Item {
    id: separator

    property int leftInset: 0
    property int rightInset: 0
    // Element of widgets/winxp drawn at its own size instead of the line
    property string xpElement: ""

    implicitHeight: 8

    KSvg.Svg {
        id: winxp
        imagePath: "widgets/winxp"
    }
    readonly property bool useXp: xpElement !== "" && winxp.hasElement(xpElement)

    KSvg.SvgItem {
        visible: separator.useXp
        y: Math.ceil((parent.height - 1) / 2)
        width: naturalSize.width
        height: naturalSize.height
        svg: winxp
        elementId: separator.xpElement
    }

    KSvg.SvgItem {
        visible: !separator.useXp
        x: separator.leftInset
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - separator.leftInset - separator.rightInset
        height: naturalSize.height
        imagePath: "widgets/line"
        elementId: "horizontal-line"
    }
}
