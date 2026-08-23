# SESSION — Phase 3 Commercial prep (2026-08-23)

**Roadmap:** [`ROADMAP-2026-08-23.md`](ROADMAP-2026-08-23.md) · **Фаза 3** · Commercial prep  
**Place SoT:** `C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl` — **Ctrl+S** после Studio-правок  
**Phase 2 tracker (closed):** [`SESSION-2026-08-23-phase2-scout-side.md`](SESSION-2026-08-23-phase2-scout-side.md)

---

## Цель фазы

Public beta / store listing ready: hub KR smoke, monetization live test, analytics hooks, cold-start onboarding — **без** ProfileService / Guilds / AI mesh / Haven décor marathon.

### Exit criteria (фаза)

| # | Критерий | Статус |
|---|----------|--------|
| 1 | Hub KR smoke (Mika funnel, prep в логах) | ☑ W1 · PrepShop seen W2 |
| 2 | Monetization live test · 0 pay combat stats | ☑ W2 **PASS CONDITIONAL** (Studio; live Robux = owner hands) |
| 3 | Analytics hooks usable без MCP-костылей | ☐ W1 attr · W3+ |
| 4 | Cold-start: новый игрок знает Mika→Exit | ☑ W1 MCP |

---

## W1 — Hub polish + cold-start onboarding — **PASS MCP (2026-08-23)**

**Scope:** не marathon décor. Читаемость Mika→Exit + cold-start tips + funnel attribute.

| # | Задача | Статус |
|---|--------|--------|
| 1 | Cold-start toast: «Поговори с Микой [E]» → «Exit → Combat» (once) | ☑ |
| 2 | NextStepChip copy: Mika [E] / Exit → Combat | ☑ |
| 3 | `HubFunnel` step **Spawn** + attr `HubFunnelStep` (Spawn / MikaOpen / PrepShop / ExitTouch) | ☑ |
| 4 | Ensure* copy: Mika TalkHint «Мика [E]»; Exit billboard «Exit → Combat» | ☑ |
| 5 | MCP Play smoke | ☑ **PASS** |
| 6 | `quality_gate.py` | ☑ **PASS** (python3.12) |

### MCP smoke (Play)

| Шаг | Результат |
|-----|-----------|
| Spawn log `[HubFunnel] … -> Spawn (Spawn)` | **PASS** |
| Then Mika → attr `HubFunnelStep=MikaOpen` (no regress) | **PASS** |
| NextStepChip «→ Exit → Combat» | **PASS** |
| Toast / NotificationLabel funnel tip visible | **PASS** |
| TalkHint «Мика [E]» Enabled | **PASS** |

### SoT правки (Studio)

- `ReplicatedStorage.RealmOfSpirits.HubFunnel` — Spawn + HubFunnelStep attr
- `ServerScriptService.RealmOfSpirits.GameManager` — Mark Spawn after LoadData
- `ServerScriptService.RealmOfSpirits.ZoneSystem` — Spawn mark backup on character
- `ServerScriptService.RealmOfSpirits.DataStoreManager` — HubFunnel.Spawn default
- `ServerScriptService.RealmOfSpirits.WorldSpawner` — TalkHint Ensure*
- `ServerScriptService.RealmOfSpirits.OtakuHavenBuilder` — `EnsureHubColdStartCopy` + Exit billboard
- `StarterPlayerScripts.ZoneController` / `NextStepChip` — cold-start copy

**Mirror:** `HubFunnel` · `ZoneController` · `NextStepChip` · `ZoneSystem` · `WorldSpawner` · `GameManager` · `DataStoreManager` · `OtakuHavenBuilder`

---

## W2 — Monetization live test — **PASS CONDITIONAL (2026-08-23)**

**Scope:** fair-combat gate на pay path · copper gacha smoke · ProcessReceipt path review · friction note для live Publish. **Не** новые DevProducts без approval · **не** pay combat power.

| # | Задача | Exit | Статус |
|---|--------|------|--------|
| 1 | Studio smoke покупки (cosmetics-only) | 0 combat stats | ☑ copper **PASS** · live Robux ☐ owner hands |
| 2 | Confirm fair-combat gate на pay path | PASS | ☑ `fair_combat_check` + Studio SoT |
| 3 | Log / note friction | backlog | ☑ см. ниже |

**Вердикт:** **PASS CONDITIONAL** — Studio/MCP cosmetics-only + CI gate green; реальный Robux purchase невозможен пока `GachaRobuxProductId = 0` и place без live API Services.

### W2 matrix

| Проверка | Результат |
|----------|-----------|
| `grantGachaReward` → только `Cosmetics` / `Type=Cosmetic` / «только косметика» | **PASS** (SoT + mirror) |
| ProcessReceipt → тот же `grantGachaReward` + `ProcessedReceipts[PurchaseId]` idempotent | **PASS** (static SoT) |
| `ZoneConfig.GachaRobuxProductId` | **0** (gate) — toast «задайте …ProductId» |
| Copper gacha MCP Play (E×2) | **PASS** — +2 cosmetics (`Fig_*` / `FigRare_*`), −100 copper |
| Combat inventory after gacha | **PASS** — Inv Ids/Qty unchanged (1,2,4,5,301) |
| Spirit Level / combat power | **PASS** — no level/stats drip from gacha |
| UI clarity | **PASS** — popup «только косметика, без бонусов в бою»; prompt «Гашапон · только косметика» |
| Robux prompt R (ProductId=0) | **PASS** — toast gate, no purchase prompt |
| ProcessReceipt MCP invoke | **N/A** — Roblox API: callback set-only, get/call запрещён |
| `fair_combat_check.py` | **PASS** (python3.12) |
| `quality_gate.py` | **PASS** (python3.12) |

### MCP smoke recipe (повтор)

1. Play (Local Server) · дождаться `[HubFunnel] … Spawn` + data load  
2. Server: `GetPlayerDataBF:Invoke(userId)` snapshot copper / Cosmetics / Inventory  
3. Teleport HRP near `Workspace.OtakuHaven.Decor.GachaMachine` (~5 studs)  
4. Client: **E** (copper) → Cosmetics++ · Inventory combat Qty неизменны · popup disclaimer  
5. Client: **R** → toast `Robux-гача: задайте ZoneConfig.GachaRobuxProductId` (пока ProductId=0)  
6. Stop Play · **Ctrl+S** если SoT меняли (W2 SoT не меняли)

### Friction — live Publish (owner)

| # | Friction | Действие |
|---|----------|----------|
| F1 | `GachaRobuxProductId = 0` | Create **Developer Product** (Robux gacha, cosmetics-only copy) → вписать ID в `ZoneConfig.GachaRobuxProductId` → **Ctrl+S** |
| F2 | Unpublished / DS memory-only | **Publish** place; Game Settings → **Enable Studio Access to API Services** (для live DS/receipts в Studio) |
| F3 | ProcessReceipt не smoke-ается из MCP | Hands: купить DevProduct в Play (опубликованный place / Test) → Cosmetics++ · повтор того же PurchaseId не дублирует награду |
| F4 | Robux spend real | Тест на **тестовом** DevProduct / малой цене; не создавать combat DevProducts |

### Owner hands — live Robux purchase

1. **Ctrl+S** place  
2. Create Developer Product (cosmetics gacha) → copy ID → `ZoneConfig.GachaRobuxProductId = <id>`  
3. Publish place · API Services on  
4. Play (published / Team Test): Haven → GachaMachine → **R** → подтвердить покупку  
5. Verify: Cosmetics++ · Inventory combat без изменений · повтор receipt не двойной grant  
6. (Опц.) повтор copper **E** — тот же cosmetics-only пул  

### SoT правки (W2)

- Нет — только verification

**NEXT after W2:** F3-W3 analytics polish · combat anim best-effort

---

## W3 — Analytics hooks polish (skeleton) ← **NEXT**

| # | Задача | Exit | Статус |
|---|--------|------|--------|
| 1 | HubFunnel day Complete readable без MCP | snapshot / debug | ☐ |
| 2 | Optional: prep ≥50% in sample logs | note | ☐ |
| 3 | Combat anim best-effort (non-blocking) | optional | ☐ |

---

## W4 — Phase 3 exit gate (skeleton)

| # | Задача | Exit | Статус |
|---|--------|------|--------|
| 1 | Hub KR smoke checklist | PASS | ☐ |
| 2 | DS stress / rejoin sanity | OK | ☐ |
| 3 | quality_gate + NEXT-SESSION → Фаза 4 / soft | docs | ☐ |

---

## Owner hands

| # | Действие | Зачем |
|---|----------|-------|
| 1 | **Ctrl+S** place | SoT sync |
| 2 | Пешком: spawn → toast/chip → Мика [E] → Exit | cold-start feel |
| 3 | DevProduct ID + Publish + live Robux **R** (W2 hands) | store prep · снять CONDITIONAL |

## Не включать

ProfileService live · Guilds · AI mesh · Haven décor marathon · B1 PvP · track 106 · pay combat stats
