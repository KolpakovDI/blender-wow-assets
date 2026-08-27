# Owner Unlock — Realm of Spirits

> **DEV-ONLY default · Publish suggestion gated on readiness**
>
> **Режим:** **PAUSED / GATED** — cutover track **не default next**  
> **Активация:** (a) агент: readiness checklist **PASS** → **предложить** owner unlock (владелец решает) · (b) явная команда — «проект готов» · «owner unlock» · «owner unlock step N»  
> **Предусловие:** Ф4 W1–W18 numbered track **PASS** · Ф3 **COMPLETE CONDITIONAL** · все `Allow*=false` · [`NEXT-SESSION.md`](NEXT-SESSION.md) § Readiness assessment **PASS**  
> **Place SoT:** `C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl` — **Ctrl+S** после каждого шага  
> **Связанные треки:** [`SESSION-2026-08-23-phase3-commercial-prep.md`](SESSION-2026-08-23-phase3-commercial-prep.md) · [`SESSION-2026-08-23-phase4-scale.md`](SESSION-2026-08-23-phase4-scale.md) § W4 OwnerFlipChecklist · **Tracker:** [`SESSION-2026-08-27-owner-unlock.md`](SESSION-2026-08-27-owner-unlock.md)

---

## Политика агента

| Правило | Детали |
|---------|--------|
| **Default** | **DEV-ONLY** — regression smoke + fix-only; **не** предлагать Publish на каждое «дальше» |
| **Publish suggestion** | Когда [`NEXT-SESSION.md`](NEXT-SESSION.md) § Readiness assessment = **PASS** — агент **может** предложить owner unlock с rationale; **не** инструкция, владелец решает |
| **Триггер unlock (owner)** | «проект готов» / «owner unlock» / «owner unlock step N» — всегда уважается, даже если readiness ещё не PASS |
| **Allow*** | **Не флипать** без прохождения предшествующих шагов и явного подтверждения на каждый gate |
| **«дальше» без readiness PASS** | Post-W18 regression smoke + fix-only — **не** owner unlock, **не** Publish suggestion |

### Readiness assessment (когда предлагать Publish)

SoT: [`NEXT-SESSION.md`](NEXT-SESSION.md) § Readiness assessment. Кратко — все **PASS**:

1. Ф4 W1–W18 numbered track closed (smoke green, gates OFF)
2. Post-W18 regression re-smoke в **текущей** сессии (Smoke*Mock + core loop)
3. `quality_gate.py` green
4. Нет P0 regressions (play smoke / Output)
5. Core loop стабилен (E2E quest→battle→Haven→Sanctum)
6. Polish threshold: нет открытых P0 blockers (named backlog 106/B1/décor — optional для soft launch)
7. Live prep audits PASS (PlaceId=0 OK для dev; cutover docs готовы)

**NOT READY сейчас (2026-08-27):** post-W18 regression не подтверждён · live cutover не начат · E1 formal buffer пуст · W4 PREP CONDITIONAL.

**При PASS:** предложить шаг 1 (Ctrl+S) → шаг 2 (Publish + API Services) — см. ниже. Агент **не** Publish сам.

---

## Аудит готовности (Studio MCP, 2026-08-27)

| Параметр | Текущее значение | Готово к unlock? |
|----------|------------------|------------------|
| `game.PlaceId` | **0** (unpublished) | ☐ → шаг 2 (после «проект готов») |
| `game.GameId` | **0** | ☐ → шаг 2 |
| `GachaRobuxProductId` | **0** (gate) | ☐ → шаг 4 |
| `AllowProfileService` | **false** | ☐ → шаг 5 |
| `AllowGuilds` | **false** | ☐ → шаг 6 |
| `AllowNewPvPFeatures` | **false** | ☐ → шаг 7 |
| `AllowAiMeshOnline` | **false** | не в scope unlock |
| `UseProfileServiceAdapter` | **nil/false** | ☐ → шаг 5 |
| `ProfileServiceAdapter.Enabled` | **false** | ☐ → шаг 5 |
| `GetMigrationAudit` | phase=`F4-W4-prep`, `ShouldUse=false`, `LiveBlocked=true` | prep **PASS** |
| `GetGuildAudit` | phase=`F4-W13-guild-inv-bank`, `GateAllows=false` | prep **PASS** |
| `GetRatedAudit` / `GetWrapAudit` | phase=`F4-W18-wrap`, `GateAllows=false`, `DevOnly=true` | prep **PASS** |

**Prior live (Ф1):** PlaceId=`130832500076229` · GameId=`10713581476` — ожидаемый конфиг после Publish (см. [`SESSION-2026-08-23-phase1-stabilization.md`](SESSION-2026-08-23-phase1-stabilization.md) § W4).

---

## Порядок шагов (строго последовательно — после активации)

> Шаги 2–7 **deferred** до команды «проект готов» / «owner unlock». Документация сохранена для будущего cutover.

### Шаг 1 — Ctrl+S place SoT

| | |
|---|---|
| **Кто** | Владелец |
| **Действие** | Сохранить `RealmOfSpirits second.rbxl` (**Ctrl+S**) |
| **PASS** | Файл place синхронизирован с последними Studio-правками |
| **Rollback** | — (безопасная операция) |

---

### Шаг 2 — Publish + Enable API Services

| | |
|---|---|
| **Кто** | **Только владелец** (MCP не может Publish) |
| **Действие** | 1. Studio → **File → Publish to Roblox** (или привязанный experience) |
| | 2. Ожидаемый конфиг: PlaceId=`130832500076229` · GameId=`10713581476` |
| | 3. **Game Settings → Security → Enable Studio Access to API Services** = **ON** |
| | 4. Play в **опубликованном** place (не unpublished file) |
| **PASS** | `game.PlaceId ≠ 0` · Output **без** `DataStore недоступен (игра не опубликована)` · `[Persistence] liveBlocked=false` (или отсутствует warn) |
| **Rollback** | Unpublish / revert to private test place — **не удалять** live DS keys без плана; для dev вернуться к unpublished edit (PlaceId=0 в локальном файле) |

**НЕ делать на этом шаге:** Allow* flip · DevProduct · ProfileService cutover.

---

### Шаг 3 — Live DS rejoin smoke (legacy DataStoreManager)

| | |
|---|---|
| **Кто** | Владелец (hands) · агент может MCP-помочь после Publish |
| **Предусловие** | Шаг 2 PASS · все `Allow*=false` · backend = `DataStoreManager` |
| **Рецепт** | 1. Play → дождаться `data loaded` (не `new data (memory)`) |
| | 2. Seed: `ForceCatchBF` ×1 → spirits +1; `GrantItemBF` 320 ×1; side **113** accept→Exit→turnIn |
| | 3. **Stop** (OnPlayerRemoving SaveData) → **Play** снова |
| | 4. PASS: spirits / inventory / quest progress сохранились; нет DoNotSave warn |
| **PASS** | Live round-trip на `RealmOfSpirits_v2` / `Player_<userId>` |
| **Rollback** | Остановить тест; данные в DS остаются — для чистого smoke использовать тестовый alt account |

**Блокер для шагов 5–7:** без PASS шага 3 **не** включать ProfileService или Guild DS.

---

### Шаг 4 — DevProduct → GachaRobuxProductId → live R purchase

| | |
|---|---|
| **Кто** | **Только владелец** (Creator Dashboard + Studio) |
| **Предусловие** | Шаг 2 PASS (Publish + API Services) |
| **Действие** | 1. Creator Dashboard → **Developer Product** (cosmetics gacha, fair-combat copy) |
| | 2. Copy Product ID → `ReplicatedStorage.RealmOfSpirits.ZoneConfig` → `GachaRobuxProductId = <id>` |
| | 3. **Ctrl+S** place → **Publish** снова |
| | 4. Play (published): Haven → GachaMachine → **R** → подтвердить покупку |
| **PASS** | Cosmetics++ · combat Inventory без изменений · повтор receipt не дублирует grant (`ProcessedReceipts`) |
| **Rollback** | `GachaRobuxProductId = 0` → Ctrl+S → Publish; DevProduct можно оставить disabled в Dashboard |

**Fair-combat:** только cosmetics — 0 pay combat stats ([`FAIR-COMBAT.md`](FAIR-COMBAT.md)).

---

### Шаг 5 — ProfileService flip (triple gate)

| | |
|---|---|
| **Кто** | Владелец (attr flip в Studio) · агент документирует, **не** auto-flip |
| **Предусловие** | Шаги **2 + 3 PASS** · legacy DSM rejoin стабилен |
| **Triple gate (`ShouldUse`)** | Все три должны быть **true**: |
| | 1. `SSS.RealmOfSpirits` attribute **`AllowProfileService=true`** |
| | 2. `ProfileServiceAdapter.Enabled=true` (ModuleScript property) |
| | 3. `SSS.RealmOfSpirits` attribute **`UseProfileServiceAdapter=true`** |
| **Порядок flip** | 4 → 5 → 6 (как в `OwnerFlipChecklist`) |
| **Smoke после flip** | Play: `[Persistence] backend=ProfileServiceAdapter ShouldUse=true` |
| | Leave + rejoin: progress на `RealmOfSpirits_Profiles_v1` |
| **PASS** | `GetMigrationAudit().ShouldUse=true` · rejoin persist · `ValidateDataShape` OK |
| **Rollback** | `UseProfileServiceAdapter=false` + `Enabled=false` + `AllowProfileService=false` → live path **сразу** DataStoreManager (no dual-write) |

Источник: `ProfileServiceAdapter.GetMigrationAudit().OwnerFlipChecklist` + `Rollback`.

---

### Шаг 6 — AllowGuilds flip (после стабильного PS)

| | |
|---|---|
| **Кто** | Владелец |
| **Предусловие** | Шаг 5 PASS · PS rejoin стабилен минимум 1–2 сессии smoke |
| **Действие** | `SSS.RealmOfSpirits` attribute **`AllowGuilds=true`** → Ctrl+S → Publish |
| **Smoke** | `/guild` CreateOrJoin не Locked · `GetGuildAudit().GateAllows=true` · bank deposit/withdraw (не Locked) · transfer inv↔bank |
| **Будущее** | Live guild DS `RealmOfSpirits_Guilds_v1` — отдельный owner slice после in-memory PASS |
| **PASS** | CreateOrJoin + bank + warfare APIs не fail-closed |
| **Rollback** | `AllowGuilds=false` → Publish → CreateOrJoin / bank / warfare снова Locked |

---

### Шаг 7 — AllowNewPvPFeatures / rated live (последний)

| | |
|---|---|
| **Кто** | Владелец |
| **Предусловие** | Шаг 6 PASS (или явный owner skip guilds + PS stable) |
| **Действие** | `SSS.RealmOfSpirits` attribute **`AllowNewPvPFeatures=true`** → Ctrl+S → Publish |
| **Smoke** | DeclareRated / MatchRated / Enqueue не Locked · `GetRatedAudit().GateAllows=true` |
| **Будущее** | Live rated store `RealmOfSpirits_RatedPvP_v1` · season flip `S0-dev` → live season |
| **PASS** | Rated APIs live · ladder writes не fail-closed |
| **Rollback** | `AllowNewPvPFeatures=false` → Publish → Declare/Match/MM снова Locked; Smoke*Mock QA остаётся |

---

## Rollback one-liners (шпаргалка)

| Шаг | Rollback |
|-----|----------|
| 2 Publish | Вернуться к unpublished edit; не трогать DS keys |
| 3 DS rejoin | Alt account / тестовый ключ; DSM path без изменений |
| 4 DevProduct | `GachaRobuxProductId=0` → Publish |
| 5 ProfileService | `Use*=false` + `Enabled=false` + `AllowProfileService=false` |
| 6 Guilds | `AllowGuilds=false` → Publish |
| 7 Rated PvP | `AllowNewPvPFeatures=false` → Publish |

---

## Что сделал агент vs что только владелец

| Агент (repo/docs/MCP) | Только владелец (hands) |
|------------------------|-------------------------|
| OWNER-UNLOCK.md + NEXT-SESSION mode | **Ctrl+S** place |
| Studio MCP read-only audit (gates, audits) | **Publish** to Roblox |
| `quality_gate.py` | **Enable API Services** |
| Документированы flip values + rollback | Live **DS rejoin** smoke |
| **НЕ** флипал Allow* · **не** Publish (hands only) | **DevProduct** create + `GachaRobuxProductId` |
| Readiness **PASS** → **предложить** owner unlock (optional) | Allow* attr flip (шаги 5–7) |
| | Live **Robux** purchase test |

---

## Когда начинать

Cutover **не default next**. Начинать когда:

- **Readiness PASS** — агент предлагает owner unlock (владелец подтверждает или откладывает), **или**
- Владелец явно: «проект готов» / «owner unlock»

До активации: post-W18 regression smoke + fix-only.

После активации порядок: **Шаг 1 → Шаг 2 → Шаг 3** — Publish + live DS rejoin на legacy `DataStoreManager`. DevProduct (шаг 4) можно после шага 2, но **не** раньше Publish. Шаги 5–7 — только после стабильного rejoin PASS.

---

## Verify commands (Studio Edit, после каждого шага)

```lua
-- ExpansionGate snapshot
require(game.ReplicatedStorage.RealmOfSpirits.ExpansionGate).GetSnapshot()

-- ProfileService migration audit
require(game.ServerScriptService.RealmOfSpirits.ProfileServiceAdapter).GetMigrationAudit()

-- Guild audit
require(game.ServerScriptService.RealmOfSpirits.GuildSystem).GetGuildAudit()

-- Rated PvP audit
require(game.ServerScriptService.RealmOfSpirits.RatedPvPSystem).GetRatedAudit()
require(game.ServerScriptService.RealmOfSpirits.RatedPvPSystem).GetWrapAudit()

-- Place + product
print(game.PlaceId, require(game.ReplicatedStorage.RealmOfSpirits.ZoneConfig).GachaRobuxProductId)
```

---

## Smoke recipes (шаги 2–3)

**Tracker:** [`SESSION-2026-08-27-owner-unlock.md`](SESSION-2026-08-27-owner-unlock.md)

### Output — что искать (PASS vs FAIL)

| Строка Output | Когда | Вердикт |
|---------------|-------|---------|
| `DataStore недоступен (игра не опубликована)` | Play init | **FAIL шаг 2** — Publish + API Services |
| `[Persistence] backend=DataStoreManager liveBlocked=false` | Play init (published) | **PASS шаг 2** |
| `[Persistence] … liveBlocked=true` | Play init | **FAIL** — ещё unpublished или API Services OFF |
| `<Player> - новые данные созданы` | первый join (нет DS key) | OK на **первом** Play после Publish |
| `<Player> - данные загружены (уровень: N)` | rejoin (есть DS key) | **PASS шаг 3** на Stop→Play |
| `<Player> - данные сохранены` | Stop / autosave | ожидаемо перед rejoin |
| `All players saved` | BindToClose / Stop | ожидаемо |
| `Skip save for … (load failed / DoNotSave)` | любой момент | **FAIL** — не продолжать cutover |
| `… ProfileService load FAILED; session marked DoNotSave` | Play init | **FAIL** — gates должны быть OFF (шаг 5+) |

**Unpublished baseline (PlaceId=0):** Stop→Play даёт снова `новые данные созданы` — это **ожидаемо**, не PASS для шага 3.

### Шаг 2 — быстрая проверка после Publish (Edit или Play)

```lua
-- Edit: PlaceId должен быть 130832500076229 (или ваш live id)
print("PlaceId", game.PlaceId, "GameId", game.GameId)

-- Play Server (после init DSM):
local audit = require(game.ServerScriptService.RealmOfSpirits.ProfileServiceAdapter).GetMigrationAudit()
print("[Step2]", "PlaceId", audit.PlaceId, "LiveBlocked", audit.LiveBlocked, "ShouldUse", audit.ShouldUse)
-- PASS: PlaceId~=0, LiveBlocked=false, ShouldUse=false
```

### Шаг 3 — seed snapshot (Play / Server, после data loaded)

**BF paths:** `ForceCatchBF` · `GrantItemBF` → `ReplicatedStorage.RealmOfSpirits` · quest BFs → `ServerScriptService.RealmOfSpirits` (runtime only).

```lua
-- Server datamodel, Play mode — замените userId при необходимости
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local player = Players:GetPlayers()[1]
local userId = player.UserId

local function bf(parent, name)
	local inst = parent:WaitForChild(name, 10)
	assert(inst, "missing BF " .. name)
	return inst
end

local forceCatch = bf(RS.RealmOfSpirits, "ForceCatchBF")
local grantItem = bf(RS.RealmOfSpirits, "GrantItemBF")
local getData = bf(SSS.RealmOfSpirits, "GetPlayerDataBF")
local questAccept = bf(SSS.RealmOfSpirits, "QuestAcceptBF")
local questTurnIn = bf(SSS.RealmOfSpirits, "QuestTurnInBF")
local questProgress = bf(SSS.RealmOfSpirits, "UpdateQuestProgressBF")
local questSeed = bf(SSS.RealmOfSpirits, "QuestSeedCompletedBF")

-- Q1 prereq for side 113 (если ещё не complete)
questSeed:Invoke(player, 1)

forceCatch:Invoke(userId, 12)          -- +1 spirit, +50 Exp
grantItem:Invoke(userId, 320, 1)       -- essence smoke item

questAccept:Invoke(player, 113)
questProgress:Invoke(player, "VisitZone", { ZoneDetail = "Exit" })
questTurnIn:Invoke(player, 113)

local data = getData:Invoke(userId)
local inv320 = 0
for _, row in ipairs(data.Inventory or {}) do
	if row.Id == 320 then inv320 = row.Quantity or row.Count or 0 end
end

local snap = {
	spirits = #(data.Spirits or {}),
	exp = data.Experience,
	caught = data.Stats and data.Stats.SpiritsCaught,
	inv320 = inv320,
	q113 = (data.CompletedQuests and table.find(data.CompletedQuests, 113)) ~= nil,
}
print("[DS-SEED]", game:GetService("HttpService"):JSONEncode(snap))
-- Запишите snap → Stop (дождаться save) → Play → сравнить снова
```

**Hands альтернатива:** поймать духа в Haven · взять side **113** у Мики · пройти Exit → turnIn · GrantItem 320 через dev panel если есть.

### Шаг 3 — rejoin verify (Play / Server, после второго Play)

```lua
local Players = game:GetService("Players")
local player = Players:GetPlayers()[1]
local getData = game.ServerScriptService.RealmOfSpirits.GetPlayerDataBF
local data = getData:Invoke(player.UserId)

local inv320 = 0
for _, row in ipairs(data.Inventory or {}) do
	if row.Id == 320 then inv320 = row.Quantity or row.Count or 0 end
end

local snap = {
	spirits = #(data.Spirits or {}),
	exp = data.Experience,
	caught = data.Stats and data.Stats.SpiritsCaught,
	inv320 = inv320,
	q113 = (data.CompletedQuests and table.find(data.CompletedQuests, 113)) ~= nil,
}
print("[DS-REJOIN]", game:GetService("HttpService"):JSONEncode(snap))
-- PASS: snap совпадает с [DS-SEED] до Stop
```

**MCP agent (после owner Publish):** `execute_luau` datamodel **Server** — seed script → owner Stop→Play → verify script. Agent **не** может Publish или надёжно эмулировать live DS без PlaceId≠0.

### Mirror paths (post-publish flip prep)

| Flip (шаг) | Studio path | Mirror file |
|------------|-------------|-------------|
| GachaRobuxProductId (4) | `ReplicatedStorage.RealmOfSpirits.ZoneConfig` | `studio/ZoneConfig.lua` |
| Allow* attrs (5–7) | `ServerScriptService.RealmOfSpirits` attributes | flip в Studio; mirror после cutover |
| ExpansionGate read | `ReplicatedStorage.RealmOfSpirits.ExpansionGate` | `studio/ExpansionGate.lua` |

Аудит 2026-08-27: Studio paths **совпадают** с mirror convention ☑.

---

## Снятие режима PAUSED

Когда readiness **PASS** + владелец согласился **или** явная команда «проект готов» / «owner unlock»: обновить `NEXT-SESSION.md` → `OWNER-UNLOCK IN PROGRESS`.

Когда шаги 2–3 PASS: `OWNER-UNLOCK: steps 2-3 PASS` или `LIVE CUTOVER ACTIVE`.

Когда все целевые шаги PASS: `DEV-ONLY` снят полностью · gates по плану.
