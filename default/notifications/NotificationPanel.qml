import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "../theme"
import "../components"

PanelWindow {
    id: root
    property var screen

    IpcHandler {
        target: "notifications"
        function toggle() {
            NotificationState.togglePanel();
        }
        function open() {
            NotificationState.showPanel();
        }
        function close() {
            NotificationState.hidePanel();
        }
        function toggleDnd() {
            NotificationState.toggleDnd();
        }
        function dismissAll() {
            NotificationState.dismissAll();
        }
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: NotificationState.panelVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-notification-panel"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    mask: Region {
        item: NotificationState.panelVisible ? maskCover : null
    }

    Item {
        id: maskCover
        anchors.fill: parent
    }

    // Click outside to close
    MouseArea {
        anchors.fill: parent
        enabled: NotificationState.panelVisible
        onClicked: NotificationState.hidePanel()
    }

    // Escape key to close
    FocusScope {
        anchors.fill: parent
        focus: NotificationState.panelVisible
        Keys.onEscapePressed: NotificationState.hidePanel()
    }

    // ── Panel ───────────────────────────────────────────────────────────────
    Rectangle {
        id: panel
        anchors {
            top: parent.top
            bottom: parent.bottom
            right: parent.right
        }
        width: 420
        color: Colors.colBg

        // Slide animation from right to left
        property real slideX: NotificationState.panelVisible ? 0 : width + Theme.cornerRadius + 4
        Behavior on slideX {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }
        transform: Translate { x: panel.slideX }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 14

            // ── Top Bar Header ──────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: "Kontrollzentrum"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
                    font.bold: true
                    color: Colors.colFg
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                // DND Toggle Button
                Rectangle {
                    implicitHeight: 28
                    implicitWidth: dndRow.implicitWidth + 16
                    radius: Theme.cornerRadius
                    color: NotificationState.dnd ? Colors.colRose : (dndMouse.containsMouse ? Colors.colBlack : Colors.colSurface)
                    border.width: 1
                    border.color: NotificationState.dnd ? Colors.colRose : Theme.borderColor

                    RowLayout {
                        id: dndRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: NotificationState.dnd ? "󰂛" : "󰂚"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            color: NotificationState.dnd ? Colors.colBg : Colors.colFg
                        }

                        Text {
                            text: "DND"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            font.bold: true
                            color: NotificationState.dnd ? Colors.colBg : Colors.colFg
                        }
                    }

                    MouseArea {
                        id: dndMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotificationState.toggleDnd()
                    }
                }

                // Clear All Button
                Rectangle {
                    implicitHeight: 28
                    implicitWidth: clearRow.implicitWidth + 16
                    radius: Theme.cornerRadius
                    color: clearMouse.containsMouse ? Colors.colBlack : Colors.colSurface
                    border.width: 1
                    border.color: Theme.borderColor
                    opacity: NotificationState.count > 0 ? 1 : 0.4

                    RowLayout {
                        id: clearRow
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: "󰆴"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            color: Colors.colRed
                        }

                        Text {
                            text: "Löschen"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            color: Colors.colFg
                        }
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: NotificationState.count > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                        enabled: NotificationState.count > 0
                        onClicked: NotificationState.dismissAll()
                    }
                }
            }

            // ── Audio Output & Volume Control Widget ────────────────────────
            AudioControlWidget {
                Layout.fillWidth: true
            }

            // ── MPRIS Music Player Widget ────────────────────────────────────
            MprisPlayerWidget {
                Layout.fillWidth: true
            }

            // ── Divider ─────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.borderColor
            }

            // ── Notifications Section Header ────────────────────────────────
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Benachrichtigungen"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    font.bold: true
                    color: Colors.colFg
                }

                Rectangle {
                    implicitHeight: 18
                    implicitWidth: badgeCount.implicitWidth + 10
                    radius: 9
                    color: Colors.colBlack
                    visible: NotificationState.count > 0

                    Text {
                        id: badgeCount
                        anchors.centerIn: parent
                        text: NotificationState.count.toString()
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        font.bold: true
                        color: Colors.colRose
                    }
                }

                Item { Layout.fillWidth: true }
            }

            // ── Notifications List ──────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Empty State
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    visible: NotificationState.count === 0

                    Text {
                        text: "󰂚"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 36
                        color: Colors.colMuted
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "Keine Benachrichtigungen"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        color: Colors.colMuted
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                // Scrollable List
                ListView {
                    id: notifList
                    anchors.fill: parent
                    spacing: 8
                    clip: true
                    model: NotificationState.notifications.values
                    visible: NotificationState.count > 0

                    delegate: NotificationCard {
                        required property var modelData
                        width: notifList.width
                        notification: modelData
                    }
                }
            }
        }
    }

    // ── Top-left concave curve — seamless connection with TopBar ─────────────
    Item {
        anchors.top: panel.top
        anchors.right: panel.left
        width: Theme.cornerRadius
        height: Theme.cornerRadius
        transform: Translate { x: panel.slideX }

        ConcaveCurves {
            anchors.fill: parent
            radius: Theme.cornerRadius
            color: Colors.colBg
            isTop: true
            mirrored: true
            borderWidth: Theme.borderWidth
            borderColor: Theme.borderColor
        }
    }

    // ── Bottom-left concave curve — seamless connection with bottom border ───
    Item {
        anchors.bottom: panel.bottom
        anchors.right: panel.left
        width: Theme.cornerRadius
        height: Theme.cornerRadius
        transform: Translate { x: panel.slideX }

        ConcaveCurves {
            anchors.fill: parent
            radius: Theme.cornerRadius
            color: Colors.colBg
            isTop: false
            mirrored: true
            borderWidth: Theme.borderWidth
            borderColor: Theme.borderColor
        }
    }

    // ── Panel border contour (left edge) ────────────────────────────────────
    Shape {
        anchors.fill: panel
        transform: Translate { x: panel.slideX }
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: Theme.borderColor
            strokeWidth: Theme.borderWidth

            startX: 0
            startY: Theme.cornerRadius

            PathLine {
                x: 0
                y: panel.height - Theme.cornerRadius
            }
        }
    }
}
