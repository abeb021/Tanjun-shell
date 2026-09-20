import QtQuick
import "../widgets"
import "../../services"

Item {
    id: root
    property string title: ""
    property string current: ""
    property string sample: "Aa Bb 12"
    property var pins: []
    property var families: []
    property string query: ""
    readonly property var shown: {
        const fam = families || [];
        const pin = pins || [];
        const low = query.toLowerCase();
        const out = [];
        const seen = {};
        const add = n => {
            const s = `${n || ""}`;
            if (!s.length || seen[s])
                return;
            seen[s] = true;
            out.push(s);
        };
        if (!low.length) {
            for (let i = 0; i < pin.length; i++)
                add(pin[i]);
            add(current);
        }
        for (let i = 0; i < fam.length; i++) {
            const n = fam[i];
            if (!low.length || n.toLowerCase().indexOf(low) >= 0)
                add(n);
        }
        return out;
    }
    signal chosen(string name)

    onTitleChanged: {
        query = "";
        q.text = "";
    }

    Column {
        id: head
        width: parent.width
        spacing: 4

        BarText {
            text: root.title
            role: "head"
        }
        BarText {
            text: root.current.length ? root.current : "default"
            px: 12
            family: Config.defaultFontUi
            width: parent.width
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
        }
        BarText {
            visible: root.current.length > 0
            text: root.sample
            px: 16
            family: root.current
            width: parent.width
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
        }
        Flow {
            width: parent.width
            spacing: 8
            visible: (root.pins || []).length > 0
            Repeater {
                model: root.pins
                HudPick {
                    required property var modelData
                    height: 32
                    implicitHeight: 32
                    label: modelData
                    current: modelData === root.current
                    onClicked: root.chosen(modelData)
                }
            }
        }
        Rectangle {
            width: parent.width
            height: 32
            color: Theme.surface
            border.width: 1
            border.color: q.activeFocus ? Theme.accent : Theme.hairline
            radius: Theme.radius
            BarText {
                visible: !q.text.length
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 8
                text: "Search…"
                sub: true
                px: 12
                family: Config.defaultFontUi
            }
            TextInput {
                id: q
                anchors.fill: parent
                anchors.margins: 8
                font.family: Config.defaultFontUi
                font.pixelSize: 12
                color: Theme.fg
                clip: true
                onTextChanged: root.query = text
            }
        }
    }

    ListView {
        id: list
        anchors.top: head.bottom
        anchors.topMargin: 6
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 8000
        maximumFlickVelocity: 5000
        model: root.shown
        delegate: Rectangle {
            required property int index
            required property var modelData
            width: ListView.view.width
            height: 32
            color: rowHover.containsMouse ? Theme.hotSoft : "transparent"
            border.width: Theme.chipBorder
            border.color: modelData === root.current || rowHover.containsMouse ? Theme.accent : "transparent"
            radius: Theme.radius
            BarText {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                text: modelData
                px: 12
                family: Config.defaultFontUi
                wrapMode: Text.NoWrap
                elide: Text.ElideRight
                color: modelData === root.current ? Theme.accent : Theme.fg
            }
            MouseArea {
                id: rowHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.chosen(modelData)
            }
        }
    }
}
