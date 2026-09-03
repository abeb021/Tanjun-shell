import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../widgets"
import "../../services"

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: ShellState.clipboardOpen || card.opacity > 0.02
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            focusable: true

            readonly property bool open: ShellState.clipboardOpen

            WlrLayershell.namespace: "tanjun-clipboard"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            onOpenChanged: if (open)
                clips.forceActiveFocus()

            Shortcut {
                sequence: "Escape"
                enabled: open
                onActivated: ShellState.closeMenus()
            }

            MouseArea {
                anchors.fill: parent
                enabled: open
                onClicked: ShellState.closeMenus()
            }

            Face {
                id: card
                job: "plane"
                width: 560
                height: 440
                anchors.centerIn: parent
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
                    highlightResizeDuration: 0
                    reuseItems: true
                    cacheBuffer: 200
                    maximumFlickVelocity: 12000
                    flickDeceleration: 3500
                    boundsBehavior: Flickable.StopAtBounds
                    Keys.onEscapePressed: ShellState.closeMenus()
                    Keys.onReturnPressed: copyCurrent()
                    Keys.onEnterPressed: copyCurrent()
                    Keys.onDownPressed: clips.incrementCurrentIndex()
                    Keys.onUpPressed: clips.decrementCurrentIndex()

                    WheelHandler {
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        onWheel: event => {
                            const delta = event.pixelDelta.y !== 0 ? event.pixelDelta.y * 2.8 : event.angleDelta.y * 2.4;
                            const maxY = Math.max(0, clips.contentHeight - clips.height);
                            clips.contentY = Math.max(0, Math.min(maxY, clips.contentY - delta));
                            event.accepted = true;
                        }
                    }

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
                        Rectangle {
                            visible: clips.currentIndex === index
                            width: 1
                            height: parent.height - 10
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.accent
                        }

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
                                cache: true
                                sourceSize: Qt.size(64, 64)
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
