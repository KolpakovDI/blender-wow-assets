# SESSION 2026-08-19 — Studio sync (docs → SoT)

## Что сделано

- Синхронизированы ключевые модули Q3/E1 в открытый place через Studio MCP.
- `UIController` доведён до варианта с `TradePanelUI`:
  - добавлена кнопка `ShopButton`
  - подключён `TradePanelUI.Mount(...)`
  - `RefreshAfford`/refresh на `FullSync` и `TradeResult`
  - `BindZoneSilentRefresh(player)` вместо старого авто-open паттерна
- `UIController` перенесён из `StarterGui` в `StarterPlayer.StarterPlayerScripts`.
- Установлено `StarterGui.ResetPlayerGuiOnSpawn = false`.

## Проверка

- MCP Play smoke: PASS
  - `DuelWayfind` и `PvPDuelHostHaven` присутствуют
  - `resolveDuelSpiritInfo` в `PvPDuelSystem` присутствует
  - `SoftRespawnAtSpawn` в `GameManager` присутствует
  - `TradePanelUI` wired в `UIController`, `shopButton`/`RefreshAfford` присутствуют
  - `UIController` только в SPS, в StarterGui отсутствует

## Известное

- FEFF `user_RoS_ShortGrass` в Output остаётся внешним plugin noise (не place SoT).
- `QuestSystem` в place self-contained; отдельный `QuestCatalog` в place не внедрялся этим шагом.

## Следом

- Ручной hands-smoke в Play: магазин/кошелёк, soft-respawn без дубля HUD, дуэль из Haven.
- После ручной проверки — сохранить place (`Ctrl+S`).
