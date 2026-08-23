# NEXT SESSION

**Статус:** 2026-08-23 — Фаза 1 **COMPLETE** · **Фаза 2 W1 PASS** (quest **109** ChestCluster MCP)
**Следующий фокус:** **Фаза 2 W2** — smoke **108** Waystone + **110** ElementShrine

**Roadmap:** [`ROADMAP-2026-08-23.md`](ROADMAP-2026-08-23.md) · **Tracker:** [`SESSION-2026-08-23-phase2-scout-side.md`](SESSION-2026-08-23-phase2-scout-side.md)

## Старт сессии (порядок жёсткий)

1. **Ctrl+S** place → подтвердить SoT
2. **Фаза 2 W2:** MCP smoke **108** + **110** (prereq Q10 / Q8)
3. Не начинать B1 PvP / ProfileService / AI mesh / track 106 без явной команды

## Где остановились

| Область | Состояние |
|---------|-----------|
| **Фаза 2 W1** | **PASS MCP (2026-08-23)** — quest **109** Accept→VisitZone ChestCluster→TurnIn; QuestLocations×6; W2 regress 115 accept OK |
| **Scout line 107–112** | SoT inline `QuestSystem` ☑ · mirror `QuestCatalog` ☑ · hooks `ZoneConfig`/`WorldSpawner`/`ZoneSystem` ☑ |
| **Wayfind 109** | `EnsureChestClusterWayfind` у Exit ☑ |
| **Фаза 1** | **COMPLETE** — [`SESSION-2026-08-23-phase1-stabilization.md`](SESSION-2026-08-23-phase1-stabilization.md) |
| **B2 115→116** | **PASS** — non-regress spot W1 ☑ |

## Owner hands (W1 carry-over)

| # | Действие | Зачем |
|---|----------|-------|
| 1 | **Ctrl+S** place после Studio-сессии | SoT sync |
| 2 | Пешком **109:** Exit → ChestCluster marker → turn-in Мика | Hands verify W1 |
| 3 | Опц.: Publish + live DS (из Фазы 1 W4) | PlaceId≠0 |

## Backlog (Фаза 2)

| # | Срез | Когда |
|---|------|-------|
| **F2-W2** | Smoke **108** + **110** | **NEXT** |
| **F2-W3** | **111** + **112** | После W2 |
| **F2-W4** | Full line exit + quality_gate | Phase 2 close |
| **106 polish** | Альтернативный track | Только по явной команде |
| **B1** | PvP slice 3 | Только по явной команде |

## Studio SoT

`C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl`

**Mirror (F2 W1):** `ZoneConfig` · `ZoneSystem` · `WorldSpawner` · `QuestSystem` (inline) · `OtakuHavenBuilder` · `QuestUI` · `QuestCatalog`

## Не включать (до явной команды)

Allow* · Guilds · ProfileService live · Haven décor marathon · PvP combat stats · два major track параллельно

## Архив

Phase 1 W1–W4 **COMPLETE** · B2 hub2 · Quest 115→116 · Resonant · Month W1–W4 PASS · [`ROADMAP-2026-08-23.md`](ROADMAP-2026-08-23.md)
