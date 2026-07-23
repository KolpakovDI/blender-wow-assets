"""Upload a Blender-exported FBX/GLB/glTF to Roblox as a Model via Open Cloud Assets API.

Env (required):
  ROBLOX_OPEN_CLOUD_API_KEY  — Creator Dashboard → Open Cloud → API Key (asset Read+Write)
  ROBLOX_USER_ID             — numeric user id (profile URL), OR
  ROBLOX_GROUP_ID            — numeric group id (alternative creator)

Usage:
  python scripts/roblox_upload_model.py path/to/model.fbx --name "FireCatSpirit"
  python scripts/roblox_upload_model.py path/to/model.glb --name "Prop" --wait 180

Prints JSON: {"ok": true, "assetId": "...", "operationId": "..."}
Exit 0 on success.
"""

from __future__ import annotations

import argparse
import json
import mimetypes
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path


API_BASE = "https://apis.roblox.com/assets/v1"


def content_type_for(path: Path) -> str:
    suffix = path.suffix.lower()
    mapping = {
        ".fbx": "model/fbx",
        ".glb": "model/gltf-binary",
        ".gltf": "model/gltf+json",
        ".rbxm": "model/x-rbxm",
        ".rbxmx": "model/x-rbxm",
    }
    if suffix in mapping:
        return mapping[suffix]
    guessed, _ = mimetypes.guess_type(str(path))
    return guessed or "application/octet-stream"


def multipart_body(fields: dict[str, tuple[str | None, bytes, str | None]]) -> tuple[bytes, str]:
    boundary = f"----CursorRealmBoundary{int(time.time() * 1000)}"
    lines: list[bytes] = []
    for name, (filename, data, ctype) in fields.items():
        lines.append(f"--{boundary}\r\n".encode())
        if filename:
            disp = f'Content-Disposition: form-data; name="{name}"; filename="{filename}"\r\n'
            lines.append(disp.encode())
            lines.append(f"Content-Type: {ctype or 'application/octet-stream'}\r\n\r\n".encode())
        else:
            lines.append(f'Content-Disposition: form-data; name="{name}"\r\n\r\n'.encode())
        lines.append(data)
        lines.append(b"\r\n")
    lines.append(f"--{boundary}--\r\n".encode())
    return b"".join(lines), boundary


def http_json(method: str, url: str, api_key: str, body: bytes | None = None, content_type: str | None = None) -> dict:
    headers = {"x-api-key": api_key}
    if content_type:
        headers["Content-Type"] = content_type
    req = urllib.request.Request(url, data=body, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            raw = resp.read().decode("utf-8", errors="replace")
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as exc:
        err_body = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {exc.code}: {err_body}") from exc


def create_asset(api_key: str, file_path: Path, display_name: str, description: str, creator: dict) -> str:
    request_obj = {
        "assetType": "Model",
        "displayName": display_name[:50],
        "description": description[:1000],
        "creationContext": {"creator": creator},
    }
    file_bytes = file_path.read_bytes()
    body, boundary = multipart_body(
        {
            "request": (None, json.dumps(request_obj).encode("utf-8"), None),
            "fileContent": (file_path.name, file_bytes, content_type_for(file_path)),
        }
    )
    result = http_json(
        "POST",
        f"{API_BASE}/assets",
        api_key,
        body=body,
        content_type=f"multipart/form-data; boundary={boundary}",
    )
    path = result.get("path") or ""
    # path like operations/{id}
    if not path:
        raise RuntimeError(f"Unexpected create response: {result}")
    return path.rsplit("/", 1)[-1]


def poll_operation(api_key: str, operation_id: str, timeout_s: float) -> dict:
    deadline = time.time() + timeout_s
    url = f"{API_BASE}/operations/{operation_id}"
    last: dict = {}
    while time.time() < deadline:
        last = http_json("GET", url, api_key)
        if last.get("done"):
            if "error" in last:
                raise RuntimeError(f"Upload failed: {last['error']}")
            return last
        time.sleep(2.0)
    raise TimeoutError(f"Operation {operation_id} not done after {timeout_s}s; last={last}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Upload FBX/GLB Model to Roblox Open Cloud")
    parser.add_argument("file", type=Path, help="Path to .fbx / .glb / .gltf")
    parser.add_argument("--name", required=True, help="Display name for the asset")
    parser.add_argument("--description", default="Uploaded from Blender via Cursor Realm pipeline")
    parser.add_argument("--wait", type=float, default=300.0, help="Seconds to poll operation")
    args = parser.parse_args()

    api_key = os.environ.get("ROBLOX_OPEN_CLOUD_API_KEY", "").strip()
    if not api_key:
        print(json.dumps({"ok": False, "error": "Set ROBLOX_OPEN_CLOUD_API_KEY"}))
        return 1

    user_id = os.environ.get("ROBLOX_USER_ID", "").strip()
    group_id = os.environ.get("ROBLOX_GROUP_ID", "").strip()
    if user_id:
        creator = {"userId": user_id}
    elif group_id:
        creator = {"groupId": group_id}
    else:
        print(json.dumps({"ok": False, "error": "Set ROBLOX_USER_ID or ROBLOX_GROUP_ID"}))
        return 1

    path = args.file
    if not path.is_file():
        print(json.dumps({"ok": False, "error": f"File not found: {path}"}))
        return 1
    if path.suffix.lower() not in {".fbx", ".glb", ".gltf", ".rbxm", ".rbxmx"}:
        print(json.dumps({"ok": False, "error": f"Unsupported extension: {path.suffix}"}))
        return 1

    try:
        operation_id = create_asset(api_key, path, args.name, args.description, creator)
        op = poll_operation(api_key, operation_id, args.wait)
        response = op.get("response") or {}
        asset_id = str(response.get("assetId") or "")
        if not asset_id:
            # sometimes path assets/{id}
            asset_path = response.get("path") or ""
            asset_id = asset_path.rsplit("/", 1)[-1] if asset_path else ""
        if not asset_id:
            print(json.dumps({"ok": False, "error": "No assetId in operation response", "operation": op}))
            return 1
        print(
            json.dumps(
                {
                    "ok": True,
                    "assetId": asset_id,
                    "operationId": operation_id,
                    "moderation": (response.get("moderationResult") or {}).get("moderationState"),
                    "rbxassetid": f"rbxassetid://{asset_id}",
                }
            )
        )
        return 0
    except Exception as exc:  # noqa: BLE001 — CLI surface
        print(json.dumps({"ok": False, "error": str(exc)}))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
