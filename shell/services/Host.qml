pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

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
    property string kernel: ""
    property int cores: 0
    property int threads: 0
    property string cpuModel: ""
    property string gpu: ""
    property string hostName: ""
    property string uptime: ""
    property string disk: ""
    property var corePct: []
    property bool facts: false
    // Set by whatever is showing live numbers. The sidebar, the system page, the
    // bar readout and the load menu each want the full sampler without the others
    // being open.
    property bool menuOpen: false
    // The bar readout is visible at all times, so it asks for the sampler too and
    // the numbers stay live without a menu being open.
    property bool barReading: false
    readonly property bool ticking: proc.running
    readonly property bool wanted: barReading || UiMode.sidebarOpen || menuOpen || (UiMode.settingsOpen && SettingsNav.page === "system")
    // A real reader shows more than the bar readout, so it earns a faster tick.
    readonly property bool panelOpen: UiMode.sidebarOpen || menuOpen || (UiMode.settingsOpen && SettingsNav.page === "system")
    // Only the sidebar lists top processes; nobody else sees Host.procs, so the
    // per-pid /proc sweep is skipped while it is closed.
    readonly property bool procsWanted: UiMode.sidebarOpen
    readonly property int interval: panelOpen ? 2 : 5

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

    function fmtRate(bps) {
        if (bps < 1024)
            return `${bps}B/s`;
        if (bps < 1024 * 1024)
            return `${(bps / 1024).toFixed(1)}K/s`;
        return `${(bps / 1024 / 1024).toFixed(1)}M/s`;
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
        for (let i = 0; i < a.length; i++) {
            if (a[i].pid !== b[i].pid || a[i].cpu !== b[i].cpu || a[i].name !== b[i].name)
                return false;
        }
        return true;
    }

    function apply(d) {
        if (d.cpu !== undefined && d.cpu !== root.cpu)
            root.cpu = d.cpu;
        if (d.temp !== undefined)
            root.temp = d.temp;
        if (d.ramUsed !== undefined)
            root.ramUsed = d.ramUsed;
        if (d.ramTotal)
            root.ramTotal = d.ramTotal;
        if (d.down !== undefined)
            root.down = d.down;
        if (d.up !== undefined)
            root.up = d.up;
        if (d.procs && !sameProcs(root.procs, d.procs))
            root.procs = d.procs;
        if (d.corePct && !sameNums(root.corePct, d.corePct))
            root.corePct = d.corePct;
        if (d.user)
            root.user = d.user;
        if (d.distro)
            root.distro = d.distro;
        if (d.kernel)
            root.kernel = d.kernel;
        if (d.cores)
            root.cores = d.cores;
        if (d.threads)
            root.threads = d.threads;
        if (d.cpuModel)
            root.cpuModel = d.cpuModel;
        if (d.gpu)
            root.gpu = d.gpu;
        if (d.host)
            root.hostName = d.host;
        if (d.uptime)
            root.uptime = d.uptime;
        if (d.disk)
            root.disk = d.disk;
        if (d.distro || d.cpu !== undefined)
            root.facts = true;
    }

    function killProc(pid) {
        const n = Number(pid);
        if (!n || n <= 1)
            return;
        Quickshell.execDetached(["kill", "-TERM", `${n}`]);
    }

    readonly property string controlPath: `${Config.stateDir}/host.json`

    // The sampler is a separate process, so its tick rate and whether it sweeps
    // /proc/<pid> are passed to it through a small handshake file it re-reads
    // every tick. Written only when the values change; Config creates the dir.
    function writeControl() {
        Config.ensureStateDir();
        const body = JSON.stringify({ procs: root.procsWanted, interval: root.interval });
        if (hostCtl.path !== root.controlPath)
            hostCtl.path = root.controlPath;
        hostCtl.setText(body);
    }

    onProcsWantedChanged: writeControl()
    onIntervalChanged: writeControl()

    FileView {
        id: hostCtl
        path: root.controlPath
        printErrors: false
        atomicWrites: true
    }

    Component.onCompleted: writeControl()

    Process {
        id: proc
        command: ["python3", `${Quickshell.shellDir}/scripts/tanjun-host.py`, "--watch", "--control", `${Config.stateDir}/host.json`]
        running: root.wanted
        stdout: SplitParser {
            onRead: line => {
                const s = `${line || ""}`.trim();
                if (!s.length)
                    return;
                try {
                    root.apply(JSON.parse(s));
                } catch (e) {}
            }
        }
    }

    // The bar shows memory, so it needs a reading before any menu is opened.
    // /proc/meminfo is read directly rather than through the sampler: the whole
    // sweep of /proc/<pid> costs milliseconds, while this costs tens of
    // microseconds, so the bar can afford it on a timer. watchChanges would not
    // work here — /proc has no inotify support, so the watch would never fire.
    FileView {
        id: memInfo
        path: "/proc/meminfo"
        preload: true
        printErrors: false
        onLoaded: root.readMem()
    }

    // A memory reading that is a couple of seconds old reads the same as a live
    // one; the bar only needs to notice that the number moved.
    Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: memInfo.reload()
    }

    function readMem() {
        const body = `${memInfo.text() || ""}`;
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
        // Same definition the sampler uses: used is whatever is not available.
        root.ramTotal = total;
        root.ramUsed = total - (avail || free);
    }
}
