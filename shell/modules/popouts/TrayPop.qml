import QtQuick
import Quickshell
import "../widgets"
import "../../services"

Face {
    id: root
    job: "pop"
    attach: true
    frosted: true
    implicitWidth: 260
    implicitHeight: Math.min(col.implicitHeight + 24, 440)
    focus: true

    property var stack: []
    readonly property var handle: {
        if (stack.length)
            return stack[stack.length - 1];
        return UiMode.trayItem ? UiMode.trayItem.menu : null;
    }
    readonly property string title: {
        if (stack.length)
            return root.labelOf(stack[stack.length - 1].text);
        const it = UiMode.trayItem;
        return it ? root.labelOf(it.tooltipTitle || it.title || "TRAY") : "TRAY";
    }

    Keys.onEscapePressed: {
        if (root.stack.length)
            root.stack = root.stack.slice(0, -1);
        else
            UiMode.closeMenus();
    }

    function labelOf(s) {
        return `${s || ""}`.replace(/_([^_])/g, "$1").replace(/__/g, "_");
    }

    function mark(entry) {
        const t = root.labelOf(entry.text);
        if (entry.hasChildren)
            return t.length ? t + "  ▸" : "▸";
        if (!entry.buttonType)
            return t;
        const on = entry.checkState === Qt.Checked;
        return (on ? "●  " : "○  ") + t;
    }

    Connections {
        target: UiMode
        function onTrayItemChanged() {
            root.stack = [];
        }
        function onPopoutChanged() {
            if (UiMode.popout !== "tray")
                root.stack = [];
        }
    }

    QsMenuOpener {
        id: opener
        menu: root.handle
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
            spacing: 2

            PopHead {
                title: root.title
                status: root.stack.length > 0 ? "BACK" : ""
                BarText {
                    visible: root.stack.length > 0
                    anchors.verticalCenter: parent.verticalCenter
                    text: "◂"
                    px: 14
                    color: Theme.accent
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.stack = root.stack.slice(0, -1)
                    }
                }
            }

            Item {
                width: parent.width
                height: 6
            }

            Repeater {
                id: menuRep
                model: opener.children
                delegate: Item {
                    required property var modelData
                    width: col.width
                    // A separator has its own height; a row's comes from the row,
                    // which now exposes implicitHeight. Reading a height it did
                    // not have collapsed every label to zero while the separators
                    // stayed, leaving a menu of blank gaps.
                    implicitHeight: modelData.isSeparator ? 9 : row.implicitHeight

                    Rectangle {
                        visible: modelData.isSeparator
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 1
                        color: Theme.hairline
                    }

                    PopRow {
                        id: row
                        visible: !modelData.isSeparator
                        width: parent.width
                        label: root.mark(modelData)
                        active: modelData.checkState === Qt.Checked
                        dimmed: !modelData.enabled
                        clickable: modelData.enabled
                        onClicked: {
                            if (modelData.hasChildren) {
                                root.stack = root.stack.concat([modelData]);
                                return;
                            }
                            modelData.triggered();
                            UiMode.closeMenus();
                        }
                    }
                }
            }

            BarText {
                visible: menuRep.count === 0 && root.stack.length === 0
                width: parent.width
                topPadding: 6
                horizontalAlignment: Text.AlignHCenter
                text: {
                    const it = UiMode.trayItem;
                    if (!it)
                        return "";
                    return root.labelOf(it.tooltipTitle || it.title || "");
                }
                px: 10
                family: Config.defaultFontUi
                color: Theme.fgSub
                elide: Text.ElideRight
            }
        }
    }
}
