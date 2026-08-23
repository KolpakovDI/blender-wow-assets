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
| 1 | Hub KR smoke (Mika funnel, prep в логах) | ☐ W1 partial · W2+ |
| 2 | Monetization live test · 0 pay combat stats | ☐ W2 |
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

## W2 — Monetization live test (skeleton)

| # | Задача | Exit | Статус |
|---|--------|------|--------|
| 1 | Live / Studio smoke покупки (cosmetics-only) | 0 combat stats | ☐ |
| 2 | Confirm fair-combat gate на pay path | PASS | ☐ |
| 3 | Log / note friction | backlog | ☐ |

**NEXT after W1:** F3-W2 monetization live test.

---

## W3 — Analytics hooks polish (skeleton)

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
| 3 | Опц.: Publish + live monetization (W2) | store prep |

## Не включать

ProfileService live · Guilds · AI mesh · Haven décor marathon · B1 PvP · track 106 · pay combat stats
