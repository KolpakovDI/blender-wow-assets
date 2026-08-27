# NEXT SESSION

> **DEV-ONLY MODE** (owner decision 2026-08-23) — **не публикуем** place и **не включаем** live cutover, пока владелец явно не снимет режим. Проект сырой; публикация отложена **намеренно**, не навсегда.

**Статус:** 2026-08-27 — Фаза 1 **COMPLETE** · Фаза 2 **COMPLETE** · Фаза 3 **COMPLETE CONDITIONAL** · **Фаза 4 W1–W3 PASS** · **W4 PREP PASS (CONDITIONAL)** · **W5–W13 PASS (dev-only)** · **W14–W18 plan locked**
**Следующий фокус (dev-only default):** **Ф4 W14→W18** rated PvP track (gate OFF) — см. SESSION § W14–W18 · **или** owner unlock — без Publish / Allow* flip

**Roadmap:** [`ROADMAP-2026-08-23.md`](ROADMAP-2026-08-23.md) · **Phase 4:** [`SESSION-2026-08-23-phase4-scale.md`](SESSION-2026-08-23-phase4-scale.md)

## План Ф4 W14–W18 (rated PvP track, DEV-ONLY)

| Нед | Название | Одна строка |
|-----|----------|-------------|
| **W14** | Rated PvP prep | Rating schema stub · Declare/Match fail-closed · `SmokeRatedPvPMock` |
| **W15** | Rank / ladder stub | In-memory ranks · `GetLadderAudit` · panel read-only · live Locked |
| **W16** | Matchmaking stub | Queue/party fail-closed · `SmokeMatchmakingMock` |
| **W17** | Season / meta stub | SeasonId · soft-reset plan · `GetSeasonAudit` (no live seasons) |
| **W18** | Numbered-track wrap | Exit checklist W1–W18 · backlog map · NEXT post-W18 |

**Gate:** `AllowNewPvPFeatures=false` (reuse existing; no new AllowRatedPvP). Live APIs Locked; QA = Smoke*Mock only.

## Dev-only policy

| Допустимо сейчас | Отложено (не заблокировано навсегда) |
|------------------|--------------------------------------|
| Studio Edit + Play (unpublished, PlaceId=0) | **Publish** place (PlaceId≠0) |
| Studio MCP smoke / multi_edit | Live **DataStore rejoin** под нагрузкой |
| Mock / shadow **ProfileService** (gate OFF) | Live **Robux** purchase (DevProduct + Publish) |
| `quality_gate.py`, git mirrors, docs | **`AllowProfileService`** flip + live PS cutover |
| Bug fix-only по красному smoke | **`AllowGuilds`** flip + live guild DS |
| Ф4 prep: audit · migrate sample · gated Load/Save · Guild in-memory MVP + bank/warfare/transfer prep | Live ops / store listing / marketing pass |

**Снять dev-only:** только явная команда владельца («publish», «owner hands», «live cutover») + [`OwnerFlipChecklist`](SESSION-2026-08-23-phase4-scale.md) в SESSION W4.

## Старт сессии (порядок жёсткий)

1. **Ctrl+S** place → подтвердить SoT
2. **Приоритет по умолчанию (dev-only):** **Ф4 W14→W18** rated PvP track (gate OFF)
3. **Bug fix-only** — если что-то красное в play smoke
4. **Owner hands / Publish / live cutover** — только по **явной** команде владельца (не default)
5. **106 / B1 / Haven décor** — только по явной команде

## Выбор владельца (что значит «дальше»)

| Команда / намерение | Действие агента |
|---------------------|-----------------|
| «дальше» (без уточнения) | **Ф4 W14→W18** по SESSION plan (dev-only safe) |
| «W14» / «rated» | SESSION W14 · rating stub + SmokeRatedPvPMock |
| «W15» / «ladder» | SESSION W15 · rank/ladder stub |
| «W16» / «matchmaking» | SESSION W16 · queue stub |
| «W17» / «season» | SESSION W17 · season/meta stub |
| «W18» / «wrap» | SESSION W18 · numbered-track wrap |
| «W13» / «inventory» / «transfer» | SESSION W13 · already **PASS** — re-smoke if needed |
| «W12» / «warfare» | SESSION W12 · already **PASS** — re-smoke if needed |
| «W11» / «item bank» | SESSION W11 · already **PASS** — re-smoke if needed |
| «W10» / «bank deposit» | SESSION W10 · already **PASS** — re-smoke if needed |
| «W9» / «Guild UI» | SESSION W9 · already **PASS** — re-smoke if needed |
| «W8» / «Guild leave» | SESSION W8 · already **PASS** — re-smoke if needed |
| «W6» / «Guild MVP» | SESSION W6 · already **PASS** |
| Owner hands / Publish / live DS | Чеклист § Owner unlock · **только явная команда** |
| «Ф4 W4 cutover» / «AllowProfileService» | OwnerFlipChecklist · live smoke · **owner unlock dev-only** |
| «106» / «B1» / «Haven décor» | Named backlog · не default |

## Где остановились

| Область | Состояние |
|---------|-----------|
| **Dev-only** | **ACTIVE** — Publish/live cutover deferred by owner |
| **Фаза 4 W13** | **PASS** — TransferItem/Copper To/FromBank fail-closed Locked; SmokeInventoryBankTransferMock |
| **Фаза 4 W12** | **PASS** — DeclareWarfare/JoinWarfare fail-closed Locked; SmokeWarfareMock in-memory |
| **Фаза 4 W11** | **PASS** — DepositItem/WithdrawItem fail-closed Locked; SmokeBankItemSlotsMock in-memory |
| **Фаза 4 W10** | **PASS** — Deposit/Withdraw fail-closed Locked; SmokeBankDepositMock in-memory |
| **Фаза 4 W9** | **PASS** — GuildPanelUI + bank prep (in-memory Locked); CreateOrJoin still gated |
| **Фаза 4 W8** | **PASS** — Leave persist + multi-player roster merge; CreateOrJoin still gated |
| **Фаза 4 W7** | **PASS** — join restore `data.Guild` → in-memory; CreateOrJoin still gated |
| **Фаза 4 W6** | **PASS** — Guild MVP design + in-memory roster; `AllowGuilds=false` |
| **Фаза 4 W5** | **PASS** — schema lock v1 + `GetGuildAudit` scout |
| **Фаза 4 W4** | **PREP PASS CONDITIONAL** — Load/Save wired, gates OFF, PlaceId=0 |
| **Фаза 4 W3** | **PASS** — one-key migrate sample (Mock) |
| **Фаза 3** | **COMPLETE CONDITIONAL** — live Robux/DS = owner unlock, not default |
| **Persistence** | Live = `DataStoreManager` · PS path ready behind triple gate |
| **ExpansionGate** | All Allow*=false (не трогали) |
| **Schema** | **v1 locked** (42 keys + optional `Guild`, `_Session`) — `Guild` may include `Role` |

## Фаза 4 W13 exit (2026-08-27) — PASS (dev-only)

- `TransferItemToBank` / `TransferItemFromBank` / `TransferCopperToBank` / `TransferCopperFromBank` — live fail-closed `Locked` until AllowGuilds + unlocked bank
- `SmokeInventoryBankTransferMock` — synthetic `{Inventory,CopperCoins}` ↔ bank; inv 5→4 · copper 850 · bank item qty 1 · copper 150; live Transfer* blocked; InsufficientItems
- Remotes `TransferItemToBank` / `TransferItemFromBank` / `TransferCopperToBank` / `TransferCopperFromBank`
- CreateOrJoin / `/guild` still fail-closed; phase `F4-W13-guild-inv-bank`
- **NOT:** AllowGuilds · guild DS · unlock Bank.Locked · live player inventory mutate under gate OFF · Publish

## Фаза 4 W12 exit (2026-08-24) — PASS (dev-only)

- `DeclareWarfare` / `JoinWarfare` — live fail-closed `Locked` until AllowGuilds + unlocked warfare
- `SmokeWarfareMock` — in-memory Declared vs target; participants 2; SelfTarget blocked; LiveDeclare/Join blocked
- Remotes `GetWarfare` / `DeclareWarfare` / `JoinWarfare`; panel `Warfare` snapshot read-only
- CreateOrJoin / `/guild` still fail-closed; phase `F4-W12-guild-warfare`
- **NOT:** AllowGuilds · AllowWarfare · guild DS · unlock Warfare.Locked · combat resolve · Publish

## Фаза 4 W11 exit (2026-08-24) — PASS (dev-only)

- `DepositItem` / `WithdrawItem` — live fail-closed `Locked` until AllowGuilds + unlocked bank
- `SmokeBankItemSlotsMock` — in-memory item 101 qty 3→2; SlotsFull; LiveDeposit/WithdrawItem blocked
- Remotes `DepositItem` / `WithdrawItem`; slot snapshot in `GetBank.Items`
- CreateOrJoin / `/guild` still fail-closed; phase `F4-W11-guild-bank-items`
- **NOT:** AllowGuilds · guild DS · unlock Bank.Locked · warfare · player inventory↔bank · Publish

## Фаза 4 W10 exit (2026-08-24) — PASS (dev-only)

- `DepositCopper` / `WithdrawCopper` — live fail-closed `Locked` until AllowGuilds + unlocked bank
- `SmokeBankDepositMock` — in-memory copper 500→300; LiveDeposit/Withdraw blocked
- Remotes `Deposit` / `Withdraw`; `GetBank.WriteLocked` · panel `BankWriteLocked`
- CreateOrJoin / `/guild` still fail-closed; phase `F4-W10-guild-bank-write`
- **NOT:** AllowGuilds · guild DS · unlock Bank.Locked · warfare · Publish

## Фаза 4 W9 exit (2026-08-23) — PASS (dev-only)

- `GuildPanelUI` LocalScript — G / `/guildpanel`; fail-closed locked message when no membership
- `GetBank` / `GetBankAudit` / `GetPanelSnapshot` — empty Locked bank on guild record (in-memory only)
- Remotes `GetPanel` / `GetBank`; CreateOrJoin / `/guild` still fail-closed
- `SmokeGuildBankMock` · `SmokeGuildPanelPrepMock` + W6–W8 regression — GateAllows=false
- **NOT:** AllowGuilds · guild DS · live bank deposit · Publish · warfare

## Фаза 4 W8 exit (2026-08-23) — PASS (dev-only)

- `ClearGuildMembership` / `Leave` — clears `data.Guild` + in-memory membership (no AllowGuilds)
- `mergeGuildMetadata` — two players same guild Id → shared roster
- `SmokeGuildLeaveMock` — DataGuildNil=true · RosterCountAfter=0 · CreateOrJoinBlocked=true
- `SmokeRosterMergeMock` — RosterCount=2 · SharedGuildCount=1 · LeaderUserId set
- `CreateOrJoin` / `/guild` still fail-closed
- **NOT:** AllowGuilds · guild DS · Publish · UI panel · bank/warfare

## Фаза 4 W7 exit (2026-08-23) — PASS (dev-only)

- `RestoreFromPlayerData` / `RestoreMembershipFromGuildTable` — **no** `AllowGuilds` required
- `GameManager` + `GuildSystem.Start` defer restore after load
- `SmokeJoinRestoreMock` — Restored=true · CreateOrJoinBlocked=true · GateAllows=false
- `CreateOrJoin` / `/guild` still fail-closed
- **NOT:** AllowGuilds · guild DS · Publish · UI panel · bank/warfare

## Фаза 4 W6 exit (2026-08-23) — PASS (dev-only)

- `GetMvpDesign` persistence plan (player Guild vs future `RealmOfSpirits_Guilds_v1`)
- In-memory `guildsById` roster + `GetRoster` / `GetGuildRecord`
- `SmokeGuildRosterMock` — roster=2 · CreateOrJoin blocked · GateAllows=false
- `CreateOrJoin` / `/guild` still fail-closed
- **NOT:** AllowGuilds · guild DS · Publish · UI panel · bank/warfare

## Фаза 4 W4 exit (2026-08-23) — PREP PASS CONDITIONAL

- `LoadPlayerData` / `SavePlayerData` / `SmokeLoadSaveMock` implemented
- Defaults OFF → zero live behavior change
- **NOT:** Allow* flip · live PS on join · Guilds live

## Owner unlock (when critical — NOT default next)

| # | Действие | Зачем |
|---|----------|-------|
| 1 | **Ctrl+S** place | SoT sync |
| 2 | Owner: снять **dev-only** явной командой | Policy gate |
| 3 | DevProduct ID → Publish → live **R** | W2 monetization CONDITIONAL |
| 4 | Live DS rejoin (PlaceId≠0) | DS CONDITIONAL · prereq W4 live |
| 5 | OwnerFlipChecklist (SESSION W4) | Allow* + Enabled + UseProfileServiceAdapter |
| 6 | Live PS Load/Save/rejoin smoke | Mark W4 COMPLETE |

## Backlog (named tracks)

| # | Срез | Когда |
|---|------|-------|
| **Ф4 W14** | Rated PvP prep (gate OFF) | **default next** (dev-only) |
| **Ф4 W15** | Rank / ladder stub (gate OFF) | after W14 |
| **Ф4 W16** | Matchmaking stub (gate OFF) | after W15 |
| **Ф4 W17** | Season / meta stub (gate OFF) | after W16 |
| **Ф4 W18** | Phase 4 numbered-track wrap | after W17 |
| **Ф4 W13** | Inventory↔bank transfer prep (gate OFF) | ☑ **PASS** |
| **Ф4 W12** | Warfare stub (gate OFF) | ☑ **PASS** |
| **Ф4 W11** | Item bank slots (gate OFF) | ☑ **PASS** |
| **Ф4 W10** | Bank deposit/withdraw prep (gate OFF) | ☑ **PASS** |
| **Ф4 W9** | Guild UI panel / bank prep (gate OFF) | ☑ **PASS** |
| **Ф4 W8** | Leave persist + multi-player roster merge | ☑ **PASS** |
| **Ф4 W7** | Join restore `data.Guild` → in-memory membership | ☑ **PASS** |
| **Ф4 W6** | Guild MVP design + in-memory roster | ☑ **PASS** |
| **Ф4 W5** | Schema lock + GuildSystem scout | ☑ **PASS** |
| **Ф4 W4 live** | Owner gate flip + live PS smoke | Owner unlock dev-only |
| **Ф4 W4 prep** | Gated Load/Save + Mock smoke | ☑ **PREP PASS** |
| **106 polish** | Alt track | Явная команда |
| **B1** | PvP slice 3 | После W14+ / owner call |

## Studio SoT

`C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl`

**Mirror (F4):** `ProfileService` · `ProfileServiceAdapter` · `DataStoreManager` · `ExpansionGate` · `GuildSystem` · `GuildPanelUI` · `GameManager` · `SpiritMeshGenerationService`

## Не включать (dev-only + gates)

Publish без owner · Allow* flip без checklist · live Guild DS · AI mesh online · Haven décor · B1 · 106 · два major track

## Архив

Phase 1–2 **COMPLETE** · Phase 3 **COMPLETE CONDITIONAL** · Phase 4 W1–W3 **PASS** · W4 **PREP PASS CONDITIONAL** · W5–W13 **PASS** · [`SESSION-2026-08-23-phase4-scale.md`](SESSION-2026-08-23-phase4-scale.md)
