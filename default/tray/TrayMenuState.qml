pragma Singleton
import QtQuick

QtObject {
    id: root

    property bool visible: false
    property var menuHandle: null
    property real anchorX: 0
    property real anchorWidth: 26
    property var targetScreen: null
    property string activeAppTitle: ""

    function openMenu(menu, itemX, itemWidth, screen, title) {
        if (visible && menuHandle === menu) {
            hide();
            return;
        }
        menuHandle = menu;
        anchorX = itemX;
        anchorWidth = itemWidth;
        targetScreen = screen;
        activeAppTitle = title || "";
        visible = true;
    }

    function hide() {
        visible = false;
        menuHandle = null;
        activeAppTitle = "";
    }
}
