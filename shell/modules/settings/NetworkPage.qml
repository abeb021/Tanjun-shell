import QtQuick
import "../widgets"
import "../../services"

Column {
    id: page
    width: parent.width
    spacing: 12
    property string pending: ""
    property string pw: ""
    readonly property int toggleRightGap: {
        const row = wifiSwitch.parent;
        if (!row)
            return -1;
        return Math.round(page.width - row.x - row.width);
    }
    readonly property int toggleRadius: Math.round(wifiSwitch.radius)

    Item {
        width: parent.width
        height: 28

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 8
            height: parent.height
            spacing: 16

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
                id: wifiSwitch
                anchors.verticalCenter: parent.verticalCenter
                on: Net.wifiOn
                onToggled: Net.toggleWifi()
            }
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
        Keys.onReturnPressed: {
            Net.connectNet(modelData, page.pw);
            page.pw = "";
            page.pending = "";
        }
        Keys.onEnterPressed: {
            Net.connectNet(modelData, page.pw);
            page.pw = "";
            page.pending = "";
        }
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
                        onClicked: {
                            Net.connectNet(modelData, page.pw);
                            page.pw = "";
                            page.pending = "";
                        }
                    }
                }
            }
        }
    }
}
