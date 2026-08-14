# SESSION 2026-08-21c — Identity slice 3 (evo progress card)

## Goal

В карточке духа видно **куда эволюционирует** и **сколько не хватает** (ур. / Bond / победы / кристаллы) + тизер удара слота 1.

## Changes

| Module | Change |
|--------|--------|
| `UIController` | `DetailEvoProgress` label; `ApplyEvoProgressUI` из `GetEvolutionRule` + Inventory/Stats |
| `UIController` | Кнопка Evolve только при полном `can`; иначе «Ещё рано» / «Макс. форма» |
| `UIController` | `EvolutionsList` тихо обновляет карточку (без toast «Доступно эволюций: N») |
| Layout | Frame ~410px; progress над кнопкой Evolve |

## Edit verify

- Rule 11 → Тигр, удар «Огненный шторм», need lvl10/bond3/wins10/cry5  
- 1011 = финальная форма (нет rule)  
- Helper + silent EvolutionsList wired  

## Manual

Открыть слот кота → строка `→ Огненный Тигр · удар «Огненный шторм»` + счётчики; после DevBoost кнопка золотая.

## Checkpoint

Сохранено в `SESSION-2026-08-21-checkpoint.md` + `NEXT-SESSION.md` (2026-08-21). Следующее: week wrap.
