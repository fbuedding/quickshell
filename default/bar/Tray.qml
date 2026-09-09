import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "../theme"
import "../tray"

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
            color: (mouseArea.containsMouse || (TrayMenuState.visible && TrayMenuState.menuHandle === modelData.menu)) ? Colors.colBlack : "transparent"
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

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor

                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton || (mouse.button === Qt.LeftButton && modelData.onlyMenu)) {
                        if (modelData.hasMenu && modelData.menu) {
                            let pos = itemRect.mapToItem(null, 0, 0);
                            TrayMenuState.openMenu(
                                modelData.menu,
                                pos.x,
                                itemRect.width,
                                root.barWindow ? root.barWindow.screen : itemRect.Window.window?.screen,
                                modelData.title || modelData.id
                            );
                        } else {
                            TrayMenuState.hide();
                            modelData.display(root.barWindow || itemRect.Window.window, mouse.x, mouse.y);
                        }
                    } else if (mouse.button === Qt.LeftButton) {
                        TrayMenuState.hide();
                        modelData.activate();
                    } else if (mouse.button === Qt.MiddleButton) {
                        TrayMenuState.hide();
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
