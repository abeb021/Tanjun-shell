import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
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

            WlrLayershell.namespace: "tanjun-clipboard"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            onVisibleChanged: if (visible)
                clips.forceActiveFocus()

            MouseArea {
                anchors.fill: parent
                onClicked: ShellState.closeMenus()
                Shortcut {
                    sequence: "Escape"
                    onActivated: ShellState.closeMenus()
                }
            }

            Rectangle {
                width: 560
                height: 440
                anchors.centerIn: parent
                color: Theme.bg
                border.width: 1
                border.color: Theme.accent
                radius: Theme.radius

                MouseArea {
                    anchors.fill: parent
                    onClicked: {}
                }

                ListView {
                    id: clips
                    anchors.fill: parent
                    anchors.margins: 12
                    clip: true
                    spacing: 4
                    model: clipModel
                    currentIndex: 0
                    keyNavigationWraps: true
                    highlightMoveDuration: 0
                    Keys.onEscapePressed: ShellState.closeMenus()
                    Keys.onReturnPressed: copyCurrent()
                    Keys.onEnterPressed: copyCurrent()

                    delegate: Rectangle {
                        id: row
                        required property string line
                        required property int index
                        readonly property bool pic: /\[\[\s*binary/i.test(line) || /\b(png|jpe?g|webp|gif|bmp)\b/i.test(line)
                        readonly property string preview: line.indexOf("\t") >= 0 ? line.slice(line.indexOf("\t") + 1) : line
                        width: clips.width
                        height: row.pic ? 76 : 36
                        color: clips.currentIndex === index || ma.containsMouse ? Theme.surfaceHover : "transparent"
                        radius: Theme.radius
                        border.width: clips.currentIndex === index ? 1 : 0
                        border.color: Theme.accent

                        Row {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 8

                            Image {
                                visible: row.pic
                                width: 64
                                height: 64
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                source: decoded.path.length ? `file://${decoded.path}` : ""
                            }

                            BarText {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - (row.pic ? 72 : 0)
                                text: row.pic ? "image" : row.preview
                                elide: Text.ElideRight
                                px: 12
                            }
                        }

                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                clips.currentIndex = row.index;
                                copyLine(row.line);
                            }
                        }

                        Process {
                            id: decoded
                            property string path: ""
                            running: row.pic && ShellState.clipboardOpen
                            command: ["bash", `${Quickshell.shellDir}/scripts/clip-decode.sh`, row.line]
                            stdout: StdioCollector {
                                onStreamFinished: decoded.path = text.trim()
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
                            clipModel.append({
                                line: lines[i]
                            });
                        clips.currentIndex = 0;
                    }
                }
            }

            ListModel {
                id: clipModel
            }

            function shellQuote(s) {
                return "'" + String(s).replace(/'/g, "'\\''") + "'";
            }

            function copyLine(line) {
                if (!line)
                    return;
                Quickshell.execDetached(["bash", "-c", `printf '%s\\n' ${shellQuote(line)} | cliphist decode | wl-copy`]);
                ShellState.closeMenus();
            }

            function copyCurrent() {
                if (clips.currentIndex < 0 || clips.currentIndex >= clipModel.count)
                    return;
                copyLine(clipModel.get(clips.currentIndex).line);
            }
        }
    }
}
