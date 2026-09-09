import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../theme"

PanelWindow {
    id: root
    property var screen

    IpcHandler {
        target: "osd"
        function show() {
            OsdState.show();
        }
        function hide() {
            OsdState.hide();
        }
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-volume-osd"

    exclusionMode: ExclusionMode.Ignore

    anchors {
        bottom: true
    }

    margins {
        bottom: 70
    }

    implicitWidth: pill.width
    implicitHeight: pill.height

    color: "transparent"

    mask: Region {
        item: null
    }

    Rectangle {
        id: pill
        width: 280
        height: 48
        radius: 24
        color: Colors.colSurface
        border.color: Colors.colHighlight
        border.width: 1

        opacity: OsdState.visible ? 1.0 : 0.0
        scale: OsdState.visible ? 1.0 : 0.88
        transformOrigin: Item.Center

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutBack
                easing.overshoot: 1.1
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            spacing: 12

            Text {
                id: iconText
                Layout.alignment: Qt.AlignVCenter
                text: OsdState.icon
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 20
                color: OsdState.muted ? Colors.colRed : Colors.colBlue
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Layout.preferredWidth: 24
            }

            Rectangle {
                id: barTrack
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                height: 8
                radius: 4
                color: Colors.colBlack
                clip: true

                Rectangle {
                    id: barFill
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width * Math.min(1.0, Math.max(0.0, OsdState.volume / 100.0))
                    radius: 4
                    color: OsdState.muted ? Colors.colSubtle : (OsdState.volume > 100 ? Colors.colGold : Colors.colBlue)

                    Behavior on width {
                        NumberAnimation {
                            duration: 100
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                }
            }

            Text {
                id: percentText
                Layout.alignment: Qt.AlignVCenter
                text: {
                    if (!OsdState.sinkReady) return "--";
                    if (OsdState.muted) return "Mute";
                    return OsdState.volume + "%";
                }
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                font.bold: true
                color: OsdState.muted ? Colors.colRed : Colors.colFg
                Layout.preferredWidth: 42
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
