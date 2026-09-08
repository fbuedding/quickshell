import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import "../theme"

Item {
    id: volumeRoot
    implicitWidth: rowLayout.implicitWidth
    implicitHeight: rowLayout.implicitHeight
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
            } else if (wheel.angleDelta.y < 0) {
                volumeRoot.sink.audio.volume = Math.max(0.0, currentVol - step);
            }
        }

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                Quickshell.execDetached(["pwvucontrol"]);
            } else if (mouse.button === Qt.RightButton) {
                if (volumeRoot.ready) {
                    volumeRoot.sink.audio.muted = !volumeRoot.sink.audio.muted;
                }
            } else if (mouse.button === Qt.MiddleButton) {
                Quickshell.execDetached(["python3", Quickshell.env("HOME") + "/.config/quickshell/default/scripts/cycle_audio.py"]);
            }
        }
    }

    PwObjectTracker {
        id: audioTracker
        objects: [volumeRoot.sink]
    }
}
