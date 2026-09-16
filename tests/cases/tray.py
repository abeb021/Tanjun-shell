from __future__ import annotations

from lib import SHELL, read


def register(s) -> None:
    tray = read(SHELL / "modules" / "bar" / "TrayBtn.qml")
    pop = read(SHELL / "modules" / "popouts" / "TrayPop.qml")
    state = read(SHELL / "services" / "ShellState.qml")
    bar = read(SHELL / "modules" / "bar" / "Bar.qml")
    s.has("tray right menu", tray, "onRightClicked")
    s.has("tray openTray", tray, "ShellState.openTray")
    s.has("tray hasMenu", tray, "modelData.hasMenu")
    s.has("tray onlyMenu", tray, "modelData.onlyMenu")
    s.has("tray activate", tray, "modelData.activate()")
    s.has("tray secondary", tray, "modelData.secondaryActivate()")
    s.has("tray scroll", tray, "modelData.scroll")
    s.has("state openTray", state, "function openTray")
    s.has("state trayItem", state, "property var trayItem")
    s.has("tray pop QsMenuOpener", pop, "QsMenuOpener")
    s.has("tray pop trigger", pop, "modelData.triggered()")
    s.has("tray pop back", pop, "back")
    s.has("tray pop stack", pop, "property var stack")
    s.has("bar SystemTray", bar, "SystemTray.items")
    s.has("bar TrayBtn delegate", bar, "delegate: TrayBtn")
    s.has("bar TrayPop", bar, "TrayPop")
