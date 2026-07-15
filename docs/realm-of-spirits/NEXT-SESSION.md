# NEXT SESSION

**Статус:** P1 Identity PASS · Explore A/B PASS · Explore C (код+UX) готово → **завтра play-тест funnel 101**.

Дата якоря: 2026-07-15 (вечер) → план на **2026-07-16**

## Цели (locked)

См. [`GOALS.md`](./GOALS.md) и GDD §9.

| Done | P0 Core + P0 Hub + **P1 Identity** + Explore A/B |
| Now | **P1 Explore C** — сдать side **101**, закрыть gate Explore |
| Later | Social → P2 Scale по gate |

## Старт сессии (порядок жёсткий)

1. **Ctrl+S** проверка place открыт: `RealmOfSpirits second.rbxl`
2. Play → Мика → **Доступные**: вторым должен быть **«Помощь торговцу»** (101)
3. Accept 101 → Combat → подобрать **5× огненный кристалл** (ItemId 101) → сдать Мике
4. Если PASS → отметить Explore C / Explore gate в GOALS + CHANGELOG; иначе фиксить прогресс `CollectItem`
5. Только после gate Explore: **P1 Social** (fair combat / cosmetics gacha) — не раньше

## План на завтра (чеклист)

### Обязательно (Explore C gate)

- [ ] Funnel 101: Accept → 5 fire crystals → Turn-in (XP/монеты/зелья)
- [ ] Прогресс квеста тикает от лута (`CollectItem`), не только от инвентаря вручную
- [ ] После сдачи 101 нет в Available; есть в Completed

### Желательно (смоук side)

- [ ] В Available видны 102/103 (после сдачи 101); 104 после story 1; 105 после 101–104
- [ ] Spot-check: side 103 награда = UniqueItem «Посох Хранителя» + зелья (код уже в place)

### Не трогать завтра (пока Explore не PASS)

- Декор Haven / новые зоны
- PvP / Scale
- Новый большой фича-спайк Social

## Уже в place (напоминание)

### Identity — PASS
- Evo banner, Attack3, rank ≤2 клика; DevBoost LeftAlt+B / `[DEV] Evo Boost`

### Explore A/B — PASS
- Tutorial crystal, Combat loot, ice 102, toast, имена ItemCatalog

### Explore C — код готов
- 103 UniqueItems; 105 prereq 101–104
- Available sort Level→Id; список Мики `QUEST_LIST_H = 120`

## Studio SoT

Place: `C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl` — **не в git**; после правок **Ctrl+S**.

| Module | Path |
|--------|------|
| QuestSystem | `ServerScriptService.RealmOfSpirits.QuestSystem` |
| QuestUI | `StarterPlayer.StarterPlayerScripts.QuestUI` |
| WorldLootService | `ServerScriptService.RealmOfSpirits.WorldLootService` |
| GameManager | `ServerScriptService.RealmOfSpirits.GameManager` |

Зеркала: `docs/realm-of-spirits/studio/`. Ноты дня: [`SESSION-2026-07-15.md`](./SESSION-2026-07-15.md).
