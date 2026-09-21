pragma ComponentBehavior: Bound
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import "../widgets"
import "../../services"

Item {
    id: picker
    property bool open: false
    property url currentFolder: Theme.wallFolder

    readonly property string home: Quickshell.env("HOME") || ""

    signal picked(string path)
    signal canceled

    visible: open
    z: 40

    onOpenChanged: if (open && !UiMode.wallFolder.length)
        currentFolder = ownWalls.count > 0 ? Theme.wallFolder : Qt.url("file://" + Theme.wallDirLegacy)

    Connections {
        target: UiMode
        function onWallFolderChanged() {
            if (!UiMode.wallFolder.length)
                return;
            const p = UiMode.wallFolder;
            picker.currentFolder = Qt.url(p.startsWith("file:") ? p : ("file://" + p));
        }
        function onWallsOpenChanged() {
            if (UiMode.wallsOpen && UiMode.wallFolder.length) {
                const p = UiMode.wallFolder;
                picker.currentFolder = Qt.url(p.startsWith("file:") ? p : ("file://" + p));
            }
        }
    }

    function prettyPath(u) {
        return `${u}`.replace("file://", "").replace(home, "~");
    }

    function goHome(sub) {
        UiMode.setWallFolder(home + (sub.length ? "/" + sub : ""));
    }

    MouseArea {
        anchors.fill: parent
        onClicked: picker.canceled()
    }

    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 720)
        height: Math.min(parent.height - 48, 560)
        color: Theme.surface
        border.width: 1
        border.color: Theme.hairline
        radius: Theme.radius

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        BarText {
            id: title
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.leftMargin: 14
            anchors.topMargin: 12
            text: "walls"
            px: 13
        }
        BarText {
            anchors.left: title.left
            anchors.top: title.bottom
            anchors.topMargin: 2
            anchors.right: closeBtn.left
            anchors.rightMargin: 8
            text: picker.prettyPath(picker.currentFolder)
            sub: true
            px: 11
            elide: Text.ElideLeft
        }
        BarButton {
            id: closeBtn
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: 8
            anchors.topMargin: 8
            implicitWidth: 48
            onClicked: picker.canceled()
            BarText {
                text: "close"
                px: 11
            }
        }

        Row {
            id: nav
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: title.bottom
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            anchors.topMargin: 28
            spacing: 4
            BarButton {
                implicitWidth: 44
                onClicked: if (fm.parentFolder.toString().length)
                    UiMode.setWallFolder(Theme.urlPath(`${fm.parentFolder}`))
                BarText {
                    text: "up"
                    px: 11
                }
            }
            BarButton {
                implicitWidth: 72
                onClicked: UiMode.setWallFolder(Theme.wallDir)
                BarText {
                    text: "walls"
                    px: 11
                }
            }
            BarButton {
                implicitWidth: 72
                onClicked: UiMode.setWallFolder(Theme.wallDirLegacy)
                BarText {
                    text: "rice"
                    px: 11
                }
            }
            BarButton {
                implicitWidth: 84
                onClicked: picker.goHome("Pictures")
                BarText {
                    text: "Pictures"
                    px: 11
                }
            }
            BarButton {
                implicitWidth: 108
                onClicked: picker.goHome("Pictures/Wallpapers")
                BarText {
                    text: "Wallpapers"
                    px: 11
                }
            }
        }

        FolderListModel {
            id: ownWalls
            folder: Theme.wallFolder
            showDirs: true
            showDotAndDotDot: false
            showHidden: false
        }

        FolderListModel {
            id: fm
            folder: picker.currentFolder
            showDirs: true
            showDirsFirst: true
            showDotAndDotDot: false
            showHidden: false
            nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp", "*.gif", "*.mp4", "*.webm", "*.mkv", "*.mov", "*.m4v"]
            sortField: FolderListModel.Name
        }

        GridView {
            id: grid
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: nav.bottom
            anchors.bottom: sampleBtn.top
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.topMargin: 10
            anchors.bottomMargin: 6
            clip: true
            cacheBuffer: 240
            reuseItems: true
            boundsBehavior: Flickable.StopAtBounds
            readonly property int cols: Math.max(2, Math.floor(width / 168))
            cellWidth: Math.floor(width / cols)
            cellHeight: Math.round(cellWidth * 0.72)
            model: fm

            delegate: Item {
                id: tile
                required property string fileName
                required property url fileUrl
                required property bool fileIsDir
                readonly property bool isVideo: {
                    const n = String(tile.fileName).toLowerCase();
                    return n.endsWith(".mp4") || n.endsWith(".webm") || n.endsWith(".mkv") || n.endsWith(".mov") || n.endsWith(".m4v");
                }
                width: grid.cellWidth
                height: grid.cellHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    color: Theme.bg
                    border.width: 1
                    border.color: hover.hovered ? Theme.accent : Theme.surfaceHover
                    radius: Theme.radius
                    clip: true

                    BarText {
                        visible: tile.fileIsDir
                        anchors.centerIn: parent
                        text: "󰉋"
                        icon: true
                        px: 22
                        color: Theme.fgSub
                    }
                    BarText {
                        visible: tile.fileIsDir
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 6
                        text: tile.fileName
                        px: 10
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideMiddle
                    }

                    Image {
                        visible: !tile.fileIsDir && !tile.isVideo
                        anchors.fill: parent
                        asynchronous: true
                        cache: false
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(Math.ceil(width * 1.4), Math.ceil(height * 1.4))
                        source: tile.fileIsDir || tile.isVideo ? "" : tile.fileUrl
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity {
                            enabled: Motion.ready
                            NumberAnimation {
                                duration: Motion.fast
                            }
                        }
                    }
                    BarText {
                        visible: !tile.fileIsDir && tile.isVideo
                        anchors.centerIn: parent
                        text: "󰎁"
                        icon: true
                        px: 22
                        color: Theme.fgSub
                    }
                    BarText {
                        visible: !tile.fileIsDir && tile.isVideo
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 6
                        text: tile.fileName
                        px: 10
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideMiddle
                    }

                    Rectangle {
                        visible: !tile.fileIsDir && hover.hovered
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 18
                        color: Theme.bg
                        BarText {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            text: tile.fileName
                            px: 10
                            elide: Text.ElideMiddle
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    HoverHandler {
                        id: hover
                        cursorShape: Qt.PointingHandCursor
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (tile.fileIsDir)
                                UiMode.setWallFolder(Theme.urlPath(`${tile.fileUrl}`));
                            else
                                picker.picked(`${tile.fileUrl}`);
                        }
                    }
                }
            }
        }

        BarButton {
            id: sampleBtn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 10
            implicitHeight: 28
            active: Config.theme.sampleWall
            onClicked: {
                Config.theme.sampleWall = !Config.theme.sampleWall;
                Config.writeSparse();
            }
            BarText {
                text: Config.theme.sampleWall ? "colors · pull" : "colors · keep"
                px: 11
            }
        }

        BarText {
            visible: fm.status === FolderListModel.Ready && fm.count === 0
            anchors.centerIn: grid
            text: "empty"
            sub: true
            px: 12
        }
    }
}
