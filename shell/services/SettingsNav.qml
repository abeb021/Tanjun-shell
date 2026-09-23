pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var pages: [
        { key: "system", label: "System", icon: "󰒓" },
        { key: "sound", label: "Sound", icon: "" },
        { key: "screen", label: "Screen", icon: "󰍹" },
        { key: "battery", label: "Battery", icon: "󰁹" },
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
    property int toggleGap: -1
    property int toggleRadius: -1

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
            { title: "Night light", sub: "screen", page: "screen", hay: "night light kelvin temperature warmth hyprsunset" },
            { title: "Night at", sub: "screen", page: "screen", hay: "night at sunset 21:00 timer hyprsunset warm" },
            { title: "Day at", sub: "screen", page: "screen", hay: "day at sunrise 5:30 identity timer hyprsunset" },
            { title: "battery", sub: "page", page: "battery", hay: "battery idle dim lock sleep hibernate rest power" },
            { title: "Dim", sub: "battery", page: "battery", hay: "dim brightness idle 2 min rest" },
            { title: "Lock", sub: "battery", page: "battery", hay: "lock idle 5 min rest" },
            { title: "Screen off", sub: "battery", page: "battery", hay: "screen off dpms idle 10 min rest" },
            { title: "Sleep", sub: "battery", page: "battery", hay: "sleep suspend idle 15 min rest" },
            { title: "Hibernate", sub: "battery", page: "battery", hay: "hibernate idle 30 min rest later" },
            { title: "style", sub: "page", page: "style", hay: "style chrome panel tanjun minimal look shell rail ticks animation motion" },
            { title: "Minimal", sub: "style", page: "style", hay: "minimal quiet plane rice tanjun" },
            { title: "Chrome", sub: "style", page: "style", hay: "chrome ticks chips marked rail panel" },
            { title: "Instant", sub: "style", page: "style", hay: "instant off none animation motion" },
            { title: "Quiet", sub: "style", page: "style", hay: "quiet animation motion default" },
            { title: "Snappy", sub: "style", page: "style", hay: "snappy fast animation motion" },
            { title: "Soft", sub: "style", page: "style", hay: "soft slow animation motion" },
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
