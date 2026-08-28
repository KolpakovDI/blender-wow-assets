# Owner setup — Paid AI stack (Anim/Char Art)

> **Когда:** перед **«A3 Tripo»** (minimal paid) · UGCraft/Leonardo — по мере срезов  
> **Блок:** [`BLOCK-ANIM-CHAR-ART-2026-08-28.md`](BLOCK-ANIM-CHAR-ART-2026-08-28.md) · research [`RESEARCH-AI-ANIM-ART-2026-08-28.md`](RESEARCH-AI-ANIM-ART-2026-08-28.md)  
> **Старт без подписок:** команда **«A1»** (free Roblox animation IDs)

---

## Quick checklist

### Phase 0 — перед «A1» (ничего платить не нужно)

- [ ] Studio place открыт · **Ctrl+S** habit
- [ ] Команда агенту: **«A1»** — combat restore на verified free IDs

### Phase 1 — minimal paid (~$12/mo, перед A3)

- [ ] Аккаунт [Tripo3D](https://www.tripo3d.ai/pricing) → **Professional** (annual ~$12/mo)
- [ ] Подтвердить **commercial use** в Terms (нужно до publish игры)
- [ ] Open Cloud API key (если ещё нет) — см. § Open Cloud ниже
- [ ] Сообщить агенту: **«A3 Tripo»** — первый hero Id=1

### Phase 2 — optional (после A1 PASS или на A4/A5)

- [ ] **UGCraft Creator** [$9/mo](https://www.ugcraft.ai/creation/roblox-animation-maker) — только если free IDs слабые → **«A1 UGCraft»**
- [ ] **Leonardo Essential** [$12/mo](https://leonardo.ai/pricing) — только если нет local ComfyUI → A4 portraits
- [ ] **Rokoko Basic** [$10/mo](https://www.rokoko.com/pricing) — отложить до A5 NPC emote

---

## Accounts to create

| Priority | Service | URL | Monthly | Needed for |
|----------|---------|-----|---------|------------|
| **P1** | Tripo3D Professional | https://www.tripo3d.ai/pricing | ~$12 | A3, A6 meshes |
| P2 | UGCraft Creator | https://www.ugcraft.ai | $9 | A1 custom R15 clips (optional) |
| P3 | Leonardo.AI Essential | https://leonardo.ai/pricing | $12 | A4 private portraits (optional) |
| P4 | Rokoko Basic | https://www.rokoko.com/pricing | $10 | A5 mocap (optional) |

**Не покупать:** Rodin API Business ($120/mo) · Meshy Pro ($20) · дублирующие mesh-инструменты.

---

## API keys & secrets (owner hands)

| Secret | Where to get | Where agent uses it | In git? |
|--------|--------------|---------------------|---------|
| **Roblox Open Cloud API key** | [create.roblox.com](https://create.roblox.com/dashboard/credentials) → API Keys → scope `asset:read`, `asset:write` | `scripts/roblox_upload_model.py` · env `ROBLOX_OPEN_CLOUD_API_KEY` | **Never** |
| **Roblox user ID** | Creator Dashboard profile | Upload script `--creator-id` or env | OK in local `.env` only |
| **Leonardo API key** (if paid A4) | Leonardo → API Access (Essential+) | Future batch script / manual export | **Never** |
| Tripo / UGCraft / Rokoko | Web login only on current tiers | Semi-manual download → agent continues pipeline | N/A |

### Open Cloud one-time setup

1. Creator Dashboard → **Credentials** → Create API Key
2. Scopes: **Assets** (read + write) for Model upload
3. Copy key once → store in local env (not repo):

```powershell
# PowerShell — user profile or session
$env:ROBLOX_OPEN_CLOUD_API_KEY = "your-key-here"
```

4. Smoke: `python scripts/roblox_upload_model.py --help` (agent runs with your env)

### Animation publish (any custom clip)

1. Studio → Animation Editor → import FBX/`.rbxm`
2. **Publish to Roblox** → copy `rbxassetid`
3. Paste ID to agent or confirm in chat — agent wires `CombatAnimResolver` / NPC emote

---

## Owner steps per slice (paid workflow)

| Slice | Owner once | Agent automates after |
|-------|------------|----------------------|
| **A1** | (optional) UGCraft login · publish custom Animation | Resolver restore · `VerifyAllClips` smoke |
| **A2** | Subjective feel OK | KIND_CONFIG · VFX · battle smoke |
| **A3** | Tripo subscribe · approve mesh look | Prompt → download FBX → Blender → Open Cloud → `insert_asset` |
| **A4** | Leonardo subscribe OR ComfyUI local · upload Decals | Wire `IconLookupId` · Sanctum camera |
| **A5** | Rokoko capture (if paid) · publish emote | Billboard / Animation wiring |
| **A6** | Avatar equip test | RealmBlade mesh · R6/R15 smoke |

---

## Agent automation map (paid tools)

| Tool | ✅ Agent | ⚠️ Semi-manual | ❌ Owner only |
|------|----------|----------------|---------------|
| **Tripo Pro** | Blender decimate · FBX export · `roblox_upload_model.py` · Studio `insert_asset` · spawn smoke | Web generate + download FBX | Billing · account · final mesh approval |
| **UGCraft** | Studio import · resolver wiring · smoke | Web prompt + download `.rbxm` | Login · publish Animation ID |
| **Leonardo** | Icon wiring in Luau · batch post-process if PNGs provided | Web/API generate | Account · API key · Decal upload |
| **Rokoko** | Blender retarget → FBX → Studio import | Export from Rokoko app | Subscription · video capture |
| **Open Cloud** | Upload script · `insert_asset` | Moderation wait/retry | API key creation |
| **Free IDs (A1)** | `search_asset` · `VerifyClip` · full A1 pipeline | — | — |

---

## Monthly cost summary

| Bundle | Tools | $/mo |
|--------|-------|------|
| **Minimal (selected)** | Tripo Pro only | **~$12** |
| Growth | Tripo + UGCraft + Leonardo | **~$33** |
| Full paid | Growth + Rokoko Basic | **~$43** |

---

## First commands after setup

| Step | Owner | Agent command |
|------|-------|---------------|
| 1 | — | **«A1»** |
| 2 | Tripo Pro + Open Cloud ready | **«A3 Tripo»** |
| 3 | (optional) UGCraft if A1 weak | **«A1 UGCraft»** |

---

*Created: 2026-08-28 · Owner checklist · No secrets in repo*
