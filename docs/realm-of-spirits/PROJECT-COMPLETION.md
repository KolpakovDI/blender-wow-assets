# Realm of Spirits — Project Completion

**Scope:** shippable **10-min demo** (фаза 1), не полный P2-продукт.  
**Place SoT:** `C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl` (не в git).  
**Якорь:** `GOALS.md` + week wrap `SESSION-2026-08-14f-week-wrap.md`.

Системы core/hub/explore/identity/social/Resonant W1–W4 — **code-PASS**. «Готово» по продукту = закрытые KR ниже + freeze out-of-scope.

---

## Фаза 1 — Shippable demo (сейчас)

**Цель:** invitee за ~10 мин: Haven → квест/лут → лов/бой → (опционально) Sanctum Ками — без MCP-костылей и без P0 UI-глюков.

| # | Критерий | Статус |
|---|----------|--------|
| 1.1 | Resonant в Dex element set (`ParentIds` / PrimaryElement), не `"Unknown"` | **PASS** 2026-08-15 — `SpiritResonance.GetDexBonus` |
| 1.2 | Sanctum Status не sticky после успешного Open | **PASS** 2026-08-15 — `KamiSanctumController` |
| 1.3 | Этот документ + NEXT/CHANGELOG/GOALS | **PASS** |
| 1.4 | Hands e2e ≥90% n≥10 (F/1/2/E) | **буфер** (процесс; не блокер кода фазы 1) |
| 1.5 | Hands-цикл Ками без ForceCatch | **буфер** (MCP PASS в `SESSION-2026-08-14g`) |

**Out of scope фазы 1:** PvP feature work, online AI mesh, Haven décor, новые зоны, DataStore `UpdateAsync`.

**Done when:** 1.1–1.3 закрыты в SoT + git; 1.4–1.5 отмечены как буфер в `NEXT-SESSION.md`.

---

## Фаза 2 — Soft-launch

| Gate | Смысл |
|------|--------|
| Publish + API Services | Реальный DataStore round-trip (не только in-memory Studio) |
| `DataStoreManager` | Session lock / `UpdateAsync` (gap 2026-08-11) |
| Hub funnel | Лёгкая инструментация Mika/Exit (не опросники) |
| Fair combat | `quality_gate.py` зелёный на mirrors |

Старт только после фазы 1 кода + хотя бы одного hands smoke.

---

## Фаза 3 — Scale (после P0 KR1–KR2 руками)

| Gate | Смысл |
|------|--------|
| P0 KR1–KR2 | E1 ≥90% n≥10; 0 open P0 |
| PvP | Под `FAIR-COMBAT.md`, не pay-to-win |
| AI mesh | Unfreeze только явно |
| Seasons / guilds | После стабильного soft-launch |

---

## Roblox practices (каждый фикс)

- Server authority: бой/Dex/Care на сервере; клиент — UI/input/VFX  
- Remotes: `typeof` / `tonumber` / range / proximity  
- Resonant Id 9xxx: fallback через roster / `ParentIds`, не только `SpiritDatabase.Get`  
- `task.*`, Parent-last `Instance.new`, `--!strict` где уместно  
- После ModuleScript Source: cache-bust; **Ctrl+S** SoT; mirror → commit (не `.rbxl`)

---

## Ссылки

- План недели (закрыт): `WEEK-PLAN-2026-08-26.md`  
- Hands MCP: `SESSION-2026-08-14g-kami-hands-loop.md`  
- Автоматизация: `AUTOMATION.md` / `python scripts/quality_gate.py`
