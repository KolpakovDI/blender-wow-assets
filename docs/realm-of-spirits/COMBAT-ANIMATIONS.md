# Боевые анимации — классификация и выбор

> **SoT (код):** `ClientController` · будущий `CombatAnimations` в `ReplicatedStorage.RealmOfSpirits`  
> **Классификация навыков:** `SkillCatalog.CombatMeta` → `Range` + `DamageKind` · см. [`SPIRIT-SKILLS.md`](SPIRIT-SKILLS.md)

## Матрица (4 категории)

| # | Range | DamageKind | Примеры навыков | Статус выбора |
|---|-------|------------|-----------------|---------------|
| **1** | Melee | Physical | коготь, укус, кулак, клешни, пике | **Proposed** (ниже) |
| 2 | Melee | Spell | молниеносный удар, касание тумана | Pending |
| 3 | Ranged | Physical | ледяная стрела, лук/ружьё | Pending |
| 4 | Ranged | Spell | шторм, луч, волна | Pending |

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
| **R6 fallback** | `rbxassetid://941992724` | R6 аватары |

Параметры как сейчас: `Priority = Action4`, slash speed **1.2**.

### Следующий шаг (Studio)

1. `ReplicatedStorage.RealmOfSpirits.CombatAnimations/` — Animation objects
2. Модуль `CombatAnimResolver` или ветка в `ClientController` по `CombatMeta`
3. Skill **119** → lunge track
4. Smoke: Play → бой → skill 1 / 119 → проверить клип с RealmBlade
5. **Ctrl+S** на `.rbxl`

---

## Категории 2–4

Будут добавлены после утверждения категории 1 и smoke в Studio.
