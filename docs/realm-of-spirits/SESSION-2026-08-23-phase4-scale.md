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
| `GuildSystem` | `SSS.RealmOfSpirits` | W6 in-memory roster + fail-closed CreateOrJoin |
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
