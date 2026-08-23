# NEXT SESSION

**Статус:** 2026-08-23 — Фаза 1 **COMPLETE** · Фаза 2 **COMPLETE** · Фаза 3 **COMPLETE CONDITIONAL** · **Фаза 4 W1 PASS** · **Фаза 4 W2 PASS** · **Фаза 4 W3 PASS**
**Следующий фокус:** **Фаза 4 W4** (owner gate flip + live DS smoke) **или** owner hands (снять Ф3 CONDITIONAL)

**Roadmap:** [`ROADMAP-2026-08-23.md`](ROADMAP-2026-08-23.md) · **Phase 4:** [`SESSION-2026-08-23-phase4-scale.md`](SESSION-2026-08-23-phase4-scale.md)

## Старт сессии (порядок жёсткий)

1. **Ctrl+S** place → подтвердить SoT
2. **Приоритет по умолчанию:** **Ф4 W4** (owner gate flip + live smoke) — **требует owner hands Ф3**
3. **Owner hands** — Publish + live DS rejoin **рекомендованы до W4 cutover**
4. **Bugfix-only** — если что-то красное в play smoke
5. **106 / B1 / Haven décor** — только по явной команде (не в Ф4 W4 без unlock)

## Выбор владельца (что значит «дальше»)

| Команда / намерение | Действие агента |
|---------------------|-----------------|
| «Ф4 W4» / «gate flip» / «ProfileService live» | ROADMAP § Phase 4 W4 · owner Allow* + live DS |
| «Ф4 W3» / «migrate sample» | **DONE** W3 PASS — see SESSION tracker |
| Owner hands / Publish / live Robux / DS | Чеклист § Owner hands · не flip Allow* без W4 plan |
| «Guilds» / «AI mesh» / «B1» | Только после W4 schema lock · named backlog |
| «дальше» (без уточнения) | **Ф4 W4** (default после W3 PASS) **или** owner hands |

## Где остановились

| Область | Состояние |
|---------|-----------|
| **Фаза 4 W3** | **PASS** — one-key migrate sample (Mock) · gate locked |
| **Фаза 4 W2** | **PASS** — ProfileService vendored + shadow read |
| **Фаза 3** | **COMPLETE CONDITIONAL** — owner hands pending |
| **Persistence** | Live = `DataStoreManager` · W3 migrate sample on sentinel id only |
| **ExpansionGate** | All Allow*=false (не трогали) |

## Фаза 4 W3 exit (2026-08-23)

- `ProfileServiceAdapter`: `MigrateSampleUserId=900000001`, `MigrateSampleKey`, `SeedMigrateSampleLegacy`, `ComputeDataChecksum`, phase `F4-W3-migrate`
- One-way migrate legacy → `RealmOfSpirits_Profiles_v1` via **ProfileStore.Mock** (no production keys)
- `ValidateDataShape` + checksum match on source/target — **PASS** (unpublished: `synthetic_seed`)
- **NOT:** Allow* · PS live Load/Save on join · Guilds · mesh · B1 · 106

## Фаза 4 W2 exit (2026-08-23)

- `SSS.RealmOfSpirits.ProfileService` — MadStudio library 5331689994 (vendored)
- `ProfileServiceAdapter`: shadow dual-read · rollback in audit
- **Fix:** `ExpansionGate` Studio `folder:GetAttribute` colon syntax

## Owner hands (carry-over Ф3 + W4 prereq)

| # | Действие | Зачем |
|---|----------|-------|
| 1 | **Ctrl+S** place | SoT sync |
| 2 | DevProduct ID → Publish → live **R** | W2 monetization CONDITIONAL |
| 3 | Live DS rejoin (PlaceId≠0) | DS CONDITIONAL · **нужен до Ф4 W4 cutover** |
| 4 | **Не** AllowProfileService до W4 explicit plan | ExpansionGate |

## Backlog (named tracks)

| # | Срез | Когда |
|---|------|-------|
| **Ф4 W4** | Owner gate flip + live PS smoke | **default next** (after owner hands) |
| **Ф4 W3** | Unpublished one-key migrate sample | ☑ **PASS** |
| **106 polish** | Alt track | Явная команда |
| **B1** | PvP slice 3 | После W4 schema lock |

## Studio SoT

`C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl`

**Mirror (F4):** `ProfileService` · `ProfileServiceAdapter` · `DataStoreManager` · `ExpansionGate` · `GuildSystem` · `SpiritMeshGenerationService`

## Не включать (до W4 + owner)

Allow* flip · ProfileService live on join · Guilds expand · AI mesh online · Haven décor · B1 · 106 · два major track

## Архив

Phase 1–2 **COMPLETE** · Phase 3 **COMPLETE CONDITIONAL** · Phase 4 W1 **PASS** · Phase 4 W2 **PASS** · Phase 4 W3 **PASS** · [`SESSION-2026-08-23-phase4-scale.md`](SESSION-2026-08-23-phase4-scale.md)
