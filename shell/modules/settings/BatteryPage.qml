import QtQuick
import "../widgets"
import "../../services"

Column {
    width: parent.width
    spacing: 18

    SetHead {
        title: "BATTERY"
        desc: Battery.ready
            ? `${Battery.percent}%` + (Battery.charging ? "  ·  CHARGING" : "")
            : "Reading battery…"
    }

    SetHead {
        title: "IDLE"
        desc: "Minutes until each step. 0 disables it."
    }
    Repeater {
        model: [
            { key: "dim", label: "DIM", value: Idle.dimMin, step: 1 },
            { key: "lock", label: "LOCK", value: Idle.lockMin, step: 1 },
            { key: "dpms", label: "SCREEN OFF", value: Idle.dpmsMin, step: 1 },
            { key: "sleep", label: "SLEEP", value: Idle.sleepMin, step: 5 },
            { key: "hibernate", label: "HIBERNATE", value: Idle.hibernateMin, step: 5 }
        ]
        SetRow {
            required property var modelData
            label: modelData.label
            sub: modelData.value > 0 ? `${modelData.value} min` : "off"
            HudPick {
                width: 32
                height: 30
                implicitHeight: 30
                label: "−"
                onClicked: Idle.bump(modelData.key, -modelData.step)
            }
            BarText {
                width: 48
                horizontalAlignment: Text.AlignHCenter
                text: modelData.value > 0 ? `${modelData.value}m` : "—"
                px: 12
                family: Config.defaultFontUi
            }
            HudPick {
                width: 32
                height: 30
                implicitHeight: 30
                label: "+"
                onClicked: Idle.bump(modelData.key, modelData.step)
            }
        }
    }
}
