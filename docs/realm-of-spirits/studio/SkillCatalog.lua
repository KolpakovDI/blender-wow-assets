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
	[61] = {Id = 61, Name = "Каменный кулак", Element = "Earth", Type = "Attack", Damage = 28, Cost = 8, Cooldown = 1.8},
	[62] = {Id = 62, Name = "Землетрясение", Element = "Earth", Type = "Attack", Damage = 40, Cost = 20, Cooldown = 4.5, Effect = {Type = "DebuffDefense", Value = 0.2, Duration = 2}},
	[63] = {Id = 63, Name = "Обвал скал", Element = "Earth", Type = "Attack", Damage = 55, Cost = 36, Cooldown = 7.5, Effect = {Type = "Stun", Duration = 1}},
	[71] = {Id = 71, Name = "Пепельный укус", Element = "Fire", Type = "Attack", Damage = 27, Cost = 8, Cooldown = 1.6},
	[72] = {Id = 72, Name = "Жаровня", Element = "Fire", Type = "Attack", Damage = 39, Cost = 19, Cooldown = 4.2, Effect = {Type = "Burn", Value = 7, Duration = 2}},
	[73] = {Id = 73, Name = "Извержение", Element = "Fire", Type = "Attack", Damage = 54, Cost = 35, Cooldown = 7.2, Effect = {Type = "Burn", Value = 9, Duration = 3}},
	[81] = {Id = 81, Name = "Порыв ветра", Element = "Wind", Type = "Attack", Damage = 26, Cost = 8, Cooldown = 1.5},
	[82] = {Id = 82, Name = "Смерч", Element = "Wind", Type = "Attack", Damage = 38, Cost = 18, Cooldown = 4.0, Effect = {Type = "DebuffDefense", Value = 0.2, Duration = 2}},
	[83] = {Id = 83, Name = "Ураган", Element = "Wind", Type = "Attack", Damage = 52, Cost = 34, Cooldown = 7.0, Effect = {Type = "DebuffAttack", Value = 0.2, Duration = 2}},
	[91] = {Id = 91, Name = "Лоза", Element = "Nature", Type = "Attack", Damage = 25, Cost = 8, Cooldown = 1.6},
	[92] = {Id = 92, Name = "Споры", Element = "Nature", Type = "Attack", Damage = 37, Cost = 18, Cooldown = 4.1, Effect = {Type = "DebuffAttack", Value = 0.2, Duration = 2}},
	[93] = {Id = 93, Name = "Гнев леса", Element = "Nature", Type = "Attack", Damage = 51, Cost = 34, Cooldown = 7.1, Effect = {Type = "DebuffDefense", Value = 0.25, Duration = 3}},
	[101] = {Id = 101, Name = "Лунный луч", Element = "Moon", Type = "Attack", Damage = 26, Cost = 8, Cooldown = 1.5},
	[102] = {Id = 102, Name = "Сонная пыль", Element = "Moon", Type = "Attack", Damage = 38, Cost = 18, Cooldown = 4.0, Effect = {Type = "DebuffAttack", Value = 0.22, Duration = 2}},
	[103] = {Id = 103, Name = "Полнолуние", Element = "Moon", Type = "Attack", Damage = 52, Cost = 34, Cooldown = 7.0, Effect = {Type = "Stun", Duration = 1}},
	[111] = {Id = 111, Name = "Ядовитый укус", Element = "Poison", Type = "Attack", Damage = 25, Cost = 8, Cooldown = 1.6, Effect = {Type = "Burn", Value = 5, Duration = 2}},
	[112] = {Id = 112, Name = "Токсичный туман", Element = "Poison", Type = "Attack", Damage = 37, Cost = 18, Cooldown = 4.1, Effect = {Type = "DebuffDefense", Value = 0.22, Duration = 2}},
	[113] = {Id = 113, Name = "Смертельный яд", Element = "Poison", Type = "Attack", Damage = 51, Cost = 34, Cooldown = 7.1, Effect = {Type = "Burn", Value = 8, Duration = 3}},
	[114] = {Id = 114, Name = "Удар клешней", Element = "Sand", Type = "Attack", Damage = 26, Cost = 8, Cooldown = 1.6},
	[115] = {Id = 115, Name = "Песчаная буря", Element = "Sand", Type = "Attack", Damage = 38, Cost = 18, Cooldown = 4.1, Effect = {Type = "DebuffAttack", Value = 0.22, Duration = 2}},
	[116] = {Id = 116, Name = "Удар дюны", Element = "Sand", Type = "Attack", Damage = 52, Cost = 34, Cooldown = 7.1, Effect = {Type = "DebuffDefense", Value = 0.25, Duration = 3}},
	[117] = {Id = 117, Name = "Стальной панцирь", Element = "Metal", Type = "Attack", Damage = 27, Cost = 8, Cooldown = 1.7},
	[118] = {Id = 118, Name = "Магнитный удар", Element = "Metal", Type = "Attack", Damage = 39, Cost = 18, Cooldown = 4.2, Effect = {Type = "DebuffDefense", Value = 0.22, Duration = 2}},
	[119] = {Id = 119, Name = "Кувалда колосса", Element = "Metal", Type = "Attack", Damage = 54, Cost = 35, Cooldown = 7.2, Effect = {Type = "Stun", Duration = 1}},
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
	[7] = {61, 62},
	[107] = {61, 62, 63},
	[8] = {71, 72},
	[108] = {71, 72, 73},
	[9] = {81, 82},
	[109] = {81, 82, 83},
	[10] = {91, 92},
	[110] = {91, 92, 93},
	[11] = {101, 102},
	[111] = {101, 102, 103},
	[12] = {111, 112},
	[112] = {111, 112, 113},
	[13] = {114, 115},
	[113] = {114, 115, 116},
	[14] = {117, 118},
	[114] = {117, 118, 119},
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
