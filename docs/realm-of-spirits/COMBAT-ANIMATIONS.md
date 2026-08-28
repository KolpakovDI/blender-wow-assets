# Боевые анимации — классификация и выбор

> **SoT (код):** `ClientController` · `CombatAnimResolver` · `CombatAnimations` в `ReplicatedStorage.RealmOfSpirits`  
> **Классификация навыков:** `SkillCatalog.CombatMeta` → `Range` + `DamageKind` · см. [`SPIRIT-SKILLS.md`](SPIRIT-SKILLS.md)  
> **Anim block (A1 restore):** [`BLOCK-ANIM-CHAR-ART-2026-08-28.md`](BLOCK-ANIM-CHAR-ART-2026-08-28.md) § A1 · research [`RESEARCH-AI-ANIM-ART-2026-08-28.md`](RESEARCH-AI-ANIM-ART-2026-08-28.md) · paid setup [`OWNER-SETUP-PAID-AI.md`](OWNER-SETUP-PAID-AI.md)

## Статус (2026-08-23)

**Body sword-swing отключён.** `CombatAnimResolver.Play()` — no-op; `ShouldPlayBodyAnim()` → `false`. Папка `CombatAnimations/` и Linked Sword клипы (`522635514` / `522638767`) удалены из place. При атаке остаются: **blade tween**, **root lunge**, feedback («Удар!» / «Выпад!»). Ниже — архив классификации и ID (для повторного включения).

### A1 restore — free vs paid paths (2026-08-28)

| Path | Cost | When | Steps |
|------|------|------|-------|
| **Free (recommended day 1)** | **$0** | Команда **«A1»** | Restore `CombatAnimations/` + resolver · IDs `522635514` / `522638767` / `129967390` · `VerifyAllClips` smoke |
| **Mixamo custom** | **$0** | Need custom feel, no subscription | Mixamo FBX → Blender root-key fix → owner publish Animation → agent wires ID |
| **UGCraft Creator** | **~$9/mo** | Free IDs feel weak after A1 PASS | Text→R15 → owner publish → **«A1 UGCraft»** |
| **DG proprietary** | License | Owner has Team Create / license | Manual extract → owner publish — blocked for public hunt |

Подробно: [`BLOCK-ANIM-CHAR-ART-2026-08-28.md`](BLOCK-ANIM-CHAR-ART-2026-08-28.md) § A1 · [`RESEARCH-AI-ANIM-ART-2026-08-28.md`](RESEARCH-AI-ANIM-ART-2026-08-28.md) § Step-by-step A1.

## Dueling Grounds — deep hunt (2026-08-23)

**Источник стиля:** [Dueling Grounds](https://www.roblox.com/games/94217045453265/Dueling-Grounds) — PvP melee duels (katana / daggers / naginata). **R15**, кастомные клипы, **AnimationPriority Action** на ударах.

| ID | Значение |
|----|----------|
| Place ID | `94217045453265` |
| Universe ID | `9051406594` |
| Creator group | [Dueling Grounds](https://www.roblox.com/communities/35562865/dueling-grounds) (`35562865`) |
| Copying allowed | **false** — place нельзя «Edit as Copy» без Team Create |

### Результат: DG animation IDs — **blocked, need user-provided IDs**

Публичных **Dueling Grounds** animation asset ID **не найдено** после расширенного поиска:

| Источник | Результат |
|----------|-----------|
| DevForum / gist / robloxscripts / GitHub raw | Нет списков DG katana M1/M2; exploit-лоадеры не содержат rbxassetid |
| Creator Store `CreatorName=Dueling Grounds` Category=Animation | **0** анимаций |
| Catalog API group `35562865` Animation | **0** записей |
| Studio MCP `search_asset` «Dueling Grounds katana animation» | Только посторонние модели, не Animation |
| Studio MCP group inventory `35562865` | Группа не принадлежит аккаунту Studio — недоступна |
| Wiki (Fandom, BloxInformer) | Описание комбо/таймингов, **без asset ID** |
| Forum «katana slash» IDs (`12905465996`, `10506078364`, …) | **Length = 0** в Studio (битые/приватные) |
| Creator Store free sword **models** (15+ hits) | **Model** asset — внутри `KeyframeSequence` в AnimSaves, **не** published Animation ID → `VerifyClip` Length 0 |

### Verified free sword animations (Studio MCP Play, 2026-08-23)

Web: DevForum [Classic Sword](https://devforum.roblox.com/t/classic-sword-function/3873089) · [Roblox Wiki Sword](https://roblox.fandom.com/wiki/Sword) · gist [Blackwatch69 R6/R15 list](https://gist.github.com/Blackwatch69/f0c4ed6e89254fe5d8de52408a848bca) · Creator Store `search_asset` free sword/katana (models only).

**Только IDs с `VerifyClip` → Length > 0:**

| Asset ID | Name / Source | Length | Free? | Recommended slot |
|----------|---------------|--------|-------|------------------|
| `522635514` | Roblox Linked Sword R15 slash · R15 Animate `toolslash` | **0.5s** | ✅ official | **SlashR15**, SpellTapR15, RangedShotR15 |
| `522638767` | Roblox Linked Sword R15 lunge · R15 Animate `toollunge` | **1.5s** | ✅ official | **LungeR15**, SpellImpulseR15 |
| `746398327` | Gist «Down Slash» R15 | **0.5s** | ✅ public | SlashR15 (alt, snappy) |
| `674871189` | Gist «Crazy Slash» R15 | **0.75s** | ✅ public | SlashR15 (alt) |
| `717879555` | Gist «Float Slash» R15 | **1.0s** | ✅ public | SlashR15 or light Lunge |
| `675025570` | Gist «Rotate Slash» R15 | **2.0s** | ✅ public | LungeR15 (alt, heavy) |
| `675025795` | Gist «Pull» R15 | **2.0s** | ✅ public | LungeR15 (alt, heavy) |
| `129967390` | R6 Animate `toolslash` (Classic Sword legacy) | **0.5s** | ✅ official | SlashR6 |
| `129967478` | R6 Animate `toollunge` (Classic Sword legacy) | **1.5s** | ✅ official | SlashR6 lunge |
| `218504594` | Gist «Full Swing» R6 · DevForum give-sword script | **0.7s** | ✅ public | SlashR6 |
| `35978879` | Gist «Sword Slice» R6 | **2.25s** | ✅ public | SlashR6 (slow heavy) |
| `204295235` | Gist «Sword Slam» R6 | **2.0s** | ✅ public | SlashR6 (slow heavy) |

**Рекомендация (top pair для RoS):** оставить **`522635514` + `522638767`** в `FALLBACK_IDS` — единственная официальная бесплатная R15-пара Roblox, уже в `CombatAnimResolver`. Альтернатива «чуть живее»: `674871189` slash + `717879555` heavy.

**Failed / Length = 0 (не использовать):**

| Asset ID | Источник | Причина |
|----------|----------|---------|
| `522635513` | Pastebin typo alternate slash | Length 0 |
| `941992724` | Classic Sword R6 gear script | Length 0 |
| `12905465996` | DevForum katana | private/broken |
| `10506078364` | Forum combo | private/broken |
| `11414802020` | DevForum swing pack | private/broken |
| `15161132977` | DevForum sword | private/broken |
| `8572359340` | DevForum dual katana | private/broken |
| `13761775939` | DevForum customizable sword | private/broken |
| `708553116` | Gist Zombie Attack | Length 0 |
| `90959017095654` | Creator Store model | Model, not Animation |
| `18997558918` | Creator Store sword anims | Model, not Animation |
| `9486802962` | Creator Store Katana Slashing | Model, not Animation |
| `9620544604` | Creator Store sword anims | Length 0 |

**DG clip table (целевая схема — заполнить вручную):**

| Роль RoS | Track (CombatAnimations/) | DG weapon | DG move | AnimationId | Length | Verified |
|----------|---------------------------|-----------|---------|-------------|--------|----------|
| Slash / SpellTap / RangedShot | `SlashR15` | Katana | M1 light | *(blocked)* | — | ❌ |
| Lunge / SpellImpulse | `LungeR15` | Katana | M2 heavy | *(blocked)* | — | ❌ |
| R6 fallback | `SlashR6` | — | — | *(blocked)* | — | ❌ |

### Как получить **exact** DG clips (ручные шаги)

1. **Team Create / collaborator** — если есть доступ к place DG: открыть `94217045453265`, найти `ReplicatedStorage` / `ServerStorage` / weapon modules → папки `Animations`, `Katana`, `M1`, `M2` и т.п.; скопировать `Animation` объекты в RoS `CombatAnimations/`.
2. **Разрешение создателей** — Discord [duelinggrounds](https://discord.com/invite/duelinggrounds), группа `35562865`; попросить опубликовать клипы в Creator Store или передать asset ID для licensed use.
3. **Asset Manager** — после копирования Animation в RoS: Properties → `AnimationId` → вставить в `CombatAnimResolver.DG_CLIPS` и в `CombatAnimations/*.AnimationId`; smoke `LoadAnimation` → **Length > 0**.
4. **Не использовать** exploit/asset-dump скрипты — нарушение ToS и нестабильные ID.

**Код:** `CombatAnimResolver.DG_CLIPS` — заполнен best free Linked Sword set (2026-08-23). Proprietary DG Katana IDs по-прежнему недоступны публично.

### Вариант 3 — best free set applied (2026-08-23) ✅

**Приоритет resolver:** `CombatAnimations/<Track>.AnimationId` (если не пустой) → `DG_CLIPS[Track]` → `FALLBACK_IDS` (тот же free set).

**Production IDs (Applied):**

| Ключ | AnimationId | Length | Роль |
|------|-------------|--------|------|
| `SlashR15` | `rbxassetid://522635514` | **0.5s** | light slash |
| `LungeR15` | `rbxassetid://522638767` | **1.5s** | heavy lunge |
| `SpellTapR15` | `rbxassetid://522635514` | 0.5s | melee spell tap |
| `SpellImpulseR15` | `rbxassetid://522638767` | 1.5s | melee spell heavy |
| `RangedShotR15` | `rbxassetid://522635514` | 0.5s | ranged release |
| `SlashR6` | `rbxassetid://129967390` | **0.5s** | R6 Animate toolslash |

Синхронизировано в: `DG_CLIPS` · `FALLBACK_IDS` · `CombatAnimations/*.AnimationId`.

**Smoke Play (MCP 2026-08-23):** `VerifyAllClips` 6/6 OK, `source=folder`; skill **1**→Slash IsPlaying · skill **119**→Lunge IsPlaying.

```lua
-- DG_CLIPS (production)
SlashR15 = "rbxassetid://522635514",
LungeR15 = "rbxassetid://522638767",
SpellTapR15 = "rbxassetid://522635514",
SpellImpulseR15 = "rbxassetid://522638767",
RangedShotR15 = "rbxassetid://522635514",
SlashR6 = "rbxassetid://129967390",
```

> Папка **CombatAnimations/** имеет приоритет над `DG_CLIPS`. Оба слоя сейчас содержат один и тот же free set.

**Re-smoke (Play):**

```lua
local R = require(game.ReplicatedStorage.RealmOfSpirits.CombatAnimResolver)
for name, row in R.VerifyAllClips() do print(name, row.source, row.assetId, "len=" .. row.length, row.ok and "OK" or "FAIL") end
```

### DG feel (тайминги — без смены клипов)

| Аспект DG | Наблюдение | Применение в RoS |
|-----------|------------|------------------|
| Light attack (M1) | Быстрый, ~0.5s wind-up (katana) | `Slash` speed **1.45**, lunge **1.6 stud**, blade windup **0.06s** |
| Heavy attack (M2) | Медленнее, длиннее commit | `Lunge` speed **0.85**, lunge **3.5 stud**, windup **0.14s** |
| Forward step | Короткий выпад вперёд на light | `GetTiming().lungeOut` 0.08 / back 0.12 |
| Weapon read | Читаемый arc клинка | Overhead blade tween (light vs heavy углы) |
| Spell / ranged | DG — только melee | RoS cat.2–4: те же клипы + tuned timing или `None` |

**Текущий production set (NOT proprietary DG):** Roblox Linked Sword — единственные стабильно загружаемые публичные sword-attack клипы:

| Роль | Track (CombatAnimations/) | AnimationId | Длина (smoke) | Источник |
|------|---------------------------|-------------|---------------|----------|
| Light slash R15 | `SlashR15` | `522635514` | **0.5s** | [DevForum Classic Sword](https://devforum.roblox.com/t/classic-sword-function/3873089) · R15 default `toolslash` |
| Heavy lunge R15 | `LungeR15` | `522638767` | **1.5s** | idem · R15 default `toollunge` |
| Spell tap R15 | `SpellTapR15` | `522635514` | 0.5s | alias light |
| Spell impulse R15 | `SpellImpulseR15` | `522638767` | 1.5s | alias heavy |
| Ranged shot R15 | `RangedShotR15` | `522635514` | 0.5s | release на месте |
| Slash R6 | `SlashR6` | `941992724` | — | Classic Sword R6 fallback |

### Root cause (2026-08-23 fix)

Предыдущий pass настроил **тайминги**, но body-anim **не был виден в бою**:

1. `ClientController.playPlayerAttackAnimation` вызывал `CombatAnimResolver.Play()` **после** `waitForBladeModel(char, 0.8)` — до **0.8s** задержки, пока RealmBlade реплицируется с сервера.
2. Визуально оставался только blade Motor6D tween → «анимация ударов не перенесена».

**Fix:** `CombatAnimResolver.Play()` сразу после поворота к цели; ожидание клинка **0.35s** параллельно; track cache в resolver.

**Smoke MCP (post-fix):** skills **1/119/31/11/2** — Action4 `IsPlaying` @ 50ms после `PlayPlayerAttack`; skill **2** → `None` (без track). Resolver direct: skill **1** length **0.5s**, **119** **1.5s**.

### Troubleshooting — «анимация не явно применяется» (2026-08-23)

**Симптом:** Linked Sword IDs (`522635514` / `522638767`) в place, track `IsPlaying=true`, но в Play неочевидно что удар сработал.

**Диагностика (MCP `execute_luau` Client):**

```luau
local hum = game.Players.LocalPlayer.Character.Humanoid
for _, t in hum:FindFirstChildOfClass("Animator"):GetPlayingAnimationTracks() do
    print(t.Name, t.Priority, t.WeightCurrent, t.IsPlaying)
end
```

| Проверка | Ожидание | Если плохо |
|----------|----------|------------|
| Track `IsPlaying` @ 50ms | `SlashR15` / `LungeR15` | см. root cause выше (timing Play) |
| `WeightCurrent` | **1.0** | вызвать `track:AdjustWeight(1, 0.05)` |
| `Priority` | **Action4** | не ниже Animate tool/idle |
| Lower-priority tracks | **0** после Play | idle/movement/tool маскируют руку |
| Root lunge | видимый шаг вперёд | увеличить `GetLungeDistance` |

**Root cause:** track **играл**, но default **Animate idle/movement** (weight 1) смешивались с Action4; root lunge **1.6 stud / 0.08s** был почти незаметен; не было client feedback.

**Fix:**

1. `CombatAnimResolver.stopConflictingTracks()` — `Stop(0.04)` всех track с priority `< Action4` перед `Play`
2. `track:Play(0.05, 1, speed)` + `AdjustWeight(1, 0.05)`
3. Lunge tuning: Slash **2.4 stud / 0.11s**, Lunge **4.2 stud / 0.13s**, speed **1.55 / 0.9**
4. `ClientController.pulseCombatFeedback()` — hint «Удар!»/«Выпад!» 0.3s, gold flash, camera punch в бою, `LastCombatAnim` attribute

**Smoke MCP (visibility pass):** skill **1** → `lowerTracks=0`, w=1.0, lunge=2.4 · skill **119** → lunge=4.2 · hint + flash on attack.

**Ctrl+S** place после правок resolver + ClientController.


| # | Range | DamageKind | Примеры навыков | Статус выбора |
|---|-------|------------|-----------------|---------------|
| **1** | Melee | Physical | коготь, укус, кулак, клешни, пике | **Done** — DG-tuned (2026-08-23) |
| **2** | Melee | Spell | молниеносный удар, касание тумана | **Done** — DG-tuned (2026-08-23) |
| **3** | Ranged | Physical | ледяная стрела, лук/ружьё | **Done** — DG-tuned (2026-08-23) |
| **4** | Ranged | Spell | шторм, луч, волна | **Done** (2026-08-23) |

---

## Категория 1: Ближний + Физический

**11 навыков:** 1, 21, 61, 71, 111, 114, 117, 119, 120, 123, 129.

### Контекст RoS

Хранитель в бою держит **RealmBlade** (`PlayerWeaponService` → `Motor6D` на правой руке). Атака = тело (`playSlashAnimation`) + tween клинка + выпад `HumanoidRootPart` (`ClientController`).

Различие «коготь / укус / кулак» — **VFX и lore духа**, не отдельная анимация тела (иначе катана в руке конфликтует с punch/bite).

### Анализ источников (2026-08-19)

| Источник | ID / asset | Цена | Вердикт |
|----------|------------|------|---------|
| **Roblox Linked Sword** | `522635514` Slash · `522638767` Lunge | Free (Roblox) | **Рекомендовано** |
| R6 Classic Sword | `129967390` / `941992724` | Free | Fallback R6 |
| Creator Store (MCP search) | [90959017095654](https://create.roblox.com/store/asset/90959017095654) и аналоги | $0 | Нестабильное качество; не синхрон с `BladeMotor` |
| DevForum / gist IDs | `717879555`, combo `10506078364+` | «Free» | Неясная лицензия |
| Punch packs (Store) | [109425003260732](https://create.roblox.com/store/asset/109425003260732) | $0 | Ломает визуал с катаной |

### Решение (proposal)

| Роль | AnimationId | Навыки |
|------|-------------|--------|
| **Основная** | `rbxassetid://522635514` | все 11 (слоты 1–2, быстрые физические) |
| **Тяжёлая** | `rbxassetid://522638767` | **119** «Кувалда колосса»; опционально **21** «Теневой укус» |
| **R6 fallback** | `rbxassetid://129967390` | R6 аватары (Animate toolslash) |

Параметры (DG-tuned 2026-08-23): `Priority = Action4`, slash speed **1.55**, lunge **2.4 stud** (heavy **4.2 stud**).

### Реализовано (2026-08-23, DG pass)

- `CombatAnimResolver.GetTiming()` — per-kind blade/lunge/spellHold
- `CombatAnimResolver.IsHeavyKind()` — overhead arc для Lunge/SpellImpulse
- `ClientController` — timing из resolver, не hardcoded 0.12/0.18
- Smoke MCP: skills **1/119/31/11/2** → 5/5 PASS; track load skill1 length **0.5s**

---

## Категория 2: Ближний + Заклинание

**3 навыка:** 31 «Молниеносный удар», 126 «Касание тумана», 303 «Небесный импульс» (Kami Unique).

### Контекст RoS

Ближнее заклинание = быстрый удар катаной с магическим эффектом (VFX/Element в `EffectCatalog`), не punch/bite — **RealmBlade** остаётся в руке.

### Решение (2026-08-23)

| Роль | Track | AnimationId | Навыки | speed | lunge |
|------|-------|-------------|--------|-------|-------|
| **SpellTap** | Slash (быстрый) | `522635514` | **31**, **126** | 1.50 | 1.4 stud |
| **SpellImpulse** | Lunge (тяжёлый) | `522638767` | **303** | 0.88 | 2.8 stud |
| **R6 fallback** | SlashR6 | `941992724` | все cat.2 на R6 | — | — |

Те же free Roblox Linked Sword клипы, что cat.1 — различие в **темпе и дистанции выпада**, не в отдельном punch-pack.

### Реализовано

- `CombatAnimResolver`: `SpellTap` / `SpellImpulse` kinds
- `CombatAnimations/`: `SpellTapR15`, `SpellImpulseR15` (alias тех же asset id)

---

## Категория 3: Дальний + Физический

**1 навык:** 11 «Ледяная стрела» (#2 Ледяная Птица / #102 эво). Будущие лук/арбалет → тот же `RangedShot`.

### Решение (2026-08-23)

| Роль | Track | AnimationId | speed | root lunge |
|------|-------|-------------|-------|------------|
| **RangedShot** | release на месте | `522635514` | 1.40 | **0** |

Поворот к цели + короткий slash-release, **без выпада** HRP. Element/VFX на сервере.

### Реализовано

- `CombatAnimResolver.RangedShot` · `ShouldRootLunge()`
- `ClientController` — lunge tween только если `lunge > 0`
- `CombatAnimations/RangedShotR15`

---

## Категория 4: Дальний + Заклинание

**~40+ навыков** (все `CombatMeta` с `Ranged` + `Spell`, плюс fallback `GetCombatMeta` для Attack/Heal без явной записи).

### Решение (2026-08-23)

| Роль | body anim | blade tween | root lunge |
|------|-----------|-------------|------------|
| **None** | нет | нет | 0 |

Игрок **поворачивается к цели**, пауза 0.12s — урон/VFX/лог на сервере и в battle UI. Исправлен баг: раньше `None` ошибочно давал lunge 2 stud.

### Реализовано

- `ResolveKind` → `None` для Ranged+Spell
- `ShouldBladeTween(false)` · `GetLungeDistance(0)` · `ShouldRootLunge(false)`
- `ClientController` — без blade motor tween для spell
