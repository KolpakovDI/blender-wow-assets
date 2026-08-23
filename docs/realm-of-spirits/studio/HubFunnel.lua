-- HubFunnel: lightweight P0 hub funnel counters (server-authoritative)
-- Steps: Spawn → Mika (quest UI) → Prep (manga/gacha/wardrobe) → ExitCombat
-- Analytics attribute HubFunnelStep: Spawn | MikaOpen | PrepShop | ExitTouch
-- Persisted on playerData.HubFunnel; resets by UTC DayKey.

local HubFunnel = {}

local STEPS = {
	Spawn = true,
	Mika = true,
	Prep = true,
	ExitCombat = true,
}

local STEP_ATTR = {
	Spawn = "Spawn",
	Mika = "MikaOpen",
	Prep = "PrepShop",
	ExitCombat = "ExitTouch",
}

local function utcDayKey()
	return os.date("!%Y-%m-%d")
end

local function setStepAttribute(player, step)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return
	end
	local label = STEP_ATTR[step] or step
	pcall(function()
		player:SetAttribute("HubFunnelStep", label)
	end)
end

function HubFunnel.Ensure(playerData)
	if type(playerData) ~= "table" then
		return nil
	end
	local today = utcDayKey()
	local hub = playerData.HubFunnel
	if type(hub) ~= "table" or hub.DayKey ~= today then
		playerData.HubFunnel = {
			DayKey = today,
			Spawn = false,
			Mika = false,
			Prep = false,
			ExitCombat = false,
			FirstSpawnAt = nil,
			FirstMikaAt = nil,
			FirstPrepAt = nil,
			FirstExitCombatAt = nil,
		}
	else
		if hub.Spawn == nil then
			hub.Spawn = false
		end
	end
	return playerData.HubFunnel
end

function HubFunnel.Mark(playerData, step)
	if type(step) ~= "string" or not STEPS[step] then
		return false
	end
	local hub = HubFunnel.Ensure(playerData)
	if not hub or hub[step] == true then
		return false
	end
	hub[step] = true
	local now = os.time()
	if step == "Spawn" then
		hub.FirstSpawnAt = now
	elseif step == "Mika" then
		hub.FirstMikaAt = now
	elseif step == "Prep" then
		hub.FirstPrepAt = now
	elseif step == "ExitCombat" then
		hub.FirstExitCombatAt = now
	end
	return true
end

function HubFunnel.GetSnapshot(playerData)
	local hub = HubFunnel.Ensure(playerData)
	if not hub then
		return {
			DayKey = utcDayKey(),
			Spawn = false,
			Mika = false,
			Prep = false,
			ExitCombat = false,
			Complete = false,
		}
	end
	return {
		DayKey = hub.DayKey,
		Spawn = hub.Spawn == true,
		Mika = hub.Mika == true,
		Prep = hub.Prep == true,
		ExitCombat = hub.ExitCombat == true,
		Complete = hub.Mika == true and hub.Prep == true and hub.ExitCombat == true,
		FirstSpawnAt = hub.FirstSpawnAt,
		FirstMikaAt = hub.FirstMikaAt,
		FirstPrepAt = hub.FirstPrepAt,
		FirstExitCombatAt = hub.FirstExitCombatAt,
	}
end

function HubFunnel.MarkPlayer(player, step)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false
	end
	local getter = rawget(_G, "GetPlayerData")
	if type(getter) ~= "function" then
		return false
	end
	local data = getter(player)
	if type(data) ~= "table" then
		return false
	end
	local changed = HubFunnel.Mark(data, step)
	if changed then
		-- Attribute = furthest completed step (never regress Spawn after Mika/Prep/Exit)
		local hub = HubFunnel.Ensure(data)
		local furthest = "Spawn"
		if hub and hub.ExitCombat == true then
			furthest = "ExitCombat"
		elseif hub and hub.Prep == true then
			furthest = "Prep"
		elseif hub and hub.Mika == true then
			furthest = "Mika"
		elseif hub and hub.Spawn == true then
			furthest = "Spawn"
		end
		local attr = STEP_ATTR[furthest] or furthest
		setStepAttribute(player, furthest)
		print(string.format("[HubFunnel] %s -> %s (%s)", player.Name, step, attr))
	end
	return changed
end

return HubFunnel
