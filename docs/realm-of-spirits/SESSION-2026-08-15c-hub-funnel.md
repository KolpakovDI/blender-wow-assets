# SESSION 2026-08-15c — Hub funnel instrumentation

**Статус:** **PASS** (код + Edit unit-smoke)  
**SoT:** Ctrl+S после патча

## Цель

Лёгкая серверная инструментация P0 hub funnel (GOALS KR Mika/Prep/Exit) без опросников.

## Решение

Модуль `ReplicatedStorage.RealmOfSpirits.HubFunnel`:

| Step | Когда |
|------|--------|
| `Mika` | `GetQuests` / успешный `AcceptQuest` |
| `Prep` | манга / гача / wardrobe |
| `ExitCombat` | переход зоны Safe→Combat |

- Первая отметка за UTC-день; поля на `playerData.HubFunnel`  
- `GetSnapshot` → `{ Mika, Prep, ExitCombat, Complete }`  
- `MarkPlayer` через `_G.GetPlayerData` (server authority)

## Файлы

- `HubFunnel.lua` (новый)  
- `QuestSystem`, `OtakuHavenService`, `ZoneSystem`, `DataStoreManager` (default/normalize)

## Smoke

Edit: Mark Mika→Prep→ExitCombat → `Complete=true`.

## Next

Publish DS smoke **или** hands e2e **или** читать `HubFunnel.GetSnapshot` в debug UI.
