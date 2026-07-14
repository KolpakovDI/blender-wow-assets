---
name: realm-battle-pipeline
description: >-
  Implements Realm of Spirits combat data and runtime: SkillCatalog,
  EffectCatalog, ItemCatalog, Battle Orchestrator, GameManager/BattleSystem/UI
  wiring. Use when building skills, effects, orchestrator, cooldowns, MP, or
  battle UI ability slots — not for Haven décor.
---

# Realm Battle Pipeline

## Already in place (Studio + docs mirrors)

- `ReplicatedStorage.RealmOfSpirits.SkillCatalog` — ById / ByName / SpiritSkills / Resolve / BuildAbilities
- `EffectCatalog` — Burn/Stun/Buff/Debuff Apply + Step
- `ItemCatalog` — shop + evolution crystals
- `SpiritDatabase` — `SkillIds`; shop via `ItemCatalog.ShopIds`
- `GameManager` / `BattleSystem` — require shared catalogs (up to 3 abilities)

## Next: Battle Orchestrator

Create `ReplicatedStorage` or `ServerScriptService` module `BattleOrchestrator` that owns:

1. Validate skill use (CD, MP, stun, in-battle)
2. Resolve skill via `SkillCatalog.Resolve`
3. Apply damage/heal via `SpiritDatabase.CalculateDamage` + `EffectCatalog`
4. Tick effects (`Step`, burn)
5. Emit client payload (abilities, cooldowns, HP/MP, message)
6. End battle / flee / catch handoff stays in `GameManager` unless moved deliberately

Prefer thin `GameManager` battle handlers that call Orchestrator.

## UI expectations

- Support **up to 3** ability buttons from `BuildAbilities(..., 3)`.
- Cooldown display from server battle state (existing PlayerCooldowns pattern).

## Validation

If available, run:

```bash
python scripts/quality_gate.py
```

Update validators when SkillIds replace inline Skills tables.

## Anti-scope

Do not rebuild Otaku Haven / arena while implementing orchestrator unless blocked by a real combat bug.
