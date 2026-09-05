import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "../widgets"
import "../../services"
import "fuzzy.js" as Fuzzy

Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData
            screen: modelData
            visible: ShellState.settingsOpen || card.opacity > 0.02
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            focusable: true

            readonly property bool open: ShellState.settingsOpen
            readonly property bool isFocused: Compositor.isScreenFocused(modelData)
            property string page: "type"
            property string face: "ui"
            property string query: ""
            readonly property bool looking: query.length > 0
            readonly property var catalog: {
                const out = [
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
                    { title: "session", sub: "page", page: "session", hay: "session lock fingerprint password" },
                    { title: "devices", sub: "page", page: "devices", hay: "devices backlight keyboard intel_backlight" },
                    { title: "intel_backlight", sub: "devices", page: "devices", hay: "intel_backlight brightness light" },
                    { title: "screen", sub: "page", page: "screen", hay: "screen monitor display scale gamma output edp" },
                    { title: "scale", sub: "screen", page: "screen", hay: "scale 1.2 fractional scaling monitor" },
                    { title: "gamma", sub: "screen", page: "screen", hay: "gamma hyprsunset night identity" },
                    { title: "color", sub: "page", page: "color", hay: "color theme palette preset skin" },
                    { title: "From wall", sub: "color", page: "color", kind: "wall", name: "wall", hay: "from wall wallpaper accent sample" }
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
            property string zoneDraft: ""
            property string weatherDraft: Config.services.weatherCity
            property string blDraft: Config.services.backlight
            property string kbDraft: Config.services.keyboard

            WlrLayershell.namespace: "tanjun-settings"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: (open && isFocused) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            anchors {
                top: true
                left: true
                right: true
                bottom: true
            }

            onOpenChanged: if (open) {
                page = "type";
                face = "ui";
                query = "";
                find.text = "";
                weatherDraft = Config.services.weatherCity;
                blDraft = Config.services.backlight;
                kbDraft = Config.services.keyboard;
                Screens.refresh();
                fontsProc.running = false;
                Qt.callLater(() => {
                    fontsProc.running = true;
                });
                find.forceActiveFocus();
            }

            onPageChanged: restFlick.contentY = 0

            HyprlandFocusGrab {
                active: Compositor.isHypr && win.open && win.isFocused
                windows: [win]
                onCleared: if (win.open && ShellState.settingsOpen)
                    ShellState.closeMenus()
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

            MouseArea {
                anchors.fill: parent
                enabled: open
                onClicked: ShellState.closeMenus()
            }

            Face {
                id: card
                job: "plane"
                width: 720
                height: Math.min(parent.height * 0.78, 520)
                anchors.centerIn: parent
                opacity: open ? 1 : 0
                scale: open ? 1 : Motion.panelFrom

                Behavior on opacity {
                    enabled: Motion.ready
                    NumberAnimation {
                        duration: Motion.panel
                        easing.type: open ? Motion.easeOut : Motion.easeIn
                    }
                }
                Behavior on scale {
                    enabled: Motion.ready
                    NumberAnimation {
                        duration: Motion.panel
                        easing.type: open ? Motion.easeOut : Motion.easeIn
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {}
                }

                    Column {
                        anchors.fill: parent
                    anchors.margins: Theme.pad
                    spacing: Theme.gap

                    Column {
                        id: head
                        width: parent.width
                        spacing: 8

                        BarText {
                            text: "settings"
                            role: "caption"
                            family: Config.defaultFontUi
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
                    }

                    Row {
                        width: parent.width
                        height: parent.height - head.height - parent.spacing
                        spacing: 12

                        Column {
                            width: 108
                            spacing: 4
                            Repeater {
                                model: [
                                    { id: "type", label: "type" },
                                    { id: "clock", label: "clock" },
                                    { id: "weather", label: "weather" },
                                    { id: "session", label: "session" },
                                    { id: "devices", label: "devices" },
                                    { id: "screen", label: "screen" },
                                    { id: "color", label: "color" }
                                ]
                                BarButton {
                                    required property var modelData
                                    implicitWidth: 108
                                    active: win.page === modelData.id
                                    onClicked: win.page = modelData.id
                                    BarText {
                                        text: modelData.label
                                        px: 12
                                        family: Config.defaultFontUi
                                        color: win.page === modelData.id ? Theme.accent : Theme.fg
                                    }
                                }
                            }
                        }

                        Item {
                            width: parent.width - 120
                            height: parent.height

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
                                visible: !win.looking && win.page === "type"
                                anchors.fill: parent

                                Column {
                                    id: typeHead
                                    width: parent.width
                                    spacing: 8
                                    BarText {
                                        text: "empty = default"
                                        sub: true
                                        px: 11
                                        family: Config.defaultFontUi
                                        width: parent.width
                                        wrapMode: Text.Wrap
                                    }
                                    Row {
                                        spacing: 4
                                        Repeater {
                                            model: [
                                                { id: "ui", label: "ui" },
                                                { id: "jp", label: "japanese" },
                                                { id: "icons", label: "icons" }
                                            ]
                                            BarButton {
                                                required property var modelData
                                                implicitWidth: 88
                                                active: win.face === modelData.id
                                                onClicked: win.face = modelData.id
                                                BarText {
                                                    text: modelData.label
                                                    px: 12
                                                    family: Config.defaultFontUi
                                                }
                                            }
                                        }
                                    }
                                }

                                Row {
                                    id: typeSize
                                    anchors.bottom: parent.bottom
                                    spacing: 8
                                    BarText {
                                        text: "size  " + Theme.fontPx
                                        px: 12
                                        family: Config.defaultFontUi
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    BarButton {
                                        implicitWidth: 32
                                        onClicked: win.nudgePx(-1)
                                        BarText {
                                            text: "−"
                                            px: 14
                                            family: Config.defaultFontUi
                                        }
                                    }
                                    BarButton {
                                        implicitWidth: 32
                                        onClicked: win.nudgePx(1)
                                        BarText {
                                            text: "+"
                                            px: 14
                                            family: Config.defaultFontUi
                                        }
                                    }
                                    BarButton {
                                        implicitWidth: 72
                                        onClicked: win.resetType()
                                        BarText {
                                            text: "reset"
                                            px: 11
                                            family: Config.defaultFontUi
                                        }
                                    }
                                }

                                FontPick {
                                    anchors.top: typeHead.bottom
                                    anchors.topMargin: 8
                                    anchors.bottom: typeSize.top
                                    anchors.bottomMargin: 8
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    title: win.face === "jp" ? "japanese" : (win.face === "icons" ? "icons" : "ui")
                                    current: win.face === "jp" ? Theme.fontJp : (win.face === "icons" ? Theme.fontIcons : Theme.fontUi)
                                    pins: [win.face === "jp" ? Config.defaultFontJp : (win.face === "icons" ? Config.defaultFontIcons : Config.defaultFontUi)]
                                    sample: win.face === "jp" ? "単 純 あ い" : (win.face === "icons" ? "  󰃠 " : "Aa Bb 12")
                                    families: win.fonts
                                    onChosen: win.setFont(win.face, name)
                                }
                            }

                            Flickable {
                                id: restFlick
                                visible: !win.looking && win.page !== "type"
                                anchors.fill: parent
                                clip: true
                                contentWidth: width
                                contentHeight: restCol.implicitHeight
                                boundsBehavior: Flickable.StopAtBounds
                                flickDeceleration: 8000
                                maximumFlickVelocity: 5000

                                Column {
                                    id: restCol
                                    width: parent.width
                                    spacing: 12

                                Column {
                                    visible: win.page === "clock"
                                    width: parent.width
                                    spacing: 8
                                    BarButton {
                                        implicitWidth: 200
                                        onClicked: {
                                            Config.clock.twelveHour = !Config.clock.twelveHour;
                                            Config.writeSparse();
                                        }
                                        BarText {
                                            text: Config.clock.twelveHour ? "12 hour" : "24 hour"
                                            px: 12
                                        }
                                    }
                                    Row {
                                        spacing: 4
                                        BarButton {
                                            implicitWidth: 88
                                            active: win.hasZone("Europe/Moscow")
                                            onClicked: win.ensureZone("Europe/Moscow", "Moscow")
                                            BarText {
                                                text: "Moscow"
                                                px: 11
                                            }
                                        }
                                        BarButton {
                                            implicitWidth: 100
                                            active: win.hasZone("Australia/Melbourne")
                                            onClicked: win.ensureZone("Australia/Melbourne", "Melbourne")
                                            BarText {
                                                text: "Melbourne"
                                                px: 11
                                            }
                                        }
                                    }
                                    BarText {
                                        visible: !(Config.clock.zones && Config.clock.zones.length)
                                        text: Config.localLabel + "  ·  auto"
                                        sub: true
                                        px: 11
                                    }
                                    Repeater {
                                        model: Config.clock.zones && Config.clock.zones.length ? Config.clockZones : []
                                        BarButton {
                                            required property var modelData
                                            required property int index
                                            implicitWidth: restCol.width
                                            onClicked: win.dropZone(index)
                                            BarText {
                                                text: (modelData.label || modelData.id) + "  ·  remove"
                                                px: 12
                                            }
                                        }
                                    }
                                    Row {
                                        spacing: 6
                                        Rectangle {
                                            width: 280
                                            height: 24
                                            color: Theme.surface
                                            border.width: 1
                                            border.color: Theme.hairline
                                            radius: Theme.radius
                                            TextInput {
                                                anchors.fill: parent
                                                anchors.margins: 4
                                            font.family: Config.defaultFontUi
                                            font.pixelSize: 12
                                            color: Theme.fg
                                            text: win.zoneDraft
                                                onTextChanged: win.zoneDraft = text
                                                Keys.onReturnPressed: win.addZone()
                                                Keys.onEnterPressed: win.addZone()
                                            }
                                        }
                                        BarButton {
                                            implicitWidth: 56
                                            onClicked: win.addZone()
                                            BarText {
                                                text: "add"
                                                px: 11
                                            }
                                        }
                                    }
                                    BarText {
                                        text: "IANA id, e.g. Europe/Moscow"
                                        sub: true
                                        px: 11
                                    }
                                }

                                Column {
                                    visible: win.page === "weather"
                                    width: parent.width
                                    spacing: 8
                                    BarText {
                                        text: "city for wttr.in. empty = from IP."
                                        sub: true
                                        px: 11
                                        width: parent.width
                                        wrapMode: Text.Wrap
                                    }
                                    Rectangle {
                                        width: parent.width
                                        height: 28
                                        color: Theme.surface
                                        border.width: 1
                                        border.color: Theme.hairline
                                        radius: Theme.radius
                                        TextInput {
                                            anchors.fill: parent
                                            anchors.margins: 4
                                            font.family: Config.defaultFontUi
                                            font.pixelSize: 13
                                            color: Theme.fg
                                            text: win.weatherDraft
                                            onTextChanged: win.weatherDraft = text
                                            Keys.onReturnPressed: win.saveWeather()
                                            Keys.onEnterPressed: win.saveWeather()
                                        }
                                    }
                                    Row {
                                        spacing: 4
                                        BarButton {
                                            implicitWidth: 80
                                            active: Config.services.weatherCity === "Moscow"
                                            onClicked: {
                                                win.weatherDraft = "Moscow";
                                                win.saveWeather();
                                            }
                                            BarText {
                                                text: "Moscow"
                                                px: 11
                                            }
                                        }
                                        BarButton {
                                            implicitWidth: 72
                                            onClicked: win.saveWeather()
                                            BarText {
                                                text: "save"
                                                px: 11
                                            }
                                        }
                                    }
                                }

                                Column {
                                    visible: win.page === "session"
                                    width: parent.width
                                    spacing: 8
                                    BarText {
                                        text: "Super+L. Idle and sleep use this lock."
                                        sub: true
                                        px: 11
                                        width: parent.width
                                        wrapMode: Text.Wrap
                                    }
                                }

                                Column {
                                    visible: win.page === "devices"
                                    width: parent.width
                                    spacing: 8
                                    BarText {
                                        text: "empty = auto"
                                        sub: true
                                        px: 11
                                        width: parent.width
                                        wrapMode: Text.Wrap
                                    }
                                    BarText {
                                        text: "backlight"
                                        px: 12
                                    }
                                    Rectangle {
                                        width: parent.width
                                        height: 28
                                        color: Theme.surface
                                        border.width: 1
                                        border.color: Theme.hairline
                                        radius: Theme.radius
                                        TextInput {
                                            anchors.fill: parent
                                            anchors.margins: 4
                                            font.family: Config.defaultFontUi
                                            font.pixelSize: 13
                                            color: Theme.fg
                                            text: win.blDraft
                                            onTextChanged: win.blDraft = text
                                            Keys.onReturnPressed: win.saveDevices()
                                            Keys.onEnterPressed: win.saveDevices()
                                        }
                                    }
                                    BarButton {
                                        implicitWidth: 140
                                        active: blDraft.trim() === "intel_backlight"
                                        onClicked: {
                                            win.blDraft = "intel_backlight";
                                            win.saveDevices();
                                        }
                                        BarText {
                                            text: "intel_backlight"
                                            px: 11
                                        }
                                    }
                                    BarText {
                                        text: "keyboard"
                                        px: 12
                                    }
                                    Rectangle {
                                        width: parent.width
                                        height: 28
                                        color: Theme.surface
                                        border.width: 1
                                        border.color: Theme.hairline
                                        radius: Theme.radius
                                        TextInput {
                                            anchors.fill: parent
                                            anchors.margins: 4
                                            font.family: Config.defaultFontUi
                                            font.pixelSize: 13
                                            color: Theme.fg
                                            text: win.kbDraft
                                            onTextChanged: win.kbDraft = text
                                            Keys.onReturnPressed: win.saveDevices()
                                            Keys.onEnterPressed: win.saveDevices()
                                        }
                                    }
                                    BarButton {
                                        implicitWidth: 72
                                        onClicked: win.saveDevices()
                                        BarText {
                                            text: "save"
                                            px: 11
                                        }
                                    }
                                }

                                ScreenPage {
                                    visible: win.page === "screen"
                                    width: parent.width
                                }

                                Column {
                                    visible: win.page === "color"
                                    width: parent.width
                                    spacing: 10
                                    SkinChip {
                                        pal: ({
                                            label: "From wall",
                                            bg: Theme.hexOf(Theme.bg),
                                            surface: Theme.hexOf(Theme.surface),
                                            fg: Theme.hexOf(Theme.fg),
                                            accent: Theme.hexOf(Theme.accent)
                                        })
                                        active: Theme.fromWall
                                        onClicked: Theme.setTheme("wall", "wall")
                                    }
                                    Flow {
                                        width: parent.width
                                        spacing: 8
                                        Repeater {
                                            model: Theme.presets
                                            SkinChip {
                                                required property var modelData
                                                pal: modelData
                                                active: Theme.name === modelData.name
                                                onClicked: Theme.setTheme(modelData.kind, modelData.name)
                                            }
                                        }
                                    }
                                    BarText {
                                        text: "wallpaper from 単 · skins"
                                        sub: true
                                        px: 11
                                        family: Config.defaultFontUi
                                        width: parent.width
                                        wrapMode: Text.Wrap
                                    }
                                }
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
                    page = row.page;
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

            function hasZone(id) {
                const z = Config.plainZones(Config.clockZones);
                for (let i = 0; i < z.length; i++) {
                    if (z[i].id === id)
                        return true;
                }
                return false;
            }

            function ensureZone(id, label) {
                if (hasZone(id))
                    return;
                const z = Config.plainZones(Config.clockZones);
                z.push({
                    id: id,
                    label: label || Config.prettyZone(id)
                });
                Config.clock.zones = z;
                Config.writeSparse();
            }

            function addZone() {
                const id = zoneDraft.trim();
                if (!id.length)
                    return;
                ensureZone(id, Config.prettyZone(id));
                zoneDraft = "";
            }

            function dropZone(index) {
                const z = Config.plainZones(Config.clockZones);
                if (index < 0 || index >= z.length)
                    return;
                z.splice(index, 1);
                Config.clock.zones = z;
                Config.writeSparse();
            }

            function saveWeather() {
                Config.services.weatherCity = weatherDraft.trim();
                Config.writeSparse();
            }

            function saveDevices() {
                Config.services.backlight = blDraft.trim();
                Config.services.keyboard = kbDraft.trim();
                Config.writeSparse();
            }
        }
    }
}
