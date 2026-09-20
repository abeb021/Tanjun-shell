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
            visible: (!ShellState.dnd && toast.count > 0) || toast.opacity > 0.02
            color: "transparent"
            implicitWidth: 320
            implicitHeight: Math.min(320, Math.max(1, toast.contentHeight) + 4)
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "tanjun-toast"
            WlrLayershell.layer: WlrLayer.Overlay

            anchors {
                top: true
                right: true
            }
            margins.top: Theme.barHeight + 8
            margins.right: 8

            ListView {
                id: toast
                anchors.fill: parent
                model: Notifs.list
                spacing: 6
                opacity: !ShellState.dnd && count > 0 ? 1 : 0
                Behavior on opacity {
                    enabled: Motion.ready
                    NumberAnimation {
                        duration: Motion.fast
                        easing.type: Motion.easeOut
                    }
                }
                add: Transition {
                    NumberAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: Motion.fast
                        easing.type: Motion.easeOut
                    }
                    NumberAnimation {
                        property: "x"
                        from: 24
                        to: 0
                        duration: Motion.fast
                        easing.type: Motion.easeOut
                    }
                }
                remove: Transition {
                    NumberAnimation {
                        property: "opacity"
                        to: 0
                        duration: Motion.fast
                        easing.type: Motion.easeIn
                    }
                }
                displaced: Transition {
                    NumberAnimation {
                        properties: "y"
                        duration: Motion.fast
                        easing.type: Motion.easeOut
                    }
                }
                delegate: Face {
                    required property var modelData
                    job: "pop"
                    width: toast.width
                    implicitHeight: col.implicitHeight + 16
                    height: implicitHeight
                    MouseArea {
                        anchors.fill: parent
                        onClicked: modelData.dismiss()
                    }
                    Column {
                        id: col
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 8
                        spacing: 4
                        BarText {
                            visible: (modelData.appName || "").length && modelData.appName !== modelData.summary
                            text: modelData.appName || ""
                            role: "caption"
                            width: parent.width
                        }
                        BarText {
                            text: modelData.summary || modelData.appName
                            px: 12
                            width: parent.width
                        }
                        BarText {
                            text: modelData.body || ""
                            sub: true
                            px: 11
                            width: parent.width
                            elide: Text.ElideRight
                        }
                        Row {
                            visible: actRep.count > 0
                            spacing: 4
                            Repeater {
                                id: actRep
                                model: modelData.actions
                                BarButton {
                                    required property var modelData
                                    implicitWidth: Math.max(52, actLabel.implicitWidth + 12)
                                    onClicked: modelData.invoke()
                                    BarText {
                                        id: actLabel
                                        text: modelData.text
                                        px: 10
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
