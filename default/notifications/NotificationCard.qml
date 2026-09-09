import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../theme"

Rectangle {
    id: root
    implicitWidth: parent ? parent.width : 380
    implicitHeight: mainCol.implicitHeight + 20
    radius: Theme.cornerRadius
    color: Colors.colSurface
    border.width: Theme.borderWidth
    border.color: Theme.borderColor
    clip: true

    required property var notification

    ColumnLayout {
        id: mainCol
        anchors {
            top: parent.top
            topMargin: 10
            left: parent.left
            leftMargin: 12
            right: parent.right
            rightMargin: 12
        }
        spacing: 6

        // ── Header (Icon + App name + Close button) ─────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // App Icon
            Item {
                implicitWidth: 16
                implicitHeight: 16

                IconImage {
                    anchors.fill: parent
                    source: {
                        let icon = root.notification.appIcon || "";
                        if (!icon) return "";
                        if (icon.startsWith("/") || icon.startsWith("file://") || icon.startsWith("image://")) return icon;
                        return Quickshell.iconPath(icon) || ("image://icon/" + icon);
                    }
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰂚"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    color: Colors.colMuted
                    visible: !root.notification.appIcon
                }
            }

            // App Name
            Text {
                text: root.notification.appName || root.notification.desktopEntry || "System"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                font.bold: true
                color: Colors.colRose
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            // Close button
            Rectangle {
                implicitWidth: 20
                implicitHeight: 20
                radius: 10
                color: closeMouse.containsMouse ? Colors.colBlack : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    color: closeMouse.containsMouse ? Colors.colRed : Colors.colMuted
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NotificationState.dismiss(root.notification)
                }
            }
        }

        // ── Content (Image + Summary + Body) ────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Thumbnail Image if present
            Rectangle {
                Layout.alignment: Qt.AlignTop
                implicitWidth: 44
                implicitHeight: 44
                radius: 4
                color: Colors.colBlack
                clip: true
                visible: !!root.notification.image

                Image {
                    anchors.fill: parent
                    source: root.notification.image || ""
                    fillMode: Image.PreserveAspectCrop
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: root.notification.summary || ""
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    font.bold: true
                    color: Colors.colFg
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    visible: text !== ""
                }

                Text {
                    Layout.fillWidth: true
                    text: root.notification.body || ""
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    color: Colors.colSubtle
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    visible: text !== ""
                }
            }
        }

        // ── Actions ─────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: Boolean(root.notification && root.notification.actions && root.notification.actions.length > 0)

            Repeater {
                model: root.notification.actions

                delegate: Rectangle {
                    implicitHeight: 24
                    implicitWidth: actionText.implicitWidth + 16
                    radius: 4
                    color: actionMouse.containsMouse ? Colors.colBlack : Colors.colSurface
                    border.width: 1
                    border.color: actionMouse.containsMouse ? Colors.colRose : Colors.colHighlight

                    Text {
                        id: actionText
                        anchors.centerIn: parent
                        text: modelData.text || ""
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        color: actionMouse.containsMouse ? Colors.colRose : Colors.colFg
                    }

                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: modelData.invoke()
                    }
                }
            }
        }
    }
}
