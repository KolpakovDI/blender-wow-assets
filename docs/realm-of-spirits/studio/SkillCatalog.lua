-- SkillCatalog - shared skill definitions for Realm of Spirits
local SkillCatalog = {}

-- Canonical skills by Id (stable for saves / unlocks)
SkillCatalog.ById = {
	[1] = {Id = 1, Name = "Огненный коготь", Element = "Fire", Type = "Attack", Damage = 26, Cost = 6, Cooldown = 1.5},
	[2] = {Id = 2, Name = "Пламенный всплеск", Element = "Fire", Type = "Attack", Damage = 40, Cost = 18, Cooldown = 4, Effect = {Type = "Burn", Value = 6, Duration = 2}},
	[3] = {Id = 3, Name = "Огненный шторм", Element = "Fire", Type = "Attack", Damage = 48, Cost = 34, Cooldown = 7, Effect = {Type = "Burn", Value = 8, Duration = 3}},
	[11] = {Id = 11, Name = "Ледяная стрела", Element = "Ice", Type = "Attack", Damage = 24, Cost = 6, Cooldown = 1.5},
	[12] = {Id = 12, Name = "Морозный ветер", Element = "Ice", Type = "Attack", Damage = 36, Cost = 16, Cooldown = 4, Effect = {Type = "DebuffAttack", Value = 0.2, Duration = 2}},
	[13] = {Id = 13, Name = "Ледяной шторм", Element = "Ice", Type = "Attack", Damage = 45, Cost = 32, Cooldown = 7, Effect = {Type = "DebuffAttack", Value = 0.25, Duration = 3}},
	[21] = {Id = 21, Name = "Теневой укус", Element = "Dark", Type = "Attack", Damage = 24, Cost = 10, Cooldown = 2.5},
	[22] = {Id = 22, Name = "Ночная аура", Element = "Dark", Type = "Attack", Damage = 40, Cost = 28, Cooldown = 6, Effect = {Type = "DebuffDefense", Value = 0.25, Duration = 3}},
	[23] = {Id = 23, Name = "Теневой шторм", Element = "Dark", Type = "Attack", Damage = 52, Cost = 36, Cooldown = 8, Effect = {Type = "DebuffDefense", Value = 0.3, Duration = 3}},
	[31] = {Id = 31, Name = "Молниеносный удар", Element = "Lightning", Type = "Attack", Damage = 28, Cost = 14, Cooldown = 3, Effect = {Type = "Stun", Duration = 1}},
	[32] = {Id = 32, Name = "Грозовой щит", Element = "Lightning", Type = "Attack", Damage = 48, Cost = 32, Cooldown = 7, Effect = {Type = "BuffDefense", Value = 0.25, Duration = 2}},
	[33] = {Id = 33, Name = "Грозовой шторм", Element = "Lightning", Type = "Attack", Damage = 58, Cost = 40, Cooldown = 8, Effect = {Type = "Stun", Duration = 1}},
	[41] = {Id = 41, Name = "Световой луч", Element = "Light", Type = "Attack", Damage = 30, Cost = 16, Cooldown = 3},
	[42] = {Id = 42, Name = "Божественная благодать", Element = "Light", Type = "Heal", HealAmount = 55, Cost = 36, Cooldown = 7, Effect = {Type = "BuffAttack", Value = 0.2, Duration = 2}},
	[43] = {Id = 43, Name = "Световой шторм", Element = "Light", Type = "Attack", Damage = 62, Cost = 42, Cooldown = 9, Effect = {Type = "BuffAttack", Value = 0.25, Duration = 2}},
	[51] = {Id = 51, Name = "Водная струя", Element = "Water", Type = "Attack", Damage = 25, Cost = 7, Cooldown = 1.5},
	[52] = {Id = 52, Name = "Приливной удар", Element = "Water", Type = "Attack", Damage = 38, Cost = 18, Cooldown = 4, Effect = {Type = "DebuffDefense", Value = 0.2, Duration = 2}},
	[53] = {Id = 53, Name = "Цунами", Element = "Water", Type = "Attack", Damage = 50, Cost = 34, Cooldown = 7, Effect = {Type = "DebuffDefense", Value = 0.25, Duration = 3}},
}

SkillCatalog.ByName = {}
for id, skill in pairs(SkillCatalog.ById) do
	SkillCatalog.ByName[skill.Name] = skill
end

-- Spirit unlock lists (slot order). Evolved forms get the storm skill as 3rd.
SkillCatalog.SpiritSkills = {
	[1] = {1, 2},
	[2] = {11, 12},
	[3] = {21, 22},
	[4] = {31, 32},
	[5] = {41, 42},
	[6] = {51, 52},
	[101] = {1, 2, 3},
	[102] = {11, 12, 13},
	[103] = {21, 22, 23},
	[104] = {31, 32, 33},
	[105] = {41, 42, 43},
	[106] = {51, 52, 53},
}

function SkillCatalog.Get(idOrName)
	if type(idOrName) == "number" then
		return SkillCatalog.ById[idOrName]
	elseif type(idOrName) == "string" then
		return SkillCatalog.ByName[idOrName]
	end
	return nil
end

function SkillCatalog.GetClone(idOrName)
	local src = SkillCatalog.Get(idOrName)
	if not src then return nil end
	local clone = table.clone(src)
	if src.Effect then
		clone.Effect = table.clone(src.Effect)
	end
	return clone
end

function SkillCatalog.Resolve(rawSkill, baseAttack)
	baseAttack = baseAttack or 12
	if type(rawSkill) == "number" then
		local fromCatalog = SkillCatalog.GetClone(rawSkill)
		if fromCatalog then
			return fromCatalog
		end
	end
	if type(rawSkill) == "table" then
		local byId = rawSkill.Id and SkillCatalog.GetClone(rawSkill.Id)
		if byId then
			for k, v in pairs(rawSkill) do
				if k ~= "Effect" then byId[k] = v end
			end
			if rawSkill.Effect then byId.Effect = table.clone(rawSkill.Effect) end
			return byId
		end
		local byName = rawSkill.Name and SkillCatalog.GetClone(rawSkill.Name)
		if byName then
			for k, v in pairs(rawSkill) do
				if k ~= "Effect" then byName[k] = v end
			end
			if rawSkill.Effect then byName.Effect = table.clone(rawSkill.Effect) end
			return byName
		end
		return {
			Name = rawSkill.Name or "Духовный удар",
			Type = rawSkill.Type or "Attack",
			Damage = rawSkill.Damage or math.max(12, math.floor(baseAttack * 0.9)),
			HealAmount = rawSkill.HealAmount,
			Cost = rawSkill.Cost or 0,
			Cooldown = rawSkill.Cooldown or 3,
			Effect = rawSkill.Effect and table.clone(rawSkill.Effect) or nil,
			Element = rawSkill.Element,
		}
	end
	if type(rawSkill) == "string" then
		local fromCatalog = SkillCatalog.GetClone(rawSkill)
		if fromCatalog then
			return fromCatalog
		end
		return {
			Name = rawSkill,
			Type = "Attack",
			Damage = math.max(14, math.floor(baseAttack * 1.1)),
			Cost = 12,
			Cooldown = 3,
		}
	end
	return {
		Name = "Духовный удар",
		Type = "Attack",
		Damage = math.max(12, math.floor(baseAttack)),
		Cost = 0,
		Cooldown = 2,
	}
end

function SkillCatalog.BuildAbilities(spiritIdOrInfo, maxSlots)
	maxSlots = maxSlots or 3
	local spiritId = spiritIdOrInfo
	local spiritInfo = nil
	if type(spiritIdOrInfo) == "table" then
		spiritInfo = spiritIdOrInfo
		spiritId = spiritInfo.Id
	end
	local atk = spiritInfo and spiritInfo.BaseStats and spiritInfo.BaseStats.Attack or 12
	local skills = {}
	local unlocks = spiritId and SkillCatalog.SpiritSkills[spiritId]
	if unlocks then
		for i = 1, math.min(maxSlots, #unlocks) do
			skills[i] = SkillCatalog.Resolve(unlocks[i], atk)
		end
		return skills
	end
	-- Fallback: inline Skills on spirit definition
	if spiritInfo and spiritInfo.Skills then
		for i = 1, math.min(maxSlots, #spiritInfo.Skills) do
			skills[i] = SkillCatalog.Resolve(spiritInfo.Skills[i], atk)
		end
	end
	if #skills == 0 then
		skills[1] = SkillCatalog.Resolve(nil, atk)
	end
	return skills
end

return SkillCatalog
