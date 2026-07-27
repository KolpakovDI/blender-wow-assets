# Apply Haven atmosphere décor

Studio MCP сейчас не отдаёт edit-tools (только `mcp_auth`) — правки в git-mirror, apply вручную.

## Шаги

1. Открыть place: `C:\Mimo\RealmOfSpirits\RealmOfSpirits second.rbxl`
2. Скопировать Source из `docs/realm-of-spirits/studio/OtakuHavenBuilder.lua`  
   → в Studio `ServerScriptService.RealmOfSpirits.OtakuHavenBuilder`
3. Command Bar (Edit):

```lua
local SSS = game:GetService("ServerScriptService")
local folder = SSS.RealmOfSpirits
local mod = folder.OtakuHavenBuilder
local src = mod.Source
mod:Destroy()
local fresh = Instance.new("ModuleScript")
fresh.Name = "OtakuHavenBuilder"
fresh.Source = src
fresh.Parent = folder
require(fresh).Build()
print("[OtakuHaven] Atmosphere décor rebuilt")
```

4. **Ctrl+S**

## Что добавлено (`Decor.AtmosphereDecor`)

- Ковровая дорожка Genkan → касса  
- Потолочная гирлянда (neon + PointLight)  
- Бумажные фонари у кассы  
- Баннеры CATCH / BATTLE / EVOLVE / COLLECT  
- Растения у входа/выхода  
- Потолочные SpotLight  
- Уличные фонари + parking silhouettes  
- `Lighting.OtakuHavenMood` + `OtakuHavenBloom`
