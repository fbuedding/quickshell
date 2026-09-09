import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import QtQuick.Shapes
import "../theme"
import "../components"

PanelWindow {
    id: root
    property var screen

    readonly property bool isFullscreen: {
        let mon = root.screen ? Hyprland.monitorFor(root.screen) : null;
        if (mon?.activeWorkspace?.hasFullscreen) return true;
        if (Hyprland.focusedWorkspace?.hasFullscreen) return true;
        let top = Hyprland.activeToplevel;
        if (top?.lastIpcObject && (top.lastIpcObject.fullscreen > 0 || top.lastIpcObject.fullscreen === true)) return true;
        return false;
    }

    IpcHandler {
        target: "applauncher"
        function toggle() {
            AppLauncherState.toggle();
        }
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: AppLauncherState.launcherVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-launcher"

    exclusionMode: root.isFullscreen ? ExclusionMode.Ignore : ExclusionMode.Normal

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    mask: Region {
        item: AppLauncherState.launcherVisible ? maskCover : null
    }
    Item {
        id: maskCover
        anchors.fill: parent
    }

    color: "transparent"

    // ── State ──────────────────────────────────────────────────────────────
    property string searchQuery: ""
    property int selectedIndex: 0
    readonly property bool isSearching: searchQuery.trim() !== ""

    property var filteredApps: {
        var q = searchQuery.trim().toLowerCase();
        var vals = DesktopEntries.applications.values;

        if (q !== "") {
            // Search mode: filter by name / genericName / keywords, alpha sort
            return vals.filter(function (e) {
                if (e.name.toLowerCase().indexOf(q) !== -1)
                    return true;
                if (e.genericName && e.genericName.toLowerCase().indexOf(q) !== -1)
                    return true;
                for (var i = 0; i < e.keywords.length; i++)
                    if (e.keywords[i].toLowerCase().indexOf(q) !== -1)
                        return true;
                return false;
            }).sort(function (a, b) {
                return a.name.localeCompare(b.name);
            });
        }

        // Default mode: recent apps first, then alphabetical
        var recent = AppLauncherState.recentIds;
        return vals.slice().sort(function (a, b) {
            var ai = recent.indexOf(a.id);
            var bi = recent.indexOf(b.id);
            if (ai !== -1 && bi !== -1)
                return ai - bi;
            if (ai !== -1)
                return -1;
            if (bi !== -1)
                return 1;
            return a.name.localeCompare(b.name);
        });
    }

    onFilteredAppsChanged: selectedIndex = 0

    // ── Launch ─────────────────────────────────────────────────────────────
    function launchEntry(entry) {
        AppLauncherState.recordLaunch(entry.id);
        entry.execute();
        AppLauncherState.hide();
    }

    // ── Navigation ─────────────────────────────────────────────────────────
    function navigate(delta) {
        if (filteredApps.length === 0)
            return;
        selectedIndex = (selectedIndex + delta + filteredApps.length) % filteredApps.length;
        listView.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    Connections {
        target: AppLauncherState
        function onLauncherVisibleChanged() {
            if (AppLauncherState.launcherVisible) {
                searchInput.text = "";
                root.searchQuery = "";
                root.selectedIndex = 0;
                searchInput.forceActiveFocus();
            }
        }
    }

    // ── Accent colours ─────────────────────────────────────────────────────
    readonly property color accentFill: Colors.colBlack
    readonly property color accentIcon: Colors.colBrightBlack
    readonly property color fgDim: Colors.colBrightBlack

    // ── Panel geometry ─────────────────────────────────────────────────────
    readonly property int maxVisible: 7
    readonly property int itemH: 42
    readonly property int panelW: 440
    // 12 top-pad + 4 handle + 8 + 44 search + 8 + list + 12 bot-pad
    readonly property int panelH: 88 + Math.min(filteredApps.length, maxVisible) * itemH
    readonly property int cornerRadius: Theme.cornerRadius

    // Shared slide offset — drives the panel AND the two corner pieces in sync
    property real slideY: AppLauncherState.launcherVisible ? 0 : (panelH + panel.anchors.bottomMargin + 10)
    Behavior on slideY {
        NumberAnimation {
            duration: 500
            easing.type: Easing.OutCubic
        }
    }

    // Click outside → close
    MouseArea {
        anchors.fill: parent
        enabled: AppLauncherState.launcherVisible
        onClicked: AppLauncherState.hide()
    }

    // ── Panel ──────────────────────────────────────────────────────────────
    Rectangle {
        id: panel
        width: root.panelW
        // Smooth height shrink/grow when filteredApps count changes
        height: root.panelH
        Behavior on height {
            NumberAnimation {
                duration: 500
                easing.type: Easing.OutCubic
            }
        }

        clip: true   // keep list items inside during height animation

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.isFullscreen ? 12 : 0

        // Semi-translucent frosted panel in normal mode or rounded card in fullscreen mode
        color: Colors.colBg
        topLeftRadius: root.isFullscreen ? 12 : root.cornerRadius
        topRightRadius: root.isFullscreen ? 12 : root.cornerRadius
        bottomLeftRadius: root.isFullscreen ? 12 : 0
        bottomRightRadius: root.isFullscreen ? 12 : 0
        border.width: root.isFullscreen ? Theme.borderWidth : 0
        border.color: Theme.borderColor

        // Slide up / down
        transform: Translate { y: root.slideY }

        // ── Content ────────────────────────────────────────────────────────
        Column {
            anchors {
                top: parent.top
                topMargin: 12
                left: parent.left
                leftMargin: 12
                right: parent.right
                rightMargin: 12
            }
            spacing: 0

            // Drag handle
            Rectangle {
                width: 36
                height: 4
                radius: 2
                anchors.horizontalCenter: parent.horizontalCenter
                color: Qt.rgba(1, 1, 1, 0.22)
            }

            Item {
                width: 1
                height: 8
            }

            // ── Search box ─────────────────────────────────────────────────
            Rectangle {
                width: parent.width
                height: 44
                radius: 10
                color: Qt.rgba(1, 1, 1, 0.07)

                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: "transparent"
                    border.color: Colors.colBrightBlack
                    border.width: 1
                    opacity: searchInput.activeFocus ? 0.55 : 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                        }
                    }
                }

                Row {
                    anchors {
                        fill: parent
                        leftMargin: 14
                        rightMargin: 14
                    }
                    spacing: 10

                    Item {
                        width: parent.width - 40
                        height: parent.height

                        Text {
                            anchors.fill: parent
                            text: root.isSearching ? "" : "Search apps…"
                            color: Colors.colBrightBlack
                            opacity: 0.28
                            font {
                                pixelSize: 13
                                family: "JetBrainsMono Nerd Font"
                            }
                            verticalAlignment: Text.AlignVCenter
                            visible: searchInput.text === ""
                        }

                        TextInput {
                            id: searchInput
                            anchors.fill: parent
                            color: Colors.colFg
                            selectionColor: root.accentFill
                            font {
                                pixelSize: 13
                                family: "JetBrainsMono Nerd Font"
                            }
                            verticalAlignment: TextInput.AlignVCenter
                            clip: true

                            onTextChanged: root.searchQuery = text

                            Keys.onPressed: function (event) {
                                if (event.key === Qt.Key_Up) {
                                    root.navigate(-1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Down) {
                                    root.navigate(1);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    if (root.filteredApps.length > 0)
                                        root.launchEntry(root.filteredApps[root.selectedIndex]);
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Escape) {
                                    AppLauncherState.hide();
                                    event.accepted = true;
                                }
                            }
                        }
                    }
                }
            }

            Item {
                width: 1
                height: 8
            }

            // ── App list ───────────────────────────────────────────────────
            ListView {
                id: listView
                width: parent.width
                height: Math.min(root.filteredApps.length, root.maxVisible) * root.itemH
                model: root.filteredApps
                clip: true
                interactive: false

                // Wheel on list (belt-and-suspenders alongside panel MouseArea)
                MouseArea {
                    anchors.fill: parent
                    onWheel: function (wheel) {
                        if (wheel.angleDelta.y < 0)
                            root.navigate(1);
                        else
                            root.navigate(-1);
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.filteredApps.length === 0
                    text: "No apps found"
                    color: Colors.colBrightBlack
                    opacity: 0.28
                    font {
                        pixelSize: 13
                        family: "JetBrainsMono Nerd Font"
                    }
                }

                delegate: Item {
                    id: appRow
                    width: listView.width
                    height: root.itemH

                    readonly property bool sel: root.selectedIndex === index
                    readonly property bool isRecent: !root.isSearching && AppLauncherState.recentIds.indexOf(modelData.id) !== -1 && AppLauncherState.recentIds.indexOf(modelData.id) < 5

                    Rectangle {
                        anchors {
                            fill: parent
                            topMargin: 2
                            bottomMargin: 2
                        }
                        radius: 10
                        color: appRow.sel ? root.accentFill : "transparent"
                        Behavior on color {
                            ColorAnimation {
                                duration: 100
                            }
                        }

                        Row {
                            anchors {
                                fill: parent
                                leftMargin: 8
                                rightMargin: 8
                            }
                            spacing: 12

                            // Icon bubble
                            Rectangle {
                                width: 36
                                height: 36
                                radius: 9
                                anchors.verticalCenter: parent.verticalCenter
                                color: appRow.sel ? root.accentIcon : Qt.rgba(1, 1, 1, 0.08)
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 100
                                    }
                                }

                                Image {
                                    id: appIcon
                                    anchors.centerIn: parent
                                    width: 22
                                    height: 22
                                    source: modelData.icon !== "" ? "image://icon/" + modelData.icon : ""
                                    smooth: true
                                    mipmap: true
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: appIcon.status !== Image.Ready
                                    text: modelData.name.charAt(0).toUpperCase()
                                    font {
                                        pixelSize: 15
                                        family: "JetBrainsMono Nerd Font"
                                        weight: Font.Bold
                                    }
                                    color: appRow.sel ? Colors.colBlue : Colors.colFg
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 100
                                        }
                                    }
                                }
                            }

                            // Name + subtitle
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    text: modelData.name
                                    font {
                                        pixelSize: 13
                                        family: "JetBrainsMono Nerd Font"
                                        weight: appRow.sel ? Font.Medium : Font.Normal
                                    }
                                    color: appRow.sel ? Colors.colFg : root.fgDim
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 100
                                        }
                                    }
                                }

                                // "Recently used" pill OR generic name
                                Row {
                                    spacing: 6
                                    visible: appRow.isRecent || modelData.genericName !== ""

                                    Rectangle {
                                        visible: appRow.isRecent
                                        width: recentLabel.width + 8
                                        height: 14
                                        radius: 4
                                        color: Qt.rgba(Colors.colBlue.r, Colors.colBlue.g, Colors.colBlue.b, 0.22)
                                        anchors.verticalCenter: parent.verticalCenter

                                        Text {
                                            id: recentLabel
                                            anchors.centerIn: parent
                                            text: "recent"
                                            font {
                                                pixelSize: 9
                                                family: "JetBrainsMono Nerd Font"
                                            }
                                            color: Colors.colBlue
                                        }
                                    }

                                    Text {
                                        visible: modelData.genericName !== ""
                                        text: modelData.genericName
                                        font {
                                            pixelSize: 11
                                            family: "JetBrainsMono Nerd Font"
                                        }
                                        color: Colors.colFg
                                        opacity: 0.35
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: root.selectedIndex = index
                            onClicked: root.launchEntry(modelData)
                            onWheel: function (wheel) {
                                if (wheel.angleDelta.y < 0)
                                    root.navigate(1);
                                else
                                    root.navigate(-1);
                            }
                        }
                    }
                }
            }

            Item {
                width: 1
                height: 4
            }
        }
    }

    // ── Bottom concave corners — makes the panel look like it's sliding
    //     out of / into the bottom screen edge instead of having sharp
    //     corners against the transparent background. Siblings of `panel`
    //     (not children) so panel's clip: true doesn't cut them off, and
    //     both share root.slideY so they move in lockstep with the panel.
    ConcaveCurves {
        radius: root.cornerRadius
        color: Colors.colBg
        isTop: false
        mirrored: true
        borderWidth: Theme.borderWidth
        borderColor: Theme.borderColor
        anchors.right: panel.left
        anchors.bottom: panel.bottom
        transform: Translate { y: root.slideY }
        visible: !root.isFullscreen
    }

    ConcaveCurves {
        radius: root.cornerRadius
        color: Colors.colBg
        isTop: false
        mirrored: false
        borderWidth: Theme.borderWidth
        borderColor: Theme.borderColor
        anchors.left: panel.right
        anchors.bottom: panel.bottom
        transform: Translate { y: root.slideY }
        visible: !root.isFullscreen
    }

    // ── Panel border contour (left edge, top-left corner, top edge, top-right corner, right edge)
    Shape {
        anchors.fill: panel
        transform: Translate { y: root.slideY }
        preferredRendererType: Shape.CurveRenderer
        visible: !root.isFullscreen

        ShapePath {
            fillColor: "transparent"
            strokeColor: Theme.borderColor
            strokeWidth: Theme.borderWidth

            startX: 0
            startY: panel.height - root.cornerRadius

            // Up left edge
            PathLine {
                x: 0
                y: root.cornerRadius
            }

            // Top-left rounded corner
            PathArc {
                x: root.cornerRadius
                y: 0
                radiusX: root.cornerRadius
                radiusY: root.cornerRadius
                direction: PathArc.Clockwise
            }

            // Across top edge
            PathLine {
                x: panel.width - root.cornerRadius
                y: 0
            }

            // Top-right rounded corner
            PathArc {
                x: panel.width
                y: root.cornerRadius
                radiusX: root.cornerRadius
                radiusY: root.cornerRadius
                direction: PathArc.Clockwise
            }

            // Down right edge
            PathLine {
                x: panel.width
                y: panel.height - root.cornerRadius
            }
        }
    }
}

