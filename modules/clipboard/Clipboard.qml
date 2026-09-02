import QtQuick
import Quickshell
import Quickshell.Io
import "../bar"
import "../../services"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: ShellState.clipboardOpen
            color: Qt.rgba(0, 0, 0, 0.35)
            exclusionMode: ExclusionMode.Ignore
            focusable: true

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: ShellState.clipboardOpen = false
            }

            Rectangle {
                width: 520
                height: 420
                anchors.centerIn: parent
                color: Theme.bg
                border.width: 1
                border.color: Theme.accent
                radius: Theme.radius

                ListView {
                    id: clips
                    anchors.fill: parent
                    anchors.margins: 12
                    clip: true
                    model: clipModel
                    delegate: Rectangle {
                        required property string line
                        width: clips.width
                        height: 36
                        color: ma.containsMouse ? Theme.surfaceHover : "transparent"
                        BarText {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.margins: 8
                            width: parent.width - 16
                            text: line
                            elide: Text.ElideRight
                            px: 12
                        }
                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                Quickshell.execDetached(["bash", "-c", `printf '%s\\n' ${shellQuote(line)} | cliphist decode | wl-copy`]);
                                ShellState.clipboardOpen = false;
                            }
                        }
                    }
                }
            }

            Process {
                id: clipProc
                running: ShellState.clipboardOpen
                command: ["cliphist", "list"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const lines = text.split("\n").filter(l => l.length);
                        clipModel.clear();
                        for (let i = 0; i < Math.min(lines.length, 40); i++)
                        clipModel.append({ line: lines[i] });
                    }
                }
            }

            ListModel {
                id: clipModel
            }

            function shellQuote(s) {
                return "'" + s.replace(/'/g, "'\\''") + "'";
            }
        }
    }
}
