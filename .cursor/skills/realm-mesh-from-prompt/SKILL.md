---
name: realm-mesh-from-prompt
description: >-
  Blender-first pipeline: generate mesh in Blender (Hyper3D Rodin via Blender MCP
  or sculpt), export FBX, upload to Roblox Open Cloud as Model, insert into the
  open Realm of Spirits place via Studio MCP. Use when the user wants mesh from
  prompt in Blender auto-uploaded to Roblox without manual Import 3D, or asks for
  Blender→Roblox automation.
---

# Realm Mesh From Prompt (Blender → Roblox auto)

**Requirement from project owner:** mesh is made **in Blender**, then loaded into Roblox **without manual Import 3D clicks**.

Studio-only `generate_mesh` is a **fallback** if Blender MCP is offline — tell the user and prefer Blender when available.

## One-time setup (human, once)

1. **Blender** with project addon `blender-addon/addon.py` (BlenderMCP) enabled; start MCP server in sidebar.
2. Enable Cursor MCP server `blender` (see `.cursor/mcp.json`).
3. **Hyper3D Rodin** key in BlenderMCP (or Free Trial) if generating from text.
4. **Roblox Open Cloud API key** (Creator Dashboard → Open Cloud):
   - Permission: **assets** Read + Write
   - Env vars (user machine / Cursor secrets — never commit):
     - `ROBLOX_OPEN_CLOUD_API_KEY`
     - `ROBLOX_USER_ID` (or `ROBLOX_GROUP_ID`)
5. Studio open with place + MCP `user-Roblox_Studio`.

## Automated pipeline (agent)

```
Prompt
  → Blender MCP: Hyper3D Rodin (create_rodin_job → poll → import GLB)
  → Blender: export FBX (scripts/blender_export_for_roblox.py)
  → python scripts/roblox_upload_model.py <fbx> --name "..."
  → Studio MCP: insert_asset(assetId, assetType=Model)
  → Ctrl+S reminder
```

### Step detail

1. Confirm Blender MCP tools available (`GetMcpTools` pattern blender / rodin). If server missing: ask user to start BlenderMCP.
2. Generate in Blender via Rodin tools (`create_rodin_job`, `poll_rodin_job_status`, import). If Rodin unavailable, use `execute_blender_code` / geometry — still must end as mesh in Blender scene.
3. Export:
   - Prefer running export helper so file lands at  
     `docs/realm-of-spirits/assets/meshes/<slug>.fbx`  
   - Via Blender MCP execute: load/run `scripts/blender_export_for_roblox.py` or equivalent `bpy.ops.export_scene.fbx`.
4. Upload (Shell):
   ```bash
   python scripts/roblox_upload_model.py docs/realm-of-spirits/assets/meshes/<slug>.fbx --name "<Name>"
   ```
   Parse JSON `assetId`.
5. Insert into place:
   ```
   insert_asset({ assetId, assetName, assetType: "Model", parentPath: "Workspace" })
   ```
   Optional: parent under `Workspace.OtakuHaven.Decor` or rename to `SpiritTemplateN`.
6. Remind **Ctrl+S**. Do not commit `.rbxl` or API keys. Large FBX may stay local / gitignored.

## Env checklist

| Variable | Purpose |
|----------|---------|
| `ROBLOX_OPEN_CLOUD_API_KEY` | Upload Model |
| `ROBLOX_USER_ID` or `ROBLOX_GROUP_ID` | Creator |
| `REALM_MESH_EXPORT` | Optional override export path |

## Limits / honesty

- Open Cloud uploads **Model** from `.fbx` / `.glb` (not raw Mesh-only type for custom FBX).
- Moderation may delay `insert_asset` until approved — poll / retry if insert fails.
- Fully “zero human forever” still needs API keys + Blender running once configured.
- Do not use Studio `generate_mesh` when user insisted on Blender, unless Blender path is blocked.

## Fallback (disclose)

If Blender MCP is down and user accepts: `user-Roblox_Studio.generate_mesh` inserts directly into place (not Blender).
