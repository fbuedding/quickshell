import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import "../theme"
import "../i18n"

Rectangle {
    id: root
    implicitWidth: parent ? parent.width : 380
    implicitHeight: contentCol.implicitHeight + 24
    radius: Theme.cornerRadius + 2
    color: Colors.colSurface
    border.width: Theme.borderWidth
    border.color: Theme.borderColor
    clip: true

    property var adapter: Bluetooth.defaultAdapter
    readonly property bool isEnabled: adapter && adapter.enabled

    readonly property var pairedDevices: {
        let devs = Bluetooth.devices.values;
        let res = [];
        for (let i = 0; i < devs.length; i++) {
            let d = devs[i];
            if (d.paired) {
                res.push(d);
            }
        }
        return res;
    }

    function getDeviceIcon(device) {
        if (!device) return "󰂰";
        let str = ((device.name || "") + " " + (device.deviceName || "") + " " + (device.icon || "")).toLowerCase();
        if (str.includes("controller") || str.includes("xbox") || str.includes("gamepad") || str.includes("playstation") || str.includes("dualsense") || str.includes("switch") || str.includes("joy-con")) {
            return "󰊴";
        }
        if (str.includes("headphone") || str.includes("headset") || str.includes("buds") || str.includes("earphone") || str.includes("airpods")) {
            return "󰋋";
        }
        if (str.includes("keyboard") || str.includes("tastatur")) {
            return "󰌌";
        }
        if (str.includes("mouse") || str.includes("maus")) {
            return "󰍽";
        }
        if (str.includes("phone") || str.includes("smartphone") || str.includes("iphone") || str.includes("android")) {
            return "󰏲";
        }
        return "󰂰";
    }

    function toggleDevice(device) {
        if (!device) return;
        if (device.connected) {
            device.disconnect();
        } else {
            device.connect();
        }
    }

    ColumnLayout {
        id: contentCol
        anchors {
            top: parent.top
            topMargin: 12
            left: parent.left
            leftMargin: 12
            right: parent.right
            rightMargin: 12
        }
        spacing: 10

        // ── Header: Title & Power Toggle ─────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: root.isEnabled ? "󰂯" : "󰂲"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 18
                color: root.isEnabled ? Colors.colBlue : Colors.colMuted
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                spacing: 1
                Layout.fillWidth: true

                Text {
                    text: "Bluetooth"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    font.bold: true
                    color: Colors.colFg
                }

                Text {
                    text: {
                        if (!root.adapter) return "Kein Adapter";
                        if (!root.isEnabled) return "Deaktiviert";
                        let connectedCount = 0;
                        for (let d of root.pairedDevices) {
                            if (d.connected) connectedCount++;
                        }
                        if (connectedCount === 0) return "Aktiviert (Kein Gerät verbunden)";
                        return connectedCount + (connectedCount === 1 ? " Gerät verbunden" : " Geräte verbunden");
                    }
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    color: Colors.colSubtle
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Power Toggle Button
            Rectangle {
                implicitWidth: pwrText.implicitWidth + 16
                implicitHeight: 24
                radius: 12
                color: root.isEnabled ? Colors.colBlue : (pwrMouse.containsMouse ? Colors.colHighlight : Colors.colBlack)
                border.width: root.isEnabled ? 0 : 1
                border.color: Theme.borderColor

                Text {
                    id: pwrText
                    anchors.centerIn: parent
                    text: root.isEnabled ? "An" : "Aus"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    font.bold: true
                    color: root.isEnabled ? Colors.colBg : Colors.colMuted
                }

                MouseArea {
                    id: pwrMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.adapter) {
                            root.adapter.enabled = !root.adapter.enabled;
                        }
                    }
                }
            }
        }

        // ── Devices Section (When Enabled) ───────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: root.isEnabled

            // Sinks Divider
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Colors.colHighlight
                opacity: 0.6
            }

            Text {
                text: I18n.t("paired_devices")
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 9
                font.bold: true
                color: Colors.colSubtle
                Layout.leftMargin: 2
            }

            // Empty state if no paired devices
            Text {
                text: I18n.t("no_paired_devices")
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                color: Colors.colMuted
                visible: root.pairedDevices.length === 0
                Layout.leftMargin: 2
            }

            // Paired Devices List
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                visible: root.pairedDevices.length > 0

                Repeater {
                    model: root.pairedDevices

                    delegate: Rectangle {
                        id: devItem
                        required property var modelData
                        readonly property bool isConn: modelData.connected

                        Layout.fillWidth: true
                        implicitHeight: 34
                        radius: 6
                        color: isConn ? Colors.colHighlight : (devMouse.containsMouse ? Colors.colBlack : "transparent")
                        border.width: isConn ? 1 : 0
                        border.color: Colors.colPine

                        RowLayout {
                            anchors {
                                fill: parent
                                leftMargin: 10
                                rightMargin: 10
                            }
                            spacing: 8

                            Text {
                                text: root.getDeviceIcon(devItem.modelData)
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 14
                                color: devItem.isConn ? Colors.colPine : Colors.colSubtle
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: devItem.modelData.name || devItem.modelData.deviceName || devItem.modelData.address
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                font.bold: devItem.isConn
                                color: devItem.isConn ? Colors.colFg : Colors.colSubtle
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                            }

                            // Battery indicator if supported
                            RowLayout {
                                spacing: 3
                                visible: devItem.modelData.batteryAvailable
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    text: "󰥈"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    color: Colors.colPine
                                }

                                Text {
                                    text: devItem.modelData.battery + "%"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    color: Colors.colSubtle
                                }
                            }

                            // Status / Action Pill
                            Rectangle {
                                implicitWidth: statusText.implicitWidth + 12
                                implicitHeight: 20
                                radius: 10
                                color: {
                                    if (devItem.isConn) return Colors.colPine;
                                    if (devItem.modelData.state === BluetoothDeviceState.Connecting) return Colors.colYellow;
                                    return Colors.colBlack;
                                }

                                Text {
                                    id: statusText
                                    anchors.centerIn: parent
                                    text: {
                                        if (devItem.isConn) return "Verbunden";
                                        if (devItem.modelData.state === BluetoothDeviceState.Connecting) return "Verbinde...";
                                        return "Verbinden";
                                    }
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: devItem.isConn ? Colors.colBg : Colors.colFg
                                }
                            }
                        }

                        MouseArea {
                            id: devMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleDevice(devItem.modelData)
                        }
                    }
                }
            }
        }
    }
}
