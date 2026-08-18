# SESSION 2026-08-16f — Q3 Slice 1 fair duel harden

**Трек:** Year-plan Q3 · E1 OWNER SKIP уже снят.

## Сделано (Studio + docs)

| Item | Статус |
|------|--------|
| `resolveDuelSpiritInfo` — Resonant/Ками 9xxx стартует дуэль | **PASS** (code) |
| Abilities через `BuildAbilities(info)` + `SkillIds` инстанса | **PASS** |
| `WIN_COPPER=0` → toast «победа! (слава)», без +0 меди / FullSync | **PASS** |
| `PvPDuelHost` Billboard «Дуэль · Y / Interact» (refresh existing) | **PASS** |
| `AllowNewPvPFeatures` | **не трогали** (false) |

## Smoke — Local Server 2p (руки)

Место: Haven или арена. Клавиши: **Y** / ProximityPrompt на жёлтой плите `PvPDuelHost`, Accept UI.

1. Два клиента Local Server, оба у Haven/арены, у каждого ≥1 дух.  
2. Игрок A: **Y** / Interact на хосте → вызов ближайшему.  
3. Игрок B: Accept.  
4. Оба на pads → навыки **1**/**2** (spirit battle UI) → KO.  
5. Победитель: toast **«победа! (слава)»** (не «+0 🥉»). Rematch Accept/Decline.  
6. Повтор с **Ками (Resonant)** у одного игрока → дуэль стартует, слот 1 читается.

| # | Шаг | PASS/FAIL | Заметка |
|---|-----|-----------|---------|
| 1 | Challenge+accept | **PASS** | 2026-08-18 владелец: дуэль прошла |
| 2 | KO + glory toast | **PASS** | вместе с полным циклом дуэли |
| 3 | Rematch/decline | не отдельно | не блокирует Slice 1 |
| 4 | Kami vs normal | не отдельно | код resolve на месте; не требовали повтор |

**Итог Slice 1:** playable 2p duel **PASS** (руки).

## Next

Q3 Slice 2: Haven décor / указатель к арене. Не Allow*.
