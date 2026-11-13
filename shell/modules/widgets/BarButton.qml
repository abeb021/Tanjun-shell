import QtQuick
import "../../services"

Item {
    id: root
    property string popoutName: ""
    property bool drawer: false
    property bool active: false
    property bool mark: false
    implicitHeight: Theme.barHeight
    implicitWidth: Math.max(Theme.barHeight, content.implicitWidth + 10)
    scale: mouse.pressed ? Motion.pressFrom : 1
    Behavior on scale {
        enabled: Motion.ready
        NumberAnimation {
            duration: Motion.fast
            easing.type: Motion.easeOut
        }
    }

    default property alias contentData: content.data
    property alias overlay: overlayLayer

    Rectangle {
        anchors.fill: parent
        color: hover.hovered || (root.active && !root.mark) ? Theme.hotSoft : "transparent"
        radius: Theme.radius
    }

    Rectangle {
        visible: Theme.pip && !root.mark && root.active
        width: 2
        height: parent.height - 8
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        color: Theme.accent
    }

    Rectangle {
        visible: !Theme.pip && !root.mark && root.active
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
        z: 2
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

    // Hover-intent: resting on a menu button opens its menu. The pointer has to
    // stay on the button for a moment, so crossing the bar does nothing, and the
    // menu closes again once the pointer leaves both the button and the card.
    HoverHandler {
        id: hover
        onHoveredChanged: {
            if (!root.popoutName.length || !Config.appearance.hoverMenus)
                return;
            if (hovered) {
                UiMode.hoverButtons++;
                if (UiMode.popout !== root.popoutName)
                    openTimer.restart();
            } else {
                UiMode.hoverButtons = Math.max(0, UiMode.hoverButtons - 1);
                openTimer.stop();
            }
        }
    }

    Timer {
        id: openTimer
        interval: UiMode.hoverOpenDelay
        onTriggered: {
            if (!UiMode.barDragging && UiMode.popout !== root.popoutName)
                UiMode.hoverPopout(root.popoutName, root);
        }
    }

    signal clicked
    signal rightClicked
    signal middleClicked
    signal wheeled(int steps)

    onClicked: {
        if (drawer)
            UiMode.toggleSidebar();
        else if (popoutName.length)
            UiMode.togglePopout(popoutName, root);
    }

    Binding {
        when: root.popoutName.length > 0
        target: root
        property: "active"
        value: UiMode.popout === root.popoutName
    }
}
