import QtQuick
import "../widgets"
import "../../services"

Column {
    id: page
    width: parent.width
    spacing: 16

    readonly property int toggleRightGap: {
        if (!btSwitch.parent)
            return -1;
        const p = btSwitch.parent.mapToItem(page, btSwitch.parent.width, 0);
        return Math.round(page.width - p.x);
    }
    readonly property int toggleRadius: Math.round(btSwitch.radius)

    SetHead {
        title: "BLUETOOTH"
        desc: !Bt.adapter
            ? "No adapter."
            : (!Bt.on ? "Off." : (Bt.scanning ? "Scanning…" : "Click a device to act."))

        BarText {
            anchors.verticalCenter: parent.verticalCenter
            text: "󰑐"
            px: 20
            family: Config.defaultFontUi
            color: Bt.scanning ? Theme.accent : Theme.fgSub
            opacity: Bt.on ? 1 : 0.4
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
            id: btSwitch
            anchors.verticalCenter: parent.verticalCenter
            on: Bt.on
            onToggled: Bt.toggle()
        }
    }

    SetEmpty {
        visible: !Bt.adapter
        icon: "󰂲"
        title: "NO BLUETOOTH ADAPTER"
        hint: "Nothing to connect."
    }

    SetEmpty {
        visible: Bt.adapter && !Bt.on
        icon: "󰂲"
        title: "BLUETOOTH IS OFF"
        hint: "Turn it on to see devices."
    }

    Repeater {
        model: Bt.devices
        SetRow {
            required property var modelData
            active: Bt.connected(modelData)
            clickable: true
            icon: "󰂯"
            label: modelData.name || modelData.address
            sub: {
                const parts = [modelData.address || ""];
                if (Bt.connected(modelData))
                    parts.push("connected");
                else if (modelData.paired)
                    parts.push("paired");
                if (modelData.batteryAvailable)
                    parts.push(`${Math.round(modelData.battery * 100)}%`);
                return parts.filter(p => `${p}`.length).join("  ·  ");
            }
            onClicked: Bt.act(modelData)
            BarText {
                text: Bt.label(modelData).toUpperCase()
                px: 9
                family: Config.defaultFontUi
                font.letterSpacing: 1
                color: Bt.connected(modelData) ? Theme.critical : Theme.accent
            }
        }
    }
}
