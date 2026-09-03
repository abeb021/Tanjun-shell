import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../widgets"
import "../../services"

PopupWindow {
    id: win

    required property var barWindow
    required property Item anchorItem

    readonly property bool open: ShellState.sidebarOpen
    readonly property int maxH: {
        const s = barWindow && barWindow.screen;
        if (!s)
            return 720;
        return Math.max(240, s.height - Theme.barHeight - 8);
    }

    visible: open || body.opacity > 0.02
    grabFocus: open
    color: "transparent"
    implicitWidth: 320
    implicitHeight: maxH
    anchor.window: barWindow
    anchor.item: anchorItem
    anchor.edges: Edges.Bottom | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.adjustment: PopupAdjustment.Slide

    onOpenChanged: {
        if (open)
            escSink.forceActiveFocus();
        else {
            body.cpuOpen = false;
            body.presetsOpen = false;
            body.wallsOpen = false;
        }
    }

    Item {
        id: escSink
        focus: true
        Keys.onEscapePressed: {
            if (body.wallsOpen)
                body.wallsOpen = false;
            else
                ShellState.closeMenus();
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: win.open
        onActivated: {
            if (body.wallsOpen)
                body.wallsOpen = false;
            else
                ShellState.closeMenus();
        }
    }

    HyprlandFocusGrab {
        active: win.open
        windows: [win]
        onCleared: if (win.open && ShellState.sidebarOpen)
            ShellState.closeMenus()
    }

    Item {
        id: body
        anchors.fill: parent
        transformOrigin: Item.TopLeft
        opacity: open ? 1 : 0
        scale: open ? 1 : Motion.popFrom
                property bool cpuOpen: false
                property bool netOpen: true
                property bool presetsOpen: false
                property bool wallsOpen: false

                Behavior on opacity {
                    enabled: Motion.ready
                    NumberAnimation {
                        duration: Motion.pop
                        easing.type: open ? Motion.easeOut : Motion.easeIn
                    }
                }
                Behavior on scale {
                    enabled: Motion.ready
                    NumberAnimation {
                        duration: Motion.pop
                        easing.type: open ? Motion.easeOut : Motion.easeIn
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {}
                }

                Rectangle {
                    anchors.fill: parent
                    color: Theme.bg
                }

            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 1
                color: Theme.hairline
            }

            Flickable {
                anchors.fill: parent
                anchors.margins: 14
                contentWidth: width
                contentHeight: col.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: col
                        width: parent.width
                        spacing: 16

                        SideBlock {
                            Row {
                                width: parent.width
                                spacing: 8

                                Column {
                                    id: mark
                                    spacing: 0
                                    BarText {
                                        text: "単"
                                        role: "seal"
                                        px: 20
                                    }
                                    BarText {
                                        text: "純"
                                        role: "seal"
                                        px: 20
                                    }
                                }

                                Column {
                                    width: parent.width - mark.implicitWidth - 8
                                    spacing: 2

                                    Item {
                                        width: parent.width
                                        height: 32
                                        BarText {
                                            anchors.left: parent.left
                                            anchors.right: sess.left
                                            anchors.rightMargin: 6
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: Host.user.length ? Host.user : ""
                                            px: 13
                                            wrapMode: Text.NoWrap
                                            elide: Text.ElideRight
                                        }
                                        Row {
                                            id: sess
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 2
                                            BarButton {
                                                implicitWidth: 32
                                                implicitHeight: 32
                                                onClicked: Lock.request()
                                                BarText {
                                                    text: ""
                                                    icon: true
                                                    px: 15
                                                }
                                            }
                                            BarButton {
                                                implicitWidth: 32
                                                implicitHeight: 32
                                                onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "exit"])
                                                BarText {
                                                    text: "󰍃"
                                                    icon: true
                                                    px: 16
                                                }
                                            }
                                            BarButton {
                                                implicitWidth: 32
                                                implicitHeight: 32
                                                onClicked: Quickshell.execDetached(["systemctl", "reboot"])
                                                BarText {
                                                    text: "󰜉"
                                                    icon: true
                                                    px: 16
                                                }
                                            }
                                            BarButton {
                                                implicitWidth: 32
                                                implicitHeight: 32
                                                onClicked: {
                                                    ShellState.closeMenus();
                                                    Quickshell.execDetached(["systemctl", "poweroff"]);
                                                }
                                                BarText {
                                                    text: ""
                                                    icon: true
                                                    px: 16
                                                }
                                            }
                                        }
                                    }

                                    BarText {
                                        width: parent.width
                                        text: Time.dateShort + (Host.machine.length ? "  ·  " + Host.machine : "")
                                        sub: true
                                        px: 11
                                        wrapMode: Text.NoWrap
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }

                        PlayerCard {
                            width: parent.width
                            artSize: 64
                            live: win.open
                        }

                        SideBlock {
                            title: "host"
                            Row {
                                spacing: 12
                                width: parent.width
                                Meter {
                                    width: (parent.width - 12) / 2
                                    icon: ""
                                    value: Host.cpuText
                                    ratio: Host.cpu / 100
                                    fill: Host.cpu >= 90 ? Theme.critical : Theme.accent
                                    danger: Host.cpu >= 90
                                    interactive: false
                                    iconClickable: true
                                    onIconClicked: body.cpuOpen = !body.cpuOpen
                                }
                                Meter {
                                    width: (parent.width - 12) / 2
                                    icon: ""
                                    value: Host.ramText
                                    ratio: Host.ramRatio
                                    fill: Host.ramRatio >= 0.9 ? Theme.critical : Theme.accent
                                    danger: Host.ramRatio >= 0.9
                                    interactive: false
                                }
                            }
                            Column {
                                visible: body.cpuOpen && Host.corePct.length > 0
                                width: parent.width
                                spacing: 3
                                BarText {
                                    text: Host.cpuTip
                                    sub: true
                                    px: 10
                                    width: parent.width
                                    wrapMode: Text.Wrap
                                }
                                Repeater {
                                    model: Host.corePct
                                    Row {
                                        required property var modelData
                                        required property int index
                                        width: parent.width
                                        spacing: 6
                                        BarText {
                                            text: `${index}`
                                            sub: true
                                            px: 10
                                            width: 16
                                        }
                                        VolumeBar {
                                            width: parent.width - 52
                                            value: Number(modelData) / 100
                                            interactive: false
                                            fill: Number(modelData) >= 90 ? Theme.critical : Theme.accent
                                        }
                                        BarText {
                                            text: `${Math.round(Number(modelData))}`
                                            px: 10
                                            width: 24
                                            horizontalAlignment: Text.AlignRight
                                        }
                                    }
                                }
                            }
                            Column {
                                width: parent.width
                                spacing: 4
                                Row {
                                    spacing: 8
                                    width: parent.width
                                    Item {
                                        width: 16
                                        height: 16
                                        BarText {
                                            anchors.centerIn: parent
                                            text: Net.connected ? "󰤨" : "󰤭"
                                            icon: true
                                            px: 13
                                            color: Net.vpnUp ? Theme.accent : (Net.connected ? Theme.fg : Theme.fgSub)
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: body.netOpen = !body.netOpen
                                        }
                                    }
                                    BarText {
                                        text: Net.vpnUp ? (Net.text + "  ·  vpn " + Net.vpn) : Net.text
                                        px: 12
                                        color: Net.vpnUp ? Theme.accent : Theme.fg
                                        width: parent.width - 24
                                        elide: Text.ElideRight
                                    }
                                }
                                Row {
                                    visible: body.netOpen
                                    width: parent.width
                                    spacing: 12
                                    Row {
                                        width: (parent.width - 12) / 2
                                        spacing: 6
                                        BarText {
                                            text: ""
                                            icon: true
                                            px: 13
                                        }
                                        BarText {
                                            width: parent.width - 22
                                            text: Host.downText
                                            px: 12
                                            horizontalAlignment: Text.AlignRight
                                        }
                                    }
                                    Row {
                                        width: (parent.width - 12) / 2
                                        spacing: 6
                                        BarText {
                                            text: ""
                                            icon: true
                                            px: 13
                                        }
                                        BarText {
                                            width: parent.width - 22
                                            text: Host.upText
                                            px: 12
                                            horizontalAlignment: Text.AlignRight
                                        }
                                    }
                                }
                            }
                            Repeater {
                                model: Host.procs
                                Item {
                                    required property var modelData
                                    width: parent.width
                                    height: 16
                                    BarText {
                                        anchors.left: parent.left
                                        anchors.right: procCpu.left
                                        anchors.rightMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.name
                                        px: 11
                                        elide: Text.ElideRight
                                    }
                                    BarText {
                                        id: procCpu
                                        anchors.right: procKill.left
                                        anchors.rightMargin: 6
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 40
                                        text: `${modelData.cpu}`
                                        sub: true
                                        px: 11
                                        horizontalAlignment: Text.AlignRight
                                    }
                                    Item {
                                        id: procKill
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 16
                                        height: 16
                                        BarText {
                                            anchors.centerIn: parent
                                            text: "󰅖"
                                            icon: true
                                            px: 11
                                            color: Theme.fgSub
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Host.killProc(modelData.pid)
                                        }
                                    }
                                }
                            }
                        }

                        SideBlock {
                            title: "desk"
                            Meter {
                                icon: ""
                                label: "audio"
                                value: Audio.label
                                ratio: Audio.volume
                                fill: Audio.muted ? Theme.critical : Theme.accent
                                danger: Audio.muted
                                onMoved: v => Audio.setVolume(v)
                            }
                            Meter {
                                visible: Audio.source
                                icon: ""
                                label: "mic"
                                value: Audio.micLabel
                                ratio: Audio.micVolume
                                fill: Audio.micMuted ? Theme.critical : Theme.accent
                                danger: Audio.micMuted
                                onMoved: v => Audio.setMicVolume(v)
                            }
                            Meter {
                                icon: "󰃠"
                                label: "light"
                                value: Backlight.percent + "%"
                                ratio: Backlight.percent / 100
                                onMoved: v => Backlight.setPercent(v * 100)
                            }
                            Meter {
                                visible: Battery.ready
                                icon: ""
                                label: Battery.charging ? "charging" : "battery"
                                value: Battery.percent + "%"
                                ratio: Battery.percent / 100
                                fill: Battery.percent <= 15 ? Theme.critical : Theme.accent
                                danger: Battery.percent <= 15
                                interactive: false
                            }
                            BarButton {
                                implicitWidth: parent.width
                                onClicked: ShellState.dnd = !ShellState.dnd
                                BarText {
                                    text: ShellState.dnd ? "dnd · on" : "dnd · off"
                                    px: 12
                                }
                            }
                            BarButton {
                                implicitWidth: parent.width
                                onClicked: ShellState.toggleSettings()
                                BarText {
                                    text: "settings"
                                    px: 12
                                }
                            }
                        }

                        SideBlock {
                            title: "skins"
                            Row {
                                width: parent.width
                                spacing: 4
                                BarButton {
                                    implicitWidth: parent.width - 52
                                    active: Theme.fromWall
                                    onClicked: {
                                        body.presetsOpen = false;
                                        Theme.setTheme("wall", "wall");
                                    }
                                    BarText {
                                        text: "From wall"
                                        px: 12
                                        color: Theme.fromWall ? Theme.accent : Theme.fg
                                    }
                                }
                                BarButton {
                                    implicitWidth: 48
                                    active: body.wallsOpen
                                    onClicked: body.wallsOpen = true
                                    BarText {
                                        text: "pick"
                                        px: 11
                                    }
                                }
                            }
                            Column {
                                width: parent.width
                                spacing: 8
                                BarButton {
                                    implicitWidth: parent.width
                                    active: body.presetsOpen || !Theme.fromWall
                                    onClicked: body.presetsOpen = !body.presetsOpen
                                    BarText {
                                        text: body.presetsOpen ? "presets  ▾" : (!Theme.fromWall && Theme.label.length ? "presets  ·  " + Theme.label : "presets  ▸")
                                        px: 11
                                        color: !Theme.fromWall ? Theme.accent : Theme.fgSub
                                    }
                                }
                                Flow {
                                    visible: body.presetsOpen
                                    width: parent.width
                                    spacing: 4
                                    Repeater {
                                        model: Theme.presets
                                        delegate: BarButton {
                                            required property var modelData
                                            implicitWidth: 92
                                            active: Theme.name === modelData.name
                                            onClicked: Theme.setTheme(modelData.kind, modelData.name)
                                            BarText {
                                                text: modelData.label
                                                px: 11
                                                color: Theme.name === modelData.name ? Theme.accent : Theme.fg
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            WallPick {
                anchors.fill: parent
                open: body.wallsOpen
                onCanceled: body.wallsOpen = false
                onPicked: path => {
                    body.wallsOpen = false;
                    Theme.setWallpaper(path);
                }
            }
        }
