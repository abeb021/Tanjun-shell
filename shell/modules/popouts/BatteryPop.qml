import QtQuick
import "../widgets"
import "../../services"

Face {
    job: "pop"
    implicitWidth: 220
    implicitHeight: col.implicitHeight + 16
    focus: true
    Keys.onEscapePressed: ShellState.closeMenus()

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        spacing: 8

        BarText {
            text: Battery.charging ? "charging" : "battery"
            px: 12
        }
        BarText {
            text: `${Battery.percent}%`
            px: 22
            color: Battery.percent <= 15 ? Theme.critical : Theme.fg
        }
        VolumeBar {
            width: parent.width
            value: Battery.percent / 100
            fill: Battery.percent <= 15 ? Theme.critical : Theme.accent
            interactive: false
        }

        BarText {
            text: `light  ${Math.max(0, Backlight.percent)}%`
            px: 12
        }
        VolumeBar {
            width: parent.width
            value: Math.max(0, Backlight.percent) / 100
            onMoved: v => Backlight.setPercent(v * 100)
        }
    }
}
