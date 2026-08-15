# SESSION 2026-08-15g — Month W4 soft-launch wrap

**План:** `MONTH-PLAN-2026-08-15.md`  
**Окно месяца:** 2026-08-15 → 2026-09-14 (закрыто досрочно по M1–M4)  
**Place SoT:** `C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl`  
**Published:** PlaceId=`130832500076229` GameId=`10713581476`

---

## M4 статусы

| # | Exit | Статус |
|---|------|--------|
| **M4.1** | Таблица M1–M3 + вердикт soft-launch | **PASS** — ниже |
| **M4.2** | E1 ≥90% n≥10 **или** CONDITIONAL + план | **CONDITIONAL** + план |
| **M4.3** | Фраза на октябрь + gate фазы 3 | **PASS** — ниже |

---

## Таблица месяца (M1–M3)

| # | Критерий | Статус | SESSION |
|---|----------|--------|---------|
| **M1** | Publish + DS round-trip + quality_gate + smoke | **PASS** | `15d-month-w1-ops` |
| **M2** | E1 sample ≥5 + HubFunnel день + friction backlog | **PASS CONDITIONAL** | `15e-month-w2` |
| **M3** | Friction close + Kami без ForceCatch + agency 2+ | **PASS** | `15f-month-w3` |
| **M4** | Wrap + E1 вердикт + октябрь + gate ф.3 | **PASS** | этот файл |

### Soft-launch вердикт

**Фаза 2 soft-launch backend — PASS (ops + code).**  
Publish + live DataStore rejoin, HubFunnel день Complete, Kami-цикл без ForceCatch, agency 2 skills, quality_gate зелёный.

**Продуктовый hands E1 (глаза/WASD/F/1/2/E, n≥10, ≥90%) — ещё не закрыт.** Метрика остаётся **CONDITIONAL**; soft-launch код/ops не блокируется.

---

## M4.2 — E1 честный вердикт + план

| Что есть | Что нет |
|----------|---------|
| MCP live-like: 5× бой (W2), Kami цикл (W3), HubFunnel Complete | ≥10 проходов **руками** F/1/2/E |
| Place published, DS persist | Invitee-only blind run без MCP |

**План к KR1 (не раздувать scope):**

1. 2–3 сессии ведущего: полный цикл Haven→квест→лут/лов→бой→Ками **только** F/E/1/2 (без TP/BF).  
2. Лог в `SESSION-2026-09-*-e1-hands.md`: PASS/FAIL на шаг, n и %.  
3. Цель октября: **n≥10**, completion ≥90% **или** явный список оставшихся P0 (не бесконечный polish).

---

## M4.3 — Фраза на октябрь + gate фазы 3

### Одна фраза (октябрь)

**Закрыть честный hands E1 (n≥10, ≥90%) и обнулить open P0 из лога; фазу 3 (PvP / AI mesh) не трогать, пока KR1–KR2 не зелёные глазами.**

### Gate фазы 3 (checklist — код не стартовать)

| Gate | Готов? | Комментарий |
|------|--------|-------------|
| KR1 E1 ≥90% n≥10 руками | **нет** | CONDITIONAL; план выше |
| KR2 0 open P0 из hands | **частично** | Wardrobe Prep closed; новых P0 из глаз нет |
| Fair combat / quality_gate | **да** | зеркала зелёные |
| Soft-launch DS + publish | **да** | PlaceId≠0, rejoin PASS |
| PvP / AI mesh / guilds | **не стартовать** | до KR1–KR2 |

---

## Что не делали (scope hold)

- Online AI mesh  
- Новая PvP / guilds  
- Haven décor / ProfileService rewrite  

---

## Ctrl+S

Если в Studio ещё висит несохранённый `OtakuHavenService` (MarkHubPrep) — **Ctrl+S**.
