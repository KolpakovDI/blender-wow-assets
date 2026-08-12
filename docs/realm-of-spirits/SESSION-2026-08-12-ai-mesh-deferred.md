# SESSION 2026-08-12 — AI mesh deferred + offline placeholder

## Intent
Implement **deferred** plan «AI Spirit Mesh Online»: no GenerationService; harden offline parent-clone + placeholder.

## Done
- `SpiritMeshResolve`: `CreatePlaceholder`, `CloneResolvedModel`
- `GameManager.CreateSpiritModel` → `CloneResolvedModel` (no silent nil)
- Docs: `SPIRIT-AI-MESH.md`, KAMI-SANCTUM, CHANGELOG, NEXT-SESSION
- Docs mirror Showcase `DisplayMesh` (live Showcase script layout differs — spawn path is SoT)

## Smoke (Edit)
| Check | Result |
|-------|--------|
| Clone ParentIds `{11,21}` | template 11, not placeholder |
| Clone ParentIds `{99999}` | placeholder `IsMeshPlaceholder=true` |
| GameManager uses CloneResolvedModel | yes |

## Not done (by plan)
- MeshGuid / Prompt / AssetId DataStore
- GenerationService / PromptCreateAssetAsync
- Sanctum «Сохранить меш» UI
- gen + publish + rejoin smoke

## Ctrl+S
Place: save after Studio Source edits.
