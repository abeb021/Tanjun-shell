import QtQuick
import "../widgets"
import "../../services"

// A labelled text field on the page grid. Enter submits; the action label on
// the right is optional so a field can save itself or sit next to a chip.
Item {
    id: root

    property string label: ""
    property string placeholder: ""
    property string hint: ""
    property string action: ""
    property int echoMode: TextInput.Normal
    property alias text: input.text
    readonly property bool focused: input.activeFocus

    signal edited(string value)
    signal accepted(string value)
    signal triggered

    function clear() {
        input.text = "";
    }

    width: parent ? parent.width : 0
    height: 34 + (hint.length > 0 ? 18 : 0)

    BarText {
        id: lab
        width: root.label.length > 0 ? 120 : 0
        anchors.left: parent.left
        anchors.verticalCenter: field.verticalCenter
        text: root.label
        px: 12
        family: Config.defaultFontUi
        font.letterSpacing: 1
        color: Theme.fg
    }

    Rectangle {
        id: field
        anchors.left: lab.right
        anchors.right: actionBar.left
        anchors.rightMargin: root.action.length > 0 ? 10 : 0
        height: 32
        anchors.verticalCenter: parent.verticalCenter
        radius: Theme.radius
        color: Theme.surface
        border.width: 1
        border.color: root.focused ? Theme.accent : Theme.hairline

        BarText {
            visible: !input.text.length
            anchors.left: parent.left
            anchors.leftMargin: 9
            anchors.verticalCenter: parent.verticalCenter
            text: root.placeholder
            px: 11
            family: Config.defaultFontUi
            color: Theme.fgSub
        }

        TextInput {
            id: input
            anchors.fill: parent
            anchors.margins: 8
            font.family: Config.defaultFontUi
            font.pixelSize: 12
            color: Theme.fg
            echoMode: root.echoMode
            clip: true
            selectByMouse: true
            onTextChanged: root.edited(text)
            Keys.onReturnPressed: root.accepted(text)
            Keys.onEnterPressed: root.accepted(text)
        }
    }

    BarText {
        id: actionBar
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: field.verticalCenter
        width: root.action.length > 0 ? implicitWidth + 10 : 0
        height: 28
        horizontalAlignment: Text.AlignRight
        text: root.action
        px: 10
        family: Config.defaultFontUi
        color: Theme.accent
        MouseArea {
            visible: root.action.length > 0
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.triggered()
        }
    }

    BarText {
        visible: root.hint.length > 0
        anchors.left: field.left
        anchors.top: field.bottom
        anchors.topMargin: 3
        text: root.hint
        px: 9
        family: Config.defaultFontUi
        color: Theme.fgSub
        elide: Text.ElideRight
        width: field.width
    }
}
