import QtQuick
import "../widgets"
import "../../services"

Column {
    id: page
    width: parent.width
    spacing: 16
    property string pending: ""
    property string pw: ""

    readonly property int toggleRightGap: {
        if (!wifiSwitch.parent)
            return -1;
        const p = wifiSwitch.parent.mapToItem(page, wifiSwitch.parent.width, 0);
        return Math.round(page.width - p.x);
    }
    readonly property int toggleRadius: Math.round(wifiSwitch.radius)

    SetHead {
        title: "WI-FI"
        desc: !Net.wifiOn
            ? "Disabled."
            : (Net.networks.length > 0 ? "Click a network to connect." : "Scanning nearby networks…")

        BarText {
            anchors.verticalCenter: parent.verticalCenter
            text: "󰑐"
            px: 20
            family: Config.defaultFontUi
            color: Net.wifiOn ? Theme.accent : Theme.fgSub
            opacity: Net.wifiOn ? 1 : 0.4
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

    SetRow {
        visible: Net.vpnUp
        icon: "󰖂"
        label: "VPN"
        sub: Net.vpn
        active: true
    }

    SetEmpty {
        visible: !Net.wifiOn
        icon: ""
        title: "WI-FI IS OFF"
        hint: "Turn it on to see networks."
    }

    SetEmpty {
        visible: Net.wifiOn && Net.networks.length === 0
        icon: "󰑐"
        title: "NO NETWORKS"
        hint: "Scanning nearby."
    }

    Repeater {
        model: Net.networks
        Column {
            id: netRow
            required property var modelData
            readonly property string netKey: modelData.name || ""
            width: page.width
            spacing: 6

            SetRow {
                active: modelData.connected
                clickable: true
                icon: ""
                label: modelData.name || "hidden"
                onClicked: {
                    if (modelData.connected) {
                        page.pending = "";
                        Net.connectNet(modelData, "");
                        return;
                    }
                    page.pending = page.pending === netRow.netKey ? "" : netRow.netKey;
                    page.pw = "";
                }
                BarText {
                    text: modelData.connected ? "DISCONNECT" : "CONNECT"
                    px: 9
                    family: Config.defaultFontUi
                    font.letterSpacing: 1
                    color: modelData.connected ? Theme.critical : Theme.accent
                }
            }

            SetField {
                id: pwField
                visible: page.pending === netRow.netKey && !modelData.connected
                echoMode: TextInput.Password
                placeholder: "Password"
                action: "CONNECT"
                onVisibleChanged: if (!visible) {
                    clear();
                    page.pw = "";
                }
                onEdited: v => page.pw = v
                onAccepted: {
                    Net.connectNet(modelData, page.pw);
                    page.pw = "";
                    page.pending = "";
                }
                onTriggered: {
                    Net.connectNet(modelData, page.pw);
                    page.pw = "";
                    page.pending = "";
                }
            }
        }
    }
}
