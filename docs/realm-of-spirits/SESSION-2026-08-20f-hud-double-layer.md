# SESSION 2026-08-20f — HUD double-layer fix

## Problem
Hotbar выглядел «задвоенным»: ghost «Поймать [E]», «Профиль», Exp «0 / 100» поверх Actions.

## Root causes
1. `UpdateTraps` писал в `catchButton.Text` при живом `ButtonLabel`
2. После package C ExpBar (`Y≈-98`) перекрывал Actions (`Y≈-88`)
3. `StyleActionButton` → `StylePanel` → два `UIStroke`
4. `NextStepChip` (`IgnoreGuiInset` + top 0.02) наложился на `ResonanceActivityBar` (тот же top band)
5. `NotificationFrame` / toast «Данные загружены!» на `Y=10` поверх activity bar

## Fix (Studio SoT)
- `CreateTextButton` + icon: `TextTransparency = 1`
- `UpdateTraps`: только `caption` → `ButtonLabel`; `Text=""` / TT=1
- ExpBar `Y=-152`, Actions `Y=-96`
- `WoWUITheme.StyleActionButton`: один gold stroke; clear Text when label exists
- `NextStepChip`: sync ScreenInsets/IgnoreGuiInset с `RealmOfSpiritsUI`; позиция под activity bar (+8px)
- Toast: `NotificationFrame` → `Y=88` (под activity+chip); ToastRouter fallback тот же; **серый бар убран** (`BackgroundTransparency=1`)

## Smoke (Client Play)
| Check | Result |
|-------|--------|
| `RealmOfSpiritsUI` count | 1 |
| Catch Text / TT / Lab | `""` / 1 / one label |
| Profile same | PASS |
| strokes on Catch/Profile | 1 |
| Exp→Actions gap | ~30px |
| NextStepChip vs ActivityBar | gap=8, overlap=false, same ScreenInsets |
| Toast vs ActivityBar/Chip | overlapBar=false, gapBelowChip=8 |

## Docs mirrors
`studio/UIController.lua`, `studio/WoWUITheme.lua`, `studio/NextStepChip.lua`
