pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var pages: [
        { key: "system", label: "System", icon: "󰒓" },
        { key: "sound", label: "Sound", icon: "" },
        { key: "screen", label: "Screen", icon: "󰍹" },
        { key: "network", label: "Network", icon: "󰖩" },
        { key: "bluetooth", label: "Bluetooth", icon: "󰂯" },
        { key: "type", label: "Type", icon: "󰛖" },
        { key: "clock", label: "Clock", icon: "󰥔" },
        { key: "weather", label: "Weather", icon: "󰖕" },
        { key: "devices", label: "Devices", icon: "󰃠" },
        { key: "style", label: "Style", icon: "󰀼" },
        { key: "color", label: "Color", icon: "󰏘" }
    ]

    property string page: "system"
    property int railCount: 0
    property int railH: 0
    property int scrollY: 0
    property int styleCount: 0

    readonly property var catalog: {
        const out = [
            { title: "system", sub: "page", page: "system", hay: "system host os kernel cpu gpu ram disk uptime" },
            { title: "sound", sub: "page", page: "sound", hay: "sound volume mute output mic mixer apps" },
            { title: "network", sub: "page", page: "network", hay: "network wifi ssid vpn scan" },
            { title: "bluetooth", sub: "page", page: "bluetooth", hay: "bluetooth buds adapter scan pair" },
            { title: "type", sub: "page", page: "type", hay: "type font ui japanese icons size reset" },
            { title: "ui font", sub: "type", page: "type", face: "ui", hay: "ui font jetbrains mono typeface" },
            { title: "japanese font", sub: "type", page: "type", face: "jp", hay: "japanese font noto sans cjk jp 単" },
            { title: "icons font", sub: "type", page: "type", face: "icons", hay: "icons font nerd symbols" },
            { title: "clock", sub: "page", page: "clock", hay: "clock timezone 12 24 hour" },
            { title: "Moscow", sub: "clock", page: "clock", hay: "moscow europe/moscow timezone clock" },
            { title: "Melbourne", sub: "clock", page: "clock", hay: "melbourne australia/melbourne timezone clock" },
            { title: "12 hour", sub: "clock", page: "clock", hay: "12 hour am pm clock" },
            { title: "24 hour", sub: "clock", page: "clock", hay: "24 hour clock" },
            { title: "weather", sub: "page", page: "weather", hay: "weather city wttr moscow" },
            { title: "devices", sub: "page", page: "devices", hay: "devices backlight keyboard intel_backlight" },
            { title: "intel_backlight", sub: "devices", page: "devices", hay: "intel_backlight brightness light" },
            { title: "screen", sub: "page", page: "screen", hay: "screen monitor display scale gamma output edp brightness layout first second extend" },
            { title: "scale", sub: "screen", page: "screen", hay: "scale 1.2 fractional scaling monitor" },
            { title: "gamma", sub: "screen", page: "screen", hay: "gamma hyprsunset night identity" },
            { title: "style", sub: "page", page: "style", hay: "style chrome panel tanjun look shell rail ticks" },
            { title: "Tanjun", sub: "style", page: "style", hay: "tanjun quiet plane rice chrome" },
            { title: "Panel", sub: "style", page: "style", hay: "panel chrome ticks chips marked rail" },
            { title: "color", sub: "page", page: "color", hay: "color theme palette preset" },
            { title: "From wall", sub: "color", page: "color", kind: "wall", name: "wall", hay: "from wall wallpaper accent sample" },
            { title: "keep palette", sub: "color", page: "color", hay: "keep palette wallpaper colors pull sample" }
        ];
        const p = Theme.presets;
        for (let i = 0; i < p.length; i++) {
            const t = p[i];
            out.push({
                title: t.label,
                sub: "color",
                page: "color",
                kind: t.kind,
                name: t.name,
                hay: `${t.label} ${t.name} ${t.kind} color theme palette`
            });
        }
        return out;
    }

    function pageOk(id) {
        const rows = pages;
        for (let i = 0; i < rows.length; i++) {
            if (rows[i].key === id)
                return true;
        }
        return false;
    }

    function openPage(id) {
        if (!pageOk(id))
            return;
        scrollY = 0;
        page = id;
        if (!UiMode.settingsOpen)
            UiMode.toggleSettings();
    }
}
