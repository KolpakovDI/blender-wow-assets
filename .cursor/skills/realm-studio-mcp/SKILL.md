---
name: realm-studio-mcp
description: >-
  Roblox Studio MCP workflows for Realm of Spirits: connect, read/edit
  ModuleScripts, bust require cache, rebuild OtakuHaven/BattleArena, export
  sources to docs. Use when editing the place via user-Roblox_Studio, when
  MCP is error/disconnected, or when syncing Studio Lua to docs/realm-of-spirits/studio.
---

# Realm Studio MCP

## Connect

1. `GetMcpTools` / `get_studio_state` on `user-Roblox_Studio`.
2. If `serverStatus: error` → user must Restart MCP + ensure Studio open with place.
3. Expected place title: `RealmOfSpirits second.rbxl`.

## Key paths

| Area | Path |
|------|------|
| Config / catalogs | `ReplicatedStorage.RealmOfSpirits.*` |
| Server systems | `ServerScriptService.RealmOfSpirits.*` |
| Client UI | `StarterGui.UIController`, `StarterPlayer.StarterPlayerScripts.*` |
| World | `workspace.OtakuHaven`, `Akihabara`, `BattleArena`, `QuestMaster` |

## Edit pattern

1. Prefer `multi_edit` / `script_read` on ModuleScripts.
2. After Source change, **bust cache** before runtime require:

```lua
local function replaceModule(parent, name)
  local old = parent:FindFirstChild(name)
  local src = old.Source
  old:Destroy()
  local m = Instance.new("ModuleScript")
  m.Name = name
  m.Source = src
  m.Parent = parent
  return m
end
```

3. Rebuilders: `OtakuHavenBuilder.Build()`, `BattleArenaBuilder.Build()`.
4. Reposition Mika from `ZoneConfig.QuestMasterPosition` after Haven rebuild.

## Export to git docs

- Large scripts: `script_read` → agent-tools file → strip `LINE→` prefixes → write `docs/realm-of-spirits/studio/<Name>.lua`.
- Always update `CHANGELOG.md` `[Unreleased]` per project rule.

## Play / VirtualInput

- Player hotkeys stay **F** (бой) / **1–3** (навыки) / **E** (лут, ловля).
- Studio MCP `user_keyboard_input` **не шлёт** F / top-row 1–3 (CoreGUI bind). Это лимит инструмента, не баг игры.
- **MCP e2e recipe:** бой = **V** (тихий алиас F в `ClientController`); навыки = **KeypadOne / KeypadTwo / KeypadThree** (уже в `UIController`).
- Запасной путь: клик HUD (`BattleButton`, `Attack1–3`) или remotes.
- Руками в Play по-прежнему F / 1 / 2.

## Do not

- Invent exploits / attack remote places.
- Leave unsaved place — tell user **Ctrl+S**.
- Remap primary player F/1/2 away just for MCP; use V + Keypad aliases instead.
