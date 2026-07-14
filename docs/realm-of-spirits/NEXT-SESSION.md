# NEXT SESSION

**Статус:** боевой пайплайн подключён. Следующий фокус — play-тест и полировка боя / контент.

Дата якоря: 2026-07-14

## Cursor infra (готово)

- Skills: `.cursor/skills/realm-orchestrator`, `realm-studio-mcp`, `realm-session-checkpoint`, `realm-battle-pipeline`
- Agent: `.cursor/agents/realm-orchestrator.md`
- Rules: `realm-of-spirits.mdc`, `realm-cursor-workflow.mdc` (alwaysApply)
- Entry: `AGENTS.md`

## Боевой пайплайн (готово)

1. ~~SkillCatalog / EffectCatalog / ItemCatalog~~ — DONE
2. ~~Battle Orchestrator~~ — DONE (`ServerScriptService.RealmOfSpirits.BattleOrchestrator`)
3. ~~Проводка GameManager Attack + Enemy AI~~ — DONE
4. ~~Боевой UI: 3 слота навыков~~ — DONE (`UIController` Attack3Button)

## Когда продолжишь игру

1. **Play-тест боя** в Studio: CD/MP/stun, heal, 3-й навык, победа/поражение/flee
2. Полировка BattleSystem / баланс / эффекты по результатам теста
3. Только потом — декор Otaku Haven / арены

## Контекст уже сделан (мир)

- Otaku Haven 2×, 2 этаж, фусума, сплошная крыша, wall2H=12, roofLift=2.5
- Мика (-12, -38), Safe 160 по Z, Combat без пересечения с магазином
- BattleArenaBuilder cyberpunk
- Place: `RealmOfSpirits second.rbxl` — **Ctrl+S в Studio** (rbxl не в git)

## Studio SoT

- `ReplicatedStorage.RealmOfSpirits`: ZoneConfig, SpiritDatabase, SkillCatalog, EffectCatalog, ItemCatalog
- `ServerScriptService.RealmOfSpirits`: BattleOrchestrator, OtakuHavenBuilder, BattleArenaBuilder, GameManager, BattleSystem
- Docs mirrors: `docs/realm-of-spirits/studio/BattleOrchestrator.lua`, catalogs, `UIController.lua`
