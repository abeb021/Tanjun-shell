import QtQuick
import "../widgets"
import "../../services"

Item {
    id: root

    property string label: ""
    property string icon: ""
    property real value: 0
    property color accentColor: Theme.accent
    property real live: value
    property bool dragging: false
    property int notches: 0

    onValueChanged: if (!dragging)
        live = snap(value)

    function snap(v) {
        const t = Math.max(0, Math.min(1, Number(v) || 0));
        const n = notches;
        if (n < 2)
            return t;
        return Math.round(t * (n - 1)) / (n - 1);
    }

    signal moved(real value)
    signal committed(real value)

    implicitHeight: (label.length || icon.length) ? 50 : 16
    height: implicitHeight

    Column {
        anchors.fill: parent
        spacing: (root.label.length || root.icon.length) ? 8 : 0

        Row {
            visible: root.label.length || root.icon.length
            width: parent.width
            spacing: 0
            BarText {
                visible: root.icon.length
                text: root.icon
                icon: true
                px: 15
                color: root.accentColor
                width: 22
            }
            BarText {
                visible: root.label.length
                text: root.label
                px: 12
                family: Config.defaultFontUi
                font.letterSpacing: 1
            }
        }

        Item {
            width: parent.width
            height: 16

            Repeater {
                model: root.notches
                Rectangle {
                    required property int index
                    visible: root.notches > 1
                    width: 1
                    height: 6
                    color: Theme.hairline
                    x: (root.notches > 1 ? index / (root.notches - 1) : 0) * track.width
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Rectangle {
                id: track
                width: parent.width
                height: 4
                radius: 2
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.surface
                border.color: Theme.hairline
                border.width: 1

                Rectangle {
                    id: fill
                    width: track.width * Math.max(0, Math.min(1, root.live))
                    height: parent.height
                    radius: 2
                    color: root.accentColor
                    Behavior on width {
                        enabled: Motion.ready && !root.dragging
                        NumberAnimation {
                            duration: Motion.fast
                        }
                    }

                    Rectangle {
                        visible: Theme.sliderGlow
                        anchors.fill: parent
                        anchors.margins: -2
                        radius: 4
                        color: "transparent"
                        border.width: 2
                        border.color: Theme.wash(root.accentColor, 0.35)
                    }
                }

                Rectangle {
                    width: Theme.thumb
                    height: Theme.thumb
                    radius: Theme.pillToggle ? Theme.thumb / 2 : Theme.radius
                    anchors.verticalCenter: parent.verticalCenter
                    x: {
                        const raw = fill.width - width / 2;
                        return Math.max(0, Math.min(Math.max(0, track.width - width), raw));
                    }
                    color: Theme.fg
                    border.color: root.accentColor
                    border.width: 2
                    scale: drag.pressed ? (Theme.sliderGlow ? 1.4 : 1.15) : 1
                    Behavior on scale {
                        enabled: Motion.ready
                        NumberAnimation {
                            duration: Motion.fast
                        }
                    }
                }
            }

            MouseArea {
                id: drag
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                preventStealing: true
                function setFromX(px) {
                    const v = root.snap(px / Math.max(1, track.width));
                    root.live = v;
                    root.moved(v);
                }
                onPressed: mouse => {
                    root.dragging = true;
                    setFromX(mouse.x);
                }
                onPositionChanged: mouse => {
                    if (pressed)
                        setFromX(mouse.x);
                }
                onReleased: {
                    root.dragging = false;
                    root.committed(root.live);
                }
            }
        }
    }
}
