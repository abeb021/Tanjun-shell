import QtQuick
import Quickshell
import Quickshell.Networking
import "../widgets"
import "../../services"

Face {
    id: root
    job: "pop"
    attach: true
    frosted: true
    implicitWidth: 290
    // The list is empty until the radio answers, and the panel must not grow after
    // it has rolled out: reserve the tallest size seen this session and let the
    // rows fill an already-final panel.
    readonly property real contentH: col.implicitHeight + 24
    property real floorH: 0
    onContentHChanged: if (contentH > floorH) floorH = contentH
    implicitHeight: Math.min(Math.max(contentH, floorH), 440)
    focus: true

    KeyCatcher {
        id: catcher
        anchors.fill: parent
        focus: true
        count: Net.networks ? Net.networks.length : 0
        onCancel: UiMode.closeMenus()
        onPick: i => {
            const list = Net.networks;
            if (!list || i < 0 || i >= list.length)
                return;
            const n = list[i];
            if (n.connected)
                n.disconnect();
            else
                n.connect();
        }

        Flickable {
            anchors.fill: parent
            anchors.margins: 12
            contentWidth: width
            contentHeight: col.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: col
                width: parent.width
                spacing: 10

                PopHead {
                    icon: "󰖩"
                    status: Net.connected ? Net.ssid : (Net.wifiOn ? "ON" : "OFF")
                }

                PopRow {
                    icon: Net.wifiOn ? "󰖩" : "󰖪"
                    clickable: true
                    onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                    BarText {
                        text: Net.wifiOn ? "ON" : "OFF"
                        px: 9
                        family: Config.defaultFontUi
                        font.letterSpacing: 1
                        color: Net.wifiOn ? Theme.accent : Theme.fgSub
                    }
                }

                PopRow {
                    visible: Net.vpnUp
                    icon: "󰖂"
                    label: Net.vpn
                    active: true
                }

                BarText {
                    visible: Net.wifiOn && Net.networks.length === 0
                    width: parent.width
                    topPadding: 6
                    horizontalAlignment: Text.AlignHCenter
                    text: "SCANNING"
                    px: 10
                    family: Config.defaultFontUi
                    font.letterSpacing: 1
                    color: Theme.fgSub
                }

                Repeater {
                    model: Net.networks
                    PopRow {
                        required property var modelData
                        required property int index
                        active: modelData.connected || catcher.currentIndex === index
                        clickable: true
                        icon: Net.signalIcon(modelData)
                        label: modelData.name || "hidden"
                        onClicked: {
                            if (modelData.connected)
                                modelData.disconnect();
                            else
                                modelData.connect();
                        }

                        BarText {
                            visible: Net.secured(modelData)
                            text: "󰌾"
                            icon: true
                            px: 10
                            color: Theme.fgSub
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: UiMode
        function onPopoutChanged() {
            Net.setScanning(UiMode.popout === "network");
            if (UiMode.popout === "network")
                catcher.forceActiveFocus();
        }
    }
}
