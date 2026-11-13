import QtQuick
import "../widgets"
import "../../services"

Column {
    id: page
    width: parent.width
    spacing: 18
    property string blDraft: Config.services.backlight
    property string kbDraft: Config.services.keyboard
    property string macDraft: Config.services.budsMac
    property string nameDraft: Config.services.budsName

    SetHead {
        title: "BACKLIGHT"
        desc: "Device name for brightness. Empty = auto."
    }
    SetField {
        label: "DEVICE"
        placeholder: "auto"
        action: "SAVE"
        text: page.blDraft
        onEdited: v => page.blDraft = v
        onAccepted: page.save()
        onTriggered: page.save()
    }
    Row {
        width: parent.width
        spacing: 10
        HudPick {
            width: 180
            label: "INTEL_BACKLIGHT"
            current: page.blDraft.trim() === "intel_backlight"
            onClicked: {
                page.blDraft = "intel_backlight";
                page.save();
            }
        }
    }

    SetHead {
        title: "KEYBOARD"
        desc: "Layout name shown on the bar. Empty = compositor default."
    }
    SetField {
        label: "LAYOUT"
        placeholder: "us"
        action: "SAVE"
        text: page.kbDraft
        onEdited: v => page.kbDraft = v
        onAccepted: page.save()
        onTriggered: page.save()
    }

    SetHead {
        title: "BUDS"
        desc: "Super+B target. Empty = off."
    }
    SetField {
        label: "MAC"
        placeholder: "AA:BB:CC:DD:EE:FF"
        text: page.macDraft
        onEdited: v => page.macDraft = v
        onAccepted: page.save()
    }
    SetField {
        label: "NAME"
        placeholder: "optional"
        action: "SAVE"
        text: page.nameDraft
        onEdited: v => page.nameDraft = v
        onAccepted: page.save()
        onTriggered: page.save()
    }

    function save() {
        Config.services.backlight = page.blDraft.trim();
        Config.services.keyboard = page.kbDraft.trim();
        Config.services.budsMac = page.macDraft.trim();
        Config.services.budsName = page.nameDraft.trim();
        Config.writeSparse();
    }
}
