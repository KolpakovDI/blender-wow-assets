# Spirit Resonance — план реализации

Статус: **Phase 4 Studio + Resonance quests 301–302 player PASS** · 2026-07-27  
SoT: `RealmOfSpirits second.rbxl` · зеркала: `docs/realm-of-spirits/studio/`

Цель: 5 треков прокачки духов для D1→D7→D30 ретеншена.

---

## Треки

| ID | Трек | Статус | Модуль / точка входа |
|----|------|--------|----------------------|
| A | Боевой рост | **Studio wired** | `SpiritResonance.GrantBattleXp` ← `GameManager.EndBattle` |
| B | Bond / Резонанс | **PASS** (Care pedestal live-build) | Care pedestal + UI + `ResonanceEvent` |
| C | Temper / Закалка | **PASS** (Temper pedestal + 302) | Picker + battle bonuses + weekly 303 |
| D | Dex / коллекция | **Studio** · Showcase prompt hardened | Dex UI + battle ATK%/DEF% + Showcase |
| E | Evo 2.0 + сезон | **Studio** · unit smoke OK | Seasonal form + Activity Pass + crystal pity |

---

## Фазы

### Phase 0 — Foundation
- [x] Foundation (см. историю)

### Phase 1 — Haven ritual (D1–D7)
- [x] Care pedestal, VFX, activity bar, QuestTracker + 301

### Phase 2 — Temper depth (D14–D30)
- [x] Temper picker UI (АТАКА / ЗАЩИТА / ДУХ) + пьедестал у Мики (`ResonanceTemperService` → `OpenTemperPicker`)
- [x] Temper bonuses in battle (`BattleOrchestrator.applyTemperDamage` / `applyTemperHeal`)
- [x] Weekly Temper challenge — quest **303** (3× TemperSpirit, prereq 302)

### Phase 3 — Dex + social (D30)
- [x] Dex UI panel (`DEX` на Resonance activity bar) + `GetDex` / `DexBonus`
- [x] Dex battle passives (`battle.DexAttackPct` / `DexDefensePct` в `BattleOrchestrator`)
- [x] Haven Showcase billboard (`ResonanceShowcaseService`, южнее Мики)

### Phase 4 — LiveOps (D30–D90)
- [x] Seasonal form flag (`spirit.SeasonalFormId`, shop `seasonal_form`, BP L4, +5% BondXp)
- [x] Activity Pass UI (`PASS` в `OtakuHavenController` + `SeasonLiveOps.GetClientSnapshot`)
- [x] Crystal pity counter (10 misses → force drop; бой + сундуки)

## Баланс Temper → бой

| Фокус | Бонус |
|-------|--------|
| Attack | +0.5 урона за очко |
| Defense | −0.4 входящего за очко |
| Spirit | +0.25 к хилу за очко |

## Баланс Dex → бой

| Сет стихии | Бонус |
|------------|--------|
| 3 духа | +2% ATK |
| 6 духов | +3% DEF |
| 12 духов | +3% ATK и +3% DEF |

## LiveOps (Phase 4)

| Механика | Детали |
|----------|--------|
| Crystal pity | 28% дроп с боя/сундука; после **10** промахов — гарант |
| Seasonal form | 50 жетонов или BP need 600; +**5%** BondXp |
| Pass XP | Care +15 / Temper +20 / бой +5 |

## Play smoke (Phase 4)

1. **PASS** → жетоны, XP, pity счётчик
2. Бой/сундук → кристалл или рост Misses
3. Купить сезонную форму → Bond уход чуть быстрее
