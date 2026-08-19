# NEXT SESSION

**Статус:** 2026-08-19 checkpoint — **Combat Anim cat.1 proposed**; W1 Sanctum smoke **PASS**; docs/mirrors в git.  
**План месяца:** [`MONTH-PLAN-2026-09-dev.md`](MONTH-PLAN-2026-09-dev.md)  
**Текущая неделя:** W1 Sanctum (закрыто) → **Combat animations pipeline**

## Старт сессии (порядок жёсткий)

1. **Combat Anim — категория 1 (Melee + Physical)**  
   - Прочитать [`COMBAT-ANIMATIONS.md`](COMBAT-ANIMATIONS.md)  
   - Studio: `ReplicatedStorage.RealmOfSpirits.CombatAnimations/` (`522635514` slash, `522638767` lunge)  
   - `ClientController` или `CombatAnimResolver` — выбор по `SkillCatalog.GetCombatMeta`  
   - Skill **119** → lunge; остальные 10 физ. melee → slash  
   - Play smoke: skill 1 + 119 с RealmBlade  
   - **Ctrl+S**

2. **Категории 2–4** — по одной после smoke cat.1 (см. матрицу в `COMBAT-ANIMATIONS.md`)

3. **Опционально:** sync `SkillCatalog.CombatMeta` + `QuestUIChain` в `.rbxl` если mirror ≠ place

## Где остановились

| Область | Состояние |
|---------|-----------|
| Quest UI chains | Done (mirror + Studio MCP) |
| SPIRIT-SKILLS + CombatMeta | Done (mirror; Studio sync — проверить) |
| Combat Anim cat.1 | **Analysis done, implementation pending** |
| Sanctum W1 | PASS — [`SESSION-2026-08-19-w1-sanctum-smoke.md`](SESSION-2026-08-19-w1-sanctum-smoke.md) |

## Studio SoT

`C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl`

**Модули в mirror (сессия):** `SkillCatalog`, `QuestUI`, `QuestUIChain`, Sanctum/QuestCatalog/DataStoreManager

**Audit в place (можно убрать):** `ServerStorage._AnimAudit_OfficialSlash`

## Не включать

Allow* · Guilds · ProfileService live · PvP · Haven décor · второй major track

## Архив

[`SESSION-2026-08-19-combat-animations-checkpoint.md`](SESSION-2026-08-19-combat-animations-checkpoint.md) · Resonant loop · W1 Sanctum smoke
