# Quest Balance — Realm of Spirits (Q1 expansion)

**Статус:** Slice 0 / Q1 · 2026-08-15  
**Каталог:** `ReplicatedStorage.RealmOfSpirits.QuestCatalog` · runtime: `ServerScriptService.RealmOfSpirits.QuestSystem`  
**Экономия:** см. [`ECONOMY-BALANCE.md`](ECONOMY-BALANCE.md) · fair combat без ATK/DEF за copper.

---

## Кривая наград (Story)

| Player Lv | XP turn-in | Copper | Цель цикла |
|-----------|------------|--------|------------|
| 1 | 60–100 | 40–60 | onboarding Exit→Catch |
| 2–3 | 120–200 | 70–100 | бой + коллекция |
| 4–6 | 250–400 | 120–180 | mid story |
| 7–10 | 450–800 | 200–350 | mastery |
| 10+ | 800–1500 | 350–500 | legendary / Kami gate |

Side: ~40–60% от Story того же уровня. Hunt: трофей Unique + mats, XP чуть ниже Side.

## Капы

| Правило | Значение |
|---------|----------|
| Активных Story одновременно | 1 (рекомендация UI; сервер допускает больше) |
| Side в день (soft) | без жёсткого капа; Daily Board отдельно |
| Deprecated Hunt | 213 Sand, 215 Crystal — скрыты из GetQuests |

## ZoneHint / TargetZone

Каждый Story/новый exploration-квест несёт:

- `ZoneHint` — русская подсказка для Quest UI / NextStepChip  
- `TargetZone` — ключ `ZoneDetail` из [`ZoneConfig`](studio/ZoneConfig.lua)

Objective `VisitZone` + `{ ZoneDetail = "FrostRidge" }` закрывается при входе в зону (`ZoneSystem`).

## Таблица квест → зона (ядро)

| Id | Имя | TargetZone | Spirit/Loot |
|----|-----|------------|-------------|
| 7 | Украденная манга | Exit | item 120 |
| 1 | Первые шаги | Combat / Akihabara | Catch any |
| 2 | Тренировка | Combat / BattleArena | Defeat 3 |
| 3 | Коллекционер | Combat+habitats | 3 types |
| 8 | К хребту льда | FrostRidge | VisitZone |
| 9 | Пепел сада | AshGarden | VisitZone |
| 10 | Каменный путь | StoneBasin | VisitZone |
| 11 | Тень лощины | ShadowHollow | VisitCatch 33 |
| 12 | Гроза шпиля | StormSpire | VisitZone |
| 13 | Луг рассвета | DawnMeadow | VisitZone |
| 14 | Прибрежный зов | MistPond | VisitZone |
| 15 | Ветряной утёс | GaleCliff | VisitZone |
| 16 | Моховая поляна | MossGlade | VisitZone |
| 107 | Разведка лагеря | ScoutPost | VisitZone |

Hunt 201–218 → `SpiritHabitats` labels (без изменений порядка 4×4).

## Quest locations (Q2+)

Именованные точки в `ZoneConfig.QuestLocations` (Camp / Shrine / ChestCluster / ScoutPost / Waystone / Overlook) — каждая ≥1 квест.

---

## Year pointer

Полный roadmap: [`YEAR-PLAN-2026-10.md`](YEAR-PLAN-2026-10.md) (Q1 квесты → Q2 ландшафт → Q3 PvP/Haven → Q4 mesh/ProfileService).
