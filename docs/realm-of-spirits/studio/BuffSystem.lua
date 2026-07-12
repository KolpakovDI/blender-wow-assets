-- BuffSystem - temporary player buffs (GDD v2.0 manga corner)
local BuffSystem = {}

BuffSystem.Definitions = {
	MangaDamage = {
		Name = "Сила манги",
		Multiplier = 1.15,
		Duration = 30 * 60,
	},
}

local function ensureBuffs(playerData)
	if not playerData.Buffs then
		playerData.Buffs = {}
	end
	return playerData.Buffs
end

function BuffSystem.CleanupExpired(playerData)
	local buffs = ensureBuffs(playerData)
	local now = os.time()
	for id, entry in pairs(buffs) do
		if not entry.ExpiresAt or entry.ExpiresAt <= now then
			buffs[id] = nil
		end
	end
end

function BuffSystem.ApplyBuff(playerData, buffId)
	local def = BuffSystem.Definitions[buffId]
	if not def then
		return false, "Unknown buff"
	end
	BuffSystem.CleanupExpired(playerData)
	local buffs = ensureBuffs(playerData)
	buffs[buffId] = {
		ExpiresAt = os.time() + def.Duration,
		Multiplier = def.Multiplier,
	}
	return true, def.Name .. " active for " .. math.floor(def.Duration / 60) .. " min"
end

function BuffSystem.GetActiveBuffs(playerData)
	BuffSystem.CleanupExpired(playerData)
	local active = {}
	local now = os.time()
	for id, entry in pairs(ensureBuffs(playerData)) do
		table.insert(active, {
			Id = id,
			Name = BuffSystem.Definitions[id] and BuffSystem.Definitions[id].Name or id,
			SecondsLeft = math.max(0, entry.ExpiresAt - now),
			Multiplier = entry.Multiplier,
		})
	end
	return active
end

function BuffSystem.GetDamageMultiplier(playerData)
	BuffSystem.CleanupExpired(playerData)
	local mult = 1
	local buffs = ensureBuffs(playerData)
	local manga = buffs.MangaDamage
	if manga and manga.ExpiresAt and manga.ExpiresAt > os.time() then
		mult = mult * (manga.Multiplier or 1)
	end
	return mult
end

function BuffSystem.HasBuff(playerData, buffId)
	BuffSystem.CleanupExpired(playerData)
	local entry = ensureBuffs(playerData)[buffId]
	return entry ~= nil and entry.ExpiresAt and entry.ExpiresAt > os.time()
end

return BuffSystem
