# SESSION 2026-08-15d — Month W1 soft-launch ops

**План:** `MONTH-PLAN-2026-08-15.md`  
**Place:** `RealmOfSpirits second.rbxl` — **PlaceId=0 / GameId=0** (локальный файл, не published)

## M1 статусы

| # | Критерий | Статус |
|---|----------|--------|
| **M1.1** | Publish + API Services | **BLOCKED** — PlaceId=0; нужен ручной Publish в Creator / Studio File→Publish |
| **M1.2** | DataStore round-trip | **BLOCKED** (зависит от M1.1). Output: `DataStore недоступен (игра не опубликована)` — только memory |
| **M1.3** | `quality_gate.py` | **PASS** — spirit DB / battle / fair combat / pvp sanity OK (`python3.12`) |
| **M1.4** | 1 smoke без ForceCatch | **PASS (live-like MCP)** — не руки F/E |

## M1.4 evidence (Output)

- `[HubFunnel] YellowMountin -> Mika` (GetQuests)
- `[HubFunnel] YellowMountin -> ExitCombat` (Safe→Combat)
- `YellowMountin начал битву с Огненный Кот` → **`Вы победили!`**
- Autosave memory: `YellowMountin - data saved` (не live DS)

Prep (манга/гача) в этом прогоне не крутили — не блокер M1.4.

## Publish checklist (ты)

1. Studio: **File → Publish to Roblox** (или Create experience) для SoT  
2. **Game Settings → Security → Enable Studio Access to API Services**  
3. Play (или Local Server) → изменить данные → Stop → Play снова → проверить spirits/level  
4. В Output **не** должно быть «DataStore недоступен»

## Next

Закрыть **M1.1–M1.2** publish руками → затем W2 hands sample ≥5.
