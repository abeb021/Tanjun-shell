#!/usr/bin/env python3
"""Start or stop OBS recording via the local WebSocket. Reads ~/.config/obs-studio."""
from __future__ import annotations

import base64
import hashlib
import json
import sys
import time
from pathlib import Path

from websocket import create_connection

CONFIG = Path.home() / ".config/obs-studio/plugin_config/obs-websocket/config.json"


def auth_string(password: str, salt: str, challenge: str) -> str:
    secret = base64.b64encode(hashlib.sha256((password + salt).encode()).digest()).decode()
    return base64.b64encode(hashlib.sha256((secret + challenge).encode()).digest()).decode()


def load_cfg() -> dict:
    data = json.loads(CONFIG.read_text(encoding="utf-8"))
    if not data.get("server_enabled"):
        data["server_enabled"] = True
        CONFIG.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    return data


def connect():
    cfg = load_cfg()
    port = int(cfg.get("server_port") or 4455)
    password = str(cfg.get("server_password") or "")
    ws = create_connection(f"ws://127.0.0.1:{port}", timeout=3)
    hello = json.loads(ws.recv())
    ident = {"op": 1, "d": {"rpcVersion": 1}}
    auth = (hello.get("d") or {}).get("authentication")
    if auth and password:
        ident["d"]["authentication"] = auth_string(password, auth.get("salt") or "", auth.get("challenge") or "")
    ws.send(json.dumps(ident))
    identified = json.loads(ws.recv())
    if identified.get("op") != 2:
        ws.close()
        raise RuntimeError("obs identify failed")
    return ws


def request(ws, kind: str, data: dict | None = None) -> dict:
    body = {"requestType": kind, "requestId": kind}
    if data:
        body["requestData"] = data
    ws.send(json.dumps({"op": 6, "d": body}))
    while True:
        msg = json.loads(ws.recv())
        if msg.get("op") == 7:
            return msg.get("d") or {}


def ok(d: dict) -> bool:
    st = d.get("requestStatus") or {}
    return bool(st.get("result", True))


def recording(ws) -> bool:
    d = request(ws, "GetRecordStatus")
    return bool((d.get("responseData") or {}).get("outputActive"))


def set_dir(ws, dest: Path) -> None:
    dest.mkdir(parents=True, exist_ok=True)
    path = str(dest)
    request(ws, "SetRecordDirectory", {"recordDirectory": path})
    request(
        ws,
        "SetProfileParameter",
        {"parameterCategory": "SimpleOutput", "parameterName": "FilePath", "parameterValue": path},
    )
    request(
        ws,
        "SetProfileParameter",
        {"parameterCategory": "AdvOut", "parameterName": "RecFilePath", "parameterValue": path},
    )


def wait_recording(ws, want: bool, tries: int = 25) -> bool:
    for _ in range(tries):
        if recording(ws) is want:
            return True
        time.sleep(0.15)
    return recording(ws) is want


def main() -> int:
    if len(sys.argv) < 2 or sys.argv[1] not in ("start", "stop"):
        sys.stderr.write("usage: obs-rec.py start|stop [dir]\n")
        return 1
    cmd = sys.argv[1]
    dest = Path(sys.argv[2]) if len(sys.argv) > 2 else Path.home() / "Videos"
    try:
        ws = connect()
    except Exception as e:
        sys.stderr.write(f"obs websocket: {e}\n")
        return 2
    try:
        if cmd == "start":
            set_dir(ws, dest)
            if not recording(ws):
                d = request(ws, "StartRecord")
                if not ok(d):
                    sys.stderr.write(f"obs StartRecord failed {d.get('requestStatus')}\n")
                    return 3
            if not wait_recording(ws, True):
                sys.stderr.write("obs did not start recording\n")
                return 3
            sys.stdout.write(f"{dest}\n")
            return 0
        if not recording(ws):
            sys.stderr.write("obs is not recording\n")
            return 4
        d = request(ws, "StopRecord")
        path = str((d.get("responseData") or {}).get("outputPath") or "")
        wait_recording(ws, False)
        if not path:
            sys.stderr.write("obs StopRecord gave no file\n")
            return 4
        sys.stdout.write(f"{path}\n")
        return 0
    finally:
        ws.close()


if __name__ == "__main__":
    raise SystemExit(main())
