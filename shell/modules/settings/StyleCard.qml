import QtQuick
import "../widgets"
import "../../services"

// A miniature of the shell drawn with the style's own tokens.
//
// Every mark here is a token from Theme that this style actually flips, so the
// preview cannot drift from the real look: a chip border that is not drawn here
// is not drawn anywhere, and vice versa. The card the preview sits on describes
// what changes in words, the picture shows the change.
Rectangle {
    id: root

    property string kind: ""
    property string label: ""
    property string blurb: ""

    // The tokens of the style being previewed, not the one in use. These mirror
    // the panelStyle ternaries in Theme.qml; keeping them beside the drawing is
    // what makes the picture honest instead of aspirational.
    readonly property bool panel: kind === "chrome" || kind === "panel"
    readonly property bool current: Theme.style === kind

    readonly property color tAccent: Theme.accent
    readonly property color tBg: Theme.bg
    readonly property color tSurface: Theme.surface
    readonly property color tFg: Theme.fg
    readonly property color tFgSub: Theme.fgSub
    readonly property color tHairline: Theme.hairline
    readonly property color tChip: panel ? Theme.wash(Theme.accent, 0.10) : Theme.surfaceHover
    readonly property color tHot: panel ? Theme.wash(Theme.accent, 0.10) : Theme.surfaceHover
    readonly property color tBorder: panel ? Theme.accent : Theme.hairline
    readonly property int tChipBorder: panel ? 1 : 0
    readonly property int tThumb: panel ? 12 : 8
    readonly property bool tRail: panel
    readonly property bool tPip: panel
    readonly property bool tGlow: panel
    readonly property bool tPill: panel

    width: parent.width
    implicitHeight: 152
    height: implicitHeight
    radius: Theme.radius
    color: current ? Theme.wash(Theme.accent, 0.06) : (hover.containsMouse ? Theme.surfaceHover : "transparent")
    border.width: 1
    border.color: current || hover.containsMouse ? Theme.accent : Theme.hairline
    Behavior on color {
        enabled: Motion.ready
        ColorAnimation {
            duration: Motion.fast
        }
    }
    Behavior on border.color {
        enabled: Motion.ready
        ColorAnimation {
            duration: Motion.fast
        }
    }

    signal clicked

    // The miniature: a bar strip, a rail chip, a slider and a card edge, which
    // between them cover every token a style flips.
    Item {
        id: preview
        width: 232
        height: 112
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter

        // The window behind: a bar on top, content below.
        Rectangle {
            id: frame
            anchors.fill: parent
            color: root.tBg
            border.width: 1
            border.color: root.tBorder
            radius: Theme.radius
        }

        // The bar strip and its inner rule. Chrome draws a faint accent line on
        // the inner edge; minimal has none.
        Item {
            id: strip
            x: 1
            width: parent.width - 2
            height: 16

            Rectangle {
                anchors.fill: parent
                color: root.tBg
            }
            Rectangle {
                visible: root.panel
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: Theme.wash(root.tAccent, 0.22)
            }
            Rectangle {
                // A desk number with the active marker. Chrome puts a 2px pip on
                // the left of the button, minimal underlines it instead.
                width: 16
                height: strip.height
                x: 4
                color: "transparent"

                Rectangle {
                    visible: root.tPip
                    width: 2
                    height: parent.height - 6
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    color: root.tAccent
                }
                Rectangle {
                    visible: !root.tPip
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 2
                    anchors.rightMargin: 2
                    height: 1
                    color: root.tAccent
                }
                Rectangle {
                    width: 8
                    height: 2
                    anchors.centerIn: parent
                    color: root.tFg
                }
            }
            // The clock, in the middle.
            Rectangle {
                width: 22
                height: 2
                anchors.centerIn: parent
                color: root.tFgSub
            }
        }

        // A rail chip: the settings list. Chrome draws a 2px mark at the left of
        // the current row; minimal leaves it bare.
        Item {
            id: rail
            x: 8
            y: strip.height + 8
            width: parent.width - 16
            height: 18

            Rectangle {
                anchors.fill: parent
                color: root.tHot
                radius: Theme.radius
            }
            Rectangle {
                visible: root.tRail
                width: 2
                height: parent.height - 8
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                color: root.tAccent
            }
            Rectangle {
                width: 30
                height: 2
                x: 10
                anchors.verticalCenter: parent.verticalCenter
                color: root.tAccent
            }
        }

        // A chip button: bordered in Chrome, plain in minimal.
        Rectangle {
            id: chip
            x: 8
            y: rail.y + rail.height + 7
            width: 46
            height: 16
            radius: Theme.radius
            color: root.tChip
            border.width: root.tChipBorder
            border.color: root.tAccent
            Rectangle {
                width: 24
                height: 2
                anchors.centerIn: parent
                color: root.tAccent
            }
        }

        // The slider: a rounded thumb in Chrome, a thin bar in minimal, with the
        // glow ring only where the style draws one.
        Item {
            x: 8
            y: chip.y + chip.height + 7
            width: parent.width - 16
            height: 10

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: root.panel ? 6 : 4
                radius: 2
                color: root.tSurface
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * 0.5
                height: root.panel ? 6 : 4
                radius: 2
                color: root.tAccent
                Rectangle {
                    visible: root.tGlow
                    anchors.fill: parent
                    anchors.margins: -2
                    radius: 4
                    color: "transparent"
                    border.width: 2
                    border.color: Theme.wash(root.tAccent, 0.35)
                }
            }
            Rectangle {
                width: root.tThumb
                height: root.tThumb
                radius: root.tPill ? root.tThumb / 2 : Theme.radius
                anchors.verticalCenter: parent.verticalCenter
                x: parent.width * 0.5 - width / 2
                color: root.tAccent
                border.width: 1
                border.color: root.tBg
            }
        }
    }

    Column {
        anchors.left: preview.right
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 16
        anchors.rightMargin: 14
        spacing: 6

        BarText {
            text: root.label
            px: 14
            family: Config.defaultFontUi
            color: root.current ? Theme.accent : Theme.fg
        }
        BarText {
            text: root.blurb
            px: 11
            family: Config.defaultFontUi
            color: Theme.fgSub
            width: parent.width
            wrapMode: Text.Wrap
        }
        BarText {
            visible: root.current
            text: "SELECTED"
            role: "head"
        }
    }

    MouseArea {
        id: hover
        z: 2
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
