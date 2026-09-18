---@module 'hl'

hl.window_rule({
    match = { class = "org.telegram.desktop", title = "Media viewer" },
    float = true,
    size = "70% 70%",
    center = true,
})

hl.window_rule({
    match = { class = "xdg-desktop-portal-gtk" },
    float = true,
    center = true,
    size = "(monitor_w*0.5) (monitor_h*0.5)",
})

hl.window_rule({
    match = { title = "File Upload|Open|Save|Select|Library" },
    float = true,
    center = true,
    size = "(monitor_w*0.5) (monitor_h*0.5)",
})

hl.window_rule({
    match = { class = "mpv" },
    float = true,
    stay_focused = true,
})

hl.window_rule({
    match = { title = "Picture-in-Picture" },
    float = true,
})

hl.window_rule({
    match = { title = "Yazi" },
    float = true,
    size = "70% 70%",
    center = true,
})

hl.layer_rule({
    match = { namespace = "hyprpicker" },
    no_anim = true,
})

hl.layer_rule({
    match = { namespace = "selection" },
    no_anim = true,
})

for _, ns in ipairs({
    "tanjun-bar",
    "tanjun-sidebar",
    "tanjun-launcher",
    "tanjun-clipboard",
    "tanjun-overview",
    "tanjun-settings",
    "tanjun-polkit",
    "tanjun-osd",
    "tanjun-toast",
}) do
    hl.layer_rule({
        match = { namespace = ns },
        no_anim = true,
    })
end
