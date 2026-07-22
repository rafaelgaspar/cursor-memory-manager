#!/usr/bin/env bash
# Installs the memory-manager skill + sessionStart hook + starter memory.md.
# Usage: ./install.sh
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required (merge hooks.json during install; inject-memory.sh needs it at session start)." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURSOR_DIR="$HOME/.cursor"
mkdir -p "$CURSOR_DIR/hooks" "$CURSOR_DIR/skills/memory-manager"

skill_target="$CURSOR_DIR/skills/memory-manager/SKILL.md"
if [ -f "$skill_target" ]; then
  cp "$skill_target" "$skill_target.bak.$(date +%s)"
  echo "Backed up existing memory-manager skill -> SKILL.md.bak.<timestamp>"
fi
cp "$SCRIPT_DIR/dot-cursor/skills/memory-manager/SKILL.md" "$skill_target"
echo "Installed memory-manager skill"

hook_target="$CURSOR_DIR/hooks/inject-memory.sh"
if [ -f "$hook_target" ]; then
  cp "$hook_target" "$hook_target.bak.$(date +%s)"
  echo "Backed up existing inject-memory.sh -> inject-memory.sh.bak.<timestamp>"
fi
cp "$SCRIPT_DIR/dot-cursor/hooks/inject-memory.sh" "$hook_target"
chmod +x "$hook_target"
echo "Installed inject-memory.sh hook script"

memory_target="$CURSOR_DIR/memory.md"
if [ -f "$memory_target" ]; then
  echo "Existing memory.md found at $memory_target -> left untouched (not overwriting your memory)."
else
  cp "$SCRIPT_DIR/dot-cursor/memory.md" "$memory_target"
  echo "Installed starter memory.md"
fi

hooks_json_target="$CURSOR_DIR/hooks.json"
if [ ! -f "$hooks_json_target" ]; then
  cp "$SCRIPT_DIR/dot-cursor/hooks.json" "$hooks_json_target"
  echo "Installed hooks.json"
elif jq -e '.hooks.sessionStart[]? | select(.command == "./hooks/inject-memory.sh")' "$hooks_json_target" >/dev/null 2>&1; then
  echo "hooks.json already references inject-memory.sh - left untouched."
else
  cp "$hooks_json_target" "$hooks_json_target.bak.$(date +%s)"
  jq '.hooks.sessionStart = ((.hooks.sessionStart // []) + [{"command": "./hooks/inject-memory.sh"}])' "$hooks_json_target" > "$hooks_json_target.tmp" \
    && mv "$hooks_json_target.tmp" "$hooks_json_target"
  echo "Merged sessionStart hook into existing hooks.json (backup saved)"
fi

echo "Done. Restart Cursor to pick up the memory-manager skill and hook."
