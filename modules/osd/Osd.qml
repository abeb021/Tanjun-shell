import QtQuick
import Quickshell
import Quickshell.Wayland
import "../bar"
import "../../services"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            readonly property bool open: ShellState.osdKind.length > 0
            visible: open || body.opacity > 0.02
            color: "transparent"
            implicitWidth: 220
            implicitHeight: 52
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "tanjun-osd"
            WlrLayershell.layer: WlrLayer.Overlay

            anchors {
                bottom: true
            }
            margins.bottom: 48

            Rectangle {
                id: body
                anchors.fill: parent
                color: Theme.surface
                border.width: 1
                border.color: Theme.accent
                radius: Theme.radius
                opacity: open ? 1 : 0
                scale: open ? 1 : Motion.osdFrom

                Behavior on opacity {
                    enabled: Motion.ready
                    NumberAnimation {
                        duration: Motion.fast
                        easing.type: open ? Motion.easeOut : Motion.easeIn
                    }
                }
                Behavior on scale {
                    enabled: Motion.ready
                    NumberAnimation {
                        duration: Motion.fast
                        easing.type: open ? Motion.easeOut : Motion.easeIn
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 6
                    BarText {
                        text: ShellState.osdKind === "brightness" ? "󰃠" : (Audio.muted ? "" : "")
                        icon: true
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Rectangle {
                        width: 180
                        height: 6
                        color: Theme.bg
                        Rectangle {
                            width: parent.width * ShellState.osdValue
                            height: parent.height
                            color: Theme.accent
                            Behavior on width {
                                enabled: Motion.ready
                                NumberAnimation {
                                    duration: Motion.fast
                                    easing.type: Motion.easeOut
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
