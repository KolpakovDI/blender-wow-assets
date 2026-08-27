# SESSION — Owner unlock (2026-08-27) — **PAUSED**

**Mode:** **PAUSED / GATED** — cutover **не default next**; readiness **NOT READY** (2026-08-27) · owner unlock по readiness PASS (агент предлагает) или «проект готов» / «owner unlock»  
**Checklist SoT:** [`OWNER-UNLOCK.md`](OWNER-UNLOCK.md)  
**Place SoT:** `C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl` — **Ctrl+S** после каждого шага  
**Prior live (Ф1):** PlaceId=`130832500076229` · GameId=`10713581476` · CreatorId=`10160129951`

> **Publish suggestion policy:** агент предлагает Publish **только** при readiness **PASS** ([`NEXT-SESSION.md`](NEXT-SESSION.md) § Readiness assessment). Сейчас **NOT READY**.

---

## Exit criteria (owner unlock track)

| # | Критерий | PASS | CONDITIONAL | Статус |
|---|----------|------|-------------|--------|
| 1 | Place SoT сохранён (Ctrl+S) | файл синхронизирован с Studio | — | ☐ deferred |
| 2 | Publish + API Services | PlaceId≠0 · нет DS-unpublished warn · `liveBlocked=false` | PlaceId match prior live | ☐ **deferred** (шаг 2–7) |
| 3 | Live DS rejoin (DSM) | Stop→Play round-trip spirits/inv/quest | prior F1 PASS + new rejoin | ☐ **deferred** |
| 4 | DevProduct + GachaRobuxProductId + live R | cosmetics-only · idempotent receipt | Studio copper only | ☐ **deferred** |
| 5 | ProfileService triple gate | ShouldUse=true · PS rejoin | — | ☐ **deferred** |
| 6 | AllowGuilds | CreateOrJoin + bank live | — | ☐ **deferred** |
| 7 | AllowNewPvPFeatures | Rated APIs live | — | ☐ **deferred** |

**Agent policy:** Allow* **не флипать** · Publish/DevProduct/gate attrs = **owner hands only** · «дальше» без readiness PASS = regression smoke, **не** Publish suggestion · readiness **PASS** → агент **может** предложить owner unlock (optional).

---

## Studio audit log

| Время | PlaceId | GameId | GachaRobuxProductId | Allow* | Аудиты | Агент |
|-------|---------|--------|---------------------|--------|--------|-------|
| 2026-08-27 (prep) | **0** | **0** | **0** | all **false** | F4-W4-prep · W13 GateAllows=false · W18 DevOnly=true | read-only |
| 2026-08-27 («дальше») | **0** | **0** | **0** | all **false** | same · paths ☑ | read-only MCP |
| 2026-08-27 (policy) | **0** | **0** | **0** | all **false** | same | owner unlock **PAUSED** |

**Paths verified (Studio = mirror convention):**

| Module | Studio path | Mirror |
|--------|-------------|--------|
| ExpansionGate | `ReplicatedStorage.RealmOfSpirits.ExpansionGate` | `studio/ExpansionGate.lua` ☑ |
| ZoneConfig | `ReplicatedStorage.RealmOfSpirits.ZoneConfig` | `studio/ZoneConfig.lua` ☑ (`GachaRobuxProductId=0`) |
| Realm attrs | `ServerScriptService.RealmOfSpirits` | attr flip target шаги 5–7 |

---

## Step tracker (owner hands 1→3) — **DEFERRED**

| Шаг | Действие | Кто | PASS | CONDITIONAL | Статус | Evidence |
|-----|----------|-----|------|-------------|--------|----------|
| **1** | Ctrl+S place SoT | Owner | файл сохранён | — | ☐ deferred | — |
| **2a** | Publish to Roblox | Owner | PlaceId=`130832500076229` | другой live place | ☐ deferred | — |
| **2b** | Enable API Services | Owner | Security ON | — | ☐ deferred | — |
| **2c** | Play published place | Owner | `[Persistence] liveBlocked=false` | backend=DataStoreManager | ☐ deferred | — |
| **3a** | Seed (ForceCatch + item + Q113) | Owner / MCP | spirits+1 · item 320 · Q113 turn-in | in-session only | ☐ deferred | — |
| **3b** | Stop → Play rejoin | Owner | `данные загружены` · persist | alt account clean smoke | ☐ deferred | — |
| **3c** | Agent MCP verify | Agent | snapshot match pre-stop | best-effort | ☐ deferred | — |

---

## Шаги 2–7 — deferred (не начинать без «проект готов»)

См. [`OWNER-UNLOCK.md`](OWNER-UNLOCK.md) для полных рецептов. Активация: «проект готов» / «owner unlock» / «owner unlock step N».

---

## Post-flip prep (шаги 4–7 — deferred)

| Шаг | Flip target | Mirror / Studio | Blocked until |
|-----|-------------|-----------------|---------------|
| 4 | `ZoneConfig.GachaRobuxProductId` | `studio/ZoneConfig.lua` L177 | owner unlock activated + шаг 2 PASS |
| 5 | `AllowProfileService` + `Enabled` + `UseProfileServiceAdapter` | SSS attrs + `ProfileServiceAdapter` | шаг 3 PASS |
| 6 | `AllowGuilds=true` | SSS attr | шаг 5 stable |
| 7 | `AllowNewPvPFeatures=true` | SSS attr | шаг 6 or owner skip |

---

## Журнал сессии

| Дата | Действие | Результат |
|------|----------|-----------|
| 2026-08-27 | Owner command: start unlock track | OWNER-UNLOCK.md + NEXT-SESSION mode |
| 2026-08-27 | MCP audit (prep) | PlaceId=0 · gates OFF · audits PASS |
| 2026-08-27 | «дальше» — tracker + smoke recipes | SESSION-2026-08-27-owner-unlock.md · OWNER-UNLOCK § smoke · paths ☑ |
| 2026-08-27 | Owner: проект не готов — не предлагать Publish | **PAUSED** · DEV-ONLY restored · steps 2–7 deferred |
| 2026-08-27 | Owner policy update: agent **may** suggest Publish when readiness PASS | readiness checklist in NEXT-SESSION + OWNER-UNLOCK · current verdict **NOT READY** |

---

## Next (default — не owner unlock)

**Default «дальше»:** post-W18 regression smoke (Smoke*Mock suite + core loop) + fix-only — см. [`NEXT-SESSION.md`](NEXT-SESSION.md).

**Owner unlock resume:** readiness **PASS** (агент предлагает) **или** «проект готов» / «owner unlock» → шаг 1 (Ctrl+S) → шаг 2 (Publish).
