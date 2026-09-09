pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland

Singleton {
    id: root

    // Returns true only when a window is in true fullscreen mode on targetScreen.
    // Maximized windows (which keep the topbar and desktop borders) return false.
    function isFullscreen(targetScreen): bool {
        let list = ToplevelManager.toplevels.values;
        for (let i = 0; i < list.length; i++) {
            let t = list[i];
            if (t && t.fullscreen) {
                if (!targetScreen || t.screens.indexOf(targetScreen) !== -1 || t.screens.length === 0) {
                    return true;
                }
            }
        }
        return false;
    }
}
