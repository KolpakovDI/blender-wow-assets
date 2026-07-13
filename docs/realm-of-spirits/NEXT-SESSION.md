# NEXT SESSION — обязательно сначала

Дата якоря: 2026-07-13 evening / продолжение 2026-07-14+

## Старт сессии (порядок жёсткий)

1. **SkillCatalog / Skills data** — каталог способностей, эффекты (Burn/Stun/Buff/Debuff), MP, CD, привязка к духам в `SpiritDatabase`
2. **Battle Orchestrator** — оркестратор применения скиллов, порядок/валидация, синк с клиентом
3. Проводка в `BattleSystem` + `GameManager` + боевой UI (`UIController`)

Не начинать с декора Otaku Haven / арены, пока скиллы и оркестратор не подняты.

## Контекст уже сделан (можно не трогать сразу)

- Otaku Haven 2×, 2 этаж, фусума, сплошная крыша, wall2H=12, roofLift=2.5
- Мика (-12, -38), Safe 160 по Z, Combat без пересечения с магазином
- BattleArenaBuilder cyberpunk
- Place: `RealmOfSpirits second.rbxl` — **Ctrl+S в Studio обязателен** (rbxl не в git)

## Studio SoT

- `ReplicatedStorage.RealmOfSpirits.ZoneConfig`
- `ServerScriptService.RealmOfSpirits.OtakuHavenBuilder`
- `ServerScriptService.RealmOfSpirits.BattleArenaBuilder`