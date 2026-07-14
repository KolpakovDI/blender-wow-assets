# NEXT SESSION

**Статус:** разработка геймплея на **паузе**. Сейчас приоритет — Cursor-инфраструктура (уже заложена) и следующий боевой код, когда снимешь паузу.

Дата якоря: 2026-07-14

## Cursor infra (готово)

- Skills: `.cursor/skills/realm-orchestrator`, `realm-studio-mcp`, `realm-session-checkpoint`, `realm-battle-pipeline`
- Agent: `.cursor/agents/realm-orchestrator.md`
- Rules: `realm-of-spirits.mdc`, `realm-cursor-workflow.mdc` (alwaysApply)
- Entry: `AGENTS.md`

## Когда снова включишь игру — порядок жёсткий

1. ~~SkillCatalog / EffectCatalog / ItemCatalog~~ — DONE (Studio + docs mirrors)
2. **Battle Orchestrator** — модуль применения скиллов, валидация CD/MP/stun, синк UI ← **первый геймплей-таск**
3. Проводка `GameManager` + `BattleSystem` + боевой UI под 3 слота

Не начинать с декора Otaku Haven / арены, пока оркестратор не поднят.

## Контекст уже сделан (мир)

- Otaku Haven 2×, 2 этаж, фусума, сплошная крыша, wall2H=12, roofLift=2.5
- Мика (-12, -38), Safe 160 по Z, Combat без пересечения с магазином
- BattleArenaBuilder cyberpunk
- Place: `RealmOfSpirits second.rbxl` — **Ctrl+S в Studio** (rbxl не в git)

## Studio SoT

- `ReplicatedStorage.RealmOfSpirits`: ZoneConfig, SpiritDatabase, SkillCatalog, EffectCatalog, ItemCatalog
- `ServerScriptService.RealmOfSpirits`: OtakuHavenBuilder, BattleArenaBuilder, GameManager, BattleSystem
