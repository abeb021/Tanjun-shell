pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Host metrics, read in-process.
//
// Every figure comes from a file under /proc or /sys that Qt reads itself, so a
// tick costs a handful of small reads and nothing else: no helper process, no
// JSON on a pipe, no handshake file. The one thing QML cannot do is list a
// directory, so the top-process table asks `ps` — a C program that already solves
// that — and only while the sidebar is showing it.
Singleton {
    id: root

    property real cpu: 0
    property real temp: -1
    property int ramUsed: 0
    property int ramTotal: 0
    property int down: 0
    property int up: 0
    property var procs: []
    property string user: Quickshell.env("USER") || Quickshell.env("LOGNAME") || ""
    property string distro: ""
    property string distroId: ""
    property string distroLike: ""
    property string kernel: ""
    property int cores: 0
    property int threads: 0
    property string cpuModel: ""
    property string gpu: ""
    property string hostName: ""
    property string uptime: ""
    property string disk: ""
    property var corePct: []

    // Set by whatever is showing live numbers. The sidebar, the system page,
    // the bar readout and the load menu each want the sampler without the others
    // being open.
    property bool menuOpen: false
    // The bar readout is visible at all times, so it asks for the sampler too and
    // the numbers stay live without a menu being open.
    property bool barReading: false
    readonly property bool testHost: `${Quickshell.env("TANJUN_TEST") || ""}` === "1"
    // "ticking" is the public name for "the shell wants host numbers right now",
    // which is what the sidebar, the system page and the load menu each turn on.
    // It is a UI state, not a measure of cost: the reads behind it are a few
    // small files.
    readonly property bool ticking: wanted
    // `barReading` keeps the sampler alive on its own; the test harness sets a
    // temp HOME and wants a shell that sits idle, so it is ignored there.
    readonly property bool wanted: (!testHost && barReading) || panelOpen
    // A real reader shows more than the bar readout, so it earns a faster tick.
    readonly property bool panelOpen: UiMode.sidebarOpen || menuOpen || (UiMode.settingsOpen && SettingsNav.page === "system")
    // Only the sidebar lists top processes; nobody else sees Host.procs, so `ps`
    // is not run while it is closed. That sweep is the only expensive one.
    readonly property bool procsWanted: UiMode.sidebarOpen
    // Bar-only numbers are read every 5 s; an open panel gets 2 s. Both are far
    // below the point where a changing digit reads as live.
    readonly property int interval: panelOpen ? 2000 : 5000

    readonly property real ramRatio: ramTotal > 0 ? ramUsed / ramTotal : 0
    readonly property string ramText: ramTotal > 0 ? `${fmtGiB(ramUsed)} / ${fmtGiB(ramTotal)}` : "—"
    // The vertical bar has no room for the pair, so it shows what is in use.
    readonly property string ramShortText: ramTotal > 0 ? fmtGiB(ramUsed) : "—"
    readonly property string cpuText: `${cpu.toFixed(0)}%`
    readonly property bool hasTemp: temp > 0
    readonly property string tempText: hasTemp ? `${Math.round(temp)}°` : ""
    readonly property int downKb: Math.round(down / 1024)
    readonly property int upKb: Math.round(up / 1024)
    readonly property string downText: `${downKb} KB/s`
    readonly property string upText: `${upKb} KB/s`
    readonly property string cpuTip: {
        const bits = [];
        if (cores > 0)
            bits.push(cores === 1 ? "1 core" : `${cores} cores`);
        if (threads > 0 && threads !== cores)
            bits.push(`${threads} threads`);
        if (cpuModel.length)
            bits.push(cpuModel);
        return bits.join(" · ") || "cpu";
    }
    readonly property string machine: {
        const bits = [];
        if (distro.length)
            bits.push(distro);
        if (kernel.length)
            bits.push(kernel);
        return bits.join("  ·  ");
    }
    readonly property string face: {
        const bits = [];
        if (user.length)
            bits.push(user);
        if (machine.length)
            bits.push(machine);
        return bits.join("  ·  ");
    }

    function fmtGiB(kib) {
        const g = kib / 1024 / 1024;
        return `${g >= 10 ? g.toFixed(0) : g.toFixed(1)}G`;
    }

    function sameNums(a, b) {
        if (!a || !b || a.length !== b.length)
            return false;
        for (let i = 0; i < a.length; i++) {
            if (a[i] !== b[i])
                return false;
        }
        return true;
    }

    function sameProcs(a, b) {
        if (!a || !b || a.length !== b.length)
            return false;
        // The cpu figure moves every tick but the rows do not have to: comparing
        // pid and name keeps the list from rebuilding when only the percentage
        // wobbles. The cpu text itself comes from the delegate, which reads the
        // current row — so also compare cpu to let it refresh.
        for (let i = 0; i < a.length; i++) {
            if (a[i].pid !== b[i].pid || a[i].name !== b[i].name || a[i].cpu !== b[i].cpu)
                return false;
        }
        return true;
    }

    function killProc(pid) {
        const n = Number(pid);
        if (!n || n <= 1)
            return;
        Quickshell.execDetached(["kill", "-TERM", `${n}`]);
    }

    // ---- sampling -----------------------------------------------------------

    property var _cpuNow: null
    property var _cpuNowT: 0
    property var _netPrevT: 0
    property var _netPrev: null

    // One tick: reload every source and publish what changed. Each read owns its
    // own FileView, and reload() is non-blocking, so the text() right after it
    // waits only for the fresh value (blockAllReads) and no tick can stall the UI
    // on a slow disk.
    function tick() {
        readCpu();
        readMem();
        readNet();
        readTemp();
    }

    function readCpu() {
        statFile.reload();
        const body = `${statFile.text() || ""}`;
        if (!body.length)
            return;
        const rows = body.split("\n");
        const now = [];
        for (let i = 0; i < rows.length; i++) {
            const line = rows[i];
            if (!line.startsWith("cpu"))
                break;
            const parts = line.split(/\s+/);
            const s = parts.slice(1, 9).map(Number);
            if (s.length < 4)
                continue;
            // idle + iowait are the "not busy" fields; the rest are work.
            now.push({ idle: (s[3] || 0) + (s[4] || 0), total: s.reduce((a, b) => a + (b || 0), 0) });
        }
        if (!now.length)
            return;
        const nowT = Date.now();
        const prev = root._cpuNow;
        const prevT = root._cpuNowT;
        root._cpuNow = now;
        root._cpuNowT = nowT;
        if (!prev || prev.length !== now.length)
            return;
        // Two ticks can land a few milliseconds apart (start/restart, a panel
        // opening right after startup). The counters barely move over that, so
        // dividing by the delta yields a fake 100%. Keep the previous reading
        // instead and wait for a real interval.
        if (nowT - prevT < 250)
            return;
        const busy = pct(prev[0], now[0]);
        if (busy !== root.cpu)
            root.cpu = busy;
        const bits = [];
        for (let i = 1; i < now.length; i++)
            bits.push(pct(prev[i], now[i]));
        if (!sameNums(root.corePct, bits))
            root.corePct = bits;
    }

    function pct(a, b) {
        const dt = Math.max(1, b.total - a.total);
        const busy = 1 - (b.idle - a.idle) / dt;
        return Math.round(Math.max(0, Math.min(100, busy * 100)) * 10) / 10;
    }

    function readMem() {
        memFile.reload();
        const body = `${memFile.text() || ""}`;
        if (!body.length)
            return;
        let total = 0;
        let avail = 0;
        let free = 0;
        const rows = body.split("\n");
        for (let i = 0; i < rows.length; i++) {
            const bits = rows[i].split(/\s+/);
            const key = bits[0];
            if (key === "MemTotal:")
                total = Number(bits[1]) || 0;
            else if (key === "MemAvailable:")
                avail = Number(bits[1]) || 0;
            else if (key === "MemFree:" && !avail)
                free = Number(bits[1]) || 0;
        }
        if (total <= 0)
            return;
        // Same definition the sampler always used: used is whatever is not
        // available, and MemFree is only a fallback for a kernel without
        // MemAvailable.
        if (root.ramTotal !== total)
            root.ramTotal = total;
        const used = total - (avail || free);
        if (root.ramUsed !== used)
            root.ramUsed = used;
    }

    function readNet() {
        netFile.reload();
        const body = `${netFile.text() || ""}`;
        if (!body.length)
            return;
        const rows = body.split("\n");
        let rx = 0;
        let tx = 0;
        for (let i = 2; i < rows.length; i++) {
            const line = rows[i];
            const at = line.indexOf(":");
            if (at < 0)
                continue;
            if (line.slice(0, at).trim() === "lo")
                continue;
            const cols = line.slice(at + 1).trim().split(/\s+/);
            rx += Number(cols[0]) || 0;
            tx += Number(cols[8]) || 0;
        }
        const t = Date.now();
        const prev = root._netPrev;
        if (prev) {
            const span = Math.max(0.05, (t - root._netPrevT) / 1000);
            const d = Math.round(Math.max(0, (rx - prev.rx) / span));
            const u = Math.round(Math.max(0, (tx - prev.tx) / span));
            if (root.down !== d)
                root.down = d;
            if (root.up !== u)
                root.up = u;
        }
        root._netPrev = { rx: rx, tx: tx };
        root._netPrevT = t;
    }

    function readTemp() {
        // Each sensor is its own FileView with the path discovered once at
        // startup, so a tick reads a couple of tiny files instead of walking
        // /sys. `reload` is non-blocking; `blockAllReads` makes the `text()`
        // right after it wait for the fresh value.
        let hottest = -1;
        const rows = root.tempSources;
        for (let i = 0; i < rows.length; i++) {
            const f = rows[i];
            f.reload();
            const v = Number(`${f.text() || ""}`.trim()) / 1000;
            if (isFinite(v) && v > hottest)
                hottest = v;
        }
        if (hottest < 0)
            return;
        const rounded = Math.round(hottest * 10) / 10;
        if (root.temp !== rounded)
            root.temp = rounded;
    }

    // ---- sources ------------------------------------------------------------

    FileView {
        id: statFile
        path: "/proc/stat"
        preload: true
        printErrors: false
        blockAllReads: true
    }

    FileView {
        id: memFile
        path: "/proc/meminfo"
        preload: true
        printErrors: false
        blockAllReads: true
    }

    FileView {
        id: netFile
        path: "/proc/net/dev"
        preload: true
        printErrors: false
        blockAllReads: true
    }

    // Sensor paths are resolved once (hwmon names never change while the machine
    // is up) and held as a list of FileViews refreshed on every tick. A Variants
    // over the path list is the one place a `required property modelData` can
    // build one FileView per sensor; each child registers itself, because a
    // Variants has no indexed access.
    property var tempSources: []
    property var tempPaths: []

    Variants {
        model: root.tempPaths
        FileView {
            required property string modelData
            id: sensor
            path: modelData
            preload: true
            printErrors: false
            blockAllReads: true
            Component.onCompleted: root.attachTemp(sensor)
            Component.onDestruction: root.detachTemp(sensor)
        }
    }

    function attachTemp(item) {
        const next = root.tempSources.slice();
        next.push(item);
        root.tempSources = next;
    }

    function detachTemp(item) {
        const at = root.tempSources.indexOf(item);
        if (at < 0)
            return;
        const next = root.tempSources.slice();
        next.splice(at, 1);
        root.tempSources = next;
    }

    // Sensor chips whose package temperature is the one worth showing.
    readonly property var tempChips: ({
        coretemp: true, k10temp: true, zenpower: true,
        cpu_thermal: true, soc_thermal: true
    })

    // One `find` prints every name file and every temp input under the hwmon
    // tree, plus the thermal zones; pairing and filtering happen here so the
    // shell side stays a single simple command. There is no directory listing in
    // QML, which is why this is the one place a helper is used. `-L` is required:
    // /sys/class/hwmon/hwmonN is a symlink and find does not descend into one
    // without it.
    readonly property string tempFindShell: "find -L /sys/class/hwmon -maxdepth 2 -name name -readable 2>/dev/null; "
        + "find -L /sys/class/hwmon -maxdepth 2 -name 'temp*_input' -readable 2>/dev/null; "
        + "find -L /sys/class/thermal -maxdepth 2 -name type -readable 2>/dev/null; "
        + "find -L /sys/class/thermal -maxdepth 2 -name temp -readable 2>/dev/null"

    Process {
        id: tempFind
        command: ["sh", "-c", root.tempFindShell]
        running: false
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.resolveTemps(text)
        }
    }

    // A second command reads the chip names and the thermal zone types, because
    // `find` prints paths only. One `sh` does both so only one process is spent
    // on discovery at startup.
    Process {
        id: chipProc
        command: ["sh", "-c", root.discoverShell]
        running: false
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.resolveChips(text)
        }
    }

    readonly property string discoverShell: "for f in /sys/class/hwmon/hwmon*/name; do "
        + "[ -r \"$f\" ] || continue; n=$(cat \"$f\" 2>/dev/null) || continue; "
        + "echo \"H ${f%/name} $n\"; done; "
        + "for f in /sys/class/thermal/thermal_zone*/type; do "
        + "[ -r \"$f\" ] || continue; t=$(cat \"$f\" 2>/dev/null) || continue; "
        + "echo \"Z ${f%/type} $t\"; done"

    property var _chipNames: ({})
    property var _zoneTypes: ({})

    function resolveChips(body) {
        const rows = `${body || ""}`.split("\n");
        const chips = {};
        const zones = {};
        for (let i = 0; i < rows.length; i++) {
            const line = rows[i].trim();
            if (line.length < 3)
                continue;
            const kind = line.slice(0, 1);
            const rest = line.slice(2);
            const at = rest.indexOf(" ");
            if (at < 0)
                continue;
            const dir = rest.slice(0, at);
            const value = rest.slice(at + 1);
            if (kind === "H")
                chips[dir] = value;
            else if (kind === "Z")
                zones[dir] = value;
        }
        root._chipNames = chips;
        root._zoneTypes = zones;
        // Names are only half the picture, so run the walk once they are known.
        tempFind.running = false;
        tempFind.running = true;
    }

    function resolveTemps(body) {
        const lines = `${body || ""}`.split("\n");
        const inputsBy = {};
        const zoneType = {};
        const zoneTemp = {};
        for (let i = 0; i < lines.length; i++) {
            const p = lines[i].trim();
            if (!p.length)
                continue;
            const slash = p.lastIndexOf("/");
            const dir = p.slice(0, slash);
            const leaf = p.slice(slash + 1);
            if (p.indexOf("/sys/class/thermal/") === 0) {
                // The type file is read by the shell command itself below; here
                // only the paths are collected, and the type is fetched next.
                if (leaf === "temp")
                    zoneTemp[dir] = p;
                else if (leaf === "type")
                    zoneType[dir] = true;
                continue;
            }
            if (leaf === "name")
                continue;
            if (!inputsBy[dir])
                inputsBy[dir] = [];
            inputsBy[dir].push(p);
        }
        const names = root._chipNames;
        const out = [];
        const dirs = Object.keys(inputsBy);
        for (let i = 0; i < dirs.length; i++) {
            const d = dirs[i];
            const chip = names[d];
            // A chip whose name was not read is kept: better one extra sensor
            // than a missing temperature.
            if (chip !== undefined && !root.tempChips[chip])
                continue;
            const list = inputsBy[d];
            for (let j = 0; j < list.length; j++)
                out.push(list[j]);
        }
        // Thermal zones only when their type names a cpu or soc, the same test
        // the helper made; the type text is in _zoneTypes from the second
        // process below.
        const types = root._zoneTypes;
        const zones = Object.keys(zoneTemp);
        for (let i = 0; i < zones.length; i++) {
            const kind = `${types[zones[i]] || ""}`.toLowerCase();
            if (kind.indexOf("cpu") < 0 && kind.indexOf("soc") < 0 && kind.indexOf("x86") < 0)
                continue;
            out.push(zoneTemp[zones[i]]);
        }
        if (out.join("\n") !== root.tempPaths.join("\n"))
            root.tempPaths = out;
    }

    // ---- tick ---------------------------------------------------------------

    Timer {
        id: tickTimer
        interval: root.interval
        repeat: true
        running: root.wanted
        // Not triggeredOnStart: `wanted` already restarts the timer when it turns
        // true, and firing both would take two readings in the same millisecond.
        onTriggered: root.tick()
    }

    onWantedChanged: {
        if (wanted) {
            // Do not leave a 5 s gap on the first open: take a reading now and
            // let the timer settle back to its interval from here.
            tickTimer.restart();
            root.tick();
        }
    }

    // ---- processes ----------------------------------------------------------

    // `ps` is the C program that already knows how to sweep /proc. It runs only
    // while the sidebar is open, and its own %cpu is good enough to rank with —
    // see applyProcs. The row for `ps` itself is dropped there: it is the newest
    // process, so its %cpu (cpu time over age) always reads high.
    Process {
        id: procsProc
        command: ["ps", "-eo", "pid=,pcpu=,comm=", "--sort=-pcpu"]
        running: false
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.applyProcs(text)
        }
    }

    function applyProcs(body) {
        const rows = `${body || ""}`.split("\n");
        const out = [];
        for (let i = 0; i < rows.length && out.length < 5; i++) {
            const line = rows[i].trim();
            if (!line.length)
                continue;
            const hit = line.match(/^(\d+)\s+([\d.]+)\s+(.*)$/);
            if (!hit)
                continue;
            const pid = Number(hit[1]);
            const name = hit[3].trim();
            // ps %cpu is total CPU time over process age, not an instantaneous
            // rate. It ranks correctly, so it is shown as-is; a running average
            // is what the old sampler reported for the first tick too.
            const cpu = Math.round((Number(hit[2]) || 0) * 10) / 10;
            if (!name.length)
                continue;
            // Its own row is always the newest process, so it tops the ranking
            // on a figure that means nothing.
            if (name === "ps")
                continue;
            out.push({ pid: pid, name: name, cpu: cpu });
        }
        if (!sameProcs(root.procs, out))
            root.procs = out;
    }

    // `ps` is fast enough to run on the same cadence as the panel tick, so there
    // is no need for a second reader. `triggeredOnStart` gives the sidebar rows
    // on the frame it opens instead of an empty gap.
    Timer {
        id: procsTimer
        interval: 2000
        repeat: true
        running: root.procsWanted
        triggeredOnStart: true
        onTriggered: {
            procsProc.running = false;
            procsProc.running = true;
        }
    }

    // ---- facts (read once) --------------------------------------------------

    FileView {
        id: cpuInfoFile
        path: "/proc/cpuinfo"
        preload: true
        printErrors: false
        onLoaded: root.readCpuInfo()
    }

    function readCpuInfo() {
        const body = `${cpuInfoFile.text() || ""}`;
        if (!body.length)
            return;
        let logical = 0;
        let coresPer = 0;
        let model = "";
        const packages = {};
        const rows = body.split("\n");
        for (let i = 0; i < rows.length; i++) {
            const line = rows[i];
            if (line.startsWith("processor"))
                logical++;
            else if (line.startsWith("physical id"))
                packages[line.split(":")[1].trim()] = true;
            else if (line.startsWith("cpu cores") && coresPer === 0)
                coresPer = parseInt(line.split(":")[1], 10) || 0;
            else if (line.startsWith("model name") && !model.length)
                model = line.split(":")[1].trim();
        }
        const pkgN = Math.max(1, Object.keys(packages).length);
        if (coresPer)
            root.cores = coresPer * pkgN;
        else if (logical)
            root.cores = logical;
        if (logical)
            root.threads = logical;
        if (model.length)
            root.cpuModel = model;
    }

    FileView {
        id: osReleaseFile
        path: "/etc/os-release"
        preload: true
        printErrors: false
        onLoaded: root.readOsRelease()
    }

    function readOsRelease() {
        const rows = `${osReleaseFile.text() || ""}`.split("\n");
        for (let i = 0; i < rows.length; i++) {
            const row = rows[i];
            const eq = row.indexOf("=");
            if (eq < 0)
                continue;
            const key = row.slice(0, eq).trim();
            const val = row.slice(eq + 1).trim().replace(/^"|"$/g, "");
            if (key === "PRETTY_NAME")
                root.distro = val;
            else if (key === "ID")
                root.distroId = val.toLowerCase();
            else if (key === "ID_LIKE")
                root.distroLike = val.toLowerCase();
        }
    }

    // The bar's distro mark: a Nerd Font "linux" glyph keyed by os-release ID
    // (codepoints from nerd-fonts glyphnames.json). An unknown ID falls back
    // through ID_LIKE, then to nothing so the caller can keep the Tanjun seal.
    readonly property var distroGlyphs: ({
        "nixos": "",
        "arch": "", "archarm": "", "archlinux": "",
        "cachyos": "", "arcolinux": "", "archcraft": "",
        "archlabs": "", "manjaro": "", "manjaro-arm": "",
        "endeavouros": "", "artix": "", "garuda": "",
        "debian": "", "devuan": "", "ubuntu": "",
        "kubuntu": "", "xubuntu": "", "lubuntu": "",
        "linuxmint": "", "pop": "", "kali": "",
        "raspbian": "", "zorin": "", "mx": "",
        "elementary": "", "deepin": "", "trisquel": "",
        "parabola": "",
        "fedora": "", "nobara": "", "rhel": "",
        "centos": "", "rocky": "", "almalinux": "",
        "ol": "",
        "opensuse-tumbleweed": "", "opensuse-leap": "",
        "opensuse": "", "sles": "", "sled": "",
        "gentoo": "", "alpine": "", "void": "",
        "solus": "", "slackware": "", "mageia": "",
        "openbsd": "", "freebsd": "", "guix": "",
        "qubes": "", "tails": "", "postmarketos": "",
        "vanilla": "", "hyperbola": ""
    })
    readonly property string distroIcon: {
        if (root.distroGlyphs[root.distroId])
            return root.distroGlyphs[root.distroId];
        const like = `${root.distroLike || ""}`.split(/\s+/);
        for (let i = 0; i < like.length; i++) {
            if (root.distroGlyphs[like[i]])
                return root.distroGlyphs[like[i]];
        }
        return "";
    }

    Process {
        id: gpuProc
        command: ["sh", "-c", "lspci 2>/dev/null | awk '/VGA|3D|Display/ { sub(/.*: /, \"\"); sub(/ \\(rev.*/, \"\"); print; exit }'"]
        running: true
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const v = `${text || ""}`.trim();
                if (v.length)
                    root.gpu = v;
            }
        }
    }

    // ---- slow facts: uptime and disk ---------------------------------------

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        preload: true
        printErrors: false
        onLoaded: root.readUptime()
    }

    function readUptime() {
        const secs = parseFloat(`${uptimeFile.text() || ""}`.split(/\s+/)[0]);
        if (!isFinite(secs))
            return;
        const h = Math.floor(secs / 3600);
        const m = Math.floor((secs % 3600) / 60);
        const text = h ? `${h}h ${m}m` : `${m}m`;
        if (root.uptime !== text)
            root.uptime = text;
    }

    Process {
        id: diskProc
        command: ["sh", "-c", "df -P -k / 2>/dev/null | awk 'NR==2 { printf \"%.0f %.0f\\n\", $3/1048576, $2/1048576 }'"]
        running: false
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const bits = `${text || ""}`.trim().split(/\s+/);
                const used = Number(bits[0]);
                const total = Number(bits[1]);
                if (!isFinite(used) || !isFinite(total) || total <= 0)
                    return;
                const pct = Math.round(100 * used / total);
                root.disk = `${used}G / ${total}G (${pct}%)`;
            }
        }
    }

    // Uptime moves by the minute and the root filesystem by the hour at most, so
    // both are read on a 30 s cadence rather than every tick.
    Timer {
        interval: 30000
        repeat: true
        running: root.wanted
        triggeredOnStart: true
        onTriggered: {
            uptimeFile.reload();
            diskProc.running = false;
            diskProc.running = true;
        }
    }

    // ---- start --------------------------------------------------------------

    Component.onCompleted: {
        root.hostName = Quickshell.env("HOSTNAME") || "";
        hostNameProc.running = true;
        // Names first: resolveTemps needs them to pick the right chips, and it
        // starts the walk itself when the names arrive.
        chipProc.running = true;
        diskProc.running = true;
    }

    Process {
        id: hostNameProc
        // One call for both of the things /proc/sys has that the facts need.
        command: ["sh", "-c", "cat /proc/sys/kernel/hostname /proc/sys/kernel/osrelease"]
        running: false
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const lines = `${text || ""}`.split("\n");
                const host = (lines[0] || "").trim();
                const release = (lines[1] || "").trim();
                if (host.length)
                    root.hostName = host;
                if (release.length)
                    root.kernel = release;
            }
        }
    }
}
