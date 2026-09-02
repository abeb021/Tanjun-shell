import QtQuick
import Quickshell
import "../bar"
import "../../services"

Rectangle {
    id: root
    color: Theme.surface
    border.width: 1
    border.color: Theme.bg
    radius: Theme.radius
    implicitWidth: 280
    implicitHeight: col.implicitHeight + 16
    focus: true
    Keys.onEscapePressed: ShellState.closeMenus()

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
        anchors.margins: 10
        spacing: 8

        BarText {
            text: Time.date
            px: 12
        }

        Row {
            spacing: 16
            Column {
                BarText {
                    text: Time.timeMoscow
                    px: 22
                }
                BarText {
                    text: "Moscow"
                    sub: true
                    px: 11
                }
            }
            Column {
                BarText {
                    text: Time.timeMelbourne
                    px: 22
                    color: Time.tzId === "Australia/Melbourne" ? Theme.accent : Theme.fg
                }
                BarText {
                    text: "Melbourne"
                    sub: true
                    px: 11
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.bg
        }

        Row {
            width: parent.width
            BarButton {
                implicitWidth: 28
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
                width: parent.width - 56
                text: Qt.formatDateTime(new Date(root.viewYear, root.viewMonth, 1), "MMMM yyyy")
                px: 12
                horizontalAlignment: Text.AlignHCenter
            }
            BarButton {
                implicitWidth: 28
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
                    width: 36
                    text: modelData
                    sub: true
                    px: 10
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
                    required property int index
                    width: 36
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
