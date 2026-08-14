# Святилище Ками (Kami Sanctum)

Anime-синто + sci-fi реактор в Otaku Haven. С **10 уровня игрока**: синтез 2–6 духов и дезинтеграция в компоненты.

## Режимы

### Синтез
- Слоты: 2–6 духов (первый = Ядро)
- Расход: все доноры + Звёзды трансформации / осколки
- Результат: `Kind = "Resonant"` с 3 SkillIds (взвешенный рандом) ± Unique 300–399
- Сила: `ResonancePower` от Lv игрока, качества доноров, звёзд, числа слотов
- Лимит: 3 синтеза / день (`ResonanceDaily.SanctumSynth`)

### Дезинтеграция
- 1 дух → Осколки Ками / Звёзды I–III / эссенции линий
- Нельзя, если в ростере останется 0 духов
- Лимит: 8 / день (`ResonanceDaily.SanctumDisintegrate`)

## Предметы
| Id | Имя |
|----|-----|
| 301 | Осколок Ками |
| 310–312 | Звезда трансформации I–III |
| 302–304 | Камень Гармонии / Ядро Разлома / Печать Мики |
| 320–323 | Эссенции Fire/Earth/Wind/Water |

## Квест онбординга
| Id | Имя | Цель | Награда |
|----|-----|------|---------|
| 304 | Звёзды трансформации | `OpenKamiSanctum` (E у shrine) | 2×310 + 1×301 |

Prereq: story **5**. Прогресс типов: `OpenKamiSanctum`, `KamiSynthesize`, `KamiDisintegrate`.

Studio QA: `KamiSanctumBF` → `SeedQA` (Lv10 + copper + 301/310); smoke synth→disintegrate **PASS** 2026-08-01.

**LOOK после синтеза (2026-08-14 SoT PASS):** имя + 3 удара (`*`) + `vid #` + ростер `[R]` + Viewport меш родителя (`SpiritMeshResolve` / `SpiritTemplate` ядра). Не online AI.

**Меш Resonant:** отдельного шаблона нет — `SpiritMeshResolve.CloneResolvedModel` клонирует `SpiritTemplate` по Id / первому `ParentIds` с мешем; иначе геометрический **placeholder** (`IsMeshPlaceholder`). Онлайн AI-меш **отложен** — `SPIRIT-AI-MESH.md`.

## ToS
Слияние / дезинтеграция (машина), без breeding.

## Модули
- `ReplicatedStorage.RealmOfSpirits.KamiSanctumConfig`
- `ServerScriptService.RealmOfSpirits.KamiSanctumSystem`
- `ServerScriptService.RealmOfSpirits.KamiSanctumService`
- Remote `KamiSanctum`
- Client `StarterPlayer.StarterPlayerScripts.KamiSanctumController`
