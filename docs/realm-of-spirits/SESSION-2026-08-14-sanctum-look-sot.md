# SESSION 2026-08-14 — Sanctum LOOK SoT smoke + parent mesh

## SoT smoke **PASS**

Place: `RealmOfSpirits second.rbxl` (не AutoRecovery).

SeedQA → ForceCatch → синтез:

- Status: `Ками-Корни vid #11 | Землетрясение * | …`
- Ростер: `[R]` у Resonant
- `ActiveSpiritName` = имя Ками
- Identity 1–3 на месте (1011 `{3,1,2}`)

## Parent mesh в UI **PASS**

После синтеза ViewportFrame `LookPreview` клонирует `SpiritMeshResolve` по `ParentIds`:

- `SpiritTemplate11`, `IsMeshPlaceholder=false`, `ResolvedTemplateId=11`
- Status: `Ками-Корни vid #11 | Пламенный всплеск * | …`

Не AI mesh. Шаблон ядра-родителя.

## Ctrl+S

SoT после viewport-патча нужно сохранить ещё раз.
