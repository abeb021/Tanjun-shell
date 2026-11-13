import QtQuick
import "../widgets"
import "../../services"

// Font page: one segmented switch picks which face you are editing, one slider
// sets the UI size, and the browser below is the only list. The face name is
// not repeated on the browser — the switch already says it.
Item {
    id: root

    property string face: "ui"
    property var fonts: []
    readonly property int minPx: 6
    readonly property int maxPx: 64

    signal facePicked(string face)
    signal fontPicked(string which, string name)
    signal sizeSet(int px)
    signal resetRequested

    Column {
        id: controls
        width: parent.width
        spacing: 14

        Rectangle {
            id: tabs
            width: Math.min(330, parent.width)
            height: 34
            radius: Theme.radius
            color: Theme.surface
            border.width: 1
            border.color: Theme.hairline

            Row {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 3

                Repeater {
                    model: [
                        { id: "ui", label: "UI" },
                        { id: "jp", label: "JAPANESE" },
                        { id: "icons", label: "ICONS" }
                    ]
                    Rectangle {
                        required property var modelData
                        width: (tabs.width - 12) / 3
                        height: parent.height
                        radius: Theme.radius
                        color: root.face === modelData.id ? Theme.hot : (tabHover.containsMouse ? Theme.hotSoft : "transparent")
                        border.width: root.face === modelData.id ? 1 : 0
                        border.color: Theme.accent

                        Behavior on color {
                            enabled: Motion.ready
                            ColorAnimation {
                                duration: Motion.fast
                            }
                        }

                        BarText {
                            anchors.centerIn: parent
                            text: modelData.label
                            px: 10
                            family: Config.defaultFontUi
                            font.letterSpacing: Theme.chipTracking
                            color: root.face === modelData.id ? Theme.accent : Theme.fgSub
                        }

                        MouseArea {
                            id: tabHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.facePicked(modelData.id)
                        }
                    }
                }
            }
        }

        Row {
            width: parent.width
            spacing: 10

            BarText {
                anchors.verticalCenter: parent.verticalCenter
                text: "SIZE"
                role: "head"
            }

            // A stepper and a field, not a slider: the size is a number you
            // can type exactly, and +/- are just the fast path.
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 124
                height: 32
                radius: Theme.radius
                color: Theme.surface
                border.width: 1
                border.color: sizeEdit.activeFocus ? Theme.accent : Theme.hairline

                Row {
                    anchors.fill: parent
                    anchors.margins: 2

                    Item {
                        width: 34
                        height: parent.height

                        BarText {
                            anchors.centerIn: parent
                            text: "−"
                            px: 15
                            family: Config.defaultFontUi
                            color: minusHover.hovered ? Theme.accent : Theme.fg
                        }
                        MouseArea {
                            id: minusHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.sizeSet(Theme.fontPx - 1)
                        }
                    }

                    TextInput {
                        id: sizeEdit
                        width: 52
                        height: parent.height
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: Config.defaultFontUi
                        font.pixelSize: 13
                        color: Theme.fg
                        inputMethodHints: Qt.ImhDigitsOnly
                        validator: IntValidator {
                            bottom: root.minPx
                            top: root.maxPx
                        }
                        onEditingFinished: root.commitSize()
                        onActiveFocusChanged: if (!activeFocus)
                            root.commitSize()
                        Keys.onReturnPressed: root.commitSize()
                        Keys.onEnterPressed: root.commitSize()
                        Keys.onUpPressed: root.sizeSet(Theme.fontPx + 1)
                        Keys.onDownPressed: root.sizeSet(Theme.fontPx - 1)
                    }

                    Item {
                        width: 34
                        height: parent.height

                        BarText {
                            anchors.centerIn: parent
                            text: "+"
                            px: 15
                            family: Config.defaultFontUi
                            color: plusHover.hovered ? Theme.accent : Theme.fg
                        }
                        MouseArea {
                            id: plusHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.sizeSet(Theme.fontPx + 1)
                        }
                    }
                }
            }

            BarText {
                anchors.verticalCenter: parent.verticalCenter
                text: "PX"
                role: "head"
            }

            HudPick {
                anchors.verticalCenter: parent.verticalCenter
                width: 74
                height: 32
                implicitHeight: 32
                label: "RESET"
                onClicked: root.resetRequested()
            }
        }
    }

    Connections {
        target: Theme
        function onFontPxChanged() {
            if (!sizeEdit.activeFocus)
                sizeEdit.text = `${Theme.fontPx}`;
        }
    }

    Component.onCompleted: sizeEdit.text = `${Theme.fontPx}`

    function commitSize() {
        const n = parseInt(sizeEdit.text, 10);
        if (!isNaN(n))
            root.sizeSet(n);
        if (!sizeEdit.activeFocus)
            sizeEdit.text = `${Theme.fontPx}`;
    }

    FontPick {
        id: browser
        anchors.top: controls.bottom
        anchors.topMargin: 16
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        faceKey: root.face
        current: root.face === "jp" ? Theme.fontJp : (root.face === "icons" ? Theme.fontIcons : Theme.fontUi)
        preview: root.face === "jp" ? "単 あ" : (root.face === "icons" ? "󰂜 󰃠" : "Aa")
        pins: [root.face === "jp" ? Config.defaultFontJp : (root.face === "icons" ? Config.defaultFontIcons : Config.defaultFontUi)]
        families: root.fonts
        onChosen: name => root.fontPicked(root.face, name)
    }
}
