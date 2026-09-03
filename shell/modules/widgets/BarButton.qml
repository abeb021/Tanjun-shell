import QtQuick
import "../../services"

Item {
    id: root
    property string popoutName: ""
    property bool active: false
    property bool mark: false
    implicitHeight: Theme.barHeight
    implicitWidth: Math.max(Theme.barHeight, content.implicitWidth + 10)

    default property alias contentData: content.data
    property alias overlay: overlayLayer

    Rectangle {
        anchors.fill: parent
        color: hover.hovered || (root.active && !root.mark) ? Theme.surfaceHover : "transparent"
        radius: Theme.radius
    }

    Rectangle {
        visible: !root.mark && root.active
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 5
        anchors.rightMargin: 5
        height: 1
        color: Theme.accent
    }

    Row {
        id: content
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 4
    }

    Item {
        id: overlayLayer
        anchors.fill: parent
        z: 1
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => {
            if (event.button === Qt.LeftButton)
                root.clicked();
            else if (event.button === Qt.RightButton)
                root.rightClicked();
            else
                root.middleClicked();
        }
        onWheel: event => root.wheeled(event.angleDelta.y > 0 ? 1 : -1)
    }

    HoverHandler {
        id: hover
    }

    signal clicked
    signal rightClicked
    signal middleClicked
    signal wheeled(int steps)

    onClicked: {
        if (popoutName.length)
            ShellState.togglePopout(popoutName, root);
    }

    Binding {
        when: root.popoutName.length > 0
        target: root
        property: "active"
        value: ShellState.popout === root.popoutName
    }
}
