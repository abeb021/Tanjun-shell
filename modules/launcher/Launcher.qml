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
            visible: ShellState.launcherOpen
            color: Qt.rgba(0, 0, 0, 0.4)
            exclusionMode: ExclusionMode.Ignore
            focusable: true

            WlrLayershell.namespace: "tanjun-launcher"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            onVisibleChanged: {
                if (visible) {
                    query.text = "";
                    query.forceActiveFocus();
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: ShellState.closeMenus()
                Shortcut {
                    sequence: "Escape"
                    onActivated: ShellState.closeMenus()
                }
            }

            Rectangle {
                id: card
                width: 560
                height: Math.min(parent.height * 0.72, query.text.length ? 520 : 420)
                anchors.centerIn: parent
                color: Theme.bg
                border.width: 1
                border.color: Theme.accent
                radius: Theme.radius

                MouseArea {
                    anchors.fill: parent
                    onClicked: {}
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    Row {
                        spacing: 10
                        BarText {
                            text: "単"
                            family: Theme.fontJp
                            px: 22
                            color: Theme.accent
                        }
                        Rectangle {
                            width: 480
                            height: 28
                            color: Theme.surface
                            border.width: 1
                            border.color: Theme.accent
                            radius: Theme.radius
                            TextInput {
                                id: query
                                anchors.fill: parent
                                anchors.margins: 4
                                font.family: Theme.fontUi
                                font.pixelSize: 14
                                color: Theme.fg
                                clip: true
                                Keys.onEscapePressed: ShellState.closeMenus()
                                Keys.onDownPressed: {
                                    if (results.filtered.length === 0)
                                        return;
                                    results.currentIndex = Math.min(results.filtered.length - 1, results.currentIndex + 1);
                                }
                                Keys.onUpPressed: {
                                    if (results.filtered.length === 0)
                                        return;
                                    results.currentIndex = Math.max(0, results.currentIndex - 1);
                                }
                                Keys.onReturnPressed: {
                                    if (results.filtered.length === 0)
                                        return;
                                    const i = Math.max(0, results.currentIndex);
                                    launch(results.filtered[i]);
                                }
                                onTextChanged: results.currentIndex = 0
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: parent.height - 52
                        visible: query.text.length === 0

                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 8
                            BarText {
                                text: Time.time
                                px: 56
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            BarText {
                                text: Time.tzLabel + "  ·  " + Time.date
                                sub: true
                                px: 14
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            BarText {
                                text: Weather.text || "…"
                                px: 16
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            BarText {
                                text: Media.line.length ? (Media.player && Media.player.isPlaying ? "  " : "  ") + Media.line : "nothing playing"
                                icon: false
                                px: 13
                                color: Media.line.length ? Theme.fg : Theme.fgSub
                                width: 500
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }

                    ListView {
                        id: results
                        visible: query.text.length > 0
                        width: parent.width
                        height: parent.height - 52
                        clip: true
                        property var filtered: {
                            const q = query.text.toLowerCase();
                            const apps = DesktopEntries.applications.values;
                            if (!apps)
                                return [];
                            const out = [];
                            for (let i = 0; i < apps.length && out.length < 30; i++) {
                                const a = apps[i];
                                if (a.noDisplay)
                                    continue;
                                const n = (a.name || "").toLowerCase();
                                if (!q || n.indexOf(q) >= 0)
                                    out.push(a);
                            }
                            return out;
                        }
                        model: filtered
                        currentIndex: 0
                        highlightMoveDuration: 0
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: results.width
                            height: 40
                            color: results.currentIndex === index || ma.containsMouse ? Theme.surfaceHover : "transparent"
                            radius: Theme.radius
                            border.width: results.currentIndex === index ? 1 : 0
                            border.color: Theme.accent
                            BarText {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                text: modelData.name
                                px: 13
                            }
                            MouseArea {
                                id: ma
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    results.currentIndex = index;
                                    launch(modelData);
                                }
                            }
                        }
                    }
                }
            }

            function launch(entry) {
                if (!entry)
                    return;
                try {
                    entry.execute();
                } catch (e) {
                    Quickshell.execDetached(["gtk-launch", entry.id]);
                }
                ShellState.launcherOpen = false;
            }
        }
    }
}
