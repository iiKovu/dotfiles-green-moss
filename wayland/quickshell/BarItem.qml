// BarItem.qml — a bar cell: icon + optional text.
// The bar has no background; the only one that ever appears is the hover
// highlight.
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string icon: ""
    property string label: ""
    property color iconColor: Colors.fg
    property color labelColor: Colors.fg
    property int iconSize: Appearance.fsM
    property int labelSize: Appearance.fsS
    property bool labelBold: false
    property string labelFamily: Appearance.font
    property int labelOffset: 0   // nudges the text down (px)
    property bool active: false
    property bool interactive: true
    property int itemHeight: 24
    property int hpad: 7
    property int gap: 6

    readonly property alias hovered: ma.containsMouse

    signal clicked()
    signal rightClicked()
    signal middleClicked()
    signal scrolled(int dir)             // +1 wheel up, -1 wheel down

    implicitWidth: row.implicitWidth + hpad * 2
    implicitHeight: itemHeight
    Layout.alignment: Qt.AlignVCenter

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: root.active ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.28)
             : (ma.containsMouse && root.interactive) ? Qt.rgba(0, 0, 0, 0.45)
             : "transparent"
        Behavior on color { ColorAnimation { duration: Appearance.mQuick; easing.type: Easing.OutQuad } }
    }

    Row {
        id: row
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 1   // the glyphs sit a bit high in their fonts
        spacing: root.gap

        Text {
            visible: root.icon.length > 0
            text: root.icon
            color: root.iconColor
            font.family: Appearance.font
            font.pixelSize: root.iconSize
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            visible: root.label.length > 0
            text: root.label
            color: root.labelColor
            font.family: root.labelFamily
            font.pixelSize: root.labelSize
            font.bold: root.labelBold
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: root.labelOffset
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        enabled: root.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: function (m) {
            if (m.button === Qt.RightButton) root.rightClicked();
            else if (m.button === Qt.MiddleButton) root.middleClicked();
            else root.clicked();
        }
        onWheel: function (w) { root.scrolled(w.angleDelta.y > 0 ? 1 : -1); }
    }
}
