import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "../theme"
import "../components"

PanelWindow {
    id: root
    property var screen

    readonly property bool isFullscreen: {
        let mon = root.screen ? Hyprland.monitorFor(root.screen) : null;
        if (mon?.activeWorkspace?.hasFullscreen) return true;
        if (Hyprland.focusedWorkspace?.hasFullscreen) return true;
        let top = Hyprland.activeToplevel;
        if (top?.lastIpcObject && (top.lastIpcObject.fullscreen > 0 || top.lastIpcObject.fullscreen === true)) return true;
        return false;
    }

    IpcHandler {
        target: "powermenu"
        function toggle() {
            PowerMenuState.toggle();
        }
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: PowerMenuState.menuVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-powermenu"

    exclusionMode: root.isFullscreen ? ExclusionMode.Ignore : ExclusionMode.Normal

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
            topMargin: root.isFullscreen ? 12 : 0
            left: parent.left
            leftMargin: root.isFullscreen ? 12 : 0
        }
        width: 220
        height: contentCol.implicitHeight + 20

        // Seamless connection with topbar and screen edge in normal mode,
        // or fully rounded floating card in fullscreen mode
        color: Colors.colBg
        topLeftRadius: root.isFullscreen ? 12 : 0
        topRightRadius: root.isFullscreen ? 12 : 0
        bottomLeftRadius: root.isFullscreen ? 12 : 0
        bottomRightRadius: root.isFullscreen ? 12 : Theme.cornerRadius
        border.width: root.isFullscreen ? Theme.borderWidth : 0
        border.color: Theme.borderColor

        clip: true

        // Slide from left to right
        property real slideX: PowerMenuState.menuVisible ? 0 : -(width + anchors.leftMargin + Theme.cornerRadius + 10)
        Behavior on slideX {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }
        transform: Translate { x: panel.slideX }

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
                        name: I18n.t("suspend"),
                        desc: I18n.t("suspend_desc"),
                        icon: "󰤄",
                        iconColor: Colors.colBlue,
                        cmd: "systemctl suspend"
                    },
                    {
                        name: I18n.t("logout"),
                        desc: I18n.t("logout_desc"),
                        icon: "󰍃",
                        iconColor: Colors.colPurple,
                        cmd: "hyprshutdown --vt 2"
                    },
                    {
                        name: I18n.t("reboot"),
                        desc: I18n.t("reboot_desc"),
                        icon: "󰜉",
                        iconColor: Colors.colYellow,
                        cmd: "hyprshutdown -t 'Restarting...' --post-cmd 'reboot'"
                    },
                    {
                        name: I18n.t("shutdown"),
                        desc: I18n.t("shutdown_desc"),
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
        borderWidth: Theme.borderWidth
        borderColor: Theme.borderColor
        anchors.top: panel.bottom
        anchors.left: panel.left
        transform: Translate { x: panel.slideX }
        visible: !root.isFullscreen
    }

    // ── Top-right concave curve — seamless connection with topbar
    ConcaveCurves {
        radius: Theme.cornerRadius
        color: Colors.colBg
        isTop: true
        mirrored: false
        borderWidth: Theme.borderWidth
        borderColor: Theme.borderColor
        anchors.top: panel.top
        anchors.left: panel.right
        transform: Translate { x: panel.slideX }
        visible: !root.isFullscreen
    }

    // ── Panel border contour (right edge, rounded bottom-right, bottom edge)
    Shape {
        anchors.fill: panel
        transform: Translate { x: panel.slideX }
        preferredRendererType: Shape.CurveRenderer
        visible: !root.isFullscreen

        ShapePath {
            fillColor: "transparent"
            strokeColor: Theme.borderColor
            strokeWidth: Theme.borderWidth

            startX: panel.width
            startY: Theme.cornerRadius

            // Down right edge
            PathLine {
                x: panel.width
                y: panel.height - Theme.cornerRadius
            }

            // Bottom-right corner
            PathArc {
                x: panel.width - Theme.cornerRadius
                y: panel.height
                radiusX: Theme.cornerRadius
                radiusY: Theme.cornerRadius
                direction: PathArc.Clockwise
            }

            // Across bottom edge
            PathLine {
                x: Theme.cornerRadius
                y: panel.height
            }
        }
    }
}
