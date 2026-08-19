# SESSION 2026-08-19 — E1 hands loop (подготовка)

**Трек:** W2 — живой цикл **Spawn → Мика Q7 → Exit/лут → Q1 catch → бой F+1/2 → сдача**.  
**Place:** `C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl`  
**Не считать PASS:** MCP TP, ForceCatch, remote Accept/Catch/Attack, V/Keypad (только для MCP-regress).

---

## MCP audit post-sync (Edit + частичный Play)

| Компонент | Статус | Заметка |
|-----------|--------|---------|
| `NextStepChip` в SPS | **OK** | 6370 chars; client log `[RoS] NextStepChip ready` |
| `QuestUI` Accept / TurnIn | **OK** | «Принять» / «Сдать» в Source |
| `UIController` CatchUiActive + battle hints | **OK** | trap count + 1/2/3 agency |
| `QuestAcceptBF` / `QuestTurnInBF` | **OK** | MCP: Q7 accept→grant 120→turn-in → console «Украденная манга» |
| Q1 ForceCatch + TurnIn (MCP BF) | **OK** | spirits 2→turn-in BF |
| Battle SkillIndex 1+2 (client FireServer) | **SKIP** | Auto-review block; руками F/1/2 |
| `ExpansionGate` Allow* | **locked** | не включать |

Известный шум: FEFF `user_RoS_ShortGrass` (plugin).

---

## Чеклист одного цикла (руками)

**Перед стартом:** place **Ctrl+S** → **Play** (свежий Solo, без `/tradetest` если не нужен инвентарь).

| # | Шаг | Клавиши / UI | PASS критерий |
|---|-----|--------------|---------------|
| 1 | Спавн Haven | — | Chip сверху: **«→ Поговори с Микой»** (или ResonanceBar + chip под ним) |
| 2 | Мика | **E** → «Принять квест» | Q7 «Украденная манга» в активных; chip → **«Выход в Акихабару»** |
| 3 | Exit → Combat | идти к Exit, **E** манга/лут | Prompt виден; после подбора — toast / инвентарь |
| 4 | Сдать Q7 | **E** у Мики → «Сдать квест» | Toast «выполнил квест: Украденная манга»; **?** гаснет |
| 5 | Принять Q1 | **E** → «Принять квест» | «Первые шаги» активен; ZoneHint в трекере/chip если есть |
| 6 | Ловля | **E** у духа (нужна ловушка) | Счётчик ловушек **×N**; зелёный prompt если `CatchUiActive`; RNG fail — норма |
| 7 | Бой | **F** старт; **1** и **2** минимум по разу | «Вы победили!» или soft-respawn без wipe HUD |
| 8 | Сдать Q1 | **E** → «Сдать квест» | XP/монеты; квест в выполненных |

**FAIL (P0):** нет «Принять»/«Сдать», HUD дублируется после поражения, SpiritDetail под UI, Kami copper error, зависший EndBattle.

**Цель недели W2:** **2–3** таких прогона; «5/5» — бонус. Заполнять [`E1-HANDS-LOG.md`](E1-HANDS-LOG.md) строки #8+.

---

## Подсказки игроку (уже в SoT)

- **Chip:** Мика → Exit → лут (E) → скрыть после funnel 101/102/120 или Haven toast «Собран»/«Сундук»
- **Q1 ZoneHint:** после FTUE chip показывает hint из активного квеста
- **Бой:** слоты 2–3 с MP/CD; tip элементов на старте; поражение = soft-respawn (не LoadCharacter)
- **Магазин:** кнопка «Магазин», цены по кошельку (post-sync PASS 19.08)

---

## Ручной прогон (user 2026-08-19)

| Check | Result |
|-------|--------|
| Полный цикл Q7→Q1 (E / F / 1 / 2) | **PASS** |
| P0 friction | нет |

Запись: `E1-HANDS-LOG` **#8 PASS**.

## Next

1. Опц.: ещё **1–2×** тот же чеклист (#9–10) для W2 уверенности
2. Или следующий трек: Explore polish глазами / Sanctum LOOK / week wrap
3. Не включать Allow* / Guilds / ProfileService / AI mesh
