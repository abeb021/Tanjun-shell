import QtQuick
import "../widgets"
import "../../services"

Column {
    id: page
    width: parent.width
    spacing: 12
    property string pending: ""
    property string pw: ""

    Row {
        width: parent.width
        height: 28
        spacing: 16

        Item {
            width: Math.max(0, parent.width - 44 - 28 - 16)
            height: 1
        }

        BarText {
            text: "󰑐"
            px: 22
            family: Config.defaultFontUi
            color: Theme.accent
            opacity: Net.wifiOn ? 1 : 0.4
            anchors.verticalCenter: parent.verticalCenter
            MouseArea {
                anchors.fill: parent
                enabled: Net.wifiOn
                cursorShape: Qt.PointingHandCursor
                onClicked: Net.setScanning(true)
            }
        }

        HudToggle {
            anchors.verticalCenter: parent.verticalCenter
            on: Net.wifiOn
            onToggled: Net.toggleWifi()
        }
    }

    BarText {
        visible: Net.vpnUp
        text: "VPN  " + Net.vpn
        px: 12
        color: Theme.accent
        family: Config.defaultFontUi
        font.letterSpacing: 1
    }

    BarText {
        visible: !Net.wifiOn
        width: parent.width
        text: "Wi-Fi is disabled"
        px: 12
        family: Config.defaultFontUi
        color: Theme.fgSub
        horizontalAlignment: Text.AlignHCenter
    }

    BarText {
        visible: Net.wifiOn && Net.networks.length === 0
        width: parent.width
        text: "No Wi-Fi networks found"
        px: 12
        family: Config.defaultFontUi
        color: Theme.fgSub
        horizontalAlignment: Text.AlignHCenter
    }

    Repeater {
        model: Net.networks
        Column {
            required property var modelData
            width: page.width
            spacing: 6

            HudCard {
                width: parent.width
                height: 46
                active: modelData.connected
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 9
                    BarText {
                        text: ""
                        icon: true
                        px: 14
                        color: modelData.connected ? Theme.accent : Theme.fgSub
                    }
                    BarText {
                        text: modelData.name || "hidden"
                        px: 12
                        family: Config.defaultFontUi
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, page.width - 170)
                    }
                }
                BarText {
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.connected ? "DISCONNECT" : "CONNECT"
                    px: 10
                    family: Config.defaultFontUi
                    color: modelData.connected ? Theme.critical : Theme.accent
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.connected) {
                                page.pending = "";
                                Net.connectNet(modelData, "");
                                return;
                            }
                            page.pending = page.pending === modelData.name ? "" : (modelData.name || "");
                            page.pw = "";
                        }
                    }
                }
            }

            Row {
                visible: page.pending === modelData.name && !modelData.connected
                spacing: 10
                Rectangle {
                    width: 220
                    height: 32
                    color: Theme.surface
                    border.width: 1
                    border.color: Theme.accent
                    radius: Theme.radius
                    TextInput {
                        anchors.fill: parent
                        anchors.margins: 8
                        echoMode: TextInput.Password
                        font.family: Config.defaultFontUi
                        font.pixelSize: 12
                        color: Theme.fg
                        onTextChanged: page.pw = text
                        Keys.onReturnPressed: Net.connectNet(modelData, page.pw)
                        Keys.onEnterPressed: Net.connectNet(modelData, page.pw)
                    }
                }
                BarText {
                    text: "CONNECT"
                    px: 11
                    family: Config.defaultFontUi
                    color: Theme.accent
                    anchors.verticalCenter: parent.verticalCenter
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Net.connectNet(modelData, page.pw)
                    }
                }
            }
        }
    }
}
