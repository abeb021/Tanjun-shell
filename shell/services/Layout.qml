pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property string keymap: labelOf(Compositor.layoutName)

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

    function cycle() {
        Compositor.cycleLayout();
    }
}
