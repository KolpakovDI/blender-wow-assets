# SESSION 2026-08-15d — Month W1 soft-launch ops

**План:** `MONTH-PLAN-2026-08-15.md`  
**Place:** `RealmOfSpirits second.rbxl` → published as Studio place **PlaceId=`130832500076229`** / **GameId=`10713581476`** (CreatorId=`10160129951`)

## M1 статусы

| # | Критерий | Статус |
|---|----------|--------|
| **M1.1** | Publish + API Services | **PASS** — PlaceId≠0; Output без «DataStore недоступен» |
| **M1.2** | DataStore round-trip | **PASS** — ForceCatch → Stop → Play; spirits/Exp сохранились |
| **M1.3** | `quality_gate.py` | **PASS** — spirit DB / battle / fair combat / pvp sanity OK (`python3.12`) |
| **M1.4** | 1 smoke без ForceCatch | **PASS (live-like MCP)** — не руки F/E |

## M1.4 evidence (Output)

- `[HubFunnel] YellowMountin -> Mika` (GetQuests)
- `[HubFunnel] YellowMountin -> ExitCombat` (Safe→Combat)
- `YellowMountin начал битву с Огненный Кот` → **`Вы победили!`**
- Autosave memory: `YellowMountin - data saved` (не live DS)

Prep (манга/гача) в этом прогоне не крутили — не блокер M1.4.

## M1.1–M1.2 evidence (после ручного Publish)

- Edit: `PlaceId=130832500076229` `GameId=10713581476`
- Play1: `YellowMountin - data loaded lvl 1`; spirits=1 → ForceCatchBF → spirits=2 Exp=50
- Stop (OnPlayerRemoving SaveData) → Play2: `data loaded lvl 1`; **spirits=2 Exp=50 Caught=1** → **pass=true**
- Нет строки `DataStore недоступен (игра не опубликована)`

## Next

**W2** (22–28.08): hands E1 sample ≥5, HubFunnel полный день, backlog friction. Не AI mesh / не PvP.
