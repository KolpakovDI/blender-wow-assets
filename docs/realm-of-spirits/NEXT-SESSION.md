# NEXT SESSION

**Статус:** UI/combat polish checkpoint (2026-07-18) · Explore C funnel 101 ещё на play-подтверждении.

Дата якоря: 2026-07-18

## Цели (locked)

См. [`GOALS.md`](./GOALS.md) и GDD §9.

| Done | P0 Core + P0 Hub + **P1 Identity** + Explore A/B · UI: traps/dragon/damage/tracker |
| Now | **P1 Explore C** — сдать side **101**, закрыть gate Explore |
| Later | Social → P2 Scale по gate |

## Старт сессии (порядок жёсткий)

1. **Ctrl+S** place: `RealmOfSpirits second.rbxl` (если не сохраняли после 2026-07-18)
2. Play → Мика → **Доступные**: **«Помощь торговцу»** (101) → Accept
3. Проверить трекер под миникартой: название, `!` / счётчик кристаллов
4. Combat → **5× огненный кристалл** → трекер `?` → сдать у Мики
5. PASS → отметить Explore C в GOALS + CHANGELOG; иначе фиксить CollectItem
6. После gate Explore: **P1 Social** — не раньше

## Исправлено / проверено 2026-07-18

- Ловушки: catch disabled + «НЕТ ЛОВУШКИ» по центру 1.5с
- Дракон (Id 4): Walk, спавн CombatZone `(88,52)`, посадка на землю (~y=2.8)
- Бой: floating damage (белые / кроваво-красные)
- UI: духи слева снизу; зум миникарты Q1/Q4; `QuestTrackerHud` под картой
- Аудит Play: UIController/Client/GM грузятся без ошибок; quality_gate OK
- Hardening: zoom BtnGlow `Active=false`; tracker OpenQuestUI→Active; catch nil-guard

## Studio SoT

Place: `C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl` — **не в git**; после правок **Ctrl+S**.

| Module | Path |
|--------|------|
| QuestTrackerHud | `ReplicatedStorage.RealmOfSpirits.QuestTrackerHud` |
| UIFeedback | `ReplicatedStorage.RealmOfSpirits.UIFeedback` |
| ZoneConfig | `ReplicatedStorage.RealmOfSpirits.ZoneConfig` |
| UIController | `StarterGui.UIController` |
| ClientController | `StarterPlayer.StarterPlayerScripts.ClientController` |
| GameManager | `ServerScriptService.RealmOfSpirits.GameManager` |
| SpiritAnimation | `ServerScriptService.RealmOfSpirits.SpiritAnimation` |
| SpiritDatabase | `ReplicatedStorage.RealmOfSpirits.SpiritDatabase` |
| QuestSystem | `ServerScriptService.RealmOfSpirits.QuestSystem` |
