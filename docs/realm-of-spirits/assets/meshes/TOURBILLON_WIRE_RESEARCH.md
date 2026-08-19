# Tourbillon Wire — исследование рефов + SoT (с нуля)

Дата: 2026-07-20  
Статус: **RESET** — предыдущая LP-сборка забыта; сцена Blender очищена.

> Игра / меш: **без** брендовых логотипов. Форма Tourbillon-like.

---

## 1. Габариты SoT (свободные источники)

| Параметр | Значение | Источник |
|----------|----------|----------|
| Длина | **4671 mm** (4.671 m) | [Bugatti Tech Specs PDF 06.2024](https://bugatti-newsroom.imgix.net/6675179393f6515cdb966608/technical-specifications-bugatti-TB-en.pdf), bugatti.com |
| Ширина (без зеркал) | **2051 mm** (2.051 m) | PDF / bugatti.com |
| Ширина + зеркала | 2165 mm | PDF |
| Высота | **1189 mm** (1.189 m) | PDF |
| Колёсная база | **2740 mm** (2.740 m) | PDF |
| Шины F / R | 285/35 R20 / 345/30 R21 | вторичные сводки (Autotijd и др.) |

**Blender (1 BU = 1 m), нос = +Y, земля z = 0:**

```
X ∈ [−1.0255, +1.0255]
Y ∈ [−2.3355, +2.3355]
Z ∈ [0, 1.189]
YF = +1.386    YR = −1.354
rF ≈ 0.354     rR ≈ 0.370
```

Свесы EST: перед ~0.95 m, зад ~0.98 m.

---

## 2. Сетчатые рефы — что анализировали

### 2.1 Ortho 4× wire — `tourbillon_ortho4_wireframe.png`

| Вид | Ориентация / содержание |
|-----|-------------------------|
| **TOP** | Teardrop, центральный spine, wasp-waist, широкие арки, венты моторного отсека |
| **SIDE** | Нос **влево** на листе; C-line; cab-forward; плотная сетка на арках/спицах |
| **FRONT** | Horseshoe, 4×LED/сторона, боковые intakes, splitter |
| **REAR** | Full-width light bar, dense diffuser/exhaust mesh |

Кроп SIDE: `crops/crop_side_wire.png` (+ варианты noseR / matchY).  
Силуэт: `crops/crop_side_wire_sil.json`.

**Важно:** топология на листе визуально близка к семейству **Chiron** (плотность, C-line, фасция). Это **гайд формы/edge-flow**, не источник мм. Мм = §1 Tourbillon.

### 2.2 ¾ wire

| Файл | Ракурс | DNA для модели |
|------|--------|----------------|
| `tourbillon_3q_front_right.png` | ¾ спереди справа | Horseshoe + brow LED, C-line, Y-spokes, interior hint, арки |
| `tourbillon_3q_front_right_b.png` | то же, плотнее | Уточнение фасции / badge-zone (без лого на меше) |
| `tourbillon_3q_rear_left.png` | ¾ сзади слева | Diffuser fins, rear openings, C-line с кормы; может быть «открытее» coupe |
| `tourbillon_3q_rear_right_elevated.png` | ¾ сзади справа сверху | Rear deck, spine, retracted wing, densе rear fascia |

Приоритет силуэта кузова: **SIDE ortho wire** → TOP → FRONT/REAR → ¾ для объёма и швов.

### 2.3 Конфликт платформ

| | Wire-рефы (визуал) | SoT проекта |
|--|-------------------|-------------|
| Платформа-вид | Chiron / близкий hypercar mesh | **Tourbillon** proportions |
| WB | ~2.71 m (Chiron) на многих сайтах | **2.740 m** |
| L / H | ~4.54 / ~1.21 | **4.671 / 1.189** |

→ Масштабируем/лофтим **форму** под Tourbillon bbox; не копируем мм Chiron.

---

## 3. DNA модели (сетка → будущие части)

Единый `BodyWire` сейчас; позже резать:

| Часть | Как читать на wire |
|-------|-------------------|
| **Дверь** | Панель внутри C-line; shut-line A-pillar → порог → intake |
| **Фары** | 4 модуля в горизонтальном слоте = часть передней решётки (`detail_headlight_grille`) |
| **Колёса** | Отдельные hubs на YF/YR; Y/multi-spoke LP |
| **C-line** | Главный боковой loop (chrome later) |
| **Horseshoe / intakes / splitter** | FRONT |
| **Rear LED + diffuser** | REAR / ¾ rear |

---

## 4. Пайплайн сборки (этот проход)

1. Очистить сцену  
2. Guides: bbox + оси F/R + земля  
3. `BodyWire` — half loft SIDE×TOP, Mirror, арки, **Wireframe display**  
4. `Wheel*` — простые цилиндры-плейсхолдеры (отдельно)  
5. Сохранить `tourbillon_wire_v0.blend`  
6. Позже: материалы, split door/HL/wheels  

Бюджет цели: **&lt; 15k tris** на game-ready; wire v0 может быть ~3–8k.
