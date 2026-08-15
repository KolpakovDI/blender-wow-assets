# SESSION 2026-08-15e — Month W2 play-test KR (start)

**План:** `MONTH-PLAN-2026-08-15.md` W2  
**Place:** PlaceId=`130832500076229` (published)

## Вердикт

| # | Exit | Статус |
|---|------|--------|
| **M2.1** | E1 sample ≥5 | **PASS CONDITIONAL** — 5× MCP live-like бой (не руки WASD/F); `EnemiesDefeated=5` Lv3 |
| **M2.2** | HubFunnel день Mika+Prep+ExitCombat | **PASS** — `Complete=true` DayKey=`2026-08-15` |
| **M2.3** | P0 friction backlog | **PASS** — 3 пункта ниже |

## M2.2 evidence

- Mika: уже в DS с W1; GetQuests ок  
- ExitCombat: TP/вход Akihabara → `[HubFunnel] -> ExitCombat`  
- Prep: **E** у `MangaBuffStand` → `[HubFunnel] -> Prep`  
- Snapshot: `Mika=true Prep=true Exit=true Complete=true`

## M2.1 evidence (live-like)

| # | Цикл | Результат |
|---|------|-----------|
| 1–5 | TP к Огненный Кот → **V** + Keypad1/2 | все **«Вы победили!»** |
| Stats | после 5 боёв | Level **3**, Exp 0, EnemiesDefeated **5**, Spirits 2, Copper 100 |

Не полный Haven→квест→лут→лов→Ками ×5 глазами — MCP/TP/V/Keypad (как E1 CONDITIONAL).

## M2.3 P0 friction backlog → W3

1. **`RequestWardrobe` не вызывал `MarkHubPrep`** в SoT (manga/gacha — да; remote гардероба — нет). Docs уже имели Mark до Safe-check; SoT дрейфовал. **Fixed 15.08e** в `OtakuHavenService`.  
2. **MCP `character_navigation`** часто `Can not find a route` в Haven/мире — для live-like нужен CFrame TP.  
3. **Plugin noise** `user_RoS_ShortGrass` FEFF (внешний) — не блокер геймплея.

## SoT fix

`OtakuHavenService` `RequestWardrobe`: `MarkHubPrep(player)` перед `isInSafeZone`. **Ctrl+S**.

## Next

W3: топ friction (уже частично закрыт #1) + Kami hands без ForceCatch + agency 2+ skills. Не AI mesh / не PvP.
