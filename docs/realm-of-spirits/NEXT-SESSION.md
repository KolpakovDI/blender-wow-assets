# NEXT SESSION

**Статус:** 2026-08-23 — Фаза 1 **COMPLETE** · Фаза 2 **COMPLETE** · Фаза 3 **COMPLETE CONDITIONAL** · **Фаза 4 W1 PASS** · **Фаза 4 W2 PASS**
**Следующий фокус:** **Фаза 4 W3** (unpublished migrate sample) **или** owner hands (снять Ф3 CONDITIONAL)

**Roadmap:** [`ROADMAP-2026-08-23.md`](ROADMAP-2026-08-23.md) · **Phase 4:** [`SESSION-2026-08-23-phase4-scale.md`](SESSION-2026-08-23-phase4-scale.md)

## Старт сессии (порядок жёсткий)

1. **Ctrl+S** place → подтвердить SoT
2. **Приоритет по умолчанию:** **Ф4 W3** (unpublished migrate sample) — gate **locked**
3. **Owner hands** — параллельно не блокирует W2, но live DS rejoin нужен до W4 cutover
4. **Bugfix-only** — если что-то красное в play smoke
5. **106 / B1 / Haven décor** — только по явной команде (не в Ф4 W1–W2)

## Выбор владельца (что значит «дальше»)

| Команда / намерение | Действие агента |
|---------------------|-----------------|
| «Ф4 W3» / «migrate sample» | ROADMAP § Phase 4 W3 · one-key Studio unpublished |
| «Ф4 W2» / «ProfileService shadow» | **DONE** W2 PASS — see SESSION tracker |
| Owner hands / Publish / live Robux / DS | Чеклист § Owner hands · не flip Allow* |
| «Guilds» / «AI mesh» / «B1» | Только после W2–W3 schema lock · named backlog |
| «дальше» (без уточнения) | **Ф4 W3** (default после W2 PASS) |

## Где остановились

| Область | Состояние |
|---------|-----------|
| **Фаза 4 W2** | **PASS** — ProfileService vendored + shadow read · gate locked |
| **Фаза 3** | **COMPLETE CONDITIONAL** — owner hands pending |
| **Persistence** | Live = `DataStoreManager` · shadow audit on join · PS module vendored |
| **ExpansionGate** | All Allow*=false (не трогали) |

## Фаза 4 W2 exit (2026-08-23)

- `SSS.RealmOfSpirits.ProfileService` — MadStudio library 5331689994 (vendored)
- `ProfileServiceAdapter`: `ShadowReadLegacyKey`, `ShadowAuditPlayer`, phase `F4-W2-shadow`, rollback in audit
- `DataStoreManager`: defer shadow audit after `LoadData`; extended `[Persistence]` init log
- **Fix:** `ExpansionGate` Studio `folder:GetAttribute` (was dot syntax crash on init)
- **NOT:** Allow* · PS Load/Save · Guilds · mesh · B1 · 106

## Фаза 4 W1 exit (2026-08-23)

- `ProfileServiceAdapter`: schema inventory (42 keys), `GetMigrationAudit`, `ValidateDataShape`
- `DataStoreManager`: `GetPersistenceBackend`, init `[Persistence]` audit log
- **NOT:** Allow* · live PS Load/Save · Guilds · mesh · B1 · 106

## Owner hands (carry-over Ф3)

| # | Действие | Зачем |
|---|----------|-------|
| 1 | **Ctrl+S** place | SoT sync |
| 2 | DevProduct ID → Publish → live **R** | W2 monetization CONDITIONAL |
| 3 | Live DS rejoin (PlaceId≠0) | DS CONDITIONAL · нужен до Ф4 W4 cutover |
| 4 | **Не** AllowProfileService до W4 plan | ExpansionGate |

## Backlog (named tracks)

| # | Срез | Когда |
|---|------|-------|
| **Ф4 W3** | Unpublished one-key migrate sample | **default next** |
| **Ф4 W2** | ProfileService vendor + shadow read | ☑ **PASS** |
| **106 polish** | Alt track | Явная команда |
| **B1** | PvP slice 3 | После PS schema lock |

## Studio SoT

`C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl`

**Mirror (F4):** `ProfileService` · `ProfileServiceAdapter` · `DataStoreManager` · `ExpansionGate` · `GuildSystem` · `SpiritMeshGenerationService`

## Не включать (до W4 + owner)

Allow* flip · ProfileService live · Guilds expand · AI mesh online · Haven décor · B1 · 106 · два major track

## Архив

Phase 1–2 **COMPLETE** · Phase 3 **COMPLETE CONDITIONAL** · Phase 4 W1 **PASS** · Phase 4 W2 **PASS** · [`SESSION-2026-08-23-phase4-scale.md`](SESSION-2026-08-23-phase4-scale.md)
