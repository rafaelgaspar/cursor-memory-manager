---
name: memory-manager
description: >-
  Maintains conversational memory in ~/.cursor/memory.md (global) and
  .cursor/memory.md (project). Use when the user asks to remember something,
  when you learn a name, role, timezone, preference, or workflow habit,
  when a user corrects you, when you resolve how a system/tool/env works,
  when choosing X over Y, when finishing a task where facts would help
  future chats, or when correcting or superseding prior memory. Also for
  forget, promote/demote, and compact memory.
disable-model-invocation: false
---

# Memory Manager

A single globally-registered `sessionStart` hook (`inject-memory.sh`) injects the global memory file **and** each workspace root's project memory file at chat start — no per-repo hook or rule setup. This skill owns **edits** to the memory files.

## Paths and layout

| Scope   | Path |
|---------|------|
| Global  | `~/.cursor/memory.md` |
| Project | `.cursor/memory.md` (workspace root) |

Keep a short title/intro, then the sections below **in this order**. Create a heading the first time you have a fact for it. Keep `## Do not store here` last (static reminders only — don't add memory bullets there).

Italic `_Store: …_` lines in empty template sections are scaffolding — delete the italic line when you add the first real bullet to that section.

If `.cursor/memory.md` does not exist yet, create it with the **project** layout when you first write project-scoped facts.

### Global layout (`~/.cursor/memory.md`)

```markdown
# Global memory

Durable facts about me across all projects. Not repo-specific.

## Identity
_Store: name, role, how to address them, timezone, units. No dates._

## Preferences
_Store: standing rules for how to work with them. No dates._

## Workflow
_Store: commits, PRs, reviews, subagents. Dated._

## Tooling
_Store: CLIs, MCPs, versions, quirks. Dated._

## Decisions
_Store: why X over Y, cross-repo. Dated._

## People
_Store: recurring collaborators and how to refer to them. Dated._

## Do not store here

- Repo-specific architecture, paths, or team context (use project `.cursor/memory.md`).
- Secrets, tokens, credentials.
```

### Project layout (`.cursor/memory.md`)

```markdown
# Project memory

Durable facts about this repo. Not personal preferences.

## Architecture
_Store: where things live, module boundaries, “we always do Z here.” Dated._

## Environments
_Store: env names, account/cluster layout. No secrets. Dated._

## Conventions
_Store: naming, tests, code-gen, review norms. Dated._

## Commands
_Store: how to run, generate, deploy this repo. Dated._

## Gotchas
_Store: resolved surprises (the answer, not the debug steps). Dated._

## Open threads
_Store: resumable multi-step work only. Dated._

## Glossary
_Store: team/domain terms the agent got wrong. Dated._

## Do not store here

- Personal workflow prefs (use global `~/.cursor/memory.md`).
- Secrets, tokens, credentials.
```

## When to write (proactive)

Update memory whenever information is **likely to help a future conversation**, not only when the user says “remember.”

**Write without being asked** when you learn or confirm something that has a home below. Map the fact to the matching section (examples are illustrative, not facts to copy):

**Global `## Identity`** (no dates) — name, role, how to address them, timezone, units:

```markdown
- Bob Tables (call me Bob). SQL specialist.
- **Time display:** Pacific (`America/Los_Angeles`), labeled with the current UTC offset.
```

**Global `## Preferences`** (no dates) — standing rules for how to work with them:

```markdown
- **Naming in written documents:** use full name **Bob Tables**, never "Bob". "Bob" is fine in chat.
```

**Global `## Workflow`** (dated) — commits, PRs, reviews, subagents:

```markdown
- Only launch subagents on the parent model unless asked. (2026-08-19)
```

**Global `## Tooling`** (dated) — CLIs, MCPs, versions, quirks:

```markdown
- **Lens kubectl:** 64 KB cap is unmarked in payloads; prefer compact output over `-o json`. (2026-06-22)
```

**Global `## Decisions`** (dated) — why X over Y, cross-repo:

```markdown
- Use Lens MCP (Desktop connected) for cluster queries; local kubectl in the sandbox may fail without network. (2026-06-22)
```

**Global `## People`** (dated) — recurring collaborators and how to refer to them:

```markdown
- **Alex:** staff engineer on platform; ping for infra reviews. (2026-08-19)
```

**Project `## Architecture`** — where things live, “we always do Z here”:

```markdown
- Auth lives in `internal/identity`; feature flags are in `pkg/flags`, not env vars. (2026-08-19)
```

**Project `## Environments`** — env/account/cluster names, no secrets:

```markdown
- `staging` is the Lens cluster `sbs-staging`; production is `sbs-prod`. (2026-08-19)
```

**Project `## Conventions`** — naming, tests, code-gen, review norms:

```markdown
- Integration tests are `*_test.go` under `internal/`; never hit real staging from unit tests. (2026-08-19)
```

**Project `## Commands`** — how to run, generate, deploy this repo:

```markdown
- `make gen` regenerates OpenAPI clients; run it after spec changes. (2026-08-19)
```

**Project `## Gotchas`** — resolved surprises (the answer, not the debug steps):

```markdown
- Truncated Lens `kubectl` JSON is a 64 KB cap, not an empty list — recount with `-o name`. (2026-06-22)
```

**Project `## Open threads`** — resumable multi-step work only:

```markdown
- Migrate the billing webhook to the v2 signer; blocked on sandbox cert rotation. (2026-08-19)
```

**Project `## Glossary`** — team/domain terms the agent got wrong:

```markdown
- **SBS ID:** 26-char environment id (`X-SBS-ID`), not a player id. (2026-08-19)
```

**Still skip** (do not store):

- Secrets, tokens, credentials, or private URLs with auth.
- Purely ephemeral state (“fixing line 42 now”, current branch name unless long-lived policy).
- Large paste dumps — distill to one bullet.
- Anything already in memory unchanged — read first, dedupe.
- Guesses or unconfirmed assumptions — store facts, not hypotheses.

**Cadence:** After every reply that established a durable fact, write it in the same turn. Do not wait for “remember” or for the task to finish. Also, before you consider a task done, ask: *“Would another chat in this repo (or any repo) get stuck without this?”* If yes, append or update memory. You do not need permission for small, high-confidence bullets; mention briefly in your reply what you saved (one line).

If scope is unclear (global vs project), prefer **project** for repo-specific facts and **global** for personal workflow prefs.

## Scope rules

- **Global:** identity, communication style, git/PR habits, tooling prefs, cross-repo habits, people.
- **Project:** architecture, env names, module patterns, team conventions, commands, gotchas, repo-specific decisions and open threads.

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

`## Identity` and `## Preferences` are durable standing rules — **no dates**
on those bullets. **Never compact/archive `## Identity` or `## Preferences`
by age.** Only dedupe/supersede them. Age-based compaction into
`memory-archive-YYYY.md` applies to bullets in `## Decisions` and other
dated sections: use the trailing `(YYYY-MM-DD)` at the end of the line to
decide age (exactly one date per bullet).

## Entry format

**`## Identity` and `## Preferences`** — standing facts/rules only. **No dates** (no trailing `(…)` either).

```markdown
- <one concise bullet>
- **Optional label:** detail when it helps scanning
```

**All other sections** (`## Workflow`, `## Tooling`, `## Decisions`, `## People`, and every project section) — content first, **one** date in parentheses at the end:

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
| Compact memory | Move bullets older than 90 days to `memory-archive-YYYY.md` in the same directory (**never `## Identity` or `## Preferences`** — see Retention above); keep the main file under ~150 lines |
| What do you remember? | Show current memory content for the relevant scope(s); don't paraphrase from injected context if the file may have changed this session — re-read it |

## How to edit

1. Read the target file(s).
2. Apply edits; keep section headings intact and in the order above.
3. For large or sensitive changes, state the bullet first; for routine proactive saves, a one-line note in the reply is enough.
4. Confirm what was stored and where when the user asked explicitly; otherwise keep confirmation minimal.

## Git

Project memory may be committed for team sharing. Global memory lives outside the repo and is never committed.
