import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland
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
        target: "calendar"
        function toggle() { CalendarState.toggle(); }
        function open() { CalendarState.show(); }
        function close() { CalendarState.hide(); }
        function next() { CalendarState.nextMonth(); }
        function prev() { CalendarState.prevMonth(); }
        function today() { CalendarState.goToToday(); }
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: CalendarState.dropdownVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-calendar"

    exclusionMode: root.isFullscreen ? ExclusionMode.Ignore : ExclusionMode.Normal

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    mask: Region {
        item: CalendarState.dropdownVisible ? maskCover : null
    }

    Item {
        id: maskCover
        anchors.fill: parent
    }

    // Click outside to close
    MouseArea {
        anchors.fill: parent
        enabled: CalendarState.dropdownVisible
        onClicked: CalendarState.hide()
    }

    // Escape key to close
    FocusScope {
        anchors.fill: parent
        focus: CalendarState.dropdownVisible
        Keys.onEscapePressed: CalendarState.hide()
    }

    // ── Morphing Side Panel ──────────────────────────────────────────────────
    Rectangle {
        id: panel
        anchors {
            top: parent.top
            topMargin: root.isFullscreen ? 12 : 0
            right: parent.right
            rightMargin: root.isFullscreen ? 12 : 0
        }
        width: 390
        height: contentCol.implicitHeight + 24

        // Seamless connection with topbar and right screen edge in normal mode,
        // or fully rounded floating card in fullscreen mode
        color: Colors.colBg
        topRightRadius: root.isFullscreen ? 12 : 0
        topLeftRadius: root.isFullscreen ? 12 : 0
        bottomRightRadius: root.isFullscreen ? 12 : 0
        bottomLeftRadius: root.isFullscreen ? 12 : Theme.cornerRadius
        border.width: root.isFullscreen ? Theme.borderWidth : 0
        border.color: Theme.borderColor

        clip: true

        // Slide from right to left (mirrored to PowerMenu)
        property real slideX: CalendarState.dropdownVisible ? 0 : (width + anchors.rightMargin + Theme.cornerRadius + 10)
        Behavior on slideX {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }
        transform: Translate { x: panel.slideX }

        // Prevent clicks inside panel from closing dropdown
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: contentCol
            anchors {
                top: parent.top
                topMargin: 12
                left: parent.left
                leftMargin: 16
                right: parent.right
                rightMargin: 16
            }
            spacing: 12

            // ── Header (Month + Year + Action Controls) ──────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: CalendarState.monthName(CalendarState.viewMonth) + " " + CalendarState.viewYear
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 15
                    font.bold: true
                    color: Colors.colFg
                    Layout.fillWidth: true
                }

                // "Heute" Pill Button
                Rectangle {
                    implicitWidth: heuteText.implicitWidth + 14
                    implicitHeight: 24
                    radius: 12
                    color: heuteMouse.containsMouse ? Colors.colHighlight : Colors.colBlack

                    Text {
                        id: heuteText
                        anchors.centerIn: parent
                        text: I18n.t("today")
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.bold: true
                        color: Colors.colFg
                    }

                    MouseArea {
                        id: heuteMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: CalendarState.goToToday()
                    }
                }

                // Prev Month Button
                Rectangle {
                    implicitWidth: 24
                    implicitHeight: 24
                    radius: 12
                    color: prevMouse.containsMouse ? Colors.colHighlight : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰅁"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        color: prevMouse.containsMouse ? Colors.colFg : Colors.colSubtle
                    }

                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: CalendarState.prevMonth()
                    }
                }

                // Next Month Button
                Rectangle {
                    implicitWidth: 24
                    implicitHeight: 24
                    radius: 12
                    color: nextMouse.containsMouse ? Colors.colHighlight : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰅂"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        color: nextMouse.containsMouse ? Colors.colFg : Colors.colSubtle
                    }

                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: CalendarState.nextMonth()
                    }
                }

                // Refresh Button
                Rectangle {
                    implicitWidth: 24
                    implicitHeight: 24
                    radius: 12
                    color: refMouse.containsMouse ? Colors.colHighlight : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰑐"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        color: CalendarState.isRefreshing ? Colors.colRose : (refMouse.containsMouse ? Colors.colFg : Colors.colMuted)
                    }

                    MouseArea {
                        id: refMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: CalendarState.refresh()
                    }
                }

                // Thunderbird Launch Button
                Rectangle {
                    implicitWidth: 24
                    implicitHeight: 24
                    radius: 12
                    color: tbMouse.containsMouse ? Colors.colHighlight : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "󰇮"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        color: tbMouse.containsMouse ? Colors.colBlue : Colors.colMuted
                    }

                    MouseArea {
                        id: tbMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(["thunderbird"]);
                            CalendarState.hide();
                        }
                    }
                }
            }

            // ── Weekday Headers + KW Header ──────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    Layout.preferredWidth: 24
                    horizontalAlignment: Text.AlignHCenter
                    text: I18n.t("calendar_week")
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    font.bold: true
                    color: Colors.colMuted
                }

                Repeater {
                    model: I18n.shortWeekdays
                    delegate: Text {
                        required property string modelData
                        required property int index
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.bold: true
                        color: (index >= 5) ? Colors.colSubtle : Colors.colFg
                    }
                }
            }

            // ── 6 Rows of Month Grid ─────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Repeater {
                    model: 6 // 6 weeks

                    delegate: RowLayout {
                        id: weekRow
                        required property int index
                        Layout.fillWidth: true
                        spacing: 3

                        // Calendar Week Number (KW)
                        Text {
                            Layout.preferredWidth: 24
                            horizontalAlignment: Text.AlignHCenter
                            text: {
                                let cell = CalendarState.monthGrid[weekRow.index * 7];
                                return (cell && cell.calendarWeek > 0) ? cell.calendarWeek.toString() : "";
                            }
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            color: Colors.colMuted
                        }

                        // 7 Days
                        Repeater {
                            model: 7

                            delegate: Rectangle {
                                id: dayCell
                                required property int index
                                property int cellIdx: weekRow.index * 7 + index
                                property var cellData: (CalendarState.monthGrid && cellIdx < CalendarState.monthGrid.length) ? CalendarState.monthGrid[cellIdx] : null
                                property bool isToday: Boolean(cellData && cellData.date && cellData.date.toDateString() === CalendarState.currentDate.toDateString())
                                property bool isSelected: Boolean(cellData && cellData.date && cellData.date.toDateString() === CalendarState.selectedDate.toDateString())
                                property bool hasEvents: Boolean(cellData && CalendarState.hasEvents(cellData.date))
                                property var eventDots: (cellData && hasEvents) ? CalendarState.eventColorsForDate(cellData.date) : []

                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                implicitHeight: 30
                                radius: 6

                                color: {
                                    if (!cellData) return "transparent";
                                    if (isSelected) return Colors.colHighlight;
                                    if (isToday) return Colors.colBlack;
                                    if (cellMouse.containsMouse) return Qt.rgba(1, 1, 1, 0.05);
                                    return "transparent";
                                }

                                border.width: (isToday && !isSelected) ? 1 : (isSelected ? 1 : 0)
                                border.color: isSelected ? Colors.colRose : Colors.colBlue

                                Text {
                                    anchors.centerIn: parent
                                    anchors.verticalCenterOffset: dayCell.hasEvents ? -3 : 0
                                    text: dayCell.cellData ? dayCell.cellData.dayNumber.toString() : ""
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    font.bold: Boolean(dayCell.isToday || dayCell.isSelected)
                                    color: {
                                        if (!dayCell.cellData) return Colors.colFg;
                                        if (!dayCell.cellData.isCurrentMonth) return Qt.rgba(0.57, 0.55, 0.67, 0.35);
                                        if (dayCell.isSelected) return Colors.colRose;
                                        if (dayCell.isToday) return Colors.colBlue;
                                        return Colors.colFg;
                                    }
                                }

                                // Appointment Dots
                                Row {
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 3
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 2
                                    visible: dayCell.hasEvents

                                    Repeater {
                                        model: dayCell.eventDots
                                        delegate: Rectangle {
                                            required property var modelData
                                            width: 4
                                            height: 4
                                            radius: 2
                                            color: modelData
                                        }
                                    }
                                }

                                MouseArea {
                                    id: cellMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (dayCell.cellData) {
                                            CalendarState.selectDate(dayCell.cellData.date);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Divider Line ─────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.borderColor
            }

            // ── Agenda / Termine für ausgewählten Tag ────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: CalendarState.formatSelectedDateHeader()
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        font.bold: true
                        color: Colors.colRose
                        Layout.fillWidth: true
                    }

                    Text {
                        property var evList: CalendarState.eventsForDate(CalendarState.selectedDate)
                        text: evList.length + (evList.length === 1 ? " Termin" : " Termine")
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        color: Colors.colMuted
                        visible: evList.length > 0
                    }
                }

                // Empty State
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    Layout.bottomMargin: 2
                    spacing: 8
                    visible: CalendarState.eventsForDate(CalendarState.selectedDate).length === 0

                    Text {
                        text: "󰃭"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        color: Colors.colMuted
                    }

                    Text {
                        text: I18n.t("no_events_day")
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        color: Colors.colMuted
                    }
                }

                // Events List
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: CalendarState.eventsForDate(CalendarState.selectedDate).length > 0

                    Repeater {
                        model: CalendarState.eventsForDate(CalendarState.selectedDate).slice(0, 5)

                        delegate: Rectangle {
                            id: eventCard
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: evRow.implicitHeight + 12
                            radius: 6
                            color: Colors.colSurface
                            border.width: 1
                            border.color: Theme.borderColor

                            RowLayout {
                                id: evRow
                                anchors {
                                    fill: parent
                                    leftMargin: 8
                                    rightMargin: 10
                                    topMargin: 6
                                    bottomMargin: 6
                                }
                                spacing: 8

                                // Color strip indicator
                                Rectangle {
                                    Layout.preferredWidth: 3
                                    Layout.fillHeight: true
                                    radius: 1.5
                                    color: eventCard.modelData.color || Colors.colBlue
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    RowLayout {
                                        Layout.fillWidth: true

                                        Text {
                                            text: (eventCard.modelData.allDay || eventCard.modelData.time === "Ganztägig") ? I18n.t("all_day") : (eventCard.modelData.time || "")
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: eventCard.modelData.color || Colors.colBlue
                                        }

                                        Item { Layout.fillWidth: true }

                                        // Calendar Name Badge
                                        Rectangle {
                                            implicitHeight: 16
                                            implicitWidth: calBadge.implicitWidth + 8
                                            radius: 4
                                            color: Colors.colBlack

                                            Text {
                                                id: calBadge
                                                anchors.centerIn: parent
                                                text: eventCard.modelData.calendar || ""
                                                font.family: "JetBrainsMono Nerd Font"
                                                font.pixelSize: 9
                                                color: Colors.colFg
                                            }
                                        }
                                    }

                                    Text {
                                        text: eventCard.modelData.title || ""
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: Colors.colFg
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        property int extraCount: CalendarState.eventsForDate(CalendarState.selectedDate).length - 5
                        visible: extraCount > 0
                        text: "+ " + extraCount + " " + I18n.t("more_events")
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        font.italic: true
                        color: Colors.colSubtle
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // ── Footer / Calendar Legend ─────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 2
                spacing: 8

                Row {
                    spacing: 6
                    Layout.alignment: Qt.AlignVCenter
                    Repeater {
                        model: CalendarState.calendars
                        delegate: Row {
                            required property var modelData
                            spacing: 4
                            visible: Boolean(modelData && (modelData.hasUrl || modelData.name === "Feiertage"))
                            Rectangle {
                                width: 6
                                height: 6
                                radius: 3
                                color: modelData.color
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: modelData.name
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 9
                                color: Colors.colMuted
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: CalendarState.lastUpdated ? ("Stand: " + CalendarState.lastUpdated.split(" ")[1]) : ""
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 9
                    color: Colors.colSubtle
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }

    // ── Top-left concave curve — seamless connection with topbar ─────────────
    ConcaveCurves {
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
        transform: Translate { x: panel.slideX }
        visible: !root.isFullscreen
    }

    // ── Bottom-right concave curve — seamless connection with right border ───
    ConcaveCurves {
        width: Theme.cornerRadius
        height: Theme.cornerRadius
        radius: Theme.cornerRadius
        color: Colors.colBg
        isTop: true
        mirrored: true
        borderWidth: Theme.borderWidth
        borderColor: Theme.borderColor
        anchors.top: panel.bottom
        anchors.right: panel.right
        transform: Translate { x: panel.slideX }
        visible: !root.isFullscreen
    }

    // ── Panel border contour (left edge, rounded bottom-left, bottom edge) ───
    Shape {
        anchors.fill: panel
        transform: Translate { x: panel.slideX }
        preferredRendererType: Shape.CurveRenderer
        visible: !root.isFullscreen

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
        }
    }
}
