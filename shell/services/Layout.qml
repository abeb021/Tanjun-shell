pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    property string keymap: "EN"

    function labelOf(t) {
        const low = `${t || ""}`.toLowerCase();
        if (low.indexOf("ru") >= 0 || low.indexOf("russian") >= 0)
            return "RU";
        if (low.indexOf("us") >= 0 || low.indexOf("english") >= 0)
            return "EN";
        if (t.length)
            return t.length <= 4 ? t.toUpperCase() : t.slice(0, 2).toUpperCase();
        return "EN";
    }

    function refresh() {
        if (Compositor.isNiri) {
            keymap = labelOf(Compositor.niriKeymap);
            return;
        }
        proc.running = true;
    }

    function cycle() {
        Compositor.cycleLayout();
        Qt.callLater(refresh);
    }

    Process {
        id: proc
        command: ["bash", "-c", "hyprctl devices -j | python -c \"import json,sys; d=json.load(sys.stdin); ks=d.get('keyboards',[]); k=next((x for x in ks if x.get('main')), ks[0] if ks else {}); print(k.get('active_keymap',''))\""]
        running: Compositor.isHypr
        stdout: StdioCollector {
            onStreamFinished: root.keymap = root.labelOf(text.trim())
        }
    }

    Connections {
        target: Hyprland
        enabled: Compositor.isHypr
        function onRawEvent(event) {
            if (event.name === "activelayout")
                root.refresh();
        }
    }

    Connections {
        target: Compositor
        function onNiriKeymapChanged() {
            if (Compositor.isNiri)
                root.keymap = root.labelOf(Compositor.niriKeymap);
        }
    }

    Component.onCompleted: refresh()
}
