from __future__ import annotations

import os
import shutil
import subprocess
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
    """Talk to a live tanjun instance, or start one for the repo shell."""

    def __init__(self) -> None:
        self.bin = QS_BIN
        self.proc: subprocess.Popen | None = None
        self.log = ""
        self.owned = False
        self._buf: list[str] = []
        self.path = SHELL
        linked = (Path.home() / ".config" / "quickshell").resolve()
        self.use_default = linked == SHELL

    def ipc(self, *args: str, timeout: float = 5) -> subprocess.CompletedProcess:
        cmd = [self.bin, "ipc"]
        if self.owned or not self.use_default:
            cmd += ["-p", str(self.path), "--any-display"]
        cmd += list(args)
        return run(cmd, timeout=timeout)

    def start(self) -> str:
        if not self.bin:
            return "qs not on PATH"
        show = self.ipc("show")
        if show.returncode == 0 and "target tanjun" in (show.stdout or ""):
            self.log = show.stdout
            return ""
        env = os.environ.copy()
        env.setdefault("QT_QPA_PLATFORM", "wayland")
        self.proc = subprocess.Popen(
            [self.bin, "-p", str(self.path), "--no-color"],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            env=env,
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
            if "Configuration Loaded" in self.log:
                return ""
            if "Failed to load configuration" in self.log:
                return self.log
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
        run([self.bin, "kill", "-p", str(self.path), "--any-display"], timeout=5)
        if self.proc and self.proc.poll() is None:
            self.proc.terminate()
            try:
                self.proc.wait(timeout=3)
            except subprocess.TimeoutExpired:
                self.proc.kill()
