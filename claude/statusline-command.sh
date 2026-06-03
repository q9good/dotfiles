#!/usr/bin/env bash
# Claude Code status line: Model | Context | Usage | Effort | Pwd
set -euo pipefail

input=$(cat)

# Colors (ANSI)
C_MODEL='\033[1;35m'    # bold magenta
C_CTX='\033[1;36m'      # bold cyan
C_USAGE='\033[1;33m'    # bold yellow
C_EFFORT='\033[1;32m'   # bold green
C_PWD='\033[1;34m'      # bold blue
C_SEP='\033[0;90m'      # dim gray
C_RESET='\033[0m'

SEP="${C_SEP} │ ${C_RESET}"

format_tokens() {
  local n=$1
  if [ "$n" -ge 1000000 ]; then
    printf '%.1fM' "$(echo "$n / 1000000" | bc -l)"
  elif [ "$n" -ge 1000 ]; then
    printf '%.1fk' "$(echo "$n / 1000" | bc -l)"
  else
    printf '%d' "$n"
  fi
}

# Model
model=$(echo "$input" | jq -r '.model.display_name // "unknown"')

# Context: percentage + used/total
ctx_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // 0')
ctx_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
ctx_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
ctx_used=$((ctx_in + ctx_out))

ctx="Ctx:$(printf '%.0f' "$ctx_pct")% $(format_tokens "$ctx_used")/$(format_tokens "$ctx_size")"

# Token usage (current turn)
cur_in=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
cur_cache_create=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
cur_cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
cur_out=$(echo "$input" | jq -r '.context_window.current_usage.output_tokens // 0')
total_in=$((cur_in + cur_cache_create + cur_cache_read))
usage="In:$(format_tokens "$total_in") Out:$(format_tokens "$cur_out")"

# Cost
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
cost_str=$(printf '$%.1f' "$cost")

# Effort
effort=$(echo "$input" | jq -r '.effort.level // empty')

# Pwd
cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty')
if [ -n "$cwd" ]; then
  pwd_str=$(echo "$cwd" | sed "s|^$HOME|~|")
else
  pwd_str=""
fi

# Build output
out="${C_MODEL}${model}${C_RESET}"
out+="${SEP}${C_CTX}${ctx}${C_RESET}"
out+="${SEP}${C_USAGE}${usage} ${cost_str}${C_RESET}"
[ -n "$effort" ] && out+="${SEP}${C_EFFORT}${effort}${C_RESET}"
[ -n "$pwd_str" ] && out+="${SEP}${C_PWD}${pwd_str}${C_RESET}"

printf '%b' "$out"
