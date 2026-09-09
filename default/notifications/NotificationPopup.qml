import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: root
    property var screen

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notification-popup"

    anchors {
        top: true
        bottom: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore

    margins {
        top: Theme.barHeight + 8
        bottom: Theme.borderThickness + 8
        right: Theme.borderThickness + 8
    }

    implicitWidth: 360
    color: "transparent"

    mask: Region {
        item: NotificationState.activePopups.length > 0 ? popupsCol : null
    }

    ColumnLayout {
        id: popupsCol
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        spacing: 8

        Repeater {
            model: NotificationState.activePopups

            delegate: Item {
                id: popupItem
                Layout.fillWidth: true
                implicitHeight: card.implicitHeight

                // Slide & Fade in animation
                opacity: 1
                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }

                NotificationCard {
                    id: card
                    anchors.fill: parent
                    notification: modelData
                }

                // Auto-dismiss timer (pauses when hovered)
                Timer {
                    interval: (modelData.expireTimeout > 0 ? modelData.expireTimeout * 1000 : 6000)
                    running: !hoverWatcher.containsMouse
                    onTriggered: NotificationState.removePopup(modelData)
                }

                HoverHandler {
                    id: hoverWatcher
                }
            }
        }
    }
}
