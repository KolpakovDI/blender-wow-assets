# SESSION — Phase 4 Scale (2026-08-23)

**Roadmap:** [`ROADMAP-2026-08-23.md`](ROADMAP-2026-08-23.md) · **Фаза 4** · 4–9 мес part-time  
**Place SoT:** `C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl` — **Ctrl+S** после Studio-правок  
**Unlock:** явная команда владельца «фаза 4» (2026-08-23) · `ExpansionGate` **остаётся locked** до W4+owner

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
| `GuildSystem` | `SSS.RealmOfSpirits` | Thin `/guild` fail-closed |
| `SpiritMeshGenerationService` | `SSS.RealmOfSpirits` | Online path blocked |
| `PvPDuelSystem` | `SSS.RealmOfSpirits` | Fair duel OK; `pvpExtraAllowed()` for rated |

**Schema inventory (W1):** 42 top-level keys + optional `Guild`, `_Session` — см. `ProfileServiceAdapter.ExpectedTopLevelKeys`.

**Migration plan (read-only):**

1. **W1** — audit API + `ValidateDataShape` on `GetDefaultData` · gate locked  
2. **W2** — vendor ProfileService Roblox module; dual-read shadow (log diff, no write)  
3. **W3** — unpublished one-key migrate sample `Player_*` → `RealmOfSpirits_Profiles_v1`  
4. **W4** — owner: `AllowProfileService` + `UseProfileServiceAdapter` + live rejoin smoke · **then** cutover

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

## W3 — Unpublished migrate sample (planned)

One test UserId in Studio unpublished; compare checksum; no production keys.

---

## W4 — Gate flip + live smoke (planned, owner)

Requires: Ф3 owner hands (Publish + live DS) **recommended** · explicit `AllowProfileService=true` · `UseProfileServiceAdapter=true` · `Enabled=true` in adapter.

---

## Owner hands (unchanged from Ф3)

| # | Действие |
|---|----------|
| 1 | **Ctrl+S** place после этой сессии |
| 2 | DevProduct → Publish → live Robux |
| 3 | Live DS rejoin |
| 4 | **Не** включать Allow* без W4 plan |

---

## Explicit NOT in scope

Allow* unlock · ProfileService live · Guilds MVP · AI mesh online · Haven décor · B1 PvP slice 3 · track 106
