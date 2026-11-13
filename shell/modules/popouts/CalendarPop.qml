import QtQuick
import "../widgets"
import "../../services"

Face {
    id: root
    job: "pop"
    attach: true
    frosted: true
    implicitWidth: Math.max(300, 24 + Time.zones.length * 120)
    implicitHeight: col.implicitHeight + 24
    focus: true
    Keys.onEscapePressed: UiMode.closeMenus()

    property int viewYear: Number(Qt.formatDateTime(Time.now, "yyyy"))
    property int viewMonth: Number(Qt.formatDateTime(Time.now, "M")) - 1

    readonly property var cells: {
        const first = new Date(viewYear, viewMonth, 1);
        const start = (first.getDay() + 6) % 7;
        const days = new Date(viewYear, viewMonth + 1, 0).getDate();
        const out = [];
        for (let i = 0; i < start; i++)
            out.push(0);
        for (let d = 1; d <= days; d++)
            out.push(d);
        while (out.length % 7 !== 0)
            out.push(0);
        return out;
    }

    Column {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: 10

        PopHead {
            title: "CLOCK"
            status: Time.date
        }

        Row {
            spacing: 16
            Repeater {
                model: Time.zones
                Column {
                    required property var modelData
                    spacing: 1
                    BarText {
                        text: Time.time.length ? Time.formatTime(modelData.id) : ""
                        px: 22
                        color: Time.tzId === modelData.id ? Theme.accent : Theme.fg
                    }
                    BarText {
                        text: modelData.label || Config.prettyZone(modelData.id)
                        px: 9
                        family: Config.defaultFontUi
                        font.letterSpacing: 1
                        color: Theme.fgSub
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.hairline
        }

        Row {
            width: parent.width
            BarButton {
                implicitWidth: 26
                implicitHeight: 26
                onClicked: {
                    if (root.viewMonth === 0) {
                        root.viewMonth = 11;
                        root.viewYear -= 1;
                    } else {
                        root.viewMonth -= 1;
                    }
                }
                BarText {
                    text: "‹"
                    px: 16
                }
            }
            BarText {
                width: parent.width - 52
                text: Qt.formatDateTime(new Date(root.viewYear, root.viewMonth, 1), "MMMM yyyy")
                px: 12
                family: Config.defaultFontUi
                horizontalAlignment: Text.AlignHCenter
            }
            BarButton {
                implicitWidth: 26
                implicitHeight: 26
                onClicked: {
                    if (root.viewMonth === 11) {
                        root.viewMonth = 0;
                        root.viewYear += 1;
                    } else {
                        root.viewMonth += 1;
                    }
                }
                BarText {
                    text: "›"
                    px: 16
                }
            }
        }

        Row {
            spacing: 0
            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                BarText {
                    required property string modelData
                    width: 38
                    text: modelData
                    px: 9
                    family: Config.defaultFontUi
                    font.letterSpacing: 1
                    color: Theme.fgSub
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        Grid {
            columns: 7
            Repeater {
                model: root.cells
                delegate: Item {
                    required property int modelData
                    width: 38
                    height: 28
                    readonly property bool today: {
                        const n = Time.now;
                        return modelData > 0 && Number(Qt.formatDateTime(n, "d")) === modelData && Number(Qt.formatDateTime(n, "M")) - 1 === root.viewMonth && Number(Qt.formatDateTime(n, "yyyy")) === root.viewYear;
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: 24
                        height: 24
                        radius: Theme.radius
                        color: today ? Theme.accent : "transparent"
                    }
                    BarText {
                        anchors.centerIn: parent
                        text: modelData > 0 ? `${modelData}` : ""
                        px: 11
                        color: today ? Theme.bg : Theme.fg
                    }
                }
            }
        }
    }
}
