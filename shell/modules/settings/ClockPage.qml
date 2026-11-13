import QtQuick
import "../widgets"
import "../../services"

Column {
    id: page
    width: parent.width
    spacing: 18
    property string draft: ""

    SetHead {
        title: "FORMAT"
        desc: "How the bar clock reads."
    }
    Row {
        width: parent.width
        spacing: 10
        HudPick {
            width: (parent.width - parent.spacing) / 2
            label: "12 HOUR"
            current: Config.clock.twelveHour
            onClicked: {
                Config.clock.twelveHour = true;
                Config.writeSparse();
            }
        }
        HudPick {
            width: (parent.width - parent.spacing) / 2
            label: "24 HOUR"
            current: !Config.clock.twelveHour
            onClicked: {
                Config.clock.twelveHour = false;
                Config.writeSparse();
            }
        }
    }

    SetHead {
        title: "ZONES"
        desc: "Click a zone to remove it."
    }
    BarText {
        visible: !(Config.clock.zones && Config.clock.zones.length)
        text: (Config.localLabel || "local") + "  ·  AUTO"
        px: 11
        family: Config.defaultFontUi
        color: Theme.fgSub
        font.letterSpacing: 1
    }
    Repeater {
        model: Config.clock.zones && Config.clock.zones.length ? Config.clockZones : []
        SetRow {
            required property var modelData
            required property int index
            clickable: true
            label: modelData.label || modelData.id
            sub: modelData.label && modelData.label !== modelData.id ? modelData.id : ""
            icon: "󰥔"
            onClicked: page.dropZone(index)
            BarText {
                text: "REMOVE"
                px: 9
                family: Config.defaultFontUi
                font.letterSpacing: 1
                color: Theme.critical
            }
        }
    }

    SetField {
        placeholder: "Add zone, e.g. Europe/Moscow"
        action: "ADD"
        text: page.draft
        onEdited: v => page.draft = v
        onAccepted: page.addZone()
        onTriggered: page.addZone()
    }

    function hasZone(id) {
        const z = Config.plainZones(Config.clockZones);
        for (let i = 0; i < z.length; i++) {
            if (z[i].id === id)
                return true;
        }
        return false;
    }

    function ensureZone(id, label) {
        if (hasZone(id))
            return;
        const z = Config.plainZones(Config.clockZones);
        z.push({
            id: id,
            label: label || Config.prettyZone(id)
        });
        Config.clock.zones = z;
        Config.writeSparse();
    }

    function addZone() {
        const id = draft.trim();
        if (!id.length)
            return;
        ensureZone(id, Config.prettyZone(id));
        draft = "";
    }

    function dropZone(index) {
        const z = Config.plainZones(Config.clockZones);
        if (index < 0 || index >= z.length)
            return;
        z.splice(index, 1);
        Config.clock.zones = z;
        Config.writeSparse();
    }
}
