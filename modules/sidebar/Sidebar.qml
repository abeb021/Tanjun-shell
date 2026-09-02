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
            implicitWidth: 320
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
                bottom: true
            }

            onOpenChanged: {
                if (open) {
                    grabOn = false;
                    grabDelay.restart();
                } else {
                    grabDelay.stop();
                    grabOn = false;
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

            Item {
                id: body
                anchors.fill: parent
                transformOrigin: Item.Left
                opacity: open ? 1 : 0
                scale: open ? 1 : Motion.panelFrom

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
                        spacing: 12

                        Row {
                            spacing: 8
                            BarText {
                                text: "単"
                                family: Theme.fontJp
                                px: 20
                                color: Theme.accent
                            }
                            Column {
                                BarText {
                                    text: "TANJUN"
                                    px: 12
                                }
                                BarText {
                                    text: Time.dateShort + "  " + Layout.keymap
                                    sub: true
                                    px: 11
                                }
                            }
                        }

                        BarText {
                            text: Weather.text
                            px: 13
                        }

                        BarText {
                            text: Media.line.length ? Media.line : "nothing playing"
                            px: 12
                            width: parent.width
                            wrapMode: Text.Wrap
                        }
                        Row {
                            spacing: 6
                            visible: Media.active
                            BarButton {
                                implicitWidth: 36
                                onClicked: if (Media.player)
                                    Media.player.togglePlaying()
                                BarText {
                                    text: Media.player && Media.player.isPlaying ? "" : ""
                                    icon: true
                                }
                            }
                            BarButton {
                                implicitWidth: 36
                                onClicked: if (Media.player && Media.player.canGoNext)
                                    Media.player.next()
                                BarText {
                                    text: ""
                                    icon: true
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Theme.surface
                        }

                        BarText {
                            text: "audio  " + Audio.label
                            px: 12
                        }
                        VolumeBar {
                            width: parent.width
                            value: Audio.volume
                            fill: Audio.muted ? Theme.critical : Theme.accent
                            onMoved: v => Audio.setVolume(v)
                        }

                        BarText {
                            visible: Audio.source
                            text: "mic  " + Audio.micLabel
                            px: 12
                        }
                        VolumeBar {
                            visible: Audio.source
                            width: parent.width
                            value: Audio.micVolume
                            fill: Audio.micMuted ? Theme.critical : Theme.accent
                            onMoved: v => Audio.setMicVolume(v)
                        }

                        BarText {
                            text: "backlight  " + Backlight.percent + "%"
                            px: 12
                        }
                        VolumeBar {
                            width: parent.width
                            value: Backlight.percent / 100
                            onMoved: v => Backlight.setPercent(v * 100)
                        }

                        BarText {
                            visible: Battery.ready
                            text: (Battery.charging ? "battery  charging  " : "battery  ") + Battery.percent + "%"
                            px: 12
                            color: Battery.percent <= 15 ? Theme.critical : Theme.fg
                        }

                        BarText {
                            text: Net.vpnUp ? (Net.text + "  ·  vpn " + Net.vpn) : Net.text
                            px: 12
                            color: Net.vpnUp ? Theme.accent : Theme.fg
                        }

                        BarButton {
                            implicitWidth: parent.width
                            onClicked: ShellState.dnd = !ShellState.dnd
                            BarText {
                                text: ShellState.dnd ? "do not disturb · on" : "do not disturb · off"
                                px: 12
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Theme.surface
                        }

                        BarText {
                            text: "session"
                            sub: true
                            px: 11
                        }

                        Row {
                            spacing: 4
                            readonly property real cell: (col.width - 12) / 4
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

                        BarText {
                            text: "themes"
                            sub: true
                            px: 11
                        }

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
