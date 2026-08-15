# Realm of Spirits — Year Plan (2026-10 → 2027-09)

**Выбор:** 12‑мес expansion **C+A** (полный бывший out-of-scope; квесты first).  
**Якорь slice:** [`QUEST-BALANCE.md`](QUEST-BALANCE.md)

```mermaid
flowchart LR
  Q1[Q1_Quests]
  Q2[Q2_Landscape]
  Q3[Q3_PvP_Haven]
  Q4[Q4_Mesh_Profile]
  Q1 --> Q2 --> Q3 --> Q4
```

| Q | Окно | Фокус | Exit |
|---|------|--------|------|
| **Q1** | мес 1–3 | QuestCatalog, баланс, ZoneHint, +exploration квесты | Catalog live; ≥6 новых квестов |
| **Q2** | мес 4–6 | Ландшафт + QuestLocations | +4–6 локаций с квестами |
| **Q3** | мес 7–9 | PvP fair + Haven décor | playable duel slice |
| **Q4** | мес 10–12 | AI mesh, ProfileService, guilds | live или CONDITIONAL |

**Gate:** PvP/mesh/ProfileService не раньше hands E1 ≥90% n≥10 **или** явный skip владельца.

## Риски → купирование

См. [`RISKS-MITIGATION.md`](RISKS-MITIGATION.md). Кратко:

1. **Монолит квестов** → только `QuestCatalog` + CI `validate_quest_catalog.py`  
2. **Пустой ландшафт** → orphan `QuestLocations` = fail gate  
3. **Ранний mesh/ProfileService/guilds** → `ExpansionGate` defaults false + stub services refuse  

Связь: soft-launch wrap `SESSION-2026-08-15g-month-w4-wrap.md` · SoT `RealmOfSpirits second.rbxl`.
