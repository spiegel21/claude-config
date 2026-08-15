#!/usr/bin/env bash
# Claude Code notification dispatcher.
#
# Replaces the previous inline osascript/curl hooks, which had three failure modes:
#   1. Anonymous pings   -> every notification now names the session (dir@branch · id).
#   2. False "finished"  -> Stop fires per RESPONSE, not per TASK. If work is still
#                           in flight we report "yielded (N running)", silently,
#                           instead of claiming completion.
#   3. Over-broad match  -> the Notification hook matched every notification type,
#                           including idle_prompt (which needs nothing from you).
#                           NOTIFY_AUDIT below captures real payloads so the noisy
#                           types can be filtered from data rather than guesswork.
#
# Wired to the Notification and Stop hook events. Reads the hook JSON on stdin.

set -uo pipefail

NTFY_TOPIC="claude-cc-493c921659"
AUDIT_LOG="$HOME/.claude/notify-audit.log"
AUDIT_MAX_BYTES=2000000   # ~2MB cap; oldest half is dropped when exceeded

payload="$(cat)"

field() { jq -r --arg k "$1" '.[$k] // empty' <<<"$payload" 2>/dev/null; }

event="$(field hook_event_name)"
session="$(field session_id)"
cwd="$(field cwd)"
message="$(field message)"
last_msg="$(field last_assistant_message)"

# ---------------------------------------------------------------- identity ---
# An anonymous "Task finished" is unactionable when many sessions run at once.
short="${session:0:8}"
dir="$(basename "${cwd:-$PWD}")"
branch="$(git -C "${cwd:-$PWD}" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
who="$dir${branch:+@$branch} · $short"

notif_type="$(field notification_type)"

# Number of background tasks (shells + subagents) still running. This field is
# supplied first-party on Stop and is authoritative; the heuristics below are
# only a fallback for payloads that lack it.
bg_running="$(jq -r '[(.background_tasks // [])[] | select(.status=="running")] | length' <<<"$payload" 2>/dev/null)"
bg_present="$(jq -r 'if has("background_tasks") then "yes" else "no" end' <<<"$payload" 2>/dev/null)"

# ------------------------------------------------------------- in-flight? ---
# Walk up from this hook to the owning `claude` process, then count its live
# child shells. A non-zero count means work is still running in that terminal.
live_shells() {
  local p=$$ ppid comm claude_pid=""
  for _ in 1 2 3 4 5 6 7 8; do
    read -r ppid comm <<<"$(ps -o ppid=,comm= -p "$p" 2>/dev/null)"
    [ -z "${ppid:-}" ] && break
    case "$comm" in *claude*) claude_pid="$p"; break;; esac
    p="$ppid"
  done
  [ -z "$claude_pid" ] && { echo 0; return; }
  pgrep -P "$claude_pid" 2>/dev/null | wc -l | tr -d ' '
}

# The job runner keeps an authoritative counter; prefer it when present.
inflight_from_state() {
  local f="$HOME/.claude/jobs/$short/state.json"
  [ -f "$f" ] && jq -r '(.inFlight.tasks // 0) + (.inFlight.queued // 0)' "$f" 2>/dev/null || echo ""
}

busy="$(inflight_from_state)"; src="state.json"
if [ -z "$busy" ]; then busy="$(live_shells)"; src="child-shells"; fi
[ -z "$busy" ] && { busy=0; src="none"; }

# --------------------------------------------------------------- dispatch ---
title=""; body=""; sound=""; push=1; verdict=""

case "$event" in
  Stop)
    if [ "$busy" -gt 0 ]; then
      # Claude ended a RESPONSE, but the terminal still has work running.
      # Do not claim completion — that is the bug this hook exists to fix.
      title="⏳ $who"
      body="Turn ended — $busy still running"
      sound=""          # silent: nothing for you to do yet
      push=0            # no phone push for a non-event
      verdict="stop-suppressed"
    else
      title="✅ $who"
      body="$(printf '%s' "${last_msg:-Task finished}" | tr '\n' ' ' | cut -c1-140)"
      sound="Submarine"
      verdict="stop-complete"
    fi
    ;;
  Notification)
    title="🔔 $who"
    body="${message:-Claude needs you}"
    sound="Glass"
    verdict="notify"
    ;;
  *)
    title="· $who"; body="${message:-$event}"; sound=""; verdict="passthrough"
    ;;
esac

# ------------------------------------------------------------------ audit ---
# Records the RAW payload plus the decision taken, so the notification types
# that fire without needing you can be identified and filtered from evidence.
{
  if [ -f "$AUDIT_LOG" ]; then
    sz=$(wc -c <"$AUDIT_LOG" 2>/dev/null | tr -d ' ')
    if [ "${sz:-0}" -gt "$AUDIT_MAX_BYTES" ]; then
      tail -n 2000 "$AUDIT_LOG" >"$AUDIT_LOG.tmp" 2>/dev/null && mv "$AUDIT_LOG.tmp" "$AUDIT_LOG"
    fi
  fi
  jq -c --arg ts "$(date -u +%FT%TZ)" \
        --arg verdict "$verdict" --arg busy "$busy" --arg src "$src" \
        '{ts:$ts, verdict:$verdict, busy:$busy, busy_src:$src, payload:.}' \
     <<<"$payload" >>"$AUDIT_LOG"
} 2>/dev/null || true

[ -z "$body" ] && exit 0

# --------------------------------------------------------------- delivery ---
esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
if [ -n "$sound" ]; then
  osascript -e "display notification \"$(esc "$body")\" with title \"$(esc "$title")\" sound name \"$sound\"" >/dev/null 2>&1 || true
else
  osascript -e "display notification \"$(esc "$body")\" with title \"$(esc "$title")\"" >/dev/null 2>&1 || true
fi

if [ "$push" -eq 1 ]; then
  curl -s -H "Title: $title" -d "$body" "https://ntfy.sh/$NTFY_TOPIC" >/dev/null 2>&1 || true
fi

exit 0
