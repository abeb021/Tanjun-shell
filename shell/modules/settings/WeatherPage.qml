import QtQuick
import "../widgets"
import "../../services"

Column {
    id: page
    width: parent.width
    spacing: 20
    property string draft: Config.services.weatherCity

    BarText {
        text: "CITY"
        role: "head"
    }
    BarText {
        text: "wttr.in. Empty uses IP."
        px: 11
        family: Config.defaultFontUi
        color: Theme.fgSub
        width: parent.width
        wrapMode: Text.Wrap
    }
    Rectangle {
        width: parent.width
        height: 32
        color: Theme.surface
        border.width: 1
        border.color: Theme.hairline
        radius: Theme.radius
        TextInput {
            anchors.fill: parent
            anchors.margins: 8
            font.family: Config.defaultFontUi
            font.pixelSize: 13
            color: Theme.fg
            text: page.draft
            onTextChanged: page.draft = text
            Keys.onReturnPressed: page.save()
            Keys.onEnterPressed: page.save()
        }
    }
    Row {
        width: parent.width
        spacing: 10
        HudPick {
            width: (parent.width - parent.spacing) / 2
            label: "MOSCOW"
            current: Config.services.weatherCity === "Moscow"
            onClicked: {
                page.draft = "Moscow";
                page.save();
            }
        }
        HudPick {
            width: (parent.width - parent.spacing) / 2
            label: "SAVE"
            onClicked: page.save()
        }
    }

    function save() {
        Config.services.weatherCity = page.draft.trim();
        Config.writeSparse();
    }
}
