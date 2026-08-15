# Spirit AI Mesh — статус

**Статус: ОТЛОЖЕНО (с 2026-08-01, подтверждено 2026-08-12)**  
Онлайн-генерацию мешей (`GenerationService` / `PromptCreateAssetAsync` → постоянный `MeshAssetId`) **не внедряем**, пока владелец явно не разморозит план.

Place SoT: `C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl`

---

## Year plan Q4 (2026-10 roadmap)

См. [`YEAR-PLAN-2026-10.md`](YEAR-PLAN-2026-10.md). Online AI mesh — **Q4 only**, после:

1. Hands E1 ≥90% n≥10 **или** явный skip владельца  
2. Q1–Q2 quest/landscape exit  
3. Фраза владельца: **«разморозить AI mesh»**

До разморозки: офлайн 4×4 + `SpiritMeshResolve` placeholder. Код online path не стартовать в Q1–Q3.

---

## Когда размораживать online (очередь развития)

Не раньше, чем:

1. Explore **W3** не красный (diversity / discovery ок или явный CONDITIONAL без Critical).  
2. **UI пакет A** сделан или сознательно skip (иначе AI-тосты утонут в шуме).  
3. Владелец явно: **«разморозить AI mesh»**.  

Идеальный соседний фокус: **Sanctum / Resonant / Identity-вид** — там уникальный меш даёт смысл. До разморозки остаёмся на офлайн 4×4 + ParentIds + placeholder (`CloneResolvedModel`).

Очередь целиком: `WEEK-PLAN-2026-08-19.md` → § «Очередь когда гармонично».

---

## Что работает сейчас (офлайн)

| Шаг | Поведение |
|-----|-----------|
| Канон 4×4 | Меши в `ReplicatedStorage.SpiritTemplates` (`SpiritTemplate{Id}`) — Studio / Blender офлайн |
| Resonant | Нет своего `SpiritTemplate9xxx` |
| Resolve | `SpiritMeshResolve`: Id → иначе первый `ParentIds` с шаблоном → иначе **геометрический placeholder** |
| Spawn | `GameManager.CreateSpiritModel` → `CloneResolvedModel` (больше не `return nil` без меша) |
| UI иконки | `IconLookupId` — те же кандидаты Id / ParentIds |

Модуль: `ReplicatedStorage.RealmOfSpirits.SpiritMeshResolve`  
Зеркало: `docs/realm-of-spirits/studio/SpiritMeshResolve.lua`

Placeholder помечается атрибутом `IsMeshPlaceholder = true` (neon + glass orb). Это **не** AI и **не** публикуется в Toolbox.

---

## Что НЕ делаем (cancelled / deferred)

1. Поля `MeshGuid` / `Prompt` / `Status` / `MeshAssetId` + миграция DataStore  
2. `SpiritMeshPromptBuilder`  
3. `SpiritMeshGenerationService` (`GenerateModelAsync` Body1, session cache)  
4. `SpiritMeshPublishService` (`PromptCreateAssetAsync`)  
5. Хук Sanctum «Сохранить меш» + publish UI  

Когда разморозим: цепочка AssetId → session cache → placeholder остаётся fallback после online path. См. Cursor plan `AI Spirit Mesh Online` (reference only).

---

## Smoke (офлайн, без gen/publish)

1. Edit: `CloneResolvedModel({ParentIds={11}})` → template 11, `IsMeshPlaceholder=false`  
2. Edit: `CloneResolvedModel({ParentIds={99999}})` → placeholder, `IsMeshPlaceholder=true`  
3. Play: Kami SeedQA → Synthesize Resonant с родителями, имеющими шаблон → видимый меш родителя (или placeholder)  
4. **Ctrl+S** place после правок Studio  

Gen + publish + rejoin **не** в scope, пока статус ОТЛОЖЕНО.

---

## Связанные доки

- `KAMI-SANCTUM.md` — меш Resonant  
- `NEXT-SESSION.md` — не стартовать AI mesh как основной фокус  
- CHANGELOG `[Unreleased]` — блок offline placeholder  
