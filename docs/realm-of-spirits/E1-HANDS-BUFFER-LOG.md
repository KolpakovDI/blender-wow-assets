# E1 Hands Buffer Log — formal n≥10

**Цель:** ≥90% успешных **полных циклов** при **n≥10**, только руками (WASD / **E** / **F** / **1** / **2**).  
**Place:** `C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl`  
**Трек:** Phase 1 W1 — [`SESSION-2026-08-23-phase1-stabilization.md`](SESSION-2026-08-23-phase1-stabilization.md) · [`ROADMAP-2026-08-23.md`](ROADMAP-2026-08-23.md)  
**Предыдущий PASS:** user hands 2026-08-23 — [`SESSION-2026-08-23-e1-hands-buffer.md`](SESSION-2026-08-23-e1-hands-buffer.md)  
**Связанные логи:** архив friction + OWNER SKIP — [`E1-HANDS-LOG.md`](E1-HANDS-LOG.md)

---

## W1 checklist (Phase 1 — перед каждым run)

- [ ] **Ctrl+S** place → Local Server, 1 игрок → **Play**
- [ ] Output без красных ошибок при старте
- [ ] Полный цикл по таблице шагов ниже (шаги 2→6→8)
- [ ] Отметить Run# в таблице: Date, F→battle, E→exit, skills 1/2, Resonant (опц.), PASS/FAIL, Notes
- [ ] **Не fabricate** — только реальные прогоны
- [ ] После 10 runs: PASS rate ≥90% **или** owner skip → SESSION

---

## Что считается «полным циклом»

Один **full cycle** = игрок проходит весь путь без MCP-костылей, от Haven до возврата в Haven:

| # | Шаг | Клавиши / действие | PASS критерий |
|---|-----|-------------------|---------------|
| 1 | **Ctrl+S** → **Play** (Local Server, 1 игрок) | — | Place сохранён, нет красных ошибок в Output |
| 2 | Haven → **Мика** | **E** → принять квест (Q1 или актуальный story/side) | Квест в трекере, нет «мёртвой» кнопки Accept |
| 3 | (Опц.) манга / Магазин | **E** | Не блокирует цикл |
| 4 | **Exit → Combat** | пешком / **E** у выхода | Зона Combat/Akihabara, трекер не врёт |
| 5 | Мир: лут / ловля | **E** | Прогресс квеста или ловля без soft-lock |
| 6 | **Бой** | **F** + навыки **1** и **2** | Бой стартует, ≥2 навыка в бою, победа или честный проигрыш без P0 |
| 7 | (Опц.) **Resonant / Sanctum** | Open Sanctum, synth/disintegrate, `[R]` в Dex | Не обязательно каждый run; отметить в колонке |
| 8 | **Сдача** → Haven | **E** у Мики → TurnIn | XP/монеты/лут, нет P0 |
| 9 | **Возврат в Haven** | портал / Exit обратно | Игрок снова в Otaku Haven |

**PASS** = шаги 2→6→8 без P0 (зависание UI, потеря инвентаря, невозможность сдать/выйти из боя).  
**FAIL** = любой P0 или использование читов (TP, ForceCatch, SeedQA, remote-only Accept/Catch/Attack).

**Не считать:** MCP V/Keypad, TP, BF без рук, `/tradetest` / `/pvpqa` (это Q3 verify, не E1).

---

## Метрика выхода

| Метрика | Gate |
|---------|------|
| Runs заполнено | **n ≥ 10** |
| PASS rate | **≥ 90%** (≤1 FAIL на 10) |
| Навыки в бою | **≥ 70%** runs с **1+2** (отметка в колонке) |
| P0 после буфера | **0** open (иначе fix-only, не новый scope) |

При **≥90% PASS** → обновить [`E1-HANDS-LOG.md`](E1-HANDS-LOG.md) итогом и закрыть KR1 в GOALS.  
При **<90%** → список FAIL в Notes + fix-only до следующей партии.

---

## User hands summary (2026-08-23)

| Поле | Значение |
|------|----------|
| Дата | **2026-08-23** |
| Источник | **user hands PASS (self-reported)** — «pass» после month wrap + Q3 slice 3 |
| Run-by-run | **не заполнено** — детальная таблица Run#1…10 не велась; не fabricate |
| MCP smoke | **PASS** (2026-08-23, см. ниже) |
| Вердикт | **PASS (user hands)** — принято как закрытие E1 buffer backlog |

> Формальный gate n≥10 / ≥90% в таблице ниже **не достигнут по данным**, но owner подтвердил hands **PASS**. Для регрессии при необходимости — новая партия runs в таблице.

---

## Таблица прогонов

| Run# | Date | F→battle | E→exit | skills 1/2 | Resonant/Sanctum | PASS/FAIL | Notes |
|------|------|----------|--------|------------|------------------|-----------|-------|
| 1 | | ☐ | ☐ | ☐ | ☐ | | |
| 2 | | ☐ | ☐ | ☐ | ☐ | | |
| 3 | | ☐ | ☐ | ☐ | ☐ | | |
| 4 | | ☐ | ☐ | ☐ | ☐ | | |
| 5 | | ☐ | ☐ | ☐ | ☐ | | |
| 6 | | ☐ | ☐ | ☐ | ☐ | | |
| 7 | | ☐ | ☐ | ☐ | ☐ | | |
| 8 | | ☐ | ☐ | ☐ | ☐ | | |
| 9 | | ☐ | ☐ | ☐ | ☐ | | |
| 10 | | ☐ | ☐ | ☐ | ☐ | | |
| 11 | | ☐ | ☐ | ☐ | ☐ | | *(опц. буфер)* |
| 12 | | ☐ | ☐ | ☐ | ☐ | | *(опц. буфер)* |

**Колонки:**
- **F→battle** — бой начался по **F** (не только HUD-клик)
- **E→exit** — выход Haven→Combat через Exit / зону (не TP)
- **skills 1/2** — оба слота использованы в одном бою
- **Resonant/Sanctum** — опц.: synth/disintegrate/`[R]` в Dex в этом run
- **Notes** — квест id, время (мин), симптом FAIL

---

## MCP smoke (не заменяет hands)

Перед партией n≥10 — один **короткий** MCP/Edit smoke (агент или dev):

- `SkillCatalog` / `ItemCatalog` / `CombatAnimResolver` require **PASS**
- `QuestMaster` в Workspace **PASS**
- `ExitZone` + `ShopExit` + `BattleArena` **PASS**
- Server: `QuestSystem` / `GameManager` / `BattleSystem` Scripts live; `PvPDuelSystem` + `PlayerTradeSystem` require **PASS**

Последний MCP smoke: **2026-08-23 Phase 1 W1** — **PASS** (SkillCatalog, ItemCatalog, KamiSanctumSystem, QuestMaster, OtakuHaven, BattleArena, PvP/Trade).

---

## Регресс ядра (не ломать month PASS)

После каждых 3–5 runs или при FAIL — один sanity check:

- Quest **304** / Sanctum open на 2 ур.
- Side **113→114** не красный (VisitZone + crystal 101)
- Dex `[R]` строка видна после Resonant synth
- Q3 slice 3 не регрессит (wayfind copy, trade modules load)

---

## Итог (заполнить после n≥10)

| Поле | Значение |
|------|----------|
| Даты прогонов | **2026-08-23** (user summary; run-by-run — n/a) |
| PASS / FAIL | **PASS** / 0 FAIL (self-reported) |
| % completion | **PASS (user hands)** — formal n≥10 table не заполнена |
| Вердикт | **PASS (user hands)** — закрыто 2026-08-23 · [`SESSION-2026-08-23-e1-hands-buffer.md`](SESSION-2026-08-23-e1-hands-buffer.md) |
