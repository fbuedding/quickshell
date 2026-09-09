import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../calendar"

Item {
    id: clockWrapper
    implicitWidth: clockRow.implicitWidth + 14
    implicitHeight: 26
    Layout.alignment: Qt.AlignVCenter

    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: (clockMouse.containsMouse || CalendarState.dropdownVisible) ? Colors.colBlack : "transparent"

        RowLayout {
            id: clockRow
            anchors.centerIn: parent
            spacing: 6

            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: "󰥔"
                color: Colors.colPurple
                font {
                    family: "JetBrainsMono Nerd Font"
                    pixelSize: 13
                }
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: Qt.formatDateTime(clock.date, "HH:mm")
                color: Colors.colFg
                font {
                    family: "JetBrainsMono Nerd Font"
                    pixelSize: 12
                    weight: Font.Bold
                }
            }
        }
    }

    MouseArea {
        id: clockMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: CalendarState.toggle()
    }
}
