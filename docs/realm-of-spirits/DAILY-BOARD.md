# Daily Board — дизайн (scope A)

Статус: **дизайн зафиксирован** · 2026-07-28 · код не трогали  
Вдохновение: Card Heroes daily «лист дня» / streak 6 из 6 (урезано до 4)  
Связано: [`SPIRIT-RESONANCE-PLAN.md`](SPIRIT-RESONANCE-PLAN.md), [`ECONOMY-BALANCE.md`](ECONOMY-BALANCE.md), `SeasonLiveOps`

## Цель

Короткий ежедневный ритуал **5–10 мин** в Haven / мире: закрыть 4 слота → soft-награда и бонус на завтра.  
Ретеншен D1–D7 без нового контента-локаций и без боевого pay-to-win.

## Решение UI

Расширить существующий **`ResonanceActivityBar`** в [`studio/UIController.lua`](studio/UIController.lua) (сейчас: `Сегодня: Уход ○  Закалка ○`).

- Не отдельная вкладка у Мики, не панель PASS.
- Текст v1 (пример): `День 2/4 · Уход ✓ · Закалка ○ · Бой ○ · Лут ○`
- При **4/4**: суффикс `· Бонус завтра` (или цвет как у полного Care+Temper).

## 4 слота дня (фиксированный набор v1)

Ротации слотов в v1 нет — один и тот же лист каждый день.

| Slot | Цель | Уже есть в коде | Примечание |
|------|------|-----------------|------------|
| 1 | Уход (Care) | `ResonanceDaily.Care`, quest **301** | Один успешный Care за день |
| 2 | Закалка (Temper) | `ResonanceDaily.Temper`, quest **302** / weekly **303** | Один Temper за день |
| 3 | 1 победа в бою | `GameManager.EndBattle` → Pass/tokens | Любая победа PvE |
| 4 | Поймать духа **или** открыть сундук | Catch / `WorldLootService` chest | OR: достаточно одного из двух |

Квесты 301–303 остаются отдельными (Мика); слоты доски **не** требуют сдачи квеста — только факт действия дня.

## Награды (soft only)

Fair combat: **нет** ATK/DEF/HP/catch-rate от доски.

| Событие | Награда (ориентир) |
|---------|-------------------|
| Закрытие слота 1–4 | Малый drip: Pass XP и/или 1 жетон (как текущий SeasonLiveOps с Care/Temper/боя) |
| **4/4 полный день** | Флаг `BonusNextDay = true` |
| На следующий день, пока флаг | ×2 Pass XP / жетоны с Care, Temper и победы в бою (не с copper shop, не free temper stone) |

Не давать сверх [`ECONOMY-BALANCE.md`](ECONOMY-BALANCE.md): temper stone daily buy cap, unsellable crystals, cosmetics-only gold sinks.

## Контракт данных (без реализации)

```lua
playerData.DailyBoard = {
  DayKey = "2026-07-28", -- YYYY-MM-DD, серверный календарный день (UTC рекомендуется)
  Care = false,
  Temper = false,
  BattleWin = false,
  CatchOrChest = false,
  BonusNextDay = false, -- выставляется при 4/4; тратится/сбрасывается на новом DayKey после применения ×2
  ClaimedSlots = {},    -- опционально: анти-дубль награды за слот
}
```

Стыковка с существующим `ResonanceDaily` (Date / Care / Temper):

- При reset дня: либо расширить `ResonanceDaily`, либо держать `DailyBoard` рядом и зеркалить Care/Temper из одних хуков.
- Рекомендация для lite B: **один** day-key path (`EnsureDailyBoard(playerData)`), Care/Temper пишут в оба поля до миграции UI.

## Reset

- Смена `DayKey` при первом действии / FullSync после полуночи UTC (или `os.date("!*t")` на сервере).
- При смене дня: слоты в false; если вчера был 4/4 → `BonusNextDay = true` на новый день; иначе false.
- После первого начисления ×2 в новом дне можно сбросить `BonusNextDay` или держать до конца дня (предпочтение: **весь бонусный день**, как CH «завтра ×2»).

## Out of scope (v1 / этот док)

- Weekly rule card / Tournament-of-Glory lite  
- Дневной hard-cap copper / «мешочек арены»  
- Clan / board of fame / dungeon weekly  
- Новые quest id 4xx только ради доски  
- Ротация текста слотов по дням недели  

## Путь к lite (scope B) — чеклист

Когда решите кодить (отдельная сессия):

1. **DataStore / normalize** — поле `DailyBoard` в [`DataStoreManager.lua`](studio/DataStoreManager.lua)
2. **Ensure + mark slots** — хуки рядом с Care/Temper в [`SpiritResonance.lua`](studio/SpiritResonance.lua); BattleWin в `EndBattle`; CatchOrChest в catch + chest open
3. **Награды / ×2** — [`SeasonLiveOps.lua`](studio/SeasonLiveOps.lua) читает `BonusNextDay`
4. **UI** — `RefreshActivityBar` в [`UIController.lua`](studio/UIController.lua): `N/4` + 4 маркера
5. **Smoke** — Care + Temper + win + catch/chest → 4/4 → на «след. день» (подмена DayKey) ×2 жетоны
6. Docs: зеркала studio + CHANGELOG Added (feature), этот файл → статус «Studio lite»

## Источник идеи

Чат 2026-07-27: разбор Card Heroes daily/weekly → предложения A–G для RoS; приоритет внедрения #1 = daily board 4–6 + бонус полного дня.
