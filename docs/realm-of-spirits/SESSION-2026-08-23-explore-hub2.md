# SESSION 2026-08-23 — B2 Explore hub 2

**Трек:** [`MONTH-PLAN-2026-09-dev.md`](MONTH-PLAN-2026-09-dev.md) W4 backlog **B2**  
**Place:** `C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl`  
**Тип:** MCP smoke (Edit + Play Server)

## Вердикт: **PASS (user hands, self-reported 2026-08-23)** · MCP world **PASS** · quest BF **CONDITIONAL**

| Шаг | Результат |
|-----|-----------|
| `EnsureExploreHub2Route` — 3 знака | **PASS** (ExploreHub2Start/Mid/End) |
| Гравийная тропа `ExploreHub2Trail` | **PASS** (5 сегментов) |
| Лут обхода `Crystal_102_6` @ (38,2,52) | **PASS** |
| QuestSystem `[115]`/`[116]` в Source | **PASS** (grep SoT) |
| Quest BF chain 113→116 | **CONDITIONAL** — в place нет `QuestAcceptBF` (нет W2-style BF smoke) |
| **Hands обход B2** | **PASS (user, self-reported 2026-08-23)** — owner «pass» после hands verify |

## Маршруты Haven → Combat

| # | Маршрут | Ориентиры | Лут |
|---|---------|-----------|-----|
| **1 (главный)** | Exit door (юг Haven) → `DirtRoad_HavenToArena` → арена/Combat | ExitWayfindBillboard · DuelWayfind | огонь #101 у Exit (W2 q114) · сундук (18,54) |
| **2 (B2 обход)** | Genkan восток → ScoutPost → Combat | 3 синих знака `ExploreHub2Wayfind` + гравий | лёд #102 @ (38,52) (q116) |

**Время:** обход ~2–3 мин пешком от Genkan до ScoutPost (≤5 мин до лута).

## Контент

| Id | Название | Цель | Prereq |
|----|----------|------|--------|
| **115** | Обходная тропа | VisitZone **ScoutPost** | Q114 |
| **116** | Лёд на обходе | CollectItem **102** ×1 | Q115 |

- **Код:** `OtakuHavenBuilder.EnsureExploreHub2Route` · `WorldLootService` · inline `QuestSystem` (SoT) · mirror `QuestCatalog`
- **Copy (RU):** «Обходная тропа → Combat · следуй знакам» · «Лагерь разведки · лут E → Combat» · «Combat · лови духа E»

## Hands verify (owner)

1. **Ctrl+S** place после сессии.
2. Spawn → восточнее Genkan найти **синий знак** «Обходная тропа → Combat».
3. Идти по гравийной полосе к ScoutPost (~2 мин) → второй знак «Лагерь разведки».
4. **E** на синий кристалл #102 у тропы (подсветка).
5. Третий знак «Combat · лови духа E» → зона Combat.
6. (Опц.) Q114 сдан → принять **115** → зайти ScoutPost → **116** → собрать лёд.

## Оговорки

- Patch через `Ensure*` — **не** полный `OtakuHavenBuilder.Build()` (сохранён ручной décor/shrine).
- Mirror `QuestCatalog.lua` опережает SoT: квесты в Studio пока inline в `QuestSystem`.
- Quest BF smoke как W2 — ждёт `QuestAcceptBF` в place или hands.

## Exit

**B2 COMPLETE** — MCP world PASS + **PASS (user hands, self-reported 2026-08-23)**. Quest BF chain остаётся CONDITIONAL (нет `QuestAcceptBF` smoke).

## Next (post-B2)

- **Пауза / polish-only** — backlog B пуст после B2
- Или **B1 PvP slice 3** (post-duel уже частично в Q3) — по явной команде
