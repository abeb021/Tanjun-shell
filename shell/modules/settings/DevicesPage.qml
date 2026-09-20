import QtQuick
import "../widgets"
import "../../services"

Column {
    id: page
    width: parent.width
    spacing: 20
    property string blDraft: Config.services.backlight
    property string kbDraft: Config.services.keyboard

    BarText {
        text: "BACKLIGHT"
        role: "head"
    }
    BarText {
        text: "Empty = auto"
        px: 11
        family: Config.defaultFontUi
        color: Theme.fgSub
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
            text: page.blDraft
            onTextChanged: page.blDraft = text
            Keys.onReturnPressed: page.save()
            Keys.onEnterPressed: page.save()
        }
    }
    HudPick {
        width: parent.width
        label: "INTEL_BACKLIGHT"
        current: page.blDraft.trim() === "intel_backlight"
        onClicked: {
            page.blDraft = "intel_backlight";
            page.save();
        }
    }

    BarText {
        text: "KEYBOARD"
        role: "head"
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
            text: page.kbDraft
            onTextChanged: page.kbDraft = text
            Keys.onReturnPressed: page.save()
            Keys.onEnterPressed: page.save()
        }
    }
    HudPick {
        width: 120
        label: "SAVE"
        onClicked: page.save()
    }

    function save() {
        Config.services.backlight = page.blDraft.trim();
        Config.services.keyboard = page.kbDraft.trim();
        Config.writeSparse();
    }
}
