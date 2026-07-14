---
name: realm-session-checkpoint
description: >-
  Saves and resumes Realm of Spirits sessions: NEXT-SESSION.md, SESSION notes,
  CHANGELOG, docs/studio Lua mirrors, scoped git commit when asked. Use when
  the user says pause, checkpoint, save progress, зафиксируй, or tomorrow continue.
---

# Realm Session Checkpoint

## When pausing / ending

1. Update `docs/realm-of-spirits/NEXT-SESSION.md`:
   - What is DONE
   - Exact next step (one primary task)
   - Studio SoT reminder + Ctrl+S
2. Append session bullets to `docs/realm-of-spirits/SESSION-YYYY-MM-DD.md` (create if needed).
3. Sync changed Studio modules → `docs/realm-of-spirits/studio/`.
4. Touch `CHANGELOG.md` `[Unreleased]` if gameplay/code changed.
5. Commit **only if user asked** — stage only realm docs/skills related files; use one-shot `git -c user.name=... -c user.email=...` if identity missing (never `git config`).

## When resuming

1. Read `NEXT-SESSION.md` first.
2. Verify Studio MCP + place open.
3. Do not invent a new priority over the file unless user overrides.

## Minimum NEXT-SESSION shape

```markdown
## Старт сессии (порядок жёсткий)
1. <current top task>
2. ...

## Studio SoT
- list modules touched
```
