# Economy Balance — P0–P3 (после Resonance)

Статус: **P0–P3 PASS (unit smoke)** · 2026-07-26  
SoT place: `RealmOfSpirits second.rbxl` · зеркала: `docs/realm-of-spirits/studio/` · rollout: `ECONOMY-ROLLOUT.md`
Цель: заземлить copper/gold после Full Resonance, не ломая soft-gates (Bond / Stamina / crystals).

## P0 — Shop

| Изменение | Где |
|-----------|-----|
| Temper stone **60→200c**, `DailyBuyCap = 3` | `ItemCatalog` + `TradeSystem.BuyItem` |
| XP scroll **80c / +120 XP** (было 100c/+50) | `ItemCatalog` + `TradeSystem.UseExpScroll` |

## P1 — Mats + Gold sinks

| Изменение | Где |
|-----------|-----|
| Crystals 101–112: `Unsellable = true`, SellPrice 0 | `ItemCatalog` + `TradeSystem.SellItem` / UI |
| Gold sinks: **201** Haven lantern (1g), **202** Showcase slot (2g), **203** rename token (1g) | `ItemCatalog.ShopIds` |
| Rename consume 203 | `GameManager` Trade `RenameSpirit` |

## P2 — Daily + battle drip

| Изменение | Где |
|-----------|-----|
| Care daily 301: treat **30%** (`ItemsChance`) | `QuestSystem` |
| Battle copper: **30→20** by level (`BattleCoinReward`) | `ItemCatalog` + `GameManager.EndBattle` |

## P3 — LiveOps (soft power)

| Изменение | Где |
|-----------|-----|
| `SeasonLiveOps`: event tokens ≠ copper; EventShop; BP soft-only | `SeasonLiveOps.lua` |
| Tokens/pass XP from Care/Temper/battle | Quest 301/302, EndBattle |
| Haven remotes: `RequestSeason` / `BuySeasonOffer` / `ClaimSeasonPass` | `OtakuHavenService` |

## Fair combat

- Gold/season shops: **cosmetics + SoftBond XP only** — no ATK/DEF/HP.
- Evo crystals remain **time/loot gated**, not vendor junk.

## Smoke

1. Shop: temper stone 200c, max 3/day; scroll +120.
2. Inventory: crystal sell disabled.
3. Buy 201/202/203 for gold; rename with 203.
4. Win battles at lvl 1 vs 15 → coins 30 vs ~20.
5. Turn in 301 repeatedly → treat ~30%.
6. Haven: `RequestSeason` returns tokens/shop.
