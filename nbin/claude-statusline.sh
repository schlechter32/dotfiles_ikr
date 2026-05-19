#!/usr/bin/env bash
# claude-statusline — Claude Code statusLine command.
#
# Primary job here: write ~/.claude/rate-cache.json from the rate-limit data
# Claude Code passes on stdin. Those numbers are derived from API *response
# headers* (anthropic-ratelimit-unified-*), so they are exact and cost no extra
# request — but they only refresh while a Claude Code session is active. The
# WezTerm statusbar reads this cache (and the hourly poller's) and shows the
# freshest. It also prints a compact status line for the in-terminal display.

payload=$(cat)
CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

reset='\033[0m'; bold='\033[1m'; dim='\033[2m'
red='\033[31m'; green='\033[32m'; yellow='\033[33m'; magenta='\033[35m'; cyan='\033[36m'
sep="${dim} │ ${reset}"

model=$(echo "$payload" | jq -r '.model.display_name // .model.id // .model // "Claude"')

ctx_pct=$(echo "$payload" | jq -r '.context_window.used_percentage // 0')
ctx_int=$(printf "%.0f" "$ctx_pct")

cwd=$(echo "$payload" | jq -r '.workspace.current_dir // .cwd // ""')
[[ -z "$cwd" ]] && cwd="$PWD"
part_git=""
if git -C "$cwd" rev-parse --is-inside-work-tree &>/dev/null; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
        || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  part_git="${green} ${branch}${reset}"
fi

rate_color() {
  local p; p=$(printf "%.0f" "$1")
  if   (( p >= 80 )); then printf "%s" "$red"
  elif (( p >= 50 )); then printf "%s" "$yellow"
  else                     printf "%s" "$green"; fi
}
r5=$(echo "$payload" | jq -r '.rate_limits.five_hour.used_percentage // 0')
r7=$(echo "$payload" | jq -r '.rate_limits.seven_day.used_percentage // 0')
r5_resets=$(echo "$payload" | jq -r '.rate_limits.five_hour.resets_at // ""')
r7_resets=$(echo "$payload" | jq -r '.rate_limits.seven_day.resets_at // ""')

# ── Write rate-cache.json (consumed by the WezTerm statusbar) ───────────────
jq -n \
  --argjson r5    "$(printf "%.0f" "$r5")" \
  --argjson r7    "$(printf "%.0f" "$r7")" \
  --arg     r5at  "$r5_resets" \
  --arg     r7at  "$r7_resets" \
  --argjson ctx   "$ctx_int" \
  --arg     model "$model" \
  --arg     cwd   "$cwd" \
  --argjson ts    "$(date +%s)" \
  '{r5:$r5,r7:$r7,r5_resets_at:$r5at,r7_resets_at:$r7at,context_pct:$ctx,model:$model,cwd:$cwd,ts:$ts}' \
  > "$CONFIG_DIR/rate-cache.json" 2>/dev/null || true

# ── Compact in-terminal line ────────────────────────────────────────────────
part_r5="$(rate_color "$r5")5h $(printf "%.0f" "$r5")%${reset}"
part_r7="$(rate_color "$r7")7d $(printf "%.0f" "$r7")%${reset}"
line="${magenta}${model}${reset}${sep}${ctx_int}% ctx"
[[ -n "$part_git" ]] && line+="${sep}${part_git}"
line+="${sep}${part_r5}${sep}${part_r7}${sep}${bold}${cyan}$(basename "$cwd")${reset}"
printf "%b\n" "$line"
