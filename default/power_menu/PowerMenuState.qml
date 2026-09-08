pragma Singleton
import QtQuick

QtObject {
    id: root

    property bool menuVisible: false

    function toggle() { menuVisible = !menuVisible }
    function show()   { menuVisible = true }
    function hide()   { menuVisible = false }
}
