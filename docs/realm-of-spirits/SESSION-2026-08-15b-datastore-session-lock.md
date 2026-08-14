# SESSION 2026-08-15b — DataStore session lock + UpdateAsync

**Статус:** **PASS** (код в SoT + mirror)  
**Place SoT:** Ctrl+S после патча

## Проблема

`DataStoreManager` писал через `SetAsync` без session lock → риск overwrite при двух серверах / race leave+autosave (gap `SESSION-2026-08-11`).

## Решение (raw DataStore, без полного ProfileService)

1. **Load** — `UpdateAsync`: если чужой `_Session` свежее `SESSION_LOCK_TIMEOUT` (1800с) → отказ, `_DoNotSave`  
2. Иначе пишем данные + `_Session = { JobId, PlaceId, Time }`  
3. **Save** — `UpdateAsync` только если lock наш/истёк; `releaseSession=true` на leave/`BindToClose` очищает `_Session`  
4. Autosave — `SaveData(player, false)` (lock renew)  
5. Retry backoff `0.5 * attempt`; `DeepCopy` / `StripEphemeral`

## Файлы

- Studio: `ServerScriptService.RealmOfSpirits.DataStoreManager`  
- Mirror: `docs/realm-of-spirits/studio/DataStoreManager.lua`

## Не закрыто

Publish place + API Services — без этого Studio остаётся in-memory (warn как раньше). Live round-trip — следующий ops-шаг.

## Next

Publish smoke **или** hands e2e / hub funnel (`PROJECT-COMPLETION.md` фаза 2).
