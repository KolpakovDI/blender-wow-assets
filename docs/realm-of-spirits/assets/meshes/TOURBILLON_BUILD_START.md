# Tourbillon — СТАРТ СБОРКИ (2026-07-20)

Команда пользователя: **СТАРТ СБОРКИ**.  
Сопоставление всех накопленных рефов + открытые источники → инструкции и build в Blender.

## 1. SoT размеров (подтверждено)

| Параметр | Значение | Источник |
|----------|----------|----------|
| L | **4.671 m** | PDF Tech Specs 06.2024 + SIDE/TOP refs |
| W (без зеркал) | **2.051 m** | PDF + FRONT ref |
| W + mirrors | 2.165 m | PDF |
| H | **1.189 m** | PDF + SIDE |
| WB | **2.740 m** | PDF + SIDE |
| Земля | **z = 0** | пунктир на SIDE/FRONT |
| Бюджет | **&lt; 15 000 tris** | проект |
| Брендинг | **нет** на меше | протокол |

Оси: нос **+Y**, ширина **±X**, вверх **+Z**. Центр кузова ≈ (0,0,0) по XY; шины касаются z=0.

Передняя ось y = **+1.386**; задняя y = **−1.354**.

## 2. Сопоставление рефов → что моделировать

| DNA / узел | Откуда | Правило LP |
|------------|--------|------------|
| Силуэт SIDE, арки, WB | `tourbillon_side_wb274_h119` | Кабина вперёд; overhang зад ≥ перед; колёса заполняют арки |
| Wasp-waist, spine | `top_L467` + `top_color` | hw(y): нос узкий → F широко → талия → R шире/равно → хвост сужается |
| Horseshoe + intakes + splitter | `front_W205` + 3Q front | Одна фасция; horseshoe центр; intakes flanking |
| Фара = часть решётки | `detail_headlight_grille` | 4 модуля/сторона (L + точки) в горизонтальном слоте; overhang; honeycomb ниже = texture/alpha |
| C-line + side intake | SIDE + 3Q front/rear | Bevel strip A-pillar → roof → вниз в intake → порог |
| Rear LED wave + diffuser | 3Q rear L/R elev. + ortho4 | Full-width bar; deep diffuser fins |
| Edge-flow / densify guide | `ortho4_wireframe` + 3Q wires | Только гайд топологии → **упрощать** до &lt;15k |
| Колёса Y-spokes | 3Q front | LP Y-rim + cylinder tire; F Ø≈0.71 / R Ø≈0.74 |

Конфликт 3Q rear-left (более «open») vs SIDE coupe: **приоритет SIDE/TOP/FRONT ortho** для силуэта; 3Q — детали C-line / diffuser / LED.

## 3. Пайплайн Blender (порядок)

1. **Scene** — metric, 1 BU=1 m; Empty `TourbillonCar`; bbox wire; оси F/R; image empties SIDE/FRONT/TOP (не в export).
2. **Body half** — loft stations по SIDE×TOP (`hw(y)`, `z_roof(y)`, `z_rocker`); Mirror X; merge.
3. **FRONT** — horseshoe rim + mesh plane; brow LEDs 4×L/R; intakes; splitter (carbon).
4. **REAR** — LED bar (emission); diffuser strakes; spine hint.
5. **C-line** + side intakes (L/R).
6. **Glass** — windshield + side (transparent); проёмы в Body.
7. **Wheels** FL/FR/RL/RR в арках на z=r.
8. **Materials** — Paint / Dark / Carbon / Chrome / Mesh / Glass / LED.
9. **Ortho check** vs refs → правка.
10. Save `bugatti_tourbillon_lp.blend` + FBX; tris count.

## 4. Бюджет tris (ориентир)

| Часть | Tris |
|-------|------|
| Body + Mirror | 6000–8000 |
| C-line + intakes | 800–1200 |
| Front group | 1200–1800 |
| Rear group | 800–1200 |
| Glass | 400–600 |
| Wheels×4 | 2400–3200 |
| **Итого** | **&lt; 15 000** |

Honeycomb / tread / dense grilles → **текстура**, не геометрия.

## 5. Иерархия (как в TOURBILLON_MODELING_BRIEF.md §7)

`TourbillonCar` → Body, CLineL/R, SideIntakeL/R, FrontGroup, Windshield, SideGlass, RearGroup, MirrorL/R, WheelFL…RR.

Подробные станции / высоты: см. `TOURBILLON_MODELING_BRIEF.md` §§3–6.

## 6. Приёмка

- [ ] L×W×H ≈ 4.671×2.051×1.189; WB 2.740  
- [ ] SIDE / FRONT / TOP / REAR читаются по рефам  
- [ ] Horseshoe + 4×LED + фара-в-решётке  
- [ ] C-line → side intake  
- [ ] Rear full-width LED + diffuser  
- [ ] Tris &lt; 15k; без логотипов  
