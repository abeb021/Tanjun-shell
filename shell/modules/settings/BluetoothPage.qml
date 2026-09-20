import QtQuick
import "../widgets"
import "../../services"

Column {
    id: page
    width: parent.width
    spacing: 18

    Row {
        width: parent.width
        height: 30
        spacing: 16

        Item {
            width: Math.max(0, parent.width - 44 - 28 - 16)
            height: 1
        }

        BarText {
            id: scanIcon
            text: "󰑐"
            px: 22
            family: Config.defaultFontUi
            color: Bt.scanning ? Theme.accent : Theme.fgSub
            opacity: Bt.on ? 1 : 0.4
            anchors.verticalCenter: parent.verticalCenter
            RotationAnimation on rotation {
                running: Bt.scanning
                loops: Animation.Infinite
                from: 0
                to: 360
                duration: 1600
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Bt.scan(!Bt.scanning)
            }
        }

        HudToggle {
            anchors.verticalCenter: parent.verticalCenter
            on: Bt.on
            onToggled: Bt.toggle()
        }
    }

    Item {
        width: parent.width
        height: 100
        visible: !Bt.adapter
        BarText {
            anchors.centerIn: parent
            text: "NO BLUETOOTH ADAPTER"
            px: 11
            family: Config.defaultFontUi
            color: Theme.fgSub
            font.letterSpacing: 1
        }
    }

    Item {
        width: parent.width
        height: 100
        visible: Bt.adapter && !Bt.on
        Column {
            anchors.centerIn: parent
            spacing: 8
            BarText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "󰂲"
                icon: true
                px: 24
                color: Theme.fgSub
            }
            BarText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "BLUETOOTH IS OFF"
                px: 11
                family: Config.defaultFontUi
                color: Theme.fgSub
                font.letterSpacing: 1
            }
            BarText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Turn it on to see devices."
                px: 9
                family: Config.defaultFontUi
                color: Theme.fgSub
            }
        }
    }

    Repeater {
        model: Bt.devices
        HudCard {
            required property var modelData
            width: parent.width
            height: 52
            active: Bt.connected(modelData)
            Row {
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                BarText {
                    text: "󰂯"
                    icon: true
                    px: 15
                    color: Bt.connected(modelData) ? Theme.accent : Theme.fgSub
                    anchors.verticalCenter: parent.verticalCenter
                }
                Column {
                    spacing: 2
                    anchors.verticalCenter: parent.verticalCenter
                    BarText {
                        text: modelData.name || modelData.address
                        px: 12
                        family: Config.defaultFontUi
                        elide: Text.ElideRight
                        width: Math.max(100, page.width - 210)
                    }
                    BarText {
                        text: {
                            const parts = [modelData.address || ""];
                            if (Bt.connected(modelData))
                                parts.push("connected");
                            else if (modelData.paired)
                                parts.push("paired");
                            if (modelData.batteryAvailable)
                                parts.push(`${Math.round(modelData.battery * 100)}%`);
                            return parts.filter(p => `${p}`.length).join("  ·  ");
                        }
                        px: 9
                        family: Config.defaultFontUi
                        color: Bt.connected(modelData) ? Theme.accent : Theme.fgSub
                    }
                }
            }
            BarText {
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: Bt.label(modelData).toUpperCase()
                px: 10
                family: Config.defaultFontUi
                color: Bt.connected(modelData) ? Theme.critical : Theme.accent
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Bt.act(modelData)
                }
            }
        }
    }
}
