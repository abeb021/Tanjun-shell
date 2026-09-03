import QtQuick
import "../widgets"
import "../../services"

Column {
    width: parent.width
    spacing: 10

    BarText {
        text: "live on Hyprland. scale and mode persist in ~/.config/hypr/monitors.lua."
        role: "caption"
        family: Config.defaultFontUi
        width: parent.width
        wrapMode: Text.Wrap
    }

    BarText {
        text: "output"
        px: 12
        family: Config.defaultFontUi
    }

    Flow {
        width: parent.width
        spacing: 4
        Repeater {
            model: Screens.list
            BarButton {
                required property var modelData
                implicitWidth: Math.max(72, lab.implicitWidth + 14)
                active: Screens.pick === modelData.name
                onClicked: Screens.pick = modelData.name
                BarText {
                    id: lab
                    text: modelData.name
                    px: 12
                    family: Config.defaultFontUi
                    color: Screens.pick === modelData.name ? Theme.accent : Theme.fg
                }
            }
        }
    }

    BarText {
        visible: Screens.current && (Screens.current.desc || "").length
        text: Screens.current ? Screens.current.desc : ""
        role: "caption"
        family: Config.defaultFontUi
        width: parent.width
        wrapMode: Text.Wrap
    }

    BarText {
        text: "mode"
        px: 12
        family: Config.defaultFontUi
    }

    Flow {
        width: parent.width
        spacing: 4
        Repeater {
            model: Screens.current ? Screens.current.modes : []
            BarButton {
                required property var modelData
                implicitWidth: Math.max(88, modeLab.implicitWidth + 14)
                active: Screens.current && Screens.sameMode(Screens.current.mode, modelData)
                onClicked: Screens.setMode(modelData)
                BarText {
                    id: modeLab
                    text: Screens.compactMode(modelData)
                    px: 11
                    family: Config.defaultFontUi
                }
            }
        }
    }

    BarText {
        text: "scale"
        px: 12
        family: Config.defaultFontUi
    }

    Flow {
        width: parent.width
        spacing: 4
        Repeater {
            model: Screens.scales
            BarButton {
                required property var modelData
                implicitWidth: 56
                active: Math.abs(Screens.scale - modelData) < 0.02
                onClicked: Screens.setScale(modelData)
                BarText {
                    text: `${modelData}`
                    px: 12
                    family: Config.defaultFontUi
                    color: Math.abs(Screens.scale - modelData) < 0.02 ? Theme.accent : Theme.fg
                }
            }
        }
    }

    BarText {
        text: "gamma  " + Screens.gamma
        px: 12
        family: Config.defaultFontUi
    }

    VolumeBar {
        width: parent.width
        value: (Screens.gamma - 50) / 100
        onMoved: v => Screens.setGamma(50 + v * 100)
    }

    Row {
        spacing: 6
        BarButton {
            implicitWidth: 72
            onClicked: Screens.setGamma(100)
            BarText {
                text: "100"
                px: 11
                family: Config.defaultFontUi
            }
        }
        BarButton {
            implicitWidth: 88
            onClicked: Screens.identity()
            BarText {
                text: "identity"
                px: 11
                family: Config.defaultFontUi
            }
        }
    }
}
