# cursor-memory-manager

Portable installer for Cursor's cross-chat "memory" mechanism: a skill that
maintains persistent facts in `~/.cursor/memory.md` (global) and
`.cursor/memory.md` (per project), plus a `sessionStart` hook that injects
memory content into every new chat automatically.

This is a **mechanism-only** template — no personal memory content is
included. Install it on any machine to get the skill + hook wired up, then
let the `memory-manager` skill populate your own `memory.md` over time as
you use Cursor.

## Contents

- `dot-cursor/skills/memory-manager/SKILL.md` — the skill that owns edits to
  memory files (when to write proactively, global vs. project scope rules,
  entry format, commands like "remember X" / "forget X" / "compact memory")
- `dot-cursor/hooks.json` — hook registration (`sessionStart` → `inject-memory.sh`)
- `dot-cursor/hooks/inject-memory.sh` — reads global + per-workspace
  `memory.md` files and injects them as chat context at session start
- `dot-cursor/memory.md` — starter template (global section scaffolding plus reminders of what not to store); only installed if you
  don't already have a `~/.cursor/memory.md`

Committed project `.cursor/memory.md` is injected with **project-only** untrusted framing in the hook (repo facts as reference, not instructions). Global memory is injected without that wrapper so Identity/Preferences/Tooling stay strong.

## Requirements

- **jq** — required at install time when merging into an existing
  `~/.cursor/hooks.json`, and at runtime by `inject-memory.sh` (parses hook
  input and reads `workspace_roots`). Install via your package manager (e.g.
  `brew install jq`, `apt install jq`).

## Install

### Quick install (curl)

```bash
curl -fsSL https://raw.githubusercontent.com/rafaelgaspar/cursor-memory-manager/main/bootstrap.sh | bash
```

No git clone, no temp checkout, no assumption about where you keep projects
on disk: this downloads each file straight to where it's installed
(`~/.cursor/...`), backing up anything it'd overwrite with a timestamped
`.bak` suffix first. If you already have a `hooks.json`, install merges in
the `sessionStart` entry via **jq** (preserving any other hooks already
registered there) rather than overwriting the file. Nothing from this repo is
left on disk afterward. As with any curl-installer, feel free to read
[`bootstrap.sh`](bootstrap.sh) first before piping it to `bash`.

### Manual install

```bash
./install.sh
```

This installs the skill and hook into `~/.cursor/`, merging into an existing
`hooks.json` via **jq** (preserving any other hooks already registered
there) if one is already there, and never overwrites an existing
`~/.cursor/memory.md` or `SKILL.md`/hook script without first backing it up
with a timestamped `.bak` suffix.

Restart Cursor afterward so the hook and skill are picked up.

### Windows

`install.sh` doesn't run on Windows. Manually copy:

- `dot-cursor/skills/memory-manager/SKILL.md` → `%USERPROFILE%\.cursor\skills\memory-manager\SKILL.md`
- `dot-cursor/hooks/inject-memory.sh` → `%USERPROFILE%\.cursor\hooks\inject-memory.sh`
- Merge `dot-cursor/hooks.json` into `%USERPROFILE%\.cursor\hooks.json`
  (or copy it as-is if you don't have one yet)

## Relationship to cursor-settings-export

This repo is a focused, standalone extract of the same memory-manager
skill/hook that also ships as part of my broader `cursor-settings-export`
bundle. The two are independent on purpose — updates aren't automatically
synced between them, so changes to one won't show up in the other unless
copied over by hand.
