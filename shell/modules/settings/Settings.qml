import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../widgets"
import "../../services"
import "fuzzy.js" as Fuzzy

Scope {
    Variants {
        model: Quickshell.screens

            OverlayHost {
            id: win
            required property var modelData
            screen: modelData
            open: UiMode.settingsOpen
            layerName: "tanjun-settings"
            grabKeys: Compositor.isScreenFocused(modelData)
            contentOpacity: card.opacity

            readonly property bool isFocused: Compositor.isScreenFocused(modelData)
            readonly property string page: SettingsNav.page
            property string face: "ui"
            property string query: ""
            readonly property bool looking: query.length > 0
            readonly property var catalog: SettingsNav.catalog
            readonly property var hits: looking ? Fuzzy.rank(query, catalog) : []
            property var fonts: []

            onOpenChanged: if (open) {
                face = "ui";
                query = "";
                find.text = "";
                Qt.callLater(resetRestScroll);
                openWork.restart();
            } else {
                openWork.stop();
                Net.setScanning(false);
                Bt.scan(false);
            }

            readonly property string pageTitle: page.toUpperCase()
            readonly property string restSrc: {
                if (page === "system")
                    return "SystemPage.qml";
                if (page === "sound")
                    return "SoundPage.qml";
                if (page === "network")
                    return "NetworkPage.qml";
                if (page === "bluetooth")
                    return "BluetoothPage.qml";
                if (page === "screen")
                    return "ScreenPage.qml";
                if (page === "clock")
                    return "ClockPage.qml";
                if (page === "weather")
                    return "WeatherPage.qml";
                if (page === "devices")
                    return "DevicesPage.qml";
                if (page === "style")
                    return "StylePage.qml";
                if (page === "color")
                    return "ColorPage.qml";
                return "";
            }

            onPageChanged: {
                resetRestScroll();
                if (page !== "type")
                    fonts = [];
                if (open)
                    openWork.restart();
                Qt.callLater(resetRestScroll);
            }

            function resetRestScroll() {
                if (!restFlick)
                    return;
                restFlick.contentY = 0;
                restFlick.returnToBounds();
                SettingsNav.scrollY = 0;
            }

            Timer {
                id: openWork
                interval: 1
                onTriggered: win.warmPage()
            }

            function warmPage() {
                if (!open)
                    return;
                if (page === "screen")
                    Screens.refresh();
                if (page === "network")
                    Net.setScanning(true);
                else
                    Net.setScanning(false);
                if (page === "bluetooth" && Bt.on)
                    Bt.scan(true);
                else
                    Bt.scan(false);
                if (page === "type" && !fonts.length) {
                    fontsProc.running = false;
                    Qt.callLater(() => {
                        fontsProc.running = true;
                    });
                }
            }

            Shortcut {
                sequence: "Escape"
                enabled: open
                onActivated: {
                    if (win.query.length) {
                        win.clearLookup();
                        return;
                    }
                    UiMode.closeMenus();
                }
            }

            Shortcut {
                sequence: "Ctrl+K"
                enabled: open
                onActivated: find.forceActiveFocus()
            }

            Shortcut {
                sequence: "Ctrl+F"
                enabled: open
                onActivated: find.forceActiveFocus()
            }

            SettingsCard {
                id: card
                open: win.open
                width: Math.min(980, parent.width - 80)
                height: Math.min(640, parent.height - 80)
                anchors.centerIn: parent

                Item {
                    anchors.fill: parent

                    Column {
                        id: sidebar
                        width: 220
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        spacing: 22

                        Text {
                            text: "SETTINGS"
                            color: Theme.fg
                            font.family: Config.defaultFontUi
                            font.pixelSize: 20
                            font.letterSpacing: Theme.brandTracking
                            font.weight: Font.DemiBold
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Theme.hairline
                        }

                        Rectangle {
                            width: parent.width
                            height: 28
                            color: Theme.surface
                            border.width: 1
                            border.color: find.activeFocus || win.looking ? Theme.accent : Theme.hairline
                            radius: Theme.radius
                            BarText {
                                visible: !find.text.length
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 8
                                text: "Search…"
                                sub: true
                                px: 12
                                family: Config.defaultFontUi
                            }
                            TextInput {
                                id: find
                                anchors.fill: parent
                                anchors.margins: 6
                                font.family: Config.defaultFontUi
                                font.pixelSize: 12
                                color: Theme.fg
                                clip: true
                                onTextChanged: win.query = text
                                Keys.onEscapePressed: {
                                    if (text.length)
                                        win.clearLookup();
                                    else
                                        UiMode.closeMenus();
                                }
                                Keys.onReturnPressed: win.takeHit(0)
                                Keys.onEnterPressed: win.takeHit(0)
                            }
                        }

                        Flickable {
                            width: parent.width
                            height: Math.max(0, sidebar.height - y)
                            clip: true
                            contentWidth: width
                            contentHeight: railCol.implicitHeight
                            boundsBehavior: Flickable.StopAtBounds
                            flickDeceleration: 8000

                            Column {
                                id: railCol
                                width: parent.width
                                spacing: 4
                                Repeater {
                                    id: railRep
                                    model: SettingsNav.pages.length
                                    onCountChanged: SettingsNav.railCount = count
                                    Item {
                                        required property int index
                                        width: sidebar.width
                                        height: 38
                                        RailBtn {
                                            width: parent.width
                                            modelData: SettingsNav.pages[index]
                                            current: win.page === SettingsNav.pages[index].key
                                            onClicked: SettingsNav.openPage(SettingsNav.pages[index].key)
                                        }
                                    }
                                }
                                onImplicitHeightChanged: SettingsNav.railH = Math.round(implicitHeight)
                                Component.onCompleted: {
                                    SettingsNav.railCount = railRep.count;
                                    SettingsNav.railH = Math.round(implicitHeight);
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: railLine
                        width: 1
                        anchors.left: sidebar.right
                        anchors.leftMargin: 28
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        color: Theme.hairline
                    }

                    Item {
                        anchors.left: railLine.right
                        anchors.leftMargin: 28
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        clip: true

                        ListView {
                                visible: win.looking
                                anchors.fill: parent
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds
                                flickDeceleration: 8000
                                model: win.hits
                                delegate: Rectangle {
                                    required property int index
                                    required property var modelData
                                    width: ListView.view.width
                                    height: 32
                                    color: hitHover.containsMouse ? Theme.surfaceHover : "transparent"
                                    border.width: 0
                                    radius: Theme.radius
                                    BarText {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.leftMargin: 8
                                        text: modelData.title
                                        px: 13
                                        family: Config.defaultFontUi
                                    }
                                    BarText {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.rightMargin: 8
                                        text: modelData.sub || ""
                                        sub: true
                                        px: 11
                                        family: Config.defaultFontUi
                                    }
                                    MouseArea {
                                        id: hitHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: win.goHit(modelData)
                                    }
                                }
                            }

                        Item {
                            id: pageBody
                            visible: !win.looking
                            anchors.fill: parent
                            clip: true

                            Column {
                                id: pageHead
                                width: parent.width
                                spacing: 12

                                Text {
                                    text: win.pageTitle
                                    color: Theme.fg
                                    font.family: Config.defaultFontUi
                                    font.pixelSize: 18
                                    font.letterSpacing: Theme.titleTracking
                                    font.weight: Font.DemiBold
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 1
                                    color: Theme.hairline
                                }
                            }

                            TypePage {
                                visible: win.page === "type"
                                anchors.top: pageHead.bottom
                                anchors.topMargin: 16
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                face: win.face
                                fonts: win.fonts
                                onFacePicked: face => win.face = face
                                onFontPicked: (which, name) => win.setFont(which, name)
                                onSizeNudge: delta => win.nudgePx(delta)
                                onResetRequested: win.resetType()
                            }

                            Flickable {
                                id: restFlick
                                visible: win.page !== "type"
                                anchors.top: pageHead.bottom
                                anchors.topMargin: 16
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                clip: true
                                flickableDirection: Flickable.VerticalFlick
                                contentWidth: width
                                contentHeight: restPage.item ? restPage.item.implicitHeight : 0
                                boundsBehavior: Flickable.StopAtBounds
                                flickDeceleration: 8000
                                maximumFlickVelocity: 5000
                                onVisibleChanged: if (visible)
                                    win.resetRestScroll()
                                onContentYChanged: if (win.isFocused)
                                    SettingsNav.scrollY = Math.round(contentY)

                                Loader {
                                    id: restPage
                                    width: parent.width
                                    height: item ? item.implicitHeight : 0
                                    active: restFlick.visible && win.restSrc.length > 0
                                    source: active ? win.restSrc : ""
                                    onLoaded: win.resetRestScroll()
                                    onItemChanged: win.resetRestScroll()
                                    onStatusChanged: if (status === Loader.Ready || status === Loader.Null)
                                        win.resetRestScroll()
                                }
                            }
                        }
                    }
                }
            }

            Process {
                id: fontsProc
                command: ["bash", "-c", "fc-list : family | cut -d',' -f1 | sed 's/^ *//;s/ *$//' | sort -u"]
                running: false
                stdout: StdioCollector {
                    onStreamFinished: win.fonts = text.split("\n").filter(l => l.length)
                }
            }

            function clearLookup() {
                query = "";
                find.text = "";
            }

            function goHit(row) {
                if (!row)
                    return;
                if (row.page)
                    SettingsNav.openPage(row.page);
                if (row.face)
                    face = row.face;
                if (row.name === "wall")
                    Theme.setTheme("wall", "wall");
                else if (row.kind && row.name)
                    Theme.setTheme(row.kind, row.name);
                clearLookup();
            }

            function takeHit(i) {
                const h = hits;
                if (!h || !h.length || i < 0 || i >= h.length)
                    return;
                goHit(h[i]);
            }

            function setFont(which, name) {
                if (which === "ui")
                    Config.appearance.fontUi = name === Config.defaultFontUi ? "" : name;
                else if (which === "jp")
                    Config.appearance.fontJp = name === Config.defaultFontJp ? "" : name;
                else
                    Config.appearance.fontIcons = name === Config.defaultFontIcons ? "" : name;
                Config.writeSparse();
            }

            function nudgePx(delta) {
                const cur = Theme.fontPx;
                const n = Math.max(11, Math.min(18, cur + delta));
                Config.appearance.fontPx = n === Config.defaultFontPx ? 0 : n;
                Config.writeSparse();
            }

            function resetType() {
                Config.appearance.fontUi = "";
                Config.appearance.fontJp = "";
                Config.appearance.fontIcons = "";
                Config.appearance.fontPx = 0;
                Config.writeSparse();
            }
        }
    }
}
