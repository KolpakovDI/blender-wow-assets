# SESSION 2026-08-21b — Identity slice 2 (LOOK sync)

## Goal

После эволюции игрок **сразу видит** новый вид в UI (карточка/слоты/toast) и витрина обновляет mesh, если дух был выставлен.

## Changes (Studio SoT)

| Module | Change |
|--------|--------|
| `UIController` | Карточка: навыки из SkillCatalog / `GetSkillNames` (не «Коготь Духа» placeholders); слот 1 с ★ |
| `UIController` | `EvolutionSuccess`: toast `Old → New` + unlocked skill; слоты; **reopen** `OpenSpiritDetail` |
| `UIController` | Icon 1011 → 🐯 (отличие от кота 🔥) |
| `GameManager` | Evolve: обновляет `Showcase` entry Id/Name; `_G.RoS_ShowcaseOnSpiritEvolved` |
| `ResonanceShowcaseService` | `RoS_ShowcaseOnSpiritEvolved` → update entry + `rebuildCarousel` (mesh `SpiritTemplate1011`) |

## Edit verify

- skills 11 slot1 «Огненный коготь» vs 1011 «Огненный шторм» — diff true  
- mesh templates 11 / 1011 present  
- UI: emoji 🐯, reopen + Old→New toast wired; showcase hook present  

## Manual smoke

1. DevBoost / LeftAlt+B → Evolve  
2. Toast: «Огненный Кот → Огненный Тигр! Удар: Огненный шторм»  
3. Карточка открыта: имя Тигр, навыки с ★ на шторме; слот emoji 🐯  
4. Если дух на витрине — mesh 1011 без re-place  

## Docs

Mirrors: UIController, GameManager, ResonanceShowcaseService (+ SESSION / NEXT / CHANGELOG)

## Checkpoint

Сохранено в `SESSION-2026-08-21-checkpoint.md` + `NEXT-SESSION.md` (2026-08-21). Следующее: week wrap.
