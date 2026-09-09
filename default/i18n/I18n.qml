pragma Singleton
import QtQuick
import Quickshell

QtObject {
    id: root

    // Priority for language detection:
    // 1. QS_LANG environment variable (e.g. QS_LANG=en or QS_LANG=de)
    // 2. System UI language / locale (e.g. "de_DE" -> "de", "en_US" -> "en", "fr_FR" -> "fr")
    readonly property string systemLang: {
        let loc = (Qt.uiLanguage || Qt.locale().name || "en").toLowerCase();
        return loc.split("_")[0].split("-")[0];
    }

    readonly property string lang: {
        let override = Quickshell.env("QS_LANG");
        if (override && override.trim() !== "") {
            let code = override.trim().toLowerCase().split("_")[0];
            if (locales.hasOwnProperty(code)) return code;
        }
        return locales.hasOwnProperty(systemLang) ? systemLang : "en";
    }

    // Configurable time & date format string overrides
    // 1. Can be set directly on this singleton or overridden via environment variables:
    //    QS_CLOCK_FORMAT, QS_DATE_FORMAT, QS_MONTH_FORMAT
    // 2. Falls back to active language default from the locales dictionary
    property string clockFormatOverride: Quickshell.env("QS_CLOCK_FORMAT") || ""
    property string dateHeaderFormatOverride: Quickshell.env("QS_DATE_FORMAT") || ""
    property string monthHeaderFormatOverride: Quickshell.env("QS_MONTH_FORMAT") || ""

    readonly property string clockFormat: clockFormatOverride !== ""
        ? clockFormatOverride
        : t("clock_format", "HH:mm")

    readonly property string dateHeaderFormat: dateHeaderFormatOverride !== ""
        ? dateHeaderFormatOverride
        : t("date_header_format", "dddd, d. MMMM")

    readonly property string monthHeaderFormat: monthHeaderFormatOverride !== ""
        ? monthHeaderFormatOverride
        : t("month_header_format", "MMMM yyyy")

    // Format helper functions using Qt.locale(lang)
    function formatTime(dateObj, customFmt) {
        if (!dateObj) return "";
        let loc = Qt.locale(lang);
        let fmt = customFmt || clockFormat;
        try {
            return dateObj.toLocaleTimeString(loc, fmt);
        } catch (e) {
            return Qt.formatTime(dateObj, fmt);
        }
    }

    function formatDate(dateObj, customFmt) {
        if (!dateObj) return "";
        let loc = Qt.locale(lang);
        let fmt = customFmt || dateHeaderFormat;
        try {
            return dateObj.toLocaleDateString(loc, fmt);
        } catch (e) {
            return Qt.formatDate(dateObj, fmt);
        }
    }

    function formatDateTime(dateObj, customFmt) {
        if (!dateObj) return "";
        let loc = Qt.locale(lang);
        let fmt = customFmt || (dateHeaderFormat + " " + clockFormat);
        try {
            return dateObj.toLocaleDateTimeString(loc, fmt);
        } catch (e) {
            return Qt.formatDateTime(dateObj, fmt);
        }
    }

    // Translation function with automatic fallback to English
    function t(key, fallback) {
        let current = locales[lang];
        if (current && current.hasOwnProperty(key)) {
            return current[key];
        }
        let fallbackDict = locales["en"];
        if (fallbackDict && fallbackDict.hasOwnProperty(key)) {
            return fallbackDict[key];
        }
        return fallback !== undefined ? fallback : key;
    }

    // Helper for short weekday names (Monday to Sunday) using Qt.locale(lang)
    readonly property var shortWeekdays: {
        let loc = Qt.locale(lang);
        // Monday (1) to Saturday (6), then Sunday (0)
        let days = [1, 2, 3, 4, 5, 6, 0];
        return days.map(d => loc.dayName(d, Locale.ShortFormat));
    }

    // Extensible language dictionaries
    // To add a new language, simply add a new language code block below (e.g. "fr", "es", "it", "pl")
    readonly property var locales: ({
        "en": {
            // Time & Date Formats (Qt date/time syntax)
            "clock_format": "h:mm AP",
            "date_header_format": "dddd, MMMM d",
            "month_header_format": "MMMM yyyy",

            // Power Menu
            "suspend": "Suspend",
            "suspend_desc": "Suspend system to RAM",
            "lock": "Lock",
            "lock_desc": "Lock the screen",
            "logout": "Log out",
            "logout_desc": "End current session",
            "reboot": "Reboot",
            "reboot_desc": "Restart the computer",
            "shutdown": "Shut down",
            "shutdown_desc": "Turn off the computer",

            // Control Center & Notifications
            "control_center": "Control Center",
            "notifications": "Notifications",
            "no_notifications": "No notifications",
            "clear_all": "Clear all",
            "dnd": "DND",
            "bluetooth": "Bluetooth",
            "paired_devices": "PAIRED DEVICES",
            "no_paired_devices": "No paired devices",
            "audio_output": "Audio Output",
            "output_devices": "OUTPUT DEVICES",
            "mic_input": "Microphone Input",
            "no_media": "No media playing",
            "unknown_title": "Unknown Title",
            "unknown_artist": "Unknown Artist",

            // Calendar
            "today": "Today",
            "calendar_week": "CW",
            "no_events_day": "No events for this day",
            "more_events": "more events",
            "all_day": "All day",

            // App Launcher
            "search_apps": "Search applications...",
            "no_apps_found": "No apps found",
            "recent": "recent"
        },

        "de": {
            // Time & Date Formats (Qt date/time syntax)
            "clock_format": "HH:mm",
            "date_header_format": "dddd, d. MMMM",
            "month_header_format": "MMMM yyyy",

            // Power Menu
            "suspend": "Bereitschaft",
            "suspend_desc": "System in Ruhezustand versetzen",
            "lock": "Sperren",
            "lock_desc": "Bildschirm sperren",
            "logout": "Abmelden",
            "logout_desc": "Sitzung beenden",
            "reboot": "Neustart",
            "reboot_desc": "Computer neu starten",
            "shutdown": "Herunterfahren",
            "shutdown_desc": "Computer ausschalten",

            // Control Center & Notifications
            "control_center": "Kontrollzentrum",
            "notifications": "Benachrichtigungen",
            "no_notifications": "Keine Benachrichtigungen",
            "clear_all": "Löschen",
            "dnd": "DND",
            "bluetooth": "Bluetooth",
            "paired_devices": "GEPAARTE GERÄTE",
            "no_paired_devices": "Keine gepaarten Geräte",
            "audio_output": "Audio-Ausgabe",
            "output_devices": "AUSGABEGERÄTE",
            "mic_input": "Mikrofon-Eingang",
            "no_media": "Keine Medienwiedergabe",
            "unknown_title": "Unbekannter Titel",
            "unknown_artist": "Unbekannter Künstler",

            // Calendar
            "today": "Heute",
            "calendar_week": "KW",
            "no_events_day": "Keine Termine für diesen Tag",
            "more_events": "weitere Termine",
            "all_day": "Ganztägig",

            // App Launcher
            "search_apps": "Anwendungen suchen...",
            "no_apps_found": "Keine Apps gefunden",
            "recent": "Zuletzt"
        }
    })
}
