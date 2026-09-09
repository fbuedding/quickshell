//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import "./app_launcher"
import "./bar"
import "./calendar"
import "./notifications"
import "./power_menu"
import "./osd"
import "./tray"
import "./theme"

ShellRoot {
    Bar {}
    Border {}

    IpcHandler {
        target: "theme"
        function set(name: string) {
            Colors.setTheme(name);
        }
        function next() {
            Colors.nextTheme();
        }
        function current(): string {
            return Colors.currentTheme;
        }
        function list(): string {
            return Colors.availableThemes.join(", ");
        }
    }
    Variants {
	model: Quickshell.screens
	TrayMenu {
	    property var modelData
	    screen: modelData
	}
    }
    Variants {
	model: Quickshell.screens
	AppLauncher {
	    property var modelData
	    screen: modelData
	}
    }
    Variants {
	model: Quickshell.screens
	PowerMenu {
	    property var modelData
	    screen: modelData
	}
    }
    Variants {
	model: Quickshell.screens
	CalendarDropdown {
	    property var modelData
	    screen: modelData
	}
    }
    Variants {
	model: Quickshell.screens
	NotificationPanel {
	    property var modelData
	    screen: modelData
	}
    }
    Variants {
	model: Quickshell.screens
	NotificationPopup {
	    property var modelData
	    screen: modelData
	}
    }
    Variants {
	model: Quickshell.screens
	VolumeOsd {
	    property var modelData
	    screen: modelData
	}
    }
}
