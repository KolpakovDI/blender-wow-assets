# Realm of Spirits — Product Goals (locked 2026-07-14)

Источник развёртки: canvas `realm-goals-all-formats`.  
Связь с фичами: canvas `realm-features-inventory`.

**Порядок:** закрыть оба P0 → выбрать один P1 → Social после fair-combat policy → Scale только после метрик P0.

---

## P0 — Core loop до кайфа

**One-liner:** За 10 минут игрок ловит, побеждает и сдаёт квест без UI-глюков.

### SMART
- **S:** Спавн → квест у Мики → ловля в Akihabara → победа в бою (heal/эффект/3-й слот если есть) → сдача квеста + XP/монеты.
- **M:** ≥90% e2e (n≥10); 0 P0 багов EndBattle/UI; медиана ≤10 мин; ≥70% боёв с 2+ SkillIndex.
- **A:** Системы shipped; play-тест + фиксы + хинты + баланс CD/MP.
- **R:** Без цикла Collect→Battle→Quest нет смысла в хабе/$/PvP.
- **T:** 2 спринта play-теста после текущего place.

### OKR
- **O:** Первый боевой цикл надёжен и достоин показа.
- **KR1** Completion ≥90% · **KR2** 0 open P0 · **KR3** agency ≥70% · **KR4** median ≤10 мин.

### Питч
*Поймай. Сразись. Вырасти. За десять минут — уже герой.*

---

## P0 — Хаб как продукт

**One-liner:** Первые 60 секунд = «аниме-магазин», не пустое лобби.

### SMART
- **S:** Вход (колокол/генкан) → Мика (эмоция + Quest UI) → подготовка (манга/магазин) → Exit в Combat.
- **M:** ≥80% называют хаб магазином; ≥80% открывают Мику; ≥50% манга/магазин до Exit; BGM на 4 зонах.
- **A:** Гео/NPC есть; polish музыки, FOMO/гача feel, навигация к Exit.
- **R:** Haven — бренд vs generic collectors.
- **T:** 1–2 недели polish после стабильного core.

### OKR
- **O:** Otaku Haven — лицо продукта, не декорация спавна.
- **KR1** brand read ≥80% · **KR2** Mika funnel ≥80% · **KR3** prep ≥50% · **KR4** audio 4/4.

### Питч
*Уютный хаб. Опасный выход. Одна дверь между ними.*

---

## P1 — Explore имеет смысл

**One-liner:** Вылазка = лут/побочка, не пустой фарм XP.

### SMART
- Вылазка ≥3 мин → ≥1 лут или side-progress (≥70%); side 101–105 проходимы; ≥3 типа лута; первый лут ≤4 мин.

### OKR
- **O:** Combat-мир награждает за риск.
- **KR:** loot rate ≥70% · side 5/5 · loot diversity ≥3 · discovery ≤4 мин.

### Питч
*Исследуй. Подбери. Вернись сильнее.*

---

## P1 — Прогресс = идентичность

**One-liner:** Эволюция меняет бой и внешность; ранг — публичный milestone.

### SMART
- ≥80% эволюций дают Skill 3; первая эволюция ≤45 мин guided; ранг/следующий порог ≤2 клика.

### OKR
- **O:** «Я круче, чем вчера» = дух + ранг.
- **KR:** evo power ≥80% · evo pace ≤45 мин · rank clarity ≥70% · element agency demo.

### Питч
*Новая форма. Новый удар. Новый ранг.*

---

## P1 — Social / monetization (fair combat)

**One-liner:** Flex и гача в Safe; бой честный.

### SMART
- 0 pay items с Combat stats; gacha = cosmetics only; P2P trade MVP (1 slot).

### OKR
- **O:** Хаб = витрина статуса, не pay-to-win.
- **KR:** fair combat 0 · gacha clarity ≥80% · trade MVP ≥20 обменов в тесте · flex ≥30%.

### Питч
*Flex в Safe. Честный бой снаружи.*

---

## P2 — Масштаб после ядра

**One-liner:** Сначала идеальный PvE-цикл — потом арена, гильдии и сезоны.

### SMART / OKR
- Gate: P0 KR1–KR2 закрыты до старта PvP.
- 0 стартов PvP/guilds до закрытия P0; 1 vertical slice; season FOMO reuse Haven timer.

### Питч
*Сначала мастер. Потом легенда сервера.*

---

## Active focus (execution)

1. ~~P0 Core E2E~~ — OK.
2. ~~P0 Hub~~ — OK.
3. ~~P1 Identity~~ — OK (2026-07-15); **refresh 2026-08-21:** slice 1–3 PASS (slot-1 attack + LOOK UI/showcase + evo-progress card) — `SESSION-2026-08-21-checkpoint.md`.
4. ~~P1 Explore~~ — A/B/C PASS; **W3 diversity PASS** (2026-08-20b).
5. ~~P1 Social~~ — OK; **E4 live 2p PASS** (2026-08-19 user).
6. ~~Element agency demo~~ — OK (battle ×1.5/×0.7 + tip/лог 2026-07-29).
7. ~~Season polish~~ — OK (pity/DaysLeft/SoftBuffs/pool 101–115 2026-07-29).
8. **Next:** буфер / по указанию ведущего; Sanctum LOOK **PASS**; E1 = 3 цикла PASS / CONDITIONAL ×N руками; AI mesh **deferred**; PvP не стартовать.
9. **Буфер:** E1 live e2e ×N глазами всё ещё CONDITIONAL (не блокер продукта, но не «метрика ≥90% n≥10»).
