import QtQuick
import Quickshell
import Quickshell.Wayland
import "../widgets"
import "../../services"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            readonly property bool open: OsdBus.kind.length > 0
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

            Face {
                id: body
                job: "pop"
                anchors.fill: parent
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
                        text: OsdBus.kind === "brightness" ? "󰃠" : (Audio.muted ? "" : "")
                        icon: true
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Rectangle {
                        width: 180
                        height: 6
                        color: Theme.bg
                        Rectangle {
                            width: parent.width * OsdBus.value
                            height: parent.height
                            color: Theme.accent
                            Behavior on width {
                                enabled: Motion.ready && body.opacity > 0.95
                                NumberAnimation {
                                    duration: Motion.fast
                                    easing.type: Motion.easeOut
                                }
                            }
                            Rectangle {
                                visible: Theme.sliderGlow
                                anchors.fill: parent
                                anchors.margins: -2
                                radius: 4
                                color: "transparent"
                                border.width: 2
                                border.color: Theme.wash(Theme.accent, 0.35)
                            }
                        }
                    }
                }
            }
        }
    }
}
