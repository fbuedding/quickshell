import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../theme"

Rectangle {
    id: root
    implicitWidth: parent ? parent.width : 380
    implicitHeight: contentCol.implicitHeight + 24
    radius: Theme.cornerRadius + 2
    color: Colors.colSurface
    border.width: Theme.borderWidth
    border.color: Theme.borderColor
    clip: true

    property var defaultSink: Pipewire.defaultAudioSink
    readonly property bool ready: defaultSink && defaultSink.ready
    readonly property bool muted: ready && defaultSink.audio.muted
    readonly property real volume: ready ? defaultSink.audio.volume : 0.0

    // Filter available audio output sinks (exclude monitors and loopbacks)
    readonly property var availableSinks: {
        if (!Pipewire.ready) return [];
        let res = [];
        let nodes = Pipewire.nodes.values;
        for (let i = 0; i < nodes.length; i++) {
            let n = nodes[i];
            if (n.isSink && !n.isStream && !n.name.endsWith(".monitor") && !n.description.includes("Easy Effects")) {
                res.push(n);
            }
        }
        return res;
    }

    PwObjectTracker {
        objects: root.defaultSink ? [root.defaultSink].concat(root.availableSinks) : root.availableSinks
    }

    function getSinkIcon(node) {
        if (!node) return "󰕾";
        let str = ((node.nickname || "") + " " + (node.description || "") + " " + (node.name || "")).toLowerCase();
        if (str.includes("headphone") || str.includes("headset") || str.includes("cloud") || str.includes("earphone") || str.includes("buds") || str.includes("airpods") || str.includes("iec958")) {
            return "󰋋";
        }
        if (str.includes("hdmi") || str.includes("displayport") || str.includes("ultragear") || str.includes("monitor") || str.includes("tv")) {
            return "󰍹";
        }
        return "󰓃";
    }

    function getSinkCleanName(node) {
        if (!node) return "Kein Gerät";
        if (node.nickname && node.nickname.trim() !== "") {
            return node.nickname;
        }
        let desc = node.description || node.name || "";
        desc = desc.replace("Digitales Stereo", "")
                   .replace("Controller", "")
                   .replace("(HDMI)", "")
                   .replace("(IEC958)", "")
                   .replace(/\[.*?\]/g, "")
                   .replace(/\s+/g, " ")
                   .trim();
        return desc || (node.name || "Audio-Ausgabe");
    }

    function selectSink(node) {
        if (!node) return;
        Pipewire.preferredDefaultAudioSink = node;
        // Move active streams to the newly selected sink
        Quickshell.execDetached([
            "sh", "-c",
            "pactl set-default-sink " + node.name + " 2>/dev/null; " +
            "for id in $(pactl list short sink-inputs 2>/dev/null | cut -f1); do pactl move-sink-input $id " + node.name + " 2>/dev/null; done"
        ]);
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

        // ── Header: Title & Mute Toggle ──────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: root.getSinkIcon(root.defaultSink)
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 18
                color: root.muted ? Colors.colMuted : Colors.colBlue
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                spacing: 1
                Layout.fillWidth: true

                Text {
                    text: "Audio-Ausgabe"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    font.bold: true
                    color: Colors.colFg
                }

                Text {
                    text: root.getSinkCleanName(root.defaultSink)
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    color: Colors.colSubtle
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Mute Pill Button
            Rectangle {
                implicitWidth: 30
                implicitHeight: 24
                radius: 12
                color: root.muted ? Colors.colRose : (muteMouse.containsMouse ? Colors.colBlack : Colors.colHighlight)

                Text {
                    anchors.centerIn: parent
                    text: root.muted ? "󰝟" : "󰕾"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    color: root.muted ? Colors.colBg : Colors.colFg
                }

                MouseArea {
                    id: muteMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.ready) {
                            root.defaultSink.audio.muted = !root.defaultSink.audio.muted;
                        }
                    }
                }
            }
        }

        // ── Interactive Volume Slider ────────────────────────────────────────
        Rectangle {
            id: sliderTrack
            Layout.fillWidth: true
            implicitHeight: 28
            radius: 6
            color: Colors.colBlack
            clip: true

            // Progress Fill
            Rectangle {
                id: sliderFill
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                }
                width: Math.max(0, Math.min(sliderTrack.width, sliderTrack.width * (root.ready ? root.defaultSink.audio.volume : 0.0)))
                radius: 6
                color: root.muted ? Colors.colMuted : Colors.colBlue

                Behavior on width {
                    enabled: !sliderMouse.pressed
                    NumberAnimation {
                        duration: 80
                        easing.type: Easing.OutQuad
                    }
                }
            }

            // Slider Content Overlay
            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 10
                    rightMargin: 10
                }

                Text {
                    text: root.muted ? "󰝟" : (root.volume === 0 ? "󰕿" : (root.volume < 0.5 ? "󰖀" : "󰕾"))
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    color: (sliderFill.width > 28 && !root.muted) ? Colors.colBg : Colors.colFg
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.ready ? (root.muted ? "Stumm" : Math.round(root.defaultSink.audio.volume * 100) + "%") : "--"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    font.bold: true
                    color: (sliderFill.width > sliderTrack.width - 45 && !root.muted) ? Colors.colBg : Colors.colFg
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // Drag / Click / Scroll Handler
            MouseArea {
                id: sliderMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                function updateVolume(mouseX) {
                    if (!root.ready) return;
                    let v = Math.max(0.0, Math.min(1.0, mouseX / sliderTrack.width));
                    root.defaultSink.audio.volume = v;
                    if (root.muted && v > 0) {
                        root.defaultSink.audio.muted = false;
                    }
                }

                onPressed: mouse => updateVolume(mouse.x)
                onPositionChanged: mouse => {
                    if (pressed) updateVolume(mouse.x);
                }

                onWheel: wheel => {
                    if (!root.ready) return;
                    let step = 0.02;
                    let cur = root.defaultSink.audio.volume;
                    if (wheel.angleDelta.y > 0) {
                        root.defaultSink.audio.volume = Math.min(1.0, cur + step);
                        if (root.muted) root.defaultSink.audio.muted = false;
                    } else if (wheel.angleDelta.y < 0) {
                        root.defaultSink.audio.volume = Math.max(0.0, cur - step);
                    }
                }
            }
        }

        // ── Sinks Divider ────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Colors.colHighlight
            opacity: 0.6
        }

        // ── Ausgabegeräte Section ────────────────────────────────────────────
        Text {
            text: "AUSGABEGERÄTE"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 9
            font.bold: true
            color: Colors.colSubtle
            Layout.leftMargin: 2
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            Repeater {
                model: root.availableSinks

                delegate: Rectangle {
                    id: sinkItem
                    required property var modelData
                    readonly property bool isActive: root.defaultSink && (root.defaultSink.id === modelData.id)

                    Layout.fillWidth: true
                    implicitHeight: 32
                    radius: 6
                    color: isActive ? Colors.colHighlight : (sinkMouse.containsMouse ? Colors.colBlack : "transparent")
                    border.width: isActive ? 1 : 0
                    border.color: Colors.colPine

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 10
                            rightMargin: 10
                        }
                        spacing: 8

                        Text {
                            text: root.getSinkIcon(sinkItem.modelData)
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            color: sinkItem.isActive ? Colors.colPine : Colors.colSubtle
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            text: root.getSinkCleanName(sinkItem.modelData)
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            font.bold: sinkItem.isActive
                            color: sinkItem.isActive ? Colors.colFg : Colors.colSubtle
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            text: "󰄬"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            color: Colors.colPine
                            visible: sinkItem.isActive
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    MouseArea {
                        id: sinkMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectSink(sinkItem.modelData)
                    }
                }
            }
        }
    }
}
