# Realm of Spirits — Changelog

Формат: [Keep a Changelog](https://keepachangelog.com/). Версии: SemVer.

---

## [Unreleased]

### Added
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
