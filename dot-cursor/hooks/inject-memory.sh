#!/usr/bin/env bash
set -euo pipefail

input="$(cat)"
MAX_BYTES=12000

read_file_capped() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  head -c "$MAX_BYTES" "$f"
}

sections=()

sections+=("## Conversational memory (session hook)")
sections+=("Persistent memory lives in ~/.cursor/memory.md (global) and .cursor/memory.md (per workspace root).")
sections+=("To create, update, dedupe, or compact memory, follow the **memory-manager** skill. After any reply that established a durable fact, write it the same turn into the matching ## section of these files—not only when the user says \"remember.\" Italic _Store:_ lines are scaffolding; replace them with a real bullet. Never store secrets.")
sections+=("")

global="${HOME}/.cursor/memory.md"
if [[ -f "$global" ]]; then
  sections+=("## Global memory (~/.cursor/memory.md)")
  sections+=("$(read_file_capped "$global")")
fi

while IFS= read -r root; do
  [[ -n "$root" ]] || continue
  proj="${root}/.cursor/memory.md"
  if [[ -f "$proj" ]]; then
    sections+=("## Project memory (${proj})")
    sections+=("$(read_file_capped "$proj")")
  fi
done < <(jq -r '.workspace_roots[]? // empty' <<<"$input")

body=""
for line in "${sections[@]}"; do
  body+="${line}"$'\n\n'
done

jq -n --arg ctx "$body" '{ "additional_context": $ctx }'
