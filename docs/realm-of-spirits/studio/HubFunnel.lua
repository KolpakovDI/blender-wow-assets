-- HubFunnel: lightweight P0 hub funnel counters (server-authoritative)
-- Steps: Spawn → Mika (quest UI) → Prep (manga/gacha/wardrobe) → ExitCombat
-- Analytics attribute HubFunnelStep: Spawn | MikaOpen | PrepShop | ExitTouch | Complete
-- Also: HubFunnelComplete (bool), HubFunnelDayKey, HubFunnelPrep (bool) for KR3 prep ≥50% log sampling
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
	Complete = "Complete",
}

local function utcDayKey()
	return os.date("!%Y-%m-%d")
end

local function isDayComplete(hub)
	return hub
		and hub.Mika == true
		and hub.Prep == true
		and hub.ExitCombat == true
end

local function resolveFurthestStep(hub)
	if not hub then
		return "Spawn"
	end
	if isDayComplete(hub) then
		return "Complete"
	end
	if hub.ExitCombat == true then
		return "ExitCombat"
	end
	if hub.Prep == true then
		return "Prep"
	end
	if hub.Mika == true then
		return "Mika"
	end
	if hub.Spawn == true then
		return "Spawn"
	end
	return "Spawn"
end

local function syncPlayerAttributes(player, snapshot)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return
	end
	local hub = snapshot
	local furthest = resolveFurthestStep(hub)
	local label = STEP_ATTR[furthest] or furthest
	pcall(function()
		player:SetAttribute("HubFunnelStep", label)
		player:SetAttribute("HubFunnelComplete", snapshot.Complete == true)
		player:SetAttribute("HubFunnelDayKey", snapshot.DayKey or "")
		player:SetAttribute("HubFunnelPrep", snapshot.Prep == true)
	end)
end

local function formatFlags(snapshot)
	return string.format(
		"Spawn=%s Mika=%s Prep=%s Exit=%s",
		tostring(snapshot.Spawn),
		tostring(snapshot.Mika),
		tostring(snapshot.Prep),
		tostring(snapshot.ExitCombat)
	)
end

local function formatStepLog(player, step, snapshot)
	if snapshot.Complete then
		return string.format(
			"[HubFunnel] %s -> Complete (Complete) DayKey=%s Mika+Prep+Exit",
			player.Name,
			snapshot.DayKey or "?"
		)
	end
	local attrLabel = STEP_ATTR[step] or step
	local flags = formatFlags(snapshot)
	if step == "Prep" then
		return string.format(
			"[HubFunnel] %s -> Prep (PrepShop) DayKey=%s %s [KR3 prep step]",
			player.Name,
			snapshot.DayKey or "?",
			flags
		)
	end
	return string.format(
		"[HubFunnel] %s -> %s (%s) DayKey=%s %s",
		player.Name,
		step,
		attrLabel,
		snapshot.DayKey or "?",
		flags
	)
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
	local complete = isDayComplete(hub)
	return {
		DayKey = hub.DayKey,
		Spawn = hub.Spawn == true,
		Mika = hub.Mika == true,
		Prep = hub.Prep == true,
		ExitCombat = hub.ExitCombat == true,
		Complete = complete,
		FirstSpawnAt = hub.FirstSpawnAt,
		FirstMikaAt = hub.FirstMikaAt,
		FirstPrepAt = hub.FirstPrepAt,
		FirstExitCombatAt = hub.FirstExitCombatAt,
	}
end

function HubFunnel.SyncPlayer(player, playerData)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return nil
	end
	local data = playerData
	if type(data) ~= "table" then
		local getter = rawget(_G, "GetPlayerData")
		if type(getter) ~= "function" then
			return nil
		end
		data = getter(player)
	end
	if type(data) ~= "table" then
		return nil
	end
	local snapshot = HubFunnel.GetSnapshot(data)
	syncPlayerAttributes(player, snapshot)
	return snapshot
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
	local snapshot = HubFunnel.GetSnapshot(data)
	syncPlayerAttributes(player, snapshot)
	if changed then
		print(formatStepLog(player, step, snapshot))
	end
	return changed
end

return HubFunnel
