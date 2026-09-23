import QtQuick
import "../widgets"
import "../../services"

Column {
    id: page
    width: parent.width
    spacing: 16

    BarText {
        text: "CHROME"
        role: "head"
    }
    BarText {
        text: "Whole shell chrome. Palettes stay on Color."
        px: 11
        family: Config.defaultFontUi
        color: Theme.fgSub
        width: parent.width
        wrapMode: Text.Wrap
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

    BarText {
        text: "ANIMATION"
        role: "head"
    }
    BarText {
        text: "Pops drop from the bar. Panels, lock, and toasts travel."
        px: 11
        family: Config.defaultFontUi
        color: Theme.fgSub
        width: parent.width
        wrapMode: Text.Wrap
    }
    Row {
        width: parent.width
        spacing: 10
        Repeater {
            model: Motion.styles
            HudPick {
                required property var modelData
                width: (parent.width - parent.spacing * 3) / 4
                label: modelData.label
                current: Motion.kind === modelData.key
                onClicked: Motion.setMotion(modelData.key)
            }
        }
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
}
