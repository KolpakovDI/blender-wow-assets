# NEXT SESSION

> **DEV-ONLY MODE (default)** — разработка в unpublished Studio (PlaceId=0). **Publish / live cutover не default next.** Агент **может** предложить Publish **только** когда [`Readiness assessment`](#readiness-assessment-когда-агент-предложит-publish) = **PASS** — это рекомендация, не инструкция; финальное решение за владельцем. Чеклист cutover — [`OWNER-UNLOCK.md`](OWNER-UNLOCK.md) (**PAUSED**, gated до readiness PASS или «owner unlock»).

**Статус:** 2026-08-27 — Фаза 1 **COMPLETE** · Фаза 2 **COMPLETE** · Фаза 3 **COMPLETE CONDITIONAL** · **Фаза 4 W1–W18 PASS** (W4 PREP CONDITIONAL) · numbered track **CLOSED** · **DEV-ONLY active**
**Следующий фокус:** **post-W18 regression smoke** — Smoke*Mock suite + core loop re-smoke · **fix-only** если красное · без Publish · без Allow* flip

**Roadmap:** [`ROADMAP-2026-08-23.md`](ROADMAP-2026-08-23.md) · **Phase 4:** [`SESSION-2026-08-23-phase4-scale.md`](SESSION-2026-08-23-phase4-scale.md) · **Owner unlock (gated):** [`OWNER-UNLOCK.md`](OWNER-UNLOCK.md) · **Tracker (PAUSED):** [`SESSION-2026-08-27-owner-unlock.md`](SESSION-2026-08-27-owner-unlock.md)

## План Ф4 W14–W18 — DONE

| Нед | Название | Статус |
|-----|----------|--------|
| **W14** | Rated PvP prep | ☑ PASS — SmokeRatedPvPMock |
| **W15** | Rank / ladder stub | ☑ PASS — SmokeLadderMock + RatedPvPPanelUI |
| **W16** | Matchmaking stub | ☑ PASS — SmokeMatchmakingMock |
| **W17** | Season / meta stub | ☑ PASS — SmokeSeasonMock |
| **W18** | Numbered-track wrap | ☑ PASS — SmokeWrapMock |

**Gate:** `AllowNewPvPFeatures=false`. Live APIs Locked; QA = Smoke*Mock only.

## Dev-only policy (active)

| Правило | Детали |
|---------|--------|
| **Default mode** | Unpublished Studio (PlaceId=0) · Mock/shadow PS · all Allow*=false |
| **Publish / live cutover** | **Не default next.** Активация: readiness **PASS** → агент **предлагает** owner unlock · или явная команда «проект готов» / «owner unlock» / «owner unlock step N» |
| **«дальше» без readiness PASS** | Post-W18 regression smoke + fix-only — **не** Publish, **не** owner unlock |
| **Не делать без owner unlock** | Allow* flip · live DS rejoin · DevProduct live · API Services (hands) |
| **Valid now** | Edit+Play smoke · MCP audit · Mock/shadow · `quality_gate` · git mirrors · fix-only |

## Readiness assessment (когда агент предложит Publish)

> **Текущий вердикт (2026-08-27): NOT READY** — см. таблицу ниже. Агент **не** предлагает Publish, пока все обязательные строки не **PASS**.

Лёгкий чеклист — все пункты **PASS** → агент **может** (не обязан каждую сессию) предложить: «Проект выглядит готовым к cutover — рассмотреть [`OWNER-UNLOCK.md`](OWNER-UNLOCK.md) шаг 1→2?» Владелец решает сам; отказ = продолжаем DEV-ONLY.

| # | Критерий | PASS | Сейчас (2026-08-27) |
|---|----------|------|---------------------|
| 1 | **Numbered track** Ф4 W1–W18 | все smoke PASS · GateAllows=false | ☑ PASS |
| 2 | **Post-W18 regression** | Smoke*Mock suite + core loop (Mika→Exit→battle→Haven→Sanctum) зелёные в текущей сессии | ☐ **не подтверждено** (default next) |
| 3 | **`quality_gate.py`** | green в текущей сессии | ☑ (последний W18 exit) |
| 4 | **P0 regressions** | нет красного в play smoke / Output (DoNotSave, load fail, broken E2E) | ☐ **не re-smoke** после W18 close |
| 5 | **Core loop stable** | quest→catch→battle→turn-in без блокеров; Sanctum Resonant path OK | ☑ dev smoke (pre-W18) · ☐ post-W18 confirm |
| 6 | **Polish threshold** | нет открытых P0 UX/blocker; named backlog (106, B1, décor) — не блокер soft launch | ☐ CONDITIONAL — E1 n≥10 таблица пуста; side 106/B1 open |
| 7 | **Live prep audit** | PlaceId=0 OK for dev; audits F4-W4/W13/W18 prep PASS | ☑ prep PASS · live cutover **не начат** |

**Когда NOT READY (сейчас):** «дальше» → regression smoke + fix-only, **без** Publish suggestion.

**Когда PASS:** агент предлагает открыть owner unlock (шаг 1 Ctrl+S → шаг 2 Publish) с кратким rationale; **не** флипает gates и **не** Publish сам.

## Старт сессии (порядок жёсткий)

1. **Ctrl+S** place → подтвердить SoT
2. **Post-W18 regression smoke** — SmokeWrapMock + SmokeRated/Ladder/MM/Season + core loop (Mika→Exit→battle→Haven→Sanctum)
3. **Fix-only** — если что-то красное в play smoke
4. **Owner unlock** — по readiness **PASS** (агент предлагает) **или** явной команде «проект готов» / «owner unlock» → [`OWNER-UNLOCK.md`](OWNER-UNLOCK.md)
5. **106 / B1 / Haven décor / mesh** — только по явной команде

## Выбор владельца (что значит «дальше»)

| Команда / намерение | Действие агента |
|---------------------|-----------------|
| «дальше» (без уточнения) | Post-W18 regression smoke + fix-only — **не** Publish (readiness likely NOT READY) |
| readiness **PASS** (агент) | **Опциональная рекомендация:** owner unlock шаг 1→2 — владелец решает |
| «проект готов» / «owner unlock» / «owner unlock step N» | [`OWNER-UNLOCK.md`](OWNER-UNLOCK.md) — cutover track (override readiness gate) |
| «W14»–«W18» / rated / ladder / MM / season / wrap | already **PASS** — re-smoke if needed |
| «106» / «B1» / «Haven décor» / «mesh» | Named backlog · не default |
| «Ф4 W4 cutover» / «AllowProfileService» | OwnerFlipChecklist · **только после** owner unlock step 3 PASS |

## Где остановились

| Область | Состояние |
|---------|-----------|
| **Mode** | **DEV-ONLY** (default) · owner unlock **PAUSED** |
| **Фаза 4 W14–W18** | **PASS** — RatedPvPSystem + PanelUI; all Smoke*Mock green; Phase `F4-W18-wrap` |
| **Фаза 4 W4** | **PREP PASS CONDITIONAL** — Load/Save wired, gates OFF, PlaceId=0 |
| **ExpansionGate** | All Allow*=false |
| **GachaRobuxProductId** | **0** (gate) |
| **Schema** | **v1 locked** |

## Фаза 4 W18 exit (2026-08-27) — PASS (dev-only prep)

- `GetWrapAudit` / `SmokeWrapMock` — checklist 7 · backlog map · GateAllows=false
- Regress: SmokeRated / Ladder / Matchmaking / Season all Success=true
- `quality_gate.py` green
- **Owner unlock:** PAUSED — см. [`OWNER-UNLOCK.md`](OWNER-UNLOCK.md) (gated on «проект готов»)

## Backlog (named tracks — post-W18)

| # | Срез | Когда |
|---|------|-------|
| **Post-W18 regression** | Smoke*Mock + core loop re-smoke + fix-only | **default «дальше»** |
| **Owner unlock** | Publish + live DS + FlipChecklist | **gated** — readiness PASS (агент предлагает) **или** «проект готов» / «owner unlock» |
| **Side 106** | «Цикл стихий» polish | явная команда |
| **Live Guild DS** | AllowGuilds + `RealmOfSpirits_Guilds_v1` | owner unlock шаг 6 |
| **PS cutover** | W4 FlipChecklist | owner unlock шаг 5 |
| **B1** | PvP slice 3 | явная команда |
| **Online AI mesh** | AllowAiMeshOnline | явная команда |
| **Haven décor p2** | polish | явная команда |
| **Ф4 W14–W18** | Rated PvP track | ☑ **PASS** |
| **Ф4 W13** | Inventory↔bank transfer | ☑ **PASS** |

## Studio SoT

`C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl`

**Mirror (F4):** `ProfileService` · `ProfileServiceAdapter` · `DataStoreManager` · `ExpansionGate` · `GuildSystem` · `GuildPanelUI` · `RatedPvPSystem` · `RatedPvPPanelUI` · `GameManager` · `SpiritMeshGenerationService`

## Не включать (dev-only)

Publish · Allow* flip · live Guild DS · rated live · Haven décor · B1 · 106 · два major track · silent W19 · **Publish suggestion без readiness PASS**

## Архив

Phase 1–2 **COMPLETE** · Phase 3 **COMPLETE CONDITIONAL** · Phase 4 W1–W18 **PASS** (W4 prep CONDITIONAL) · [`SESSION-2026-08-23-phase4-scale.md`](SESSION-2026-08-23-phase4-scale.md)
