# NEXT SESSION

> **DEV-ONLY MODE** (owner decision 2026-08-23) — **не публикуем** place и **не включаем** live cutover, пока владелец явно не снимет режим. Проект сырой; публикация отложена **намеренно**, не навсегда.

**Статус:** 2026-08-27 — Фаза 1 **COMPLETE** · Фаза 2 **COMPLETE** · Фаза 3 **COMPLETE CONDITIONAL** · **Фаза 4 W1–W18 PASS** (W4 PREP CONDITIONAL) · numbered track **CLOSED**
**Следующий фокус (dev-only default):** **post-W18** — owner unlock **или** named backlog (не invent W19) — без Publish / Allow* flip

**Roadmap:** [`ROADMAP-2026-08-23.md`](ROADMAP-2026-08-23.md) · **Phase 4:** [`SESSION-2026-08-23-phase4-scale.md`](SESSION-2026-08-23-phase4-scale.md)

## План Ф4 W14–W18 — DONE

| Нед | Название | Статус |
|-----|----------|--------|
| **W14** | Rated PvP prep | ☑ PASS — SmokeRatedPvPMock |
| **W15** | Rank / ladder stub | ☑ PASS — SmokeLadderMock + RatedPvPPanelUI |
| **W16** | Matchmaking stub | ☑ PASS — SmokeMatchmakingMock |
| **W17** | Season / meta stub | ☑ PASS — SmokeSeasonMock |
| **W18** | Numbered-track wrap | ☑ PASS — SmokeWrapMock |

**Gate:** `AllowNewPvPFeatures=false`. Live APIs Locked; QA = Smoke*Mock only.

## Dev-only policy

| Допустимо сейчас | Отложено (не заблокировано навсегда) |
|------------------|--------------------------------------|
| Studio Edit + Play (unpublished, PlaceId=0) | **Publish** place (PlaceId≠0) |
| Studio MCP smoke / multi_edit | Live **DataStore rejoin** под нагрузкой |
| Mock / shadow **ProfileService** (gate OFF) | Live **Robux** purchase (DevProduct + Publish) |
| `quality_gate.py`, git mirrors, docs | **`AllowProfileService`** flip + live PS cutover |
| Bug fix-only по красному smoke | **`AllowGuilds` / `AllowNewPvPFeatures`** flip |
| Ф4 prep complete through W18 | Live ops / store listing / marketing pass |

**Снять dev-only:** только явная команда владельца («publish», «owner hands», «live cutover») + [`OwnerFlipChecklist`](SESSION-2026-08-23-phase4-scale.md) в SESSION W4.

## Старт сессии (порядок жёсткий)

1. **Ctrl+S** place → подтвердить SoT
2. **Приоритет по умолчанию (dev-only):** **post-W18** — owner unlock **или** named backlog
3. **Bug fix-only** — если что-то красное в play smoke
4. **Owner hands / Publish / live cutover** — только по **явной** команде владельца (не default)
5. **106 / B1 / Haven décor** — только по явной команде

## Выбор владельца (что значит «дальше»)

| Команда / намерение | Действие агента |
|---------------------|-----------------|
| «дальше» (без уточнения) | **Post-W18:** спросить/выбрать owner unlock **или** named backlog (не invent W19) |
| «W14»–«W18» / rated / ladder / MM / season / wrap | already **PASS** — re-smoke if needed |
| «W13» / «inventory» / «transfer» | SESSION W13 · already **PASS** |
| Owner hands / Publish / live DS | Чеклист § Owner unlock · **только явная команда** |
| «Ф4 W4 cutover» / «AllowProfileService» | OwnerFlipChecklist · live smoke · **owner unlock dev-only** |
| «106» / «B1» / «Haven décor» / «mesh» | Named backlog · не default |

## Где остановились

| Область | Состояние |
|---------|-----------|
| **Dev-only** | **ACTIVE** — Publish/live cutover deferred by owner |
| **Фаза 4 W14–W18** | **PASS** — RatedPvPSystem + PanelUI; all Smoke*Mock green; Phase `F4-W18-wrap` |
| **Фаза 4 W13** | **PASS** — Transfer* Locked; SmokeInventoryBankTransferMock |
| **Фаза 4 W4** | **PREP PASS CONDITIONAL** — Load/Save wired, gates OFF, PlaceId=0 |
| **ExpansionGate** | All Allow*=false (не трогали) |
| **Schema** | **v1 locked** |

## Фаза 4 W18 exit (2026-08-27) — PASS (dev-only)

- `GetWrapAudit` / `SmokeWrapMock` — checklist 7 · backlog map · GateAllows=false
- Regress: SmokeRated / Ladder / Matchmaking / Season all Success=true
- `quality_gate.py` green
- **NOT:** Allow* · Publish · live rated / guild DS / PS cutover

## Backlog (named tracks — post-W18)

| # | Срез | Когда |
|---|------|-------|
| **Owner unlock** | Publish + live DS + FlipChecklist | явная команда |
| **Live Guild DS** | AllowGuilds + `RealmOfSpirits_Guilds_v1` | owner unlock |
| **PS cutover** | W4 live FlipChecklist | owner unlock |
| **B1** | PvP slice 3 | явная команда |
| **Online AI mesh** | AllowAiMeshOnline | явная команда |
| **Haven décor p2** | polish | явная команда |
| **Ф4 W14–W18** | Rated PvP track | ☑ **PASS** |
| **Ф4 W13** | Inventory↔bank transfer | ☑ **PASS** |

## Studio SoT

`C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl`

**Mirror (F4):** `ProfileService` · `ProfileServiceAdapter` · `DataStoreManager` · `ExpansionGate` · `GuildSystem` · `GuildPanelUI` · `RatedPvPSystem` · `RatedPvPPanelUI` · `GameManager` · `SpiritMeshGenerationService`

## Не включать (dev-only + gates)

Publish без owner · Allow* flip без checklist · live Guild DS · AI mesh online · Haven décor · B1 · 106 · два major track · silent W19

## Архив

Phase 1–2 **COMPLETE** · Phase 3 **COMPLETE CONDITIONAL** · Phase 4 W1–W18 **PASS** (W4 prep CONDITIONAL) · [`SESSION-2026-08-23-phase4-scale.md`](SESSION-2026-08-23-phase4-scale.md)
