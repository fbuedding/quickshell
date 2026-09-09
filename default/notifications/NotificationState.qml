pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool panelVisible: false
    property bool dnd: false

    readonly property var server: notifServer
    readonly property var notifications: notifServer.trackedNotifications
    readonly property int count: notifServer.trackedNotifications.values.length

    // Active popup toasts shown on-screen
    property var activePopups: []

    function togglePanel() { panelVisible = !panelVisible; }
    function showPanel()   { panelVisible = true; }
    function hidePanel()   { panelVisible = false; }
    function toggleDnd()   { dnd = !dnd; }

    function dismiss(notification) {
        if (!notification || typeof notification.dismiss !== "function") return;
        removePopup(notification);
        notification.dismiss();
    }

    function dismissAll() {
        let list = notifServer.trackedNotifications.values.slice();
        for (let i = 0; i < list.length; i++) {
            list[i].dismiss();
        }
        activePopups = [];
    }

    function addPopup(notif) {
        for (let i = 0; i < activePopups.length; i++) {
            if (activePopups[i].id === notif.id) return;
        }
        let list = activePopups.slice();
        list.push(notif);
        activePopups = list;
    }

    function removePopup(notif) {
        let list = [];
        for (let i = 0; i < activePopups.length; i++) {
            if (activePopups[i].id !== notif.id) {
                list.push(activePopups[i]);
            }
        }
        activePopups = list;
    }

    NotificationServer {
        id: notifServer
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true
        keepOnReload: true

        onNotification: notif => {
            notif.tracked = true;
            if (!root.dnd) {
                root.addPopup(notif);
            }
        }
    }
}
