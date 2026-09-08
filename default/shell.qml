import QtQuick
import Quickshell
import "./app_launcher"
import "./bar"
import "./power_menu"

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
}
