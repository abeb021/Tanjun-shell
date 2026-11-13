import QtQuick
import "../widgets"
import "../../services"

Column {
    width: parent.width
    spacing: 16

    SetHead {
        title: "MONITOR MODE"
        desc: "Which output the bar and desk follow."
    }
    Row {
        width: parent.width
        spacing: 10
        Repeater {
            model: [
                { id: "first", label: "FIRST" },
                { id: "second", label: "SECOND" },
                { id: "extend", label: "EXTEND" }
            ]
            HudPick {
                required property var modelData
                width: (parent.width - parent.spacing * 2) / 3
                label: modelData.label
                current: Screens.deskKind === modelData.id
                onClicked: Screens.setDesk(modelData.id)
            }
        }
    }

    HudSlider {
        width: parent.width
        label: "BRIGHTNESS"
        icon: ""
        value: Backlight.percent < 0 ? 0 : Backlight.percent / 100
        onMoved: v => Backlight.setPercent(v * 100)
        onCommitted: v => Backlight.setPercent(v * 100)
    }

    SetHead {
        visible: Compositor.hasGamma
        title: "NIGHT LIGHT"
        desc: Screens.nightKelvin + "K · " + (Screens.nightOn ? "on" : "off")

        HudToggle {
            anchors.verticalCenter: parent.verticalCenter
            on: Screens.nightOn
            onToggled: Screens.setNightOn(!Screens.nightOn)
        }
    }

    HudSlider {
        visible: Compositor.hasGamma
        width: parent.width
        label: "TEMPERATURE"
        icon: ""
        value: (6500 - Screens.nightKelvin) / 3500
        onMoved: v => Screens.previewNight(6500 - v * 3500)
        onCommitted: v => Screens.setNightTemp(6500 - v * 3500)
    }

    SetRow {
        visible: Compositor.hasGamma
        label: "NIGHT AT"
        sub: "warm from this time"
        HudPick {
            width: 32
            height: 30
            implicitHeight: 30
            label: "−"
            onClicked: Screens.bumpNight(-15)
        }
        BarText {
            width: 56
            horizontalAlignment: Text.AlignHCenter
            text: Screens.nightAt
            px: 12
            family: Config.defaultFontUi
        }
        HudPick {
            width: 32
            height: 30
            implicitHeight: 30
            label: "+"
            onClicked: Screens.bumpNight(15)
        }
    }

    SetRow {
        visible: Compositor.hasGamma
        label: "DAY AT"
        sub: "identity from this time"
        HudPick {
            width: 32
            height: 30
            implicitHeight: 30
            label: "−"
            onClicked: Screens.bumpDay(-15)
        }
        BarText {
            width: 56
            horizontalAlignment: Text.AlignHCenter
            text: Screens.dayAt
            px: 12
            family: Config.defaultFontUi
        }
        HudPick {
            width: 32
            height: 30
            implicitHeight: 30
            label: "+"
            onClicked: Screens.bumpDay(15)
        }
    }

    SetHead {
        title: "OUTPUTS"
        desc: "Scale is saved per output."
    }

    Repeater {
        model: Screens.list
        Column {
            id: mon
            required property var modelData
            width: page.width
            spacing: 4

            SetRow {
                active: Screens.pick === modelData.name
                clickable: true
                label: modelData.name
                sub: `${modelData.width}x${modelData.height}` + (modelData.mode ? `  ·  ${Screens.compactMode(modelData.mode)}` : "")
                onClicked: Screens.pick = modelData.name
                BarText {
                    visible: Screens.pick === modelData.name
                    text: "ACTIVE"
                    px: 9
                    family: Config.defaultFontUi
                    font.letterSpacing: 1
                    color: Theme.accent
                }
            }

            HudSlider {
                width: parent.width
                label: "SCALE (" + Screens.fmtScale(modelData.scale) + "x)"
                icon: ""
                notches: Screens.scales.length
                value: Screens.scaleSlider(modelData.scale)
                onCommitted: v => {
                    Screens.pick = modelData.name;
                    Screens.setScale(Screens.scaleAt(v));
                }
            }
        }
    }

    BarText {
        text: Compositor.screenNote
        role: "caption"
        family: Config.defaultFontUi
        width: parent.width
        wrapMode: Text.Wrap
    }
}
