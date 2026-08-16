# SESSION 2026-08-16 — UIController locals fix

**Тип:** P0 hotfix (Luau 200 locals)  
**Gate:** ExpansionGate locked (verified Edit)

## Проблема

Play console:
`Players.…PlayerGui.UIController:… Out of local registers when trying to allocate HandleShopZoneActivation: exceeded limit 200`

UIController не грузился после marathon UI polish.

## Fix

- Новый `ReplicatedStorage.RealmOfSpirits.TradePanelUI` (магазин/продажа/скролл)
- `StarterGui.UIController` — require + thin wrappers; без inline `tradeFrame`

## Smoke

| Check | Status |
|-------|--------|
| Console `UI Controller загружен!` | **PASS** |
| Client TradeFrame + BattleLogScroll + DexPanel | **PASS** |
| ShortGrass FEFF | noise (ignore) |

## Next

Честный E1 глазами (F/E/1/2) **или** MCP live-like буфер снова. **Не** Allow*.
