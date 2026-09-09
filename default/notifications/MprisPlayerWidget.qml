import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../theme"
import "../i18n"

Rectangle {
    id: root
    implicitWidth: parent ? parent.width : 380
    implicitHeight: hasPlayer ? contentCol.implicitHeight + 24 : 70
    radius: Theme.cornerRadius + 2
    color: Colors.colSurface
    border.width: Theme.borderWidth
    border.color: Theme.borderColor
    clip: true

    readonly property var players: Mpris.players.values
    readonly property bool hasPlayer: players.length > 0
    property int playerIndex: 0

    readonly property var player: {
        if (!hasPlayer) return null;
        let idx = Math.min(playerIndex, players.length - 1);
        if (idx < 0) idx = 0;
        return players[idx];
    }

    // Auto-select playing player if current is stopped
    Connections {
        target: Mpris.players
        function onValuesChanged() {
            if (!hasPlayer) {
                root.playerIndex = 0;
                return;
            }
            for (let i = 0; i < players.length; i++) {
                if (players[i].playbackState === MprisPlaybackState.Playing) {
                    root.playerIndex = i;
                    break;
                }
            }
        }
    }

    // Position tracker
    property real currentPos: player ? player.position : 0
    Timer {
        interval: 1000
        running: player && player.isPlaying
        repeat: true
        onTriggered: {
            if (player) root.currentPos = player.position;
        }
    }

    Connections {
        target: player
        function onPositionChanged() {
            if (player) root.currentPos = player.position;
        }
    }

    function formatTime(totalSecs) {
        if (!totalSecs || isNaN(totalSecs) || totalSecs < 0) return "0:00";
        let m = Math.floor(totalSecs / 60);
        let s = Math.floor(totalSecs % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    // ── Empty State ─────────────────────────────────────────────────────────
    RowLayout {
        anchors.centerIn: parent
        spacing: 12
        visible: !root.hasPlayer

        Text {
            text: "󰎈"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 22
            color: Colors.colMuted
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            text: I18n.t("no_media")
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            color: Colors.colMuted
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // ── Active Player ───────────────────────────────────────────────────────
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
        visible: root.hasPlayer

        // Header: App name + player switcher if multiple
        RowLayout {
            Layout.fillWidth: true

            Rectangle {
                implicitHeight: 20
                implicitWidth: playerBadgeText.implicitWidth + 12
                radius: 10
                color: Colors.colBlack

                Text {
                    id: playerBadgeText
                    anchors.centerIn: parent
                    text: root.player ? (root.player.identity || root.player.desktopEntry || "Medien") : ""
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    font.bold: true
                    color: Colors.colRose
                }
            }

            Item { Layout.fillWidth: true }

            // Multiple players switcher
            RowLayout {
                spacing: 4
                visible: root.players.length > 1

                Repeater {
                    model: root.players.length

                    delegate: Rectangle {
                        implicitWidth: 6
                        implicitHeight: 6
                        radius: 3
                        color: index === root.playerIndex ? Colors.colRose : Colors.colMuted

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.playerIndex = index
                        }
                    }
                }
            }
        }

        // Middle: Album Art + Track Info
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Album Art
            Rectangle {
                implicitWidth: 60
                implicitHeight: 60
                radius: Theme.cornerRadius
                color: Colors.colBlack
                clip: true

                Image {
                    id: artImg
                    anchors.fill: parent
                    source: (root.player && root.player.trackArtUrl) ? root.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰎈"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 26
                    color: Colors.colSubtle
                    visible: !artImg.visible
                }
            }

            // Track Details
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    id: titleText
                    text: (root.player && root.player.trackTitle) ? root.player.trackTitle : I18n.t("unknown_title")
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    font.bold: true
                    color: Colors.colFg
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    id: artistText
                    text: (root.player && root.player.trackArtist) ? root.player.trackArtist : I18n.t("unknown_artist")
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    color: Colors.colRose
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    Layout.fillWidth: true
                    text: (root.player && root.player.trackAlbum) ? root.player.trackAlbum : ""
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    color: Colors.colMuted
                    elide: Text.ElideRight
                    visible: text !== ""
                }
            }
        }

        // Progress Bar
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            visible: root.player && root.player.lengthSupported && root.player.length > 0

            Item {
                Layout.fillWidth: true
                implicitHeight: 12

                Rectangle {
                    id: progressTrack
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    height: 4
                    radius: 2
                    color: Colors.colBlack

                    Rectangle {
                        anchors {
                            left: parent.left
                            top: parent.top
                            bottom: parent.bottom
                        }
                        width: (root.player && root.player.length > 0)
                            ? Math.min(parent.width, Math.max(0, parent.width * (root.currentPos / root.player.length)))
                            : 0
                        radius: 2
                        color: Colors.colBlue
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: (root.player && root.player.canSeek) ? Qt.PointingHandCursor : Qt.ArrowCursor
                    enabled: root.player && root.player.canSeek && root.player.length > 0

                    onClicked: mouse => {
                        let frac = Math.max(0, Math.min(1, mouse.x / width));
                        let targetSecs = frac * root.player.length;
                        root.player.position = targetSecs;
                        root.currentPos = targetSecs;
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: root.formatTime(root.currentPos)
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    color: Colors.colMuted
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.formatTime(root.player ? root.player.length : 0)
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    color: Colors.colMuted
                }
            }
        }

        // Controls
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 16

            // Shuffle
            Text {
                text: "󰒟"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                color: (root.player && root.player.shuffle) ? Colors.colRose : Colors.colMuted
                visible: root.player && root.player.shuffleSupported
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.player.shuffle = !root.player.shuffle
                }
            }

            // Previous
            Text {
                text: "󰒮"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 18
                color: (root.player && root.player.canGoPrevious) ? Colors.colFg : Colors.colMuted
                MouseArea {
                    anchors.fill: parent
                    cursorShape: (root.player && root.player.canGoPrevious) ? Qt.PointingHandCursor : Qt.ArrowCursor
                    enabled: root.player && root.player.canGoPrevious
                    onClicked: root.player.previous()
                }
            }

            // Play / Pause Button
            Rectangle {
                implicitWidth: 36
                implicitHeight: 36
                radius: 18
                color: Colors.colRose

                Text {
                    anchors.centerIn: parent
                    text: (root.player && root.player.isPlaying) ? "󰏤" : "󰐊"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 18
                    color: Colors.colBg
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.player) root.player.togglePlaying();
                    }
                }
            }

            // Next
            Text {
                text: "󰒭"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 18
                color: (root.player && root.player.canGoNext) ? Colors.colFg : Colors.colMuted
                MouseArea {
                    anchors.fill: parent
                    cursorShape: (root.player && root.player.canGoNext) ? Qt.PointingHandCursor : Qt.ArrowCursor
                    enabled: root.player && root.player.canGoNext
                    onClicked: root.player.next()
                }
            }

            // Loop
            Text {
                text: (root.player && root.player.loopState === MprisLoopState.Track) ? "󰑘" : "󰑖"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                color: (root.player && root.player.loopState !== MprisLoopState.None) ? Colors.colRose : Colors.colMuted
                visible: root.player && root.player.loopSupported
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!root.player) return;
                        if (root.player.loopState === MprisLoopState.None) {
                            root.player.loopState = MprisLoopState.Playlist;
                        } else if (root.player.loopState === MprisLoopState.Playlist) {
                            root.player.loopState = MprisLoopState.Track;
                        } else {
                            root.player.loopState = MprisLoopState.None;
                        }
                    }
                }
            }
        }
    }
}
