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
        onCountChanged: ShellState.settingsStyleCount = count
        StyleCard {
            required property int index
            width: page.width
            kind: Theme.styles[index].key
            label: Theme.styles[index].label
            blurb: Theme.styles[index].blurb
            onClicked: Theme.setStyle(kind)
        }
        Component.onCompleted: ShellState.settingsStyleCount = count
    }
}
