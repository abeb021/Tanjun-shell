import QtQuick
import Quickshell
import "../widgets"
import "../../services"

Face {
    id: root
    job: "pop"
    implicitWidth: 240
    implicitHeight: Math.min(col.implicitHeight + 16, 420)
    focus: true

    property var stack: []
    readonly property var handle: {
        if (stack.length)
            return stack[stack.length - 1];
        return UiMode.trayItem ? UiMode.trayItem.menu : null;
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
        anchors.margins: 8
        contentWidth: width
        contentHeight: col.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            width: parent.width
            spacing: 2

            BarButton {
                visible: root.stack.length > 0
                implicitWidth: parent.width
                implicitHeight: 24
                onClicked: root.stack = root.stack.slice(0, -1)
                BarText {
                    text: "◂  back"
                    px: 11
                }
            }

            Repeater {
                id: menuRep
                model: opener.children
                delegate: Item {
                    required property var modelData
                    width: col.width
                    implicitHeight: modelData.isSeparator ? 9 : rowBtn.implicitHeight

                    Rectangle {
                        visible: modelData.isSeparator
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 1
                        color: Theme.hairline
                    }

                    BarButton {
                        id: rowBtn
                        visible: !modelData.isSeparator
                        implicitWidth: parent.width
                        implicitHeight: 24
                        enabled: modelData.enabled
                        onClicked: {
                            if (modelData.hasChildren) {
                                root.stack = root.stack.concat([modelData]);
                                return;
                            }
                            modelData.triggered();
                            UiMode.closeMenus();
                        }
                        BarText {
                            text: root.mark(modelData)
                            px: 12
                            color: modelData.enabled ? (modelData.checkState === Qt.Checked ? Theme.accent : Theme.fg) : Theme.fgSub
                            width: col.width - 16
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            BarText {
                visible: menuRep.count === 0 && root.stack.length === 0
                text: {
                    const it = UiMode.trayItem;
                    if (!it)
                        return "";
                    return root.labelOf(it.tooltipTitle || it.title || "");
                }
                sub: true
                px: 11
                width: parent.width
                elide: Text.ElideRight
            }
        }
    }
}
