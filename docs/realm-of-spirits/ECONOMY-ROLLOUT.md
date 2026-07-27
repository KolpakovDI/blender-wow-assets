# Economy rollout — поэтапная реализация

Статус: **P0–P3 PASS (unit smoke)** · 2026-07-26  
SoT: `RealmOfSpirits second.rbxl`

Порядок: **P0 → P1 → P2 → P3**.

| Этап | Цель | Критерий PASS | Статус |
|------|------|---------------|--------|
| **P0** | Temper cap + XP scroll ROI | Buy 3×#5 OK, 4-й fail; scroll +120 | ✅ |
| **P1** | Crystals unsellable + gold sinks | Sell #101 fail; buy 201/202/203; rename consume 203 | ✅ |
| **P2** | Battle drip + Care treat RNG | BattleCoin 30/25/20; Quest 301/302 + ItemsChance в Studio | ✅ |
| **P3** | Season tokens LiveOps | BuyOffer / ClaimPass / SoftBond mult; tokens ≠ copper | ✅ |

## Лог smoke (Edit / execute_luau)

- **P0:** stone 200c cap3; 4-й buy fail; UseExpScroll `+120`; crystal sell blocked (bonus).
- **P1:** lantern → Cosmetics+1; showcase slots=1; rename token consume OK; poor gold fail.
- **P2:** BattleCoin(1/8/15)=30/25/20; Quest `[301]`/`[302]` + `ItemsChance` + season hooks; treat RNG ~0.32/200.
- **P3:** EventShop cosmetic+soft OK; BP claim lvl1 OK; BondXpMult=1.25.

## Осталось (следующий этап продукта)

1. **Ctrl+S** + Play smoke в Haven shop / бой.
2. **SpiritResonance Phase 0 → Studio** — иначе CareSpirit/TemperSpirit objectives 301/302 не прогрессируют.
3. UI: Temper picker / Dex / Showcase billboard (Resonance Phase 1–3).

## Fair combat

Gold/season: cosmetics + SoftBond only — без ATK/DEF/HP.
