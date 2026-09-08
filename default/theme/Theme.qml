pragma Singleton
import QtQuick

QtObject {
    // Matches Hyprland decoration.rounding
    readonly property int rounding: 5
    readonly property int cornerRadius: rounding

    readonly property int borderThickness: 12
    readonly property int barHeight: 34

    // Inner shell border
    readonly property int borderWidth: 1
    readonly property color borderColor: Colors.colBlack
}
