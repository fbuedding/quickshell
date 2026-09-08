import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "../theme"
import "../app_launcher"

PanelWindow {
    id: barWindow
    property int barHeight: 34
    property color barColor: Colors.colBg

    color: barColor
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: barHeight
    exclusiveZone: barHeight
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-topbar"

    Item {
        anchors.fill: parent

        // Left Section: CachyOS Symbol (App Launcher)
        RowLayout {
            id: leftSection
            anchors {
                left: parent.left
                leftMargin: 16
                verticalCenter: parent.verticalCenter
            }
            spacing: 8

            Item {
                width: 26
                height: 26
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: logoMouse.containsMouse ? Colors.colBlack : "transparent"

                    Image {
                        id: logoImg
                        anchors.centerIn: parent
                        width: 20
                        height: 20
                        sourceSize: Qt.size(20, 20)
                        source: "file:///usr/share/icons/cachyos.svg"
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    // Distro fallback icon if SVG fails to load
                    Text {
                        anchors.centerIn: parent
                        text: ""
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16
                        color: Colors.colGreen
                        visible: logoImg.status !== Image.Ready
                    }
                }

                MouseArea {
                    id: logoMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: AppLauncherState.toggle()
                }
            }
        }

        // Center Section: Workspaces
        Workspaces {
            anchors.centerIn: parent
        }

        // Right Section: SysInfo, Volume, Clock
        RowLayout {
            id: rightSection
            anchors {
                right: parent.right
                rightMargin: 16
                verticalCenter: parent.verticalCenter
            }
            spacing: 12

            SysInfo {}

            Separator {}

            Volume {}

            Separator {}

            Clock {}
        }

        // Subtle bottom border line
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: 1
            color: Colors.colBlack
        }
    }
}
