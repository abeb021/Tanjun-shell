import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../bar"
import "../../services"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            visible: ShellState.sidebarOpen || body.opacity > 0.02
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            focusable: true

            readonly property bool open: ShellState.sidebarOpen
            readonly property bool onFocusedScreen: {
                const m = Hyprland.focusedMonitor;
                if (!m || !modelData)
                    return true;
                return m.name === modelData.name;
            }

            property bool grabOn: false

            WlrLayershell.namespace: "tanjun-sidebar"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            onOpenChanged: {
                if (open) {
                    grabOn = false;
                    grabDelay.restart();
                } else {
                    grabDelay.stop();
                    grabOn = false;
                    body.cpuOpen = false;
                }
            }

            Timer {
                id: grabDelay
                interval: 180
                onTriggered: grabOn = win.open
            }

            Shortcut {
                sequence: "Escape"
                enabled: open
                onActivated: ShellState.closeMenus()
            }

            HyprlandFocusGrab {
                active: win.grabOn && win.onFocusedScreen
                windows: [win]
                onCleared: if (win.grabOn && ShellState.sidebarOpen)
                    ShellState.closeMenus()
            }

            MouseArea {
                anchors.fill: parent
                enabled: open
                onClicked: ShellState.closeMenus()
            }

            Item {
                id: body
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 320
                transformOrigin: Item.Left
                opacity: open ? 1 : 0
                scale: open ? 1 : Motion.panelFrom
                property bool cpuOpen: false
                property bool netOpen: true

                Behavior on opacity {
                    enabled: Motion.ready
                    NumberAnimation {
                        duration: Motion.panel
                        easing.type: open ? Motion.easeOut : Motion.easeIn
                    }
                }
                Behavior on scale {
                    enabled: Motion.ready
                    NumberAnimation {
                        duration: Motion.panel
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
                color: Theme.accent
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
                                spacing: 8
                                width: parent.width
                                BarText {
                                    text: "単"
                                    family: Theme.fontJp
                                    px: 20
                                    color: Theme.accent
                                }
                                Column {
                                    spacing: 2
                                    width: parent.width - 28
                                    BarText {
                                        text: Host.user.length ? Host.user : "TANJUN"
                                        px: 12
                                    }
                                    BarText {
                                        visible: Host.machine.length > 0
                                        text: Host.machine
                                        sub: true
                                        px: 11
                                        width: parent.width
                                        wrapMode: Text.Wrap
                                    }
                                    BarText {
                                        text: Time.dateShort + "  ·  " + Layout.keymap + (Weather.text.length ? "  ·  " + Weather.text : "")
                                        sub: true
                                        px: 11
                                        width: parent.width
                                        wrapMode: Text.Wrap
                                    }
                                }
                            }
                        }

                        PlayerCard {
                            width: parent.width
                            artSize: 64
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
                        }

                        SideBlock {
                            title: "session"
                            Row {
                                spacing: 4
                                readonly property real cell: (parent.width - 12) / 4
                                BarButton {
                                    implicitWidth: parent.cell
                                    onClicked: {
                                        ShellState.closeMenus();
                                        const cmd = Config.argv(Config.session.lock);
                                        if (cmd && cmd.length)
                                            Quickshell.execDetached(cmd);
                                    }
                                    BarText {
                                        text: "lock"
                                        px: 11
                                    }
                                }
                                BarButton {
                                    implicitWidth: parent.cell
                                    onClicked: Quickshell.execDetached(["hyprctl", "dispatch", "exit"])
                                    BarText {
                                        text: "logout"
                                        px: 11
                                    }
                                }
                                BarButton {
                                    implicitWidth: parent.cell
                                    onClicked: Quickshell.execDetached(["systemctl", "reboot"])
                                    BarText {
                                        text: "reboot"
                                        px: 11
                                    }
                                }
                                BarButton {
                                    implicitWidth: parent.cell
                                    onClicked: {
                                        ShellState.closeMenus();
                                        Quickshell.execDetached(["systemctl", "suspend"]);
                                    }
                                    BarText {
                                        text: "sleep"
                                        px: 11
                                    }
                                }
                            }
                        }

                        SideBlock {
                            title: "skins"
                            Flow {
                                width: parent.width
                                spacing: 4
                                Repeater {
                                    model: Theme.catalog
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
    }
}
