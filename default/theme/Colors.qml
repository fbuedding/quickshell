pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // List of available theme keys
    readonly property var availableThemes: ["rose-pine-moon", "tokyo-night", "catppuccin-mocha"]

    // Current active theme key
    property string currentTheme: "rose-pine-moon"

    readonly property string currentThemeName: active.name || currentTheme

    // Preload persisted theme from ~/.config/quickshell/current_theme
    FileView {
        id: themeFile
        path: Quickshell.env("HOME") + "/.config/quickshell/current_theme"
        onLoaded: {
            let t = themeFile.text().trim();
            if (t && root.themes.hasOwnProperty(t)) {
                root.currentTheme = t;
            }
        }
    }

    // Helper process to execute external on_theme_change hook
    Process {
        id: hookProc
    }

    // Helper process to persist theme to disk
    Process {
        id: saveProc
    }

    function setTheme(themeName) {
        if (!themes.hasOwnProperty(themeName)) return false;
        currentTheme = themeName;

        // Persist to ~/.config/quickshell/current_theme
        let path = Quickshell.env("HOME") + "/.config/quickshell/current_theme";
        saveProc.command = ["sh", "-c", "echo -n '" + themeName + "' > " + path];
        saveProc.running = true;

        // Run user hook script if available
        let hookPath = Quickshell.env("HOME") + "/.config/quickshell/on_theme_change.sh";
        let hookCmd = "if [ -x " + hookPath + " ]; then " + hookPath + " " + themeName + "; fi";
        hookProc.command = ["sh", "-c", hookCmd];
        hookProc.running = true;

        return true;
    }

    function nextTheme() {
        let idx = availableThemes.indexOf(currentTheme);
        let nextIdx = (idx + 1) % availableThemes.length;
        setTheme(availableThemes[nextIdx]);
    }

    // Theme Palettes
    readonly property var themes: ({
        "rose-pine-moon": {
            name: "Rosé Pine",
            colBg: "#232136",
            colFg: "#e0def4",
            colBlack: "#393552",
            colSurface: "#1f1d2e",
            colOverlay: "#26233a",
            colMuted: "#6e6a86",
            colSubtle: "#908caa",
            colHighlight: "#393552",
            colRed: "#eb6f92",
            colGreen: "#3e8fb0",
            colYellow: "#f6c177",
            colBlue: "#9ccfd8",
            colPurple: "#c4a7e7",
            colCyan: "#ea9a97",
            colWhite: "#e0def4",
            colBrightBlack: "#6e6a86",
            colRose: "#ea9a97",
            colLove: "#eb6f92",
            colGold: "#f6c177",
            colFoam: "#9ccfd8",
            colIris: "#c4a7e7",
            colPine: "#3e8fb0"
        },
        "tokyo-night": {
            name: "Tokyo Night",
            colBg: "#1a1b26",
            colFg: "#c0caf5",
            colBlack: "#292e42",
            colSurface: "#16161e",
            colOverlay: "#1f2335",
            colMuted: "#565f89",
            colSubtle: "#7aa2f7",
            colHighlight: "#292e42",
            colRed: "#f7768e",
            colGreen: "#9ece6a",
            colYellow: "#e0af68",
            colBlue: "#7aa2f7",
            colPurple: "#bb9af7",
            colCyan: "#7dcfff",
            colWhite: "#c0caf5",
            colBrightBlack: "#414868",
            colRose: "#7dcfff",
            colLove: "#f7768e",
            colGold: "#e0af68",
            colFoam: "#7aa2f7",
            colIris: "#bb9af7",
            colPine: "#9ece6a"
        },
        "catppuccin-mocha": {
            name: "Catppuccin",
            colBg: "#1e1e2e",
            colFg: "#cdd6f4",
            colBlack: "#313244",
            colSurface: "#181825",
            colOverlay: "#11111b",
            colMuted: "#6c7086",
            colSubtle: "#a6adc8",
            colHighlight: "#45475a",
            colRed: "#f38ba8",
            colGreen: "#a6e3a1",
            colYellow: "#f9e2af",
            colBlue: "#89b4fa",
            colPurple: "#cba6f7",
            colCyan: "#94e2d5",
            colWhite: "#cdd6f4",
            colBrightBlack: "#585b70",
            colRose: "#f5c2e7",
            colLove: "#f38ba8",
            colGold: "#f9e2af",
            colFoam: "#89dceb",
            colIris: "#cba6f7",
            colPine: "#a6e3a1"
        }
    })

    readonly property var active: themes[currentTheme] || themes["rose-pine-moon"]

    readonly property color colBg: active.colBg
    readonly property color colFg: active.colFg
    readonly property color colBlack: active.colBlack
    readonly property color colSurface: active.colSurface
    readonly property color colOverlay: active.colOverlay
    readonly property color colMuted: active.colMuted
    readonly property color colSubtle: active.colSubtle
    readonly property color colHighlight: active.colHighlight
    readonly property color colRed: active.colRed
    readonly property color colGreen: active.colGreen
    readonly property color colYellow: active.colYellow
    readonly property color colBlue: active.colBlue
    readonly property color colPurple: active.colPurple
    readonly property color colCyan: active.colCyan
    readonly property color colWhite: active.colWhite
    readonly property color colBrightBlack: active.colBrightBlack
    readonly property color colBrightRed: active.colRed
    readonly property color colBrightGreen: active.colGreen
    readonly property color colBrightYellow: active.colYellow
    readonly property color colBrightBlue: active.colBlue
    readonly property color colBrightPurple: active.colPurple
    readonly property color colBrightCyan: active.colCyan
    readonly property color colBrightWhite: active.colWhite

    // Semantic names
    readonly property color colRose: active.colRose
    readonly property color colLove: active.colLove
    readonly property color colGold: active.colGold
    readonly property color colFoam: active.colFoam
    readonly property color colIris: active.colIris
    readonly property color colPine: active.colPine
}
