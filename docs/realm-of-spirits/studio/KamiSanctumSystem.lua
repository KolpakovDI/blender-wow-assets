-- KamiSanctumSystem — server logic for synthesize / disintegrate
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local realm = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local KamiSanctumConfig = require(realm:WaitForChild("KamiSanctumConfig"))
local SpiritDatabase = require(realm:WaitForChild("SpiritDatabase"))
local SkillCatalog = require(realm:WaitForChild("SkillCatalog"))
local ItemCatalog = require(realm:WaitForChild("ItemCatalog"))

local KamiSanctumSystem = {}

local function invQty(data, itemId)
	itemId = tonumber(itemId)
	if not data or type(data.Inventory) ~= "table" then
		return 0
	end
	for _, inv in ipairs(data.Inventory) do
		if tonumber(inv.Id) == itemId then
			return tonumber(inv.Quantity) or 0
		end
	end
	return 0
end

local function takeItem(data, itemId, qty)
	itemId = tonumber(itemId)
	qty = math.floor(tonumber(qty) or 0)
	if qty <= 0 then
		return true
	end
	for i, inv in ipairs(data.Inventory or {}) do
		if tonumber(inv.Id) == itemId then
			local have = tonumber(inv.Quantity) or 0
			if have < qty then
				return false
			end
			inv.Quantity = have - qty
			if inv.Quantity <= 0 then
				table.remove(data.Inventory, i)
			end
			return true
		end
	end
	return false
end

local function giveItem(data, itemId, qty)
	itemId = tonumber(itemId)
	qty = math.floor(tonumber(qty) or 0)
	if qty <= 0 then
		return
	end
	data.Inventory = data.Inventory or {}
	for _, inv in ipairs(data.Inventory) do
		if tonumber(inv.Id) == itemId then
			inv.Quantity = (tonumber(inv.Quantity) or 0) + qty
			return
		end
	end
	table.insert(data.Inventory, {Id = itemId, Quantity = qty})
end

local function normalizeComponents(raw)
	local out = {}
	if type(raw) ~= "table" then
		return out
	end
	for k, v in pairs(raw) do
		local id = tonumber(k) or tonumber(v and v.Id)
		local qty = tonumber(v)
		if type(v) == "table" then
			qty = tonumber(v.Quantity) or tonumber(v.Qty)
		end
		if id and qty and qty > 0 then
			out[id] = (out[id] or 0) + math.floor(qty)
		end
	end
	return out
end

local function collectDonors(data, indices)
	local spirits = data.Spirits or {}
	local donors = {}
	local seen = {}
	for _, idx in ipairs(indices) do
		idx = math.floor(tonumber(idx) or 0)
		if idx < 1 or idx > #spirits then
			return nil, "bad_index"
		end
		if seen[idx] then
			return nil, "dup_index"
		end
		seen[idx] = true
		table.insert(donors, {Index = idx, Spirit = spirits[idx]})
	end
	return donors, nil
end

local function weightedPick(rng, entries)
	local total = 0
	for _, e in ipairs(entries) do
		total += math.max(0, tonumber(e.Weight) or 0)
	end
	if total <= 0 then
		return nil
	end
	local r = rng:NextNumber() * total
	local acc = 0
	for _, e in ipairs(entries) do
		acc += math.max(0, tonumber(e.Weight) or 0)
		if r <= acc then
			return e
		end
	end
	return entries[#entries]
end

local function skillPoolFromDonors(donors)
	local pool = {}
	local seen = {}
	for _, d in ipairs(donors) do
		local sp = d.Spirit
		local ids = sp.SkillIds
		if type(ids) ~= "table" then
			ids = {}
			local cat = SpiritDatabase.Get(sp.Id)
			if cat and type(cat.SkillIds) == "table" then
				ids = cat.SkillIds
			elseif SkillCatalog.SpiritSkills[sp.Id] then
				ids = SkillCatalog.SpiritSkills[sp.Id]
			end
		end
		local q = KamiSanctumConfig.SpiritQuality(sp, SpiritDatabase)
		for _, sid in ipairs(ids) do
			sid = tonumber(sid)
			if sid and not seen[sid] then
				local def = SkillCatalog.Get(sid)
				if def and def.Type ~= "Passive" then
					seen[sid] = true
					table.insert(pool, {Id = sid, Weight = 10 + q * 40, Source = "parent"})
				end
			elseif sid and seen[sid] then
				for _, e in ipairs(pool) do
					if e.Id == sid then
						e.Weight += 5 + q * 10
						break
					end
				end
			end
		end
	end
	return pool
end

function KamiSanctumSystem.PreviewSynthesize(data, spiritIndices, components)
	if not data then
		return {Ok = false, Error = "no_data"}
	end
	local level = tonumber(data.Level) or 1
	if level < KamiSanctumConfig.MinPlayerLevel then
		return {Ok = false, Error = "level", Need = KamiSanctumConfig.MinPlayerLevel}
	end
	local indices = {}
	for _, i in ipairs(spiritIndices or {}) do
		table.insert(indices, math.floor(tonumber(i) or 0))
	end
	local n = #indices
	if n < KamiSanctumConfig.MinDonors or n > KamiSanctumConfig.MaxDonors then
		return {Ok = false, Error = "count", Min = 2, Max = 6}
	end
	local donors, err = collectDonors(data, indices)
	if not donors then
		return {Ok = false, Error = err}
	end
	local daily = KamiSanctumConfig.EnsureDaily(data)
	if daily.SanctumSynth >= KamiSanctumConfig.DailySynthCap then
		return {Ok = false, Error = "daily_cap", Cap = KamiSanctumConfig.DailySynthCap}
	end
	local comps = normalizeComponents(components)
	local starScore = KamiSanctumConfig.StarScore(comps)
	local shardNeed = 1
	if invQty(data, KamiSanctumConfig.ShardId) + KamiSanctumConfig.CountShard(comps) < shardNeed and KamiSanctumConfig.CountShard(comps) < 1 then
		-- allow synth if player has at least 1 shard in inventory (will consume)
		if invQty(data, KamiSanctumConfig.ShardId) < 1 then
			return {Ok = false, Error = "need_shard", ItemId = 301}
		end
	end
	local copper = KamiSanctumConfig.CopperCost(n)
	if (tonumber(data.CopperCoins) or 0) < copper then
		return {Ok = false, Error = "copper", Need = copper}
	end

	local qualities = {}
	local primaries = {}
	local qSum = 0
	for i, d in ipairs(donors) do
		local q = KamiSanctumConfig.SpiritQuality(d.Spirit, SpiritDatabase)
		qualities[i] = q
		qSum += q
		local p = d.Spirit.HybridPrimary or SpiritDatabase.GetPrimary(d.Spirit)
		table.insert(primaries, p)
	end
	local qualityScore = qSum / #donors
	local diversity = KamiSanctumConfig.DiversityFactor(primaries)
	local power = KamiSanctumConfig.ResonancePower(level, qualityScore, starScore, n, diversity)
	local countBonus = (n - 2) / 4
	local weightUnique = math.clamp(0.08 + 0.12 * starScore + 0.05 * countBonus + 0.04 * qualityScore, 0.05, 0.55)

	-- Core primary lean
	local coreP = primaries[1] or "Earth"
	local namePool = KamiSanctumConfig.NamePrefixes[coreP] or {"Ками"}

	local core = donors[1] and donors[1].Spirit
	return {
		Ok = true,
		DonorCount = n,
		CopperCost = copper,
		StarScore = starScore,
		QualityScore = qualityScore,
		ResonancePower = power,
		CorePrimary = coreP,
		Primaries = primaries,
		UniqueChance = weightUnique,
		TierHint = weightUnique > 0.35 and "Epic+" or (weightUnique > 0.2 and "Rare" or "Common"),
		NameHint = "Ками-" .. namePool[1],
		CoreParentId = core and tonumber(core.Id) or nil,
		CoreParentName = core and tostring(core.Name or "ядро"),
		DailyLeft = KamiSanctumConfig.DailySynthCap - daily.SanctumSynth,
	}
end

function KamiSanctumSystem.Synthesize(data, spiritIndices, components, rng)
	local preview = KamiSanctumSystem.PreviewSynthesize(data, spiritIndices, components)
	if not preview.Ok then
		return preview
	end
	rng = rng or Random.new()
	local indices = {}
	for _, i in ipairs(spiritIndices) do
		table.insert(indices, math.floor(tonumber(i) or 0))
	end
	local donors = select(1, collectDonors(data, indices))
	local comps = normalizeComponents(components)
	local n = #donors

	-- Consume copper
	local copper = preview.CopperCost
	data.CopperCoins = (tonumber(data.CopperCoins) or 0) - copper

	-- Consume components specified + 1 shard minimum
	local shardFromComp = comps[KamiSanctumConfig.ShardId] or 0
	if shardFromComp > 0 then
		if not takeItem(data, KamiSanctumConfig.ShardId, shardFromComp) then
			return {Ok = false, Error = "shard_take"}
		end
	elseif not takeItem(data, KamiSanctumConfig.ShardId, 1) then
		return {Ok = false, Error = "shard_take"}
	end
	for id, qty in pairs(comps) do
		if id ~= KamiSanctumConfig.ShardId then
			if not takeItem(data, id, qty) then
				return {Ok = false, Error = "component_take", ItemId = id}
			end
		end
	end

	-- Roll skills
	local parentPool = skillPoolFromDonors(donors)
	local starScore = preview.StarScore
	local countBonus = (n - 2) / 4
	local weightUnique = math.clamp(0.08 + 0.12 * starScore + 0.05 * countBonus + 0.04 * preview.QualityScore, 0.05, 0.55)
	local skillIds = {}
	local uniqueSkill = nil
	local used = {}

	for slot = 1, 3 do
		local rollUnique = rng:NextNumber() < weightUnique and slot == 3
		if rollUnique or (#parentPool == 0 and slot == 1) then
			local uid = KamiSanctumConfig.UniqueSkillIds[rng:NextInteger(1, #KamiSanctumConfig.UniqueSkillIds)]
			if not used[uid] then
				table.insert(skillIds, uid)
				used[uid] = true
				local def = SkillCatalog.GetClone(uid)
				if def then
					local pow = preview.ResonancePower
					if def.Damage then
						def.Damage = math.floor((def.Damage or 0) * pow + 0.5)
					end
					if def.HealAmount then
						def.HealAmount = math.floor((def.HealAmount or 0) * pow + 0.5)
					end
					uniqueSkill = def
				end
			end
		end
		if #skillIds < slot then
			local pick = weightedPick(rng, parentPool)
			if pick and not used[pick.Id] then
				table.insert(skillIds, pick.Id)
				used[pick.Id] = true
			elseif pick then
				-- try another
				for _ = 1, 8 do
					pick = weightedPick(rng, parentPool)
					if pick and not used[pick.Id] then
						table.insert(skillIds, pick.Id)
						used[pick.Id] = true
						break
					end
				end
			end
		end
	end
	while #skillIds < 3 do
		local uid = KamiSanctumConfig.UniqueSkillIds[rng:NextInteger(1, #KamiSanctumConfig.UniqueSkillIds)]
		if not used[uid] then
			table.insert(skillIds, uid)
			used[uid] = true
		else
			break
		end
	end

	local names = {}
	for _, sid in ipairs(skillIds) do
		local s = SkillCatalog.Get(sid)
		table.insert(names, s and s.Name or ("Skill#" .. tostring(sid)))
	end

	local coreP = preview.CorePrimary
	local prefixes = KamiSanctumConfig.NamePrefixes[coreP] or {"Ками"}
	local name = string.format("Ками-%s", prefixes[rng:NextInteger(1, #prefixes)])
	if n >= 4 then
		name = name .. "·" .. tostring(n)
	end

	local avgLv = 0
	local avgBond = 0
	local temper = {Attack = 0, Defense = 0, Spirit = 0}
	local parentIds = {}
	for _, d in ipairs(donors) do
		avgLv += tonumber(d.Spirit.Level) or 1
		avgBond += tonumber(d.Spirit.Bond) or 0
		local tp = d.Spirit.TemperPoints or {}
		temper.Attack += tonumber(tp.Attack) or 0
		temper.Defense += tonumber(tp.Defense) or 0
		temper.Spirit += tonumber(tp.Spirit) or 0
		table.insert(parentIds, tonumber(d.Spirit.Id) or 0)
	end
	avgLv = math.floor(avgLv / n + 0.5)
	avgBond = math.floor(avgBond / n + 0.5)
	temper.Attack = math.floor(temper.Attack / n)
	temper.Defense = math.floor(temper.Defense / n)
	temper.Spirit = math.floor(temper.Spirit / n)

	local newLevel = math.clamp(math.floor(avgLv * 0.85 + (tonumber(data.Level) or 10) * 0.15), 1, 100)
	local hash = 0
	for _, pid in ipairs(parentIds) do
		hash = (hash * 33 + pid) % 800
	end
	local newId = 9000 + hash

	local resonant = {
		Id = newId,
		Kind = "Resonant",
		Name = name,
		Level = newLevel,
		Experience = 0,
		Bond = math.clamp(avgBond, 0, 10),
		BondXp = 0,
		TemperFocus = donors[1].Spirit.TemperFocus,
		TemperPoints = temper,
		Skills = names,
		SkillIds = skillIds,
		UniqueSkill = uniqueSkill,
		ParentIds = parentIds,
		DonorCount = n,
		HybridPrimary = coreP,
		PrimaryElement = coreP,
		Element = coreP,
		ResonancePower = preview.ResonancePower,
		BonusHP = math.floor(20 * preview.ResonancePower),
		BonusAttack = math.floor(4 * preview.ResonancePower),
		BonusDefense = math.floor(3 * preview.ResonancePower),
		BonusSpeed = math.floor(1 * preview.ResonancePower),
		CaughtAt = os.time(),
	}

	-- Remove donors high index first
	table.sort(indices, function(a, b)
		return a > b
	end)
	for _, idx in ipairs(indices) do
		table.remove(data.Spirits, idx)
	end
	table.insert(data.Spirits, resonant)
	data.ActiveSpiritIndex = #data.Spirits
	data.CurrentSpiritId = resonant.Id

	local daily = KamiSanctumConfig.EnsureDaily(data)
	daily.SanctumSynth += 1

	return {
		Ok = true,
		Spirit = resonant,
		ResonancePower = preview.ResonancePower,
		CopperSpent = copper,
		DailyLeft = KamiSanctumConfig.DailySynthCap - daily.SanctumSynth,
	}
end

function KamiSanctumSystem.PreviewDisintegrate(data, spiritIndex)
	if not data then
		return {Ok = false, Error = "no_data"}
	end
	if (tonumber(data.Level) or 1) < KamiSanctumConfig.MinPlayerLevel then
		return {Ok = false, Error = "level", Need = KamiSanctumConfig.MinPlayerLevel}
	end
	local spirits = data.Spirits or {}
	if #spirits <= 1 then
		return {Ok = false, Error = "last_spirit"}
	end
	spiritIndex = math.floor(tonumber(spiritIndex) or 0)
	local sp = spirits[spiritIndex]
	if not sp then
		return {Ok = false, Error = "bad_index"}
	end
	local daily = KamiSanctumConfig.EnsureDaily(data)
	if daily.SanctumDisintegrate >= KamiSanctumConfig.DailyDisintegrateCap then
		return {Ok = false, Error = "daily_cap", Cap = KamiSanctumConfig.DailyDisintegrateCap}
	end
	local rows = KamiSanctumConfig.DisassembleLootWeights(sp, SpiritDatabase)
	local tips = {}
	for _, r in ipairs(rows) do
		local item = ItemCatalog.Get(r.Id)
		table.insert(tips, {
			Id = r.Id,
			Name = item and item.Name or ("#" .. r.Id),
			Quantity = r.Quantity,
			Weight = r.Weight,
		})
	end
	return {
		Ok = true,
		SpiritName = sp.Name,
		SpiritIndex = spiritIndex,
		LootTable = tips,
		DailyLeft = KamiSanctumConfig.DailyDisintegrateCap - daily.SanctumDisintegrate,
	}
end

function KamiSanctumSystem.Disintegrate(data, spiritIndex, rng)
	local preview = KamiSanctumSystem.PreviewDisintegrate(data, spiritIndex)
	if not preview.Ok then
		return preview
	end
	rng = rng or Random.new()
	spiritIndex = math.floor(tonumber(spiritIndex) or 0)
	local sp = data.Spirits[spiritIndex]
	local rows = KamiSanctumConfig.DisassembleLootWeights(sp, SpiritDatabase)
	local pick = weightedPick(rng, rows)
	if not pick then
		pick = {Id = 301, Quantity = 1}
	end
	-- second small roll for bonus shard
	local bonus = nil
	if rng:NextNumber() < 0.25 then
		bonus = {Id = 301, Quantity = 1}
	end

	table.remove(data.Spirits, spiritIndex)
	if (tonumber(data.ActiveSpiritIndex) or 1) > #data.Spirits then
		data.ActiveSpiritIndex = math.max(1, #data.Spirits)
	end
	if data.Spirits[data.ActiveSpiritIndex] then
		data.CurrentSpiritId = data.Spirits[data.ActiveSpiritIndex].Id
	end

	giveItem(data, pick.Id, pick.Quantity)
	local granted = {{Id = pick.Id, Quantity = pick.Quantity}}
	if bonus then
		giveItem(data, bonus.Id, bonus.Quantity)
		table.insert(granted, bonus)
	end
	-- copper crumbs
	local copperGain = 15 + math.floor(KamiSanctumConfig.SpiritQuality(sp, SpiritDatabase) * 40)
	data.CopperCoins = (tonumber(data.CopperCoins) or 0) + copperGain

	local daily = KamiSanctumConfig.EnsureDaily(data)
	daily.SanctumDisintegrate += 1

	return {
		Ok = true,
		Granted = granted,
		CopperGain = copperGain,
		DailyLeft = KamiSanctumConfig.DailyDisintegrateCap - daily.SanctumDisintegrate,
	}
end

return KamiSanctumSystem
