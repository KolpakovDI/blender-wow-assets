# Risks & Mitigations — Year expansion C+A

Связь: [`YEAR-PLAN-2026-10.md`](YEAR-PLAN-2026-10.md) · gate-код: `studio/ExpansionGate.lua`

## Риски плана → купирование

| Риск | Купирование (сделано) | Как проверить |
|------|------------------------|---------------|
| Монолит `QuestSystem` снова раздуется | Данные только в `QuestCatalog`; `validate_quest_catalog.py` падает, если снова `local QuestDatabase` | `python scripts/quality_gate.py` |
| `continue` / хрупкий Luau | GetAvailableQuests на `if not Deprecated` | тот же gate |
| Ландшафт без квестовых якорей | Каждая `ZoneConfig.QuestLocations.*` обязана иметь VisitZone-квест; gate проверяет orphans | gate + Play VisitZone |
| AI mesh / ProfileService раньше E1 | `ExpansionGate` defaults **false**; ProfileServiceAdapter + SpiritMeshGenerationService отказывают без gate | `/expansiongate` в Studio; gate asserts |
| Гильдии раньше Q4 | `GuildSystem.CreateOrJoin` → `AssertGuildsAllowed()` | `/guild` пишет blocked |
| PvP power creep | `WIN_COPPER=0`; rated hooks → `AllowNewPvPFeatures` | fair_combat / pvp sanity |
| ScoutQuestor мёртвый UI | `_G.RoS_OpenQuestUI` в QuestSystem; Scout вызывает его | E у разведчика |

## Unlock (только владелец после E1)

На `ServerScriptService.RealmOfSpirits` атрибуты (bool):

- `AllowGuilds`
- `AllowProfileService` (+ `UseProfileServiceAdapter` и `ProfileServiceAdapter.Enabled`)
- `AllowAiMeshOnline` (+ `SpiritMeshGenerationService.OnlineEnabled`)
- `AllowNewPvPFeatures`

Без атрибутов всё остаётся **закрыто**.

## Quality gate

Добавлен `scripts/validate_quest_catalog.py` в `quality_gate.py`.
