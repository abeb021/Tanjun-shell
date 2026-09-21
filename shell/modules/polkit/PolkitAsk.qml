import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Polkit
import "../widgets"
import "../../services"

Scope {
    PolkitAgent {
        id: agent
    }

    Variants {
        model: Quickshell.screens

        OverlayHost {
            id: win
            required property var modelData
            screen: modelData
            open: agent.isActive
            layerName: "tanjun-polkit"
            grabKeys: Compositor.isScreenFocused(modelData)
            holdExclusive: true
            contentOpacity: card.opacity
            dismissOthers: false

            readonly property var flow: agent.flow

            onOpenChanged: if (open)
                reply.forceActiveFocus()

            onDismissed: {
                if (win.flow)
                    win.flow.cancelAuthenticationRequest();
            }

            Face {
                id: card
                job: "plane"
                width: 420
                height: col.implicitHeight + 28
                anchors.centerIn: parent
                opacity: win.open ? 1 : 0

                MouseArea {
                    anchors.fill: parent
                    onClicked: {}
                }

                Column {
                    id: col
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Theme.pad
                    spacing: Theme.gap

                    BarText {
                        text: Theme.tan
                        role: "seal"
                    }
                    BarText {
                        width: parent.width
                        wrapMode: Text.Wrap
                        text: win.flow && win.flow.message ? win.flow.message : "auth"
                        px: Theme.typeBody
                    }
                    BarText {
                        visible: !!(win.flow && win.flow.inputPrompt)
                        width: parent.width
                        text: win.flow ? win.flow.inputPrompt : ""
                        sub: true
                        px: Theme.typeCaption
                    }
                    Rectangle {
                        width: parent.width
                        height: 28
                        visible: !!(win.flow && win.flow.isResponseRequired)
                        color: Theme.bg
                        border.width: 1
                        border.color: Theme.hairline
                        radius: Theme.radius
                        TextInput {
                            id: reply
                            anchors.fill: parent
                            anchors.margins: 6
                            color: Theme.fg
                            font.family: Theme.fontUi
                            font.pixelSize: Theme.fontPx
                            echoMode: win.flow && win.flow.responseVisible ? TextInput.Normal : TextInput.Password
                            onAccepted: {
                                if (!win.flow)
                                    return;
                                win.flow.submit(text);
                                text = "";
                            }
                            Keys.onEscapePressed: {
                                if (win.flow)
                                    win.flow.cancelAuthenticationRequest();
                            }
                        }
                    }
                    Row {
                        spacing: 8
                        BarButton {
                            implicitWidth: 72
                            onClicked: {
                                if (!win.flow)
                                    return;
                                win.flow.submit(reply.text);
                                reply.text = "";
                            }
                            BarText {
                                text: "ok"
                                px: 11
                            }
                        }
                        BarButton {
                            implicitWidth: 72
                            onClicked: {
                                if (win.flow)
                                    win.flow.cancelAuthenticationRequest();
                            }
                            BarText {
                                text: "cancel"
                                px: 11
                            }
                        }
                    }
                }
            }
        }
    }
}
