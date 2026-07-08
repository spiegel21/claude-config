# Claude Code personal config

Personal Claude Code configuration, portable across machines.

## Contents

| Path | Restores to | What it is |
|---|---|---|
| `CLAUDE.md` | `~/.claude/CLAUDE.md` | Global instructions (automation proposals, delegation policy) |
| `settings.json` | `~/.claude/settings.json` | Model, notification hooks, voice, theme |
| `settings.local.json` | `~/.claude/settings.local.json` | Sandbox + permission allowlist |
| `agents/` | `~/.claude/agents/` | Custom subagents (scout, executor, verifier, code-reviewer, debugger, pr-author) |
| `skills/` | `~/.claude/skills/` | Custom skills (handoff-prompt, propose-automations) |
| `commands/` | `~/.claude/commands/` | Slash commands (ask-output, disk-check, gh-check) |
| `hooks/` | `~/.claude/hooks/` | Shell hooks (post-edit-sync.sh) |
| `memory/` | `~/.claude/projects/<project-key>/memory/` | Auto-memory (see note below) |

## Keeping this repo in sync

This repo is the source of truth. `install.sh` copies repo → `~/.claude` (new machine
setup). `sync.sh` does the reverse: `~/.claude` → repo, then commits and pushes if
anything changed. A `PostToolUse` hook (`hooks/post-edit-sync.sh`, wired in
`settings.json`) runs `sync.sh` automatically after any Edit/Write to a tracked config
path, so day-to-day changes push themselves. Run `./sync.sh` manually if you ever need to
force a sync.

## Restore on a new machine

```sh
git clone git@github.com:spiegel21/claude-config.git
cd claude-config
./install.sh
```

Or manually:

```sh
mkdir -p ~/.claude
cp CLAUDE.md settings.json settings.local.json ~/.claude/
cp -R agents skills commands ~/.claude/
```

### Memory note

Memory is keyed by project directory path. The files in `memory/` came from
`~/.claude/projects/-Users-eduardospiegel/memory/` (sessions started in `$HOME`).
On the new machine, copy them to the equivalent path for that machine's home
directory, e.g. `~/.claude/projects/-Users-<username>/memory/`.

### Notes

- `settings.json` hooks use macOS `osascript` notifications and `jq` — macOS-only; install `jq` (`brew install jq`).
- No secrets are stored here. Authenticate `gh` and any MCP servers separately on the new machine.
