pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../calendar"

Singleton {
    id: root

    property bool panelVisible: false
    property bool dnd: false

    readonly property var server: notifServer
    readonly property var notifications: notifServer.trackedNotifications
    readonly property int count: notifServer.trackedNotifications.values.length

    // Active popup toasts shown on-screen
    property var activePopups: []

    function togglePanel() {
        panelVisible = !panelVisible;
        if (panelVisible) CalendarState.hide();
    }
    function showPanel() {
        panelVisible = true;
        CalendarState.hide();
    }
    function hidePanel()   { panelVisible = false; }
    function toggleDnd()   { dnd = !dnd; }

    function dismiss(notification) {
        if (!notification) {
            clearStalePopups();
            return;
        }
        removePopup(notification);
        try {
            if (typeof notification.dismiss === "function") {
                notification.dismiss();
            }
        } catch (e) {
            console.warn("Error dismissing notification:", e);
        }
    }

    function dismissAll() {
        let list = notifServer.trackedNotifications.values.slice();
        for (let i = 0; i < list.length; i++) {
            try {
                if (list[i] && typeof list[i].dismiss === "function") {
                    list[i].dismiss();
                }
            } catch (e) {}
        }
        activePopups = [];
    }

    function addPopup(notif) {
        if (!notif || notif.id === undefined) return;
        let list = [];
        for (let i = 0; i < activePopups.length; i++) {
            let item = activePopups[i];
            if (item && item.id !== undefined) {
                if (item.id === notif.id) return;
                list.push(item);
            }
        }
        list.push(notif);
        activePopups = list;

        // Auto-remove popup when the notification is closed by client or dismissed
        try {
            if (notif.closed && typeof notif.closed.connect === "function") {
                notif.closed.connect(() => {
                    removePopup(notif.id);
                });
            }
        } catch (e) {}
    }

    function removePopup(notifOrId) {
        let targetId = (typeof notifOrId === "object" && notifOrId !== null) ? notifOrId.id : notifOrId;
        let list = [];
        for (let i = 0; i < activePopups.length; i++) {
            let item = activePopups[i];
            if (item && item.id !== undefined) {
                if (targetId !== undefined && item.id === targetId) {
                    continue;
                }
                list.push(item);
            }
        }
        activePopups = list;
    }

    function clearStalePopups() {
        let list = [];
        for (let i = 0; i < activePopups.length; i++) {
            let item = activePopups[i];
            if (item && item.id !== undefined) {
                list.push(item);
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
            if (!root.dnd && !notif.lastGeneration) {
                root.addPopup(notif);
            }
        }
    }
}
