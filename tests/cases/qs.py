from __future__ import annotations

import json
import os
import time

from lib import QS_BIN, Qs

# Smoke test for a real Quickshell process.
#
# The old suite here opened every panel and read `uiMode` back 300 times. That
# proved the IPC verbs existed, but never that the shell was correct: a QML
# binding referencing an undeclared property, a FileView that is never reloaded,
# a sensor path that resolves to nothing — all of those leave the UI looking
# normal and were caught by eye or not at all. What is checked here is the two
# things that actually fail in practice:
#
#   1. the log, which is where QML reports its own errors, and
#   2. the live numbers, which is where a wrong read shows up as a zero.
#
# Anything that can be checked without booting a shell lives in the other cases
# files (calc, fuzzy, paint, config), which cost milliseconds.

# QML reports broken bindings at runtime only through the scene log; nothing else
# in the process raises.
LOG_FATAL = (
    "Type .* unavailable",
    "is not defined",
    "Cannot assign to non-existent property",
    "Cannot read property",
    "Unable to assign",
    "Error: Cannot",
    "Failed to load configuration",
)

# Warnings that come from the environment the test runs in, not from the shell:
# another agent owns the bus when a real session is up.
LOG_IGNORE = (
    "polkit",
    "PolicyKit",
    "org.freedesktop.Notifications",
    "notification server",
    "QtWaylandClient",
    "textinput",
    "Signal detected",
)


def _fatal_lines(log: str) -> list[str]:
    out = []
    for line in (log or "").splitlines():
        low = line.lower()
        if any(ign.lower() in low for ign in LOG_IGNORE):
            continue
        if "warn" in low and "scene" not in low:
            continue
        if not any(marker.lower() in low for marker in LOG_FATAL):
            continue
        out.append(line.strip())
    return out


def _host_json(qs: Qs):
    r = qs.ipc("call", "tanjun", "hostJson")
    if r.returncode != 0:
        return None
    try:
        return json.loads((r.stdout or "").strip() or "null")
    except json.JSONDecodeError:
        return None


def register(s) -> None:
    if not QS_BIN:
        s.ok("qs on PATH", False, "qs not on PATH; smoke test skipped")
        return
    if not os.environ.get("WAYLAND_DISPLAY"):
        s.ok("wayland display", False, "WAYLAND_DISPLAY unset; smoke test skipped")
        return

    qs = Qs()
    err = qs.start()
    try:
        s.ok("qs boots", not err, (err or qs.log)[-800:])
        if err:
            return
        s.ok("configuration loaded", "Configuration Loaded" in (qs.log or ""), (qs.log or "")[-400:])

        # The sampler is idle unless something asks for numbers, and the test host
        # ignores the always-on bar readout on purpose. Opening the stats menu is
        # how a real session starts it, so the test does the same.
        qs.ipc("call", "tanjun", "toggleStats")

        # Let the startup one-shots (facts, sensor discovery, disk) finish. Nothing
        # here waits on a panel, so an idle shell must still fill these in.
        deadline = time.time() + 8
        host = None
        while time.time() < deadline:
            host = _host_json(qs)
            if host and host.get("ramTotal") and host.get("cores"):
                break
            time.sleep(0.3)

        s.ok("hostJson responds", isinstance(host, dict), str(host)[:300])
        if isinstance(host, dict):
            # A read that silently fails shows up as a zero or a sentinel here and
            # nowhere else: no exception is raised for a FileView of an empty path.
            s.ok("host ram total", (host.get("ramTotal") or 0) > 0, str(host.get("ramTotal")))
            s.ok("host ram used sane", 0 < (host.get("ramUsed") or 0) <= (host.get("ramTotal") or 0), str(host.get("ramUsed")))
            s.ok("host cores", (host.get("cores") or 0) > 0, str(host.get("cores")))
            s.ok("host threads", (host.get("threads") or 0) > 0, str(host.get("threads")))
            s.ok("host cpu model", bool(host.get("cpuModel")), str(host.get("cpuModel")))
            s.ok("host distro", bool(host.get("distro")), str(host.get("distro")))
            s.ok("host kernel", bool(host.get("kernel")), str(host.get("kernel")))
            s.ok("host hostname", bool(host.get("hostName")), str(host.get("hostName")))
            s.ok("host uptime", bool(host.get("uptime")), str(host.get("uptime")))
            s.ok("host disk", bool(host.get("disk")), str(host.get("disk")))
            s.ok("host temp sensors found", (host.get("tempSensors") or 0) > 0, str(host.get("tempSensors")))
            s.ok("host interval", host.get("interval") in (2000, 5000), str(host.get("interval")))
            s.ok("host procs gated", host.get("wantProcs") in (True, False), str(host.get("wantProcs")))

        # One sample interval later the counters must have moved. This is the check
        # that catches a FileView that is never reloaded: the values are valid JSON
        # and in range, they just never change, and cpu pins at 100 from a 1-tick
        # delta.
        # A settle window of at least two ticks: the first tick only establishes
        # the CPU baseline, so `corePct` is empty and a delta cannot be computed
        # until the second.
        first = _host_json(qs)
        time.sleep(4)
        second = _host_json(qs)
        if isinstance(first, dict) and isinstance(second, dict):
            cores = second.get("corePct") or []
            s.ok("host core pct length", len(cores) == (second.get("threads") or 0), f"{len(cores)} vs {second.get('threads')}")
            s.ok("host cpu in range", 0 <= (second.get("cpu") or 0) <= 100, str(second.get("cpu")))
            s.ok("host cpu not pinned", (second.get("cpu") or 0) < 100, str(second.get("cpu")))
            s.ok("host uptime present", isinstance(second.get("uptime"), str), str(second.get("uptime")))
            # -1 is the "never read" sentinel. On a machine whose sensors were
            # discovered, a real reading must have replaced it.
            if (second.get("tempSensors") or 0) > 0:
                s.ok("host temp read", (second.get("temp") or -1) > 0, str(second.get("temp")))

        fatal = _fatal_lines(qs.log)
        s.ok("no qml errors in log", not fatal, "\n".join(fatal[:5]))
    finally:
        qs.stop()
