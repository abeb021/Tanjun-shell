import QtQuick
import "../widgets"
import "../../services"

// Load, memory, and cpu temperature in one small card. The two load figures get
// a hairline bar; temperature is one number and reads as text.
Face {
    id: root
    job: "pop"
    attach: true
    frosted: true
    implicitWidth: 232
    implicitHeight: col.implicitHeight + 24
    focus: true
    Keys.onEscapePressed: UiMode.closeMenus()

    readonly property real load: Math.max(0, Math.min(1, Host.cpu / 100))
    readonly property real mem: Math.max(0, Math.min(1, Host.ramRatio))
    readonly property color loadTint: Host.cpu >= 90 ? Theme.critical : (Host.cpu >= 70 ? Theme.warning : Theme.accent)
    readonly property color memTint: Host.ramRatio >= 0.9 ? Theme.critical : (Host.ramRatio >= 0.75 ? Theme.warning : Theme.accent)
    readonly property color heatTint: Host.temp >= 90 ? Theme.critical : (Host.temp >= 75 ? Theme.warning : Theme.accent)

    // The menu is the only thing on the bar that needs the sampler, so opening
    // it is what starts the tick and closing it stops the tick again.
    readonly property bool open: UiMode.popout === "stats"
    onOpenChanged: Host.menuOpen = root.open
    Component.onDestruction: Host.menuOpen = false

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 12

        PopHead {
            title: "LOAD"
            status: Host.ticking ? "LIVE" : ""
        }

        Column {
            width: parent.width
            spacing: 5

            Item {
                width: parent.width
                height: 15

                BarText {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰓅"
                    icon: true
                    px: 12
                    color: root.loadTint
                }
                BarText {
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    text: "cpu"
                    px: 11
                    family: Config.defaultFontUi
                    color: Theme.fgSub
                }
                BarText {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: Host.cpuText
                    px: 13
                    family: Config.defaultFontUi
                    color: Theme.fg
                }
            }

            VolumeBar {
                width: parent.width
                value: root.load
                fill: root.loadTint
                interactive: false
            }
        }

        Column {
            width: parent.width
            spacing: 5

            Item {
                width: parent.width
                height: 15

                BarText {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰍛"
                    icon: true
                    px: 12
                    color: root.memTint
                }
                BarText {
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    text: "ram"
                    px: 11
                    family: Config.defaultFontUi
                    color: Theme.fgSub
                }
                BarText {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: Host.ramText
                    px: 13
                    family: Config.defaultFontUi
                    color: Theme.fg
                }
            }

            VolumeBar {
                width: parent.width
                value: root.mem
                fill: root.memTint
                interactive: false
            }
        }

        // A bar implies a range you can move through, which a temperature is not.
        Item {
            width: parent.width
            height: 15
            visible: Host.hasTemp

            BarText {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "󰔏"
                icon: true
                px: 12
                color: root.heatTint
            }
            BarText {
                anchors.left: parent.left
                anchors.leftMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                text: "temp"
                px: 11
                family: Config.defaultFontUi
                color: Theme.fgSub
            }
            BarText {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: Host.tempText
                px: 13
                family: Config.defaultFontUi
                color: Theme.fg
            }
        }

        BarText {
            width: parent.width
            visible: Host.cpuTip.length > 0
            text: Host.cpuTip
            px: 9
            family: Config.defaultFontUi
            color: Theme.fgSub
            elide: Text.ElideRight
        }
    }
}
