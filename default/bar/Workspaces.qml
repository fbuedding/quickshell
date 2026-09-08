import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../theme"

Item {
    id: root
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 12
    implicitWidth: row.implicitWidth
    implicitHeight: 26

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: 9
            Rectangle {
                width: 26
                height: 24
                radius: 5

                property var workspace: Hyprland.workspaces.values.find(ws => ws.id === index + 1) ?? null
                property bool isActive: Hyprland.focusedWorkspace?.id === (index + 1)
                property bool hasWindows: (workspace?.toplevels?.values?.length ?? 0) > 0

                color: isActive ? Colors.colBlack : (wsMouse.containsMouse ? "#2a273f" : "transparent")
                border.color: isActive ? Colors.colPurple : "transparent"
                border.width: 1

                Text {
                    text: index + 1
                    color: parent.isActive ? Colors.colPurple : (parent.hasWindows ? Colors.colFg : Colors.colBrightBlack)
                    font.pixelSize: root.fontSize
                    font.family: root.fontFamily
                    font.bold: parent.isActive || parent.hasWindows
                    anchors.centerIn: parent
                }

                Rectangle {
                    width: 12
                    height: 2
                    radius: 1
                    color: Colors.colPurple
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: parent.isActive
                }

                MouseArea {
                    id: wsMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + (index + 1) + " })")
                }
            }
        }
    }
}
