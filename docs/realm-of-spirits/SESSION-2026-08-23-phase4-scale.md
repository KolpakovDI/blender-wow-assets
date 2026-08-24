# SESSION — Phase 4 Scale (2026-08-23)

**Roadmap:** [`ROADMAP-2026-08-23.md`](ROADMAP-2026-08-23.md) · **Фаза 4** · 4–9 мес part-time  
**Place SoT:** `C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl` — **Ctrl+S** после Studio-правок  
**Unlock:** явная команда владельца «фаза 4» (2026-08-23) · `ExpansionGate` **остаётся locked** до owner W4 FlipChecklist

---

## Track choice (rationale)

| Трек | Зависимости | W1? |
|------|-------------|-----|
| **ProfileService prep** | Foundation для Guilds, rated PvP rank, scale DS | **ДА — W1** |
| Guilds MVP expand | Profile + roster persistence | W3+ (после schema lock) |
| Rated PvP seasons | `pvpExtraAllowed()` + rank in save | W5+ backlog |
| Online AI mesh | `AllowAiMeshOnline` + UI polish | **не в W1–W4** (отложено) |
| Haven décor phase 2 | — | **вне scope** |

**Выбор:** **ProfileService prep** — единственный трек без unlock Allow* на W1; не блокирует owner hands Ф3; зеркалит YEAR-PLAN Q4 порядок (ProfileService → guilds → mesh).

**Gate carry-over:** E1 formal n≥10 **или** owner skip (accepted) · live DS rejoin **CONDITIONAL** (Ф3 owner hands) · **не** flip `AllowProfileService` на W1.

---

## Scout summary (mirrors + Studio 2026-08-23)

| Компонент | Путь (Studio) | Состояние |
|-----------|---------------|-----------|
| `ExpansionGate` | `RS.RealmOfSpirits` | All Allow*=false defaults |
| `ProfileServiceAdapter` | `SSS.RealmOfSpirits` | Stub → **W1 audit API** |
| `DataStoreManager` | `SSS.RealmOfSpirits` | Live backend `RealmOfSpirits_v2` + session lock |
| `GuildSystem` | `SSS.RealmOfSpirits` | W10 deposit/withdraw prep; W9 UI+bank; W8 leave+merge; CreateOrJoin fail-closed |
| `SpiritMeshGenerationService` | `SSS.RealmOfSpirits` | Online path blocked |
| `PvPDuelSystem` | `SSS.RealmOfSpirits` | Fair duel OK; `pvpExtraAllowed()` for rated |

**Schema inventory (W1):** 42 top-level keys + optional `Guild`, `_Session` — см. `ProfileServiceAdapter.ExpectedTopLevelKeys`.

**Migration plan (read-only):**

1. **W1** — audit API + `ValidateDataShape` on `GetDefaultData` · gate locked  
2. **W2** — vendor ProfileService Roblox module; dual-read shadow (log diff, no write)  
3. **W3** — unpublished one-key migrate sample `Player_900000001` → `RealmOfSpirits_Profiles_v1` · **PASS**  
4. **W4** — Load/Save wired behind gates (**PREP PASS**); owner FlipChecklist + live rejoin → COMPLETE

---

## W1 — ProfileService scout + audit scaffold — **PASS (2026-08-23)**

**Scope:** read-only; **no** live migration; **no** Allow* flip.

| # | Задача | Статус |
|---|--------|--------|
| 1 | Scout stubs (PS / Guilds / PvP / mesh) | ☑ |
| 2 | Schema inventory 42 keys | ☑ `ProfileServiceAdapter.GetSchemaInventory` |
| 3 | `GetMigrationAudit()` + `ValidateDataShape` | ☑ |
| 4 | `DataStoreManager:GetPersistenceBackend` + init audit log | ☑ |
| 5 | Studio sync + Edit smoke | ☑ MCP multi_edit |
| 6 | `quality_gate.py` | ☑ (post-commit) |
| 7 | Docs: NEXT / ROADMAP / CHANGELOG | ☑ |

**MCP smoke (Edit):** `GetMigrationAudit` → `F4-W1-prep`, `liveBlocked=true`, `ShouldUse=false` · `ValidateDataShape(GetDefaultData)` → **PASS**.

**NOT in W1:** Allow* · ProfileService live Load/Save · Guilds expand · B1 · 106 · Haven décor.

---

## W2 — ProfileService vendor + shadow read — **PASS (2026-08-23)**

| # | Задача | Статус |
|---|--------|--------|
| 1 | Add ProfileService module to `SSS.RealmOfSpirits` (Roblox library 5331689994) | ☑ |
| 2 | `ProfileServiceAdapter` shadow: legacy GetAsync + `ValidateDataShape` log only | ☑ |
| 3 | `DataStoreManager:LoadData` → `ShadowAuditPlayer` defer (no PS write) | ☑ |
| 4 | Play smoke: `[Persistence]` + shadow line | ☑ |
| 5 | Rollback path in `GetMigrationAudit().Rollback` | ☑ |
| 6 | Studio sync + mirrors | ☑ |
| 7 | `quality_gate.py` | ☑ |
| 8 | Docs: NEXT / ROADMAP / CHANGELOG | ☑ |

**MCP smoke (Play, unpublished):**

```
[Persistence] backend=DataStoreManager liveBlocked=true gatePS=false schemaV=1 keys=42 shadow=true vendored=true phase=F4-W2-shadow
[ProfileServiceAdapter] shadow user=… vendored=true liveShape=true legacyRead=false legacyShape=false match=nil
```

(`legacyRead=false` expected unpublished — DS API off; live path unchanged.)

**Bugfix during W2:** `RS.ExpansionGate` Studio had `folder.GetAttribute` (dot) → `folder:GetAttribute` — init log was crashing before fix.

**Rollback (no Allow* flip):**

1. Delete `SSS.RealmOfSpirits.ProfileService` ModuleScript  
2. Set `ProfileServiceAdapter.ShadowReadEnabled = false` (Studio + mirror)  
3. Remove `ShadowAuditPlayer` defer from `DataStoreManager:LoadData` (optional; harmless when shadow off)  
4. **Ctrl+S** place — live remains `DataStoreManager`

**NOT in W2:** Allow* · ProfileService LoadProfileAsync/Save · Guilds · B1 · 106 · Haven décor

---

## W3 — Unpublished migrate sample — **PASS (2026-08-23)**

| # | Задача | Статус |
|---|--------|--------|
| 1 | Sentinel UserId `900000001` (NOT production) | ☑ |
| 2 | `MigrateSampleKey` one-way legacy → `RealmOfSpirits_Profiles_v1` (Mock target) | ☑ |
| 3 | `ValidateDataShape` + `ComputeDataChecksum` compare source/target | ☑ |
| 4 | Gate locked · no Allow* · live path = DataStoreManager | ☑ |
| 5 | MCP Edit + Play smoke | ☑ |
| 6 | Studio sync + mirror | ☑ |
| 7 | `quality_gate.py` | ☑ |
| 8 | Docs: NEXT / ROADMAP / CHANGELOG | ☑ |

**API (W3):** `MigrateSampleUserId=900000001` · `MigrateSampleEnabled=true` · `SeedMigrateSampleLegacy` · `MigrateSampleKey` · `ComputeDataChecksum` · phase `F4-W3-migrate`.

**MCP smoke (Edit, unpublished):**

```
GetMigrationAudit → phase=F4-W3-migrate, liveBlocked=true, ShouldUse=false, MigrateSampleUserId=900000001
ValidateDataShape(GetDefaultData) → PASS
MigrateSampleKey() → Success=true, SourceOrigin=synthetic_seed, ChecksumMatch=true, MockTarget=true
```

(`SourceOrigin=synthetic_seed` expected unpublished — legacy DS API off; mock ProfileService target used.)

**MCP smoke (Play, unpublished):**

```
[Persistence] backend=DataStoreManager liveBlocked=true gatePS=false schemaV=1 keys=42 shadow=true vendored=true phase=F4-W3-migrate
[ProfileServiceAdapter] shadow user=… vendored=true liveShape=true legacyRead=false …
MigrateSampleKey (Server) → Success=true, ChecksumMatch=true
```

**Rollback (no Allow* flip):**

1. Set `MigrateSampleEnabled=false` in `ProfileServiceAdapter` (Studio + mirror)
2. `ProfileStore.Mock:WipeProfileAsync("Player_900000001")` if re-smoking
3. W2 rollback still applies (remove PS module / `ShadowReadEnabled=false`)
4. **Ctrl+S** place — live remains `DataStoreManager`

**NOT in W3:** Allow* · ProfileService live Load/Save on join · production UserIds · Guilds · B1 · 106 · Haven décor

---

## W4 — Gate flip + live smoke — **PREP PASS CONDITIONAL (2026-08-23)**

**Scope:** implement Load/Save behind triple gate; **do not** flip Allow* / Enabled / UseProfileServiceAdapter.

| # | Задача | Статус |
|---|--------|--------|
| 1 | `LoadPlayerData` / `SavePlayerData` (ProfileService session) | ☑ gated by `ShouldUse()` |
| 2 | `DataStoreManager` Load/Save branch on `ShouldUse()` | ☑ defaults OFF = DSM path |
| 3 | `SmokeLoadSaveMock` (sentinel Mock Load→mutate→View) | ☑ PASS |
| 4 | Keep ExpansionGate / Enabled / Use* OFF | ☑ |
| 5 | MCP Edit + Play smoke (flags OFF) | ☑ |
| 6 | Studio sync + mirrors | ☑ |
| 7 | `quality_gate.py` | ☑ green |
| 8 | Docs: NEXT / ROADMAP / CHANGELOG | ☑ |

**API (W4 prep):** `LiveLoadSaveReady=true` · `SmokeLoadSaveMock` · `GetActiveProfile` / `ReleasePlayer` · phase `F4-W4-prep` · `OwnerFlipChecklist` in audit.

**Triple gate (`ShouldUse`):** `Enabled` ∧ `ExpansionGate.AllowProfileService` ∧ SSS `UseProfileServiceAdapter` — all still **false**.

**MCP smoke (Edit, unpublished PlaceId=0):**

```
GetMigrationAudit → phase=F4-W4-prep, liveBlocked=true, ShouldUse=false, LiveLoadSaveReady=true
ValidateDataShape(GetDefaultData) → PASS
SmokeLoadSaveMock() → Success=true, LevelAfter=42, ShapeOk=true
LoadPlayerData / SavePlayerData (gate OFF) → nil / false
```

**MCP smoke (Play, unpublished):**

```
[Persistence] backend=DataStoreManager liveBlocked=true gatePS=false … phase=F4-W4-prep
shadow join unchanged · memory DSM path
SmokeLoadSaveMock (Server) → Success=true
```

**Blocked (live cutover):** PlaceId=0 · **dev-only mode** (owner 2026-08-23) · Ф3 Publish + live DS rejoin **deferred** · **no** Allow* flip until owner unlock.

> **Dev-only constraint:** W4 prep code is complete and safe unpublished. Live cutover (Publish → rejoin → FlipChecklist) remains valid but is **not default next** — owner explicitly deferred publish while project is raw.

**OwnerFlipChecklist (live W4 COMPLETE — owner unlock dev-only first):**

1. Ctrl+S place SoT  
2. Publish (PlaceId≠0)  
3. Live rejoin verify legacy `DataStoreManager`  
4. SSS attr `AllowProfileService=true`  
5. `ProfileServiceAdapter.Enabled=true`  
6. SSS attr `UseProfileServiceAdapter=true`  
7. Play: `[Persistence] backend=ProfileServiceAdapter`  
8. Leave+rejoin on `RealmOfSpirits_Profiles_v1`

**Rollback (gates still OFF — prep only):**

1. Flip any accidental Allow*/Enabled/Use* back to false  
2. Live path returns to DataStoreManager immediately  
3. W2/W3 rollback still available  

**NOT in W4 prep:** Allow* unlock · live PS on join · Guilds · B1 · 106 · Haven décor

---

## Schema lock (post-W4 prep, dev-only) — **LOCKED v1 (2026-08-23)**

**Scope:** freeze player save shape for Guilds + rated PvP prep; **no** live migration until owner unlock.

| Item | Value |
|------|-------|
| `SchemaVersion` | **1** (bump only with explicit migration plan) |
| Required top-level keys | **42** — `ProfileServiceAdapter.ExpectedTopLevelKeys` |
| Optional keys | `Guild` (Id, Name, Tag, Role?) · `_Session` (ephemeral, stripped on save) |
| Validation | `ValidateDataShape` · `GetMigrationAudit` · `ComputeDataChecksum` |
| Live backend (dev-only) | `DataStoreManager` / `RealmOfSpirits_v2` |
| PS target (gated) | `RealmOfSpirits_Profiles_v1` behind `ShouldUse()` |

**Change policy:** new persisted fields → schema v2 + migrate sample + owner review. **Do not** add keys ad-hoc while v1 locked.

**Verify (unpublished):** `GetMigrationAudit().SchemaVersion == 1` · `ValidateDataShape(GetDefaultData())` → PASS.

---

## W5 — GuildSystem scout + prep — **PASS (dev-only, 2026-08-23)**

**Scope:** read-only inventory + `GetGuildAudit`; **no** `AllowGuilds` flip · **no** roster DS · **no** Publish.

| # | Задача | Статус |
|---|--------|--------|
| 1 | Scout thin stub (`/guild`, `GuildEvent`, `data.Guild`) | ☑ |
| 2 | Document gate deps (`AllowGuilds`, `AssertGuildsAllowed`) | ☑ |
| 3 | `GetGuildAudit()` read-only API (mirror) | ☑ |
| 4 | Link to schema lock (`Guild` optional key) | ☑ |
| 5 | Studio sync + MCP smoke | ☑ Edit: `GetGuildAudit` → Phase=F4-W5-guild-scout GateAllows=false |
| 6 | `quality_gate.py` | ☑ green |
| 7 | Docs: NEXT / ROADMAP / CHANGELOG | ☑ |

**Inventory (W5 scout):**

| Компонент | Состояние |
|-----------|-----------|
| `GuildSystem.CreateOrJoin` | Fail-closed · `ExpansionGate.AssertGuildsAllowed()` |
| Persisted shape | `data.Guild = { Id, Name, Tag [, Role] }` — optional in schema v1 |
| Runtime | In-memory `membership` + (W6) `guildsById` roster |
| Remote | `ReplicatedStorage.RealmOfSpirits.GuildEvent` |
| Studio chat | `/guild`, `/guildleave`, `/expansiongate` (Studio only) |

**W5 NOT in scope:** AllowGuilds flip · guild roster DataStore · bank/warfare · UI panel · B1 · 106 · Haven décor

---

## W6 — Guild MVP design + in-memory roster — **PASS (dev-only, 2026-08-23)**

**Scope:** persistence design doc-in-API + thin in-memory roster; **no** `AllowGuilds` flip · **no** guild DS · **no** Publish.

| # | Задача | Статус |
|---|--------|--------|
| 1 | `GetMvpDesign()` — player Guild vs future `RealmOfSpirits_Guilds_v1` | ☑ |
| 2 | In-memory `guildsById` + `GetRoster` / `GetGuildRecord` | ☑ |
| 3 | `CreateOrJoin` fills roster when gate allows; still fail-closed | ☑ |
| 4 | `SmokeGuildRosterMock` (sentinel members, gate OFF) | ☑ |
| 5 | Remote `GetRoster` action; `/guildleave` before `/guild` match | ☑ |
| 6 | Studio sync + MCP Edit smoke | ☑ |
| 7 | `quality_gate.py` | ☑ green |
| 8 | Docs: NEXT / ROADMAP / CHANGELOG | ☑ |

**MCP smoke (Edit, unpublished):**

```
GetGuildAudit → Phase=F4-W6-guild-mvp GateAllows=false AllowGuildsAttr=false
SmokeGuildRosterMock → Success=true RosterCount=2 RosterOk=true CreateOrJoinBlocked=true
GetMvpDesign → InMemoryOnly=true FutureStore=RealmOfSpirits_Guilds_v1
```

**Persistence plan (locked design, not live):**

1. Player optional `Guild {Id,Name,Tag,Role}` — no full roster in profile (schema v1)
2. Future DS `RealmOfSpirits_Guilds_v1` keyed by guild Id — owner unlock + AllowGuilds
3. Join = upsert roster + set player Guild; Leave = remove / dissolve if empty
4. W6 = memory only (`guildsById` + `membership`); server restart wipes

**W6 NOT in scope:** AllowGuilds · live guild DS · UI panel · bank/warfare · B1 · 106 · Haven décor

**Next after W6:** W7 join restore `data.Guild` → in-memory membership (still gate OFF = no create).

---

## W7 — Join restore `data.Guild` → in-memory — **PASS (dev-only, 2026-08-23)**

**Scope:** restore persisted `Guild` into session membership/roster; **no** `AllowGuilds` for restore; create stays fail-closed; **no** guild DS · **no** Publish.

| # | Задача | Статус |
|---|--------|--------|
| 1 | `RestoreMembershipFromGuildTable` / `RestoreFromPlayerData` (gate-independent) | ☑ |
| 2 | `GameManager` hook after `LoadData` | ☑ |
| 3 | `GuildSystem.Start` defer restore when data ready | ☑ |
| 4 | `SmokeJoinRestoreMock` (sentinel restore, create still blocked) | ☑ |
| 5 | Phase/audit → `F4-W7-guild-restore` | ☑ |
| 6 | Studio sync + MCP Edit smoke | ☑ |
| 7 | `quality_gate.py` | ☑ green |
| 8 | Docs: NEXT / ROADMAP / CHANGELOG | ☑ |

**Policy note:** restore is intentional **without** `AllowGuilds` so continuity testing works in-memory while `/guild` + `CreateOrJoin` remain gated.

**MCP smoke (Edit, unpublished):**

```
GetGuildAudit → Phase=F4-W7-guild-restore GateAllows=false AllowGuildsAttr=false RestoreRequires=false CreateRequires=true
SmokeGuildRosterMock → Success=true RosterCount=2 CreateOrJoinBlocked=true
SmokeJoinRestoreMock → Success=true Restored=true Role=Officer RosterCount=1 CreateOrJoinBlocked=true NoGuildRejected=true
GetMvpDesign → AllowGuildsRequiredForRestore=false AllowGuildsRequiredForCreate=true
```

**W7 NOT in scope:** AllowGuilds · live guild DS · UI panel · bank/warfare · B1 · 106 · Haven décor

**Next after W7:** W8 Leave persist + multi-player roster merge (still gate OFF = no create).

---

## W8 — Leave persist + multi-player roster merge — **PASS (dev-only, 2026-08-23)**

**Scope:** `/guildleave` + `Leave` clear `data.Guild` + membership; same guild Id restores merge roster; **no** `AllowGuilds` for leave/restore; create stays fail-closed; **no** guild DS · **no** Publish.

| # | Задача | Статус |
|---|--------|--------|
| 1 | `ClearGuildMembership` — gate-independent leave + `data.Guild = nil` | ☑ |
| 2 | `Leave(player)` wraps clear + attributes + remote | ☑ |
| 3 | `mergeGuildMetadata` — multi-player restore into shared `guildsById` | ☑ |
| 4 | `SmokeGuildLeaveMock` (sentinel leave, gate OFF) | ☑ |
| 5 | `SmokeRosterMergeMock` (two restores → roster=2) | ☑ |
| 6 | Phase/audit → `F4-W8-guild-leave-merge` | ☑ |
| 7 | Studio sync + MCP Edit smoke | ☑ |
| 8 | `quality_gate.py` | ☑ green |
| 9 | Docs: NEXT / ROADMAP / CHANGELOG | ☑ |

**Policy note:** Leave and restore remain **without** `AllowGuilds`; only `CreateOrJoin` / `/guild` require gate.

**MCP smoke (Edit, unpublished):**

```
GetGuildAudit → Phase=F4-W8-guild-leave-merge GateAllows=false LeaveRequiresAllowGuilds=false CreateRequiresAllowGuilds=true
SmokeGuildLeaveMock → Success=true DataGuildNil=true RosterCountAfter=0 CreateOrJoinBlocked=true
SmokeRosterMergeMock → Success=true RosterCount=2 SharedGuildCount=1 LeaderUserId=900000401 CreateOrJoinBlocked=true
SmokeJoinRestoreMock → Success=true (regression)
SmokeGuildRosterMock → Success=true (regression)
```

**W8 NOT in scope:** AllowGuilds · live guild DS · UI panel · bank/warfare · B1 · 106 · Haven décor

**Next after W8:** W9 guild UI panel / bank prep (still gate OFF = no create/live DS).

---

## W9 — Guild UI panel / bank prep — **PASS (dev-only, 2026-08-23)**

**Scope:** client GuildPanelUI + empty Locked bank shape on guild record; **no** `AllowGuilds` · **no** live bank DS · **no** Publish.

| # | Задача | Статус |
|---|--------|--------|
| 1 | Empty `Bank` on guild record + `GetBank` / `GetBankAudit` | ☑ |
| 2 | `GetPanelSnapshot` + remotes GetPanel / GetBank | ☑ |
| 3 | `GuildPanelUI` LocalScript (G / `/guildpanel`, fail-closed) | ☑ |
| 4 | `SmokeGuildBankMock` + `SmokeGuildPanelPrepMock` | ☑ |
| 5 | Phase/audit → `F4-W9-guild-ui-bank` | ☑ |
| 6 | Studio sync + MCP Edit smoke | ☑ |
| 7 | Docs: NEXT / ROADMAP / CHANGELOG | ☑ |
| 8 | `quality_gate.py` | ⚠ shell unavailable this turn — MCP smokes green |

**Policy note:** UI read + bank shape work with gate OFF; CreateOrJoin / bank writes remain fail-closed.

**MCP smoke (Edit, unpublished):**

```
GetGuildAudit → Phase=F4-W9-guild-ui-bank GateAllows=false
SmokeGuildBankMock → Success=true Copper=0 Locked=true CreateOrJoinBlocked=true
SmokeGuildPanelPrepMock → Success=true LockedOk=true MemberOk=true CreateOrJoinBlocked=true
W6–W8 regress → leave/merge/roster/restore Success=true
AllowGuilds=false · GuildPanelUI present
```

**W9 NOT in scope:** AllowGuilds · live guild DS · live deposit/withdraw · warfare · B1 · 106 · Haven décor · Publish

**Next after W9:** W10 bank deposit/withdraw prep **or** warfare stub (still gate OFF).

---

## W10 — Bank deposit/withdraw prep — **PASS (dev-only, 2026-08-24)**

**Scope:** live Deposit/Withdraw APIs fail-closed (`Locked`) until AllowGuilds; in-memory mutate via `SmokeBankDepositMock` for QA; **no** AllowGuilds · **no** live guild DS · **no** Publish.

| # | Задача | Статус |
|---|--------|--------|
| 1 | `DepositCopper` / `WithdrawCopper` — validate + fail-closed Locked | ☑ |
| 2 | In-memory `applyBankCopperDelta` for smoke QA only | ☑ |
| 3 | Remotes `Deposit` / `Withdraw` + `GetBank` WriteLocked / panel `BankWriteLocked` | ☑ |
| 4 | `SmokeBankDepositMock` (live blocked + copper 500→300) | ☑ |
| 5 | Phase/audit → `F4-W10-guild-bank-write` | ☑ |
| 6 | `GuildPanelUI` WRITE LOCKED label + Error handler | ☑ |
| 7 | Studio sync + MCP Edit smoke | ☑ |
| 8 | Docs: NEXT / ROADMAP / CHANGELOG | ☑ |
| 9 | `quality_gate.py` | ☑ green |

**Policy choice (documented):** live path = **fail-closed Locked** (`!AllowGuilds` ∨ `bank.Locked`); QA = `SmokeBankDepositMock` mutates in-memory copper without unlocking live remotes.

**MCP smoke (Edit, unpublished):**

```
GetGuildAudit → Phase=F4-W10-guild-bank-write GateAllows=false
SmokeBankDepositMock → Success=true LiveDepositBlocked=true LiveWithdrawBlocked=true CopperAfter=300 WriteLocked=true
W6–W9 regress → roster/restore/leave/merge/bank/panel Success=true
AllowGuilds=false · DepositWithdrawPrep=true · LiveBankWrites=false
```

**W10 NOT in scope:** AllowGuilds · live guild DS · unlock Bank.Locked · warfare · B1 · 106 · Haven décor · Publish

**Next after W10:** W11 warfare stub **or** item bank slots (still gate OFF).

---

## Owner unlock (when critical — NOT default under dev-only)

| # | Действие |
|---|----------|
| 0 | Owner: **lift dev-only** explicit command |
| 1 | **Ctrl+S** place после Studio-правок |
| 2 | DevProduct → Publish → live Robux |
| 3 | Live DS rejoin |
| 4 | W4 OwnerFlipChecklist — **не** включать Allow* без plan |

---

## Explicit NOT in scope

Allow* unlock · ProfileService live · live Guild DS · AI mesh online · Haven décor · B1 PvP slice 3 · track 106
