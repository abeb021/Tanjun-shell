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
            open: ShellState.settingsOpen
            layerName: "tanjun-settings"
            grabKeys: Compositor.isScreenFocused(modelData)
            contentOpacity: card.opacity

            readonly property bool isFocused: Compositor.isScreenFocused(modelData)
            readonly property string page: ShellState.settingsPage
            property string face: "ui"
            property string query: ""
            readonly property bool looking: query.length > 0
            readonly property var catalog: {
                const out = [
                    { title: "system", sub: "page", page: "system", hay: "system host os kernel cpu gpu ram disk uptime" },
                    { title: "sound", sub: "page", page: "sound", hay: "sound volume mute output mic mixer apps" },
                    { title: "network", sub: "page", page: "network", hay: "network wifi ssid vpn scan" },
                    { title: "bluetooth", sub: "page", page: "bluetooth", hay: "bluetooth buds adapter scan pair" },
                    { title: "type", sub: "page", page: "type", hay: "type font ui japanese icons size reset" },
                    { title: "ui font", sub: "type", page: "type", face: "ui", hay: "ui font jetbrains mono typeface" },
                    { title: "japanese font", sub: "type", page: "type", face: "jp", hay: "japanese font noto sans cjk jp 単" },
                    { title: "icons font", sub: "type", page: "type", face: "icons", hay: "icons font nerd symbols" },
                    { title: "clock", sub: "page", page: "clock", hay: "clock timezone 12 24 hour" },
                    { title: "Moscow", sub: "clock", page: "clock", hay: "moscow europe/moscow timezone clock" },
                    { title: "Melbourne", sub: "clock", page: "clock", hay: "melbourne australia/melbourne timezone clock" },
                    { title: "12 hour", sub: "clock", page: "clock", hay: "12 hour am pm clock" },
                    { title: "24 hour", sub: "clock", page: "clock", hay: "24 hour clock" },
                    { title: "weather", sub: "page", page: "weather", hay: "weather city wttr moscow" },
                    { title: "devices", sub: "page", page: "devices", hay: "devices backlight keyboard intel_backlight" },
                    { title: "intel_backlight", sub: "devices", page: "devices", hay: "intel_backlight brightness light" },
                    { title: "screen", sub: "page", page: "screen", hay: "screen monitor display scale gamma output edp brightness layout first second extend" },
                    { title: "scale", sub: "screen", page: "screen", hay: "scale 1.2 fractional scaling monitor" },
                    { title: "gamma", sub: "screen", page: "screen", hay: "gamma hyprsunset night identity" },
                    { title: "style", sub: "page", page: "style", hay: "style chrome panel tanjun look shell rail ticks" },
                    { title: "Tanjun", sub: "style", page: "style", hay: "tanjun quiet plane rice chrome" },
                    { title: "Panel", sub: "style", page: "style", hay: "panel chrome ticks chips marked rail" },
                    { title: "color", sub: "page", page: "color", hay: "color theme palette preset" },
                    { title: "From wall", sub: "color", page: "color", kind: "wall", name: "wall", hay: "from wall wallpaper accent sample" },
                    { title: "keep palette", sub: "color", page: "color", hay: "keep palette wallpaper colors pull sample" }
                ];
                const p = Theme.presets;
                for (let i = 0; i < p.length; i++) {
                    const t = p[i];
                    out.push({
                        title: t.label,
                        sub: "color",
                        page: "color",
                        kind: t.kind,
                        name: t.name,
                        hay: `${t.label} ${t.name} ${t.kind} color theme palette`
                    });
                }
                return out;
            }
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
                if (open)
                    openWork.restart();
                Qt.callLater(resetRestScroll);
            }

            function resetRestScroll() {
                if (!restFlick)
                    return;
                restFlick.contentY = 0;
                restFlick.returnToBounds();
                ShellState.settingsScrollY = 0;
            }

            Timer {
                id: openWork
                interval: 1
                onTriggered: win.warmPage()
            }

            function warmPage() {
                if (!open)
                    return;
                if (page === "system")
                    Host.refresh();
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
                    ShellState.closeMenus();
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
                                        ShellState.closeMenus();
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
                                    model: ShellState.settingsPages.length
                                    onCountChanged: ShellState.settingsRailCount = count
                                    Item {
                                        required property int index
                                        width: sidebar.width
                                        height: 38
                                        RailBtn {
                                            width: parent.width
                                            modelData: ShellState.settingsPages[index]
                                            current: win.page === ShellState.settingsPages[index].key
                                            onClicked: ShellState.openSettingsPage(ShellState.settingsPages[index].key)
                                        }
                                    }
                                }
                                onImplicitHeightChanged: ShellState.settingsRailH = Math.round(implicitHeight)
                                Component.onCompleted: {
                                    ShellState.settingsRailCount = railRep.count;
                                    ShellState.settingsRailH = Math.round(implicitHeight);
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

                            Item {
                                visible: win.page === "type"
                                anchors.top: pageHead.bottom
                                anchors.topMargin: 16
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom

                                Column {
                                    id: typeHead
                                    width: parent.width
                                    spacing: 12
                                    BarText {
                                        text: "FACE"
                                        role: "head"
                                    }
                                    Row {
                                        width: parent.width
                                        spacing: 10
                                        Repeater {
                                            model: [
                                                { id: "ui", label: "UI" },
                                                { id: "jp", label: "JAPANESE" },
                                                { id: "icons", label: "ICONS" }
                                            ]
                                            HudPick {
                                                required property var modelData
                                                width: (parent.width - 20) / 3
                                                label: modelData.label
                                                current: win.face === modelData.id
                                                onClicked: win.face = modelData.id
                                            }
                                        }
                                    }
                                    BarText {
                                        text: "Empty = default"
                                        px: 11
                                        family: Config.defaultFontUi
                                        color: Theme.fgSub
                                        width: parent.width
                                        wrapMode: Text.Wrap
                                    }
                                }

                                Row {
                                    id: typeSize
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    spacing: 10
                                    BarText {
                                        text: "SIZE  " + Theme.fontPx
                                        role: "head"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    HudPick {
                                        width: 42
                                        implicitHeight: 32
                                        height: 32
                                        label: "−"
                                        onClicked: win.nudgePx(-1)
                                    }
                                    HudPick {
                                        width: 42
                                        implicitHeight: 32
                                        height: 32
                                        label: "+"
                                        onClicked: win.nudgePx(1)
                                    }
                                    HudPick {
                                        width: 88
                                        implicitHeight: 32
                                        height: 32
                                        label: "RESET"
                                        onClicked: win.resetType()
                                    }
                                }

                                FontPick {
                                    anchors.top: typeHead.bottom
                                    anchors.topMargin: 8
                                    anchors.bottom: typeSize.top
                                    anchors.bottomMargin: 8
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    title: win.face === "jp" ? "JAPANESE" : (win.face === "icons" ? "ICONS" : "UI")
                                    current: win.face === "jp" ? Theme.fontJp : (win.face === "icons" ? Theme.fontIcons : Theme.fontUi)
                                    pins: [win.face === "jp" ? Config.defaultFontJp : (win.face === "icons" ? Config.defaultFontIcons : Config.defaultFontUi)]
                                    sample: win.face === "jp" ? "単 純 あ い" : (win.face === "icons" ? "  󰃠 " : "Aa Bb 12")
                                    families: win.fonts
                                    onChosen: win.setFont(win.face, name)
                                }
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
                                    ShellState.settingsScrollY = Math.round(contentY)

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
                    ShellState.openSettingsPage(row.page);
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
