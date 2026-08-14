-- HubFunnel: lightweight P0 hub funnel counters (server-authoritative)
-- Steps: Mika (quest UI) → Prep (manga/gacha/wardrobe) → ExitCombat
-- Persisted on playerData.HubFunnel; resets by UTC DayKey.

local HubFunnel = {}

local STEPS = {
	Mika = true,
	Prep = true,
	ExitCombat = true,
}

local function utcDayKey()
	return os.date("!%Y-%m-%d")
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
			Mika = false,
			Prep = false,
			ExitCombat = false,
			FirstMikaAt = nil,
			FirstPrepAt = nil,
			FirstExitCombatAt = nil,
		}
	end
	return playerData.HubFunnel
end

-- Returns true only on first mark of the day for that step.
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
	if step == "Mika" then
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
			Mika = false,
			Prep = false,
			ExitCombat = false,
			Complete = false,
		}
	end
	return {
		DayKey = hub.DayKey,
		Mika = hub.Mika == true,
		Prep = hub.Prep == true,
		ExitCombat = hub.ExitCombat == true,
		Complete = hub.Mika == true and hub.Prep == true and hub.ExitCombat == true,
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
		print(string.format("[HubFunnel] %s -> %s", player.Name, step))
	end
	return changed
end

return HubFunnel
