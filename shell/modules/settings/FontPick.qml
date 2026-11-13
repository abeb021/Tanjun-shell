import QtQuick
import "../widgets"
import "../../services"

// Font browser: the current face at the top, a search field, and every family
// on the machine. Each row is drawn in its own font, so the list is the
// preview — there is no separate sample block to keep in sync.
Item {
    id: root

    property string current: ""
    property string preview: "Aa"
    property var pins: []
    property var families: []
    // Changing the face is a new list; the old search would be misleading.
    property string faceKey: ""

    property string query: ""
    property string queryRaw: ""

    signal chosen(string name)

    readonly property var shown: {
        const fam = root.families || [];
        const pin = root.pins || [];
        const low = root.query.toLowerCase();
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
            add(root.current);
        }
        for (let i = 0; i < fam.length; i++) {
            const n = fam[i];
            if (!low.length || n.toLowerCase().indexOf(low) >= 0)
                add(n);
        }
        return out;
    }

    onFaceKeyChanged: {
        query = "";
        queryRaw = "";
        q.text = "";
    }

    Timer {
        id: qTimer
        interval: 80
        onTriggered: root.query = root.queryRaw
    }

    Column {
        id: head
        width: parent.width
        spacing: 10

        Row {
            width: parent.width
            spacing: 10

            Column {
                width: parent.width - sample.width - 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                BarText {
                    text: "CURRENT"
                    role: "head"
                }
                BarText {
                    width: parent.width
                    text: root.current.length ? root.current : "Default"
                    px: 13
                    family: Config.defaultFontUi
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                    color: root.current.length ? Theme.fg : Theme.fgSub
                }
            }

            Rectangle {
                id: sample
                width: 96
                height: 44
                radius: Theme.radius
                color: Theme.surface
                border.width: 1
                border.color: Theme.hairline

                BarText {
                    anchors.centerIn: parent
                    text: root.preview
                    px: 15
                    family: root.current.length ? root.current : Config.defaultFontUi
                    color: Theme.fg
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 32
            radius: Theme.radius
            color: Theme.surface
            border.width: 1
            border.color: q.activeFocus ? Theme.accent : Theme.hairline

            BarText {
                visible: !q.text.length
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "Search fonts…"
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
                onTextChanged: {
                    root.queryRaw = text;
                    qTimer.restart();
                }
            }
        }
    }

    ListView {
        id: list
        anchors.top: head.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        reuseItems: true
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 8000
        maximumFlickVelocity: 5000
        model: root.shown

        delegate: Rectangle {
            required property var modelData
            width: ListView.view.width
            height: 34
            radius: Theme.radius
            color: rowHover.containsMouse ? Theme.hotSoft : (modelData === root.current ? Theme.hot : "transparent")
            border.width: modelData === root.current || rowHover.containsMouse ? 1 : 0
            border.color: Theme.accent

            Behavior on color {
                enabled: Motion.ready
                ColorAnimation {
                    duration: Motion.fast
                }
            }

            BarText {
                anchors.left: parent.left
                anchors.right: peek.left
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

            BarText {
                id: peek
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: root.preview
                px: 13
                family: modelData
                color: modelData === root.current ? Theme.accent : Theme.fgSub
                opacity: 0.75
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

    Item {
        visible: list.count === 0
        anchors.fill: list
        SetEmpty {
            anchors.centerIn: parent
            width: parent.width
            icon: "󰛖"
            title: "NO FONTS"
            hint: "Try another spelling."
        }
    }

    WheelScroll {
        anchors.fill: list
        flick: list
    }
}
