import QtQuick
import "../widgets"
import "../../services"

// Replays the current animation preset, so its speed can be judged before it is
// trusted. Three things the shell actually animates: a popout dropping from the
// bar, a panel arriving, and a toast sliding in. Every value comes from Motion,
// so changing the preset and watching this strip is the same motion the shell
// will use.
Rectangle {
    id: root

    implicitHeight: 112
    radius: Theme.radius
    color: Theme.bg
    border.width: 1
    border.color: Theme.hairline

    property bool playing: false
    // true for the single frame where we snap back to the start, so the replay
    // always plays the arrival rather than animating backwards first
    property bool snap: false

    function run() {
        SettingsNav.demoRuns++;
        snap = true;
        playing = false;
        Qt.callLater(() => {
            snap = false;
            playing = true;
        });
    }

    Component.onCompleted: Qt.callLater(root.run)

    Connections {
        target: Motion
        function onKindChanged() {
            root.run();
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.run()
    }

    // the bar the popout belongs to
    Rectangle {
        id: miniBar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        height: 14
        color: Theme.surface

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5
            Repeater {
                model: 4
                Rectangle {
                    required property int index
                    width: index === 0 ? 14 : 7
                    height: 3
                    radius: 1
                    color: index === 0 ? Theme.accent : Theme.hairline
                }
            }
        }
    }

    // 1. a popout pulled out of the bar (the real one uses this same spring)
    SpringProgress {
        id: demoReveal
        open: root.playing
    }

    Item {
        id: popSlot
        width: 96
        height: Math.round(34 * demoReveal.value)
        clip: true
        x: 10
        y: 10 + miniBar.height

        Rectangle {
            width: popSlot.width
            height: 34
            radius: Theme.radius
            color: Theme.wash(Theme.accent, 0.14)
            border.width: 1
            border.color: Theme.accent

            Column {
                anchors.centerIn: parent
                spacing: 3
                Repeater {
                    model: 2
                    Rectangle {
                        required property int index
                        width: index === 0 ? 54 : 34
                        height: 3
                        radius: 1
                        color: Theme.wash(Theme.fg, index === 0 ? 0.75 : 0.4)
                    }
                }
            }
        }
    }

    // 2. a panel arriving
    Rectangle {
        id: panelCard
        width: 116
        height: 54
        radius: Theme.radius
        color: Theme.surface
        border.width: 1
        border.color: Theme.hairline
        x: root.width - width - 14
        y: 30 + (root.playing ? 0 : Motion.panelY)
        opacity: root.playing ? 1 : 0
        scale: root.playing ? 1 : Motion.panelFrom

        Rectangle {
            anchors.fill: parent
            anchors.margins: 9
            color: "transparent"
            Column {
                spacing: 5
                Repeater {
                    model: 3
                    Rectangle {
                        required property int index
                        width: index === 2 ? 48 : 84
                        height: 3
                        radius: 1
                        color: Theme.wash(Theme.fg, index === 0 ? 0.7 : 0.35)
                    }
                }
            }
        }

        Behavior on y {
            enabled: Motion.ready && !root.snap
            NumberAnimation {
                duration: Motion.panel
                easing.type: root.playing ? Motion.enterEase : Motion.easeIn
            }
        }
        Behavior on opacity {
            enabled: Motion.ready && !root.snap
            NumberAnimation {
                duration: Motion.panel
                easing.type: root.playing ? Motion.enterEase : Motion.easeIn
            }
        }
        Behavior on scale {
            enabled: Motion.ready && !root.snap
            NumberAnimation {
                duration: Motion.panel
                easing.type: root.playing ? Motion.enterEase : Motion.easeIn
            }
        }
    }

    // 3. a toast sliding in from the right
    Rectangle {
        id: toast
        width: 74
        height: 20
        radius: Theme.radius
        color: Theme.wash(Theme.good, 0.16)
        border.width: 1
        border.color: Theme.good
        y: 78
        x: root.width - width - 14 + (root.playing ? 0 : Math.max(0, Motion.toastX))
        opacity: root.playing ? 1 : 0

        Behavior on x {
            enabled: Motion.ready && !root.snap
            NumberAnimation {
                duration: Motion.slow
                easing.type: root.playing ? Motion.enterEase : Motion.easeIn
            }
        }
        Behavior on opacity {
            enabled: Motion.ready && !root.snap
            NumberAnimation {
                duration: Motion.slow
                easing.type: root.playing ? Motion.enterEase : Motion.easeIn
            }
        }
    }

    BarText {
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        text: `pop ${Motion.pop} · panel ${Motion.panel} · toast ${Motion.slow} ms`
        px: 10
        family: Config.defaultFontUi
        color: Theme.fgSub
    }

    BarText {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        text: root.playing ? "replay" : "…"
        px: 10
        family: Config.defaultFontUi
        color: Theme.accent
    }
}
