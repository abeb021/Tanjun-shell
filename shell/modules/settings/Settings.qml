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
            keepMapped: true
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
            readonly property int pageIndex: {
                const rows = SettingsNav.pages;
                for (let i = 0; i < rows.length; i++) {
                    if (rows[i].key === page)
                        return i;
                }
                return 0;
            }
            readonly property string pageAbout: {
                const rows = SettingsNav.pages;
                return pageIndex < rows.length ? `${rows[pageIndex].about || ""}` : "";
            }
            property int hitIndex: 0
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
                if (page === "battery")
                    return "BatteryPage.qml";
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
                width: Math.min(1040, parent.width - 80)
                height: Math.min(680, parent.height - 80)
                anchors.centerIn: parent

                Item {
                    anchors.fill: parent

                    Item {
                        id: sidebar
                        width: 212
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom

                        Row {
                            id: brand
                            width: parent.width
                            height: 38
                            spacing: 10

                            BarText {
                                visible: Theme.tan.length > 0
                                width: visible ? 26 : 0
                                anchors.verticalCenter: parent.verticalCenter
                                text: Theme.tan
                                role: "seal"
                                px: 22
                            }
                            BarText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "TANJUN"
                                px: 12
                                font.letterSpacing: Theme.brandTracking
                                font.weight: Font.DemiBold
                                color: Theme.fg
                            }
                        }

                        Rectangle {
                            id: brandRule
                            width: parent.width
                            height: 1
                            anchors.top: brand.bottom
                            anchors.topMargin: 10
                            color: Theme.hairline
                        }

                        Flickable {
                            id: railFlick
                            anchors.top: brandRule.bottom
                            anchors.topMargin: 10
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            clip: true
                            contentWidth: width
                            contentHeight: railCol.implicitHeight
                            boundsBehavior: Flickable.StopAtBounds
                            flickDeceleration: 8000

                            Column {
                                id: railCol
                                width: parent.width
                                spacing: 2
                                Repeater {
                                    id: railRep
                                    model: SettingsNav.pages.length
                                    onCountChanged: SettingsNav.railCount = count
                                    Item {
                                        id: railRow
                                        required property int index
                                        readonly property var entry: SettingsNav.pages[index]
                                        width: sidebar.width
                                        height: 34

                                        RailBtn {
                                            anchors.fill: parent
                                            modelData: railRow.entry
                                            current: win.page === railRow.entry.key
                                            onClicked: {
                                                win.clearLookup();
                                                SettingsNav.openPage(railRow.entry.key);
                                            }
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
                        WheelScroll {
                            anchors.fill: railFlick
                            flick: railFlick
                        }
                    }

                    Rectangle {
                        id: railLine
                        width: 1
                        anchors.left: sidebar.right
                        anchors.leftMargin: 24
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        color: Theme.hairline
                    }

                    Item {
                        id: main
                        anchors.left: railLine.right
                        anchors.leftMargin: 24
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        clip: true

                        Column {
                            id: pageHead
                            width: parent.width
                            spacing: 0

                            Item {
                                width: parent.width
                                height: 42

                                Text {
                                    id: pageTitleText
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: win.looking ? "RESULTS" : win.pageTitle
                                    color: Theme.fg
                                    font.family: Config.defaultFontUi
                                    font.pixelSize: Math.min(30, Math.round(Theme.fontPx * 1.85))
                                    font.letterSpacing: Theme.titleTracking
                                    font.weight: Font.DemiBold
                                }

                                Rectangle {
                                    id: searchBox
                                    width: Math.max(180, Math.min(260, parent.width * 0.38))
                                    height: 34
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    radius: Theme.radius
                                    color: Theme.surface
                                    border.width: 1
                                    border.color: find.activeFocus || win.looking ? Theme.accent : Theme.hairline

                                    BarText {
                                        visible: !find.text.length
                                        anchors.left: parent.left
                                        anchors.leftMargin: 30
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "SEARCH"
                                        px: 11
                                        color: Theme.fgSub
                                    }

                                    Row {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 8
                                        spacing: 7

                                        BarText {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "󰍉"
                                            icon: true
                                            px: 13
                                            color: find.activeFocus || win.looking ? Theme.accent : Theme.fgSub
                                        }

                                        TextInput {
                                            id: find
                                            width: parent.width - 20 - 14 - (clear.visible ? clear.width + 6 : 0)
                                            anchors.verticalCenter: parent.verticalCenter
                                            font.family: Config.defaultFontUi
                                            font.pixelSize: 12
                                            color: Theme.fg
                                            clip: true
                                            onTextChanged: {
                                                win.query = text;
                                                win.hitIndex = 0;
                                            }
                                            Keys.onEscapePressed: {
                                                if (text.length)
                                                    win.clearLookup();
                                                else
                                                    UiMode.closeMenus();
                                            }
                                            Keys.onDownPressed: win.moveHit(1)
                                            Keys.onUpPressed: win.moveHit(-1)
                                            Keys.onReturnPressed: win.takeHit(win.hitIndex)
                                            Keys.onEnterPressed: win.takeHit(win.hitIndex)
                                        }

                                        BarText {
                                            id: clear
                                            visible: win.looking
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "✕"
                                            icon: true
                                            px: 9
                                            color: clearHover.containsMouse ? Theme.accent : Theme.fgSub
                                            MouseArea {
                                                id: clearHover
                                                anchors.fill: parent
                                                anchors.margins: -4
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: win.clearLookup()
                                            }
                                        }
                                    }
                                }
                            }

                            BarText {
                                width: parent.width
                                height: 18
                                text: win.looking
                                    ? (win.hits.length ? `${win.hits.length} MATCH${win.hits.length === 1 ? "" : "ES"}  ·  “${win.query.toUpperCase()}”` : `NO MATCHES  ·  “${win.query.toUpperCase()}”`)
                                    : win.pageAbout
                                px: Theme.typeCaption
                                family: Config.defaultFontUi
                                color: Theme.fgSub
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                width: parent.width
                                height: 1
                                color: Theme.hairline
                            }
                        }

                        ListView {
                            id: hitList
                            visible: win.looking
                            anchors.top: pageHead.bottom
                            anchors.topMargin: 10
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            flickDeceleration: 8000
                            model: win.hits
                            delegate: Rectangle {
                                id: hitRow
                                required property int index
                                required property var modelData
                                width: hitList.width
                                height: 38
                                radius: Theme.radius
                                color: index === win.hitIndex ? Theme.hot : (hitHover.containsMouse ? Theme.hotSoft : "transparent")

                                Rectangle {
                                    visible: hitRow.index === win.hitIndex
                                    width: 2
                                    height: 16
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: Theme.accent
                                }
                                BarText {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: hitRow.modelData.title
                                    px: 12
                                    family: Config.defaultFontUi
                                }
                                BarText {
                                    anchors.right: parent.right
                                    anchors.rightMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: win.hitLabel(hitRow.modelData)
                                    px: 9
                                    family: Config.defaultFontUi
                                    font.letterSpacing: 1
                                    color: Theme.fgSub
                                }
                                MouseArea {
                                    id: hitHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: win.hitIndex = hitRow.index
                                    onClicked: win.goHit(hitRow.modelData)
                                }
                            }
                        }
                        WheelScroll {
                            anchors.fill: hitList
                            flick: hitList
                            visible: hitList.visible
                        }

                        Item {
                            id: pageBody
                            visible: !win.looking
                            anchors.top: pageHead.bottom
                            anchors.topMargin: 18
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            clip: true

                            TypePage {
                                visible: win.page === "type"
                                anchors.top: parent.top
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
                                anchors.top: parent.top
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

                                Binding {
                                    target: SettingsNav
                                    property: "toggleGap"
                                    when: restFlick.visible
                                    value: (win.page === "network" || win.page === "bluetooth") && restPage.item ? restPage.item.toggleRightGap : -1
                                }

                                Binding {
                                    target: SettingsNav
                                    property: "toggleRadius"
                                    when: restFlick.visible
                                    value: (win.page === "network" || win.page === "bluetooth") && restPage.item ? restPage.item.toggleRadius : -1
                                }
                            }
                            WheelScroll {
                                anchors.fill: restFlick
                                flick: restFlick
                                visible: restFlick.visible
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
                hitIndex = 0;
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

            function moveHit(delta) {
                const n = hits ? hits.length : 0;
                if (!n)
                    return;
                hitIndex = (hitIndex + delta + n) % n;
                hitList.positionViewAtIndex(hitIndex, ListView.Contain);
            }

            function hitLabel(row) {
                if (!row || !row.page)
                    return `${row && row.sub ? row.sub : ""}`.toUpperCase();
                const rows = SettingsNav.pages;
                for (let i = 0; i < rows.length; i++) {
                    if (rows[i].key === row.page)
                        return rows[i].label.toUpperCase();
                }
                return `${row.sub || ""}`.toUpperCase();
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
