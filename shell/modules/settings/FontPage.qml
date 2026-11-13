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
    readonly property int minPx: 11
    readonly property int maxPx: 18

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
            spacing: 12

            BarText {
                anchors.verticalCenter: parent.verticalCenter
                text: "SIZE"
                role: "head"
            }

            HudSlider {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(80, parent.width - 196)
                notches: root.maxPx - root.minPx + 1
                value: (Theme.fontPx - root.minPx) / (root.maxPx - root.minPx)
                onCommitted: v => root.sizeSet(root.minPx + Math.round(v * (root.maxPx - root.minPx)))
            }

            BarText {
                anchors.verticalCenter: parent.verticalCenter
                width: 26
                horizontalAlignment: Text.AlignRight
                text: `${Theme.fontPx}`
                px: 12
                family: Config.defaultFontUi
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
