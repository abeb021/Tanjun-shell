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
        Quickshell.execDetached(["hyprctl", "switchxkblayout", "at-translated-set-2-keyboard", "next"]);
        Qt.callLater(refresh);
    }

    Process {
        id: proc
        command: ["bash", "-c", "hyprctl devices -j | python -c \"import json,sys; d=json.load(sys.stdin); ks=d.get('keyboards',[]); k=next((x for x in ks if x.get('main')), ks[0] if ks else {}); print(k.get('active_keymap',''))\""]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim().toLowerCase();
                if (t.indexOf("ru") >= 0 || t.indexOf("russian") >= 0)
                    root.keymap = "RU";
                else
                    root.keymap = "EN";
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

    Timer {
        interval: 4000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
