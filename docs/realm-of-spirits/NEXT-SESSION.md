# NEXT SESSION

**Статус:** P1 Social **in progress** — fair-combat policy + gacha fix + P2P server MVP.

Дата якоря: 2026-07-18

## Цели (locked)

См. [`GOALS.md`](./GOALS.md), [`FAIR-COMBAT.md`](./FAIR-COMBAT.md), GDD §9.

| Done | P0 Core/Hub · P1 Identity · Explore A/B/C · fair-combat policy · gacha cosmetics-only · PlayerTrade server |
| Now | **P1 Social UI** — клиентский Trade Request (1 слот) + clarity toast «только косметика» |
| Later | Flex equip в Safe · trade play-тест 2 игрока · P2 Scale |

## Старт сессии (порядок жёсткий)

1. **Ctrl+S** place (`PlayerTradeSystem`, `OtakuHavenService`, `ItemCatalog`)
2. Клиент: `PlayerTradeHud` / prompt рядом с игроком в Safe → Request / Offer / Ready
3. Play-тест 2 клиента (или Local Server 2 players) — обмен 1 предмета
4. UI гачи: явный текст «только косметика» в результате (сервер уже шлёт Message)
5. Не начинать PvP

## Сделано 2026-07-18 (Social kickoff)

- `FAIR-COMBAT.md` — политика locked
- Gacha: убраны ловушки/зелья из пула (FAIL→PASS)
- `PlayerTradeSystem` — Remote `PlayerTrade`, 1 слот, Safe+distance
- `ItemCatalog.CombatUtility` flags

## Studio SoT

Place: `C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl` — **Ctrl+S**.
