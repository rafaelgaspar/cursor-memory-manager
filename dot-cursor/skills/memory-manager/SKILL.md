---
name: memory-manager
description: >-
  Maintains conversational memory in ~/.cursor/memory.md (global) and
  .cursor/memory.md (project). Use when the user asks to remember something,
  when you learn durable context during work, when correcting or superseding
  prior memory, or when finishing a task where facts would help future chats.
  Also for forget, promote/demote, and compact memory.
disable-model-invocation: false
---

# Memory Manager

A single globally-registered `sessionStart` hook (`inject-memory.sh`) injects the global memory file **and** each workspace root's project memory file at chat start — no per-repo hook or rule setup. This skill owns **edits** to the memory files.

## Paths and layout

| Scope   | Path |
|---------|------|
| Global  | `~/.cursor/memory.md` |
| Project | `.cursor/memory.md` (workspace root) |

Both files share the same layout: a short title/intro, `## Preferences`, `## Decisions`, further `##` sections as needed (e.g. `## Tooling`), and `## Do not store here` last (static reminders only — don't add dated memory bullets there). If `.cursor/memory.md` does not exist yet, create it with this layout when you first write project-scoped facts.

## When to write (proactive)

Update memory whenever information is **likely to help a future conversation**, not only when the user says “remember.”

**Write without being asked** when you learn or confirm:

- A **decision or rationale** (why X was chosen over Y).
- A **repo fact** (where things live, naming patterns, env/account layout, “we always do Z here”).
- A **user correction** to your assumption (treat as durable unless clearly one-off).
- A **preference** shown in how they want work done (commits, PRs, tools, review style).
- **Resolved ambiguity** that took exploration (save the answer, not the debugging steps).
- **Active thread** worth resuming later (multi-step initiative, blocked item, explicit “we’ll continue later”).

**Still skip** (do not store):

- Secrets, tokens, credentials, or private URLs with auth.
- Purely ephemeral state (“fixing line 42 now”, current branch name unless long-lived policy).
- Large paste dumps — distill to one bullet.
- Anything already in memory unchanged — read first, dedupe.
- Guesses or unconfirmed assumptions — store facts, not hypotheses.

**Cadence:** Before you consider a task done, ask: *“Would another chat in this repo (or any repo) get stuck without this?”* If yes, append or update memory. You do not need permission for small, high-confidence bullets; mention briefly in your reply what you saved (one line).

If scope is unclear (global vs project), prefer **project** for repo-specific facts and **global** for personal workflow prefs.

## Scope rules

- **Global:** communication style, git/PR habits, tooling prefs, cross-repo habits.
- **Project:** architecture, env names, module patterns, team conventions, repo-specific decisions and open threads.

## Retention

The `sessionStart` hook only injects the live `memory.md` files — it never
reads `memory-archive-*.md`. So moving a bullet to the archive during
compaction is functionally equivalent to forgetting it (it stops showing up
in every new chat), even though the text still exists on disk.

The hook truncates each injected file at the first **12,000 bytes**
(`MAX_BYTES` in `inject-memory.sh` — a local sanity limit, not a Cursor
platform rule), so an overgrown file silently loses its tail. That's the
main reason to compact: keep the live file well under that cap (~150 lines
is a safe rule of thumb). Raising the cap means editing the hook script and
updating this section to match.

`## Preferences` entries are durable standing rules — **no dates** on those
bullets. **Never compact/archive `## Preferences` by age.** Only dedupe/supersede
them. Age-based compaction into `memory-archive-YYYY.md` applies to bullets
in `## Decisions` and other dated sections: use the trailing `(YYYY-MM-DD)`
at the end of the line to decide age (exactly one date per bullet).

## Entry format

**`## Preferences`** — standing rules only. **No dates** (no trailing `(…)` either).

```markdown
- <one concise bullet>
- **Optional label:** detail when it helps scanning
```

**`## Decisions` and other dated sections** — content first, **one** date in parentheses at the end:

```markdown
- <one concise bullet> (YYYY-MM-DD)
```

- **First write:** end with the **actual** calendar date in parentheses, e.g. `(2026-07-22)` — always `YYYY-MM-DD`, never the literal word `today`.
- **Any update** (wording change, reaffirmation, or correction): replace the bullet in place and set the parentheses to that same **`YYYY-MM-DD` form** for the current day. Never use `(today)`, `(YYYY-MM-DD, …)`, or multiple dates. Don't keep two bullets for the same fact.

Before adding, **read** the target file, **dedupe**, and **remove** contradicted bullets.

If something the user says contradicts stored memory, trust the user, update the bullet, and briefly note the correction in your reply.

## Commands (user phrases)

| Intent | Action |
|--------|--------|
| Remember globally | Edit `~/.cursor/memory.md` |
| Remember for this project | Edit `.cursor/memory.md` |
| Promote to global | Move bullet from project → global; remove from project |
| Demote to project | Move global repo-specific bullet → project; remove from global |
| Forget X | Remove matching bullets from the appropriate file(s) |
| Compact memory | Move bullets older than 90 days to `memory-archive-YYYY.md` in the same directory (**never `## Preferences`** — see Retention above); keep the main file under ~150 lines |
| What do you remember? | Show current memory content for the relevant scope(s); don't paraphrase from injected context if the file may have changed this session — re-read it |

## Workflow

1. Read the target file(s).
2. Apply edits; keep section headings intact.
3. For large or sensitive changes, state the bullet first; for routine proactive saves, a one-line note in the reply is enough.
4. Confirm what was stored and where when the user asked explicitly; otherwise keep confirmation minimal.

## Git

Project memory may be committed for team sharing. Global memory lives outside the repo and is never committed.
