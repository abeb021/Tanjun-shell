from __future__ import annotations

import os
import shutil
import signal
import subprocess
import tempfile
import threading
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SHELL = ROOT / "shell"
COMP = ROOT / "compositors"
SCRIPTS = ROOT / "scripts"

PALETTE_KEYS = (
    "name",
    "label",
    "kind",
    "accent",
    "accentHover",
    "critical",
    "warning",
    "info",
    "good",
    "fg",
    "fgSub",
    "bg",
    "surface",
    "surfaceHover",
)

QS_BIN = shutil.which("qs") or shutil.which("quickshell")


def run(cmd: list[str], **kw) -> subprocess.CompletedProcess:
    return subprocess.run(
        cmd,
        check=False,
        capture_output=True,
        text=True,
        **kw,
    )


class Qs:
    """Boot an owned Tanjun instance. Never attach to the live desktop shell."""

    def __init__(self) -> None:
        self.bin = QS_BIN
        self.proc: subprocess.Popen | None = None
        self.log = ""
        self.owned = False
        self._buf: list[str] = []
        self.path = SHELL
        self.home: Path | None = None

    def ipc(self, *args: str, timeout: float = 5) -> subprocess.CompletedProcess:
        cmd = [self.bin, "ipc"]
        if self.owned and self.proc and self.proc.pid:
            cmd += ["--pid", str(self.proc.pid)]
        else:
            cmd += ["-p", str(self.path), "--any-display"]
        cmd += list(args)
        return run(cmd, timeout=timeout)

    def start(self) -> str:
        if not self.bin:
            return "qs not on PATH"
        env = os.environ.copy()
        env.setdefault("QT_QPA_PLATFORM", "wayland")
        env["QT_QUICK_BACKEND"] = "software"
        self.home = Path(tempfile.mkdtemp(prefix="tanjun-qs-"))
        cfg = self.home / "config"
        state = self.home / "state"
        cache = self.home / "cache"
        cfg.mkdir()
        state.mkdir()
        cache.mkdir()
        env["XDG_CONFIG_HOME"] = str(cfg)
        env["XDG_STATE_HOME"] = str(state)
        env["XDG_CACHE_HOME"] = str(cache)
        env["TANJUN_TEST"] = "1"
        self.proc = subprocess.Popen(
            [self.bin, "-p", str(self.path), "--no-color"],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            env=env,
            start_new_session=True,
        )
        self.owned = True

        def pump() -> None:
            assert self.proc and self.proc.stdout
            for line in self.proc.stdout:
                self._buf.append(line)

        threading.Thread(target=pump, daemon=True).start()
        deadline = time.time() + 8
        while time.time() < deadline:
            self.log = "".join(self._buf)
            if "Failed to load configuration" in self.log:
                return self.log
            if "Configuration Loaded" in self.log:
                return ""
            if self.proc.poll() is not None:
                time.sleep(0.1)
                self.log = "".join(self._buf)
                return self.log or f"qs exited {self.proc.returncode}"
            time.sleep(0.05)
        self.log = "".join(self._buf)
        return self.log or "timeout waiting for Configuration Loaded"

    def stop(self) -> None:
        if not self.owned:
            return
        pid = self.proc.pid if self.proc else 0
        if pid:
            run([self.bin, "kill", "--pid", str(pid)], timeout=5)
            try:
                os.killpg(pid, signal.SIGTERM)
            except OSError:
                pass
        if self.proc and self.proc.poll() is None:
            self.proc.terminate()
            try:
                self.proc.wait(timeout=3)
            except subprocess.TimeoutExpired:
                self.proc.kill()
        if self.home:
            shutil.rmtree(self.home, ignore_errors=True)
            self.home = None
