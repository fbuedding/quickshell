import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../theme"

ColumnLayout {
    id: root
    spacing: 8
    property string fontFamily: "JetBrainsMono Nerd Font"
    property int fontSize: 12
    property real cpuUsage: 0
    property real ramUsage: 0
    property int cpuTemp: 0

    Process {
        id: sysInfoProc
        command: ["bash", "-c",
            "read -r _ u1 n1 s1 i1 w1 ir1 soft1 st1 _ < /proc/stat; " +
            "sleep 0.5; " +
            "read -r _ u2 n2 s2 i2 w2 ir2 soft2 st2 _ < /proc/stat; " +
            "tot1=$((u1+n1+s1+i1+w1+ir1+soft1+st1)); tot2=$((u2+n2+s2+i2+w2+ir2+soft2+st2)); " +
            "idle1=$((i1+w1)); idle2=$((i2+w2)); " +
            "cpu=$(awk -v t1=$tot1 -v t2=$tot2 -v i1=$idle1 -v i2=$idle2 'BEGIN { dt=t2-t1; didle=i2-i1; print (dt>0) ? sprintf(\"%.0f\", 100*(dt-didle)/dt) : 0 }'); " +
            "mem=$(awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{if(t>0) printf \"%.0f\", (t-a)/t*100; else print 0}' /proc/meminfo); " +
            "temp=$(sensors 2>/dev/null | awk -F'[:+°]' '/(Package id 0|Tctl|CPU|temp1)/ {for(i=1;i<=NF;i++) if($i ~ /^[0-9]+(\\.[0-9]+)?$/) {print int($i); exit}}'); " +
            "if [ -z \"$temp\" ]; then for t in /sys/class/thermal/thermal_zone*/temp; do [ -f \"$t\" ] && temp=$(($(cat \"$t\")/1000)) && break; done; fi; " +
            "echo \"$cpu $mem ${temp:-0}\""
        ]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(/\s+/);
                if (parts.length >= 3) {
                    root.cpuUsage = parseInt(parts[0]) || 0;
                    root.ramUsage = parseInt(parts[1]) || 0;
                    root.cpuTemp = parseInt(parts[2]) || 0;
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: sysInfoProc.running = true
    }

    // CPU
    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 0
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "󰘚"
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            color: Colors.colFg
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.cpuUsage + "%"
            font.family: root.fontFamily
            font.pixelSize: root.fontSize - 1
            color: Colors.colFg
        }
    }

    Separator {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
    }

    // RAM
    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 0
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "󰍛"
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            color: Colors.colFg
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.ramUsage + "%"
            font.family: root.fontFamily
            font.pixelSize: root.fontSize - 1
            color: Colors.colFg
        }
    }

    Separator {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
    }

    // Temp
    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 0
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "\uf2c9"
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            color: root.cpuTemp >= 80 ? Colors.colRed : Colors.colFg
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.cpuTemp + "°"
            font.family: root.fontFamily
            font.pixelSize: root.fontSize - 1
            color: root.cpuTemp >= 80 ? Colors.colRed : Colors.colFg
        }
    }
}

