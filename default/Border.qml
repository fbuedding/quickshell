import Quickshell
import Quickshell.Wayland
import QtQuick
import "./theme"
import "./components"

Scope {
    id: root
    property int thickness: Theme.borderThickness
    property color borderColor: Colors.colBg

    Variants {
        model: Quickshell.screens

        Item {
            id: screenRoot
            required property var modelData

            // Top border disabled: TopBar occupies the top edge directly

            PanelWindow {
                screen: screenRoot.modelData
                anchors {
                    bottom: true
                    left: true
                    right: true
                }
                implicitHeight: root.thickness
                exclusiveZone: root.thickness
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "quickshell-border-bottom"
                color: root.borderColor
            }

            PanelWindow {
                screen: screenRoot.modelData
                anchors {
                    top: true
                    bottom: true
                    left: true
                }
                implicitWidth: root.thickness
                exclusiveZone: root.thickness
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "quickshell-border-left"
                color: root.borderColor
            }

            PanelWindow {
                screen: screenRoot.modelData
                anchors {
                    top: true
                    bottom: true
                    right: true
                }
                implicitWidth: root.thickness
                exclusiveZone: root.thickness
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "quickshell-border-right"
                color: root.borderColor
            }

            // Concave screen corners connecting borders & topbar
            PanelWindow {
                screen: screenRoot.modelData
                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }
                color: "transparent"
                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "quickshell-corners"
                mask: Region { item: null } // Completely click-through

                // Top-Left corner (below TopBar, right of Left Border)
                ConcaveCurves {
                    radius: Theme.cornerRadius
                    color: root.borderColor
                    isTop: true
                    mirrored: false
                    anchors.top: parent.top
                    anchors.left: parent.left
                }

                // Top-Right corner (below TopBar, left of Right Border)
                ConcaveCurves {
                    radius: Theme.cornerRadius
                    color: root.borderColor
                    isTop: true
                    mirrored: true
                    anchors.top: parent.top
                    anchors.right: parent.right
                }

                // Bottom-Left corner (above Bottom Border, right of Left Border)
                ConcaveCurves {
                    radius: Theme.cornerRadius
                    color: root.borderColor
                    isTop: false
                    mirrored: false
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                }

                // Bottom-Right corner (above Bottom Border, left of Right Border)
                ConcaveCurves {
                    radius: Theme.cornerRadius
                    color: root.borderColor
                    isTop: false
                    mirrored: true
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                }

                // Inner shell border contour
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.width: Theme.borderWidth
                    border.color: Theme.borderColor
                    radius: Theme.cornerRadius
                }
            }
        }
    }
}
