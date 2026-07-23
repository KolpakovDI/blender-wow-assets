"""Blender-side helper: export selected (or all mesh) objects to FBX for Roblox upload.

Run inside Blender (GUI Scripting, or Blender MCP execute_blender_code):

  exec(open(r"C:\\Users\\Asus\\Projects\\blender-wow-assets\\scripts\\blender_export_for_roblox.py").read())

Or set EXPORT_PATH / EXPORT_SELECTED via environment before running Blender.
"""

from __future__ import annotations

import os
from pathlib import Path

import bpy


def export_fbx(out_path: Path, selected_only: bool = True) -> str:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    # Apply scale-friendly defaults for Roblox-ish import
    bpy.ops.export_scene.fbx(
        filepath=str(out_path),
        use_selection=selected_only,
        apply_scale_options="FBX_SCALE_ALL",
        bake_space_transform=True,
        object_types={"MESH", "ARMATURE", "EMPTY"},
        use_mesh_modifiers=True,
        add_leaf_bones=False,
        path_mode="COPY",
        embed_textures=True,
        axis_forward="-Z",
        axis_up="Y",
    )
    return str(out_path.resolve())


def main() -> None:
    default_dir = Path(__file__).resolve().parent.parent / "docs" / "realm-of-spirits" / "assets" / "meshes"
    out = Path(os.environ.get("REALM_MESH_EXPORT", str(default_dir / "export.fbx")))
    selected_only = os.environ.get("REALM_MESH_SELECTED", "1") not in {"0", "false", "False"}
    if selected_only and not bpy.context.selected_objects:
        # fall back to all mesh objects
        for obj in bpy.context.scene.objects:
            if obj.type == "MESH":
                obj.select_set(True)
        selected_only = True
    path = export_fbx(out, selected_only=selected_only)
    print(f"REALM_EXPORT_OK {path}")


if __name__ == "__main__":
    main()
