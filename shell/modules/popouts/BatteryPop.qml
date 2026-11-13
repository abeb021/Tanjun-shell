import QtQuick
import "../widgets"
import "../../services"

Face {
    id: root
    job: "pop"
    attach: true
    implicitWidth: 240
    implicitHeight: col.implicitHeight + 24
    focus: true
    Keys.onEscapePressed: UiMode.closeMenus()

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 10

        PopHead {
            title: "BATTERY"
            status: Battery.charging ? "CHARGING" : "ON BATTERY"
        }

        Row {
            spacing: 8
            BarText {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰁹"
                icon: true
                px: 18
                color: Battery.percent <= 15 ? Theme.critical : Theme.accent
            }
            BarText {
                anchors.verticalCenter: parent.verticalCenter
                text: `${Battery.percent}%`
                px: 26
                family: Config.defaultFontUi
                color: Battery.percent <= 15 ? Theme.critical : Theme.fg
            }
        }

        VolumeBar {
            width: parent.width
            thumb: true
            value: Battery.percent / 100
            fill: Battery.percent <= 15 ? Theme.critical : Theme.accent
            interactive: false
        }

        PopHead {
            title: "DISPLAY"
            status: `${Math.max(0, Backlight.percent)}%`
        }

        VolumeBar {
            width: parent.width
            thumb: true
            value: Math.max(0, Backlight.percent) / 100
            onMoved: v => Backlight.setPercent(v * 100)
        }
    }
}
