# Herdr rate-limit recovery

A conservative Herdr startup plugin for agents nested behind `cloudcli-ssh` and `codex-runner` or `claude-runner`.

Herdr cannot classify those nested processes as native agents, so this plugin starts a singleton watcher that uses `herdr pane list`, `pane read`, and `pane run` directly. It therefore does not depend on `pane.agent_status_changed`.

Defaults:

- Poll every 5 seconds.
- Match only Codex error lines beginning `■ rate limit exceeded:`. Generic 429 text and quoted inline discussions do not trigger recovery.
- Recognize `■ rate limit exceeded: Your requests to ...`, including wrapped continuation lines.
- Wait 75 seconds before the first retry and 150 seconds before the second.
- Re-read the pane and require the complete terminal tail to be unchanged before sending.
- Cancel if a normal shell prompt appears below the error.
- Count only an actual `go on` send as a retry; cancelled cooldowns do not consume the budget.
- At most 2 actual retries per pane in a rolling 30-minute window.
- Continue watching after a retry. A new rate-limit error below the previous one is treated as the next attempt.
- Never auto-confirm approvals or react to unrelated failures.

Optional Herdr server environment overrides:

- `HERDR_RATE_LIMIT_POLL_SECONDS` (minimum 2)
- `HERDR_RATE_LIMIT_WAIT_SECONDS` (minimum 60)
- `HERDR_RATE_LIMIT_WINDOW_SECONDS` (minimum 300)
- `HERDR_RATE_LIMIT_MAX_RETRIES` (1 to 3)
