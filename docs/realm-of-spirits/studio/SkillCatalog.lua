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
	[52] = {Id = 52, Name = "Приливное исцеление", Element = "Water", Type = "Heal", HealAmount = 30, Cost = 18, Cooldown = 8},
	[53] = {Id = 53, Name = "Цунами", Element = "Water", Type = "Attack", Damage = 50, Cost = 34, Cooldown = 7, Effect = {Type = "DebuffDefense", Value = 0.25, Duration = 3}},
	[61] = {Id = 61, Name = "Каменный кулак", Element = "Earth", Type = "Attack", Damage = 28, Cost = 8, Cooldown = 1.8},
	[62] = {Id = 62, Name = "Землетрясение", Element = "Earth", Type = "Attack", Damage = 40, Cost = 20, Cooldown = 4.5, Effect = {Type = "DebuffDefense", Value = 0.25, Duration = 3}},
	[63] = {Id = 63, Name = "Обвал скал", Element = "Earth", Type = "Attack", Damage = 55, Cost = 36, Cooldown = 7.5, Effect = {Type = "Stun", Duration = 1}},
	[71] = {Id = 71, Name = "Пепельный укус", Element = "Fire", Type = "Attack", Damage = 27, Cost = 8, Cooldown = 1.6},
	[72] = {Id = 72, Name = "Жаровня", Element = "Fire", Type = "Attack", Damage = 39, Cost = 19, Cooldown = 4.2, Effect = {Type = "Burn", Value = 7, Duration = 2}},
	[73] = {Id = 73, Name = "Извержение", Element = "Fire", Type = "Attack", Damage = 54, Cost = 35, Cooldown = 7.2, Effect = {Type = "Burn", Value = 9, Duration = 3}},
	[81] = {Id = 81, Name = "Порыв ветра", Element = "Wind", Type = "Attack", Damage = 24, Cost = 6, Cooldown = 1.2},
	[82] = {Id = 82, Name = "Смерч", Element = "Wind", Type = "Attack", Damage = 36, Cost = 16, Cooldown = 3.5, Effect = {Type = "DebuffAttack", Value = 0.22, Duration = 2}},
	[83] = {Id = 83, Name = "Ураган", Element = "Wind", Type = "Attack", Damage = 52, Cost = 34, Cooldown = 7.0, Effect = {Type = "DebuffAttack", Value = 0.25, Duration = 2}},
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
	[120] = {Id = 120, Name = "Кристальный укус", Element = "Crystal", Type = "Attack", Damage = 28, Cost = 8, Cooldown = 1.7},
	[121] = {Id = 121, Name = "Призматический луч", Element = "Crystal", Type = "Attack", Damage = 40, Cost = 18, Cooldown = 4.2, Effect = {Type = "DebuffAttack", Value = 0.22, Duration = 2}},
	[122] = {Id = 122, Name = "Осколочный шторм", Element = "Crystal", Type = "Attack", Damage = 55, Cost = 35, Cooldown = 7.2, Effect = {Type = "DebuffDefense", Value = 0.25, Duration = 3}},
	[123] = {Id = 123, Name = "Лавовый щипок", Element = "Magma", Type = "Attack", Damage = 28, Cost = 8, Cooldown = 1.7, Effect = {Type = "Burn", Value = 5, Duration = 2}},
	[124] = {Id = 124, Name = "Поток магмы", Element = "Magma", Type = "Attack", Damage = 41, Cost = 18, Cooldown = 4.2, Effect = {Type = "Burn", Value = 7, Duration = 2}},
	[125] = {Id = 125, Name = "Извержение", Element = "Magma", Type = "Attack", Damage = 56, Cost = 35, Cooldown = 7.2, Effect = {Type = "Burn", Value = 10, Duration = 3}},
	[126] = {Id = 126, Name = "Касание тумана", Element = "Mist", Type = "Attack", Damage = 27, Cost = 8, Cooldown = 1.7},
	[127] = {Id = 127, Name = "Пелена тумана", Element = "Mist", Type = "Attack", Damage = 40, Cost = 18, Cooldown = 4.2, Effect = {Type = "DebuffAttack", Value = 0.22, Duration = 2}},
	[128] = {Id = 128, Name = "Призрачный шквал", Element = "Mist", Type = "Attack", Damage = 55, Cost = 35, Cooldown = 7.2, Effect = {Type = "Stun", Duration = 1}},
	-- Sky line (#18→#118)
	[129] = {Id = 129, Name = "Небесный пике", Element = "Sky", Type = "Attack", Damage = 26, Cost = 7, Cooldown = 1.4},
	[130] = {Id = 130, Name = "Порыв высоты", Element = "Sky", Type = "Attack", Damage = 39, Cost = 17, Cooldown = 3.8, Effect = {Type = "DebuffAttack", Value = 0.2, Duration = 2}},
	[131] = {Id = 131, Name = "Штормовой клекот", Element = "Sky", Type = "Attack", Damage = 54, Cost = 34, Cooldown = 7.0, Effect = {Type = "Stun", Duration = 1}},
	-- ElementPassives (meta only — not action-bar slots)
	[200] = {Id = 200, Name = "Жар стихии", Element = "Fire", Type = "Passive", Kind = "AtkPct", Value = 0.05, Description = "+5% урон"},
	[201] = {Id = 201, Name = "Угли защиты", Element = "Fire", Type = "Passive", Kind = "DefPct", Value = 0.05, Description = "+5% защита"},
	[202] = {Id = 202, Name = "Каменная стойкость", Element = "Earth", Type = "Passive", Kind = "DefPct", Value = 0.06, Description = "+6% защита"},
	[203] = {Id = 203, Name = "Глубинный удар", Element = "Earth", Type = "Passive", Kind = "AtkPct", Value = 0.04, Description = "+4% урон"},
	[204] = {Id = 204, Name = "Порыв ветра", Element = "Wind", Type = "Passive", Kind = "AtkPct", Value = 0.05, Description = "+5% урон"},
	[205] = {Id = 205, Name = "Лёгкость", Element = "Wind", Type = "Passive", Kind = "DefPct", Value = 0.04, Description = "+4% защита"},
	[206] = {Id = 206, Name = "Прилив", Element = "Water", Type = "Passive", Kind = "AtkPct", Value = 0.04, Description = "+4% урон"},
	[207] = {Id = 207, Name = "Зеркало вод", Element = "Water", Type = "Passive", Kind = "DefPct", Value = 0.06, Description = "+6% защита"},
	-- Kami Sanctum Unique pool (Resonant weighted roll)
	[300] = {Id = 300, Name = "Печать Ками", Element = "Fire", Type = "Attack", Damage = 48, Cost = 28, Cooldown = 6.5, Effect = {Type = "Burn", Value = 8, Duration = 3}, Unique = true},
	[301] = {Id = 301, Name = "Зеркальный резонанс", Element = "Water", Type = "Attack", Damage = 42, Cost = 24, Cooldown = 5.5, Effect = {Type = "DebuffAttack", Value = 0.2, Duration = 3}, Unique = true},
	[302] = {Id = 302, Name = "Корни синто", Element = "Earth", Type = "Attack", Damage = 45, Cost = 26, Cooldown = 6.0, Effect = {Type = "DebuffDefense", Value = 0.22, Duration = 3}, Unique = true},
	[303] = {Id = 303, Name = "Небесный импульс", Element = "Wind", Type = "Attack", Damage = 40, Cost = 22, Cooldown = 5.0, Effect = {Type = "Stun", Duration = 1}, Unique = true},
	[304] = {Id = 304, Name = "Исцеление святилища", Element = "Water", Type = "Heal", HealAmount = 55, Cost = 30, Cooldown = 8.0, Unique = true},
	[305] = {Id = 305, Name = "Вспышка синтеза", Element = "Fire", Type = "Attack", Damage = 62, Cost = 36, Cooldown = 7.5, Effect = {Type = "Burn", Value = 12, Duration = 2}, Unique = true},
	[306] = {Id = 306, Name = "Печать гармонии", Element = "Earth", Type = "Heal", HealAmount = 40, Cost = 22, Cooldown = 6.5, Unique = true},
	[307] = {Id = 307, Name = "Разлом духа", Element = "Wind", Type = "Attack", Damage = 58, Cost = 34, Cooldown = 7.0, Effect = {Type = "DebuffDefense", Value = 0.28, Duration = 2}, Unique = true},
}

-- Range: Melee | Ranged
-- DamageKind: Physical (melee or ranged weapon: sword, claw, bow, gun, bolt) | Spell (elemental magic)
SkillCatalog.CombatMeta = {
	[1] = {Range = "Melee", DamageKind = "Physical"},
	[2] = {Range = "Ranged", DamageKind = "Spell"},
	[3] = {Range = "Ranged", DamageKind = "Spell"},
	[11] = {Range = "Ranged", DamageKind = "Physical"},
	[12] = {Range = "Ranged", DamageKind = "Spell"},
	[13] = {Range = "Ranged", DamageKind = "Spell"},
	[21] = {Range = "Melee", DamageKind = "Physical"},
	[22] = {Range = "Ranged", DamageKind = "Spell"},
	[23] = {Range = "Ranged", DamageKind = "Spell"},
	[31] = {Range = "Melee", DamageKind = "Spell"},
	[32] = {Range = "Ranged", DamageKind = "Spell"},
	[33] = {Range = "Ranged", DamageKind = "Spell"},
	[41] = {Range = "Ranged", DamageKind = "Spell"},
	[42] = {Range = "Ranged", DamageKind = "Spell"},
	[43] = {Range = "Ranged", DamageKind = "Spell"},
	[51] = {Range = "Ranged", DamageKind = "Spell"},
	[52] = {Range = "Ranged", DamageKind = "Spell"},
	[53] = {Range = "Ranged", DamageKind = "Spell"},
	[61] = {Range = "Melee", DamageKind = "Physical"},
	[62] = {Range = "Ranged", DamageKind = "Spell"},
	[63] = {Range = "Ranged", DamageKind = "Spell"},
	[71] = {Range = "Melee", DamageKind = "Physical"},
	[72] = {Range = "Ranged", DamageKind = "Spell"},
	[73] = {Range = "Ranged", DamageKind = "Spell"},
	[81] = {Range = "Ranged", DamageKind = "Spell"},
	[82] = {Range = "Ranged", DamageKind = "Spell"},
	[83] = {Range = "Ranged", DamageKind = "Spell"},
	[91] = {Range = "Ranged", DamageKind = "Spell"},
	[92] = {Range = "Ranged", DamageKind = "Spell"},
	[93] = {Range = "Ranged", DamageKind = "Spell"},
	[101] = {Range = "Ranged", DamageKind = "Spell"},
	[102] = {Range = "Ranged", DamageKind = "Spell"},
	[103] = {Range = "Ranged", DamageKind = "Spell"},
	[111] = {Range = "Melee", DamageKind = "Physical"},
	[112] = {Range = "Ranged", DamageKind = "Spell"},
	[113] = {Range = "Ranged", DamageKind = "Spell"},
	[114] = {Range = "Melee", DamageKind = "Physical"},
	[115] = {Range = "Ranged", DamageKind = "Spell"},
	[116] = {Range = "Ranged", DamageKind = "Spell"},
	[117] = {Range = "Melee", DamageKind = "Physical"},
	[118] = {Range = "Ranged", DamageKind = "Spell"},
	[119] = {Range = "Melee", DamageKind = "Physical"},
	[120] = {Range = "Melee", DamageKind = "Physical"},
	[121] = {Range = "Ranged", DamageKind = "Spell"},
	[122] = {Range = "Ranged", DamageKind = "Spell"},
	[123] = {Range = "Melee", DamageKind = "Physical"},
	[124] = {Range = "Ranged", DamageKind = "Spell"},
	[125] = {Range = "Ranged", DamageKind = "Spell"},
	[126] = {Range = "Melee", DamageKind = "Spell"},
	[127] = {Range = "Ranged", DamageKind = "Spell"},
	[128] = {Range = "Ranged", DamageKind = "Spell"},
	[129] = {Range = "Melee", DamageKind = "Physical"},
	[130] = {Range = "Ranged", DamageKind = "Spell"},
	[131] = {Range = "Ranged", DamageKind = "Spell"},
	[300] = {Range = "Ranged", DamageKind = "Spell"},
	[301] = {Range = "Ranged", DamageKind = "Spell"},
	[302] = {Range = "Ranged", DamageKind = "Spell"},
	[303] = {Range = "Melee", DamageKind = "Spell"},
	[304] = {Range = "Ranged", DamageKind = "Spell"},
	[305] = {Range = "Ranged", DamageKind = "Spell"},
	[306] = {Range = "Ranged", DamageKind = "Spell"},
	[307] = {Range = "Ranged", DamageKind = "Spell"},
}

function SkillCatalog.GetCombatMeta(idOrSkill)
	local id = type(idOrSkill) == "table" and idOrSkill.Id or tonumber(idOrSkill)
	if id and SkillCatalog.CombatMeta[id] then
		return SkillCatalog.CombatMeta[id]
	end
	local s = type(idOrSkill) == "table" and idOrSkill or SkillCatalog.Get(id)
	if s and s.Type == "Heal" then
		return {Range = "Ranged", DamageKind = "Spell"}
	end
	if s and s.Type == "Attack" then
		return {Range = "Ranged", DamageKind = "Spell"}
	end
	return nil
end

SkillCatalog.ByName = {}
for id, skill in pairs(SkillCatalog.ById) do
	SkillCatalog.ByName[skill.Name] = skill
end

-- Spirit unlock lists (slot order). Evolved forms: signature storm skill is slot 1 (Identity).
SkillCatalog.SpiritSkills = {
	[11] = {1, 2},
	[42] = {11, 12},
	[33] = {21, 22},
	[32] = {31, 32},
	[13] = {41, 42},
	[41] = {51, 52},
	[1011] = {3, 1, 2},
	[1042] = {13, 11, 12},
	[1033] = {23, 21, 22},
	[1032] = {33, 31, 32},
	[1013] = {43, 41, 42},
	[1041] = {53, 51, 52},
	[21] = {61, 62},
	[1021] = {63, 61, 62},
	[12] = {71, 72},
	[1012] = {73, 71, 72},
	[31] = {81, 82},
	[1031] = {83, 81, 82},
	[22] = {91, 92},
	[1022] = {93, 91, 92},
	[43] = {101, 102},
	[1043] = {103, 101, 102},
	[24] = {111, 112},
	[1024] = {113, 111, 112},
	[25] = {114, 115},
	[1025] = {116, 114, 115},
	[23] = {117, 118},
	[1023] = {119, 117, 118},
	[26] = {120, 121},
	[1026] = {122, 120, 121},
	[14] = {123, 124},
	[1014] = {125, 123, 124},
	[44] = {126, 127},
	[1044] = {128, 126, 127},
	[34] = {129, 130},
	[1034] = {131, 129, 130},
}

-- 2 meta passives per Primary (not action-bar)
SkillCatalog.ElementPassives = {
	Fire = {200, 201},
	Earth = {202, 203},
	Wind = {204, 205},
	Water = {206, 207},
}

function SkillCatalog.GetElementPassives(primary)
	local ids = SkillCatalog.ElementPassives[primary]
	if not ids then return {} end
	local out = {}
	for _, id in ipairs(ids) do
		local s = SkillCatalog.GetClone(id)
		if s then table.insert(out, s) end
	end
	return out
end

function SkillCatalog.GetElementPassiveMods(primary)
	local atk, def = 0, 0
	for _, s in ipairs(SkillCatalog.GetElementPassives(primary)) do
		if s.Kind == "AtkPct" then atk += (tonumber(s.Value) or 0)
		elseif s.Kind == "DefPct" then def += (tonumber(s.Value) or 0)
		end
	end
	return atk, def
end

function SkillCatalog.FormatElementPassivesTip(primary)
	local list = SkillCatalog.GetElementPassives(primary)
	if #list == 0 then return nil end
	local parts = {}
	for _, s in ipairs(list) do
		table.insert(parts, string.format("%s (%s)", s.Name, s.Description or s.Kind or ""))
	end
	return "Пассивы: " .. table.concat(parts, " · ")
end

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
	local meta = SkillCatalog.GetCombatMeta(clone)
	if meta then
		clone.Range = meta.Range
		clone.DamageKind = meta.DamageKind
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

local function ensureMinBattleSkills(skills, maxSlots, atk)
	-- P0 agency: typical fights need ≥2 usable slots (hotkeys 1/2)
	if maxSlots < 2 then
		return skills
	end
	if #skills == 0 then
		skills[1] = SkillCatalog.Resolve(nil, atk)
	end
	if #skills < 2 then
		skills[2] = {
			Name = "Духовный импульс",
			Type = "Attack",
			Damage = math.max(16, math.floor(atk * 1.25)),
			Cost = 10,
			Cooldown = 3.5,
		}
	end
	return skills
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
	if spiritInfo and spiritInfo.BonusAttack then
		atk = atk + (tonumber(spiritInfo.BonusAttack) or 0)
	end
	local skills = {}
	-- Resonant / instance SkillIds take priority
	if spiritInfo and type(spiritInfo.SkillIds) == "table" and #spiritInfo.SkillIds > 0 then
		for i = 1, math.min(maxSlots, #spiritInfo.SkillIds) do
			local sid = spiritInfo.SkillIds[i]
			local resolved = SkillCatalog.Resolve(sid, atk)
			if spiritInfo.UniqueSkill and spiritInfo.UniqueSkill.Id == sid then
				resolved = spiritInfo.UniqueSkill
			end
			skills[i] = resolved
		end
		return ensureMinBattleSkills(skills, maxSlots, atk)
	end
	local unlocks = spiritId and SkillCatalog.SpiritSkills[spiritId]
	if unlocks then
		for i = 1, math.min(maxSlots, #unlocks) do
			skills[i] = SkillCatalog.Resolve(unlocks[i], atk)
		end
		return ensureMinBattleSkills(skills, maxSlots, atk)
	end
	-- Fallback: inline Skills on spirit definition
	if spiritInfo and spiritInfo.Skills then
		for i = 1, math.min(maxSlots, #spiritInfo.Skills) do
			skills[i] = SkillCatalog.Resolve(spiritInfo.Skills[i], atk)
		end
	end
	return ensureMinBattleSkills(skills, maxSlots, atk)
end

return SkillCatalog
