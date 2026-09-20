#!/usr/bin/env python3
import json
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

TICK = "--tick" in sys.argv
RT = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / "tanjun-host.prev"


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
            name = name.strip()
            if name == "lo":
                continue
            cols = rest.split()
            rx += int(cols[0])
            tx += int(cols[8])
    return rx, tx


def procs(limit=5):
    me = os.getpid()
    out = []
    try:
        raw = os.popen("ps -eo pid,pcpu,comm --no-headers --sort=-pcpu").read()
    except OSError:
        return out
    for line in raw.splitlines():
        parts = line.strip().split(None, 2)
        if len(parts) < 3:
            continue
        try:
            if int(parts[0]) == me:
                continue
            cpu = float(parts[1])
        except ValueError:
            continue
        name = parts[2]
        if name.startswith("["):
            continue
        out.append({"pid": int(parts[0]), "name": name, "cpu": round(cpu, 1)})
        if len(out) >= limit:
            break
    return out


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
    pct = int(100 * u.used / u.total) if u.total else 0
    fmt = lambda n: f"{n:.0f}G" if n >= 10 else f"{n:.1f}G"
    return f"{fmt(used)} / {fmt(total)} ({pct}%)"


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


def load_prev():
    try:
        d = json.loads(RT.read_text())
        if time.monotonic() - float(d.get("t", 0)) > 8:
            return None
        return d
    except (OSError, ValueError, TypeError):
        return None


def save_prev(rows, rx, tx) -> None:
    try:
        RT.write_text(
            json.dumps({"cpu": rows, "rx": rx, "tx": tx, "t": time.monotonic()})
        )
    except OSError:
        pass


prev = load_prev()
a2 = cpu_rows()
r2, u2 = net()
if prev is None:
    time.sleep(0.12)
    a1 = a2
    r1, u1 = r2, u2
    a2 = cpu_rows()
    r2, u2 = net()
    span = 0.12
else:
    a1 = [tuple(x) for x in prev["cpu"]]
    r1, u1 = int(prev["rx"]), int(prev["tx"])
    span = max(0.05, time.monotonic() - float(prev["t"]))
save_prev(a2, r2, u2)

cpu = pct(a1[0], a2[0]) if a1 and a2 else 0.0
core_pct = []
for i in range(1, min(len(a1), len(a2))):
    core_pct.append(round(pct(a1[i], a2[i]), 1))
used, total = mem()

out = {
    "cpu": round(cpu, 1),
    "corePct": core_pct,
    "ramUsed": used,
    "ramTotal": total,
    "down": round(max(0.0, (r2 - r1) / span)),
    "up": round(max(0.0, (u2 - u1) / span)),
    "procs": procs(),
    "uptime": uptime_text(),
    "disk": disk_text(),
}
if not TICK:
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

print(json.dumps(out))
