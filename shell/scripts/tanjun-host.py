#!/usr/bin/env python3
import heapq
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

WATCH = "--watch" in sys.argv
try:
    INTERVAL = float(os.environ.get("TANJUN_HOST_INTERVAL", "2"))
except ValueError:
    INTERVAL = 2.0
INTERVAL = max(0.05, min(INTERVAL, 60.0))
LIMIT = 5


def cpu_rows():
    out = []
    with open("/proc/stat", encoding="utf-8") as f:
        for line in f:
            if not line.startswith("cpu"):
                break
            parts = line.split()
            nums = [int(x) for x in parts[1:]]
            idle = nums[3] + (nums[4] if len(nums) > 4 else 0)
            out.append((idle, sum(nums)))
    return out


def mem():
    data = {}
    with open("/proc/meminfo", encoding="utf-8") as f:
        for line in f:
            bits = line.split()
            data[bits[0].rstrip(":")] = int(bits[1])
    total = data.get("MemTotal", 1)
    avail = data.get("MemAvailable", data.get("MemFree", 0))
    return total - avail, total


def net():
    rx = tx = 0
    with open("/proc/net/dev", encoding="utf-8") as f:
        f.readline()
        f.readline()
        for line in f:
            name, rest = line.split(":", 1)
            if name.strip() == "lo":
                continue
            cols = rest.split()
            rx += int(cols[0])
            tx += int(cols[8])
    return rx, tx


def comm_of(pid):
    """Full process name, or "" if the process is gone.

    /proc/<pid>/stat truncates the comm to 15 characters, so names come from
    comm instead — but only for the handful of rows that are shown.
    """
    try:
        with open(f"/proc/{pid}/comm", encoding="utf-8") as f:
            return f.read().strip()
    except (OSError, UnicodeDecodeError):
        return ""


def scan_procs(limit=LIMIT, prev=None, span=1.0):
    """Rank the busiest pids by cpu ticks.

    The sweep itself opens one file per process and nothing more: the tick
    counters and the kernel-thread test both come out of the stat line it has to
    read anyway. Comm is read afterwards, for the ranked rows only, because the
    sampler loop is the process that has to keep ticking.
    """
    me = os.getpid()
    hz = os.sysconf("SC_CLK_TCK") or 100
    now = {}
    ranked = []
    try:
        for ent in os.scandir("/proc"):
            if not ent.name.isdigit():
                continue
            pid = int(ent.name)
            if pid == me:
                continue
            try:
                with open(f"/proc/{pid}/stat", encoding="utf-8") as f:
                    stat = f.read()
                close = stat.rfind(")")
                if close < 0:
                    continue
                # Kernel threads are named in brackets, e.g. (kworker/0:1).
                if stat.startswith("[", stat.find("(") + 1):
                    continue
                rest = stat[close + 2 :].split()
                ticks = int(rest[11]) + int(rest[12])
            except (OSError, ValueError, IndexError):
                continue
            now[pid] = ticks
            if prev is None:
                ranked.append((ticks, pid, ""))
            elif pid in prev:
                dt = ticks - prev[pid]
                if dt > 0:
                    ranked.append((dt, pid, ""))
    except OSError:
        return [], now
    if prev is None:
        try:
            up = float(Path("/proc/uptime").read_text(encoding="utf-8").split()[0])
        except (OSError, ValueError, IndexError):
            up = 1.0
        denom = max(1.0, hz * max(up, 0.05))
    else:
        denom = max(1.0, hz * max(span, 0.05))
    out = []
    for dt, pid, _ in heapq.nlargest(limit, ranked):
        name = comm_of(pid)
        if not name:
            # The process can exit between the stat read and the comm read.
            continue
        out.append({"pid": pid, "name": name, "cpu": round(100.0 * dt / denom, 1)})
    return out, now


def procs(limit=5, prev=None, span=1.0):
    rows, _ = scan_procs(limit, prev, span)
    return rows


def cpu_desc():
    logical = 0
    packages = set()
    cores_per = 0
    model = ""
    try:
        with open("/proc/cpuinfo", encoding="utf-8") as f:
            for line in f:
                if line.startswith("processor"):
                    logical += 1
                elif line.startswith("physical id"):
                    packages.add(line.split(":", 1)[1].strip())
                elif line.startswith("cpu cores") and cores_per == 0:
                    try:
                        cores_per = int(line.split(":", 1)[1])
                    except ValueError:
                        pass
                elif line.startswith("model name") and not model:
                    model = line.split(":", 1)[1].strip()
    except OSError:
        pass
    cores = cores_per * max(len(packages), 1) if cores_per else logical
    return {
        "cores": cores,
        "threads": logical or os.cpu_count() or 0,
        "model": model,
    }


def cpu_temp():
    """Hottest package/soc sensor, in Celsius.

    hwmon is tried first because the x86 coretemp driver labels packages with a
    fixed name; the thermal zones are the fallback for anything else. A machine
    with neither simply reports no temperature.
    """
    found = []
    try:
        for ent in os.scandir("/sys/class/hwmon"):
            try:
                with open(f"{ent.path}/name", encoding="utf-8") as f:
                    chip = f.read().strip()
            except OSError:
                continue
            if chip not in ("coretemp", "k10temp", "zenpower", "cpu_thermal", "soc_thermal"):
                continue
            try:
                for tz in os.scandir(ent.path):
                    if not (tz.name.startswith("temp") and tz.name.endswith("_input")):
                        continue
                    try:
                        with open(tz.path, encoding="utf-8") as f:
                            found.append(int(f.read().strip()) / 1000.0)
                    except (OSError, ValueError):
                        continue
            except OSError:
                continue
        if found:
            return round(max(found), 1)
        for ent in os.scandir("/sys/class/thermal"):
            if not ent.name.startswith("thermal_zone"):
                continue
            try:
                with open(f"{ent.path}/type", encoding="utf-8") as f:
                    kind = f.read().strip().lower()
                if "cpu" not in kind and "soc" not in kind and "x86" not in kind:
                    continue
                with open(f"{ent.path}/temp", encoding="utf-8") as f:
                    found.append(int(f.read().strip()) / 1000.0)
            except (OSError, ValueError):
                continue
    except OSError:
        return None
    return round(max(found), 1) if found else None


def gpu_name():
    try:
        r = subprocess.run(["lspci"], capture_output=True, text=True, timeout=1)
    except (OSError, subprocess.TimeoutExpired):
        return ""
    for line in (r.stdout or "").splitlines():
        if "VGA" in line or "3D" in line or "Display" in line:
            return line.split(": ", 1)[-1].split(" (rev")[0].strip()
    return ""


def uptime_text():
    try:
        secs = float(Path("/proc/uptime").read_text(encoding="utf-8").split()[0])
    except (OSError, ValueError, IndexError):
        return ""
    h = int(secs // 3600)
    m = int((secs % 3600) // 60)
    if h:
        return f"{h}h {m}m"
    return f"{m}m"


def disk_text():
    try:
        u = shutil.disk_usage("/")
    except OSError:
        return ""
    used = u.used / 1024**3
    total = u.total / 1024**3
    pct_n = int(100 * u.used / u.total) if u.total else 0
    fmt = lambda n: f"{n:.0f}G" if n >= 10 else f"{n:.1f}G"
    return f"{fmt(used)} / {fmt(total)} ({pct_n}%)"


def os_name():
    pretty = ""
    try:
        with open("/etc/os-release", encoding="utf-8") as f:
            for line in f:
                if line.startswith("PRETTY_NAME="):
                    pretty = line.split("=", 1)[1].strip().strip('"')
                    break
    except OSError:
        pass
    return pretty or "Linux"


def pct(a, b):
    idle1, tot1 = a
    idle2, tot2 = b
    dt = max(1, tot2 - tot1)
    return max(0.0, min(100.0, 100.0 * (1.0 - (idle2 - idle1) / dt)))


def sample(prev, facts, want=0):
    a2 = cpu_rows()
    r2, u2 = net()
    t2 = time.monotonic()
    if prev is None:
        cpu = 0.0
        core_pct = []
        down = up = 0
        span = INTERVAL
        proc_rows, proc_map = scan_procs(want or LIMIT, None, span)
    else:
        span = max(0.05, t2 - prev["t"])
        cpu = pct(prev["cpu"][0], a2[0]) if prev["cpu"] and a2 else 0.0
        core_pct = [
            round(pct(prev["cpu"][i], a2[i]), 1)
            for i in range(1, min(len(prev["cpu"]), len(a2)))
        ]
        down = round(max(0.0, (r2 - prev["rx"]) / span))
        up = round(max(0.0, (u2 - prev["tx"]) / span))
        proc_rows, proc_map = scan_procs(want or LIMIT, prev["procs"], span)
    used, total = mem()
    temp = cpu_temp()
    out = {
        "cpu": round(cpu, 1),
        "corePct": core_pct,
        "ramUsed": used,
        "ramTotal": total,
        "down": down,
        "up": up,
        "procs": proc_rows,
        "uptime": uptime_text(),
        "disk": disk_text(),
    }
    if temp is not None:
        out["temp"] = temp
    if facts:
        desc = cpu_desc()
        out.update(
            {
                "user": os.environ.get("USER") or os.environ.get("LOGNAME") or "",
                "host": os.uname().nodename,
                "distro": os_name(),
                "kernel": os.uname().release,
                "cores": desc["cores"],
                "threads": desc["threads"],
                "cpuModel": desc["model"],
                "gpu": gpu_name(),
            }
        )
    nxt = {"cpu": a2, "rx": r2, "tx": u2, "t": t2, "procs": proc_map}
    return out, nxt


def main() -> None:
    prev = None
    facts = True
    while True:
        out, prev = sample(prev, facts)
        print(json.dumps(out), flush=True)
        facts = False
        if not WATCH:
            return
        time.sleep(INTERVAL)


if __name__ == "__main__":
    main()
