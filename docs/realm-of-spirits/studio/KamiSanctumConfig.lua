-- KamiSanctumConfig — synthesis 2–6 + disintegrate weights
local KamiSanctumConfig = {}

KamiSanctumConfig.MinPlayerLevel = 10
KamiSanctumConfig.MinDonors = 2
KamiSanctumConfig.MaxDonors = 6
KamiSanctumConfig.DailySynthCap = 3
KamiSanctumConfig.DailyDisintegrateCap = 8
KamiSanctumConfig.BaseCopperCost = 80
KamiSanctumConfig.UniqueSkillIds = {300, 301, 302, 303, 304, 305, 306, 307}
KamiSanctumConfig.StarItemIds = {310, 311, 312} -- I, II, III
KamiSanctumConfig.StarTier = {[310] = 1, [311] = 2, [312] = 3}
KamiSanctumConfig.ShardId = 301
KamiSanctumConfig.EssenceByPrimary = {
	Fire = 320,
	Earth = 321,
	Wind = 322,
	Water = 323,
}
KamiSanctumConfig.PrimaryCycle = {"Fire", "Earth", "Wind", "Water"}

KamiSanctumConfig.NamePrefixes = {
	Fire = {"Искра", "Жар", "Пепел"},
	Earth = {"Камень", "Корни", "Глыба"},
	Wind = {"Порыв", "Перо", "Шёпот"},
	Water = {"Капля", "Прилив", "Зыбь"},
}

function KamiSanctumConfig.CopperCost(nDonors)
	nDonors = math.clamp(tonumber(nDonors) or 2, 2, 6)
	return math.floor(KamiSanctumConfig.BaseCopperCost * (1 + 0.35 * (nDonors - 2)))
end

function KamiSanctumConfig.DayKey()
	return os.date("!%Y-%m-%d")
end

function KamiSanctumConfig.EnsureDaily(data)
	if type(data.ResonanceDaily) ~= "table" then
		data.ResonanceDaily = {}
	end
	local d = data.ResonanceDaily
	local key = KamiSanctumConfig.DayKey()
	if d.Date ~= key then
		d.Date = key
		d.Care = false
		d.Temper = false
		d.SanctumSynth = 0
		d.SanctumDisintegrate = 0
	end
	d.SanctumSynth = math.max(0, math.floor(tonumber(d.SanctumSynth) or 0))
	d.SanctumDisintegrate = math.max(0, math.floor(tonumber(d.SanctumDisintegrate) or 0))
	return d
end

function KamiSanctumConfig.SpiritQuality(spirit, SpiritDatabase)
	if type(spirit) ~= "table" then
		return 0.2
	end
	local lv = math.clamp((tonumber(spirit.Level) or 1) / 50, 0, 2)
	local bond = math.clamp((tonumber(spirit.Bond) or 0) / 10, 0, 1)
	local tp = spirit.TemperPoints or {}
	local temper = ((tonumber(tp.Attack) or 0) + (tonumber(tp.Defense) or 0) + (tonumber(tp.Spirit) or 0)) / 60
	temper = math.clamp(temper, 0, 1.5)
	local evo = (tonumber(spirit.Id) or 0) >= 101 and (tonumber(spirit.Id) or 0) < 9000
	local resonant = spirit.Kind == "Resonant"
	local evoBonus = evo and 0.25 or 0
	local resBonus = resonant and 0.15 or 0
	return math.clamp(0.35 * lv + 0.25 * bond + 0.2 * temper + evoBonus + resBonus, 0.1, 1.5)
end

function KamiSanctumConfig.StarScore(components)
	-- components: { [itemId] = qty }
	local score = 0
	local ref = 6 -- 2× tier3
	if type(components) ~= "table" then
		return 0
	end
	for id, qty in pairs(components) do
		local tier = KamiSanctumConfig.StarTier[tonumber(id)]
		if tier then
			score += tier * math.max(0, math.floor(tonumber(qty) or 0))
		end
	end
	return math.clamp(score / ref, 0, 1.5)
end

function KamiSanctumConfig.CountShard(components)
	if type(components) ~= "table" then
		return 0
	end
	return math.max(0, math.floor(tonumber(components[KamiSanctumConfig.ShardId]) or components[tostring(KamiSanctumConfig.ShardId)] or 0))
end

function KamiSanctumConfig.CycleDistance(a, b)
	local idx = {}
	for i, p in ipairs(KamiSanctumConfig.PrimaryCycle) do
		idx[p] = i
	end
	local ia, ib = idx[a], idx[b]
	if not ia or not ib then
		return 2
	end
	local d = math.abs(ia - ib)
	return math.min(d, 4 - d)
end

function KamiSanctumConfig.DiversityFactor(primaries)
	if #primaries == 0 then
		return 1
	end
	local uniq = {}
	for _, p in ipairs(primaries) do
		uniq[p] = true
	end
	local n = 0
	for _ in pairs(uniq) do
		n += 1
	end
	if n == 1 then
		return 1.18 -- stable same Primary
	elseif n == 2 then
		return 1.05
	elseif n >= 3 then
		return 0.95 + 0.08 * math.min(n, 4) -- glass Unique lean via weights, slight power bump
	end
	return 1
end

function KamiSanctumConfig.ResonancePower(playerLevel, qualityScore, starScore, nDonors, diversity)
	local base = 0.50 + 0.022 * math.max(1, tonumber(playerLevel) or 1)
	local spiritQ = tonumber(qualityScore) or 0.3
	local stars = 0.85 + 0.40 * (tonumber(starScore) or 0)
	local count = 0.90 + 0.08 * (math.clamp(tonumber(nDonors) or 2, 2, 6) - 2)
	local compat = tonumber(diversity) or 1
	return math.clamp(base * (0.55 + spiritQ) * stars * count * compat, 0.6, 2.8)
end

--- Disassemble loot table: returns list of {Id, Quantity, Weight}
function KamiSanctumConfig.DisassembleLootWeights(spirit, SpiritDatabase)
	local q = KamiSanctumConfig.SpiritQuality(spirit, SpiritDatabase)
	local id = tonumber(spirit.Id) or 0
	local evolved = id >= 101 and id < 9000
	local resonant = spirit.Kind == "Resonant"
	local primary = "Earth"
	if SpiritDatabase then
		primary = SpiritDatabase.GetPrimary(spirit) or "Earth"
	end
	if spirit.HybridPrimary then
		primary = spirit.HybridPrimary
	end
	local essenceId = KamiSanctumConfig.EssenceByPrimary[primary]

	local rows = {
		{Id = 301, Quantity = 1, Weight = 40},
		{Id = 301, Quantity = 2, Weight = 15 + math.floor(q * 20)},
		{Id = 310, Quantity = 1, Weight = 8 + math.floor(q * 25)},
	}
	if q > 0.55 then
		table.insert(rows, {Id = 311, Quantity = 1, Weight = 5 + math.floor(q * 15)})
	end
	if evolved and essenceId then
		table.insert(rows, {Id = essenceId, Quantity = 1, Weight = 20})
		table.insert(rows, {Id = 311, Quantity = 1, Weight = 12})
	end
	if resonant then
		table.insert(rows, {Id = 312, Quantity = 1, Weight = 10})
		table.insert(rows, {Id = 301, Quantity = 3, Weight = 25})
	end
	return rows
end

return KamiSanctumConfig
