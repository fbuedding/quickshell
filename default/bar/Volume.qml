import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts
import "../theme"

Item {
    id: volumeRoot
    implicitWidth: 25
    implicitHeight: layout.implicitHeight

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

    ColumnLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 0

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: volumeRoot.icon
            color: volumeRoot.muted ? Colors.colCyan : Colors.colFg
            font {
                family: volumeRoot.fontFamily
                pixelSize: volumeRoot.fontSize
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: {
                if (!volumeRoot.ready)
                    return "_";
                if (volumeRoot.muted)
                    return "mut";
                return volumeRoot.vol + "%";
            }
            color: volumeRoot.muted ? Colors.colCyan : Colors.colFg
            font {
                family: volumeRoot.fontFamily
                pixelSize: volumeRoot.fontSize - 1
            }
        }
    }

    MouseArea {
        id: volumeMouseArea
        anchors.fill: parent
        focus: false

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

        onClicked: {
            if (volumeRoot.ready) {
                volumeRoot.sink.audio.muted = !volumeRoot.sink.audio.muted;
            }
        }
    }

    PwObjectTracker {
        id: audioTracker
        objects: [volumeRoot.sink]
    }
}
