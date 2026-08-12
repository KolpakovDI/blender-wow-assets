# SESSION 2026-08-20c — UI пакет A

## Intent
Очередь: после Explore W3 → **UI пакет A** (toast queue + теги «зачем» в сумке).

## Done
- `ReplicatedStorage.RealmOfSpirits.ToastRouter` — Critical > Reward > Tip; один toast на экране
- Wired: `UIController.ShowNotification`, `ZoneController.showToast`, `OtakuHavenController.showToast`
- `ItemCatalog.GetWhyTag` — Material→эволюция, Quest→квест Мики, Sanctum→святилище, Catch→ловля, зелье→бой
- Сумки: `Имя · тег xN`

## Smoke (Client)
| Check | Result |
|-------|--------|
| GetWhyTag 101 | эволюция |
| GetWhyTag 120 | квест Мики |
| GetWhyTag 1 | ловля |
| ToastRouter.Notify | function |

## Ctrl+S
Сохранить place.

## Next queue
UI пакет **B** (chip «следующий шаг») — по WEEK-PLAN после стабильного A.
