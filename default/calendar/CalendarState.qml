pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../notifications"

Singleton {
    id: root

    property bool dropdownVisible: false

    property var currentDate: new Date()
    property var selectedDate: new Date()
    property int viewYear: currentDate.getFullYear()
    property int viewMonth: currentDate.getMonth() // 0 - 11

    property var eventsByDate: ({})
    property var calendars: []
    property string lastUpdated: ""
    property bool isRefreshing: false

    // Update current date every minute
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            root.currentDate = new Date();
        }
    }

    // Preload cached events on startup
    FileView {
        id: cachedFile
        path: Quickshell.env("HOME") + "/.cache/quickshell/calendar/events.json"
        onLoaded: {
            let str = cachedFile.text();
            if (str && str.trim() !== "") {
                try {
                    let data = JSON.parse(str);
                    root.eventsByDate = data.events || {};
                    root.calendars = data.calendars || [];
                    root.lastUpdated = data.lastUpdated || "";
                } catch (e) {
                    console.warn("CalendarState cache load error:", e);
                }
            }
        }
    }

    // Process to fetch calendar events in the background
    Process {
        id: fetchProc
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/default/scripts/fetch_calendar.py"]
        stdout: StdioCollector {
            id: collector
            waitForEnd: true
            onStreamFinished: {
                root.isRefreshing = false;
                let out = collector.text;
                if (!out || out.trim() === "") return;
                try {
                    let data = JSON.parse(out);
                    root.eventsByDate = data.events || {};
                    root.calendars = data.calendars || [];
                    root.lastUpdated = data.lastUpdated || "";
                } catch (e) {
                    console.warn("CalendarState JSON parse error:", e);
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            root.isRefreshing = false;
        }
    }

    // Auto-refresh every 15 minutes
    Timer {
        id: refreshTimer
        interval: 900000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    function toggle() {
        dropdownVisible = !dropdownVisible;
        if (dropdownVisible) {
            NotificationState.hidePanel();
            refresh();
        }
    }

    function show() {
        dropdownVisible = true;
        NotificationState.hidePanel();
        refresh();
    }

    function hide() {
        dropdownVisible = false;
    }

    function refresh() {
        if (!fetchProc.running) {
            isRefreshing = true;
            fetchProc.running = true;
        }
    }

    function prevMonth() {
        if (viewMonth === 0) {
            viewMonth = 11;
            viewYear--;
        } else {
            viewMonth--;
        }
    }

    function nextMonth() {
        if (viewMonth === 11) {
            viewMonth = 0;
            viewYear++;
        } else {
            viewMonth++;
        }
    }

    function goToToday() {
        currentDate = new Date();
        viewYear = currentDate.getFullYear();
        viewMonth = currentDate.getMonth();
        selectedDate = new Date();
    }

    function selectDate(d) {
        selectedDate = d;
        if (d.getMonth() !== viewMonth) {
            viewMonth = d.getMonth();
            viewYear = d.getFullYear();
        }
    }

    function formatDateKey(d) {
        if (!d) return "";
        let y = d.getFullYear();
        let m = String(d.getMonth() + 1).padStart(2, '0');
        let day = String(d.getDate()).padStart(2, '0');
        return y + "-" + m + "-" + day;
    }

    function eventsForDate(d) {
        if (!d) return [];
        let key = formatDateKey(d);
        return (eventsByDate && eventsByDate[key]) ? eventsByDate[key] : [];
    }

    function hasEvents(d) {
        return eventsForDate(d).length > 0;
    }

    function eventColorsForDate(d) {
        let evs = eventsForDate(d);
        let colors = [];
        for (let i = 0; i < evs.length; i++) {
            let col = evs[i].color || "#9ccfd8";
            if (colors.indexOf(col) === -1) {
                colors.push(col);
            }
            if (colors.length >= 3) break;
        }
        return colors;
    }

    function monthName(m) {
        const names = [
            "Januar", "Februar", "März", "April", "Mai", "Juni",
            "Juli", "August", "September", "Oktober", "November", "Dezember"
        ];
        return names[m] || "";
    }

    function formatSelectedDateHeader() {
        const days = ["Sonntag", "Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag"];
        let dayName = days[selectedDate.getDay()];
        let dayNum = selectedDate.getDate();
        let mName = monthName(selectedDate.getMonth());
        return dayName + ", " + dayNum + ". " + mName;
    }

    function getWeekNumber(d) {
        let target = new Date(d.valueOf());
        let dayNr = (d.getDay() + 6) % 7; // Monday = 0
        target.setDate(target.getDate() - dayNr + 3);
        let firstThursday = target.valueOf();
        target.setMonth(0, 1);
        if (target.getDay() !== 4) {
            target.setMonth(0, 1 + ((4 - target.getDay()) + 7) % 7);
        }
        return 1 + Math.ceil((firstThursday - target) / 604800000);
    }

    readonly property var monthGrid: {
        let cells = [];
        let firstDay = new Date(viewYear, viewMonth, 1);
        let startOffset = (firstDay.getDay() + 6) % 7; // Monday = 0
        let startDate = new Date(viewYear, viewMonth, 1 - startOffset);

        for (let i = 0; i < 42; i++) {
            let d = new Date(startDate.getFullYear(), startDate.getMonth(), startDate.getDate() + i);
            let isCurrentMonth = d.getMonth() === viewMonth;
            let kw = (i % 7 === 0) ? getWeekNumber(d) : 0;
            cells.push({
                date: d,
                dayNumber: d.getDate(),
                isCurrentMonth: isCurrentMonth,
                calendarWeek: kw,
                index: i
            });
        }
        return cells;
    }
}
