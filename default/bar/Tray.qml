import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "../theme"

RowLayout {
    id: root
    spacing: 6
    Layout.alignment: Qt.AlignVCenter

    property var barWindow: null

    readonly property int itemCount: SystemTray.items.values.length
    readonly property bool hasItems: itemCount > 0
    visible: hasItems

    Repeater {
        model: SystemTray.items

        delegate: Rectangle {
            id: itemRect
            implicitWidth: 26
            implicitHeight: 26
            radius: Theme.cornerRadius
            color: mouseArea.containsMouse ? Colors.colBlack : "transparent"
            Layout.alignment: Qt.AlignVCenter

            readonly property string iconSource: {
                if (!modelData.icon) return "";
                if (modelData.icon.startsWith("image://") || modelData.icon.startsWith("/") || modelData.icon.startsWith("file://")) {
                    return modelData.icon;
                }
                return Quickshell.iconPath(modelData.icon) || ("image://icon/" + modelData.icon);
            }

            IconImage {
                anchors.centerIn: parent
                width: 18
                height: 18
                source: itemRect.iconSource
            }

            QsMenuAnchor {
                id: menuAnchor
                menu: modelData.menu
                anchor.window: root.barWindow || itemRect.Window.window
                anchor.item: itemRect
                anchor.edges: Edges.Bottom
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor

                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        if (modelData.hasMenu && modelData.menu) {
                            menuAnchor.open();
                        } else {
                            modelData.display(root.barWindow || itemRect.Window.window, mouse.x, mouse.y);
                        }
                    } else if (mouse.button === Qt.LeftButton) {
                        modelData.activate();
                    } else if (mouse.button === Qt.MiddleButton) {
                        modelData.secondaryActivate();
                    }
                }

                onWheel: wheel => {
                    modelData.scroll(wheel.angleDelta.y, false);
                }
            }
        }
    }
}
