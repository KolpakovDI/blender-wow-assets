# SESSION 2026-08-19 — Resonant live loop (MCP smoke)

**Трек:** [`WEEK-PLAN-2026-08-26.md`](WEEK-PLAN-2026-08-26.md) · якорь [`SESSION-2026-08-14g-kami-hands-loop.md`](SESSION-2026-08-14g-kami-hands-loop.md)  
**Place:** `C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl` (post-sync SoT)  
**Тип:** MCP live-like — **не** честные руки (F/E/`[R]` у shrine пешком).

## Вердикт: **PASS** (MCP Play)

| Шаг | Результат |
|-----|-----------|
| SeedQA → Synthesize {1,2} | **Ками-Глыба** Resonant, active idx **3**, skill1 **Пламенный всплеск** |
| Care (DoResonanceCareBF) | **PASS** |
| Бой vs Лавовый Краб, SkillIndex **1+2** | Console: «начал битву…» → **«Вы победили!»** (`winner=Player`) |
| Temper +Attack (client) | fired |
| Sanctum Open у shrine + FullSync | Roster: **`[R] 3. Ками-Глыба Lv5`** |

## Чеклист руками (следующий шаг)

1. **Ctrl+S** → **Play** Solo  
2. Набрать 2 духов + осколок **#301** (магазин / лут, не ForceCatch на финале)  
3. Shrine Haven → **Open** Sanctum → выбрать 2 духов → **Слить**  
4. Status LOOK: `имя vid #N | удар * | …`  
5. Выйти в Combat → **F** → **1** и **2** vs дух  
6. **Care** (UI или пьедестал) или **Temper** на активном Ками  
7. Вернуться к shrine → Sanctum → в списке **`[R]`** у Resonant  

**PASS** = бой с Ками-сkill в логе + Care/Temper toast + `[R]` в Sanctum без P0.

## Оговорки

- **need_shard:** для синтеза нужен **Осколок Ками (#301)** в инвентаре. Fix 19.08: 1× в старте + выдача при первом Open Sanctum; иначе Магазин Haven (**120 меди**).
- Hands (user): после фикса `need_shard` **больше не блокирует**, синтез/слияние проходит нормально.
- Live feedback 19.08: порог Sanctum был слишком высоким для hands-цикла. `KamiSanctumConfig.MinPlayerLevel` снижен **10 → 2** в SoT и docs mirror.
- MCP: TP к врагу / shrine; SeedQA + ForceCatch на setup — не считать hands PASS.  
- Open вдали от shrine → «Подойдите ближе» (известно с 14.08g).  
- `ExpansionGate` Allow* / AI mesh / PvP — **не** включать.

## Next

Один **hands** прогон по чеклисту выше → строка в лог (создать `KAMI-HANDS-LOG.md` или секция в SESSION). Опц. E1 #9–10.
