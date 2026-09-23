pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var list: []
    property string pick: ""
    property real scale: 1
    property bool hold: false
    property string _sunsetBody: ""
    property bool _sunsetRestart: false

    readonly property string sunsetPath: `${Config.configHome}/hypr/hyprsunset.conf`
    readonly property string nightAt: Config.screens.nightAt.length ? Config.screens.nightAt : "21:00"
    readonly property string dayAt: Config.screens.dayAt.length ? Config.screens.dayAt : "5:30"
    readonly property int nightKelvin: Config.screens.nightTemp > 0 ? Config.screens.nightTemp : 5500
    readonly property bool nightOn: Config.screens.nightOn !== false

    readonly property var current: {
        const rows = list;
        for (let i = 0; i < rows.length; i++) {
            if (rows[i].name === pick)
                return rows[i];
        }
        return rows.length ? rows[0] : null;
    }

    readonly property var scales: [1, 1.2, 1.25, 1.5, 1.75, 2]

    function snapScale(raw) {
        const stops = scales;
        if (!stops.length)
            return 1;
        let n = Number(raw);
        if (!(n > 0))
            n = 1;
        let best = stops[0];
        let bestD = Math.abs(n - best);
        for (let i = 1; i < stops.length; i++) {
            const d = Math.abs(n - stops[i]);
            if (d < bestD) {
                best = stops[i];
                bestD = d;
            }
        }
        return best;
    }

    function scaleIndex(raw) {
        const stops = scales;
        const n = snapScale(raw);
        for (let i = 0; i < stops.length; i++) {
            if (Math.abs(stops[i] - n) < 0.001)
                return i;
        }
        return 0;
    }

    function scaleAt(t) {
        const stops = scales;
        if (!stops.length)
            return 1;
        const last = stops.length - 1;
        const i = Math.max(0, Math.min(last, Math.round(Math.max(0, Math.min(1, Number(t) || 0)) * last)));
        return stops[i];
    }

    function scaleSlider(raw) {
        const last = scales.length - 1;
        if (last <= 0)
            return 0;
        return scaleIndex(raw) / last;
    }

    function fmtScale(raw) {
        const n = snapScale(raw);
        return `${n}`.replace(/(\.\d*?)0+$/, "$1").replace(/\.$/, "");
    }

    function compactMode(s) {
        let t = `${s || ""}`.replace(/\s/g, "").replace(/Hz$/i, "");
        t = t.replace(/@(\d+(?:\.\d+)?)$/, (_, n) => {
            const hz = Number(n);
            if (!hz)
                return `@${n}`;
            if (Math.abs(hz - Math.round(hz)) < 0.05)
                return `@${Math.round(hz)}`;
            const t3 = Math.round(hz * 1000) / 1000;
            return `@${t3}`;
        });
        return t;
    }

    function sameMode(a, b) {
        return compactMode(a) === compactMode(b);
    }

    function refresh() {
        monProc.running = false;
        Qt.callLater(() => {
            monProc.running = true;
        });
        if (!Compositor.hasGamma)
            return;
        Compositor.ensureSunset();
    }

    function adopt(out) {
        for (let i = 0; i < out.length; i++) {
            out[i].mode = compactMode(out[i].mode);
            const modes = out[i].modes || [];
            for (let j = 0; j < modes.length; j++)
                modes[j] = compactMode(modes[j]);
            out[i].modes = modes;
        }
        list = out;
        if (!pick.length && out.length)
            pick = out[0].name;
        else {
            let hit = false;
            for (let i = 0; i < out.length; i++) {
                if (out[i].name === pick)
                    hit = true;
            }
            if (!hit && out.length)
                pick = out[0].name;
        }
        syncScale();
    }

    function parse(text) {
        const rows = Compositor.parseMonitors(text);
        if (rows)
            adopt(rows);
    }

    function syncScale() {
        const cur = current;
        if (!cur)
            return;
        const sc = Number(cur.scale) || 1;
        if (hold) {
            if (Math.abs(sc - scale) < 0.02)
                hold = false;
            return;
        }
        scale = sc;
    }

    onPickChanged: {
        hold = false;
        syncScale();
    }

    function patch(row) {
        const rows = list.slice();
        for (let i = 0; i < rows.length; i++) {
            if (rows[i].name === row.name)
                rows[i] = row;
        }
        list = rows;
    }

    function apply(row) {
        if (!row || !row.name)
            return;
        patch(row);
        Compositor.persistMonitors(list);
        Compositor.applyMonitor(row);
    }

    function setScale(v) {
        const cur = current;
        if (!cur)
            return;
        scale = snapScale(v);
        hold = true;
        const next = Object.assign({}, cur);
        next.scale = scale;
        apply(next);
    }

    function setMode(mode) {
        const cur = current;
        if (!cur)
            return;
        const next = Object.assign({}, cur);
        next.mode = compactMode(mode);
        apply(next);
    }

    function setNightOn(on) {
        if (!Compositor.hasGamma)
            return;
        Config.screens.nightOn = !!on;
        Config.writeSparse();
        writeSunset(true);
        if (!on)
            Compositor.identityGamma();
        else
            Compositor.setTemperature(nightKelvin);
    }

    function previewNight(v) {
        if (!Compositor.hasGamma || !nightOn)
            return;
        Compositor.setTemperature(clampKelvin(v));
    }

    function parseHM(raw) {
        const s = `${raw || ""}`.trim();
        const m = s.match(/^(\d{1,2}):(\d{2})$/);
        if (!m)
            return null;
        const h = Number(m[1]);
        const min = Number(m[2]);
        if (h > 23 || min > 59)
            return null;
        return { h: h, min: min };
    }

    function fmtHM(h, min) {
        return `${h}:${min < 10 ? "0" : ""}${min}`;
    }

    function normClock(raw, fallback) {
        const t = parseHM(raw);
        if (t)
            return fmtHM(t.h, t.min);
        const fb = parseHM(fallback);
        return fb ? fmtHM(fb.h, fb.min) : `${fallback || ""}`;
    }

    function addMins(raw, delta, fallback) {
        const t = parseHM(normClock(raw, fallback));
        if (!t)
            return fallback;
        let n = t.h * 60 + t.min + Number(delta);
        n = ((n % 1440) + 1440) % 1440;
        return fmtHM(Math.floor(n / 60), n % 60);
    }

    function clampKelvin(v) {
        const k = Math.round(Number(v) || 0);
        return Math.max(3000, Math.min(6500, k));
    }

    function sunsetJson() {
        return JSON.stringify({
            on: nightOn,
            nightAt: nightAt,
            dayAt: dayAt,
            nightTemp: nightKelvin,
            path: sunsetPath
        });
    }

    function applySunset(raw) {
        let obj = {};
        try {
            obj = JSON.parse(`${raw || ""}`);
        } catch (e) {
            obj = {};
        }
        if (obj.nightAt !== undefined)
            Config.screens.nightAt = normClock(obj.nightAt, nightAt);
        if (obj.dayAt !== undefined)
            Config.screens.dayAt = normClock(obj.dayAt, dayAt);
        if (obj.nightTemp !== undefined) {
            const k = Math.round(Number(obj.nightTemp));
            if (k >= 1000 && k <= 10000)
                Config.screens.nightTemp = k;
        }
        if (obj.on !== undefined)
            Config.screens.nightOn = !!obj.on;
        Config.writeSparse();
        writeSunset(true);
        return sunsetJson();
    }

    function setNightAt(raw) {
        Config.screens.nightAt = normClock(raw, nightAt);
        Config.writeSparse();
        writeSunset(true);
    }

    function setDayAt(raw) {
        Config.screens.dayAt = normClock(raw, dayAt);
        Config.writeSparse();
        writeSunset(true);
    }

    function bumpNight(delta) {
        setNightAt(addMins(nightAt, delta, "21:00"));
    }

    function bumpDay(delta) {
        setDayAt(addMins(dayAt, delta, "5:30"));
    }

    function setNightTemp(v) {
        Config.screens.nightTemp = clampKelvin(v);
        Config.writeSparse();
        writeSunset(false);
        if (nightOn)
            Compositor.setTemperature(Config.screens.nightTemp);
    }

    function writeSunset(restart) {
        _sunsetRestart = restart !== false;
        if (!nightOn) {
            _sunsetBody = "max-gamma = 150\n\n"
                + "profile {\n"
                + "    time = 0:00\n"
                + "    identity = true\n"
                + "}\n";
        } else {
            _sunsetBody = "max-gamma = 150\n\n"
                + "profile {\n"
                + `    time = ${dayAt}\n`
                + "    identity = true\n"
                + "}\n\n"
                + "profile {\n"
                + `    time = ${nightAt}\n`
                + `    temperature = ${nightKelvin}\n`
                + "}\n";
        }
        sunsetMk.command = ["mkdir", "-p", `${Config.configHome}/hypr`];
        sunsetMk.running = false;
        Qt.callLater(() => {
            sunsetMk.running = true;
        });
    }

    function ingestSunset(text) {
        if (Config.screens.nightAt.length && Config.screens.dayAt.length)
            return;
        const blocks = `${text || ""}`.split("profile");
        let day = "";
        let night = "";
        let temp = 0;
        for (let i = 0; i < blocks.length; i++) {
            const b = blocks[i];
            const tm = b.match(/time\s*=\s*([0-9]{1,2}:[0-9]{2})/);
            if (!tm)
                continue;
            if (/identity\s*=\s*true/.test(b))
                day = tm[1];
            else {
                night = tm[1];
                const k = b.match(/temperature\s*=\s*([0-9]+)/);
                if (k)
                    temp = Number(k[1]) || 0;
            }
        }
        if (!Config.screens.dayAt.length && day.length)
            Config.screens.dayAt = day;
        if (!Config.screens.nightAt.length && night.length)
            Config.screens.nightAt = night;
        if (Config.screens.nightTemp <= 0 && temp >= 1000)
            Config.screens.nightTemp = temp;
    }

    Process {
        id: monProc
        command: Compositor.monitorQuery
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.parse(text)
        }
    }

    Connections {
        target: Compositor
        function onMonitorsDirty() {
            root.refresh();
        }
    }

    FileView {
        id: sunsetFile
        printErrors: false
        atomicWrites: true
        onLoaded: root.ingestSunset(text())
    }

    Process {
        id: sunsetMk
        running: false
        onExited: {
            sunsetFile.path = root.sunsetPath;
            sunsetFile.setText(root._sunsetBody);
            if (`${Quickshell.env("TANJUN_TEST") || ""}` === "1")
                return;
            if (!Compositor.hasGamma)
                return;
            if (root._sunsetRestart)
                Compositor.reloadSunset();
            else if (root.nightOn)
                Compositor.setTemperature(root.nightKelvin);
        }
    }

    Component.onCompleted: {
        sunsetFile.path = sunsetPath;
        sunsetFile.reload();
        refresh();
    }

    function cloneRow(r) {
        return {
            name: r.name,
            desc: r.desc,
            width: r.width,
            height: r.height,
            scale: r.scale,
            mode: r.mode,
            modes: r.modes,
            x: r.x,
            y: r.y,
            disabled: r.disabled
        };
    }

    function internalOf(rows) {
        for (let i = 0; i < rows.length; i++) {
            const n = `${rows[i].name || ""}`;
            if (n.indexOf("eDP") === 0 || n.indexOf("LVDS") === 0)
                return rows[i];
        }
        return rows.length ? rows[0] : null;
    }

    function externalOf(rows, internal) {
        if (!internal)
            return null;
        for (let i = 0; i < rows.length; i++) {
            if (rows[i].name !== internal.name)
                return rows[i];
        }
        return null;
    }

    function rowWidth(row) {
        const w = Number(row && row.width) || 0;
        if (w > 0)
            return w;
        const hit = `${(row && row.mode) || ""}`.match(/^(\d+)x/);
        return hit ? Number(hit[1]) : 1920;
    }

    readonly property string deskKind: {
        const rows = list || [];
        const internal = internalOf(rows);
        if (!internal)
            return "";
        const external = externalOf(rows, internal);
        const onInt = !internal.disabled;
        const onExt = !!(external && !external.disabled);
        if (onInt && !onExt)
            return "first";
        if (onExt && !onInt)
            return "second";
        if (onInt && onExt)
            return "extend";
        return "";
    }

    function deskJson() {
        const rows = list || [];
        const names = [];
        const enabled = [];
        for (let i = 0; i < rows.length; i++) {
            names.push(rows[i].name);
            if (!rows[i].disabled)
                enabled.push(rows[i].name);
        }
        const internal = internalOf(rows);
        return JSON.stringify({
            kind: deskKind,
            names: names,
            enabled: enabled,
            internal: internal ? internal.name : ""
        });
    }

    function setDesk(kind) {
        const src = list || [];
        if (!src.length)
            return;
        const rows = [];
        for (let i = 0; i < src.length; i++)
            rows.push(cloneRow(src[i]));
        const internal = internalOf(rows);
        if (!internal)
            return;
        const external = externalOf(rows, internal);
        if (kind === "first") {
            for (let i = 0; i < rows.length; i++) {
                rows[i].disabled = rows[i].name !== internal.name;
                if (!rows[i].disabled) {
                    rows[i].x = 0;
                    rows[i].y = 0;
                }
            }
        } else if (kind === "second" && external) {
            for (let i = 0; i < rows.length; i++) {
                rows[i].disabled = rows[i].name !== external.name;
                if (!rows[i].disabled) {
                    rows[i].x = 0;
                    rows[i].y = 0;
                }
            }
        } else if (kind === "extend" && external) {
            for (let i = 0; i < rows.length; i++)
                rows[i].disabled = false;
            external.x = 0;
            external.y = 0;
            internal.x = rowWidth(external);
            internal.y = 0;
        } else {
            return;
        }
        list = rows;
        Compositor.persistMonitors(rows);
        Compositor.applyMonitors(rows);
    }
}
