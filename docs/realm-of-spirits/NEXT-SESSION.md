# NEXT SESSION

**Статус:** Checkpoint 2026-07-23 evening. **PvP slice PASS**. **MistPond + Водный Карп** в Studio (Swim + хвост); нужен **Play QA** плавания. Tourbillon **paused**.

Дата якоря: 2026-07-23 → продолжение 2026-07-24

## Старт сессии (порядок жёсткий)

1. Place SoT: `C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl` — **Ctrl+S** если не сохранял
2. Studio MCP `user-Roblox_Studio` (если error → Restart MCP)
3. Этот файл
4. **Play QA: карп плавает в пруду + машет хвостом** (ниже)

## Product progress

| Тема | Статус |
|------|--------|
| P0–P1 Core / Haven / Social | **DONE** |
| P2 PvP vertical slice | **DONE** (2p PASS) |
| P2 MistPond + Water Carp #6 | **CODE IN STUDIO** — Play QA pending |

## Точный next step (игра)

1. Ctrl+S → Play
2. Haven → Akihabara Combat → **север** по каменным ступеням
3. Японский пруд (песок, стекло-вода, фонарь) — **без** текстовых табличек
4. Один **Водный Карп** в воде: плавает в пределах пруда, хвост машет
5. Бой / ловля; синие водные кристаллы
6. Нет артефактов preview/procedural рядом с прудом

После PASS → следующий дух/зона или polish карпа (светлый реф = эво #106).

## Закрыто в этой сессии

- PvP: rematch/origin, Haven challenge zone, PlayerInteract Обмен|Дуэль
- MistPond японский берег; refs → SpiritTemplate6
- Swim + tail anim; cleanup artifacts
- Allow-rule: не спрашивать Allow в чате

## Studio SoT

`C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl` (не в git). **Ctrl+S.**

Ключевые модули: `SpiritAnimation`, `SpiritDatabase`, `ZoneConfig`, `WorldSpawner`, `GameManager` (Swim wander), `PvPDuel*`, `PlayerInteractController`, `SpiritTemplate6`

Quality: `python scripts/quality_gate.py`
