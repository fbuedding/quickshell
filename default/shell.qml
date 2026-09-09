import QtQuick
import Quickshell
import "./app_launcher"
import "./bar"
import "./calendar"
import "./notifications"
import "./power_menu"
import "./osd"

ShellRoot {
    Bar {}
    Border {}
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
