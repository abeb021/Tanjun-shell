import QtQuick
import Quickshell
import "../widgets"
import "../../services"

Item {
    id: root

    readonly property var lockScreen: parent.screen
    readonly property bool isFocused: Compositor.isScreenFocused(lockScreen)
    readonly property string wallSrc: {
        const p = Theme.wallStill.length ? Theme.wallStill : (Theme.wallFile.length ? Theme.wallFile : `${Config.configHome}/background`);
        if (!p.length)
            return "";
        return p.startsWith("file:") ? p : ("file://" + p);
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        cache: false
        source: root.wallSrc
        visible: status === Image.Ready
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.55)
    }

    BarText {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: Theme.pad
        text: "単"
        role: "seal"
    }

    BarButton {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.pad - 4
        implicitWidth: 40
        implicitHeight: 28
        onClicked: Layout.cycle()
        BarText {
            text: Layout.keymap
            px: Theme.typeCaption
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -24
        spacing: 4
        width: 360

        BarText {
            width: parent.width
            text: {
                clock.date;
                return Time.formatTime(Time.tzId);
            }
            role: "display"
            px: Math.round(Theme.fontPx * 6)
            renderType: Text.NativeRendering
            horizontalAlignment: Text.AlignHCenter
        }

        BarText {
            width: parent.width
            text: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy")
            role: "caption"
            horizontalAlignment: Text.AlignHCenter
        }

        BarText {
            width: parent.width
            text: Time.tzLabel
            role: "caption"
            horizontalAlignment: Text.AlignHCenter
        }

        Repeater {
            model: Config.clockZones
            BarText {
                required property var modelData
                width: 360
                visible: (modelData.id || "") !== Time.tzId
                text: {
                    clock.date;
                    const lab = modelData.label || Config.prettyZone(modelData.id);
                    return Time.formatTime(modelData.id) + "  ·  " + lab;
                }
                role: "caption"
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Item {
            width: 1
            height: Theme.pad
        }

        Face {
            width: parent.width
            height: 36
            job: "pop"
            lit: box.activeFocus
            danger: Lock.fail
            ticks: false

            TextInput {
                id: box
                anchors.fill: parent
                anchors.margins: 8
                font.family: Theme.fontUi
                font.pixelSize: Theme.typeBody
                color: Theme.fg
                echoMode: TextInput.Password
                passwordCharacter: "•"
                clip: true
                enabled: Lock.locked && !Lock.busy
                text: Lock.password
                onTextChanged: {
                    if (Lock.password !== text)
                        Lock.password = text;
                }
                Keys.onReturnPressed: Lock.submit()
                Keys.onEnterPressed: Lock.submit()
            }
        }

        BarText {
            width: parent.width
            text: Lock.fail ? "wrong" : (Lock.fprint ? "fingerprint" : "")
            role: "caption"
            horizontalAlignment: Text.AlignHCenter
            height: Theme.typeCaption + 2
        }
    }

    Row {
        visible: Battery.ready
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: Theme.pad
        spacing: 6
        BarText {
            text: Battery.icon
            icon: true
            px: 13
            color: Battery.percent <= 15 ? Theme.critical : Theme.fg
        }
        BarText {
            text: `${Battery.percent}`
            role: "caption"
        }
    }

    BarText {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.pad
        text: Host.user
        role: "caption"
    }

    onIsFocusedChanged: {
        if (Lock.locked)
            box.forceActiveFocus();
    }

    Connections {
        target: Lock
        function onLockedChanged() {
            if (Lock.locked)
                box.forceActiveFocus();
        }
    }

    Component.onCompleted: {
        if (Lock.locked)
            box.forceActiveFocus();
    }
}
