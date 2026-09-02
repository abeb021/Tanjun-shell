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
            visible: ShellState.launcherOpen
            color: Qt.rgba(0, 0, 0, 0.4)
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
                onClicked: ShellState.launcherOpen = false
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
                                Keys.onEscapePressed: ShellState.launcherOpen = false
                                Keys.onReturnPressed: {
                                    if (results.filtered.length > 0)
                                        launch(results.filtered[0]);
                                }
                                Component.onCompleted: forceActiveFocus()
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
                                text: Time.date
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
                                const n = (a.name || "").toLowerCase();
                                if (!q || n.indexOf(q) >= 0)
                                    out.push(a);
                            }
                            return out;
                        }
                        model: filtered
                        delegate: Rectangle {
                            required property var modelData
                            width: results.width
                            height: 40
                            color: ma.containsMouse ? Theme.surfaceHover : "transparent"
                            radius: Theme.radius
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
                                onClicked: launch(modelData)
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
