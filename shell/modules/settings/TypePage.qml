import QtQuick
import "../widgets"
import "../../services"

Item {
    id: root
    property string face: "ui"
    property var fonts: []
    signal facePicked(string face)
    signal fontPicked(string which, string name)
    signal sizeNudge(int delta)
    signal resetRequested

    Column {
        id: typeHead
        width: parent.width
        spacing: 12
        BarText {
            text: "FACE"
            role: "head"
        }
        Row {
            width: parent.width
            spacing: 10
            Repeater {
                model: [
                    { id: "ui", label: "UI" },
                    { id: "jp", label: "JAPANESE" },
                    { id: "icons", label: "ICONS" }
                ]
                HudPick {
                    required property var modelData
                    width: (parent.width - 20) / 3
                    label: modelData.label
                    current: root.face === modelData.id
                    onClicked: root.facePicked(modelData.id)
                }
            }
        }
        BarText {
            text: "Empty = default"
            px: 11
            family: Config.defaultFontUi
            color: Theme.fgSub
            width: parent.width
            wrapMode: Text.Wrap
        }
    }

    Row {
        id: typeSize
        anchors.bottom: parent.bottom
        width: parent.width
        spacing: 10
        BarText {
            text: "SIZE  " + Theme.fontPx
            role: "head"
            anchors.verticalCenter: parent.verticalCenter
        }
        HudPick {
            width: 42
            implicitHeight: 32
            height: 32
            label: "−"
            onClicked: root.sizeNudge(-1)
        }
        HudPick {
            width: 42
            implicitHeight: 32
            height: 32
            label: "+"
            onClicked: root.sizeNudge(1)
        }
        HudPick {
            width: 88
            implicitHeight: 32
            height: 32
            label: "RESET"
            onClicked: root.resetRequested()
        }
    }

    FontPick {
        anchors.top: typeHead.bottom
        anchors.topMargin: 8
        anchors.bottom: typeSize.top
        anchors.bottomMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        title: root.face === "jp" ? "JAPANESE" : (root.face === "icons" ? "ICONS" : "UI")
        current: root.face === "jp" ? Theme.fontJp : (root.face === "icons" ? Theme.fontIcons : Theme.fontUi)
        pins: [root.face === "jp" ? Config.defaultFontJp : (root.face === "icons" ? Config.defaultFontIcons : Config.defaultFontUi)]
        sample: root.face === "jp" ? "単 純 あ い" : (root.face === "icons" ? "  󰃠 " : "Aa Bb 12")
        families: root.fonts
        onChosen: root.fontPicked(root.face, name)
    }
}
