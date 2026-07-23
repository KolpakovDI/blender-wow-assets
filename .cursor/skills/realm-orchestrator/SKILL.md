---
name: realm-orchestrator
description: >-
  Orchestrates Realm of Spirits work sessions in Cursor: picks the right
  workflow (Studio MCP, catalogs/battle, session checkpoint, docs sync),
  enforces NEXT-SESSION order, and avoids decorative Haven work during
  combat-pipeline focus. Use when the user mentions Realm of Spirits,
  Otaku Haven, SkillCatalog, Battle Orchestrator, Studio MCP, or asks what
  to do next on this Roblox project.
---

# Realm Orchestrator

Entry skill for all Realm of Spirits agent work.

## Before any task

1. Read `docs/realm-of-spirits/NEXT-SESSION.md` — hard priority order.
2. Check Studio MCP (`user-Roblox_Studio`): if needed, call `get_studio_state`.
3. Place SoT: `C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl` (not in git). Remind **Ctrl+S** after Studio edits.
4. Docs mirrors: `docs/realm-of-spirits/studio/*.lua` — sync after meaningful Studio module changes.

## Route by intent

| User intent | Skill / path |
|-------------|--------------|
| Session start / “что дальше” / resume | This skill + `NEXT-SESSION.md` |
| Edit place via Studio MCP | Read [realm-studio-mcp](../realm-studio-mcp/SKILL.md) |
| Mesh / model from text prompt → Studio | Read [realm-mesh-from-prompt](../realm-mesh-from-prompt/SKILL.md) |
| Save / pause / checkpoint | Read [realm-session-checkpoint](../realm-session-checkpoint/SKILL.md) |
| Skills / effects / battle orchestrator / GameManager combat | Read [realm-battle-pipeline](../realm-battle-pipeline/SKILL.md) |
| Changelog / GDD / docs only | `.cursor/rules/realm-of-spirits.mdc` |

## Hard rules

- Do **not** start with Otaku Haven décor / arena polish while `NEXT-SESSION.md` says battle pipeline is next.
- Prefer shared catalogs in `ReplicatedStorage.RealmOfSpirits`:
  - `SkillCatalog`, `EffectCatalog`, `ItemCatalog`, `SpiritDatabase`, `ZoneConfig`
- After Studio `ModuleScript` Source edits: bust require cache (Destroy + recreate ModuleScript) before `require` / `Build()`.
- Never commit `.rbxl`. Never `git config`. Commit only when user asks.
- Russian UI strings stay Russian; agent chat with user in Russian when they write Russian.

## Session open checklist

```
- [ ] MCP Studio ready (Edit mode)
- [ ] NEXT-SESSION top item identified
- [ ] No parallel décor tasks unless user explicitly asks
```

## Session close checklist

Hand off to `realm-session-checkpoint`.
