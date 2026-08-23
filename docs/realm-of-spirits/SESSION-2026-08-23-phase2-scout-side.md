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
| 1 | 1 side chain Accept→TurnIn PASS | ☐ W1: **109 PASS** MCP; полная линия 108–112 — W2–W4 |
| 2 | Регресс W2 (113→114, 115→116) не красный | ☑ **PASS** spot-check 115 accept MCP W1 |
| 3 | QuestLocations + VisitZone hooks в SoT | ☑ W1 |

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

**Mirror sync:** `OtakuHavenBuilder.lua` (EnsureChestClusterWayfind); `QuestCatalog.lua` уже содержал 108–112.

---

## W2 — Quest 108 + 110 (VisitZone polish)

| # | Задача | Exit |
|---|--------|------|
| 1 | Hands/MCP smoke **108** Waystone (prereq Q10) | Accept→VisitZone→TurnIn PASS |
| 2 | Hands/MCP smoke **110** ElementShrine (prereq Q8) | PASS |
| 3 | Wayfind optional: StoneBasin / FrostRidge hints | Ensure* только при hands FAIL |

---

## W3 — Quest 111 + 112

| # | Задача | Exit |
|---|--------|------|
| 1 | MCP smoke **111** Overlook (prereq Q12) | PASS |
| 2 | MCP smoke **112** TrailCamp | PASS |
| 3 | Mini-chain smoke 109→loot (reuse WorldLoot, optional) | CONDITIONAL |

---

## W4 — Phase 2 exit + regress

| # | Задача | Exit |
|---|--------|------|
| 1 | Full line **107–112** catalog validate | `validate_quest_catalog.py` green |
| 2 | W2 chain **113→116** non-regress MCP | PASS |
| 3 | `quality_gate.py` | green |
| 4 | Hands: пешком Exit → ChestCluster → Мика | owner verify |

---

## Hands verify (owner, W1)

1. **Ctrl+S** place.
2. Q1 сдан → принять **109** «Сундучный грот» у Мики.
3. Выйти Exit → следовать знаку «ChestCluster · восток от Exit» → войти в зону «Сундучный грот» (marker).
4. Сдать **109** у Мики.
5. Опц.: регресс **115** после **114** — синие знаки обхода.

## Next

- **W2:** smoke **108** + **110**; hands wayfind StoneBasin / FrostRidge
- Не параллелить **106 polish** track
