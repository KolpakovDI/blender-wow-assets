# Realm of Spirits Automation

Локальные и CI-проверки для боевой системы и базы духов.

## Что включено

- `scripts/validate_spirit_database.py`
  - проверяет `SpiritDatabase.Spirits`: дубликаты id, `Name/BaseStats/CatchRate`,
    `SkillIds` ↔ `SkillCatalog.ById`, `MovementType` Walk/Fly.
- `scripts/battle_sanity_check.py`
  - проверяет наличие критичных блоков в боевом рантайме (`GameManager`) и UI (`UIController`),
    чтобы ловить регрессии по выходу из боя и динамическим скилам.
- `scripts/fair_combat_check.py`
  - fair-combat / P1 Social: gacha → только `Cosmetics`, UI disclaimer,
    Flex wardrobe tokens, `ItemCatalog.CombatUtility`, P2P trade Safe MVP,
    presence `FAIR-COMBAT.md` (по docs mirrors в `docs/realm-of-spirits/studio/`).
- `scripts/roblox_upload_model.py` + `scripts/blender_export_for_roblox.py`
  - Blender → FBX/GLB → Open Cloud **Model** → `assetId` → Studio `insert_asset`
  - Env: `ROBLOX_OPEN_CLOUD_API_KEY` + `ROBLOX_USER_ID` (или `ROBLOX_GROUP_ID`)
  - Skill: `realm-mesh-from-prompt` (Blender-first; не Studio `generate_mesh`)
- `scripts/quality_gate.py`
  - объединяет проверки выше в один gate (exit code 1 при ошибках).

## CI

GitHub Actions:

- `.github/workflows/realm-quality-gate.yml`
  - запускает `python scripts/quality_gate.py` на `push` (`main/master`) и `pull_request`.

## Cursor hooks profiles

- `.cursor/hooks.dev.json` — мягкий режим (fail-open), удобен в активной разработке.
- `.cursor/hooks.strict.json` — строгий режим (fail-closed), блокирует поток при падении hook-команд.
- `.cursor/hooks.json` — активный профиль (файл, который читает Cursor).

### Переключение профиля

```bash
python scripts/switch_hooks_profile.py dev
python scripts/switch_hooks_profile.py strict
```

### Примечание

После переключения профиля Cursor подхватывает изменения `hooks.json` автоматически,
но если поведение не обновилось — перезапусти Cursor.
