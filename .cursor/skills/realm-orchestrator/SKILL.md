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
| **«A1»** / **«анимации»** / **«Anim block»** | [`BLOCK-ANIM-CHAR-ART-2026-08-28.md`](../../docs/realm-of-spirits/BLOCK-ANIM-CHAR-ART-2026-08-28.md) · paid setup [`OWNER-SETUP-PAID-AI.md`](../../docs/realm-of-spirits/OWNER-SETUP-PAID-AI.md) |
| Changelog / GDD / docs only | `.cursor/rules/realm-of-spirits.mdc` |

## Hard rules

- Do **not** start with Otaku Haven décor / arena polish while `NEXT-SESSION.md` says battle pipeline is next.
- Prefer shared catalogs in `ReplicatedStorage.RealmOfSpirits`:
  - `SkillCatalog`, `EffectCatalog`, `ItemCatalog`, `SpiritDatabase`, `ZoneConfig`
- After Studio `ModuleScript` Source edits: bust require cache (Destroy + recreate ModuleScript) before `require` / `Build()`.
- Never commit `.rbxl` or secrets. **Always commit** meaningful docs/skills/mirrors after a coherent chunk; do not push unless asked.
- Russian UI strings stay Russian; agent chat with user in Russian when they write Russian.
- **DEV-ONLY default:** do not suggest Publish on every «дальше». When [`NEXT-SESSION.md`](../../docs/realm-of-spirits/NEXT-SESSION.md) § Readiness assessment = **PASS**, agent **may** proactively offer owner unlock / Publish with rationale; owner decides.

## Session open checklist

```
- [ ] MCP Studio ready (Edit mode)
- [ ] NEXT-SESSION top item identified
- [ ] No parallel décor tasks unless user explicitly asks
```

## Session close checklist

Hand off to `realm-session-checkpoint`.
