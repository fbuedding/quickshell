import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../theme"
import "../components"

PanelWindow {
    id: root
    property var screen

    IpcHandler {
        target: "powermenu"
        function toggle() {
            PowerMenuState.toggle();
        }
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: PowerMenuState.menuVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-powermenu"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    mask: Region {
        item: PowerMenuState.menuVisible ? maskCover : null
    }

    Item {
        id: maskCover
        anchors.fill: parent
    }

    color: "transparent"

    // Click outside to close
    MouseArea {
        anchors.fill: parent
        enabled: PowerMenuState.menuVisible
        onClicked: PowerMenuState.hide()
    }

    // Escape key to close
    FocusScope {
        anchors.fill: parent
        focus: PowerMenuState.menuVisible
        Keys.onEscapePressed: PowerMenuState.hide()
    }

    // ── Menu Panel ──────────────────────────────────────────────────────────
    Rectangle {
        id: panel
        anchors {
            top: parent.top
            topMargin: 0
            left: parent.left
            leftMargin: 0
        }
        width: 220
        height: contentCol.implicitHeight + 20

        // Seamless connection with topbar and screen edge:
        // Top-left and Top-right MUST have no rounded corners
        color: Colors.colBg
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: 0
        bottomRightRadius: Theme.cornerRadius

        clip: true

        // Slide from left to right
        property real slideX: PowerMenuState.menuVisible ? 0 : -width
        Behavior on slideX {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }
        transform: Translate { x: panel.slideX }

        opacity: PowerMenuState.menuVisible ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }

        // ── Actions ─────────────────────────────────────────────────────────
        Column {
            id: contentCol
            anchors {
                top: parent.top
                topMargin: 10
                left: parent.left
                leftMargin: 10
                right: parent.right
                rightMargin: 10
            }
            spacing: 4

            Repeater {
                model: [
                    {
                        name: "Suspend",
                        desc: "Bereitschaft",
                        icon: "󰤄",
                        iconColor: Colors.colBlue,
                        cmd: "systemctl suspend"
                    },
                    {
                        name: "Logout",
                        desc: "Abmelden",
                        icon: "󰍃",
                        iconColor: Colors.colPurple,
                        cmd: "hyprshutdown --vt 2"
                    },
                    {
                        name: "Reboot",
                        desc: "Neustart",
                        icon: "󰜉",
                        iconColor: Colors.colYellow,
                        cmd: "hyprshutdown -t 'Restarting...' --post-cmd 'reboot'"
                    },
                    {
                        name: "Shutdown",
                        desc: "Herunterfahren",
                        icon: "⏻",
                        iconColor: Colors.colRed,
                        cmd: "hyprshutdown -t 'Shutting down...' --post-cmd 'shutdown -P 0'"
                    }
                ]

                Rectangle {
                    id: btn
                    width: contentCol.width
                    height: 38
                    radius: 6
                    color: btnMouse.containsMouse ? Colors.colBlack : "transparent"

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 10
                            rightMargin: 10
                        }
                        spacing: 12

                        Text {
                            text: modelData.icon
                            color: modelData.iconColor
                            font {
                                family: "JetBrainsMono Nerd Font"
                                pixelSize: 16
                            }
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            text: modelData.name
                            color: btnMouse.containsMouse ? Colors.colFg : Colors.colWhite
                            font {
                                family: "JetBrainsMono Nerd Font"
                                pixelSize: 12
                                weight: Font.Medium
                            }
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Text {
                            text: "󰅂"
                            color: Colors.colBrightBlack
                            font {
                                family: "JetBrainsMono Nerd Font"
                                pixelSize: 12
                            }
                            visible: btnMouse.containsMouse
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    MouseArea {
                        id: btnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            PowerMenuState.hide();
                            Quickshell.execDetached(["sh", "-c", modelData.cmd]);
                        }
                    }
                }
            }
        }
    }

    // ── Bottom-left concave curve — seamless connection with left border
    ConcaveCurves {
        radius: Theme.cornerRadius
        color: Colors.colBg
        isTop: true
        mirrored: false
        anchors.top: panel.bottom
        anchors.left: panel.left
        transform: Translate { x: panel.slideX }
        opacity: panel.opacity
    }

    // ── Top-right concave curve — seamless connection with topbar
    ConcaveCurves {
        radius: Theme.cornerRadius
        color: Colors.colBg
        isTop: true
        mirrored: false
        anchors.top: panel.top
        anchors.left: panel.right
        transform: Translate { x: panel.slideX }
        opacity: panel.opacity
    }
}
