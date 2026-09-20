import QtQuick
import Quickshell
import "../widgets"
import "../../services"

Column {
    width: parent.width
    spacing: 20

    Row {
        width: parent.width
        height: pfp.status === Image.Ready ? 150 : implicitHeight
        spacing: 24

        Image {
            id: pfp
            width: 140
            height: 140
            visible: status === Image.Ready
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            asynchronous: true
            source: {
                const h = Quickshell.env("HOME") || "";
                return h.length ? `file://${h}/.config/fastfetch/pfp3.png` : "";
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14
            Repeater {
                model: [
                    { k: "󰒋  HOSTNAME", v: Host.hostName || Host.user },
                    { k: "󰣇  OS", v: Host.distro },
                    { k: "󰔛  UPTIME", v: Host.uptime }
                ]
                Column {
                    required property var modelData
                    visible: `${modelData.v || ""}`.length > 0
                    spacing: 3
                    BarText {
                        text: modelData.k
                        px: 10
                        color: Theme.accent
                        family: Theme.fontIcons
                        font.letterSpacing: 2
                    }
                    BarText {
                        text: modelData.v
                        px: 13
                        family: Config.defaultFontUi
                    }
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: 28
        Repeater {
            model: [
                { k: "󰍛  CPU", v: Host.cpuModel || Host.cpuTip },
                { k: "󰢮  GPU", v: Host.gpu },
                { k: "󰘚  MEMORY", v: Host.ramText },
                { k: "󰋊  STORAGE", v: Host.disk }
            ]
            Column {
                required property var modelData
                visible: `${modelData.v || ""}`.length > 0
                width: parent.width
                spacing: 10
                BarText {
                    text: modelData.k
                    px: 12
                    color: Theme.accent
                    family: Theme.fontIcons
                    font.letterSpacing: 2
                }
                BarText {
                    text: modelData.v
                    px: 12
                    family: Config.defaultFontUi
                    width: parent.width
                    elide: Text.ElideRight
                }
            }
        }
    }
}
