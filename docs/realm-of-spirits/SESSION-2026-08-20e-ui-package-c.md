# SESSION 2026-08-20e — UI пакет C

## Intent
Очередь после B: mobile safe area, CD fill, dim Catch.

## Done
- `RealmOfSpiritsUI.ScreenInsets = DeviceSafeInsets`
- ActionsFrame `Y=-88` H=54; buttons H=44; BattleFrame `Y=-188` H=178
- Skill buttons: `CdFill` overlay (remaining/MaxCooldown); text CD/MP kept
- Catch dim (`Transparency 0.35`) when traps > 0 but `CatchUiActive` false

## Smoke (Client)
| Check | Result |
|-------|--------|
| actionsY / battleY | -88 / -188 |
| catchH / catchTrans | 44 / ~0.35 |
| ScreenInsets | DeviceSafeInsets |
| Source CdFill | yes |

## Ctrl+S
Сохранить place.

## Next queue
UI пакет **D** (grid сумок) — отдельный спринт; или wrap недели / Identity.
