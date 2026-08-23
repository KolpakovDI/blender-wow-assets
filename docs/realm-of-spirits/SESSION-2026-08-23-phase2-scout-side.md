# SESSION — Phase 2 scout side line (2026-08-23)

**Roadmap:** [`ROADMAP-2026-08-23.md`](ROADMAP-2026-08-23.md) · **Фаза 2** · track **108–112**  
**Place SoT:** `C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl` — **Ctrl+S** после Studio-правок  
**Phase 1 tracker (closed):** [`SESSION-2026-08-23-phase1-stabilization.md`](SESSION-2026-08-23-phase1-stabilization.md)

---

## Цель фазы

«Показать другу» + 30+ мин контента: side scout line **108–112** (VisitZone, без новых ObjectiveType).

### Exit criteria (фаза)

| # | Критерий | Статус |
|---|----------|--------|
| 1 | 1 side chain Accept→TurnIn PASS | ☑ W4 full line **107–112** MCP **PASS** |
| 2 | Регресс W2 (113→114, 115→116) не красный | ☑ W4 chain **113→116** MCP **PASS** |
| 3 | QuestLocations + VisitZone hooks в SoT | ☑ W1 · W4 QuestLocations count=6 **PASS** |

---

## W1 — Quest 109 «Сундучный грот» — **PASS MCP (2026-08-23)**

**Deliverable:** VisitZone **ChestCluster** — accept → zone → turn-in.

| # | Задача | Статус |
|---|--------|--------|
| 1 | `ZoneConfig.QuestLocations` (6 pads) в SoT | ☑ |
| 2 | `WorldSpawner.BuildQuestLocations()` | ☑ (был в mirror, добавлен в Studio) |
| 3 | `ZoneSystem` VisitZone + QuestLocation details | ☑ (Studio sync) |
| 4 | Quest **107–112** inline `QuestSystem.QuestDatabase` | ☑ |
| 5 | `EnsureChestClusterWayfind` у Exit | ☑ |
| 6 | QuestUI Mika **107–109** | ☑ |
| 7 | MCP smoke **109** | ☑ **PASS** |
| 8 | W2 non-regress **115** accept | ☑ **PASS** |

### MCP smoke (Play/Server)

| Шаг | Результат |
|-----|-----------|
| `QuestSeedCompletedBF(player, {1})` | **PASS** |
| Accept **109** | **PASS** |
| `UpdateQuestProgressBF` VisitZone **ChestCluster** | **PASS** |
| TurnIn **109** | **PASS** |
| Seed **114** + Accept **115** (regress) | **PASS** |
| `QuestLocations` count=6, ChestCluster model | **PASS** |

### SoT правки (Studio)

- `ReplicatedStorage.RealmOfSpirits.ZoneConfig` — `QuestLocations` + Music keys
- `ServerScriptService.RealmOfSpirits.ZoneSystem` — VisitZone progress + detail keys
- `ServerScriptService.RealmOfSpirits.WorldSpawner` — `BuildQuestLocations()`
- `ServerScriptService.RealmOfSpirits.QuestSystem` — quests **107–112**
- `ServerScriptService.RealmOfSpirits.OtakuHavenBuilder` — `EnsureChestClusterWayfind`
- `StarterPlayer.StarterPlayerScripts.QuestUI` — Mika lines 107–109

**Mirror sync (W1):** `OtakuHavenBuilder.lua` (EnsureChestClusterWayfind); `QuestCatalog.lua` уже содержал 108–112.

---

## W2 — Quest 108 + 110 (VisitZone polish) — **PASS MCP (2026-08-23)**

| # | Задача | Exit | Статус |
|---|--------|------|--------|
| 1 | Hands/MCP smoke **108** Waystone (prereq Q10) | Accept→VisitZone→TurnIn PASS | ☑ **PASS MCP** |
| 2 | Hands/MCP smoke **110** ElementShrine (prereq Q8) | PASS | ☑ **PASS MCP** |
| 3 | Wayfind optional: StoneBasin / FrostRidge hints | Ensure* только при hands FAIL | ☑ **SKIP** — MCP PASS без Ensure* |
| 4 | Mirror sync W1 SoT modules | Studio → docs/studio | ☑ |
| 5 | Non-regress **115** accept | PASS | ☑ **PASS** |

### MCP smoke (Play/Server)

| Шаг | Результат |
|-----|-----------|
| `QuestSeedCompletedBF(player, {10})` | **PASS** |
| Accept **108** | **PASS** («Квест принят!») |
| `UpdateQuestProgressBF` VisitZone **Waystone** | **PASS** (ReadyToTurnIn via `QuestGetActiveBF`) |
| TurnIn **108** | **PASS** («Квест сдан!») |
| `QuestSeedCompletedBF(player, {8})` | **PASS** |
| Accept **110** | **PASS** |
| `UpdateQuestProgressBF` VisitZone **ElementShrine** | **PASS** (ReadyToTurnIn) |
| TurnIn **110** | **PASS** |
| Seed **114** + Accept **115** (regress) | **PASS** |
| `QuestLocations` Waystone + ElementShrine present (count=6) | **PASS** |

### Mirror sync (W2)

Studio → `docs/realm-of-spirits/studio/`:

- `ZoneSystem.lua` ☑
- `WorldSpawner.lua` ☑
- `ZoneConfig.lua` ☑
- `QuestUI.lua` ☑
- `QuestSystem.lua` — **не перезаписан dump’ом Studio**: SoT Play = inline `QuestDatabase`; git mirror остаётся на `QuestCatalog` (иначе `validate_quest_catalog` red). Квесты **108/110** уже в `QuestCatalog.lua`.

### Wayfind Ensure*

Не добавлялись (`EnsureStoneBasin*` / `EnsureFrostRidge*`) — smoke Accept→VisitZone→TurnIn зелёный без world hints.

---

## W3 — Quest 111 + 112 — **PASS MCP (2026-08-23)**

| # | Задача | Exit | Статус |
|---|--------|------|--------|
| 1 | MCP smoke **111** Overlook (prereq Q12) | Accept→VisitZone→TurnIn PASS | ☑ **PASS MCP** |
| 2 | MCP smoke **112** TrailCamp (prereq Q1) | PASS | ☑ **PASS MCP** |
| 3 | Mini-chain smoke 109→loot (reuse WorldLoot, optional) | CONDITIONAL | ☑ **PASS MCP** (109 repeat, no WorldLoot step) |
| 4 | W2 non-regress **115** accept | PASS | ☑ **PASS MCP** |
| 5 | `quality_gate.py` | green | ☑ **PASS** (python3.12) |

### MCP smoke (Play/Server)

| Шаг | Результат |
|-----|-----------|
| `QuestSeedCompletedBF(player, {12})` | **PASS** |
| Accept **111** «Обзорный утёс» | **PASS** («Квест принят!») |
| `UpdateQuestProgressBF` VisitZone **Overlook** | **PASS** |
| TurnIn **111** | **PASS** («Квест сдан!») |
| `QuestSeedCompletedBF(player, {1})` | **PASS** |
| Accept **112** «Придорожный стан» | **PASS** |
| `UpdateQuestProgressBF` VisitZone **TrailCamp** | **PASS** |
| TurnIn **112** | **PASS** |
| Repeat **109** (optional mini-chain) | **PASS** |
| Seed **114** + Accept **115** (regress) | **PASS** («Квест принят!») |
| `QuestLocations` Overlook + TrailCamp (count=6) | **PASS** |

### SoT правки

Нет — smoke зелёный на существующих hooks W1–W2.

---

## W4 — Phase 2 exit + regress — **PASS MCP (2026-08-23)**

| # | Задача | Exit | Статус |
|---|--------|------|--------|
| 1 | Full line **107–112** catalog validate | `validate_quest_catalog.py` green | ☑ **PASS** |
| 2 | MCP smoke **107–112** Accept→VisitZone→TurnIn | seeds per quest | ☑ **PASS** |
| 3 | W2 chain **113→116** non-regress MCP | full BF chain | ☑ **PASS** |
| 4 | `quality_gate.py` | green | ☑ **PASS** (python3.12) |
| 5 | Hands: пешком Exit → ChestCluster → Мика | owner verify | ☐ owner |

### MCP smoke (Play/Server) — full scout line

| Шаг | Seed | Результат |
|-----|------|-----------|
| **107** ScoutPost | Q1 | **PASS** Accept→VisitZone→TurnIn |
| **108** Waystone | Q10 | **PASS** |
| **109** ChestCluster | Q1 | **PASS** |
| **110** ElementShrine | Q8 | **PASS** |
| **111** Overlook | Q12 | **PASS** |
| **112** TrailCamp | Q1 | **PASS** |

### MCP smoke — W2 chain regress

| Шаг | Результат |
|-----|-----------|
| Seed Q1 → **113** Exit → turn-in | **PASS** |
| **114** grant #101 → turn-in | **PASS** |
| **115** ScoutPost → turn-in | **PASS** |
| **116** grant #102 → turn-in | **PASS** |
| `QuestLocations` count=6 | **PASS** |

**SoT правки:** нет — W4 exit green на W1–W3 hooks.

---

## Phase 2 — **COMPLETE (2026-08-23)**

Exit criteria ☑ · W1–W4 MCP PASS · `validate_quest_catalog` + `quality_gate` green.

---

## Hands verify (owner)

1. **Ctrl+S** place.
2. W1: Q1 сдан → **109** у Мики → ChestCluster → turn-in.
3. W2 опц.: prereq Q10 → **108** Waystone; prereq Q8 → **110** ElementShrine.
4. W4: prereq Q1 → **107** ScoutPost у Exit.
5. Опц.: регресс **113→116** пешком после **114**.

## Next

- **Фаза 3** Commercial prep — [`ROADMAP-2026-08-23.md`](ROADMAP-2026-08-23.md) § Фаза 3
- Не параллелить **106 polish** track без явной команды
