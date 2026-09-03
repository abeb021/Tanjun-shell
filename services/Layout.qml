pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    property string keymap: "EN"

    function refresh() {
        proc.running = true;
    }

    function cycle() {
        const quoted = Config.services.keyboard.length ? `'${String(Config.services.keyboard).replace(/'/g, "'\\''")}'` : `"$(${root.mainKbPy})"`;
        Quickshell.execDetached(["bash", "-c", `hyprctl switchxkblayout ${quoted} next`]);
        Qt.callLater(refresh);
    }

    readonly property string mainKbPy: "hyprctl devices -j | python -c \"import json,sys; d=json.load(sys.stdin); ks=d.get('keyboards',[]); k=next((x for x in ks if x.get('main')), ks[0] if ks else {}); print(k.get('name',''))\""

    Process {
        id: proc
        command: ["bash", "-c", "hyprctl devices -j | python -c \"import json,sys; d=json.load(sys.stdin); ks=d.get('keyboards',[]); k=next((x for x in ks if x.get('main')), ks[0] if ks else {}); print(k.get('active_keymap',''))\""]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim();
                const low = t.toLowerCase();
                if (low.indexOf("ru") >= 0 || low.indexOf("russian") >= 0)
                    root.keymap = "RU";
                else if (low.indexOf("us") >= 0 || low.indexOf("english") >= 0)
                    root.keymap = "EN";
                else if (t.length)
                    root.keymap = t.length <= 4 ? t.toUpperCase() : t.slice(0, 2).toUpperCase();
            }
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "activelayout")
                root.refresh();
        }
    }
}
