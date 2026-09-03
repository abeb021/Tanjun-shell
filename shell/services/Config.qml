pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string configHome: Quickshell.env("XDG_CONFIG_HOME") || `${Quickshell.env("HOME")}/.config`
    readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || `${Quickshell.env("HOME")}/.local/state`
    readonly property string configDir: `${configHome}/tanjun`
    readonly property string stateDir: `${stateHome}/tanjun`
    readonly property string configFile: `${configDir}/config.json`
    readonly property string stateFile: `${stateDir}/state.json`
    readonly property string legacyStateFile: `${configDir}/state.json`

    readonly property alias clock: adapter.clock
    readonly property alias services: adapter.services
    readonly property alias session: adapter.session
    readonly property alias appearance: adapter.appearance
    readonly property alias screens: adapter.screens

    readonly property string defaultFontUi: "JetBrains Mono"
    readonly property string defaultFontJp: "Noto Sans CJK JP"
    readonly property string defaultFontIcons: "Symbols Nerd Font"
    readonly property int defaultFontPx: 13

    readonly property string localId: {
        try {
            return Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC";
        } catch (e) {
            return "UTC";
        }
    }
    readonly property string localLabel: prettyZone(localId)
    readonly property var clockZones: {
        const z = clock.zones;
        if (z && z.length)
            return z;
        return [{ id: localId, label: localLabel }];
    }

    property bool _rewriting: false

    function prettyZone(id) {
        const s = `${id || ""}`;
        if (!s.length)
            return "Local";
        const tail = s.split("/").pop() || s;
        return tail.replace(/_/g, " ");
    }

    function argv(value) {
        if (!value)
            return [];
        if (typeof value === "string")
            return value.length ? [value] : [];
        const out = [];
        for (let i = 0; i < value.length; i++)
            out.push(`${value[i]}`);
        return out;
    }

    function sameArgv(a, b) {
        const x = argv(a);
        const y = argv(b);
        if (x.length !== y.length)
            return false;
        for (let i = 0; i < x.length; i++) {
            if (x[i] !== y[i])
                return false;
        }
        return true;
    }

    function isFlat(obj) {
        if (!obj || typeof obj !== "object")
            return false;
        if (obj.clock || obj.services || obj.session || obj.theme || obj.appearance)
            return false;
        return obj.zones !== undefined || obj.weatherCity !== undefined || obj.backlight !== undefined || obj.keyboard !== undefined || obj.lock !== undefined || obj.themeHook !== undefined;
    }

    function applyFlat(obj) {
        if (obj.zones && obj.zones.length)
            clock.zones = obj.zones;
        if (obj.weatherCity !== undefined)
            services.weatherCity = `${obj.weatherCity}`;
        if (obj.backlight !== undefined)
            services.backlight = `${obj.backlight}`;
        if (obj.keyboard !== undefined)
            services.keyboard = `${obj.keyboard}`;
        if (obj.lock !== undefined)
            session.lock = argv(obj.lock);
    }

    function plainZones(z) {
        const out = [];
        if (!z)
            return out;
        for (let i = 0; i < z.length; i++) {
            const it = z[i];
            out.push({
                id: `${it.id || ""}`,
                label: `${it.label || prettyZone(it.id)}`
            });
        }
        return out;
    }

    function localeTwelve() {
        return Qt.locale().timeFormat(Locale.ShortFormat).toLowerCase().indexOf("a") >= 0;
    }

    function sparseObject() {
        const out = {};
        const z = plainZones(clock.zones);
        const clk = {};
        if (z.length)
            clk.zones = z;
        if (clock.twelveHour !== localeTwelve())
            clk.twelveHour = !!clock.twelveHour;
        if (Object.keys(clk).length)
            out.clock = clk;
        const svc = {};
        if (services.weatherCity.length)
            svc.weatherCity = services.weatherCity;
        if (services.backlight.length)
            svc.backlight = services.backlight;
        if (services.keyboard.length)
            svc.keyboard = services.keyboard;
        if (Object.keys(svc).length)
            out.services = svc;
        const lock = argv(session.lock);
        if (lock.length && !sameArgv(lock, ["loginctl", "lock-session"]))
            out.session = { lock: lock };
        const ap = {};
        if (appearance.fontUi.length && appearance.fontUi !== defaultFontUi)
            ap.fontUi = appearance.fontUi;
        if (appearance.fontJp.length && appearance.fontJp !== defaultFontJp)
            ap.fontJp = appearance.fontJp;
        if (appearance.fontIcons.length && appearance.fontIcons !== defaultFontIcons)
            ap.fontIcons = appearance.fontIcons;
        if (appearance.fontPx > 0 && appearance.fontPx !== defaultFontPx)
            ap.fontPx = appearance.fontPx;
        if (Object.keys(ap).length)
            out.appearance = ap;
        if (screens.gamma > 0)
            out.screens = { gamma: screens.gamma };
        return out;
    }

    function writeSparse() {
        _rewriting = true;
        Quickshell.execDetached(["mkdir", "-p", configDir]);
        file.setText(`${JSON.stringify(sparseObject(), null, 2)}\n`);
        Qt.callLater(() => {
            root._rewriting = false;
        });
    }

    function ensureStateDir() {
        Quickshell.execDetached(["mkdir", "-p", stateDir]);
    }

    Component.onCompleted: ensureStateDir()

    FileView {
        id: file
        path: root.configFile
        printErrors: false
        watchChanges: true
        onFileChanged: {
            if (!root._rewriting)
                reload();
        }
        onLoaded: {
            try {
                const raw = JSON.parse(text());
                if (root.isFlat(raw)) {
                    root.applyFlat(raw);
                    root.writeSparse();
                }
            } catch (e) {}
        }
        adapter: JsonAdapter {
            id: adapter

            property JsonObject clock: JsonObject {
                property var zones: []
                property bool twelveHour: Qt.locale().timeFormat(Locale.ShortFormat).toLowerCase().indexOf("a") >= 0
            }

            property JsonObject services: JsonObject {
                property string weatherCity: ""
                property string backlight: ""
                property string keyboard: ""
            }

            property JsonObject session: JsonObject {
                property var lock: ["loginctl", "lock-session"]
            }

            property JsonObject appearance: JsonObject {
                property string fontUi: ""
                property string fontJp: ""
                property string fontIcons: ""
                property int fontPx: 0
            }

            property JsonObject screens: JsonObject {
                property int gamma: 0
            }
        }
    }
}
