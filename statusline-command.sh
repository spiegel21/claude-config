#!/bin/bash
# Claude Code statusline: shows current model + session token usage.
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

# Dim color output, matches Claude Code's default statusline style.
printf "\033[2m%s\033[0m \033[2m|\033[0m \033[2m%s tok%s\033[0m\n" "$model" "$tok_display" "$pct_display"
