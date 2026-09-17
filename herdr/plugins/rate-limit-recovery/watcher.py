#!/usr/bin/env python3
"""Poll Herdr panes and conservatively resume explicit rate-limit failures."""

from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import time
from typing import Any

POLL_SECONDS = max(2, int(os.environ.get("HERDR_RATE_LIMIT_POLL_SECONDS", "5")))
WAIT_SECONDS = max(60, int(os.environ.get("HERDR_RATE_LIMIT_WAIT_SECONDS", "75")))
WINDOW_SECONDS = max(300, int(os.environ.get("HERDR_RATE_LIMIT_WINDOW_SECONDS", "1800")))
MAX_RETRIES = min(3, max(1, int(os.environ.get("HERDR_RATE_LIMIT_MAX_RETRIES", "2"))))
TAIL_LINES = 16
RATE_LIMIT_RE = re.compile(
    r"^(?:\x1b\[[0-9;]*m)*\x1b\[38;5;1m"
    r"■[ \t]+rate[ -]?limit exceeded:",
    re.IGNORECASE | re.MULTILINE,
)
SHELL_PROMPT_RE = re.compile(r"(?:^|\s)[^\s]{0,80}[$#%]\s*$")


class Watcher:
    def __init__(self) -> None:
        self.herdr = os.environ.get("HERDR_BIN_PATH", "herdr")
        self.state_dir = Path(os.environ["HERDR_PLUGIN_STATE_DIR"])
        self.state_dir.mkdir(parents=True, exist_ok=True)
        self.pending: dict[str, dict[str, Any]] = {}
        self.handled: dict[str, str] = {}
        self.cap_notified: set[str] = set()

    def log(self, message: str) -> None:
        stamp = time.strftime("%Y-%m-%dT%H:%M:%S%z")
        print(f"{stamp} rate-limit-watcher: {message}", flush=True)

    def run(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [self.herdr, *args],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )

    def panes(self) -> list[str]:
        result = self.run("pane", "list")
        if result.returncode != 0:
            self.log(f"pane list failed: {result.stderr.strip()}")
            return []
        try:
            payload = json.loads(result.stdout)
            panes = payload["result"]["panes"]
        except (json.JSONDecodeError, KeyError, TypeError):
            self.log("pane list returned unexpected JSON")
            return []
        return [
            str(pane["pane_id"])
            for pane in panes
            if pane.get("pane_id") and not pane.get("exited", False)
        ]

    def tail(self, pane_id: str) -> str | None:
        result = self.run(
            "pane", "read", pane_id,
            "--source", "recent-unwrapped",
            "--lines", "80",
            "--format", "ansi",
        )
        if result.returncode != 0:
            return None
        lines = [line.rstrip() for line in result.stdout.splitlines() if line.strip()]
        return "\n".join(lines[-TAIL_LINES:])

    @staticmethod
    def signature(text: str) -> str:
        return hashlib.sha256(text.encode("utf-8")).hexdigest()

    @staticmethod
    def eligible(text: str) -> bool:
        if not RATE_LIMIT_RE.search(text):
            return False
        lines = [line.strip() for line in text.splitlines() if line.strip()]
        if not lines:
            return False
        # If the remote runner exited and left an ordinary shell prompt below the
        # error, typing "go on" would execute a shell command instead of resuming.
        if SHELL_PROMPT_RE.search(lines[-1]):
            return False
        return True

    def attempt_file(self, pane_id: str) -> Path:
        safe = re.sub(r"[^A-Za-z0-9_.-]", "_", pane_id)
        return self.state_dir / f"{safe}.attempts.json"

    def recent_attempts(self, pane_id: str) -> list[int]:
        now = int(time.time())
        path = self.attempt_file(pane_id)
        try:
            values = json.loads(path.read_text(encoding="utf-8"))
        except (FileNotFoundError, json.JSONDecodeError, OSError):
            values = []
        return [
            int(value) for value in values
            if now - int(value) < WINDOW_SECONDS
        ]

    def next_attempt(self, pane_id: str) -> int | None:
        attempts = self.recent_attempts(pane_id)
        if len(attempts) >= MAX_RETRIES:
            return None
        return len(attempts) + 1

    def record_attempt(self, pane_id: str) -> bool:
        attempts = self.recent_attempts(pane_id)
        if len(attempts) >= MAX_RETRIES:
            return False
        attempts.append(int(time.time()))
        self.attempt_file(pane_id).write_text(
            json.dumps(attempts) + "\n",
            encoding="utf-8",
        )
        return True

    def notify(self, title: str, body: str, sound: str) -> None:
        result = self.run(
            "notification", "show", title,
            "--body", body,
            "--sound", sound,
        )
        if result.returncode != 0:
            self.log(f"notification failed: {result.stderr.strip()}")

    def scan(self) -> None:
        now = time.monotonic()
        live = set(self.panes())
        for pane_id in list(self.pending):
            if pane_id not in live:
                self.pending.pop(pane_id, None)

        for pane_id in live:
            text = self.tail(pane_id)
            if not text or not self.eligible(text):
                self.pending.pop(pane_id, None)
                self.handled.pop(pane_id, None)
                self.cap_notified.discard(pane_id)
                continue

            signature = self.signature(text)
            if self.handled.get(pane_id) == signature:
                continue

            pending = self.pending.get(pane_id)
            if not pending or pending["signature"] != signature:
                attempt = self.next_attempt(pane_id)
                if attempt is None:
                    self.handled[pane_id] = signature
                    if pane_id not in self.cap_notified:
                        self.cap_notified.add(pane_id)
                        self.log(f"{pane_id}: retry cap reached")
                        self.notify(
                            "Herdr rate limit needs attention",
                            f"{pane_id}: automatic retry limit reached",
                            "request",
                        )
                    continue
                delay = WAIT_SECONDS * (2 ** (attempt - 1))
                self.pending[pane_id] = {
                    "signature": signature,
                    "attempt": attempt,
                    "due": now + delay,
                }
                self.log(
                    f"{pane_id}: explicit rate limit detected; "
                    f"retry {attempt}/{MAX_RETRIES} in {delay}s"
                )
                continue

            if now < float(pending["due"]):
                continue

            # The current tail must still be byte-for-byte identical to the one
            # observed before the cooldown. Any user or agent activity cancels it.
            current = self.tail(pane_id)
            if (
                not current
                or not self.eligible(current)
                or self.signature(current) != pending["signature"]
            ):
                self.log(f"{pane_id}: output changed; cancelling retry")
                self.pending.pop(pane_id, None)
                continue

            if not self.record_attempt(pane_id):
                self.pending.pop(pane_id, None)
                self.handled[pane_id] = signature
                continue

            result = self.run("pane", "run", pane_id, "go on")
            self.pending.pop(pane_id, None)
            self.handled[pane_id] = signature
            if result.returncode != 0:
                self.log(f"{pane_id}: prompt failed: {result.stderr.strip()}")
                self.notify(
                    "Herdr recovery failed",
                    f"{pane_id}: could not send go on",
                    "request",
                )
                continue

            self.log(f"{pane_id}: sent go on after cooldown")
            self.notify(
                "Herdr resumed rate-limited runner",
                f"{pane_id}: sent go on after rate-limit cooldown",
                "done",
            )

    def loop(self) -> None:
        self.log("watcher started")
        while True:
            try:
                self.scan()
            except Exception as error:
                self.log(f"scan error: {error}")
            time.sleep(POLL_SECONDS)


if __name__ == "__main__":
    Watcher().loop()
