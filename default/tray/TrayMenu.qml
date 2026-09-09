import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Services.SystemTray
import "../theme"
import "../components"

PanelWindow {
    id: root
    property var screen

    IpcHandler {
        target: "traymenu"

        function openByName(name: string): void {
            if (!SystemTray.items) return;
            for (let i = 0; i < SystemTray.items.values.length; i++) {
                let item = SystemTray.items.values[i];
                let id = (item.id || "").toLowerCase();
                let title = (item.title || "").toLowerCase();
                let query = name.toLowerCase();
                if (id.includes(query) || title.includes(query)) {
                    let itemX = 59 + i * 32;
                    TrayMenuState.openMenu(item.menu, itemX, 26, root.screen, item.title || item.id);
                    return;
                }
            }
        }

        function openSteam(): void { openByName("steam"); }
        function openHeroic(): void { openByName("heroic"); }
        function openKeepass(): void { openByName("keepass"); }
        function openBluetooth(): void { openByName("blue"); }
        function openSignal(): void { openByName("signal"); }
        function openAusweis(): void { openByName("ausweis"); }

        function toggle(): void {
            if (TrayMenuState.visible) {
                TrayMenuState.hide();
            } else {
                openSteam();
            }
        }

        function close(): void {
            TrayMenuState.hide();
        }
    }

    readonly property bool isCurrentScreen: (root.screen === TrayMenuState.targetScreen) || (!TrayMenuState.targetScreen && root.screen === Quickshell.screens[0])

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: (TrayMenuState.visible && isCurrentScreen) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-traymenu"

    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    mask: Region {
        item: (TrayMenuState.visible && isCurrentScreen) ? maskCover : null
    }

    Item {
        id: maskCover
        anchors {
            top: parent.top
            topMargin: Theme.barHeight
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        // Click outside (below topbar) to close
        MouseArea {
            anchors.fill: parent
            onClicked: TrayMenuState.hide()
        }

        // Escape key to close
        FocusScope {
            anchors.fill: parent
            focus: TrayMenuState.visible && isCurrentScreen
            Keys.onEscapePressed: TrayMenuState.hide()
        }

        // Opener for the root tray menu
        QsMenuOpener {
            id: rootOpener
            menu: (TrayMenuState.visible && isCurrentScreen) ? TrayMenuState.menuHandle : null
        }

        // Helper functions
        function formatAppTitle(title) {
            if (!title) return "";
            let t = title.toLowerCase();
            if (t.includes("heroic")) return "Heroic Games";
            if (t.includes("steam")) return "Steam";
            if (t.includes("keepass")) return "KeePassXC";
            if (t.includes("signal")) return "Signal";
            if (t.includes("ausweis")) return "AusweisApp";
            if (t.includes("blue")) return "Bluetooth";
            return title.replace(/_/g, " ").replace(/-/g, " ");
        }

        function formatLabel(str) {
            if (!str) return "";
            return str.replace(/&&/g, "&").replace(/&/g, "");
        }

        function resolveIcon(icon) {
            if (!icon) return "";
            if (icon.startsWith("image://") || icon.startsWith("/") || icon.startsWith("file://")) {
                return icon;
            }
            return Quickshell.iconPath(icon) || ("image://icon/" + icon);
        }

        // Timer to close submenus smoothly when moving cursor
        Timer {
            id: submenuCloseTimer
            interval: 180
            onTriggered: {
                panel.activeSubmenuEntry = null;
            }
        }

        // ── Main Menu Panel ──────────────────────────────────────────────────
        Rectangle {
            id: panel

            readonly property int minX: Theme.borderThickness + Theme.cornerRadius + 6
            readonly property int maxX: root.width - width - Theme.borderThickness - Theme.cornerRadius - 6
            property real targetX: TrayMenuState.anchorX - 10
            x: Math.max(minX, Math.min(maxX, targetX))
            y: 0

            width: Math.max(200, Math.min(360, contentCol.implicitWidth + 16))
            height: contentCol.implicitHeight + 16

            property var activeSubmenuEntry: null
            property real activeSubmenuY: 0

            color: Colors.colBg
            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: Theme.cornerRadius
            bottomRightRadius: Theme.cornerRadius

            border.width: 0

            visible: TrayMenuState.visible && isCurrentScreen
            opacity: (visible && rootOpener.children && rootOpener.children.values.length > 0) ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }

            property real slideY: visible ? 0 : -6
            Behavior on slideY {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }
            transform: Translate { y: panel.slideY }

            // Prevent clicks inside panel from dismissing menu
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {}
            }

            ColumnLayout {
                id: contentCol
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    topMargin: 8
                    bottomMargin: 8
                    leftMargin: 8
                    rightMargin: 8
                }
                spacing: 2

                // Subtle App Title Header
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 20
                    visible: TrayMenuState.activeAppTitle !== ""
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        Text {
                            text: maskCover.formatAppTitle(TrayMenuState.activeAppTitle)
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            font.bold: true
                            color: Colors.colIris
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Theme.borderColor
                    opacity: 0.35
                    visible: TrayMenuState.activeAppTitle !== ""
                    Layout.leftMargin: 4
                    Layout.rightMargin: 4
                    Layout.bottomMargin: 3
                }

                // Root Menu Items
                Repeater {
                    model: rootOpener.children

                    delegate: Loader {
                        Layout.fillWidth: true
                        sourceComponent: modelData.isSeparator ? separatorComponent : itemComponent
                        property var itemData: modelData
                        property bool isSubmenu: false
                        Layout.preferredHeight: item ? item.implicitHeight : 0
                    }
                }
            }
        }

        // ── Top-left concave curve — seamless connection with topbar ─────────
        ConcaveCurves {
            id: leftCurve
            width: Theme.cornerRadius
            height: Theme.cornerRadius
            radius: Theme.cornerRadius
            color: Colors.colBg
            isTop: true
            mirrored: true
            borderWidth: Theme.borderWidth
            borderColor: Theme.borderColor
            anchors.top: panel.top
            anchors.right: panel.left
            transform: Translate { y: panel.slideY }
            visible: panel.visible && panel.opacity > 0.05
        }

        // ── Top-right concave curve — seamless connection with topbar ────────
        ConcaveCurves {
            id: rightCurve
            width: Theme.cornerRadius
            height: Theme.cornerRadius
            radius: Theme.cornerRadius
            color: Colors.colBg
            isTop: true
            mirrored: false
            borderWidth: Theme.borderWidth
            borderColor: Theme.borderColor
            anchors.top: panel.top
            anchors.left: panel.right
            transform: Translate { y: panel.slideY }
            visible: panel.visible && panel.opacity > 0.05
        }

        // ── Panel border contour (seamlessly flows out of topbar) ────────────
        Shape {
            anchors.fill: panel
            transform: Translate { y: panel.slideY }
            preferredRendererType: Shape.CurveRenderer
            visible: panel.visible && panel.opacity > 0.05

            ShapePath {
                fillColor: "transparent"
                strokeColor: Theme.borderColor
                strokeWidth: Theme.borderWidth

                startX: 0
                startY: Theme.cornerRadius

                // Down left edge
                PathLine {
                    x: 0
                    y: panel.height - Theme.cornerRadius
                }

                // Bottom-left corner
                PathArc {
                    x: Theme.cornerRadius
                    y: panel.height
                    radiusX: Theme.cornerRadius
                    radiusY: Theme.cornerRadius
                    direction: PathArc.Counterclockwise
                }

                // Across bottom edge
                PathLine {
                    x: panel.width - Theme.cornerRadius
                    y: panel.height
                }

                // Bottom-right corner
                PathArc {
                    x: panel.width
                    y: panel.height - Theme.cornerRadius
                    radiusX: Theme.cornerRadius
                    radiusY: Theme.cornerRadius
                    direction: PathArc.Counterclockwise
                }

                // Up right edge
                PathLine {
                    x: panel.width
                    y: Theme.cornerRadius
                }
            }
        }

        // ── Floating Submenu Panel ───────────────────────────────────────────
        Rectangle {
            id: submenuPanel
            visible: panel.activeSubmenuEntry !== null && panel.activeSubmenuEntry.hasChildren
            width: Math.max(180, Math.min(300, subCol.implicitWidth + 18))
            height: subCol.implicitHeight + 16
            color: Colors.colBg
            radius: 10
            border.width: Theme.borderWidth
            border.color: Theme.borderColor
            clip: true

            opacity: visible ? 1.0 : 0.0
            Behavior on opacity {
                NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
            }

            x: {
                let rightPos = panel.x + panel.width + 4;
                if (rightPos + width < root.width - 12) {
                    return rightPos;
                } else {
                    return Math.max(12, panel.x - width - 4);
                }
            }
            y: {
                let targetY = panel.y + panel.activeSubmenuY;
                return Math.max(0, Math.min(maskCover.height - height - 12, targetY));
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: submenuCloseTimer.stop()
                onClicked: {}
            }

            QsMenuOpener {
                id: subOpener
                menu: panel.activeSubmenuEntry
            }

            ColumnLayout {
                id: subCol
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    topMargin: 8
                    bottomMargin: 8
                    leftMargin: 8
                    rightMargin: 8
                }
                spacing: 2

                Repeater {
                    model: subOpener.children

                    delegate: Loader {
                        Layout.fillWidth: true
                        sourceComponent: modelData.isSeparator ? separatorComponent : itemComponent
                        property var itemData: modelData
                        property bool isSubmenu: true
                        Layout.preferredHeight: item ? item.implicitHeight : 0
                    }
                }
            }
        }

        // ── Component: Separator ─────────────────────────────────────────────
        Component {
            id: separatorComponent
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.borderColor
                opacity: 0.35
                Layout.topMargin: 3
                Layout.bottomMargin: 3
                Layout.leftMargin: 6
                Layout.rightMargin: 6
            }
        }

        // ── Component: Menu Item ─────────────────────────────────────────────
        Component {
            id: itemComponent
            Rectangle {
                id: itemBtn
                Layout.fillWidth: true
                implicitHeight: 28
                implicitWidth: itemRow.implicitWidth + 16
                radius: 6

                readonly property bool itemEnabled: itemData ? itemData.enabled : false
                readonly property int itemButtonType: itemData ? itemData.buttonType : QsMenuButtonType.None
                readonly property int itemCheckState: itemData ? itemData.checkState : Qt.Unchecked
                readonly property string itemIcon: itemData ? itemData.icon : ""
                readonly property string itemText: itemData ? itemData.text : ""
                readonly property bool itemHasChildren: itemData ? itemData.hasChildren : false
                readonly property bool isSelected: itemData && (panel.activeSubmenuEntry === itemData)

                color: {
                    if (!itemEnabled) return "transparent";
                    if (btnMouse.containsMouse || isSelected) return Colors.colBlack;
                    return "transparent";
                }
                Behavior on color {
                    ColorAnimation { duration: 80 }
                }

                RowLayout {
                    id: itemRow
                    anchors {
                        fill: parent
                        leftMargin: 8
                        rightMargin: 8
                    }
                    spacing: 8

                    // CheckBox / RadioButton / Icon indicator
                    Item {
                        width: 16
                        height: 16
                        Layout.alignment: Qt.AlignVCenter

                        // CheckBox
                        Rectangle {
                            anchors.centerIn: parent
                            width: 13
                            height: 13
                            radius: 3
                            color: (itemBtn.itemCheckState === Qt.Checked) ? Colors.colIris : "transparent"
                            border.width: 1
                            border.color: (itemBtn.itemCheckState === Qt.Checked) ? Colors.colIris : Colors.colMuted
                            visible: itemBtn.itemButtonType === QsMenuButtonType.CheckBox

                            Text {
                                anchors.centerIn: parent
                                text: "✓"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 9
                                font.bold: true
                                color: Colors.colBg
                                visible: itemBtn.itemCheckState === Qt.Checked
                            }
                        }

                        // RadioButton
                        Rectangle {
                            anchors.centerIn: parent
                            width: 13
                            height: 13
                            radius: 6.5
                            color: "transparent"
                            border.width: 1
                            border.color: (itemBtn.itemCheckState === Qt.Checked) ? Colors.colIris : Colors.colMuted
                            visible: itemBtn.itemButtonType === QsMenuButtonType.RadioButton

                            Rectangle {
                                anchors.centerIn: parent
                                width: 5
                                height: 5
                                radius: 2.5
                                color: Colors.colIris
                                visible: itemBtn.itemCheckState === Qt.Checked
                            }
                        }

                        // Icon Image
                        IconImage {
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            source: maskCover.resolveIcon(itemBtn.itemIcon)
                            visible: itemBtn.itemButtonType === QsMenuButtonType.None && itemBtn.itemIcon !== ""
                        }
                    }

                    // Item Text
                    Text {
                        Layout.fillWidth: true
                        text: maskCover.formatLabel(itemBtn.itemText)
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        color: !itemBtn.itemEnabled ? Colors.colMuted : (btnMouse.containsMouse ? Colors.colFg : Colors.colWhite)
                        elide: Text.ElideRight
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Submenu Arrow
                    Text {
                        text: "󰅂"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        color: (btnMouse.containsMouse || itemBtn.isSelected) ? Colors.colFg : Colors.colSubtle
                        visible: itemBtn.itemHasChildren
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                MouseArea {
                    id: btnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: itemBtn.itemEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                    onEntered: {
                        if (!itemData) return;
                        if (itemBtn.itemHasChildren) {
                            submenuCloseTimer.stop();
                            panel.activeSubmenuEntry = itemData;
                            panel.activeSubmenuY = itemBtn.mapToItem(panel, 0, 0).y;
                        } else {
                            if (!isSubmenu && panel.activeSubmenuEntry !== null) {
                                submenuCloseTimer.restart();
                            }
                        }
                    }

                    onClicked: {
                        if (!itemData || !itemBtn.itemEnabled) return;
                        if (itemBtn.itemHasChildren) {
                            submenuCloseTimer.stop();
                            panel.activeSubmenuEntry = (panel.activeSubmenuEntry === itemData) ? null : itemData;
                            panel.activeSubmenuY = itemBtn.mapToItem(panel, 0, 0).y;
                        } else {
                            if (typeof itemData.triggered === "function") {
                                itemData.triggered();
                            }
                            TrayMenuState.hide();
                        }
                    }
                }
            }
        }
    }
}
