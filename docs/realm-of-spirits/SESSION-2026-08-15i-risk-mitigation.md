# SESSION 2026-08-15i — Risk mitigation for year expansion C+A

## Goal

Купировать риски плана [`YEAR-PLAN-2026-10.md`](YEAR-PLAN-2026-10.md): монолит квестов, пустой ландшафт, ранний AI mesh / ProfileService / guilds / PvP creep.

## Done

| Risk | Mitigation |
|------|------------|
| QuestSystem monolith | Catalog-only + `validate_quest_catalog.py` in `quality_gate.py` |
| Luau `continue` | GetAvailableQuests → `if not Deprecated` |
| Orphan QuestLocations | Gate fails if location lacks VisitZone quest |
| Early Q3/Q4 | `ExpansionGate` defaults **all false** (RS ModuleScript) |
| ProfileService | Adapter gated; `ShouldUse()` false |
| AI mesh online | `SpiritMeshGenerationService` stub refuses |
| Guilds | CreateOrJoin **fail-closed** without gate unlock |
| PvP power | `WIN_COPPER=0` + `pvpExtraAllowed()` |
| Dead ScoutQuestor | `_G.RoS_OpenQuestUI` + WorldSpawner uses it |

Docs: [`RISKS-MITIGATION.md`](RISKS-MITIGATION.md)

## Studio smoke (Edit)

Gate all false; mesh blocked; quest 8 = «К хребту льда»; VisitZone set size 13; QuestSystem has RoS_OpenQuestUI, no `continue`.

## Owner

1. **Ctrl+S** SoT  
2. Play: quest 8 → FrostRidge VisitZone  
3. Do **not** set `Allow*` attrs until E1 / skip  

## Unlock later

SSS.RealmOfSpirits attrs: `AllowGuilds`, `AllowProfileService`, `AllowAiMeshOnline`, `AllowNewPvPFeatures` (+ chat `/expansiongate`).
