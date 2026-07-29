# Fair Combat Policy (P1 Social)

**Статус:** locked 2026-07-18 · источник: `GOALS.md` P1 Social  

**One-liner:** Flex и гача в Safe; бой честный.

---

## Правила

### 1. Pay = Robux (и любые IAP)
За **Robux / Developer Products** нельзя получить ничего, что меняет исход боя:
- постоянные Attack / Defense / HP / Speed / Crit
- боевые расходники (зелья HP/MP, баффы урона)
- ловушки / свитки, ускоряющие catch→battle funnel сверх free-to-play темпа

**Разрешено за Robux:** только **cosmetics** (стикеры, фигурки, рюкзак-аксессуары, UI flex).

### 2. Гача
- Пул гачи (монеты **и** Robux) = **только cosmetics** (+ опционально cosmetic-only vanity).
- Медные монеты как consolation в coin-гаче допустимы (экономика хаба), но **не** combat items.
- FOMO-таймер — маркетинг коллекции, не power gate.

### 3. Магазин за внутриигровые монеты
- Shop (ловушки, зелья, свитки) = **copper/silver/gold**, заработанные в PvE.
- Это **не** pay-to-win, пока нет Robux→монеты exchange без лимита.
- Запрещено: Robux → combat shop items напрямую.

### 4. Бесплатные хаб-баффы
- Манга `MangaDamage` (+15% / 30 мин) — **бесплатно** в Safe; OK.
- Нельзя продавать тот же (или сильнее) бафф за Robux.

### 5. P2P Trade MVP
- Обмен **1 слот предмета** между игроками в Safe.
- Нельзя обменивать то, чего нет в инвентаре; сервер валидирует.
- Cosmetics и materials — да; будущие pay-locked exclusives — по отдельному whitelist.

### 6. PvP / гильдии
- **PvP Arena duel slice allowed** after Social PASS; rules: no Robux power, potions disabled in duel, reward copper-only, same skill formula both sides.

---

## Аудит 2026-07-18 (до фикса)

| Источник | Было | Вердикт |
|----------|------|---------|
| Gacha coin/Robux | ловушка / зелье / монеты / стикер | **FAIL** — combat items в pay-пуле |
| Shop | Id 1–3 за медь | PASS (earned currency) |
| Manga buff | free +15% | PASS |
| TradeSystem | только NPC shop | нет P2P ещё |
| Robux ProductId | `ZoneConfig.GachaRobuxProductId` | тот же пул → FAIL |

## После фикса гачи
Gacha → только cosmetics (редкость common/rare/legendary). Shop без изменений.

---

## KR (из GOALS)
- fair combat **0** нарушений pay→combat
- gacha clarity ≥80% (UI говорит «только косметика»)
- trade MVP: `SimulateSwap` item↔item + item↔cosmetic unit **PASS** 2026-07-29 (`/tradetest` + 2p Play optional)
- flex ≥30% (wardrobe equip в Safe)
- trade MVP ≥20 обменов в тесте (после P2P slice)
- flex ≥30% игроков с cosmetic equipped в Safe
