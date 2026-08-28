# Agents — Realm of Spirits / blender-wow-assets

## Project focus

Roblox game **Realm of Spirits** (place: `RealmOfSpirits second.rbxl` under `C:\Mimo\RealmOfSpirits\`).  
Git holds docs + Cursor infra + tooling; the `.rbxl` is **not** in git. After meaningful repo edits, **commit** (never `.rbxl` / secrets / `.tmp_extract`); push only when asked.

## Start here every session

1. Read [`docs/realm-of-spirits/NEXT-SESSION.md`](docs/realm-of-spirits/NEXT-SESSION.md) — **current:** week plan 26.08–01.09 Resonant loop + P0 friction (`WEEK-PLAN-2026-08-26.md`)
2. Load skill **realm-orchestrator** (`.cursor/skills/realm-orchestrator/SKILL.md`)
3. Confirm Studio MCP `user-Roblox_Studio` if place edits are needed

## Skills (project)

| Skill | Use for |
|-------|---------|
| `realm-orchestrator` | Routing, priorities, session rules |
| `realm-studio-mcp` | Roblox Studio MCP edit/rebuild/export |
| `realm-mesh-from-prompt` | Blender → Open Cloud FBX upload → Studio `insert_asset` |
| `realm-session-checkpoint` | Pause / save / resume docs + optional commit |
| `realm-battle-pipeline` | SkillCatalog → Orchestrator → battle UI |

## Anim / Char Art (named backlog)

Start only on **«A1»** / **«анимации»** / **«Anim block»** — not default next (post-W18 regression stays primary).

| Doc | Role |
|-----|------|
| [`BLOCK-ANIM-CHAR-ART-2026-08-28.md`](docs/realm-of-spirits/BLOCK-ANIM-CHAR-ART-2026-08-28.md) | A1–A6 slices · agent playbook · § Paid stack |
| [`RESEARCH-AI-ANIM-ART-2026-08-28.md`](docs/realm-of-spirits/RESEARCH-AI-ANIM-ART-2026-08-28.md) | Tool pricing · Tier 0/1/2 comparison |
| [`OWNER-SETUP-PAID-AI.md`](docs/realm-of-spirits/OWNER-SETUP-PAID-AI.md) | Owner checklist before **«A3 Tripo»** (~$12/mo minimal) |
| [`COMBAT-ANIMATIONS.md`](docs/realm-of-spirits/COMBAT-ANIMATIONS.md) | Clip IDs · free/paid paths · A1 restore reference |

Personal (all Roblox projects): `luau-roblox-style` in `~/.cursor/skills/` — `--!strict`, `task.*`, Parent-last `Instance.new`, CollectionService tags.

## Subagent

- `.cursor/agents/realm-orchestrator.md` — coordinator; use for “what next” / multi-step RoS work

## Rules

- `.cursor/rules/realm-of-spirits.mdc` — changelog / GDD / PROJECT docs
- `.cursor/rules/realm-cursor-workflow.mdc` — always-on Cursor workflow for this repo

## Quality gate

```bash
python scripts/quality_gate.py
```

See `docs/realm-of-spirits/AUTOMATION.md`.
