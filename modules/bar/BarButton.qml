import QtQuick
import Quickshell
import "../../services"

Item {
    id: root
    property string popoutName: ""
    property string tooltip: ""
    property bool active: false
    implicitHeight: Theme.barHeight
    implicitWidth: Math.max(Theme.barHeight, content.implicitWidth + 10)

    default property alias contentData: content.data

    Rectangle {
        anchors.fill: parent
        color: hover.hovered ? Theme.surfaceHover : "transparent"
        border.width: hover.hovered || root.active ? 1 : 0
        border.color: Theme.accent
        radius: Theme.radius
    }

    Row {
        id: content
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 4
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
}
