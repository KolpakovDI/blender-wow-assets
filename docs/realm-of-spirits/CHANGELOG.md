# Realm of Spirits — Changelog

Формат: [Keep a Changelog](https://keepachangelog.com/). Версии: SemVer.

---

## [Unreleased]

### Added
- Миникарта: здания/POI (Haven, Вход, Exit, Мика, Акихабара, Арена, спавн, колокол), кристаллы/сундуки в радиусе, подписи и направление взгляда; конфиг `ZoneConfig.MinimapLandmarks`
- P1 Identity: прогресс эволюции в карточке духа (ур./кристаллы/победы + тизер 3-го навыка), announce-баннер `EvolutionSuccess`, ранг и следующий порог в Профиле + кнопка «Ранг →»
- Боевая кнопка зелья здоровья (`UsePotion`, +40 HP, CD 3с, счётчик в UI)
- Hub first-minute guide: Spawn banner/toast → Мика billboard → prep/Exit cues (`ZoneController`)
- Product goals locked: `GOALS.md` + GDD §9 (P0 Core/Hub, P1 Explore/Identity/Social, P2 Scale) — SMART/OKR/питч
- `BattleOrchestrator` — валидация CD/MP/stun, resolve игрока/врага, mana regen; `GameManager` Attack + Enemy AI делегируют в оркестратор
- Боевой UI: третий слот навыка (`Attack3Button`) в `UIController`
- `SkillCatalog` / `EffectCatalog` / `ItemCatalog` — общие каталоги способностей, эффектов и предметов (`ReplicatedStorage.RealmOfSpirits`)
- Otaku Haven 2.0: магазин 76×76, 2 этаж (RoomA/B), anime-лестница, балкон, сплошная черепичная крыша (`roofLift`), фусума дракон/бамбук
- `BattleArenaBuilder` — cyberpunk-арена (портал вход/выход, teal/orange)
- Genkan slippers: визуальные тапочки на ногах в Safe/Genkan, снимаются на Exit/Combat
- Spirit XP за победу в бою + прогресс квеста `LevelUpSpirit`
- `WorldLootService` — огненные кристаллы (ItemId 101) и сундуки в Akihabara для побочных квестов
- QuestUI Focus Mode — камера к Мике при открытии диалога (X/Esc сброс)
- Mika 2D-Live — BillboardGui эмоции Talk/Joy/Panic/Point/Bow над квестором
- Genkan — скрытие уличной обуви + тапочки (подошва/верх/ремешок)
- Mika 2D-Live faces — procedural face panel (глаза/рот/брови) вместо глифов
- Gacha Robux — `MarketplaceService` + `ZoneConfig.GachaRobuxProductId` + prompt R
- Otaku Haven Alpha+: стеклянный фасад с раздвижными дверями, северная стена с выходной дверью в Akihabara, колокольчик на входе (звук), FOMO-таймер лимитированной гачи (2ч), примерочная `FittingRoom`, реплики Мики в Quest UI
- `ZoneConfig.Music` — стартовые SoundId для Safe/Genkan/Exit/Combat (можно заменить своими)
- Мерцание PointLight витрин в `ZoneController`

### Fixed
- `UIController` — навыки в карточке духа из каталога (не плейсхолдеры); кнопка эволюции по реальным требованиям; `rankFrame` открывается из Профиля (раньше никогда не показывался)
- `EvolutionSystem` — при эволюции пишутся `SkillIds`; клиент получает `OldName` / `UnlockedSkill` для announce
- `BellTrigger` / `OtakuHavenBuilder` — колокол на объёме Genkan (раньше offset внутри зала)
- `ZoneController` — hub intro на Spawn, prep toast в Safe, Exit banner, BellTrigger из `ZoneConfig`
- `GameManager` — синтаксис Attack-хендлера (`end)` → `})` после проводки BattleOrchestrator); скрипт снова загружается в Play
- `QuestSystem` — `CatchDifferentSpirits` считает только уникальные SpiritId; AcceptQuest засчитывает уже пойманных духов; `FindChests` прогресс
- `ZoneSystem` — приоритет зон при перекрытии Safe/Genkan/Exit; `CanQuery=true` на zone volumes; корректный Genkan detect стоя
- `MusicController` — треки Genkan/Exit по `ZoneDetail`, а не только Safe/Combat
- `WorldSpawner` удаляет старый `PlayerHouse`, чтобы в мире оставались Otaku Haven + Akihabara
- `ZoneController` — колокольчик срабатывает через широкий входной триггер, а не только через высокую модель колокольчика
- Промпты манги/гачи в place были `Enabled=false` («soon») — включены и локализованы
- `UIController` — защита, если `CreateResourceBar` не вернул fill
- После победы в бою или успешной поимки игра возвращается в обычный режим (основной UI, выбор цели мышью)
- `GameManager` — `SendBattleUpdate` не шлёт обновления после завершения боя (защита от повторного включения боевого UI)
- `UIController` — `EnterNormalMode()` при End/Flee/SpiritCaught/CatchFailed; игнор устаревших `Battle Update`
- `ClientController` — `exitNormalMode()` сбрасывает `isInBattle` и выбор цели

### Changed
- Otaku Haven: вывеска «Otaku Haven» над дверью на балкон; фусума между комнатами ×2 шире + южный коридор; проём на балкон 14 studs
- `SpiritDatabase` — духи на `SkillIds`; shop через `ItemCatalog.ShopIds`
- `GameManager` / `BattleSystem` — используют shared Skill/Effect catalogs (до 3 скиллов)
- `ZoneConfig` — Haven/Safe/Combat сдвинуты (магазин не пересекает Combat); Мика `(-12,-38)`; Safe Z=160; wall2H 2 этажа = 12
- Manga shelf UX: вывеска, floor arrow, понятный prompt и таймер баффа; старые placeholder hints убраны
- `ClientController` — выбор духа мышью (mouse.Target + raycast + GuiInset + screen proximity), подсветка цели, маркер `?`/`⚔` для квестов; выбор работает на любой дистанции, E/F — в радиусе 45 studs
- `UIController` — `MainFrame.Active = false`, чтобы прозрачный UI не перехватывал клики
- `GameManager` — таргетинг по `SpiritInstanceId`, проверка дистанции, удаление пойманной модели
- `UIController` — подсказка цели из `TargetHint`
- `UIController` — HP/MP только в режиме боя; убрана постоянная панель уровня/монет/ранга; полоска опыта (текущий/до след. уровня) над action bar
- `GameManager` — боевые скилы игрока/врага теперь собираются из `SpiritDatabase` (динамические имя/урон/мана/кулдаун), добавлена обработка `Heal`
- `UIController` — боевые кнопки показывают реальные скилы духа, состояние кулдауна/маны и блокируются при недоступности
- `GameManager` — добавлена базовая система эффектов скилов (`Burn`, `Stun`, `Buff/Debuff Attack/Defense`) с пошаговым применением в бою для игрока и врага
- `EvolutionSystem` — эволюция переведена на единую `SpiritDatabase` (имя/статы/скилы эволюции теперь берутся из общего каталога духов, без отдельной копии в системе эволюции)
- `ZoneConfig.Music` + `MusicController` — поддержка зональных треков `Safe/Genkan/Exit/Combat`, нормализация `SoundId` (`id` или `rbxassetid://id`) и единый кроссфейд по текущей зоне
- `QuestUI` — компактный диалог Мики сверху: вкладки, скролл-список квестов, окно описания до кнопки Принять/Сдать; focus-камера и face-to-face
- `ZoneController` — баннер «Otaku Haven» справа сверху (не перекрывает диалог Мики)
- `QuestMasterBehavior` — Live2D emoji billboard над Микой отключён

### Applied (2026-07-14)
- P0 Core E2E play-тест подтверждён (квест/ловля/бой); фокус сдвинут на P0 Hub
- P1 Identity UX + QuestUI layout + ZoneBanner offset — зеркала в `docs/.../studio/`

### Applied (2026-07-11)
- Studio: пересборка Otaku Haven (`OtakuHavenBuilder.Build()`), Play-тест — все системы загружаются без ошибок
- Проверены модули: WoWUITheme, BuffSystem, OtakuHavenService, ZoneSystem, SpiritAnimation, UIController (themed)
- Исправление raycast для духов и `CanQuery=false` на зонах — в Studio
- Приветственный текст UI убран; баннер Safe Zone не показывается при спавне

### Planned
- PvP, новые зоны, звук

### Added
- WoW-style UI theme: `WoWUITheme` module + restyled `UIController` (unit frame, HP/MP gems, minimap ring, action bar)
- UI asset sheet + slice script (`assets/ui-asset-sheet.png`, `docs/realm-of-spirits/assets/slice_ui_sheet.py`)
- `OtakuHavenService` — ProximityPrompt: manga, gacha (50 copper), fitting room → Trade UI
- `OtakuHavenController` — toast, таймер баффа, открытие магазина из примерочной
- `MusicController` — кроссфейд BGM по зоне (Lo-Fi / J-Rock, asset id в ZoneConfig.Music)
- `RemoteEvent` `OtakuHaven`, `ZoneChanged` в RealmOfSpirits
- Примерочная (`FittingRoom`) в Otaku Haven
- Cursor project hooks (`.cursor/hooks.json`) для напоминания об обновлении changelog после игровых правок и запуска локальных sanity-check скриптов
- Dev-утилиты: `scripts/validate_spirit_database.py` и `scripts/battle_sanity_check.py`
- CI-like quality gate: `scripts/quality_gate.py` + GitHub workflow `.github/workflows/realm-quality-gate.yml`
- Профили hooks: `.cursor/hooks.dev.json` (мягкий) и `.cursor/hooks.strict.json` (строгий)
- Утилита переключения профиля: `scripts/switch_hooks_profile.py`
- Документация автоматизаций: `docs/realm-of-spirits/AUTOMATION.md`
- `validate_spirit_database.py` усилен контрактными проверками скилов/эффектов (`Type`, `Damage`/`HealAmount`, `Effect.Type/Duration`)

### Changed
- `GameManager` — урон игрока умножается на `BuffSystem.GetDamageMultiplier`
- `DataStoreManager` — поля `Buffs`, `Cosmetics` в дефолтных данных
- `OtakuHavenBuilder` — активные prompt'ы manga/gacha, fitting room
- `ZoneConfig.Music` — placeholder для SoundId
- `OtakuHavenBuilder` — процедурная постройка Safe Zone (пол, стены, неон, стойка, genkan, LED, постеры, gacha/manga placeholders)
- `ZoneSystem` (server) + `ZoneController` (client) — атрибуты зоны, баннеры Safe/Combat, колокол у входа
- `RemoteEvent` `ZoneChanged` в RealmOfSpirits
- Модели `Workspace.OtakuHaven` и `Workspace.Akihabara` с зонами Genkan / Safe / Exit / Combat
- Исходники Studio-скриптов: `docs/realm-of-spirits/studio/*.lua`

### Changed
- `WorldSpawner` строит Otaku Haven, переносит SpawnLocation в genkan и QuestMaster к стойке (имя «Мика · Квестор»)
- `GameManager` берёт `SpiritSpawnPositions` из `ZoneConfig` (духи в Akihabara, не в магазине)
- GDD v2.0: добавлен сценарий Safe Zone «Otaku Haven» (4 сцены, реализация в Studio)
- Летающие духи постоянно машут крыльями и парят над землёй (не выше роста игрока); наземные при ходьбе двигают ногами от «бедра», без отрыва от тела
- QuestMaster переделан в аниме-регистратора гильдии (Алиса): униформа, эльфийские уши, кошачий хвост, книга регистраций и гусиное перо
- Анимации NPC: поклон при разговоре, радость при сдаче квеста, chibi-реакция при провале

### Fixed
- Наземные духи при ходьбе прижаты к земле (raycast каждый шаг), ноги двигаются от «бедра» без отрыва от тела
- Летающие духи (2, 4) постоянно машут крыльями (Heartbeat), парят над землёй не выше роста игрока (~5 studs)
- Raycast для земли игнорирует невидимые зоны (CombatZone/SafeZone) и других духов — все модели стоят на Baseplate/Terrain
- Прогресс квестов обновляется при поимке духа и победе в бою (`UpdateQuestProgress` в GameManager)
- При открытии панели квестов у квестора показывается вкладка «Активные», если квест готов к сдаче
- Духи спавнятся целыми моделями (исправлен `GetSpirit`, убрана анимация по частям)
- Дубликаты моделей духов убраны из Workspace в ServerStorage
- QuestMaster выравнивается по земле при загрузке мира и сохраняет вертикальную ориентацию (не падает на бок)
- Квесты сдаются квестору: после выполнения целей статус «Готов к сдаче», награды при сдаче
- Над QuestMaster появляется «?» когда есть квесты, готовые к сдаче

---

## [0.2.0] — 2026-07-11

### Added
- `ReplicatedStorage.RealmOfSpirits.SpiritDatabase` — единый ModuleScript (духи 1–5, эволюции 101–105, ElementChart, ShopItems, CalculateDamage)
- `ServerScriptService.RealmOfSpirits.TradeSystem` — покупка, продажа, использование свитка опыта
- Обработчик Trade в GameManager (GetShop / Buy / Sell / UseItem)
- UI магазина в UIController (кнопка «Магазин», панель товаров и инвентаря)

### Changed
- GameManager, BattleSystem, UIController используют общий SpiritDatabase
- WorldSpawner упрощён: только генерация мира, спавн духов — через GameManager
- BattleSystem упрощён: делегирует расчёт урона в SpiritDatabase

### Fixed
- Награды за бой и прокачку начисляют `CopperCoins` вместо несуществующего `Coins`
- LevelingSystem и RankSystem работают с `CopperCoins`
- Удалён тестовый `MCP_Test_Part` из Workspace
- Удалён дублирующий/битый код в WorldSpawner и BattleSystem

---

## [0.1.0] — 2026-07-11

### Added
- Документация проекта: PROJECT.md, GDD.md, CHANGELOG.md
- Cursor rule для отслеживания изменений
- MCP-подключение Cursor ↔ Roblox Studio (проверено: list_roblox_studios, execute_luau)

### Documented (текущее состояние place)
- 5 базовых духов с anime MeshPart моделями (SpiritTemplate1-5)
- GameManager: бой real-time, ловля, HUD духов, анимация смерти
- QuestSystem: 6 сюжет + 5 побочных квестов, QuestMaster NPC
- WorldSpawner: генерация мира (дом, арена, горы, деревья)
- DataStoreManager v2: autosave, player data structure
- EvolutionSystem: 5 эволюций (101-105)
- LevelingSystem: 100 уровней, 12 skill unlocks
- RankSystem: D through SSS
- UIController: программный GUI (1574 строк)
- 8 RemoteEvents в ReplicatedStorage.RealmOfSpirits

### Known Issues (на момент v0.1.0)
- SpiritDatabase дублировался в GameManager, BattleSystem, WorldSpawner, UIController
- WorldSpawner создавал простые Part-духов, GameManager — MeshPart templates
- LevelingSystem/RankSystem: поле Coins не совпадало с DataStore (CopperCoins)
- BattleSystem Script содержал класс, но не использовался
- Trade RemoteEvent без серверной логики
- MCP_Test_Part в Workspace (тестовый объект)
