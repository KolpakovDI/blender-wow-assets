# Daily Board — дизайн + Studio lite

Статус: **Studio lite** · 2026-07-28  
Вдохновение: Card Heroes daily «лист дня» / streak (урезано до 4)  
Связано: [`SPIRIT-RESONANCE-PLAN.md`](SPIRIT-RESONANCE-PLAN.md), [`ECONOMY-BALANCE.md`](ECONOMY-BALANCE.md), `SeasonLiveOps`

## Цель

Короткий ежедневный ритуал **5–10 мин**: закрыть 4 слота → soft-награда и бонус на завтра.  
Без боевого pay-to-win.

## UI

`ResonanceActivityBar` в `UIController`: `День N/4 · Уход · Закалка · Бой · Лут` (+ `· Бонус` если `BonusNextDay`).

## 4 слота

| Slot | Цель | Хук |
|------|------|-----|
| Care | Уход | `SpiritResonance.Care` → `MarkDailySlot` |
| Temper | Закалка | `SpiritResonance.Temper` → `MarkDailySlot` |
| BattleWin | Победа в бою | `GameManager` + `OnBattleWin` |
| CatchOrChest | Поимка **или** сундук | catch / `WorldLootService` |

## Награды

| Слот | Soft |
|------|------|
| Care / Temper | `MarkDailySlot` → `OnDailyCare` / `OnDailyTemper` × `TokenMult` (2 если BonusNextDay) |
| BattleWin | `OnBattleWin` (GameManager) × mult — не дублировать в Mark |
| CatchOrChest | `OnDailyBoardSlot` 1 token + 5 PassXP × mult |
| 4/4 → завтра | `BonusNextDay` на rollover `DayKey` |

Soft Care/Temper начисляются при **слоте дня** (`MarkDailySlot`), не при сдаче квестов 301/302.

## Данные

`playerData.DailyBoard` — см. `EnsureDailyBoard` / `MarkDailySlot` в `SpiritResonance`.

## Out of scope

Weekly rules, copper hard-cap, clan, quests 4xx, отдельная панель Мики/PASS.
