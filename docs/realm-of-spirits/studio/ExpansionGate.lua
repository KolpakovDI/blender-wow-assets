-- ExpansionGate: hard stops for Q3/Q4 features until owner unlocks
-- Default: all false. Unlock only via SSS.RealmOfSpirits attributes OR explicit Enable* calls after hands E1.

local ExpansionGate = {}

-- Compile-time defaults (Q1/Q2 focus)
ExpansionGate.AllowNewPvPFeatures = false -- keep existing duel; block power rewards / rated
ExpansionGate.AllowGuilds = false -- GuildSystem CreateOrJoin blocked until true
ExpansionGate.AllowProfileService = false -- ProfileServiceAdapter never loads saves
ExpansionGate.AllowAiMeshOnline = false -- SpiritMeshGenerationService must check this

local function sssFolder()
	return game:GetService("ServerScriptService"):FindFirstChild("RealmOfSpirits")
end

local function attrBool(name, fallback)
	local folder = sssFolder()
	if not folder then
		return fallback
	end
	local v = folder:GetAttribute(name)
	if v == nil then
		return fallback
	end
	return v == true
end

function ExpansionGate.RefreshFromAttributes()
	ExpansionGate.AllowNewPvPFeatures = attrBool("AllowNewPvPFeatures", ExpansionGate.AllowNewPvPFeatures)
	ExpansionGate.AllowGuilds = attrBool("AllowGuilds", ExpansionGate.AllowGuilds)
	ExpansionGate.AllowProfileService = attrBool("AllowProfileService", ExpansionGate.AllowProfileService)
	ExpansionGate.AllowAiMeshOnline = attrBool("AllowAiMeshOnline", ExpansionGate.AllowAiMeshOnline)
end

function ExpansionGate.GetSnapshot()
	ExpansionGate.RefreshFromAttributes()
	return {
		AllowNewPvPFeatures = ExpansionGate.AllowNewPvPFeatures,
		AllowGuilds = ExpansionGate.AllowGuilds,
		AllowProfileService = ExpansionGate.AllowProfileService,
		AllowAiMeshOnline = ExpansionGate.AllowAiMeshOnline,
		Note = "Unlock only after hands E1 ≥90% n≥10 or owner skip — YEAR-PLAN-2026-10",
	}
end

function ExpansionGate.AssertProfileServiceBlocked()
	ExpansionGate.RefreshFromAttributes()
	if ExpansionGate.AllowProfileService then
		return true
	end
	return false
end

function ExpansionGate.AssertAiMeshBlocked()
	ExpansionGate.RefreshFromAttributes()
	return ExpansionGate.AllowAiMeshOnline == true
end

function ExpansionGate.AssertGuildsAllowed()
	ExpansionGate.RefreshFromAttributes()
	return ExpansionGate.AllowGuilds == true
end

-- Studio helper: print gate status
function ExpansionGate.PrintStatus()
	local s = ExpansionGate.GetSnapshot()
	print(string.format(
		"[ExpansionGate] PvPExtra=%s Guilds=%s ProfileService=%s AiMesh=%s",
		tostring(s.AllowNewPvPFeatures),
		tostring(s.AllowGuilds),
		tostring(s.AllowProfileService),
		tostring(s.AllowAiMeshOnline)
	))
end

return ExpansionGate
