# NEXT SESSION

**Статус:** 2026-08-23 — Фаза 1 **COMPLETE** · **Фаза 2 W2 PASS** (quests **108** + **110** MCP)
**Следующий фокус:** **Фаза 2 W3** — smoke **111** Overlook + **112** TrailCamp

**Roadmap:** [`ROADMAP-2026-08-23.md`](ROADMAP-2026-08-23.md) · **Tracker:** [`SESSION-2026-08-23-phase2-scout-side.md`](SESSION-2026-08-23-phase2-scout-side.md)

## Старт сессии (порядок жёсткий)

1. **Ctrl+S** place → подтвердить SoT
2. **Фаза 2 W3:** MCP smoke **111** + **112** (prereq Q12 / Q1)
3. Не начинать B1 PvP / ProfileService / AI mesh / track 106 без явной команды

## Где остановились

| Область | Состояние |
|---------|-----------|
| **Фаза 2 W2** | **PASS MCP (2026-08-23)** — **108** Waystone (seed Q10) + **110** ElementShrine (seed Q8); regress 115 accept OK; mirrors W1 synced |
| **Фаза 2 W1** | **PASS MCP** — quest **109** ChestCluster |
| **Scout line 107–112** | SoT inline `QuestSystem` ☑ · mirror `QuestCatalog` ☑ · hooks ☑ |
| **Wayfind 109** | `EnsureChestClusterWayfind` у Exit ☑ |
| **Wayfind 108/110** | Ensure* StoneBasin/FrostRidge — **не нужны** (MCP PASS без hints) |
| **Фаза 1** | **COMPLETE** |
| **B2 115→116** | **PASS** — non-regress spot W1+W2 ☑ |

## Owner hands (carry-over)

| # | Действие | Зачем |
|---|----------|-------|
| 1 | **Ctrl+S** place после Studio-сессии | SoT sync |
| 2 | Пешком **109:** Exit → ChestCluster → Мика | Hands verify W1 |
| 3 | Опц.: пешком **108** Waystone / **110** ElementShrine | Hands verify W2 |
| 4 | Опц.: Publish + live DS (из Фазы 1 W4) | PlaceId≠0 |

## Backlog (Фаза 2)

| # | Срез | Когда |
|---|------|-------|
| **F2-W3** | Smoke **111** + **112** | **NEXT** |
| **F2-W4** | Full line exit + quality_gate | Phase 2 close |
| **106 polish** | Альтернативный track | Только по явной команде |
| **B1** | PvP slice 3 | Только по явной команде |

## Studio SoT

`C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl`

**Mirror (F2 W2):** `ZoneSystem` · `WorldSpawner` · `ZoneConfig` · `QuestUI` (Studio dump) · `QuestCatalog` 108–112 · `QuestSystem` git = QuestCatalog require (SoT Play inline) · W1 `OtakuHavenBuilder`

## Не включать (до явной команды)

Allow* · Guilds · ProfileService live · Haven décor marathon · PvP combat stats · два major track параллельно

## Архив

Phase 1 W1–W4 **COMPLETE** · B2 hub2 · Quest 115→116 · Resonant · Month W1–W4 PASS · [`ROADMAP-2026-08-23.md`](ROADMAP-2026-08-23.md)
