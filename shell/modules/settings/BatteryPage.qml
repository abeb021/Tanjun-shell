import QtQuick
import "../widgets"
import "../../services"

Column {
    width: parent.width
    spacing: 20

    Column {
        visible: Battery.ready
        width: parent.width
        spacing: 8
        BarText {
            text: "BATTERY"
            role: "head"
        }
        BarText {
            text: Battery.percent + "%" + (Battery.charging ? "  ·  CHARGING" : "")
            px: 18
            family: Config.defaultFontUi
        }
    }

    Column {
        width: parent.width
        spacing: 10
        BarText {
            text: "IDLE"
            role: "head"
        }
        Repeater {
            model: [
                { key: "dim", label: "DIM", value: Idle.dimMin, step: 1 },
                { key: "lock", label: "LOCK", value: Idle.lockMin, step: 1 },
                { key: "dpms", label: "SCREEN OFF", value: Idle.dpmsMin, step: 1 },
                { key: "sleep", label: "SLEEP", value: Idle.sleepMin, step: 5 },
                { key: "hibernate", label: "HIBERNATE", value: Idle.hibernateMin, step: 5 }
            ]
            Row {
                required property var modelData
                width: parent.width
                spacing: 10
                BarText {
                    width: 110
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.label
                    px: 12
                    family: Config.defaultFontUi
                    font.letterSpacing: 1
                }
                HudPick {
                    width: 42
                    label: "−"
                    onClicked: Idle.bump(modelData.key, -modelData.step)
                }
                Rectangle {
                    width: 72
                    height: 42
                    radius: Theme.radius
                    color: Theme.surface
                    border.width: 1
                    border.color: Theme.hairline
                    BarText {
                        anchors.centerIn: parent
                        text: modelData.value + "m"
                        px: 13
                        family: Config.defaultFontUi
                    }
                }
                HudPick {
                    width: 42
                    label: "+"
                    onClicked: Idle.bump(modelData.key, modelData.step)
                }
            }
        }
    }
}
