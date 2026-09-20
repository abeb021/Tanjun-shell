pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real cpu: 0
    property int ramUsed: 0
    property int ramTotal: 1
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

    readonly property real ramRatio: ramTotal > 0 ? ramUsed / ramTotal : 0
    readonly property string ramText: `${fmtGiB(ramUsed)} / ${fmtGiB(ramTotal)}`
    readonly property string cpuText: `${cpu.toFixed(0)}%`
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

    function killProc(pid) {
        const n = Number(pid);
        if (!n || n <= 1)
            return;
        Quickshell.execDetached(["kill", "-TERM", `${n}`]);
        Qt.callLater(refresh);
    }

    function refresh() {
        proc.running = false;
        proc.running = true;
    }

    Process {
        id: proc
        command: root.facts ? ["python3", `${Quickshell.shellDir}/scripts/tanjun-host.py`, "--tick"] : ["python3", `${Quickshell.shellDir}/scripts/tanjun-host.py`]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    root.cpu = d.cpu ?? root.cpu;
                    root.ramUsed = d.ramUsed ?? root.ramUsed;
                    root.ramTotal = d.ramTotal || root.ramTotal;
                    root.down = d.down ?? root.down;
                    root.up = d.up ?? root.up;
                    if (d.procs)
                        root.procs = d.procs;
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
                    if (d.corePct)
                        root.corePct = d.corePct;
                    if (d.distro || d.cpu !== undefined)
                        root.facts = true;
                } catch (e) {}
            }
        }
    }

    Connections {
        target: ShellState
        function onSidebarOpenChanged() {
            if (ShellState.sidebarOpen)
                root.refresh();
        }
        function onSettingsOpenChanged() {
            if (ShellState.settingsOpen)
                root.refresh();
        }
    }

    Timer {
        interval: 2000
        running: ShellState.sidebarOpen || ShellState.settingsOpen
        repeat: true
        onTriggered: root.refresh()
    }
}
