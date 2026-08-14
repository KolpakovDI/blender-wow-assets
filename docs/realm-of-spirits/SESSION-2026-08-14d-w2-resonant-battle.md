# SESSION 2026-08-14d — W2 Resonant в бою

**Статус:** **PASS**  
**Place SoT:** `C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl` (Ctrl+S после патча ~22:43)

## Цель

Синтез → активный Ками (Resonant) → дикий бой → слот 1 = навык Resonant (не молчаливый Start / не чужой шаблон).

## Баг

`GameManager` Start брал `GetSpirit(playerSpirit.Id)`. У Resonant Id = **9xxx** (нет в `SpiritDatabase`) → `spiritInfo == nil` → **тихий return**. V / `Battle:FireServer("Start")` не давали строк боя.

`BuildPlayerAbilities` уже умел `playerSpirit.SkillIds` — ломался только резолв info на Start.

## Фикс (SoT + mirror)

В `ServerScriptService.RealmOfSpirits.GameManager`:

- `ResolveBattleSpiritInfo(playerSpirit)` — каталог если есть; иначе при `Kind == "Resonant"` / `Id >= 9000` синтетический info с `BaseStats` ядра `ParentIds[1]`, `SkillIds` / имя / элемент с roster.
- Start: `spiritInfo = ResolveBattleSpiritInfo(playerSpirit)`.

Mirror: `docs/realm-of-spirits/studio/GameManager.lua`.

## Smoke (MCP Play)

1. `KamiSanctumBF` SeedQA → `ForceCatchBF(12)` → Synthesize `{1,2}` → SetActive 2.  
2. Активный: **Ками-Корни** Resonant, слот 1 roster = **Землетрясение** (`SkillIds` 62,1,61).  
3. Бой vs **Лунный Кролик**: `PlayerSkills` = `Землетрясение|Огненный коготь|Каменный кулак`.  
4. Attack SkillIndex=1 → лог: **«Вы нанесли 63 урона! (Землетрясение)»**.

## Заметки

- `ForceCatchBF` / `GetPlayerDataBF` — `ReplicatedStorage.RealmOfSpirits`; `KamiSanctumBF` — SSS.  
- После поражения `activeBattles` может держать «уже в бою» — для чистого smoke: Stop/Start Play.  
- FEFF `user_RoS_ShortGrass` — plugin, ignore.

## Next

**W3** — Care или Temper на Resonant с видимым toast/UI (`WEEK-PLAN-2026-08-26.md`).
