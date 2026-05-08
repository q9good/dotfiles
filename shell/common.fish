# Shared shell config for fish
# Sourced by ~/.config/fish/config.fish via install.sh

# Bell notification when a long-running command finishes (>=10s)
set -g _notify_cmd_start 0
set -g _NOTIFY_THRESHOLD 10

function _notify_preexec --on-event fish_preexec
    set -g _notify_cmd_start (date +%s)
end

function _notify_postexec --on-event fish_postexec
    if test $_notify_cmd_start -gt 0
        set elapsed (math (date +%s) - $_notify_cmd_start)
        if test $elapsed -ge $_NOTIFY_THRESHOLD
            printf '\a'
        end
        set -g _notify_cmd_start 0
    end
end
