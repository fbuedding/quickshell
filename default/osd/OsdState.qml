pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    property bool visible: false
    property var sink: Pipewire.defaultAudioSink
    readonly property bool sinkReady: sink && sink.ready && sink.audio
    readonly property bool muted: sinkReady ? sink.audio.muted : false
    readonly property int volume: sinkReady ? Math.round(sink.audio.volume * 100) : 0

    readonly property string icon: {
        if (!sinkReady)
            return String.fromCodePoint(0xF0581);
        if (muted)
            return "\udb81\udd81";
        if (volume === 0)
            return String.fromCodePoint(0xF0581);
        if (volume < 34)
            return String.fromCodePoint(0xF057F);
        if (volume < 67)
            return String.fromCodePoint(0xF0580);
        return String.fromCodePoint(0xF057E);
    }

    property bool readyForEvents: false
    property int lastVol: -1
    property int lastMuted: -1

    Timer {
        id: hideTimer
        interval: 1500
        repeat: false
        onTriggered: root.visible = false
    }

    Timer {
        id: initTimer
        interval: 1200
        running: true
        repeat: false
        onTriggered: {
            if (sinkReady) {
                lastVol = root.volume;
                lastMuted = root.muted ? 1 : 0;
            }
            readyForEvents = true;
        }
    }

    onVolumeChanged: {
        if (!readyForEvents) {
            lastVol = volume;
            return;
        }
        if (volume !== lastVol) {
            lastVol = volume;
            show();
        }
    }

    onMutedChanged: {
        if (!readyForEvents) {
            lastMuted = muted ? 1 : 0;
            return;
        }
        let m = muted ? 1 : 0;
        if (m !== lastMuted) {
            lastMuted = m;
            show();
        }
    }

    function show() {
        hideTimer.restart();
        root.visible = true;
    }

    function hide() {
        hideTimer.stop();
        root.visible = false;
    }

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }
}
