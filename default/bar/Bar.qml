import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Shapes
import "../components"
import "../theme"

PanelWindow {
    id: barWindow
    property int barWidth: 25
    property int cornerRadius: 16
    property int borderThickness: 12
    property color barColor: Colors.colBg
    property color borderColor: Colors.colBg
    color: "transparent"
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    implicitWidth: borderThickness + barWidth + cornerRadius
    exclusiveZone: borderThickness + barWidth
    Item {
        anchors.fill: parent
        // Left border strip — z: 0, sits underneath
        Rectangle {
            id: borderStrip
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            width: barWindow.borderThickness
            color: barWindow.borderColor
            z: 0
        }
        Rectangle {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.leftMargin: 0
            width: barWindow.borderThickness + barWindow.barWidth
            color: barWindow.barColor
            z: 1
        }
        ConcaveCurves {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.leftMargin: barWindow.borderThickness + barWindow.barWidth
            radius: barWindow.cornerRadius
            color: barWindow.barColor
            isTop: true
            z: 1
        }
        ConcaveCurves {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.leftMargin: barWindow.borderThickness + barWindow.barWidth
            radius: barWindow.cornerRadius
            color: barWindow.barColor
            isTop: false
            z: 1
        }
    }
    Workspaces {
        anchors.top: parent.top
        z: 2
    }
    Column {
        anchors.bottom: parent.bottom
        spacing: 20
        z: 2
        SysInfo {}
        Volume {}
        // Battery {}
        Clock {}
    }
}
