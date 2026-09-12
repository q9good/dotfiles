---
name: herdr-cloudcli-bridge
description: "Operate a local Herdr session when the coding agent itself runs through cloudcli-ssh and codex-runner or claude-runner, so local MCP shells do not inherit HERDR_* variables. Use together with the Herdr skill when the user asks to create or control Herdr panes from such a runner session."
---

# Herdr CloudCLI Bridge

This skill supplements Herdr's built-in skill for this verified topology:

    local Herdr pane -> cloudcli-ssh -> codex-runner or claude-runner -> agent

The agent may genuinely originate from a Herdr pane while commands executed by the local MCP server show an empty HERDR_ENV. The MCP shell is a separate local process and may not inherit the runner terminal environment.

## Verify context safely

First print HERDR_ENV, HERDR_SESSION, HERDR_SOCKET_PATH, HERDR_WORKSPACE_ID, HERDR_TAB_ID, and HERDR_PANE_ID through the local MCP shell.

If they are absent, do not use the default socket and do not infer the focused pane. Ask the user to run this inside the originating local Herdr pane:

    env | grep '^HERDR_'

Treat the returned values as explicit session context only when the user confirms this is the pane that launched the runner. Do not hardcode sample IDs or reuse values from an earlier session.

## Bridge local MCP commands to the session

For every local MCP shell call, explicitly export the confirmed HERDR_ENV, HERDR_SESSION, HERDR_SOCKET_PATH, HERDR_WORKSPACE_ID, HERDR_TAB_ID, and HERDR_PANE_ID values before invoking Herdr.

Validate the connection with an explicit, read-only target:

    herdr pane layout --pane "$HERDR_PANE_ID"

Proceed only if the returned workspace, tab, and pane match the confirmed context. Continue using explicit targets; do not rely on another client's focused pane.

## Create a pane and enter a runner project

Inspect the caller's layout and choose a sensible split direction. Preserve the local project directory and user focus:

    herdr pane split --current --direction right --cwd "$PWD" --no-focus

Parse the new pane ID from .result.pane.pane_id. Drive interactive commands one step at a time:

    herdr pane run '<new-pane-id>' 'cloudcli-ssh'
    herdr pane read '<new-pane-id>' --source recent-unwrapped --lines 120

After the remote prompt is visibly ready:

    herdr pane run '<new-pane-id>' 'claude-runner --model <model>'
    # Or use codex-runner with the arguments requested by the user.
    herdr pane read '<new-pane-id>' --source recent-unwrapped --lines 120

Only send a menu choice after reading and verifying the current prompt:

    herdr pane run '<new-pane-id>' '<choice>'
    herdr pane read '<new-pane-id>' --source recent-unwrapped --lines 160

A project choice may lead to a second prompt for an existing or new agent session. Stop there unless the user already specified that second choice. Report the pane ID and the exact prompt awaiting input.

## Safety

- Use only local MCP tools for file and shell operations in this project.
- Never use the default Herdr socket when the confirmed session has a session-specific HERDR_SOCKET_PATH.
- Never infer a pane from UI focus or sidebar order.
- Never blindly send multiple menu choices; read after every transition.
- Use --no-focus for background pane creation.
- Do not close panes, tabs, workspaces, sessions, or stop the server unless explicitly requested.
