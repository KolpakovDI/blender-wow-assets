# NEXT SESSION

**Статус:** **P1 Identity** — UX shipped в Studio (нужен play-тест + Ctrl+S).

Дата якоря: 2026-07-14

## Цели (locked)

См. [`GOALS.md`](./GOALS.md) и GDD §9.

| Done | P0 Core + P0 Hub |
| Now | **P1 Identity** — play-тест критериев ниже |
| Later | Explore / Social → P2 Scale по gate |

## P1 Identity — критерии

1. ≥80% эволюций открывают Skill slot 3 в боевом UI
2. Guided path до первой эволюции ощутим (кристаллы + lvl + battles)
3. Ранг / следующий порог ≤2 клика в UI
4. Announce/feedback при эволюции (не тихий swap)

## Что уже в place (Ctrl+S обязателен для .rbxl)

- Карточка духа: реальные навыки, прогресс эволюции, кнопка по lvl/кристаллам/победам
- `EvolutionSuccess` → баннер + 3-й навык; сервер пишет `SkillIds`
- Профиль: следующий ранг; «Ранг →» открывает `rankFrame`
- QuestUI: узкая панель сверху, список квестов со скроллом, описание до Принять/Сдать
- ZoneBanner «Otaku Haven» справа; Live2D emoji над Микой выключен

## Play-тест (следующий шаг)

1. **Ctrl+S** place: `C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl`
2. Дух → детали: навыки из каталога, строка «→ форма / ур / кристаллы / победы»
3. Собрать 5× огненный кристалл (Akihabara), lvl 10, 10 побед → ЭВОЛЮЦИЯ → баннер
4. Бой после эво: виден Attack3
5. Профиль (1 клик) → следующий порог; «Ранг →» (2 клик) → детали ранга

## Place

`C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl` — **Ctrl+S**
