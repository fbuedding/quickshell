import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import "../theme"
import "../notifications"

Item {
    id: volumeRoot
    implicitWidth: rowLayout.implicitWidth + 14
    implicitHeight: 26
    Layout.alignment: Qt.AlignVCenter

    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 12

    property var sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink && sink.ready
    readonly property bool muted: ready && sink.audio.muted
    readonly property int vol: ready ? Math.round(sink.audio.volume * 100) : 0

    readonly property string icon: {
        if (!ready)
            return String.fromCodePoint(0xF0581);
        if (muted)
            return "\udb81\udd81";
        if (vol === 0)
            return String.fromCodePoint(0xF0581);
        if (vol < 34)
            return String.fromCodePoint(0xF057F);
        if (vol < 67)
            return String.fromCodePoint(0xF0580);
        return String.fromCodePoint(0xF057E);
    }

    function cycleSink() {
        if (!Pipewire.ready) return;
        let sinks = [];
        for (let n of Pipewire.nodes.values) {
            if (n.isSink && !n.isStream && !n.name.endsWith(".monitor") && !n.description.includes("Easy Effects")) {
                sinks.push(n);
            }
        }
        if (sinks.length <= 1) return;
        let curId = volumeRoot.sink ? volumeRoot.sink.id : -1;
        let idx = -1;
        for (let i = 0; i < sinks.length; i++) {
            if (sinks[i].id === curId) {
                idx = i;
                break;
            }
        }
        let nextIdx = (idx + 1) % sinks.length;
        let target = sinks[nextIdx];
        Pipewire.preferredDefaultAudioSink = target;
        Quickshell.execDetached([
            "sh", "-c",
            "pactl set-default-sink " + target.name + " 2>/dev/null; " +
            "for id in $(pactl list short sink-inputs 2>/dev/null | cut -f1); do pactl move-sink-input $id " + target.name + " 2>/dev/null; done"
        ]);
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: (volumeMouseArea.containsMouse || NotificationState.panelVisible) ? Colors.colBlack : "transparent"

        RowLayout {
            id: rowLayout
            anchors.centerIn: parent
            spacing: 5

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: volumeRoot.icon
                color: volumeRoot.muted ? Colors.colCyan : Colors.colBlue
                font {
                    family: volumeRoot.fontFamily
                    pixelSize: volumeRoot.fontSize + 1
                }
            }

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: {
                    if (!volumeRoot.ready)
                        return "--";
                    if (volumeRoot.muted)
                        return "muted";
                    return volumeRoot.vol + "%";
                }
                color: volumeRoot.muted ? Colors.colCyan : Colors.colFg
                font {
                    family: volumeRoot.fontFamily
                    pixelSize: volumeRoot.fontSize
                }
            }
        }
    }

    MouseArea {
        id: volumeMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onWheel: wheel => {
            if (!volumeRoot.ready)
                return;
            let step = 0.02;
            let currentVol = volumeRoot.sink.audio.volume;
            if (wheel.angleDelta.y > 0) {
                volumeRoot.sink.audio.volume = Math.min(1.0, currentVol + step);
                if (volumeRoot.muted) volumeRoot.sink.audio.muted = false;
            } else if (wheel.angleDelta.y < 0) {
                volumeRoot.sink.audio.volume = Math.max(0.0, currentVol - step);
            }
        }

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                NotificationState.togglePanel();
            } else if (mouse.button === Qt.RightButton) {
                if (volumeRoot.ready) {
                    volumeRoot.sink.audio.muted = !volumeRoot.sink.audio.muted;
                }
            } else if (mouse.button === Qt.MiddleButton) {
                volumeRoot.cycleSink();
            }
        }
    }

    PwObjectTracker {
        id: audioTracker
        objects: [volumeRoot.sink]
    }
}
