#!/bin/bash
# Claude Code statusline: shows current model, session token usage,
# session (5-hour) and weekly (7-day) rate limit usage.
# Reads the JSON payload Claude Code pipes to statusLine commands on stdin.

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "Claude"')

in_tok=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
out_tok=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

total_tok=$((in_tok + out_tok))

# Format token count as e.g. 850, 12.3k, 1.2M
fmt_tokens() {
  awk -v n="$1" 'BEGIN {
    if (n >= 1000000) printf "%.1fM", n/1000000;
    else if (n >= 1000) printf "%.1fk", n/1000;
    else printf "%d", n;
  }'
}
tok_display=$(fmt_tokens "$total_tok")

pct_display=""
if [ -n "$used_pct" ] && [ "$used_pct" != "null" ]; then
  pct_display=$(printf " (%.0f%% ctx)" "$used_pct")
fi

session_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
session_resets_at=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')

# Format seconds remaining as e.g. 45m, 3h12m
fmt_remaining() {
  local secs="$1"
  if [ "$secs" -lt 0 ]; then secs=0; fi
  local h=$((secs / 3600))
  local m=$(((secs % 3600) / 60))
  if [ "$h" -gt 0 ]; then
    printf "%dh%02dm" "$h" "$m"
  else
    printf "%dm" "$m"
  fi
}

session_display=""
if [ -n "$session_pct" ] && [ "$session_pct" != "null" ]; then
  session_display=$(printf " | session %.0f%%" "$session_pct")
  if [ -n "$session_resets_at" ] && [ "$session_resets_at" != "null" ]; then
    now=$(date +%s)
    remaining=$((session_resets_at - now))
    remaining_display=$(fmt_remaining "$remaining")
    session_display="${session_display} (${remaining_display} left)"
  fi
fi

week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_display=""
if [ -n "$week_pct" ] && [ "$week_pct" != "null" ]; then
  week_display=$(printf " | wk %.0f%%" "$week_pct")
fi

# Dim color output, matches Claude Code's default statusline style.
printf "\033[2m%s\033[0m \033[2m|\033[0m \033[2m%s tok%s%s%s\033[0m\n" \
  "$model" "$tok_display" "$pct_display" "$session_display" "$week_display"
