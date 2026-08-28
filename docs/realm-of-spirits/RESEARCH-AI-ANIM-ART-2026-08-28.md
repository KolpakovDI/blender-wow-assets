# AI Animation & Art Research — Realm of Spirits (2026-08-28)

> **Цель:** найти **самый дешёвый жизнеспособный** AI-assisted workflow для блока A1–A6  
> **Контекст:** DEV-only, R15/R6, офлайн-меши в `SpiritTemplates`, Rodin `API_INSUFFICIENT_FUNDS`  
> **Источники:** веб-поиск август 2026, официальные pricing/help страницы, Roblox Creator Hub  
> **Owner decision (2026-08-28):** **paid tier** — владелец выбрал платный стек вместо Tier 0-only.  
> **Active plan:** minimal **~$12/mo** (Tripo Pro) + free A1 IDs; growth **~$33/mo** optional. См. [`BLOCK-ANIM-CHAR-ART-2026-08-28.md`](BLOCK-ANIM-CHAR-ART-2026-08-28.md) § Paid stack · setup [`OWNER-SETUP-PAID-AI.md`](OWNER-SETUP-PAID-AI.md).

---

## Executive summary

| Tier | Стоимость | Рекомендация для RoS |
|------|-----------|----------------------|
| **Tier 0** | **$0/мес** | **A1:** verified free Roblox IDs (522635514/522638767) — AI не нужен · **A3:** Hunyuan3D Global (20 gen/день) или Studio `generate_mesh` · **A4:** ComfyUI local SD/Flux · **A5:** Mixamo emotes + Rokoko Text-to-Motion |
| **Tier 1** | **<$20/мес** | **A3:** Tripo Professional ~$12/мес (annual) — commercial mesh + FBX · **A1 custom:** UGCraft Creator $9/мес (R15-native AI anim) · **A4:** Leonardo Essential $12/мес (private portraits) |
| **Tier 2** | **$20–50/мес** | Meshy Pro $20 · Cascadeur Indie $8–19 (FBX export) · DeepMotion Starter $9 · Rodin Creator $20 (без API) |

**Главный вывод:** для RoS **не нужно платить за AI на A1** — verified free IDs уже есть. Максимальный ROI при $0: **Hunyuan3D / Studio mesh** (A3) + **ComfyUI** (A4) + **Mixamo** (backup/custom clips).

---

## Сравнительная таблица инструментов

| Инструмент | Use case | Цена (2025–2026) | Roblox fit | Agent automatable? |
|------------|----------|------------------|------------|-------------------|
| **Mixamo** | Библиотека mocap + auto-rig, FBX | **$0** (Adobe account) | ⚠️ Generic skeleton → Blender fix → R15 import | Частично (ручной download) |
| **Verified Roblox IDs** | Combat slash/lunge R15/R6 | **$0** | ✅ Native R15, `VerifyClip` | ✅ `search_asset` + wiring |
| **UGCraft Animation Maker** | Text → R15 `.rbxm`/FBX | Free 20 credits; Creator **$9/mo** | ✅ R15 CurveAnimation-ready | Частично (web) |
| **DeepMotion Animate 3D** | Video → mocap FBX/GLB/BVH | Freemium **60 credits/mo** (non-commercial); Starter **$9/mo** | ⚠️ Retarget to R15 in Blender | Частично |
| **DeepMotion SayMotion** | Text → motion FBX | Free **25 credits/mo** (non-commercial); from **$15/mo** | ⚠️ Retarget | Частично |
| **Rokoko Vision/Create** | Video/text mocap | Free **30s/mo** video + **unlimited text-to-motion**; Basic **$10/mo** | ⚠️ FBX → Blender → R15 | Частично |
| **Plask** | Browser video mocap | Free **15s/day**; Standard **$18/mo** annual | ⚠️ FBX retarget | Частично |
| **Cascadeur** | Physics keyframe + AI AutoPosing | Free (`.casc` only); Indie **$8/mo** annual (FBX) | ⚠️ Manual R15 pipeline | ❌ Desktop GUI |
| **Kinetix** | In-game UGC emotes SDK | **€0.15/emote** (B2B) | ❌ SDK, не Luau pipeline | ❌ |
| **Hunyuan3D Global** | Text/image → 3D GLB/OBJ | **20 gen/day free**; API **$0.02/credit** (~$0.50/model) | ✅ GLB/FBX → Blender cleanup | ✅ Blender MCP + web |
| **Tripo3D** | Text/image → 3D + Smart Low Poly | Free **300 credits/mo** (non-commercial); Pro **~$12/mo** annual | ✅ FBX/OBJ/GLB export | Частично (web/API) |
| **Meshy AI** | Text/image → textured mesh | Free **100 credits/mo**; Pro **$20/mo** | ✅ FBX/GLB — **но free = no download** | Частично |
| **Hyper3D Rodin** | Text/image → quad mesh | Free **10 credits** (pay-per-download); Creator **$20/mo**; API **Business $120/mo** | ✅ FBX via Blender MCP | ✅ MCP (сейчас **blocked: funds**) |
| **Roblox Studio `generate_mesh`** | Text → mesh in place | **$0** (встроено) | ✅ Native, `MaxTriangles` param | ✅ Studio MCP |
| **ComfyUI + SD/Flux** | UI portraits, icons | **$0** (local GPU) | ✅ PNG → Decal/Image upload | Частично (local scripts) |
| **Leonardo.AI** | Game portraits, character ref | Free **150 tokens/day** (public); Essential **$12/mo** | ✅ PNG → rbxassetid | Частично (API on paid) |
| **Midjourney** | High-quality concept art | from **$10/mo**, no free tier | ✅ Decals only | ❌ Discord/web |
| **Stable Diffusion WebUI** | Local portraits | **$0** | ✅ | Частично |

---

## Roblox constraints (критично для pipeline)

### Mesh

| Лимит | Значение | Источник |
|-------|----------|----------|
| MeshPart max triangles | **20 000** | [Creator Hub specifications](https://create.roblox.com/docs/art/modeling/specifications) |
| Rigid accessory | **4 000** | accessories specs |
| Spirit prop (world mesh) | Target **2 000–8 000** для mobile headroom | best practice |
| Formats | **GLB** (preferred), FBX, OBJ | Import 3D |
| Geometry | Watertight, volume > 0, quads preferred | specs |
| Rig (if animated mesh) | Max **4 bone influences**/vertex; root at origin | export settings |

**Manual cleanup после AI:** decimate in Blender, fix non-manifold, merge doubles, scale to studs, pivot at feet/center, split if >20k tris, bake textures to ≤1024 (icons 256–512).

### Animation

| Аспект | Детали |
|--------|--------|
| Import paths | Animation Clip Editor (FBX/glTF) или Import 3D → AnimSaves |
| Hard keyframe limit | **Нет официального cap**, но большие FBX → broken interpolation |
| R15 retarget | Adaptive animation помогает, но Mixamo/AI mocap требуют Blender fix (delete root location keys) |
| Known bugs | Scale -1 in mirrored bones breaks lerp; bone name = part name → wrong rotations |
| Verified free combat | `522635514`, `522638767`, `129967390` — уже в `COMBAT-ANIMATIONS.md` |

### 2D / UI

| Аспект | Детали |
|--------|--------|
| Upload | Creator Dashboard → Development Items → **Images/Decals** |
| Resolution | До **4096×4096** (4K texture streaming, beta/production 2026) |
| Battle icons | 64px readable → export **256×256** PNG with padding |
| Decal in UI | `ImageLabel.Image = "rbxassetid://..."` |

---

## Рекомендуемый стек по tier

### Tier 0 — $0 (рекомендуется для DEV)

| Срез | Инструмент | Почему |
|------|------------|--------|
| **A1** Combat body | Verified Roblox IDs | AI не нужен; native R15; уже documented |
| **A2** Combat feel | Agent tuning only | Resolver timing, lunge, VFX — no AI cost |
| **A3** Spirit mesh | **Hunyuan3D Global** (20/day) → Blender → Open Cloud | Бесплатно, GLB export; Rodin blocked |
| **A3 fallback** | Studio `generate_mesh` MCP | Zero setup, уже в skill fallback |
| **A4** UI portraits | **ComfyUI local** (SDXL/Flux) | $0 marginal cost, private, batch icons |
| **A5** NPC emote | **Mixamo** emotes + **Rokoko** text-to-motion (unlimited free) | Free FBX |
| **A6** Avatar/Blade | Blender manual + Studio mesh | No recurring cost |

**Ежемесячная стоимость: $0**

### Tier 1 — <$20/mo (если нужен commercial + quality)

| Срез | Инструмент | Цена |
|------|------------|------|
| **A1** custom R15 clips | UGCraft Creator | **$9/mo** |
| **A3** commercial meshes | Tripo Professional (annual) | **~$12/mo** |
| **A4** private portraits | Leonardo Essential | **$12/mo** |
| **A5** more mocap | Rokoko Basic | **$10/mo** |

**Pick one paid mesh tool** — не нужны Rodin + Meshy + Tripo одновременно.

### Tier 2 — moderate ($20–50/mo)

- Meshy Pro **$20/mo** — если нужны unlimited downloads + API
- Cascadeur Indie **$8–19/mo** — custom combat keyframes with physics
- DeepMotion Starter **$9/mo** — video mocap volume
- Rodin Creator **$20/mo** — если пополнить credits (API всё равно $120)

---

## Маппинг A1–A6 → инструменты

| Срез | Задача | Tier 0 | Tier 1 upgrade |
|------|--------|--------|----------------|
| **A1** | Restore combat body anims | Free Roblox IDs | UGCraft text→R15 |
| **A2** | DG feel + VFX | Agent code tuning | Cascadeur edit exported FBX |
| **A3** | 8 hero spirit meshes | Hunyuan3D / Studio mesh | Tripo Pro commercial |
| **A4** | Sanctum/battle portraits | ComfyUI SD/Flux | Leonardo Essential |
| **A5** | Mika 3 emote states | Mixamo + Billboard sprites from SD | Rokoko Basic mocap |
| **A6** | RealmBlade + R15/R6 | Blender + Studio mesh | Rodin top-up credits |

---

## Step-by-step: A1 (Combat animation) — Tier 0

> **Важно:** для RoS A1 **AI не обязателен**. Verified IDs уже PASS smoke.

### Path A — Recommended ($0, no AI)

1. Agent восстанавливает `CombatAnimations/` (6× Animation instances)
2. Восстанавливает `CombatAnimResolver` с `ShouldPlayBodyAnim → true`
3. IDs: `522635514` (slash), `522638767` (lunge), `129967390` (R6)
4. Play smoke: `VerifyAllClips` 6/6 Length>0, skills 1/119/31/11/2
5. Ctrl+S place

### Path B — Custom clips via Mixamo ($0, semi-manual)

1. [mixamo.com](https://www.mixamo.com) → Adobe login (free)
2. Search: "sword slash", "lunge", "cast spell" → preview
3. Download FBX **Without Skin**, 30fps
4. **Blender fix (обязательно):**
   - Import FBX
   - Select armature → delete **Location** keyframes on root/Hips
   - Export FBX (Bake Animation ON, Simplify 0.0)
5. Studio → Animation Editor → Import FBX → preview on R15 rig
6. Publish Animation → owner hands → получить rbxassetid
7. Agent wires ID into `CombatAnimResolver.FALLBACK_IDS`

### Path C — UGCraft R15-native ($0 trial / $9/mo)

1. [ugcraft.ai/creation/roblox-animation-maker](https://www.ugcraft.ai/creation/roblox-animation-maker)
2. Prompt: "R15 sword slash forward, 0.5s, Action priority"
3. Download `.rbxm` or FBX (~90 sec)
4. Import directly to Studio (no Blender retarget)
5. Publish → wire ID

---

## Step-by-step: A3 (Spirit mesh) — Tier 0

> Pipeline из `realm-mesh-from-prompt` skill, Rodin заменён на Hunyuan3D.

### Path A — Hunyuan3D Global web ($0)

1. Открыть [3d.hunyuanglobal.com](https://3d.hunyuanglobal.com) (20 free gen/day)
2. Prompt brief (из BLOCK-ANIM doc):
   - Id 1: "cute fire cat spirit, round silhouette, game creature, low poly"
   - Id 7: "stone golem tank spirit, chunky silhouette, fantasy pet"
3. Generate → download **GLB/OBJ**
4. Blender MCP `import_generated_asset` или File → Import GLB
5. **Cleanup in Blender:**
   - Decimate to ~3–5k tris
   - Apply scale, origin to center/bottom
   - Fix normals, remove doubles
6. Export FBX: `scripts/blender_export_for_roblox.py`
7. Shell: `python scripts/roblox_upload_model.py docs/realm-of-spirits/assets/meshes/spirit-1.fbx --name "SpiritTemplate1"`
8. Studio MCP: `insert_asset` → parent `ReplicatedStorage.SpiritTemplates` → rename `SpiritTemplate1`
9. Scale/collision pass in Studio
10. Smoke: `SpiritMeshResolve.CloneResolvedModel({Id=1})` → `IsMeshPlaceholder=false`
11. Ctrl+S

### Path B — Blender MCP Hunyuan3D ($0 local/API)

1. Blender MCP: `generate_hunyuan3d_model` → `poll_hunyuan_job_status` → `import_generated_asset_hunyuan`
2. Далее шаги 5–11 как выше

### Path C — Studio generate_mesh fallback ($0, disclose)

1. Studio MCP: `generate_mesh` с prompt + `MaxTriangles: 5000`
2. Parent under `SpiritTemplates`, manual scale
3. **Минус:** не Blender-first; качество ниже; нет FBX mirror в git
4. Disclose owner в SESSION note

### Path D — Tripo free (DEV prototyping only)

- 300 credits/mo, **non-commercial** — OK для DEV-only PlaceId=0
- Export FBX → тот же Blender cleanup → Open Cloud pipeline
- Upgrade to Pro ($12/mo annual) перед publish game

---

## Step-by-step: A4 (UI portraits) — Tier 0

1. Install ComfyUI + SDXL or Flux Schnell (local, free)
2. Prompt template per spirit:
   ```
   game UI portrait, [fire cat spirit], centered bust, clean background,
   cel-shaded, bold silhouette, 256x256, icon style, no text
   ```
3. Batch generate 32 variants → pick 8 heroes + battle icons
4. Post-process: crop, contrast boost for 64px readability
5. Upload PNG → Creator Dashboard → Images → copy rbxassetid
6. Agent wires `IconLookupId` / Sanctum Viewport textures
7. **Leonardo free alternative:** 150 tokens/day, but images are **public**

---

## Риски и owner hands

| Риск | Mitigation | Owner? |
|------|------------|--------|
| Rodin `API_INSUFFICIENT_FUNDS` | Hunyuan3D / Tripo / Studio mesh | Owner funds Rodin if preferred |
| Mixamo maintenance mode | Have UGCraft/Rokoko backup; verified IDs primary | — |
| Meshy free = no download | Use Tripo or Hunyuan instead | — |
| AI mesh >20k tris | Blender decimate before upload | Agent |
| Non-commercial free tiers | DEV-only OK; upgrade before monetization | Owner decision |
| Animation publish to CDN | Creator Hub Animation upload | **Owner hands** |
| Open Cloud API key | One-time env setup | **Owner hands** |
| Visual sign-off per spirit | Iterate prompts | **Owner hands** |
| DG proprietary feel | Free Linked Sword set sufficient for MVP | Owner optional license |

### Что агент может автоматизировать

- ✅ Studio MCP: resolver wiring, smoke, mesh insert
- ✅ Blender MCP: Hunyuan3D gen, export, decimate scripts
- ✅ Open Cloud upload script
- ✅ ComfyUI batch if installed locally
- ⚠️ Mixamo/Tripo/Leonardo web: semi-manual download
- ❌ Animation publish to Roblox CDN
- ❌ Marketplace purchases
- ❌ Subjective art approval

---

## Почему НЕ платить за Rodin сейчас

| Фactor | Rodin | Hunyuan3D / Tripo |
|--------|-------|-------------------|
| Current status | API blocked (insufficient funds) | Working free tiers |
| API cost | Business **$120/mo** | Hunyuan API ~$0.50/model |
| Free tier | 10 credits one-time | 20/day or 300/mo |
| Blender MCP | Integrated but broken | Hunyuan MCP available |
| Commercial | Creator $20/mo + credits | Tripo Pro $12/mo |

**Verdict:** пополнить Rodin credits имеет смысл только если нужны quad-mesh + HD textures для specific hero; для 8 spirit silhouettes Tier 0 достаточен.

---

## Pricing snapshot (verified sources, Aug 2026)

| Service | Free tier | Cheapest paid |
|---------|-----------|---------------|
| Mixamo | Unlimited downloads | $0 |
| UGCraft | 20 credits | $9/mo Creator |
| DeepMotion Animate3D | 60 credits/mo | $9/mo Starter |
| SayMotion | 25 credits/mo | $15/mo |
| Rokoko | 30s video/mo + unlimited text-to-motion | $10/mo Basic |
| Plask | 15s/day | $18/mo annual Standard |
| Cascadeur | Full toolset, .casc export only | $8/mo annual Indie |
| Hunyuan3D Global | 20 gen/day | API $0.02/credit |
| Tripo3D | 300 credits/mo (non-commercial) | ~$12/mo annual Pro |
| Meshy | 100 credits/mo, **no download** | $20/mo Pro |
| Rodin/Hyper3D | 10 credits signup | $20/mo Creator; API $120/mo Business |
| Leonardo | 150 tokens/day | $12/mo Essential |
| ComfyUI/SD local | Unlimited (GPU cost) | $0 software |

---

## Recommended action for next session

> **Updated 2026-08-28 (owner: paid tier):** Tier 0 paths остаются valid fallback; primary workflow — paid minimal stack.

1. **A1:** Start with verified free IDs — **zero subscription day 1, fastest PASS**
2. **Owner:** Complete [`OWNER-SETUP-PAID-AI.md`](OWNER-SETUP-PAID-AI.md) before **A3 Tripo**
3. **A3:** First hero mesh via **Tripo Pro** (Id=1 Fire Cat) → Blender cleanup → Open Cloud → `insert_asset`
4. **A4:** ComfyUI local first; upgrade to Leonardo Essential only if no GPU / need private gens
5. **UGCraft / Rokoko:** add only when A1 feel or A5 mocap gap appears

---

## Related docs

- [`BLOCK-ANIM-CHAR-ART-2026-08-28.md`](BLOCK-ANIM-CHAR-ART-2026-08-28.md)
- [`OWNER-SETUP-PAID-AI.md`](OWNER-SETUP-PAID-AI.md)
- [`COMBAT-ANIMATIONS.md`](COMBAT-ANIMATIONS.md)
- [`SPIRIT-AI-MESH.md`](SPIRIT-AI-MESH.md)
- [`.cursor/skills/realm-mesh-from-prompt/SKILL.md`](../../.cursor/skills/realm-mesh-from-prompt/SKILL.md)

---

*Research date: 2026-08-28 · Web sources*
