# SESSION — Post-W18 regression smoke (2026-08-27)

**Mode:** **DEV-ONLY** · PlaceId=0 · all Allow*=false · owner unlock **PAUSED**  
**Place SoT:** `C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl`  
**Trigger:** default «дальше» per updated policy (regression smoke + fix-only, no Publish)

---

## Regression matrix

| # | Suite / check | Mode | Result | Notes |
|---|---------------|------|--------|-------|
| 1 | `PS_ValidateDataShape` | Edit | **PASS** | schema v1 · 42 keys |
| 2 | `PS_GetMigrationAudit` | Edit | **PASS** | phase=F4-W4-prep · LiveBlocked=true · ShouldUse=false |
| 3 | `PS_SmokeLoadSaveMock` | Edit + Server | **PASS** | Mock Load→mutate→View |
| 4 | `SmokeWrapMock` | Edit + Server | **PASS** | ChecklistCount=7 · Phase=F4-W18-wrap · GateAllows=false |
| 5 | `SmokeRatedPvPMock` | Edit | **PASS** | LiveDeclare/Match Locked |
| 6 | `SmokeLadderMock` | Edit | **PASS** | LiveRankBlocked · LadderCount≥3 |
| 7 | `SmokeMatchmakingMock` | Edit | **PASS** | Queue/party Locked |
| 8 | `SmokeSeasonMock` | Edit | **PASS** | LiveSeasonBlocked · S0-dev |
| 9 | `SmokeGuildRosterMock` | Edit | **PASS** | W6 sentinel roster |
| 10 | `SmokeJoinRestoreMock` | Edit | **PASS** | W7 restore |
| 11 | `SmokeGuildLeaveMock` | Edit | **PASS** | W8 leave |
| 12 | `SmokeRosterMergeMock` | Edit | **PASS** | W8 merge |
| 13 | `SmokeGuildBankMock` | Edit | **PASS** | W9 bank read |
| 14 | `SmokeGuildPanelPrepMock` | Edit | **PASS** | W9 panel prep |
| 15 | `SmokeBankDepositMock` | Edit | **PASS** | W10 copper |
| 16 | `SmokeBankItemSlotsMock` | Edit | **PASS** | W11 item slots |
| 17 | `SmokeWarfareMock` | Edit + Server | **PASS** | W12 warfare stub |
| 18 | `SmokeInventoryBankTransferMock` | Edit | **PASS** | W13 inv↔bank |
| 19 | `ExpansionGate` all Allow*=false | Edit | **PASS** | ProfileService · Guilds · NewPvPFeatures OFF |
| 20 | `[Persistence]` log | Play/Server | **PASS** | backend=DataStoreManager liveBlocked=true gatePS=false phase=F4-W4-prep |
| 21 | `[ProfileServiceAdapter] shadow` | Play/Server | **PASS** | vendored=true liveShape=true |
| 22 | HubFunnel Spawn → MikaOpen | Play | **PASS** | `[HubFunnel] YellowMountin -> Spawn` then `-> Mika (MikaOpen)` |
| 23 | Key systems load | Play/Output | **PASS** | GameManager · QuestSystem · ZoneSystem · RatedPvP · GuildPanelUI · KamiSanctum |
| 24 | `quality_gate.py` | repo | **PASS** | all 5 validators green (2026-08-27 session) |
| 25 | Core loop E2E (Mika→Exit→battle→Haven→Sanctum) | Play | **CONDITIONAL** | MCP live-like — см. § E2E matrix ниже; hands gaps остаются |
| 26 | `user_RoS_ShortGrass.server.lua` BOM | Play/Output | **WARN** | U+feff parse error ×6 — decorative grass, non-P0 |

**Edit summary:** 18/18 Smoke*Mock + audits **PASS** (GateAllows=false throughout).  
**Play summary:** persistence + HubFunnel Spawn/Mika **PASS** · MCP E2E **CONDITIONAL** (battle+return+SeedQA; Prep/Complete/hands path not closed).  
**Fixes applied:** none (no P0 red smoke; BOM grass = backlog noise, not fix-only scope).

---

## E2E matrix (MCP Play 2026-08-27 evening)

| Step | MCP automatable? | Result | Evidence / notes |
|------|------------------|--------|------------------|
| Play Local Server start | ☑ | **PASS** | `start_stop_play` · Client+Server datamodels |
| HubFunnel Spawn log | ☑ (auto) | **PASS** | `[HubFunnel] … -> Spawn (Spawn)` |
| HubFunnel MikaOpen attr | ☑ (auto) | **PASS** | `-> Mika (MikaOpen)` on data load |
| HubFunnel Prep (PrepShop) | ☐ gameplay / BF copy | **NOT CONFIRMED** | `RequestWardrobe` remote — no `[KR3 prep step]` log; BF `Mark(Prep)` via MCP не персистит в live data |
| Exit touch → Combat | ☐ partial | **CONDITIONAL** | `character_navigation` to Exit **timeout**; **server TP** to `Akihabara.CombatZone` → `CurrentZone=Combat` · `ExitTouch` log |
| HubFunnel ExitCombat / Complete | ☐ partial | **CONDITIONAL** | `ExitCombat=true` · `Complete=false` (Prep missing) |
| Battle entry (Orchestrator) | ☑ remotes | **PASS** | `ForceCatchBF(11)` + `Battle:FireServer("Start")` + `Attack` SkillIndex 1 · console: `начал битву с Огненный Кот` |
| Battle outcome / ability slot | ☑ remotes | **CONDITIONAL** | Battle ended `BattleEnd=Enemy` (loss after death respawn); SkillIndex 1 fired — HUD slots **not** eye-verified |
| Return Haven (Safe/Spawn) | ☑ server TP | **PASS** | TP `OtakuHaven.Zones.SpawnZone` → `CurrentZone=Safe` `ZoneDetail=Safe` |
| Kami Sanctum SeedQA | ☑ `KamiSanctumBF` | **PASS** | Lv10 · copper=250 |
| Kami Sanctum Open UI | ☐ remote only | **CONDITIONAL** | `KamiSanctum:FireServer("Open")` — no server error; roster `[R]` **not** eye-verified |
| Full quest→catch→turn-in (no QA BF) | ☐ | **NOT RUN** | Requires hands E/catch or explicit smoke script |

### MCP could vs could not

| MCP **could** | MCP **could not** (owner hands) |
|---------------|----------------------------------|
| Start/stop Play · console capture | Пешком Мика → Exit door **E** (navigation unreliable / timeout) |
| Read HubFunnel attrs + logs | Prep через manga buff **E** у стенда (gameplay proximity) |
| Server TP to CombatZone / Haven Spawn | Честный бой **F / 1 / 2** глазами (V/Keypad/remotes = live-like only) |
| `ForceCatchBF` · `Battle:FireServer` remotes | Full loop catch без `ForceCatchBF` |
| `KamiSanctumBF` SeedQA · Open remote | Sanctum `[R]` roster visual confirm |
| `GetHubFunnelSnapshotBF` audit | HubFunnel **Complete** day (needs Prep gameplay) |

### Owner hands gaps (blocked for readiness #2/#5 PASS)

1. Haven: **E** у manga buff или wardrobe → `[HubFunnel] … Prep (PrepShop)` / `HubFunnelPrep=true`
2. Haven: пешком или **E** Exit door → Combat (не server TP)
3. Combat: бой **F/1/2** до победы (или подтвердить ability slots на HUD)
4. (Опц.) quest accept → catch **E** → turn-in у Мики без QA BF
5. Sanctum: **E** shrine → Open → `[R]` roster spot-check

---

## Readiness re-assessment (7 criteria)

| # | Критерий | Было (2026-08-27 pre-smoke) | Стало (post-smoke) |
|---|----------|----------------------------|---------------------|
| 1 | Numbered track F4 W1–W18 | ☑ PASS | ☑ PASS |
| 2 | Post-W18 regression | ☐ не подтверждено | ☑ Smoke*Mock **PASS** · ☑ MCP E2E **CONDITIONAL** (battle+return; Prep/Complete/hands not closed) |
| 3 | `quality_gate.py` | ☑ (W18 exit) | ☑ **PASS** (this session) |
| 4 | P0 regressions | ☐ не re-smoke | ☑ **PASS** — no DoNotSave/load fail/E2E blocker · ShortGrass BOM = non-P0 warn |
| 5 | Core loop stable | ☑ pre-W18 · ☐ post-W18 | ☑ Spawn+Mika+Combat+battle load · ☐ Prep+Complete+hands quest/catch → **CONDITIONAL** |
| 6 | Polish threshold | ☐ CONDITIONAL | ☐ CONDITIONAL — E1 n≥10 empty · side 106/B1 open (not soft-launch blockers) |
| 7 | Live prep audit | ☑ prep PASS | ☑ PASS · live cutover not started |

**Verdict: NOT READY** — criteria 2, 5, 6 not all PASS. Agent **does not** suggest Publish / owner unlock.

---

## Recommended next command

| Priority | Command | Why |
|----------|---------|-----|
| **1** | «hands E2E» / owner checklist § gaps | Close Prep+Complete + F/1/2 win + (опц.) catch/turn-in — readiness #2/#5 |
| 2 | «106» / «B1» / «Haven décor» | Named backlog — explicit only |
| 3 | «owner unlock» / «проект готов» | Override readiness gate — owner decides |

---

## Journal

| Time | Action | Result |
|------|--------|--------|
| 2026-08-27 PM | MCP Edit: full Smoke*Mock suite (W6–W18 + PS audits) | 18/18 PASS |
| 2026-08-27 PM | MCP Play: persistence + HubFunnel + Server smokes | PASS (partial E2E) |
| 2026-08-27 PM | `python3.12.exe scripts/quality_gate.py` | green |
| 2026-08-27 PM | Docs: NEXT-SESSION readiness update | NOT READY maintained |
| 2026-08-27 evening | MCP Play E2E live-like (battle remotes + Haven return + SeedQA) | **CONDITIONAL** — see § E2E matrix |
