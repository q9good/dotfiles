#!/usr/bin/env python3
"""Start the rate-limit watcher as a detached singleton."""

from __future__ import annotations

import json
import os
from pathlib import Path
import subprocess
import sys


def process_is_watcher(pid: int, watcher_path: Path) -> bool:
    try:
        os.kill(pid, 0)
    except OSError:
        return False
    proc_cmdline = Path(f"/proc/{pid}/cmdline")
    if not proc_cmdline.exists():
        return True
    try:
        command = proc_cmdline.read_bytes().replace(b"\0", b" ")
    except OSError:
        return False
    return str(watcher_path).encode() in command


def main() -> int:
    root = Path(os.environ.get("HERDR_PLUGIN_ROOT", Path(__file__).parent))
    state_dir = Path(
        os.environ.get(
            "HERDR_PLUGIN_STATE_DIR",
            Path.home() / ".cache" / "herdr-rate-limit-recovery",
        )
    )
    state_dir.mkdir(parents=True, exist_ok=True)
    pid_path = state_dir / "watcher.pid"

    watcher_path = root / "watcher.py"
    try:
        pid = int(pid_path.read_text(encoding="utf-8").strip())
    except (FileNotFoundError, ValueError, OSError):
        pid = 0
    if pid > 0 and process_is_watcher(pid, watcher_path):
        return 0

    # A manual start may have used the fallback state directory. Avoid a second
    # daemon when Herdr later invokes this startup hook with its managed path.
    found = subprocess.run(
        ["pgrep", "-f", str(watcher_path)],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    for value in found.stdout.split():
        candidate = int(value)
        if candidate != os.getpid() and process_is_watcher(candidate, watcher_path):
            pid_path.write_text(f"{candidate}\n", encoding="utf-8")
            return 0

    log = (state_dir / "watcher.log").open("a", encoding="utf-8")
    env = os.environ.copy()
    env["HERDR_PLUGIN_STATE_DIR"] = str(state_dir)
    process = subprocess.Popen(
        [sys.executable, str(root / "watcher.py")],
        stdin=subprocess.DEVNULL,
        stdout=log,
        stderr=log,
        env=env,
        start_new_session=True,
        close_fds=True,
    )
    pid_path.write_text(f"{process.pid}\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
