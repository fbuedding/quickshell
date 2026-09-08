import QtQuick
import QtQuick.Layouts
import Quickshell
import "../theme"

RowLayout {
    id: clockRoot
    spacing: 5
    Layout.alignment: Qt.AlignVCenter

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
