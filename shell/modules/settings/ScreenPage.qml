import QtQuick
import "../widgets"
import "../../services"

Column {
    width: parent.width
    spacing: 20

    Column {
        width: parent.width
        spacing: 10
        BarText {
            text: "MONITOR MODE"
            role: "head"
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
                    onClicked: Screens.setDesk(modelData.id)
                }
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

    Item {
        visible: Compositor.hasGamma
        width: parent.width
        height: 58
        Row {
            anchors.fill: parent
            spacing: 25
            HudSlider {
                width: parent.width - 70 - parent.spacing
                height: parent.height
                label: "NIGHT LIGHT"
                icon: ""
                value: (Screens.gamma - 50) / 100
                onMoved: v => Screens.setGamma(50 + v * 100)
            }
            Rectangle {
                width: 70
                height: 36
                radius: Theme.radius
                anchors.verticalCenter: parent.verticalCenter
                color: Screens.gammaLive ? Theme.wash(Theme.accent, 0.1) : Theme.wash(Theme.fgSub, 0.15)
                border.width: 1
                border.color: Screens.gammaLive ? Theme.accent : Theme.fgSub
                BarText {
                    anchors.centerIn: parent
                    text: Screens.gammaLive ? "ON" : "OFF"
                    px: 10
                    family: Config.defaultFontUi
                    color: Screens.gammaLive ? Theme.accent : Theme.fgSub
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (Screens.gammaLive)
                            Screens.identity();
                        else
                            Screens.setGamma(Screens.gamma === 100 ? 80 : Screens.gamma);
                    }
                }
            }
        }
    }

    Repeater {
        model: Screens.list
        HudCard {
            required property var modelData
            width: parent.width
            implicitHeight: 108
            height: implicitHeight
            active: Screens.pick === modelData.name
            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8
                Row {
                    spacing: 10
                    BarText {
                        text: modelData.name
                        px: 14
                        family: Config.defaultFontUi
                    }
                    BarText {
                        text: `${modelData.width}x${modelData.height}` + (modelData.mode ? `  ${Screens.compactMode(modelData.mode)}` : "")
                        px: 12
                        family: Config.defaultFontUi
                        color: Theme.fgSub
                    }
                    BarText {
                        visible: Screens.pick === modelData.name
                        text: "ACTIVE"
                        px: 10
                        family: Config.defaultFontUi
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
            MouseArea {
                z: -1
                anchors.fill: parent
                onClicked: Screens.pick = modelData.name
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
