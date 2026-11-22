// LightsPanel.qml — Bedroom lights (Sonoff TX2C), unfolded FROM the notch.
// Opened by the Control Centre's "Lights" toggle. One button per gang; the
// state and the backend live in ShellState (lights / setLight / lightsRun).
// Same shape as PowerPanel: a row of big buttons, colour on the background
// when on (see the note on ControlPanel's Toggle).
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    readonly property var items: [
        { key: "high", label: "High" },
        { key: "low",  label: "Low"  }
    ]

    MouseArea { anchors.fill: parent }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: ShellState.closePanel()

        RowLayout {
            anchors { fill: parent; leftMargin: 22; rightMargin: 22; topMargin: 30; bottomMargin: 20 }
            spacing: 12

            Repeater {
                model: root.items

                Rectangle {
                    id: btn
                    required property var modelData
                    readonly property bool on: ShellState.lights[modelData.key] === true

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 16
                    color: btn.on ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.42)
                         : bMa.containsMouse ? Colors.fill2 : Colors.fill3
                    Behavior on color { ColorAnimation { duration: Appearance.mQuick; easing.type: Easing.OutQuad } }
                    scale: bMa.pressed ? 0.95 : 1
                    Behavior on scale { NumberAnimation { duration: Appearance.mQuick; easing.type: Easing.OutCubic } }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: btn.on ? "󰌵" : "󰌶"
                            color: Colors.label
                            font.family: Appearance.font; font.pixelSize: Appearance.fsL
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: btn.modelData.label
                            color: btn.on ? Colors.label : Colors.label3
                            font.family: Appearance.fontUI; font.pixelSize: Appearance.fsXS
                            font.weight: btn.on ? Appearance.wMedium : Appearance.wRegular
                        }
                    }
                    MouseArea {
                        id: bMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ShellState.setLight(btn.modelData.key, !btn.on)
                    }
                }
            }
        }
    }

    // Unreachable switch (off the network, bad key): say so instead of lying.
    Text {
        visible: !ShellState.lightsOk && !ShellState.lightsBusy
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 4 }
        text: "Switch not responding"
        color: Colors.label3
        font.family: Appearance.fontUI; font.pixelSize: Appearance.fsXXS
    }
}
