pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property string keymap: labelOf(Compositor.layoutName)

    function labelOf(t) {
        const low = `${t || ""}`.toLowerCase();
        if (low.indexOf("russian") >= 0 || low === "ru" || /\bru\b/.test(low))
            return "RU";
        if (low.indexOf("english") >= 0 || low === "us" || /\bus\b/.test(low))
            return "EN";
        return "EN";
    }

    function cycle() {
        Compositor.cycleLayout();
    }
}
