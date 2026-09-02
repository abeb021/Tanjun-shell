import QtQuick
import Quickshell
import "../bar"
import "../../services"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: ShellState.sidebarOpen
            color: Theme.bg
            implicitWidth: 320
            exclusionMode: ExclusionMode.Ignore

            anchors {
                top: true
                right: true
                bottom: true
            }

            margins.top: Theme.barHeight

            Column {
                anchors.fill: parent
                anchors.margins: 14
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
                Rectangle {
                    width: parent.width
                    height: 8
                    color: Theme.surface
                    Rectangle {
                        width: parent.width * Audio.volume
                        height: parent.height
                        color: Theme.accent
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: mouse => Audio.setVolume(mouse.x / width)
                    }
                }

                BarText {
                    text: "backlight  " + Backlight.percent + "%"
                    px: 12
                }
                Rectangle {
                    width: parent.width
                    height: 8
                    color: Theme.surface
                    Rectangle {
                        width: parent.width * Backlight.percent / 100
                        height: parent.height
                        color: Theme.accent
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: mouse => {
                            const p = Math.round(mouse.x / width * 100);
                            Quickshell.execDetached(["brightnessctl", "-d", "intel_backlight", "set", `${p}%`]);
                            Backlight.refresh();
                        }
                    }
                }

                BarButton {
                    implicitWidth: parent.width
                    onClicked: ShellState.dnd = !ShellState.dnd
                    BarText {
                        text: ShellState.dnd ? "не беспокоить · on" : "не беспокоить · off"
                        px: 12
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
                            implicitWidth: 96
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
