import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../notifications"

Item {
    id: root
    implicitWidth: 26
    implicitHeight: 26
    Layout.alignment: Qt.AlignVCenter

    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: (btnMouse.containsMouse || NotificationState.panelVisible) ? Colors.colBlack : "transparent"

        Text {
            anchors.centerIn: parent
            text: {
                if (NotificationState.dnd) return "󰂛";
                if (NotificationState.count > 0) return "󱅫";
                return "󰂚";
            }
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            color: {
                if (NotificationState.dnd) return Colors.colMuted;
                if (NotificationState.count > 0) return Colors.colRose;
                return Colors.colFg;
            }
        }

        // Unread badge dot
        Rectangle {
            anchors {
                top: parent.top
                topMargin: 3
                right: parent.right
                rightMargin: 3
            }
            width: 7
            height: 7
            radius: 3.5
            color: Colors.colRose
            visible: NotificationState.count > 0 && !NotificationState.dnd
        }
    }

    MouseArea {
        id: btnMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                NotificationState.toggleDnd();
            } else {
                NotificationState.togglePanel();
            }
        }
    }
}
