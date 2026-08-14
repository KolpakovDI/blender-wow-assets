# WoW-Style UI Assets

## Source

- **Sheet:** `assets/ui-asset-sheet.png` (repo root via Cursor assets)
- **Slicer:** `docs/realm-of-spirits/assets/slice_ui_sheet.py`

Run:

```bash
pip install Pillow
python docs/realm-of-spirits/assets/slice_ui_sheet.py
```

Output: `docs/realm-of-spirits/assets/ui/` (64×64 skill frames, bars, minimap ring, etc.)

## Roblox upload

1. Upload each PNG to [Creator Dashboard](https://create.roblox.com/) → Decals/Images
2. Copy asset IDs into `ReplicatedStorage.RealmOfSpirits.WoWUITheme.Assets`:

```lua
WoWUITheme.Assets = {
    SkillFrame = "rbxassetid://...",
    UnitPortrait = "rbxassetid://...",
    BarHP = "rbxassetid://...",
    BarMP = "rbxassetid://...",
    MinimapRing = "rbxassetid://...",
}
```

Empty strings = procedural gold/wood/stone fallback (current default).

## Studio integration

- **Module:** `ReplicatedStorage.RealmOfSpirits.WoWUITheme`
- **Consumer:** `StarterGui.UIController` — unit frame, HP/MP gems, minimap ring, action bar, panels
