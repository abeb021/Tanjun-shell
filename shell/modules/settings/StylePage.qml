import QtQuick
import "../widgets"
import "../../services"

Column {
    id: page
    width: parent.width
    spacing: 16

    SetHead {
        title: "BAR"
        desc: "Which screen edge holds the shell bar."
    }
    Row {
        width: parent.width
        spacing: 10
        Repeater {
            model: [
                { id: "top", label: "TOP" },
                { id: "bottom", label: "BOTTOM" },
                { id: "left", label: "LEFT" },
                { id: "right", label: "RIGHT" }
            ]
            HudPick {
                required property var modelData
                width: (parent.width - parent.spacing * 3) / 4
                label: modelData.label
                current: Theme.barEdge === modelData.id
                onClicked: Theme.setBarEdge(modelData.id)
            }
        }
    }

    SetHead {
        title: "CHROME"
        desc: "Whole shell chrome. Palettes stay on Color."
    }

    Repeater {
        model: Theme.styles.length
        onCountChanged: SettingsNav.styleCount = count
        StyleCard {
            required property int index
            width: page.width
            kind: Theme.styles[index].key
            label: Theme.styles[index].label
            blurb: Theme.styles[index].blurb
            onClicked: Theme.setStyle(kind)
        }
        Component.onCompleted: SettingsNav.styleCount = count
    }

    SetHead {
        title: "ANIMATION"
        desc: "Pops drop from the bar. Panels, lock, and toasts travel."
    }
    MotionDemo {
        width: parent.width
    }

    Row {
        width: parent.width
        spacing: 10
        Repeater {
            model: Motion.styles
            HudPick {
                required property var modelData
                width: (parent.width - parent.spacing * Math.max(0, Motion.styles.length - 1)) / Math.max(1, Motion.styles.length)
                label: modelData.label
                current: Motion.kind === modelData.key
                onClicked: Motion.setMotion(modelData.key)
            }
        }
    }
    HudSlider {
        id: speed
        width: parent.width
        label: `SPEED  ${Math.round(Motion.speedMin + speed.live * (Motion.speedMax - Motion.speedMin))}%`
        icon: "󰓅"
        notches: 16
        value: (Motion.speedPct - Motion.speedMin) / Math.max(1, Motion.speedMax - Motion.speedMin)
        onCommitted: v => Motion.setSpeed(Motion.speedMin + v * (Motion.speedMax - Motion.speedMin))
    }
    BarText {
        text: {
            const rows = Motion.styles;
            for (let i = 0; i < rows.length; i++) {
                if (rows[i].key === Motion.kind)
                    return rows[i].blurb;
            }
            return "";
        }
        px: 11
        family: Config.defaultFontUi
        color: Theme.fgSub
        width: parent.width
        wrapMode: Text.Wrap
    }

    BarText {
        text: "Click the strip to replay it with the current preset and speed."
        px: 11
        family: Config.defaultFontUi
        color: Theme.fgSub
        width: parent.width
        wrapMode: Text.Wrap
    }
}
