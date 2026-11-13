import QtQuick
import "../widgets"
import "../../services"

Column {
    width: parent.width
    spacing: 18

    SetHead {
        title: "WALL"
        desc: "Whether a new wallpaper also repaints the palette."
    }
    Row {
        width: parent.width
        spacing: 10
        HudPick {
            width: (parent.width - parent.spacing) / 2
            label: "PULL COLORS"
            current: Config.theme.sampleWall
            onClicked: {
                Config.theme.sampleWall = true;
                Config.writeSparse();
            }
        }
        HudPick {
            width: (parent.width - parent.spacing) / 2
            label: "KEEP PALETTE"
            current: !Config.theme.sampleWall
            onClicked: {
                Config.theme.sampleWall = false;
                Config.writeSparse();
            }
        }
    }
    BarText {
        text: Config.theme.sampleWall ? "pick a wall and pull colors" : "pick a wall, keep this palette"
        px: 11
        family: Config.defaultFontUi
        color: Theme.fgSub
        width: parent.width
        wrapMode: Text.Wrap
    }

    SetHead {
        title: "PALETTES"
        desc: "Named colors. Shell chrome is on Style."
    }
    SkinChip {
        pal: ({
            label: "From wall",
            bg: Theme.hexOf(Theme.bg),
            surface: Theme.hexOf(Theme.surface),
            fg: Theme.hexOf(Theme.fg),
            accent: Theme.hexOf(Theme.accent)
        })
        active: Theme.fromWall
        onClicked: Theme.setTheme("wall", "wall")
    }
    Flow {
        width: parent.width
        spacing: 8
        Repeater {
            model: Theme.presets
            SkinChip {
                required property var modelData
                pal: modelData
                active: Theme.name === modelData.name
                onClicked: Theme.setTheme(modelData.kind, modelData.name)
            }
        }
    }
}
