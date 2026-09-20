import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../widgets"
import "../../services"

Scope {
    Variants {
        model: Quickshell.screens

        OverlayHost {
            id: win
            required property var modelData
            screen: modelData
            open: UiMode.clipboardOpen
            layerName: "tanjun-clipboard"
            contentOpacity: card.opacity
            property var thumbs: ({})
            property int thumbGen: 0

            function clipKey(line) {
                const id = `${line || ""}`.split("\t")[0].replace(/[^0-9]/g, "");
                return id;
            }

            function isPic(line) {
                return /\[\[\s*binary/i.test(line) || /\b(png|jpe?g|webp|gif|bmp)\b/i.test(line);
            }

            function thumbOf(line) {
                thumbGen;
                const k = clipKey(line);
                const p = k.length ? (thumbs[k] || "") : "";
                return p.length ? `file://${p}` : "";
            }

            function decodeAt(index) {
                if (index < 0 || index >= clipModel.count)
                    return;
                const row = clipModel.get(index);
                if (!row || !isPic(row.line))
                    return;
                const k = clipKey(row.line);
                if (!k.length || thumbs[k])
                    return;
                decodeProc.command = ["bash", `${Quickshell.shellDir}/scripts/clip-decode.sh`, row.line];
                decodeProc.running = false;
                Qt.callLater(() => {
                    decodeProc.running = true;
                });
            }

            onOpenChanged: {
                if (open) {
                    clips.forceActiveFocus();
                    gcProc.running = false;
                    gcProc.running = true;
                }
            }

            Shortcut {
                sequence: "Escape"
                enabled: open
                onActivated: UiMode.closeMenus()
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
                    onCurrentIndexChanged: win.decodeAt(currentIndex)
                    maximumFlickVelocity: 12000
                    flickDeceleration: 3500
                    boundsBehavior: Flickable.StopAtBounds
                    Keys.onEscapePressed: UiMode.closeMenus()
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
                                source: win.thumbOf(row.line)
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
                    }
                }
            }

            Process {
                id: gcProc
                command: ["bash", `${Quickshell.shellDir}/scripts/clip-decode.sh`, "--gc"]
                running: false
            }

            Process {
                id: decodeProc
                running: false
                stdout: StdioCollector {
                    onStreamFinished: {
                        const p = text.trim();
                        if (!p.length)
                            return;
                        const bits = p.split("/");
                        const k = bits[bits.length - 1];
                        if (!k.length)
                            return;
                        win.thumbs[k] = p;
                        win.thumbGen++;
                    }
                }
            }

            Process {
                id: clipProc
                running: UiMode.clipboardOpen
                command: ["cliphist", "list"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const lines = text.split("\n").filter(l => l.length);
                        clipModel.clear();
                        win.thumbs = ({});
                        win.thumbGen++;
                        for (let i = 0; i < Math.min(lines.length, 40); i++)
                            clipModel.append({
                                line: lines[i]
                            });
                        clips.currentIndex = 0;
                        win.decodeAt(0);
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
                UiMode.closeMenus();
            }

            function copyCurrent() {
                if (clips.currentIndex < 0 || clips.currentIndex >= clipModel.count)
                    return;
                copyLine(clipModel.get(clips.currentIndex).line);
            }
        }
    }
}
