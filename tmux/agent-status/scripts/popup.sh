#!/usr/bin/env bash
# popup.sh — notification popup for agent-status
#
# Modes:
#   --render   runs inside tmux popup (renderer)
#   (default)  dispatcher called from hook.sh / notify-shell.sh
#
# Args (dispatcher mode):
#   --state=done|permission|shell
#   --label=<text>
#   --pane=<tmux pane id>   source pane (for window-active check)

SCRIPT="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

# ── Renderer (inside popup) ───────────────────────────────────────────────────
if [[ "${1:-}" == "--render" ]]; then
    state="${NOTIFY_STATE:-done}"
    win="${NOTIFY_WIN:-}"
    win_idx="${NOTIFY_WIN_IDX:-0}"
    label="${NOTIFY_LABEL:-DONE}"
    session="${NOTIFY_SESSION:-}"
    caller_session="${NOTIFY_CALLER_SESSION:-}"
    caller_win_idx="${NOTIFY_CALLER_WIN_IDX:-}"

    # Catppuccin Mocha palette
    bd=$'\033[38;2;180;190;254m'  # lavender  (border/frame)
    gn=$'\033[38;2;166;227;161m'  # green     (done)
    rd=$'\033[38;2;243;139;168m'  # red/pink  (permission)
    bl=$'\033[38;2;137;180;250m'  # blue      (shell)
    tx=$'\033[38;2;205;214;244m'  # text
    dm=$'\033[38;2;88;91;112m'    # overlay   (dim)
    r=$'\033[0m'

    case "$state" in
        done)       face="${gn}▲ ▲${r}" ;;
        permission) face="${rd}▓ ▓${r}" ;;
        shell)      face="${bl}⏱  ⏱${r}" ;;
        *)          face="${dm}▒ ▒${r}" ;;
    esac

    printf "\n"
    printf "  ${dm}░${bd}▄▄▄▄▄${dm}░${r}\n"
    printf "  ${bd}█${r} %s ${bd}█${r}  ${dm}[%s]${r}\n"    "$face" "$win"
    printf "  ${bd}█${r} ${bd}▄▄▄${r} ${bd}█${r}  ${tx}%s${r}\n" "$label"
    printf "  ${bd}▀▀▀▀▀▀▀${dm}░${r}\n"
    printf "\n  ${dm}↵ jump  q quit${r}\n"

    tput civis 2>/dev/null

    [[ "$state" == "permission" ]] && timeout=10 || timeout=5
    deadline=$(( SECONDS + timeout ))

    while (( SECONDS < deadline )); do
        remaining=$(( deadline - SECONDS ))
        (( remaining < 1 )) && remaining=1
        read -t "$remaining" -rsn1 k || exit 0
        case "$k" in
            "")  if [[ -n "$caller_session" && -n "$caller_win_idx" ]]; then
                     mkdir -p "$HOME/.cache/agent-status" 2>/dev/null
                     printf '%s\n' "${caller_session}:${caller_win_idx}" \
                         >> "$HOME/.cache/agent-status/location_stack"
                     # Cap stack at 50 entries
                     tail -n 50 "$HOME/.cache/agent-status/location_stack" \
                         > "$HOME/.cache/agent-status/location_stack.tmp" \
                         && mv "$HOME/.cache/agent-status/location_stack.tmp" \
                               "$HOME/.cache/agent-status/location_stack"
                 fi
                 [ -n "$session" ] && timeout 2 tmux switch-client -t "$session" 2>/dev/null
                 timeout 2 tmux select-window -t "${session:+$session:}$win_idx" 2>/dev/null; exit 0 ;;
            q)   exit 0 ;;
        esac
    done
    exit 0
fi

# ── Dispatcher ────────────────────────────────────────────────────────────────
state="done"
label=""
src_pane="${TMUX_PANE:-}"

for arg in "$@"; do
    case "$arg" in
        --state=*)   state="${arg#--state=}" ;;
        --label=*)   label="${arg#--label=}" ;;
        --pane=*)    src_pane="${arg#--pane=}" ;;
        --session=*) src_session="${arg#--session=}" ;;
    esac
done

[[ -z "$label" ]] && case "$state" in
    done)       label="DONE" ;;
    permission) label="APPROVE?" ;;
    shell)      label="done" ;;
esac

[ -z "${TMUX:-}" ] && exit 0

# Skip "done" popup (Claude finished) when already viewing that window.
# Shell and permission popups always show.
if [[ "$state" == "done" && -n "$src_pane" ]]; then
    win_active=$(timeout 2 tmux display-message -t "$src_pane" -p '#{window_active}' 2>/dev/null)
    [[ "$win_active" == "1" ]] && exit 0
fi

win=$(timeout 2 tmux display-message ${src_pane:+-t "$src_pane"} -p '#I:#W' 2>/dev/null)
win_idx="${win%%:*}"

# Capture the caller's current location so the renderer can push it onto the
# location stack before jumping (enables prefix+Enter to jump back).
caller_session=$(timeout 2 tmux display-message -p '#{session_name}' 2>/dev/null)
caller_win_idx=$(timeout 2 tmux display-message -p '#{window_index}' 2>/dev/null)

[[ "$state" == "permission" ]] && pw=34 || pw=30

tmux display-popup \
    ${src_pane:+-t "$src_pane"} \
    -x R -y T \
    -w "$pw" -h 8 \
    -b rounded \
    -s "fg=#9E8C5D,bg=#1E1E2E" \
    -S "fg=#9E8C5D" \
    -e "NOTIFY_STATE=$state" \
    -e "NOTIFY_WIN=$win" \
    -e "NOTIFY_WIN_IDX=$win_idx" \
    -e "NOTIFY_SESSION=$src_session" \
    -e "NOTIFY_LABEL=$label" \
    -e "NOTIFY_CALLER_SESSION=$caller_session" \
    -e "NOTIFY_CALLER_WIN_IDX=$caller_win_idx" \
    -E "bash '$SCRIPT' --render"
