# Realm of Spirits — Changelog

Формат: [Keep a Changelog](https://keepachangelog.com/). Версии: SemVer.

---

## [Unreleased]

### Q3 Slice 2: Haven duel wayfind (2026-08-18)
- У Exit: указатель «Дуэль → арена» (`EnsureDuelWayfind`) + жёлтая плита `PvPDuelHostHaven` (Y / Interact)
- Знаки дороги Haven↔арена на русском; хост дуэли вызывается и из хаба

### Q3 Slice 1: fair duel harden (2026-08-16)
- `PvPDuelSystem.resolveDuelSpiritInfo` — Resonant/Ками (9xxx) больше не «Ошибка духа» на старте дуэли
- Победа при `WIN_COPPER=0`: toast «(слава)», без начисления меди / «+0 🥉»
- `PvPDuelHost` Billboard: «Дуэль · Y / Interact» (обновляет существующий хост)
- Hands: Local Server 2p дуэль **PASS** 2026-08-18

### Meta: E1 OWNER SKIP (2026-08-16)
- Formal hands n≥10 пропущен владельцем («всё работает»); friction #1–6 закрыты кодом
- Year-plan gate E1 снят; `ExpansionGate` Allow* не трогали (нужен явный unlock)

### Fix: Resonant Kami missing from spirit slots after synth (2026-08-16)
- FullSync / деталь духа требовали запись в `SpiritDatabase` — Id 9xxx Resonant отбрасывался → пустые слоты после слияния всех
- `ResolveOwnedSpiritDisplay`: имя/элемент с инстанса; слоты + SpiritDetail; soft-fill списка Ками если FullSync ещё пуст

### Fix: shop prices truncated / unaffordable unclear (2026-08-16)
- Цена была в одной строке с именем → `TextTruncate` срезал её в узкой колонке
- Отдельная строка «Цена: …», дубль на кнопке «Купить»; зелёный / красный + «(мало)» по кошельку
- После Buy/Sell/FullSync `RefreshAfford` пересчитывает цвета, пока панель открыта

### Added: Осколок Ками в магазине (2026-08-16)
- Item `301` в `ShopIds`: цена 120 меди, DailyBuyCap 5 — без MCP-grant для Sanctum loop
- E1-HANDS-LOG: таблица #1–6 FAIL починена (дубликаты убраны)

### Fix: Kami synthesize Error "copper" (2026-08-16)
- Слияние смотрело только `CopperCoins` (0–99 после нормализации), игнорируя серебро/золото → ложный отказ
- Оплата/проверка по сумме меди; UI: «Недостаточно монет…» вместо сырого `copper`

### Fix: battle defeat wiped spirits/loot/skills UI (2026-08-16)
- Поражение звало `LoadCharacter` → `StarterGui` клонировал `UIController` заново с пустым `PlayerData`
- SoftRespawn (хил + TP на спавн) без смерти; `UIController` → `StarterPlayerScripts`; `ResetPlayerGuiOnSpawn=false`; FullSync после смерти/поражения

### Fix: Temper (Закалка) no UI / pedestal dead (2026-08-16)
- Пьедестал слал `OpenTemperPicker`, клиент не обрабатывал → «Закалка не работает»
- `TemperPickerFrame`: Атака / Защита / Дух; кнопка ЗАКАЛКА и пьедестал открывают пикер
- Яснее fail: мало Stam / нужен камень закалки

### Fix: Care quest 301 not completing after Resonance (2026-08-16)
- Studio: `UpdateQuestProgressBF:Invoke(player, …)` вместо `UserId` → BF возвращал `no player`, а `pcall` считал успех — прогресс CareSpirit не писал
- `pushCareQuest` / Temper: сначала `_G.UpdateQuestProgress`, BF с `player.UserId` + проверка `result == true`
- `QuestQaBF.resolvePlayer` принимает Player или UserId

### Fix: SpiritDetail empty unclosable panel (E1 FAIL #2, 2026-08-16)
- `RealmOfSpiritsUI` был `ZIndexBehavior.Global` + `SpiritDetailFrame.ZIndex=50` → фон рисовался поверх детей (пустое окно, «Закрыть» не кликался)
- `ZIndexBehavior.Sibling` + bump ZIndex детей панели

### Fix: QuestUI Accept button missing (E1 FAIL #1, 2026-08-16)
- `CareSpirit`/`TemperSpirit` в `showQuestDetail` падали на `progress.Current` при Available → кнопка «Принять» не создавалась
- Автовыбор квеста при открытии списка (приоритет Q7 «Украденная манга»); футер Accept крупнее

### Fix: UIController 200 locals (2026-08-16)
- Play: `Out of local registers … HandleShopZoneActivation` — магазин вынесен в `TradePanelUI` ModuleScript
- Smoke PASS: `UI Controller загружен!` + TradeFrame/BattleLogScroll/DexPanel на клиенте
- MCP hands buffer post-fix: HubFunnel Complete + бой V/Keypad vs Огненный Кот + ScoutPost — `SESSION-2026-08-16b-mcp-hands-buffer.md`
- Kami без ForceCatch: SeedQA → Care/Temper → Sanctum Open — `SESSION-2026-08-16c-kami-care-temper.md`
- Шаблон честного E1: `E1-HANDS-LOG.md` (n≥10, F/E/1/2, без MCP-читов)

### Trade UI scroll (2026-08-15)
- `UIController` TradeFrame: `ShopScroll` / `InventoryScroll` + CanvasSize; списки больше не вылезают за рамку
- CareRewardCard уезжает под activity bar, если магазин открыт; TradeFrame ZIndex=55 — Play smoke PASS
- Trade rows: `ItemName` + TextTruncate слева от Купить/Продать; миникарта — точки QuestLocations/ScoutQuestor
- SeasonPass body → ScrollingFrame (`BodyText`); Actions тоже ScrollingFrame
- Кнопка **Магазин** в ActionsFrame; GetShop больше не спамит при входе в Genkan; `OpenTrade` открывает панель
- SeasonPass **EventShop** ×5 офферов (не только seasonal_form); SkillsScroll; minimap без `continue`
- SpiritDetail: `DetailSkillsScroll` + разведены Resonance/Evo/кнопки (высота 450)
- KamiSanctum: LookPreview справа от списка (не поверх Превью/Слить/Status); TextTruncate имён
- DexPanel: `DexScroll` для списка стихий; BagContentUI: скролл длинного описания предмета
- BattleLogScroll справа (история ходов); CareReward TextTruncate; QuestTracker H=200; P2P trade TextTruncate
- NextStepChip шире + TextTruncate; Season HowBodyScroll; имена слотов духов Truncate
- Haven wardrobe/pass TextTruncate; HintFrame TextTruncate
- Toast/NotificationFrame шире + TextTruncate/ClipsDescendants
- ActivityBar + ProfileRank TextTruncate
- RankFrame: `RequirementsScroll` для длинного списка требований
- BattleLog auto-scroll fallback AbsoluteSize; PlayerInteract Desc TextTruncate
- FlexBillboard (косметика над головой) TextTruncate
- SpiritDetail имя TextTruncate

### MCP hands buffer (2026-08-15l)
- HubFunnel Complete + бой V/Keypad + Kami без ForceCatch + ScoutPost; ExpansionGate locked — `SESSION-2026-08-15l-mcp-hands-buffer.md`
- E1 глазами n≥10 всё ещё CONDITIONAL (не закрыт этим буфером)
- `OtakuHavenService.hookPlayerFlex` — guard `typeof(player)`

### Q2 music + exploration dialogue (2026-08-15k)
- ZoneConfig/MusicController: BGM keys для QuestLocations
- QuestUI: реплики 8–16 / 107–112 + ScoutQuestor; Play MossGlade VisitZone PASS — `SESSION-2026-08-15k-q2-music-dialogue.md`

### Q1 ZoneHint UI + VisitZone smoke (2026-08-15j)
- QuestUI / NextStepChip / QuestTrackerHud показывают ZoneHint; QuestAccepted несёт hint
- Список квестов: subtitle ZoneHint; ZoneController баннеры QuestLocations (ScoutPost…)
- Play: quest 8 FrostRidge + quest 107 ScoutPost VisitZone PASS; pads×6 + ScoutQuestor
- Quest **16** Моховая поляна (MossGlade) — `SESSION-2026-08-15j-zonehint-ui.md`
- Haven **BrandAccents** lanterns in SoT + `OtakuHavenBuilder.Build`

### Risk mitigation year expansion (2026-08-15i)
- `ExpansionGate` (defaults false) + ProfileService / SpiritMesh stubs + Guild fail-closed
- `validate_quest_catalog.py` in quality_gate; no QuestSystem `continue`; Scout → `_G.RoS_OpenQuestUI`
- Docs: `RISKS-MITIGATION.md` · SESSION `15i-risk-mitigation`

### Year expansion C+A (2026-08-15h)
- Roadmap: `YEAR-PLAN-2026-10.md` · баланс: `QUEST-BALANCE.md`
- **QuestCatalog** ModuleScript + `VisitZone`; Story 1–3/7 ZoneHint; exploration 8–15; side 107–112
- **Q2:** `ZoneConfig.QuestLocations` ×6 + WorldSpawner pads/landscape + ScoutQuestor
- **Q3:** PvP fair `WIN_COPPER=0`; Haven `BrandAccents` lanterns
- **Q4 stubs:** `ProfileServiceAdapter`, `GuildSystem` thin (`/guild`), AI mesh gated to Q4 in `SPIRIT-AI-MESH.md`
- SESSION: `SESSION-2026-08-15h-year-expansion.md`

### Month plan 15.08–14.09 (2026-08-15)
- Тема: **soft-launch + play-test KR** (publish/DS → hands sample → friction/Kami → wrap) — `MONTH-PLAN-2026-08-15.md`
- Вне scope: AI mesh, новая PvP/guilds, декор Haven, ProfileService rewrite
- **W1 PASS** 15.08d: M1.1 PlaceId=`130832500076229`; M1.2 DS rejoin (ForceCatch→Stop→Play spirits/Exp); M1.3 quality_gate; M1.4 MCP бой+HubFunnel — `SESSION-2026-08-15d-month-w1-ops.md`
- **W2 PASS CONDITIONAL** 15.08e: HubFunnel Complete; 5× MCP бой win; `RequestWardrobe`→`MarkHubPrep` в SoT — `SESSION-2026-08-15e-month-w2.md`
- **W3 PASS** 15.08f: Kami без ForceCatch (Ками-Корни `#9384`); Care/Temper; Sanctum `[R]`; agency Keypad1+2 — `SESSION-2026-08-15f-month-w3.md`
- **W4 PASS** 15.08g: soft-launch wrap; E1 CONDITIONAL + план рук; октябрь = hands E1 n≥10; фаза 3 gated — `SESSION-2026-08-15g-month-w4-wrap.md`

### Project completion phase 1 (2026-08-15)
- Roadmap: `PROJECT-COMPLETION.md` — shippable demo (фаза 1); soft-launch / scale = фазы 2–3
- **Dex Resonant**: `SpiritResonance.GetDexBonus` резолвит элемент через roster / `ParentIds[1]` (Id 9xxx не `"Unknown"`)
- **Sanctum UX**: успешный `Open` сбрасывает sticky Status «Ошибка: …» → idle hint
- Буфер: hands e2e n≥10 / Kami без ForceCatch; не AI mesh / не PvP

### Hub funnel instrumentation (2026-08-15c)
- `HubFunnel` ModuleScript: дневные флаги **Mika / Prep / ExitCombat** на `playerData`
- Хуки: QuestSystem (GetQuests/Accept), OtakuHaven (манга/гача/wardrobe), ZoneSystem (Safe→Combat)
- Edit smoke `Complete=true` — `SESSION-2026-08-15c-hub-funnel.md`

### DataStore session lock (2026-08-15b)
- `DataStoreManager`: load/save через **`UpdateAsync`** + soft `_Session` lock (JobId/Time, 30 мин); leave/BindToClose release
- Нет `SetAsync` на player key; DoNotSave при чужом lock / load fail — `SESSION-2026-08-15b-datastore-session-lock.md`
- Publish + API Services для live round-trip — ещё ops

### Week wrap 26.08–01.09 (2026-08-14f, досрочно)
- **W1–W4 PASS** — Resonant loop + P0 friction закрыты; SoT Ctrl+S ~22:55 — `SESSION-2026-08-14f-week-wrap.md`
- След. фраза: **hands-цикл Ками** (синтез→бой→уход→Sanctum) + e2e глазами; E1 ×N буфер; не AI mesh / не PvP
- **Hands-цикл MCP PASS** (2026-08-14g): Ками-Глыба → удар «Огненный коготь» → Care+Temper → Sanctum `[R]` — `SESSION-2026-08-14g-kami-hands-loop.md`

### Week plan 26.08–01.09 (2026-08-14)
- Тема: **Resonant loop + P0 friction** (Ками в бою и Care/Temper; лут E без костыля) — `WEEK-PLAN-2026-08-26.md`
- **W1 PASS**: Crystal_120 **E** без ручного Enabled; бой **V**+Keypad1/2 победа — `SESSION-2026-08-14c-w1-friction.md`
- **W2 PASS**: Resonant Start больше не no-op — `ResolveBattleSpiritInfo` в `GameManager` (Id 9xxx / Kind Resonant → stats ядра + `SkillIds` roster); smoke слот 1 «Землетрясение» в бою — `SESSION-2026-08-14d-w2-resonant-battle.md`
- **W3 PASS**: Care + Temper на активном Resonant с toast/UI (`Уход выполнен` / `Закалка +Attack`); Source не меняли — `SESSION-2026-08-14e-w3-resonant-care-temper.md`
- Wrap: см. блок выше

### Week wrap + Sanctum LOOK (2026-08-22)
- Неделя 19–25.08: E4 / Explore W3 / UI A–D / Identity 1–3 закрыты по коду; след. неделя = **Sanctum/Resonant LOOK**
- После синтеза: toast имя + удар слота 1; status имя + `vid #ParentIds[1]` + 3 навыка (`*` на 1); ростер `[R]`; preview ядро-родитель
- `KamiSanctumService.sync` пишет `ActiveSpiritName`; починен сломанный `SynthesizeResult` (обрезанный патч)
- Smoke MCP Play **PASS**: `Ками-Глыба vid #11 | Жаровня * | …`; ростер `[R]`; `ActiveSpiritName` — `SESSION-2026-08-22b-sanctum-look-smoke.md`
- E1 live-like **3 цикла PASS** в SoT (Q7 манга E → Q1 catch → бой F+1/2 → сдача); цикл 3 = UI/E + HUD-клики (MCP VirtualInput не шлёт F/1/2 — лимит Studio, не баг биндов); ×N руками нет — `SESSION-2026-08-14-e1-e2e.md`
- MCP hotkeys: бой **V** (=F, silent alias в `ClientController`); навыки **Keypad1–3** (уже в `UIController`); игрок по-прежнему F/1/2

### Luau / remote hygiene (2026-08-22)
- Серверные remotes: `typeof(action)`, `tonumber` id, лов/бой требуют живую цель + range; слот атаки clamp 1–3
- `BattleEvent` Attack больше не `task.wait` в хендлере (нет yield-race)
- `EvolutionSystem.CanEvolve` nil-safe Inventory/Stats; Evolve индекс в пределах roster
- `BattleOrchestrator.CanUseSkill` отклоняет нечисловой skillIndex
- Бой берёт `playerSpirit.SkillIds` (не только каталог шаблона)
- `SESSION-2026-08-22-luau-hygiene.md`

### Checkpoint 2026-08-21
- Identity slice **1–3 PASS** (удар слот 1, LOOK UI/showcase, evo-progress card); Explore W3 + UI A–D + HUD уже PASS
- Week wrap закрыт 22.08; тема след. недели — Sanctum LOOK — `SESSION-2026-08-22-week-wrap.md`
- Оценка: P0/P1 soft polish ~недели; P2 (PvP/гильдии) — месяцы; AI mesh online deferred

### Identity slice 3 — evo progress card (2026-08-21c)
- Карточка духа: строка прогресса `→ форма · удар` + Ур./Bond/Побед/кристаллы; Evolve только при полном can
- `EvolutionsList` тихо обновляет UI (без toast «Доступно эволюций: N»)
- Edit verify rule 11→Тигр/шторм **PASS** — `SESSION-2026-08-21c-identity-slice-3.md`

### Identity slice 2 — LOOK sync (2026-08-21b)
- Карточка духа: навыки из каталога/`SkillIds` (не placeholders); после Evolve — toast **Old→New** + reopen card; слот 1011 emoji 🐯
- Showcase: entry Id следует эволюции → `RoS_ShowcaseOnSpiritEvolved` / carousel mesh `SpiritTemplate1011`
- Edit verify skills+mesh+hooks **PASS** — `SESSION-2026-08-21b-identity-slice-2.md`

### Identity slice 1 (2026-08-21)
- Эволюция меняет **вид** (Id/template) и **удар слота 1**: evolved `SkillIds` / `SpiritSkills` — signature skill первым (1011 `{3,1,2}` → «Огненный шторм»)
- `BuildPlayerAbilities` берёт `playerSpirit.SkillIds`; Evolve обновляет `CurrentSpiritId` + `ActiveSpiritName`; UI `EvolutionSuccess` мержит дух сразу
- `EvolutionSystem.UnlockedSkill` = skill слота 1; DevBoostIdentity → Bond≥3; EvolveSpiritBF синхронит Id/имя
- Smoke PrepareEvo→Evolve: id 1011, slot1 «Огненный шторм», mesh SpiritTemplate1011 **PASS** — `SESSION-2026-08-21-identity-slice-1.md`

### Checkpoint 2026-08-20
- UI A→D + HUD double-layer закрыты; цель завтра: **Identity** (эволюция = вид + удар) — `SESSION-2026-08-20-checkpoint.md`, `NEXT-SESSION.md`

### UI package D (2026-08-20g)
- Сумки: **grid** (иконка + stack + rarity stroke) + **detail** (имя / why-tag / описание ItemCatalog)
- `BagContentUI` ModuleScript (вынесен из UIController — лимит 200 locals)
- `ItemCatalog.GetIconEmoji` / `GetRarityColor`
- Smoke: open bag → 4 cells, detail «Ловушка · ловля» — `SESSION-2026-08-20g-ui-package-d.md`

### HUD double-layer fix (2026-08-20f)
- Catch/Profile: `TextButton.Text` + `ButtonLabel` больше не рисуют подпись дважды (`TextTransparency=1`, caption только в label)
- ExpBar `Y=-152` / Actions `Y=-96` — без наложения «0 / 100» на hotbar
- `WoWUITheme.StyleActionButton`: один gold stroke (не `StylePanel` с двумя UIStroke)
- **NextStepChip** vs `ResonanceActivityBar`: один inset-space + chip под баром (`Y=bar+H+8`); smoke gap=8, overlap=false
- **Toast** (`NotificationFrame` / ToastRouter fallback): `Y=88` под chip+activity; **без серого бара** (`BackgroundTransparency=1` + TextStroke); Bind уничтожает fallback GUI
- Client smoke: 1× `RealmOfSpiritsUI`, gap Exp→Actions ≈30px, strokes=1 — `SESSION-2026-08-20f-hud-double-layer.md`

### UI package C (2026-08-20e)
- DeviceSafeInsets; Actions/Battle подняты (+44px hit); skill `CdFill`; Catch dim вне цели — `SESSION-2026-08-20e-ui-package-c.md`

### UI package B (2026-08-20d)
- `NextStepChip`: persistent chip Мика → Exit → лут (E); client-only; smoke Combat→loot step **PASS** — `SESSION-2026-08-20d-ui-package-b.md`

### UI package A (2026-08-20c)
- `ToastRouter`: один toast; приоритеты Critical > Reward > Tip; wired UIController / ZoneController / OtakuHavenController
- `ItemCatalog.GetWhyTag` + сумки `Имя · тег xN` (эволюция / квест Мики / святилище / ловля / бой)
- Smoke Client GetWhyTag 101/120/1 **PASS** — `SESSION-2026-08-20c-ui-package-a.md`

### Explore diversity / funnel polish (2026-08-20b)
- Funnel у Exit→Combat: highlight **101** + **102** + **120** + сундук медь `(18,54)` — ≥3 типа награды ≤4 мин
- Exit toast: «огонь / лёд / манга / сундук (E)»; chest toast через ItemCatalog (не `#id`)
- MCP Play: 4 ExploreFunnel + funnel chest **PASS** — `SESSION-2026-08-20b-explore-diversity.md`

### Backlog queue (2026-08-12)
- **UI пакеты A→B→C→D** и **online AI-меши** поставлены в очередь «когда гармонично» (после Explore W3; AI — после UI A + явная разморозка) — `WEEK-PLAN-2026-08-19.md`, `SPIRIT-AI-MESH.md`. Сейчас код UI/AI online **не** стартовали.

### AI spirit mesh — offline only (2026-08-12)
- **Онлайн GenerationService / PromptCreateAssetAsync / MeshAssetId — ОТЛОЖЕНО** (см. `SPIRIT-AI-MESH.md`); todos gen/publish cancelled
- `SpiritMeshResolve.CreatePlaceholder` + `CloneResolvedModel`: Id → ParentIds template → geometric placeholder (`IsMeshPlaceholder`)
- `GameManager.CreateSpiritModel` больше не `return nil` без шаблона — всегда клон или placeholder
- Smoke Edit: ParentIds `{11}` → template; bad parent → placeholder **PASS**

### Explore loot feel — slice 1 (2026-08-20)
- **Visible funnel loot** outside Safe: highlight огненные кристаллы (ItemId **101**) на пути Hub Exit→Combat `(8,2,58)` / `(28,2,52)`; billboards AlwaysOnTop **Enabled**; Exit toast про кристаллы (E)
- `WorldLootService`: grant → toast + `FullSync`; `getPlayerData` через `_G` / `GetPlayerDataBF` (без ephemeral DSM); MCP Play smoke grant **PASS** — `SESSION-2026-08-20.md`
- W3 ещё не полный PASS (diversity ≥2–3 типов — следующий день)

### Social 2p / E4 PASS (2026-08-19)
- **E4 PASS** — user play-test: Local Server **2 Players**, Safe, `/tradetest`, live inventory swap (2026-08-12/19). Evidence = **ручной**, не MCP. P1 Social gate для недели закрыт → Explore loot unlocked (`SESSION-2026-08-19.md`, `WEEK-PLAN-2026-08-19.md`)
- E1 остаётся **CONDITIONAL** (нет полных e2e ×N глазами); Solo MCP trade regress ранее зелёный

### Week wrap / stabilize (2026-08-12 → 2026-08-18)
- **Вт 18.08 стабилизация:** MCP Play regress — Q7→turn-in, Q1 ForceCatch→turn-in, Battle Start→SkillIndex 1+2→End, Kami `SeedQA`+Synthesize Resonant **PASS**; Showcase plaza structural OK; Critical hotfix не потребовался — `SESSION-2026-08-18.md`
- **Итог exit criteria:** E2/E3/E5 **PASS**; E1/E4 **CONDITIONAL** (нет 5× manual; нет live 2p Local Server)
- **P0 Core+Hub CONDITIONAL · P1 Social CONDITIONAL** — следующий крупный трек (Explore / Identity / PvP) только после ручного E4 PASS
- Place SoT без кодовых правок 18.08 (только smoke)

### P1 Social 2p / E4 (2026-08-17)
- **E4 CONDITIONAL** (не PASS / не FAIL) — `SESSION-2026-08-17.md`
  - MCP smoke: `PlayerTradeSystem.SimulateSwap` item↔item + item↔cosmetic **PASS**; empty/missing **reject PASS**
  - `/tradetest` kit (ловушка+зелье+косметика) + toast **PASS**; Request unknown/self → «Игрок не найден» **PASS**
  - Live **2 Players Local Server** UI-обмен не гонялся (MCP Play Solo) — для полного PASS нужен ручной 2p в Safe
  - Hotfix кода не потребовались; docs mirror `PlayerTradeSystem` синхронизирован (`typeof(action)` + payload table guard)

### P0 play-test gate (2026-08-15)
- **Вердикт Core+Hub: CONDITIONAL** (не FAIL) — `SESSION-2026-08-15.md`, `NEXT-SESSION.md`
  - **E1 CONDITIONAL:** MCP e2e Q7→catch→Battle End PASS (12–13.08); формальный 5× Local Server не закрыт
  - **E2 PASS:** SkillIndex 1+2 End; `ensureMinBattleSkills` ≥2; MaxCooldown/CD/MP UI (слот 2 доступен)
  - **E3 PASS:** Мика ≤15 с; Exit KeepVisible; BGM Safe→Combat (14.08 + MCP regress 15.08)
  - **E4** → пн Social: **CONDITIONAL** 17.08 (см. блок выше); **E5** docs обновлены
- Backlog triage: FEFF ShortGrass = plugin (skip); Exit hint optional; 5× manual желателен но не блокер Social при CONDITIONAL
- Prep Social: `/tradetest`, Safe, 1-slot offer — выполнено в smoke 17.08

### Product checkpoint (2026-08-14)
- P0 Hub как продукт (60 с): видимый Exit wayfind (`ExitWayfindBillboard` + KeepVisible); funnel toast; Play smoke Мика≤15 с + Exit + BGM Safe→Combat **PASS** — `SESSION-2026-08-14.md`

### Product checkpoint (2026-08-13)
- P0 Core polish день 2 (agency): слоты 2–3 читаемы (имя / MP / CD remaining+Max); MCP smoke SkillIndex 1+2 End + Q7/Q1 e2e **PASS** — `SESSION-2026-08-13.md`

### Product checkpoint (2026-08-12)
- P0 Core polish день 1: agency/UI hints + MCP smoke regress **PASS** — `SESSION-2026-08-12.md`
- `user_RoS_ShortGrass` FEFF: **не в place** (plugin/package Output noise); skip

### Changed
- **P0 Hub Exit visibility**: `OtakuHavenBuilder` ShopExit billboard AlwaysOnTop/Enabled + `HubWayfind`/`KeepVisible`; `ClientController` не гасит Exit wayfind; ZoneController hub/Exit toasts
- **Battle agency day-2**: `PlayerSkills.MaxCooldown` в sync; кнопки навыков 2-строчные (MP + CD); toast CD/MP по-русски; layout слотов шире
- **Battle agency UX**: `SkillCatalog.ensureMinBattleSkills` (≥2 слота); UI слоты 2/3 Visible по skills; catch `×N` ловушек; EndBattle toast дольше/яснее; hint «1/2/3 · H» на старте боя
- **Haven P0 Hub polish**: spawn → **Genkan** `(-25,1.5,-6)` лицом к Мике; TalkHint «КВЕСТ →» снова; Mika `showEmotion` on; wayfind AlwaysOnTop + `WaySpawnMika`
- **Battle agency/VFX**: скиллы окрашены по Element; вспышка панели на «Сильно!/Слабо…»; `PlayerSkills.Element` в battle payload
- **P0 core-loop polish**: victory toast показывает copper (`CopperCoins`); FullSync без спама «синхронизированы»; бой хоткеи **1/2/3 + H**; catch hint «нет ловушек» без блокировки `isInBattle`; квест 7 → Exit в description/tracker
- **GDD §3.2.1 / 4×4**: канон Primary 4 линии (+эво); ElementPassives vs 3 unique; deprecated Sand/Crystal
- **GDD §3.2.1**: таблица духов по Primary (legacy mesh inventory) — superseded by 4×4 canon 2026-07-30; убрана временная `SpiritMeshGallery` из EditPreviews
- **Combat element tip**: первый вход в Combat → toast «Огонь→Земля→Ветер→Вода→Огонь · ×1.5/×0.7» (`ZoneController`)
- **P1 Social trade KR**: `PlayerTradeSystem.SimulateSwap` QA — item↔item + item↔cosmetic + fail-missing PASS; `/tradetest` kit без изменений
- **Season polish**: PASS snapshot с pity/DaysLeft/SoftBuffs; pool кристаллов 101–117; EndsAt 2026-08-31; UI «До конца / Bond soft / гарант»; RequestSeason → GetClientSnapshot
- **Element agency demo**: в бою Primary ×1.5/×0.7 реально применяется; лог «Сильно!/Слабо…»; tip на старте «Огонь vs Земля — … · цикл»; `BattleElementTip` в UI
- **Dex UI Primary labels**: панель DEX показывает «Огонь / Земля / Ветер / Вода» (+ тиры ★); копирайт про Primary-сеты; docs mirror + `DexBonus` handler
- **Four Primary Elements**: чарт Fire→Earth→Wind→Water→Fire (×1.5/×0.7); у духов `PrimaryElement` + `Aspect`; Dex/урон по Primary; UI «Огонь (Пепел)»; подпись-скиллы Water Heal / Wind tempo / Earth armor

### Removed
- **Эйфелева башня** у Haven (`EiffelTowerStatue` + `EiffelPedestal`) — удалена по запросу

### Added
- **Spirit meshes evo 101–105**: Studio AI → `SpiritTemplates` Огненный Тигр / Ледяной Феникс / Теневой Волк / Грозовой Левиафан / Световой Альфа — **канон 4×4 полностью с мешами**
- **Spirit meshes Magma/Mist/Sky**: Studio AI `generate_mesh` → `ReplicatedStorage.SpiritTemplates` **16/116, 17/117, 18/118** (+ ServerStorage mirror, EditPreviews); Blender MCP был offline; Play smoke spawn PASS
- **Evo QA #18→#118**: MCP Play PASS — PrepareEvoBF + EvolveSpiritBF → Небесный Феникс (skills 129–131, кристаллы 118 списаны)
- **Hunt 218 / Sky cascade**: accept→ForceCatch #18→turn-in PASS (UniqueItem **27** Перо Небесного Хребта + 3×118); Studio `QuestSeedCompletedBF`
- **Hunt remap / Sky 218**: квесты **213/215** `Deprecated` (не в available, Accept блокируется); цепь **212→214→216→217→218**; Hunt **218** Небесный Сокол / UniqueItem **27**; зоны Sand/Crystal «архив»; WorldLoot SkyRidge ×2 кристалла 118
- **4×4 Primary canon (1B/2B)**: 16 линий / 32 формы; бой = 3 unique skills; 2 `ElementPassives` на Primary (пассив Atk%/Def%, tip в agency); Wind **#18→#118** Небесный Сокол / SkyRidge; Sand/Crystal soft-deprecate (нет spawn); smoke slots+passives PASS; **Play smoke** Fire vs Earth — tip «Пассивы:…», слоты база 2
- **Hunt 217 / Mist**: дух **#17** Туманный Дух → эво **#117** Призрачный Кирин; Primary Water / Aspect Mist; зона **FogBasin** `(660,200)`; skills 126–128; кристалл Item **117**; трофей UniqueItem **26**; квест **217** (prereq 216); Season pool +117; MCP cascade 201→217 accept→catch→turn-in PASS (трофей 26 + 3×117)
- **Evo QA #16→#116**: MCP Play smoke PASS — L14 + Bond 3 + 5×116 + 14 wins → Вулканический Титан (skills 123–125, кристаллы списаны); `PrepareEvoBF` теперь выставляет `Bond`
- **Hunt 216 / Magma**: дух **#16** Лавовый Краб → эво **#116** Вулканический Титан; Primary Fire / Aspect Magma; зона **MagmaFissure** `(590,240)`; skills 123–125; кристалл Item **116**; трофей UniqueItem **25**; квест **216** (prereq 215); Season pool +116; MCP cascade 201→216 accept→catch→turn-in PASS (трофей 25 + 3×116)
- **Side 106 «Цикл стихий»**: CollectItem 2× Primary-кристаллы 101/107/109/106 (prereq 101); UniqueItem **24** Скрижаль; ветряные кристаллы у GaleCliff; MCP Play accept→turn-in PASS (Скрижаль 24)
- **Hunt 215 / Crystal**: дух **#15** Хрустальный Лис → эво **#115** Призматический Страж; зона **CrystalCaves** `(520,280)`; skills 120–122; кристалл Item **115**; трофей UniqueItem **23**; квест **215** (prereq 214); MCP smoke accept→turn-in PASS
- **Haven onboarding polish (P0 Hub)**: напольные wayfind `WayMika` / `WayManga` / `WayExit` в `OtakuHavenBuilder`; rebuild Haven + Мика на `QuestMasterPosition`; Play smoke — manga buff, gacha copper+FOMO, fitting wardrobe (prompts Enabled); BGM Safe→Genkan→Exit→Combat PASS
- **Side QA 101–105**: MCP Play smoke **PASS** (CollectItem/FindChests/Defeat/Catch → Легенда 105)
- **Story QA 1–6**: MCP Play smoke **PASS** (7→1→…→6 accept/progress/turn-in); копирайт квеста 1 (Exit→Akihabara); реплики Мики на 1/7; Exit сцена 4 — toast + снятие тапочек PASS
- **Genkan footwear fix**: sync тапочек по `CurrentZone`/`ZoneDetail` (гонка ZoneChanged); Safe/Spawn тоже indoor; welcome-колокольчик + toast; MCP client smoke 6 parts PASS
- **Сценарий Haven · квест 7 «Украденная манга»**: GDD сцена 2 — CollectItem **120**, награда 500c + UniqueItem **22** Секретный билет; сюжет **[1]** теперь prereq `{7}`; loot у Exit; диалог Мики (Shadow/Сеул); MCP Play smoke PASS
- **Evo QA #14→#114**: MCP Play smoke PASS — L14 + Bond 3 + 5×114 + 14 wins → Железный Колосс (кристаллы списаны)
- **Hunt 214 / Metal**: дух **#14** Стальной Жук → эво **#114** Железный Колосс; стихия `Metal`; зона **IronWastes** `(450,200)`; skills 117–119; кристалл Item **114**; трофей UniqueItem **21**; квест **214** (prereq 213)
- **Daily Board lite**: 4 слота (Care/Temper/Battle/Loot), `DailyBoard` + activity bar `N/4`, `BonusNextDay` ×2 soft tokens/Pass XP — см. [`DAILY-BOARD.md`](DAILY-BOARD.md)
- **Hunt 213 / Sand**: дух **#13** Пустынный Скорпион → эво **#113** Песчаный Император; стихия `Sand`; зона **SandDunes** `(360,-40)`; skills 114–116; кристалл Item **113**; трофей UniqueItem **20**; квест **213** (prereq 212)
- **Spirit Resonance Phase 4**: seasonal form (`SeasonalFormId`, shop/BP), Activity Pass UI (`PASS`), crystal pity (10 misses → гарант на бой/сундук) — `SeasonLiveOps`
- **Spirit Resonance Phase 3**: Dex UI (`DEX` на activity bar), Dex passives в бою (`DexAttackPct`/`DexDefensePct`), Haven `ResonanceShowcaseService` (витрина южнее Мики) — см. `SPIRIT-RESONANCE-PLAN.md`
- **Spirit Resonance Phase 2**: Temper picker (Attack/Defense/Spirit), пьедестал `ResonanceTemperService`, `BattleOrchestrator` Temper atk/def/heal bonuses, weekly quest **303** — см. `SPIRIT-RESONANCE-PLAN.md`
- **Spirit Resonance Phase 1**: `ResonanceCareService` пьедестал «Уход» у Мики + VFX; `ResonanceActivityBar`; `QuestTrackerHud` wired + auto-accept quest 301; CareSpirit priority в трекере — см. `SPIRIT-RESONANCE-PLAN.md`
- **Spirit Resonance Phase 0 → Studio**: `SpiritResonance` module, `ResonanceEvent`, Care/Temper UI, battle XP share, RequiredBond evo gate, quest progress CareSpirit/TemperSpirit — см. `SPIRIT-RESONANCE-PLAN.md`

### Fixed
- **Bag UI item names**: `UIController.BuildBagContentsFromInventory` брал имя только из `SpiritDatabase.ShopItems` → лут 101/102/120 показывался как `Предмет #102`; теперь `ItemCatalog.Get` (имя + qty). `ItemCatalog.Get` принимает tonumber(id). Smoke: `Огненный кристалл x2`, `Ледяной кристалл x3`, `Коробка редкой манги x1`
- **P0 Wed smoke regress PASS**: Q7→Q1 catch→Battle End (SkillIndex 1+2); FEFF ShortGrass вне place (plugin)
- **Daily Board Care/Temper soft**: `MarkDailySlot` → `OnDailyCare`/`OnDailyTemper` при первом claim (раньше только CatchOrChest + квесты 301/302); без double-grant на сдаче квеста; MCP smoke 4/4 + `BonusNextDay` ×2 + PASS snapshot PASS
- **MusicController BGM**: `ZoneMusic` больше не в `PlayerGui` (Roblox снимал Folder) — папка в `SoundService`; кроссфейд Safe/Genkan/Exit/Combat снова слышен
- **ShowcasePlaza**: LoS=false, prompt на Base, ClickDetector; `showcaseSet` напрямую (не только `_G`)
- **Квест 301 Care pedestal**: подтверждён игроком PASS 2026-07-27 (корень — мёртвый saved prompt)
- **Temper pedestal**: тот же live-build (один Ready, ClickDetector, LoS=false) + UIController `TemperPrompt` → OpenTemperPicker; Temper quest push через `UpdateQuestProgressBF`
- **Квест 301 пьедестал (корень)**: в `.rbxl` лежал сохранённый pedestal с ProximityPrompt **без Triggered** (connections не сериализуются) — E молчал; UI кнопка жила. Удалён из Workspace; скрипт строит живой pedestal при Play + ClickDetector; убран rebuild-loop

### Changed
- **Resonance 301–303**: цепочка Care→Temper→weekly MCP smoke PASS 2026-07-27; Phase 4 pity/tokens unit OK
- **Квест 301 пьедестал**: E → `RequestPedestalCare` в **UIController** (тот же `FireServer("Care")`, что кнопка) + server BF backup; `ResonanceCarePedestalClient` в Play не клонировался — обход через UIController; MCP: FireClient → 1/1 Ready PASS 2026-07-27
- **Квест 301 пьедестал**: E на сервере зовёт `DoResonanceCareBF` (не только клиент); MCP smoke 301→Ready→turn-in→302 PASS 2026-07-27
- **Квест 301 пьедестал vs UI Уход** (попытка): пьедестал → `RequestPedestalCare` → `ResonanceCarePedestalClient` → тот же `FireServer("Care")`, что кнопка UI; `FromPedestal` пушит CareSpirit — **на Play у игрока пьедестал всё ещё FAIL**; UI Уход — PASS (см. `NEXT-SESSION.md`)
- **Квест 301 шаги 3–4 (пьедестал → сдача)**: `ResonanceCareService` больше не дублировал Source (старый промпт на Bowl + LoS); Care идёт через `DoResonanceCareBF`; прогресс квеста через `UpdateQuestProgressBF`; промпт на Base, LoS=false, dist=12; `GetActiveQuests` tonumber + ReadyToTurnIn dual-key — smoke MCP OK, Play pedestal FAIL
- **Квест 301 с пьедестала Уход**: `UpdateProgress` для CareSpirit (битый `end` у CollectItem), tonumber ключей квеста, `GetOrCreateQuestSystem` в `_G.UpdateQuestProgress` + сразу `ActiveQuests`; повторный E / уход уже сегодня всё равно засчитывает цель; при взятии 301 если Care уже был — цель сразу 1/1
- **Пьедестал Уход/Закалка «не качает»**: после успеха UI мержит Bond/Temper в `PlayerData` и обновляет карточку духа; в «Состоянии» видны бонусы закалки; Temper без выбранного духа больше не молчит; Care с пьедестала пробует лакомство, если бесплатный уход уже был
- **Квест 302 после 301**: после сдачи UI не обновлял «Доступные» — теперь `GetQuests` + `OpenQuestUI` на вкладку Available; `tonumber(QuestId)` + `hasQuestFlag` для prereq
- **Пьедесталы у Мики**: Care/Temper отодвинуты (~26 studs, offset ±22/+14), `MaxActivationDistance=8`, LoS — больше не срабатывают при разговоре с Микой
- **Уход/Закалка «ничего не происходит»**: кнопки берут активного духа по умолчанию + уведомление; пьедестал Care идёт через `_G.RoS_DoResonanceCare` (те же данные, что GameManager)
- **Квест 301 у Мики**: убран auto-accept при входе (квест пропадал из «Доступные»); резонанс 301–303 сортируются сверху списка у Мики
- **Catch trap FX**: спавн ловушки при поимке — fallback на ServerStorage + procedural neon «ЛОВУШКА», видимость частей, pcall place/Clear; больше не пропадает молча
- **DataStoreManager**: восстановлен повреждённый Source (syntax error L47 ломал весь GameManager) — NormalizeCurrency/NormalizeSpirits + корректный стартовый дух с Bond/Temper; UpdateData тоже нормализует spirits
- **UIController**: при повторном клоне StarterGui уничтожает старый `RealmOfSpiritsUI` (больше не два HUD)
- **ArenaPortalService**: лог wire только один раз (без спама в Output)

### Known issues
- _(пусто)_ — квест 301 pedestal: server `DoResonanceCareBF` на Triggered; MCP smoke 301→care→turn-in→302 PASS 2026-07-27 (нужен Play-подтверждение у игрока)

### Changed
- **PASS UX**: золотая кнопка «Сезон · N жетонов» в **левом нижнем** углу; в панели — «Как получить жетоны»; счётчик обновляется сразу после боя/FullSync
- **Care pedestal feedback**: при Уходе — карточка прогресса BondXp (полоска), список ачивок (Уход дня / Bond↑ / квест), пульсация activity bar и QuestTracker
- **Spawn void (пустое небо)**: `CharacterAutoLoads=true` + retry `LoadCharacter` + `PivotTo` на SpawnLocation Haven `(-25,1.5,18)` — персонаж больше не зависает камерой в skybox
- **Spawn/Lighting**: убраны дубли Sky/Atmosphere (Coast Haze) — фикс магента-заливки; Spawn на полу Haven; телепорт на SpawnLocation при CharacterAdded
- **Spawn**: `SpawnPosition` / SpawnLocation перенесены в **Genkan** `(-25, 1, -6)` — больше не у Мики снаружи (`Z=-45`)
- **Economy rollout P0–P3**: unit smoke PASS в Studio (shop cap, gold sinks, battle copper scaling, quests 301/302 + ItemsChance, SeasonLiveOps) — см. `ECONOMY-ROLLOUT.md`
- **Economy P0–P3**: temper stone 200c + cap 3/day; XP scroll 80c/+120; crystals unsellable; gold sinks 201–203; Care treat 30%; battle copper 30→20 by level; `SeasonLiveOps` tokens/BP soft-only — см. `ECONOMY-BALANCE.md`
- **Мика QuestUI**: панель квестов — `BillboardGui` над головой (не перекрывает образ); камера на корпус; убран tween 700×500
- **Мика QuestUI**: панель в ScreenGui с clamp в viewport (не уезжает за край); при нехватке места сверху — справа от Мики; X всегда доступен; Esc закрывает
- **Мика interact**: стандартный ProximityPrompt (`Default`) снова виден; якорь **над головой** (по mesh AABB, без Custom/TalkHint)
- **Lighting**: приглушено солнце — Brightness 2.6→**1.35**, Exposure **-0.35**, bloom/sun rays/coast glare слабее (`ensureHavenMoodLighting`)
- **Ground level pass**: удалён второй Baseplate (top Y=1); DirtRoad/Haven Floor/City plaza-sidewalk-alley на Y=0; trails pinned; TourbillonCar на землю; билдеры больше не поднимают pads на 1.05/1.08
- **Мика (QuestMaster)**: mesh regen v4 — face по `mika-face-pink-bob.png` (pastel pink bob, dark pink eyes) + pink/black cyber suit; `(-12,-38)`, prompt сохранён

### Added
- **Otaku Haven CityDistrict** (v2): enterable shop shells (doorway + floor/walls/ceiling + interior props), shops set back behind sidewalks (not on paths); Akihabara-style kanban/noren/striped awnings/chochin/spill light; alleys keep walk lane clear; `OtakuCityDistrict` + `OtakuHavenBuilder.Build()`; Spawn/Mika/zones/road unchanged
- **CityDistrict shop scale**: doorway clear **8 studs** (R15), width ~6.7; shells ~16×12×14 (was ~11×7.5)
- **CityDistrict v3**: townhouses (pitched roof, porch, 2F windows) instead of bus-stop shells; doors flipped to **outer** sides; houses on road flanks (not on arena path); **PlayerGarage** (~30×16×24) west of south plaza with 4 car bays
- **PlayerGarage**: отодвинут на **50 studs** дальше от Haven (`center.X - 98`)
- **PlayerGarage**: коробка — глухие левая/правая (перпендикулярны стеклу) + стеклянные передняя/задняя с раздвижными дверями; ориентация по FaceDir
- **CityDistrict houses v6**: вдоль Transition-дороги к морю; дверь на **E** (ProximityPrompt); окна — проёмы со стеклом Transparency 0.88 (видно изнутри)
- **CityDistrict houses**: фасад и стены — единая кирпичная коробка (одна толщина/цвет/плоскость; углы сходятся)
- **CityDistrict houses**: ориентация коробки — Front ∥ Back, Sides ⊥ (задняя стена больше не как боковая)
- **CityDistrict houses**: fix client Play — `frontAt` был left-handed CFrame (det=-1), после старта Look сбрасывался в -Z; теперь `wallAt` right-handed
- **CityDistrict houses**: крыша — скат вдоль FaceDir; окна — проёмы + тонкая рамка (без чёрной пластины); дверь — только косяки, виден интерьер
- **CityDistrict houses**: анти-z-fight (стекло/рамка разведены, косяки в проёме, пол выше фундамента); стены/дверь SmoothPlastic; окна плотнее (`winT` 0.55→**0.28**)
- **CityDistrict houses**: таблички — `wallAt` всегда с Up вверх (текст больше не вверх ногами)
- **CityDistrict houses**: дверь после upright-`wallAt` — створка по мировому `right` (`xSign`), снова в проёме
- **CityDistrict houses**: полотно двери ≈ проём (5.4×7.9); пальмы Transition/coast у домов убраны


- **VenomHollow / #12 Ядовитая Гадюка** (Poison): зона `(280,-160)`, skills 111–113, evo **#112 Василиск-Гидра**, item 112, hunt **212** + trophy 19, SpiritTemplate12/112, trail; ElementChart Poison
- **Moonwell / #11 Лунный Кролик** (Moon): зона `(-220,-160)`, skills 101–103, evo **#111 Цукуёми-Страж**, item 111, hunt **211** + trophy 18, SpiritTemplate11/111, trail + billboard; ElementChart Moon
- **MossGlade / #10 Моховой Олень** (Nature): зона `(50,-200)`, skills 91–93, evo **#110 Древний Энт**, item 110, hunt **210** + trophy 17, SpiritTemplate10/110, trail + billboard; ElementChart Nature
- **GaleCliff / #9 Ветряной Лис** (Wind): зона `(-140,180)`, skills 81–83, evo **#109 Буревой Кицунэ**, item 109, hunt **209** + trophy 16, SpiritTemplate9/109, trail + billboard; ElementChart Wind
- **ForceCatchBF** (Studio MCP QA): grant catch + `CatchSpecificSpirit` progress без RNG / interaction lock
- **AshGarden / #8 Пепельный Саламандр**: зона `(175,50)`, skills 71–73, evo **#108 Инферно-Дракон**, item 108, hunt **208** + trophy 15, SpiritTemplate8/108, trail + billboard
- **SpiritTemplate107** (Горный Титан): AI mesh + preview @ StoneBasin; UI icon ⛰️; Scale ~5.2
- **CoastWave** (`StarterPlayerScripts`): лёгкий bob пены/воды CoastalShowcase
- **CoastalShowcase**: береговая линия сглажена; пальмы убраны из воды; пена прибоя накатывается/откатывается на **±3 studs** (`CoastWave`)
- **CoastalShowcase**: песок/wet без щелей (перекрытие полос); прибой явный — накат ~5.5 studs, растяжение пены, wet/water в такт (`CoastWave`)
- **CoastalShowcase**: пальмы убраны из воды/прибоя; Transition Ground — плавный градиент трава → сухая → песок (цвет/материал/стык с пляжем)
- **StoneBasinTrail** + billboard «Каменный бассейн» — wayfinding от Haven к Earth habitat
- **EditPreviews** folder: SpiritPreview6/7/107 убраны с корня Workspace
- **Earth #7 Каменный Голем**: StoneBasin `(-80,-120)`, skills 61–63, evo #107 Горный Титан, item 107, hunt 207 + trophy 14, SpiritTemplate7 + habitat; ZoneSystem/Controller/Music wired
- **PalmSway** (`StarterPlayerScripts`): листья пальм CoastalShowcase покачиваются от «ветра» (RenderStepped)
- **CoastalShowcase**: anti z-fighting на пляже — без X-overlap песка, слои Y (sand/wet/path/water), transition под песком на берегу, Reflectance воды снижен
- **MistPond / Водный Карп**: зона и spawn перенесены в **Прибрежное море** у CoastalShowcase `(30, 2, -880)`; старый пруд у Combat убран; hunt 203 / кристаллы 106 / Swim bounds обновлены
- **CoastalShowcase** (workspace): anime coastal strip **1000 studs** south of map (`Z≈-750`); approach from Haven: **sand/palms first → shore → sea**; Terrain Water for swimming + turquoise visual overlay; ~73 low-poly palms + rocks; modular `PalmTree_Modular`; warm cartoon Lighting; ViewPad among palms @ `(0, 0.6, -680)`; **Baseplate 2048**; плавный `Transition`: city fringe → meadow → dry grass → dunes → beach (S-curve path cobble→sand, hills, bushes→palms, trailhead у спавна)
- **SpiritTrap**: только как предмет рюкзака (Id=1); шаблон `SpiritTemplates.SpiritTrapTemplate`. По кнопке **Ловить** сервер ставит ловушку **под духа** и играет анимацию поимки (struggle → втягивание); успех/провал; превью в мире убрано
- **Путь Охотника** quest chain 201–206 (`Type=Hunt`, `CatchSpecificSpirit` by HuntOrder): XP/coins/reputation + habitat trophies (UniqueItems 8–13) + element crystals; wire GameManager catch → progress; QuestUI/HUD/Client markers
- Spirit habitats spread across map for future hunt-quest chain: `SpiritHabitats` + `ZoneConfig.SpiritHabitats` (HuntOrder 1–6); pockets FrostRidge / ShadowHollow / StormSpire / DawnMeadow (+ MistPond); crystals by element near each; baseplate 800
- **SpiritTemplate106** (Цунами-Карп): светлый pearl koi по `ref_water_carp_light.png` — AI mesh + scale ~4.5; preview у MistPond; RS/SS templates; polish pass (re-gen Studio mesh)
- MistPond PvE pocket (north of Akihabara Combat): ZoneConfig/ZoneSystem/Music/WorldSpawner/WorldLoot; water spirit **Водный Карп** (id 6) + **Цунами-Карп** (106); water skills 51–53; item 106; SpiritTemplate6; workspace MistPond built in Edit
- MistPond wayfinding: neon water + 28-stud beacon + AlwaysOnTop billboard; path from Combat north with «ПРУД ↑»; gate sign; spawn on shore
- MistPond visual: Japanese sand-shore pond (glass water, rocks, ishidōrō lantern); stepping stones from Combat; removed text signs/billboards/neon beacon
- **Водный Карп** модель: procedural koi по рефам (navy body, translucent fins, white head spot, whiskers) → `SpiritTemplate6` + preview у пруда
- Водный Карп: `MovementType=Swim` — плавает в пределах PondWater, анимация хвоста; убраны preview/procedural артефакты у пруда
- PvP Arena duel vertical slice: PvPDuelSystem + PvPDuelController; fair ExecuteFairSkill; challenge Y near arena; pads A/B; existing battle UI; +15 copper winner; potions off in duel
- PvP rematch UI after KO/flee (20s): both Accept → new duel on pads; Decline/timeout → teleport both to pre-fight `Origin` CFrames; no character blades in duel (HideBattleBlade)
- `scripts/pvp_sanity_check.py` in quality gate (docs mirrors: visuals/freeze/rematch/origin/HideBattleBlade)
- PvP challenge zone: Haven + corridor (300 studs from arena) + arena; fight still on pads; `/pvpqa` → Haven
- `PlayerInteractController`: единый UI у игрока — кнопки **Обмен** / **Дуэль** рядом, описание снизу; T/Y; ProximityPrompt у Trade/Duel отключены; trade range 22

### Fixed
- **fullSyncCooldown**: объявление рядом с `activeBattles` (PlayerRemoving больше не падает на nil)
- **RequestFullSync**: cooldown 1.5s (anti-spam)
- **SetActiveSpirit / Evolve**: `math.floor` индекс
- **DataStore**: `ProcessedReceipts = {}` в default data
- **WorldLoot**: claim-флаг до getPlayerData (anti race)
- **NPC Trade GetShop/Buy/Sell**: только Safe/Haven или ≤45 studs у `ShopEntrance` (Model → BasePart)
- **GetPlayerDataBF**: `IsStudio()` only (как остальные QA BF)
- **Tourbillon DoorToggle**: HRP ≤22 studs от chassis
- **CatchSpirit**: обязательна world-модель + `ValidateSpiritTarget`; иначе Error+FullSync (закрыт remote-farm без instanceId)
- **NPC Trade Buy/Sell**: `quantity` clamp 1–99 (`tonumber`/`floor`)
- **ProcessReceipt**: идемпотентность по `PurchaseId` (`ProcessedReceipts`)
- **Battle Start**: цель только через TargetInstanceId + range (убран FindSpiritModel fallback)
- **ArenaPortal**: нет портала или далеко → return (не телепорт)
- **Catch Error/Fail**: клиент `RequestFullSync`; сервер handler на DataSync
- **PvP**: бой на `ActiveSpiritIndex` (не всегда Spirits[1])
- **QA BF**: ForceCatchBF / PrepareEvoBF / EvolveSpiritBF → `IsStudio()` only
- **Robux ProcessReceipt**: конец FOMO-сезона больше не делает `PurchaseGranted` без награды — окно продлевается (как coin gacha), иначе `NotProcessedYet`
- **Активный дух**: `ActiveSpiritIndex` в DataStore; бой берёт серверный индекс (не клиентский spoof); **Q** → `CycleActiveSpirit`; attrs `ActiveSpiritIndex`/`ActiveSpiritName`
- **CoastWave**: poll + fallback по именам Foam_/Water_ (больше не `loaded 0`)
- **DisplayOrder**: RealmOfSpiritsUI=100, ZoneUI=150, QuestUI=200 (поверх = Haven/trade/duel)
- **Docs**: экспорт `GameManager.lua` + `DataStoreManager`; `battle_sanity_check` fail если нет GameManager
- **AI-меши (голем/олень/лис и др.)**: при wander падали на бок — `CreateSpiritModel` якорит все BasePart (`Anchored` + `CanCollide=false` как у классических шаблонов); `SpiritAnimation.MoveStep` всегда `lookAt(..., Vector3.yAxis)`
- **PalmSway**: fronds **770** (было 0) — pivot без Frond_, poll до стабильной репликации CoastalShowcase
- **Catch polish**: `EnsureModelPrimaryPart` для AI-мешей; unlock снова включает wander; 5s safety unlock Dying/InteractionLocked; клиент не таргетит locked духов
- Habitat trails: ярче neon Path_/TrailPost (GaleCliff/MossGlade/Ash/Stone)
- **Путь Охотника X** Play QA **PASS** (2026-07-26): accept → catch #10 → turn-in; UniqueItem 17 + 3×110
- **Evo #10→#110** Play QA **PASS** (2026-07-26): Древний Энт; SkillIds 91–93
- Hunt **210** Prerequisites восстановлены `{209}` после temp-clear для QA
- **Путь Охотника IX** Play QA **PASS** (2026-07-26): accept → catch #9 → turn-in; UniqueItem 16 + 3×109
- **Evo #9→#109** Play QA **PASS** (2026-07-26): Буревой Кицунэ; SkillIds 81–83
- Hunt **209** Prerequisites восстановлены `{208}` после temp-clear для QA
- **Путь Охотника VIII** Play QA **PASS** (2026-07-26): accept → catch #8 → turn-in; UniqueItem 15 + 3×108
- **PrepareEvoBF**: выставляет `Stats.EnemiesDefeated` (EvolutionSystem считает глобальные победы, не `spirit.EnemiesDefeated`)
- Hunt **208** Prerequisites восстановлены `{207}` после temp-clear для QA
- **Evo #7→#107 / #8→#108** Play QA **PASS** (2026-07-26): PrepareEvoBF + EvolveSpiritBF → Горный Титан / Инферно-Дракон
- **Путь Охотника VII** Play QA **PASS** (2026-07-25): accept → catch Каменный Голем (StoneBasin) → turn-in; UniqueItem 14 + 3× item 107
- **BattleArena вход/выход**: `ProximityPrompt.Triggered` из Builder.Build не сохранялся в place — `WirePortals` + `ArenaPortalService`; RemoteEvent `ArenaPortal` по E; Touched/Click; `PivotTo`; портал крупнее + billboard `[E]`
- Мика (QuestMaster): больше не лежит на боку — убран `CFrame.lookAt` (ломал procedural риг); upright по AABB + yaw-only + pin к земле; baseplate top = Y0; WorldSpawner + QuestMasterBehavior
- Hunt `CatchSpecificSpirit`: не сидится из уже имеющихся духов (стартовый кот ≠ поимка в зоне) — иначе 201 сразу ReadyToTurnIn
- Spirit ground place: raycast ignores `BattleArena` dome (RoofRing) so habitats outside Combat don’t spawn on arena roof
- MistPond Water Carp **Play QA PASS** (2026-07-24): Swim wander в пруду, хвост машет (4 parts), без console errors / preview artifacts
- **Evo QA #6→#106 PASS** (2026-07-25): L12 + 5× водный кристалл + 12 battles → Цунами-Карп; SkillIds 51–53; unlocked «Цунами»; SpiritTemplate106
- **AcceptQuest**: отказ если квест уже в `CompletedQuests` («Квест уже выполнен»)
- **Путь Охотника I–VI** Play QA **PASS** (2026-07-25 non-stop): 201→206; UniqueItems 8–13; Level 6 / Rep~245
- **Путь Охотника III** Play QA **PASS** (2026-07-25): accept → catch Водный Карп (MistPond) → turn-in; unlocks 204
- **Путь Охотника II** Play QA **PASS** (2026-07-25): accept → catch Ледяная Птица (FrostRidge) → turn-in; unlocks 203
- **Путь Охотника I** Play QA **PASS** (2026-07-24 evening): accept → catch Fire Cat → turn-in → UniqueItem 8 + XP/coins; unlocks 202
- P2 PvP vertical slice **PASS** (Local Server 2p, 2026-07-23): Haven challenge, interact UI Обмен/Дуэль, rematch/origin return
- Studio PvPDuelSystem was missing spirit visuals/freeze vs docs mirror — full Source sync (setupDuelVisuals, freeze, rematch, origin return)
- PvP duel rematch/challenge range 80 studs (pads ~56 apart); spirit duel visuals between pads; freeze players on pads during duel; `DuelEnd` + battle `End` clears client `inDuel`
- PvP duel challenge/accept: зона была радиус 55 от центра — вход арены (~86) вне зоны → нет промпта/отказ сервера; теперь bbox арены + radius 130, жёлтая плита `PvPDuelHost`, toasts, `BattleEngaged` для UI боя, refresh MP/CD
- P2P trade Social gate **PASS** (Local Server 2p, 2026-07-22): обмен item↔item, тост успеха, сумки обновляются
- P2P trade: success toast `Обмен успешен` + `CANCEL_REASON_TEXT`; client `DisplayOrder = 500` / `Готово`; server coerces item ids before transfer (PlayerTradeSystem, PlayerTradeController)
- Dirt road Haven→Arena: была на Y≈0.12 (не читалась на baseplate) → snap к земле + толщина 0.5, Sand/контраст, Y≈1.4
- `QuestTrackerHud`: счётчик цели справа (`3/5`), не обрезается Truncate; `CollectItem` синхронизируется с инвентарём в `GetActiveQuests`
- Боевая катана: сабельный хват — ось клинка = продолжение `RightLowerArm→Hand`, ребро вниз, позиция у `RightGripAttachment` (без залома запястья)
- Меч: `REST_C0` / `BLADE_REST_C0` — клинок остриём вверх (`+90°` вместо `-90°`)
- `QuestTrackerHud` — меньше окно (200×140, Y=268), не заходит под миникарту справа сверху
- Меч `RealmBlade`: в Studio Source был «склеен» старый Tool-`giveBlade` на `CharacterAdded` (меч при спавне) — перезаписан на Model+Motor6D + `stripOnSpawn`; атака — tween замах/взмах `BladeMotor` + slash + выпад

### Changed
- P2P trade Social gate prep: знак у примерочной «P2P ОБМЕН → T»; Studio `/tradetest` (ловушка+зелье+косметика); `PlayerTradeSystem`
- Haven→Arena road: **street lamps** + указатели `← HAVEN` / `ARENA →` вдоль тротуаров
- Haven→Arena road: **двухполосная anime** по рефу Creator Store [`Anime Road`](https://create.roblox.com/store/asset/10235862952) (двойная жёлтая + тротуары); убрана «зебра» от чередования цветов
- Haven→Arena road: **anime asphalt** (Asphalt + белый curb + жёлтая пунктир) + Catmull-Rom сглаживание; `BuildDirtRoadToArena`
- Otaku Haven: грунтовая dual-track дорога Haven Exit → Arena Entrance (`DirtRoad_HavenToArena`, ~151 studs); `OtakuHavenBuilder.BuildDirtRoadToArena`
- Otaku Haven: приглушены гирлянды/фонари (Fairy 0.18/3.5, Paper 0.55/8, Path 0.4/9) + bloom Intensity 0.22
- Otaku Haven: **atmosphere décor** — гирлянда, ковровая дорожка Genkan→касса, бумажные фонари, баннеры CATCH/BATTLE/EVOLVE/COLLECT, растения, споты, path lanterns + parking silhouettes; `ColorCorrection`/`Bloom` mood; `OtakuHavenBuilder.lua`
- Blender Tourbillon: **арки ellipse+haunch** — задний проём вертикально вытянут (rh/rv≈0.52/0.57), ArchLip 22–158°; колёса rF/rR **0.49/0.50**; gap~2cm по бокам; haunch поднят; `compare_side_ref.png`
- Blender Tourbillon: **колёса+арки vs SIDE wire** — PDF Ø были малы на WB-lock рефе; rF/rR **0.47/0.485** (было 0.354/0.370); arch gap **~2.5cm** (было 14cm); ArchLip не полный полукруг (25–155°); `compare_side_ref.png`
- Blender Tourbillon: **SIDE envelope pass1** — sil `sil_side_full_clean.json` → BodyWire Z-fit (WB hubs lock, tips→±L/2, peak H=1.189); арки tire+14cm; SideHalf+ArchLip; `compare_side_ref.png`; `tourbillon_wire_v1.blend`
- Blender Tourbillon: **checkpoint 2026-07-20** — прогресс в `tourbillon_wire_v1.blend` + `NEXT-SESSION` / `SESSION-2026-07-20`; завтра натягивать модель на рефы (SIDE→FRONT→TOP)
- Blender Tourbillon: **SIDE реф recalib** — старый кроп обрезал нос/корму → ложные выводы о длине; новый `crop_side_wire_full_noseR.png`; калибровка **только WB+земля**; tip-to-tip не SoT (wire-платформа длиннее/выше Tourbillon при WB-lock); `compare_side_ref.png`
- Blender Tourbillon: **ArchLip скругление** — кромки арок на окружность (open≈tire+5.5cm); `ArchLipFL/FR/RL/RR` pipe-кольца; SideHalf обновлён; `check_side_archlip.png`
- Blender Tourbillon: **ortho continue** — чистые арки boolean; SideHalf для SIDE; Body remirror + ширина 2.051; RefPlanes Side/Front/Top; чеки `check_side/front/top.png`
- Blender Tourbillon: **SIDE арки + ortho** — причина «закрытых» колёс: в ortho SIDE сливаются L/R половины; `BodyWire_SideHalf` (+X) с открытыми арками r≈0.50; RefPlane_Side WB-lock; `side_arch_check.png`; полный `BodyWire` скрыт в viewport (вкл. для ¾)
- Blender Tourbillon: **ortho-align + арки** — арки открыты (r≈tire+8cm + clear skirt), колёса видны на SIDE; fit SIDE sil×TOP hw; RefPlane Side/Front/Top + Cam_*; `side_arch_check.png`; `tourbillon_wire_v1.blend`
- Blender Tourbillon: **WIRE v1.1** — спицы в плоскости вращения (YZ); intakes врезаны в Body (не отдельные); Front/RearBumper по TOP hw(y); Windshield+DoorGlassL/R (прозрачные); `tourbillon_wire_v1.blend`
- Blender Tourbillon: **WIRE v1 ≈ ¾ refs** — denser BodyWire+subdiv, horseshoe/8×LED/intakes, C-line, side intakes, mirrors, RearLED+7 fins, Y-spokes; front wheels blue wire; ~12.5k tris; `tourbillon_wire_v1.blend`
- Blender Tourbillon: **RESET → WIRE v0** — сцена очищена; глубокий разбор ortho+¾ wire vs PDF SoT (L4671/W2051/H1189/WB2740); `BodyWire` loft + Wheel placeholders; `tourbillon_wire_v0.blend`; `TOURBILLON_WIRE_RESEARCH.md`
- Blender Tourbillon: **SIDE ortho-fit по сетке** — `RefPlane_Side` = `crops/crop_side_wire_noseR.png` (кроп SIDE из `ortho4_wireframe`, нос вправо); WB-lock hubs 274 cm; силуэт из wire (`crop_side_wire_sil.json`); Body loft пересобран (нос↓ крыша 1.189); `side_wire_fit_check.png`; ~1.4k Body tris
- Blender Tourbillon: **СТАРТ СБОРКИ LP v1** — loft Body SIDE×TOP + Mirror, boolean-арки, horseshoe+8×LED+intakes+splitter, RearLED+diffuser, C-line, Y-spokes, glass; ~2.2k tris; `bugatti_tourbillon_lp.blend/.fbx`; бриф `TOURBILLON_BUILD_START.md`
- Blender Tourbillon: **RESET** — сцена очищена, старт с нуля; `bugatti_tourbillon_lp.blend` = пустой canvas (+ Camera); прошлые Caps/join сняты
- Blender Tourbillon: **стыки Cap/Arch→Body** — carve под оболочками, join+weld NoseCap/RearCap/ArchLip* в единый `Body` (paint); Windshield отдельно; арки переоткрыты; ~7.6k Body / ~12k total tris; `bugatti_tourbillon_lp.*`
- Blender Tourbillon: **SIDE корма** — `RearCap` deck/haunch + `ArchLipRL/RR` (круглые); Body scraps вычищены; sail к envelope (~8 mm); Diffuser/RearLED; `rear_side_check.png`; `bugatti_tourbillon_lp.*`
- Blender Tourbillon: **SIDE full envelope** — Body крыша/корма/днище по `ref_side_wb` (`RefPlane_Side`), H clamp 1.189; перед: NoseCap+ArchLip+Windshield сшиты; mean sil err~7 mm; `bugatti_tourbillon_lp.*`
- Blender Tourbillon: **SIDE капот + лобовое** — deck Body по розовому envelope (лёгкая valley); `Windshield` пересобран (transparent wrap, err~3 mm); плавный стык cowl/A-pillar; `bugatti_tourbillon_lp.*` + `hood_ws_check.png`
- Blender Tourbillon: **SIDE нос point-to-point** — `NoseCap` по каждому sample розового tip (err~3 mm); арки — чистые круговые `ArchLip*`; Body front Laplacian/corrective smooth без рваных силуэтов; `bugatti_tourbillon_lp.*`
- Blender Tourbillon: **SIDE капот + передняя арка** — кроп `ref/crops/crop_side_hood_arch.png`; `ArchLipFL/FR` по розовому inner (~3 cm gap); колесо видно; `NoseCap` до tip Y≈2.48; `bugatti_tourbillon_lp.*` + `hood_arch_check.png`
- Blender Tourbillon: **SIDE днище** — rocker поднят к сплошной нижней линии рефа (~0.14–0.20 над пунктиром земли); арки не задеты; колёса на z=0; `bugatti_tourbillon_lp.*`
- Blender Tourbillon: **SIDE капот** — поднят deck/brow к сплошному контуру (tip низкий, valley, подъём к лобовому); fender brow сохранён; `bugatti_tourbillon_lp.*`
- Blender Tourbillon: **SIDE BG fit** — пунктир = земля (z=0), сплошной контур = кузов; `RefPlane_Side` по solid tips/roof + WB 274; нос/корма по solid envelope; колёса на осях и на земле; `bugatti_tourbillon_lp.*`
- Blender Tourbillon: **SIDE nose/rear** — контур по розовому SIDE (tips + envelope), `RefPlane_Side` content-lock (WB 274 / H 119), Cam_Side с носом вправо; overlay-check; `bugatti_tourbillon_lp.*`
- Blender Tourbillon: **SIDE WB-lock** — `RefPlane_Side` = sheet crop `ref/crops/crop_side_wb.png`, калибровка по осям **274 cm** (hubs → YF/YR); колёса вписаны в реф; Body nose/roof/rear по SIDE-контуру; ~9k tris; `bugatti_tourbillon_lp.*`
- Blender Tourbillon: **ortho-ref mode** — `Cam_Side/Front/Rear/Top` + `RefPlane_*` (SIDE фото на bbox L×H, FRONT/REAR/TOP кропы с листа); Body silhouette pass + boolean-арки; ~7.8k tris; превью/fbx; `ref/crops/`; `bugatti_tourbillon_lp.*`
- Blender Tourbillon: **pass8 HS** — half-grid Body + Mirror + subdiv×1 (~7.6k tris), profile maps SIDE×TOP; horseshoe без tear; ortho обновлены; `bugatti_tourbillon_lp.*`
- Blender Tourbillon: **pass7** — цельный нос без tear-cut horseshoe (carbon recess + rim поверх), planar fascia, subdiv Body ~9k tris; ortho обновлены; `bugatti_tourbillon_lp.*`
- Blender Tourbillon: **pass5–6** — единый Body + subdiv×1 (~9k tris), horseshoe cut, смягчённый капот, арки переоткрыты, ArchLip скрыты (clip); ortho/fbx; `bugatti_tourbillon_lp.*`
- Blender Tourbillon: **pass5+** — единый Body nose→tail (без шва FrontFascia), horseshoe/intake cutouts, valley~0.11, скрыты шумные DoorSkin для чистого SIDE; ortho/fbx обновлены; `bugatti_tourbillon_lp.*`
- Blender Tourbillon: **pass4** — denser Body без laplacian (ровнее SIDE), valley~0.11–0.13; FRONT flying-fender (gap под LED→intakes), grille bars, slim flush DRL; ortho обновлены; `bugatti_tourbillon_lp.*`
- Blender Tourbillon: **pass3** — C-line groove + duotone по полигону C, `ArchLip*` губы арок, flush chrome C-line; ortho обновлены; ~5.8k tris; `bugatti_tourbillon_lp.*`
- Blender Tourbillon: **pass2 по листу** — плотный SIDE loft (cab-forward, haunch, valley~0.12), FRONT flush horseshoe/LED/intakes, denser C-line, открытые арки, Y-spokes, wrap windshield; ortho обновлены; ~3.7k tris; `bugatti_tourbillon_lp.*`
- Blender Tourbillon: **сборка с нуля по ТЗ v2026-07-19d** — Body SIDE×TOP loft (долина капота ~0.11, крыша 1.189), FRONT horseshoe+4×LED+intakes, REAR LED-bar+diffuser+spine, C-line/intakes, flush dihedral doors, Y-spokes на WB; ortho side/front/rear/top + ¾; ~3.3k tris; `bugatti_tourbillon_lp.*`
- Blender Tourbillon: ТЗ **v2026-07-19d** переписано по orthographic sheet (side/front/rear/top + 467/205/119/274 cm); SoT-реф `ref/tourbillon_ortho_sheet_ref.png`; `TOURBILLON_MODELING_BRIEF.md`
- Blender Tourbillon: flush front (horseshoe+brow+4×LED+intake), fresnel-glass, arch lips, cabin hint; Cycles `front_cycles.png`; `bugatti_tourbillon_lp.*`
- Blender Tourbillon: сглаженный Body, капот/deck выше (долина ~0.09–0.11), стекло Mix+Transmission, Cycles-превью `bugatti_tourbillon_front_cycles.png`; `bugatti_tourbillon_lp.*`
- Blender Tourbillon: арки открыты под колёса, шины на земле в арках, Y-spokes, стекло читаемее; превью обновлены; `bugatti_tourbillon_lp.*`
- Blender Tourbillon: **сборка с нуля по ТЗ v2026-07-19c** — Body loft (side/top maps + арки), front horseshoe/4×LED/intakes, прозрачное лобовое, C-line/duotone, rear LED+diffuser, dihedral doors, Y-spokes; bbox 4.671×2.051×1.189; ~4.8k tris; `Tourbillon_Controls`; превью side/front/top/rear/3q; `bugatti_tourbillon_lp.*`
- Blender Tourbillon: единое ТЗ **v2026-07-19c** — анализ DNA + карты пропорций side/front/top/rear из open sources (PDF 4671×2051×1189, WB 2740, шины, C-line, flying fender, dihedral); `TOURBILLON_MODELING_BRIEF.md`
- Blender Tourbillon front-match: horseshoe+mesh впереди кузова, каналы капота/высокие крылья, 4×LED, intakes, spine, **прозрачное** лобовое (проём в Body); ref `tourbillon_front_blue_ref.png`; `bugatti_tourbillon_front.png`; `bugatti_tourbillon_lp.*`
- Blender Tourbillon: капот и багажник выше (без глубоких долин между крыльями); колёса в арках крыльев капота/кормы; side-match + Y-спицы; ref `meshes/ref/tourbillon_side_blue_ref.png`; `bugatti_tourbillon_side.png`; `bugatti_tourbillon_lp.*`
- Blender Tourbillon side-match по фото: длинная тёмная корма/haunch, flush horseshoe+LED с капотом, Y/snowflake-спицы, C-line + side intake; ref `meshes/ref/tourbillon_side_blue_ref.png`; превью `bugatti_tourbillon_side/front/threequarter.png`; `bugatti_tourbillon_lp.*`
- Blender Tourbillon **единая модель** по обновлённому ТЗ: Body с дверным проёмом + flush `DoorSkin/Glass/Roof` на `DoorPivot*` (dihedral); `HeadlightL/R` (LED emission + Area Light); Windshield fixed; duotone; габариты ~4.67×2.05×1.19; script `Tourbillon_Controls`; `TOURBILLON_MODELING_BRIEF.md` v2026-07-19b
- Blender Tourbillon: briefing по открытым спекам + модель в масштабе ~4.67×2.05×1.19 м; **duotone** (светлый фюзеляж / тёмный зад по C-line); **dihedral doors** (`DoorPivotL/R` + Door/Glass/Roof); side intake, hood channels/frunk hint; `TOURBILLON_MODELING_BRIEF.md`
- Blender hypercar: подгонка под ¾ front-left (silver-blue, C-line, horseshoe, intakes, carbon lower); фронт/бок/верх согласованы; `bugatti_tourbillon_threequarter/front/side/top.png`
- Blender hypercar side: цельный силуэт без разрывов (убраны floating A-pillar/valley/intake/rocker slab); continuous Body + C-line + glass; champagne/dark two-tone; `bugatti_tourbillon_side.png`
- Blender hypercar A-pillar: тонкие сильно заваленные стойки + chrome edge, стык с C-line; `APillarL/R`, `APillarChromeL/R`
- Blender hypercar cabin front: лобовое с аркой и M-кромкой, chrome spine через стекло на капот, V-линии капота, A-pillars; `bugatti_tourbillon_cabin_front.png`
- Blender hypercar front: horseshoe grille + mesh, vertical chrome spine, 4×LED/side under brows, side intakes with fins, full-width splitter, mirrors; `bugatti_tourbillon_front.png`
- Blender hypercar: сверху меньше «песочных часов» (талия ~1.06 vs арки ~1.20); сбоку — низкий профиль, C-line, two-tone, side skirt, raised wing; `bugatti_tourbillon_side/top.png`
- Blender hypercar wheel arches: передние «floating fender» + deep hood valleys; задние muscular coke-bottle flare + engine-deck valleys; `ArchFL/FR/RL/RR`, `Valley*`; ~12k tris; `bugatti_tourbillon_lp.*` + `bugatti_tourbillon_arch_front/rear.png`
- Blender hypercar top-view: coke-bottle силуэт (широкие арки / мягкая талия), azure paint, центральный spine + red LED, hood channels, engine bay/intakes, wrap windshield; ~12k tris; `bugatti_tourbillon_lp.*` + `bugatti_tourbillon_top.png`

### Added
- Blender hypercar: улучшение по пользовательским фото (satin silver/champagne/dark duotone, quad LED, C-line, wavy red rear LED, Y-spokes, Tourbillon-like cabin dials) без брендовых надписей; ~5.2k tris; `bugatti_tourbillon_lp.*` + refs в `meshes/ref/`
- Hypercar `TourbillonCar` (пропорции Tourbillon-like, без брендинга): Blender FBX `docs/realm-of-spirits/assets/meshes/tourbillon_car.fbx`; Studio — butterfly-двери (HingeConstraint), `VehicleSeat` + ProximityPrompt «Сесть», arcade-drive (WASD / экранные кнопки) через `TourbillonCarController` + `TourbillonDriveUI`
- Blender катана `RealmKatana` (~3.36 stud): FBX `docs/realm-of-spirits/assets/meshes/realm_katana.fbx`; Open Cloud asset `126498557070994` → Studio `MeshImports.RealmKatana`; `PlayerWeaponService` берёт её как шаблон клинка
- Blender→Roblox auto mesh pipeline: `scripts/roblox_upload_model.py` + `blender_export_for_roblox.py` + skill `realm-mesh-from-prompt` (Open Cloud Model upload → Studio `insert_asset`)
- `fair_combat_check.py` — CI/local gate: gacha cosmetics-only, Flex/trade/UI clarity, `FAIR-COMBAT.md` (включён в `quality_gate.py`)
- Flex equip wardrobe — `FittingRoom` → `OpenWardrobe` / `EquipCosmetic`; Safe-only `FlexBillboard` над персонажем (`OtakuHavenService` + `OtakuHavenController`)
- `PlayerTradeController` — клиентский P2P UI: ProximityPrompt «Обмен» (T) в Safe, панель 1 слот / Готов / Отмена
- Gacha result popup — явный дисклеймер «Только косметика — без бонусов в бою»
- `FAIR-COMBAT.md` — политика P1 Social; gacha cosmetics-only; `PlayerTradeSystem` (1-slot P2P, Safe)
- Explore C PASS (2026-07-18 Play): side **101** «Помощь торговцу» — Accept → 5× огненный кристалл → трекер `5/5` + `?` → TurnIn у Мики (кристаллы списываются)
- `QuestTrackerHud` — окно активных квестов под миникартой: название, счётчики целей, золотой `!` / изумрудный `?`
- `UIFeedback` — центральные flash-сообщения и всплывающий урон в бою (вынесено из `UIController` из‑за лимита Luau locals)
- Бой — числа урона над головой: белые по врагу, кроваво‑красные по игроку (float + fade)
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
- P2P trade: success toast `Обмен успешен` + `CANCEL_REASON_TEXT`; client `DisplayOrder = 500` / `Готово`; server coerces item ids before transfer (PlayerTradeSystem, PlayerTradeController)
- `validate_spirit_database.py` — только `SpiritDatabase.Spirits`, формат `SkillIds` + сверка с `SkillCatalog` (quality_gate снова зелёный)
- Docs mirror `studio/QuestSystem.lua` synced from Studio (was stale): quest 103 UniqueItem **7**, quest 105 Prerequisites **101–104**
- Аудит 2026-07-18: zoom BtnGlow не перехватывает клики; `QuestTrackerHud` refresh из `OpenQuestUI.Active`; catch unlock nil-safe
- `QuestTrackerHud` — название квеста читается чётко (контраст, обводка, ZIndex; empty-лейбл больше не перекрывает строки)
- Поимка без ловушек (ItemId 1): кнопка/E неактивны в обычном режиме и при квестах; «НЕТ ЛОВУШКИ» — крупно по центру экрана 1,5 с
- `UIController` — compile error «Out of local registers» (overlay-логика → `UIFeedback`)
- Грозовой Дракон (SpiritId 4): `MovementType = Walk`, спавн на CombatZone (не на BattleArena sign), принудительная посадка на землю
- `QuestSystem` — сдача CollectItem списывает предметы + проверка инвентаря; Accept больше не авто-закрывает CatchSpirit от стартового духа; seed CollectItem из инвентаря; nil-guard data/Stats/Inventory; story 4–6 Items → реальные Id из ItemCatalog (1/2/3)
- `QuestUI` — цели CollectItem и награды Items из ItemCatalog; имена UniqueItems; убран дубль elseif
- `QuestSystem` / `QuestUI` — «Помощь торговцу» (101) был в Available, но прятался ниже короткого списка из‑за `pairs()`; сортировка Level→Id + высота списка 120
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
- `UIController` — панель «Мои духи» в левом нижнем углу; кнопки зума миникарты крупнее и на краю круга (Q1 / Q4)
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

### Fixed
- P2P trade: success toast `Обмен успешен` + `CANCEL_REASON_TEXT`; client `DisplayOrder = 500` / `Готово`; server coerces item ids before transfer (PlayerTradeSystem, PlayerTradeController)
- `GameManager` / `DataStoreManager` — у пойманных и стартовых духов пишутся `Name` + `SkillIds`; `NormalizeSpirits` на LoadData
- `EvolutionSystem` — `OldName` берётся из каталога, если у инстанса нет имени
- `GameManager` — `BonusHP` эволюции учитывается в max HP боя
- `RankSystem:PromoteRank` — награды в `CopperCoins` (раньше писало в несуществующий `Coins`)
- `ZoneController` — `EntranceBell` как Model: `Touched` вешается на BasePart

### Applied (2026-07-15)
- P1 Identity: server/client auto-suite PASS (slot3×5, evolve meta, rank next, UI hooks)
- P1 Identity: manual Play PASS (evo banner, Attack3, rank ≤2 клика); Studio DevBoost: `[DEV] Evo Boost` / LeftAlt+B (F9 = консоль Studio)
- P1 Explore Slice A: tutorial FireCrystal у Exit→Combat, весь лут в Combat AABB; toast Exit/Combat про кристаллы (E)
- `UIController` — имена предметов в сумке/инвентаре из `ItemCatalog` (кристалл 101 больше не «Предмет #101»)
- P1 Explore Slice B: `WorldLootService` — ледяные кристаллы (ItemId 102) в Combat; типы лута: fire / ice / chest
- P1 Explore Slice C: side 103 — Посох Хранителя через UniqueItems (не ghost Inventory Id7); side 105 prereq = 101–104
- P1 Explore Slice C UX: Available sort Level→Id + `QUEST_LIST_H=120` — «Помощь торговцу» видна сразу после «Первые шаги» (funnel play-тест — следующий сеанс)

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
- P2P trade: success toast `Обмен успешен` + `CANCEL_REASON_TEXT`; client `DisplayOrder = 500` / `Готово`; server coerces item ids before transfer (PlayerTradeSystem, PlayerTradeController)
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
- P2P trade: success toast `Обмен успешен` + `CANCEL_REASON_TEXT`; client `DisplayOrder = 500` / `Готово`; server coerces item ids before transfer (PlayerTradeSystem, PlayerTradeController)
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
