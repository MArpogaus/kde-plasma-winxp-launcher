/*
    SPDX-License-Identifier: GPL-2.0-or-later

    Horizontal separator: the Plasma theme's line, centred in its height.
*/
import QtQuick
import org.kde.ksvg as KSvg

Item {
    id: separator

    property int leftInset: 0
    property int rightInset: 0

    implicitHeight: 8

    KSvg.SvgItem {
        x: separator.leftInset
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - separator.leftInset - separator.rightInset
        height: naturalSize.height
        imagePath: "widgets/line"
        elementId: "horizontal-line"
    }
}
