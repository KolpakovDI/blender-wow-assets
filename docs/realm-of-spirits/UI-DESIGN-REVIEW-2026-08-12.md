# Realm of Spirits — UI/UX Design Review

**Дата:** 2026-08-12 (якорь аудита; актуальное состояние place сверено с docs/`NEXT-SESSION` на 2026-08-20)  
**Аудитория:** ведущий разработчик (код + продукт), не обязательно GD  
**Объём:** анализ и рекомендации. Код не менялся.  
**SoT place:** `C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl`  
**Зеркала UI:** `docs/realm-of-spirits/studio/UIController.lua`, `ZoneController.lua`, `QuestUI.lua`, `ClientController.lua`, `OtakuHavenBuilder.lua`, `WorldLootService.lua`, `PlayerTradeController.lua`

---

## 1. Executive summary

Realm of Spirits уже закрыл самые болезненные «молчания» интерфейса: в бою видны **CD и MP на кнопках**, слот 2 реально жмётся, **EndBattle** даёт понятный toast, сумки показывают **имена из ItemCatalog** (а не `#102`), Exit в хабе **не гасится** billboard’ом, у двери подсказывают про **кристаллы (E)**. Это правильный фундамент для коллекционерского RPG-цикла «поймай → сразись → вернись».

Главный риск сейчас не «нет UI», а **разрозненность и шум**: несколько независимых toast-каналов (Zone / Haven / Trade / NotificationFrame), нижняя панель действий рядом с зоной мобильного стика, сумки как текстовый список без иконок/сравнения, и онбординг первых 60 секунд всё ещё держится на цепочке текстовых подсказок вместо одного ясного «следующего шага». Для Roblox (телефон + ПК) это критично: экран маленький, внимание короткое, лишний toast = игрок не читает следующий.

**Вердикт:** UI функционально достаточен для P0 core/Hub и Explore slice 1; до «кайфа за 10 минут» не хватает дисциплины иерархии (что важно прямо сейчас), единого канала обратной связи и мобильной проверки нижней панели. Ниже — конкретные P0/P1/P2 без декоративных рефакторов ради красоты.

---

## 2. Method + sources

### Метод

1. Прочитаны продуктовые якоря: `NEXT-SESSION.md`, `WEEK-PLAN-2026-08-19.md`, `GOALS.md` (P0 Hub / Explore).  
2. Разобран клиентский UI: `UIController` (бой, сумки, catch, toasts), `ZoneController` (wayfind/Exit), `QuestUI`/`QuestTrackerHud`, billboards в `ClientController`/`OtakuHavenBuilder`, Explore loot prompts.  
3. Studio MCP: place открыт (`RealmOfSpirits second.rbxl`, Edit). Детальный разбор — по docs-зеркалам (SoT логики UI в скриптах).  
4. Сопоставление с открытыми стандартами game UI / FTUE / Roblox Creator Hub / NN/g (когнитивная нагрузка уведомлений).

### Таблица источников (≥8)

| # | Источник | URL | Takeaway (1 строка) |
|---|----------|-----|---------------------|
| 1 | Stonehouse — *User interface design in video games* (Game Developer) | https://www.gamedeveloper.com/design/user-interface-design-in-video-games | Diegetic / spatial / meta / non-diegetic — выбирать тип UI по нужде ясности, а не по «иммерсии любой ценой». |
| 2 | *Diegetic vs Non-Diegetic UI* (Nasty Rodent) | https://nastyrodent.com/diegetic-and-non-diegetic-ui/ | Spatial UI (billboards, world markers) снимает нагрузку с HUD; плохо читаемый diegetic хуже честного оверлея. |
| 3 | Justinmind — *Game UI: design principles* | https://www.justinmind.com/ui-design/game | HUD по краям; в бою критично мгновенное чтение HP/ресурсов/CD без закрытия экшена. |
| 4 | StraySpark — *Ability & Buff System* (cooldown UX) | https://www.strayspark.studio/blog/ability-buff-system-action-rpgs-ue5 | CD = sweep/число + смена состояния «ready»; отдельно показывать «нет ресурса» vs «на CD». |
| 5 | StraySpark — *Inventory players enjoy* | https://www.strayspark.studio/blog/inventory-crafting-system-players-enjoy | Инвентарь — overhead: имена, категории, быстрые действия; не заставлять игрока расшифровывать ID. |
| 6 | WANDR — *Game Menu Design* (inventory) | https://www.wandr.studio/blog/game-menu-design | Паттерн grid + detail: сканирование отдельно от чтения; фильтр должен быть доступен. |
| 7 | NN/g — *Minimize Cognitive Load* | https://www.nngroup.com/articles/minimize-cognitive-load/ | Убирать лишний текст/декор, который не помогает решению; снижать «помнить самому». |
| 8 | NN/g — *Five Mistakes… Push Notifications* | https://www.nngroup.com/articles/push-notification/ | Burst и нерелевантные алерты учат игнору; в игре то же для toast-спама. |
| 9 | Mobile Game Doctor — *FTUE & Onboarding* | https://mobilegamedoctor.com/2025/05/30/ftue-onboarding-whats-in-a-name/ | Первые 60 с / 15 мин — учить делая; системы, не нужные сейчас, прятать. |
| 10 | Nasty Rodent — *Onboarding and FTUE Design* | https://nastyrodent.com/onboarding-and-ftue-design/ | Pull > push: подсказка в контексте действия лучше модалки; FTUE проверять в engine, не в Figma. |
| 11 | Roblox Staff — *Designing UI Tips* (DevForum) | https://devforum.roblox.com/t/designing-ui-tips-and-best-practices/3074034 | Mobile-first, Scale, safe areas, не лезть в thumbstick/jump; toasts ≠ модалки. |
| 12 | Roblox Creator Hub — *On-screen UI / ScreenInsets* | https://create.roblox.com/docs/ui/on-screen-containers | `ScreenInsets` / safe area — иначе кнопки под notch и top bar. |
| 13 | Roblox Creator Hub — *Proximity prompts* | https://create.roblox.com/docs/ui/proximity-prompts | Промпт должен ясно сказать объект + действие + клавишу; world interaction ≠ второй HUD. |
| 14 | Theseus — *Readability… Case Study of Hades* | http://theseus.fi/handle/10024/900621 | Читаемость боя: телеграфы, контраст, HUD/VFX не окклюдируют угрозу; сбой должен быть «понятен одной фразой». |
| 15 | Acagamic — *Video Game Inventory UX* | https://acagamic.com/newsletter/2023/03/21/how-to-unlock-the-secrets-of-video-game-inventory-ux-design/ | Решить: мир паузится или нет при открытии сумки — это часть UX, не «деталь». |

---

## 3. Current UI map (поверхности)

| Поверхность | Где живёт | Тип UI (diegesis) | Что игрок видит / делает | Заметки аудита |
|-------------|-----------|-------------------|--------------------------|----------------|
| **Hub / Otaku Haven** | World + Zone titles + BGM | Spatial + non-diegetic | Колокол, генкан, Мика, манга, Exit | P0 Hub: бренд «магазин» + funnel toast |
| **Мика / Quest** | `QuestUI` (ScreenGui + billboard над NPC) | Non-diegetic modal + spatial marker | Принять/сдать, трекер справа | Камера на NPC; трекер `QuestTrackerHud` |
| **Bags** | `BagsFrame` + `BagContentFrame` | Non-diegetic menu | 9 сумок, список `Имя xN`, валюта | Имена через `ItemCatalog` ✓; нет иконок/use |
| **Battle** | `BattleFrame` низ экрана | Non-diegetic combat HUD | HP/MP bars, skills 1–3, зелье, побег, element tip | CD/MP на кнопках ✓; agency flash |
| **Catch** | `ActionsFrame` + proximity/атрибуты | Non-diegetic + world | «Поймать [E] ×N», подсветка готовности | Нет ловушек → toast в магазин |
| **Trade (магазин / P2P)** | `TradeFrame` / `PlayerTradeController` | Modal | Buy/Sell/Use; обмен T | Отдельный toast GUI (DisplayOrder высокий) |
| **Explore loot** | Billboard + ProximityPrompt (E) | Spatial + prompt | Кристаллы у Exit→Combat, сундуки | Slice 1 PASS; toast «Собран: …» |
| **Wayfind** | `ExitWayfindBillboard` KeepVisible | Spatial | Стрелка/подпись Exit | Не гасится ClientController ✓ |
| **Toasts / hints** | ZoneToast, HavenToast, NotificationFrame, HintFrame, Trade toast | Non-diegetic alerts | Зоны, награды, ошибки CD/MP, EndBattle | **Несколько параллельных каналов** |

### Иерархия DisplayOrder (факт из CHANGELOG / кода)

- `RealmOfSpiritsUI` ≈ 100  
- Zone UI ≈ 150  
- QuestUI ≈ 200  
- Haven / trade / duel выше (trade toast до ~500)

Это правильно для модалок, но **конкурирующие toast’ы** всё равно могут пересекаться по времени и позиции (низ экрана vs центр).

---

## 4. Heuristic scores (1–5)

Шкала: **1** = ломает цикл · **3** = терпимо для прототипа · **5** = уровень «можно показывать незнакомым».

| Критерий | Оценка | Коротко почему |
|----------|--------|----------------|
| **Clarity** | **3.5** | Бой и Exit читаются; сумки/меню ещё «инженерные». |
| **Feedback** | **4** | CD/MP toasts, EndBattle, catch ready, element tip — сильная сторона. |
| **Hierarchy** | **2.5** | Много равноправных панелей + toast-каналов; «что сейчас главное?» не всегда ясно. |
| **Consistency** | **3** | WoWUITheme (дерево/камень/золото) есть; но Haven/Zone/Trade визуально разные семьи. |
| **Cognitive load** | **2.5** | FTUE + zone + prep + element + loot подсказки подряд; NN/g: лишнее = игнор. |
| **Accessibility (цвет+текст)** | **3** | Текст на кнопках спасает (не только цвет CD); мало контрастных иконок; emoji как иконки — риск на части шрифтов. |
| **Onboarding (≤60 с)** | **3.5** | Мика ≤15 с, Exit KeepVisible, toast-маршрут — хорошо; нет одного persistent «следующий шаг». |
| **Combat agency** | **4** | Слоты 2–3, MaxCooldown UI, hotkeys 1/2/3/H — цель E2 закрыта по ощущению. |
| **Inventory literacy** | **3** | Имена каталога ✓; нет «зачем этот кристалл», rarity, quick-use из сумки. |

**Среднее ≈ 3.2** — «играбельный вертикальный срез с ясным боем», ещё не «продуктовый UI».

---

## 5. Findings

### Strengths (уже работает на игрока)

1. **Боевая agency:** подписи `CD · MP`, disabled-состояния, русские отказы («перезаряжается», «недостаточно MP»), hint `1/2/3 · H`. Соответствует практике cooldown readability (источник 4).  
2. **Конец боя не молчит:** победа с copper / поражение / побег — длиннее и яснее toast.  
3. **Hub wayfind:** Exit billboard `KeepVisible` + Zone toast у Exit про кристаллы — spatial UI по Stonehouse/Nasty Rodent (источники 1–2).  
4. **Bag literacy fix:** `ItemCatalog.Get` вместо `Предмет #102` — прямой hit по inventory UX (источники 5–6).  
5. **Catch affordance:** количество ловушек на кнопке + яркий ready-state.  
6. **Explore funnel:** видимый лут у двери (billboards AlwaysOnTop) закрывает «пустой мир» для первого выхода.  
7. **Тема:** `WoWUITheme` даёт узнаваемый dark-fantasy каркас (не generic purple dashboard).

### Risks (сломает доверие, если игнорировать)

1. **Toast overload:** ZoneController + OtakuHaven + UIController.NotificationFrame + Trade + loot. NN/g (8): burst учит «не читать». В первые 60–90 с игрок получает hub intro → prep → Exit crystals → element cycle — это 4 учебных сообщения почти подряд.  
2. **Нижняя action bar vs mobile:** `ActionsFrame` и `BattleFrame` сидят внизу (`1, -70` / `-170`). DevForum Roblox (11): thumbstick/jump занимают углы — риск мискликов и перекрытия.  
3. **Сумки = только чтение:** нет use/equip из bag content; торговля и бой живут отдельно → игрок не строит ментальную модель «инвентарь = действие».  
4. **Два «меню» экономики:** `TradeFrame` (NPC shop) vs P2P trade vs Haven примерочная — разные тосты и потоки.  
5. **Quest tracker vs world:** трекер справа + billboards + zone titles — при одновременном квесте и луте competing focal points.  
6. **Цвет стихий на кнопках** помогает agency, но **low MP vs CD** различаются оттенками серого/фиолетового — без текста было бы плохо (текст есть — держать).

### Gaps (чего нет относительно стандартов)

| Gap | Почему важно | Связь с GOALS |
|-----|--------------|---------------|
| Единый **ToastRouter** (priority + queue + cooldown) | Снизить cognitive load | P0 median ≤10 мин, меньше «не понял награду» |
| **Один primary objective** (FTUE chip): «Иди к Мике» → «Выйди в Exit» | 60 с Hub KR | P0 Hub brand/Mika funnel |
| Bag **icons + rarity + «квест/эво» tag** | Inventory literacy | Explore loot diversity читается |
| Visual **cooldown sweep** (не только текст) | Glanceability в бою | Combat agency ≥70% |
| Mobile/emulator pass нижней панели | Roblox аудитория | Стабильный e2e на телефоне |
| Bag open policy (pause? blur?) | Acagamic (15) | Ощущение «системы», не бага |
| Согласованный **copy tone** (ты/вы, длина) | Consistency | Меньше ощущения «склеенных фич» |

---

## 6. Prioritized recommendations

### P0 — эта неделя (рядом с Explore polish / e2e глазами)

| ID | Рекомендация | Польза игроку | Effort | Acceptance check |
|----|--------------|---------------|--------|------------------|
| **P0-1** | **Очередь toast’ов:** один видимый alert; приоритет (ошибка боя > награда > zone tip); не показывать 2-й, пока 1-й жив | Читает награды и отказы, не «мелькание» | **M** | В прогоне Spawn→Exit→loot за 2 мин на экране ≤1 toast одновременно; zone tip не перекрывает «Собран: Огненный кристалл» |
| **P0-2** | **Persistent next-step chip** (одна строка): после спавна «Поговори с Микой» → после квеста «Выход в Акихабару» → после Exit «Подбери кристалл (E)» | Первые 60 с без догадок | **S–M** | Новый игрок без подсказок чата за ≤60 с у Мики; за ≤4 мин первый лут (уже KR Explore) |
| **P0-3** | **Mobile Device Emulator pass** нижней панели (phone + safe insets): сдвинуть/уменьшить Actions/Battle, не лезть в jump | Можно нажать навык пальцем | **M** | Emulator iPhone: все skill/catch кнопки ≥~44px, не под virtual jump; Play smoke 1 бой |
| **P0-4** | В сумке у квест/эво предметов **короткий зачем-тег** («для эволюции», «квест Мики») рядом с именем | Лут не «мусор с названием» | **S** | Кристалл 101 в сумке: имя + тег; playtester говорит зачем он нужен без открытия вики |
| **P0-5** | **Playtest UI-only 10 мин** (скрипт §8) ×3 человека / 3 своих прогона | Поймать реальные friction до feature creep | **S** | Заметки: 3 top friction; ни одного «не нашёл Exit / не понял CD» |

### P1 — следующий спринт после стабильного Explore diversity

| ID | Рекомендация | Польза | Effort | Acceptance |
|----|--------------|--------|--------|------------|
| **P1-1** | Bag: **иконка + stack** (grid), клик → detail panel (описание ItemCatalog) | Сканирование как в RPG | **L** | Найти ледяной кристалл среди 8 предметов ≤5 с |
| **P1-2** | Skill buttons: **radial/fill CD** + число (текст оставить) | Glance в хаосе боя | **M** | Без чтения мелкого текста видно, какой слот ready |
| **P1-3** | Унифицировать **визуальный язык** Haven toast / Zone toast / Notification (одна рамка WoWUITheme) | Consistency | **M** | Скриншоты: игрок не отличает «три разных игры» |
| **P1-4** | Catch/Battle contextual: прятать нерелевантную кнопку вне контекста (или dim сильнее) | Меньше шума в Safe | **S** | В Safe Catch не «кричит» зелёным без цели |
| **P1-5** | Quest tracker: при фокусе на objective подсвечивать **только** релевантный world cue | Hierarchy | **M** | На квесте 7 трекер и Exit не спорят с 5 billboards лута |

### P2 — после P0 KR / перед тяжёлым Identity UI polish

| ID | Рекомендация | Польза | Effort | Acceptance |
|----|--------------|--------|--------|------------|
| **P2-1** | Gamepad focus graph для Bags/Quest/Trade | Консоль/геймпад | **L** | B закрывает, D-pad по сетке |
| **P2-2** | Опция «меньше подсказок» / once-only tips | Уважение ветеранов | **M** | Повторный вход: нет hub intro spam |
| **P2-3** | Damage/heal numbers + attributable failure (Hades readability) | Понятно почему умер | **L** | После поражения игрок одной фразой называет причину |
| **P2-4** | Словарь UI-копирайта (длина, тон, горячие клавиши) | Consistency | **S** | Чеклист в docs; новые строки проходят |

---

## 7. Anti-patterns (чего не делать)

1. **Generic AI purple dashboard** — градиенты «SaaS», glassmorphism, neon glow поверх аниме-хаба. У вас уже wood/stone/gold — усиливать это, не менять ДНК.  
2. **Card spam** — не оборачивать каждый кристалл/квест/toast в отдельную «карточку с тенью». Карточки только там, где есть выбор (обмен слот, гача результат).  
3. **Ещё один toast «на всякий случай»** вместо правки wayfind/prompt. Если Exit не виден — чинить billboard, не писать пятое сообщение.  
4. **Diegetic ради diegetic:** убирать числа CD с кнопок «для иммерсии» — для Roblox midcore это вред (источники 1, 4, 14).  
5. **Inventory Tetris** без механики-цели — переменный размер слотов ради «как в stalker» убьёт мобильный UX.  
6. **Обучение модалками на паузе** в первые 60 с — FTUE (9–10): учить через Мику + дверь + E, не через 5 экранов текста.  
7. **Дублировать ProximityPrompt и огромную ScreenGui-кнопку** с разным copy («E» vs «Взаимодействовать») — один глагол везде.  
8. **Фича Identity/PvP UI**, пока Explore diversity и toast-дисциплина сырые — `NEXT-SESSION` уже запрещает этот фокус.

---

## 8. Suggested next playtest script (10 мин, только UI)

**Цель:** найти friction интерфейса, не баланс урона.  
**Сетап:** Studio Play (1 игрок), чистый или почти чистый профиль; телефонный emulator **или** запись экрана ПК.  
**Правило ведущего:** не подсказывать голосом; только наблюдать.

| Мин | Шаг | Смотреть |
|-----|-----|----------|
| 0:00–1:00 | Спавн в Haven, свободно оглядеться | Нашёл ли Мику/Exit без чата? Сколько toast’ов прочитал? |
| 1:00–2:30 | Открыть Мику, взять стартовый квест | Понятен ли трекер? Закрывается ли UI без паники? |
| 2:30–4:00 | Дойти до Exit пешком | Billboard Exit? Toast про кристаллы мешает или помогает? |
| 4:00–5:30 | Подобрать кристалл (E), открыть сумки | Имя предмета? Понял ли зачем? |
| 5:30–7:30 | Поймать духа (E) / бой F | Catch ready? В бою нажал skill **2**? Видел CD/MP? |
| 7:30–9:00 | Закончить бой | EndBattle toast: награда ясна? Вернулся ли HUD? |
| 9:00–10:00 | Вернуться / сдача если успел; иначе открыть trade/bags | Что осталось непонятным? |

**После прогона — 5 вопросов (да/нет + одна фраза):**

1. Что было самым важным на экране в первую минуту?  
2. Где искал выход из магазина?  
3. В бою было ясно, почему кнопка серая?  
4. Что лежит в сумке и зачем?  
5. Какой toast запомнился / какой раздражал?

**Pass UI-playtest:** 0 блокеров «не нашёл Exit / не понял ловлю / думал что skill 2 сломан»; ≤1 жалоба на спам подсказок.

---

## Appendix — связь с недельным фокусом

| Цель недели | UI-угол |
|-------------|---------|
| Explore polish глазами | P0-2 chip + P0-1 toast queue у Exit/loot |
| Diversity лута | P0-4 теги + позже P1-1 иконки |
| E1 CONDITIONAL | Скрипт §8 как часть живых e2e |
| Не трогать Identity/décor | Anti-patterns §7.8 |

---

*Документ подготовлен как design analysis only. Реализация — отдельными задачами по P0 таблице.*
