import QtQuick
import "../widgets"
import "../../services"

Column {
    id: page
    width: parent.width
    spacing: 20
    property string draft: ""

    BarText {
        text: "FORMAT"
        role: "head"
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

    BarText {
        text: "ZONES"
        role: "head"
    }
    Row {
        width: parent.width
        spacing: 10
        HudPick {
            width: (parent.width - parent.spacing) / 2
            label: "MOSCOW"
            current: page.hasZone("Europe/Moscow")
            onClicked: page.ensureZone("Europe/Moscow", "Moscow")
        }
        HudPick {
            width: (parent.width - parent.spacing) / 2
            label: "MELBOURNE"
            current: page.hasZone("Australia/Melbourne")
            onClicked: page.ensureZone("Australia/Melbourne", "Melbourne")
        }
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
        HudCard {
            required property var modelData
            required property int index
            width: page.width
            height: 46
            BarText {
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.label || modelData.id
                px: 12
                family: Config.defaultFontUi
            }
            BarText {
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: "REMOVE"
                px: 10
                family: Config.defaultFontUi
                color: Theme.critical
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: page.dropZone(index)
                }
            }
        }
    }
    Row {
        width: parent.width
        spacing: 10
        Rectangle {
            width: Math.max(160, parent.width - 88)
            height: 32
            color: Theme.surface
            border.width: 1
            border.color: Theme.hairline
            radius: Theme.radius
            TextInput {
                anchors.fill: parent
                anchors.margins: 8
                font.family: Config.defaultFontUi
                font.pixelSize: 12
                color: Theme.fg
                text: page.draft
                onTextChanged: page.draft = text
                Keys.onReturnPressed: page.addZone()
                Keys.onEnterPressed: page.addZone()
            }
        }
        HudPick {
            width: 78
            height: 32
            implicitHeight: 32
            label: "ADD"
            onClicked: page.addZone()
        }
    }
    BarText {
        text: "IANA id, e.g. Europe/Moscow"
        px: 11
        family: Config.defaultFontUi
        color: Theme.fgSub
        width: parent.width
        wrapMode: Text.Wrap
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
