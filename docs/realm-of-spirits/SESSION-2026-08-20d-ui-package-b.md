# SESSION 2026-08-20d — UI пакет B

## Intent
Очередь: после UI A → **chip «следующий шаг»** (Мика → Exit → лут E).

## Done
- `StarterPlayerScripts.NextStepChip` LocalScript
- Chip сверху: `→ Поговори с Микой` → `Выход в Акихабару` → `Подбери лут у двери (E)` → скрыть
- Триггеры: QuestAccepted/OpenQuestUI/ActiveQuests; Zone Exit/Combat; FullSync funnel 101/102/120 или Haven Toast «Собран»/«Сундук»
- Серверные Remotes не менялись

## Smoke (Client Play)
| Check | Result |
|-------|--------|
| Chip GUI visible | yes |
| Combat zone → loot step | `→ Подбери лут у двери (E)` |

## Ctrl+S
Сохранить place.

## Next queue
UI пакет **C** (mobile / CD fill) или wrap недели; AI mesh — только после разморозки.
