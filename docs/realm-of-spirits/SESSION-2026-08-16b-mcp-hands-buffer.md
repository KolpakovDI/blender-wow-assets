# SESSION 2026-08-16b — MCP hands buffer (post–locals fix)

**Тип:** live-like MCP buffer — **не** честный hands E1 (WASD/F/1/2/E глазами).  
**Gate:** ExpansionGate locked (Edit verify PASS).  
**Контекст:** после hotfix `TradePanelUI` / UIController locals (`SESSION-2026-08-16-uicontroller-locals.md`).

## Checklist

| # | Шаг | Статус |
|---|-----|--------|
| 1 | ExpansionGate Allow*=false | **PASS** |
| 2 | HubFunnel Mika+Prep+ExitCombat → Complete (`DayKey=2026-08-16`) | **PASS** (via `GetPlayerDataBF` + `HubFunnel.Mark`) |
| 3 | Бой V + Keypad1/2 vs Огненный Кот → победа | **PASS** (console: «начал битву…» / «Вы победили!») |
| 4 | VisitZone ScoutPost (`ZoneDetail=ScoutPost`) | **PASS** |
| 5 | Client UI frames TradeFrame + BattleLogScroll after locals fix | **PASS** |

## Оговорки

- TP + VirtualInput (V/Keypad), не руки. E1 n≥10 глазами — **ещё открыт**.
- `_G.GetPlayerData` недоступен из MCP `execute_luau` Server — использовать `GetPlayerDataBF`.
- Шум: FEFF `user_RoS_ShortGrass` ignore.

## Next

Честный E1 глазами **или** лёгкий Q2. **Не** Allow* / mesh / ProfileService.
