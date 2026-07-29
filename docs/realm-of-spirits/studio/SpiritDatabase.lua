-- Shared spirit database for Realm of Spirits
-- Skills: SkillIds → SkillCatalog; shop → ItemCatalog
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local realmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local SkillCatalog = require(realmFolder:WaitForChild("SkillCatalog"))
local ItemCatalog = require(realmFolder:WaitForChild("ItemCatalog"))

local SpiritDatabase = {}

SpiritDatabase.Spirits = {
	[1] = {
		MovementType = "Walk",
		Id = 1, Name = "Огненный Кот", Element = "Fire", Rarity = "Common",
		Color = Color3.fromRGB(255, 100, 50), Size = 3,
		BaseStats = {HP = 110, Attack = 18, Defense = 12, Speed = 12},
		SkillIds = {1, 2},
		CatchRate = 0.65,
	},
	[2] = {
		Id = 2, Name = "Ледяная Птица", Element = "Ice", Rarity = "Uncommon",
		Color = Color3.fromRGB(100, 200, 255), Size = 2.5,
		BaseStats = {HP = 85, Attack = 14, Defense = 9, Speed = 18},
		SkillIds = {11, 12},
		CatchRate = 0.45,
	},
	[3] = {
		Id = 3, Name = "Теневой Пёс", Element = "Dark", Rarity = "Rare",
		Color = Color3.fromRGB(100, 50, 150), Size = 3.5,
		BaseStats = {HP = 120, Attack = 18, Defense = 12, Speed = 15},
		SkillIds = {21, 22},
		CatchRate = 0.22,
	},
	[4] = {
		MovementType = "Walk",
		Id = 4, Name = "Грозовой Дракон", Element = "Lightning", Rarity = "Epic",
		Color = Color3.fromRGB(200, 200, 100), Size = 5,
		BaseStats = {HP = 150, Attack = 22, Defense = 15, Speed = 20},
		SkillIds = {31, 32},
		CatchRate = 0.05,
	},
	[5] = {
		Id = 5, Name = "Световой Единорог", Element = "Light", Rarity = "Legendary",
		Color = Color3.fromRGB(255, 255, 200), Size = 4,
		BaseStats = {HP = 180, Attack = 25, Defense = 20, Speed = 16},
		SkillIds = {41, 42},
		CatchRate = 0.01,
	},
	[6] = {
		MovementType = "Swim",
		Id = 6, Name = "Водный Карп", Element = "Water", Rarity = "Uncommon",
		Color = Color3.fromRGB(25, 40, 85), Size = 3.2,
		BaseStats = {HP = 100, Attack = 15, Defense = 14, Speed = 14},
		SkillIds = {51, 52},
		CatchRate = 0.4,
	},
	[7] = {
		MovementType = "Walk",
		Id = 7, Name = "Каменный Голем", Element = "Earth", Rarity = "Uncommon",
		Color = Color3.fromRGB(140, 110, 70), Size = 3.8,
		BaseStats = {HP = 130, Attack = 16, Defense = 20, Speed = 9},
		SkillIds = {61, 62},
		CatchRate = 0.38,
	},
	[8] = {
		MovementType = "Walk",
		Id = 8, Name = "Пепельный Саламандр", Element = "Fire", Rarity = "Uncommon",
		Color = Color3.fromRGB(220, 90, 40), Size = 3.4,
		BaseStats = {HP = 105, Attack = 19, Defense = 12, Speed = 15},
		SkillIds = {71, 72},
		CatchRate = 0.42,
	},
	[9] = {
		MovementType = "Walk",
		Id = 9, Name = "Ветряной Лис", Element = "Wind", Rarity = "Uncommon",
		Color = Color3.fromRGB(120, 200, 180), Size = 3.2,
		BaseStats = {HP = 95, Attack = 18, Defense = 10, Speed = 20},
		SkillIds = {81, 82},
		CatchRate = 0.40,
	},
	[10] = {
		MovementType = "Walk",
		Id = 10, Name = "Моховой Олень", Element = "Nature", Rarity = "Uncommon",
		Color = Color3.fromRGB(80, 160, 70), Size = 3.5,
		BaseStats = {HP = 115, Attack = 17, Defense = 14, Speed = 14},
		SkillIds = {91, 92},
		CatchRate = 0.40,
	},
	[11] = {
		MovementType = "Walk",
		Id = 11, Name = "Лунный Кролик", Element = "Moon", Rarity = "Uncommon",
		Color = Color3.fromRGB(200, 210, 255), Size = 3.2,
		BaseStats = {HP = 100, Attack = 18, Defense = 11, Speed = 19},
		SkillIds = {101, 102},
		CatchRate = 0.40,
	},
	[12] = {
		MovementType = "Walk",
		Id = 12, Name = "Ядовитая Гадюка", Element = "Poison", Rarity = "Uncommon",
		Color = Color3.fromRGB(90, 180, 60), Size = 3.3,
		BaseStats = {HP = 98, Attack = 19, Defense = 12, Speed = 17},
		SkillIds = {111, 112},
		CatchRate = 0.39,
	},
	[13] = {
		MovementType = "Walk",
		Id = 13, Name = "Пустынный Скорпион", Element = "Sand", Rarity = "Uncommon",
		Color = Color3.fromRGB(210, 170, 90), Size = 3.4,
		BaseStats = {HP = 105, Attack = 20, Defense = 14, Speed = 15},
		SkillIds = {114, 115},
		CatchRate = 0.37,
	},
	[14] = {
		MovementType = "Walk",
		Id = 14, Name = "Стальной Жук", Element = "Metal", Rarity = "Uncommon",
		Color = Color3.fromRGB(140, 155, 175), Size = 3.5,
		BaseStats = {HP = 110, Attack = 21, Defense = 16, Speed = 13},
		SkillIds = {117, 118},
		CatchRate = 0.36,
	},
	[15] = {
		MovementType = "Walk",
		Id = 15, Name = "Хрустальный Лис", Element = "Crystal", Rarity = "Uncommon",
		Color = Color3.fromRGB(180, 220, 255), Size = 3.4,
		BaseStats = {HP = 108, Attack = 22, Defense = 14, Speed = 18},
		SkillIds = {120, 121},
		CatchRate = 0.35,
	},
	[101] = {Id = 101, Name = "Огненный Тигр", Element = "Fire", Rarity = "Rare", BaseStats = {HP = 150, Attack = 25, Defense = 15, Speed = 18}, SkillIds = {1, 2, 3}, CatchRate = 0.1},
	[102] = {MovementType = "Fly", Id = 102, Name = "Ледяной Феникс", Element = "Ice", Rarity = "Rare", BaseStats = {HP = 120, Attack = 22, Defense = 12, Speed = 28}, SkillIds = {11, 12, 13}, CatchRate = 0.08},
	[103] = {Id = 103, Name = "Теневой Волк", Element = "Dark", Rarity = "Epic", BaseStats = {HP = 180, Attack = 30, Defense = 18, Speed = 22}, SkillIds = {21, 22, 23}, CatchRate = 0.05},
	[104] = {MovementType = "Fly", Id = 104, Name = "Грозовой Левиафан", Element = "Lightning", Rarity = "Legendary", BaseStats = {HP = 220, Attack = 35, Defense = 22, Speed = 30}, SkillIds = {31, 32, 33}, CatchRate = 0.02},
	[105] = {Id = 105, Name = "Световой Альфа", Element = "Light", Rarity = "Legendary", BaseStats = {HP = 280, Attack = 40, Defense = 28, Speed = 25}, SkillIds = {41, 42, 43}, CatchRate = 0.01},
	[106] = {Id = 106, Name = "Цунами-Карп", Element = "Water", Rarity = "Rare", Color = Color3.fromRGB(30, 100, 200), Size = 4.5, BaseStats = {HP = 160, Attack = 24, Defense = 20, Speed = 16}, SkillIds = {51, 52, 53}, CatchRate = 0.08},
	[107] = {MovementType = "Walk", Id = 107, Name = "Горный Титан", Element = "Earth", Rarity = "Rare", Color = Color3.fromRGB(160, 130, 80), Size = 5.2, BaseStats = {HP = 200, Attack = 26, Defense = 28, Speed = 11}, SkillIds = {61, 62, 63}, CatchRate = 0.07},
	[108] = {MovementType = "Walk", Id = 108, Name = "Инферно-Дракон", Element = "Fire", Rarity = "Rare", Color = Color3.fromRGB(255, 80, 30), Size = 5.0, BaseStats = {HP = 170, Attack = 28, Defense = 18, Speed = 17}, SkillIds = {71, 72, 73}, CatchRate = 0.07},
	[109] = {MovementType = "Walk", Id = 109, Name = "Буревой Кицунэ", Element = "Wind", Rarity = "Rare", Color = Color3.fromRGB(90, 220, 200), Size = 4.8, BaseStats = {HP = 155, Attack = 27, Defense = 14, Speed = 24}, SkillIds = {81, 82, 83}, CatchRate = 0.07},
	[110] = {MovementType = "Walk", Id = 110, Name = "Древний Энт", Element = "Nature", Rarity = "Rare", Color = Color3.fromRGB(60, 130, 55), Size = 5.4, BaseStats = {HP = 190, Attack = 24, Defense = 26, Speed = 12}, SkillIds = {91, 92, 93}, CatchRate = 0.07},
	[111] = {MovementType = "Walk", Id = 111, Name = "Цукуёми-Страж", Element = "Moon", Rarity = "Rare", Color = Color3.fromRGB(160, 175, 255), Size = 5.0, BaseStats = {HP = 165, Attack = 27, Defense = 16, Speed = 22}, SkillIds = {101, 102, 103}, CatchRate = 0.07},
	[112] = {MovementType = "Walk", Id = 112, Name = "Василиск-Гидра", Element = "Poison", Rarity = "Rare", Color = Color3.fromRGB(70, 150, 45), Size = 5.2, BaseStats = {HP = 175, Attack = 28, Defense = 18, Speed = 16}, SkillIds = {111, 112, 113}, CatchRate = 0.07},
	[113] = {MovementType = "Walk", Id = 113, Name = "Песчаный Император", Element = "Sand", Rarity = "Rare", Color = Color3.fromRGB(190, 150, 70), Size = 5.3, BaseStats = {HP = 185, Attack = 29, Defense = 20, Speed = 15}, SkillIds = {114, 115, 116}, CatchRate = 0.07},
	[114] = {MovementType = "Walk", Id = 114, Name = "Железный Колосс", Element = "Metal", Rarity = "Rare", Color = Color3.fromRGB(100, 115, 135), Size = 5.5, BaseStats = {HP = 195, Attack = 30, Defense = 24, Speed = 12}, SkillIds = {117, 118, 119}, CatchRate = 0.07},
	[115] = {MovementType = "Walk", Id = 115, Name = "Призматический Страж", Element = "Crystal", Rarity = "Rare", Color = Color3.fromRGB(140, 200, 255), Size = 5.2, BaseStats = {HP = 180, Attack = 31, Defense = 20, Speed = 20}, SkillIds = {120, 121, 122}, CatchRate = 0.07},
}

for _, spirit in pairs(SpiritDatabase.Spirits) do
	if spirit.SkillIds and not spirit.Skills then
		local skills = {}
		for _, skillId in ipairs(spirit.SkillIds) do
			local s = SkillCatalog.GetClone(skillId)
			if s then table.insert(skills, s) end
		end
		spirit.Skills = skills
	end
end

-- Four primaries: Fire → Earth → Wind → Water → Fire. Aspect = old flavor tag.
local PRIMARY_ASPECT = {
	[1] = { "Fire", "Fire" },
	[101] = { "Fire", "Fire" },
	[8] = { "Fire", "Ash" },
	[108] = { "Fire", "Ash" },
	[5] = { "Fire", "Light" },
	[105] = { "Fire", "Light" },
	[6] = { "Water", "Water" },
	[106] = { "Water", "Water" },
	[2] = { "Water", "Ice" },
	[102] = { "Water", "Ice" },
	[11] = { "Water", "Moon" },
	[111] = { "Water", "Moon" },
	[7] = { "Earth", "Earth" },
	[107] = { "Earth", "Earth" },
	[10] = { "Earth", "Nature" },
	[110] = { "Earth", "Nature" },
	[13] = { "Earth", "Sand" },
	[113] = { "Earth", "Sand" },
	[14] = { "Earth", "Metal" },
	[114] = { "Earth", "Metal" },
	[15] = { "Earth", "Crystal" },
	[115] = { "Earth", "Crystal" },
	[12] = { "Earth", "Poison" },
	[112] = { "Earth", "Poison" },
	[9] = { "Wind", "Wind" },
	[109] = { "Wind", "Wind" },
	[4] = { "Wind", "Storm" },
	[104] = { "Wind", "Storm" },
	[3] = { "Wind", "Dark" },
	[103] = { "Wind", "Dark" },
}

for id, spirit in pairs(SpiritDatabase.Spirits) do
	local map = PRIMARY_ASPECT[id]
	if map then
		spirit.PrimaryElement = map[1]
		spirit.Aspect = map[2]
		spirit.Element = map[1] -- battle / Dex use Primary
	else
		spirit.PrimaryElement = spirit.Element or "Earth"
		spirit.Aspect = spirit.Aspect or spirit.PrimaryElement
		spirit.Element = spirit.PrimaryElement
	end
end

-- Cycle: Fire → Earth → Wind → Water → Fire (×1.5 / ×0.7)
SpiritDatabase.ElementChart = {
	Fire = { Strong = { "Earth" }, Weak = { "Water" } },
	Earth = { Strong = { "Wind" }, Weak = { "Fire" } },
	Wind = { Strong = { "Water" }, Weak = { "Earth" } },
	Water = { Strong = { "Fire" }, Weak = { "Wind" } },
}

SpiritDatabase.AspectLabelsRu = {
	Fire = "Огонь",
	Ash = "Пепел",
	Light = "Свет",
	Water = "Вода",
	Ice = "Лёд",
	Moon = "Луна",
	Earth = "Земля",
	Nature = "Природа",
	Sand = "Песок",
	Metal = "Металл",
	Crystal = "Кристалл",
	Poison = "Яд",
	Wind = "Ветер",
	Storm = "Гроза",
	Dark = "Тень",
}

SpiritDatabase.PrimaryLabelsRu = {
	Fire = "Огонь",
	Earth = "Земля",
	Wind = "Ветер",
	Water = "Вода",
}


-- Only purchasable shop rows (not evolution materials)
SpiritDatabase.ShopItems = {}
for _, shopId in ipairs(ItemCatalog.ShopIds) do
	SpiritDatabase.ShopItems[shopId] = ItemCatalog.ById[shopId]
end

SpiritDatabase.EvolutionRules = {
	-- RequiredBond: Spirit Resonance track B (Haven care)
	[1] = {EvolvedId = 101, RequiredLevel = 10, RequiredBond = 3, RequiredItems = {{Id = 101, Quantity = 5}}, RequiredBattles = 10},
	[2] = {EvolvedId = 102, RequiredLevel = 12, RequiredBond = 3, RequiredItems = {{Id = 102, Quantity = 5}}, RequiredBattles = 15},
	[3] = {EvolvedId = 103, RequiredLevel = 15, RequiredBond = 3, RequiredItems = {{Id = 103, Quantity = 5}}, RequiredBattles = 20},
	[4] = {EvolvedId = 104, RequiredLevel = 18, RequiredBond = 4, RequiredItems = {{Id = 104, Quantity = 5}}, RequiredBattles = 25},
	[5] = {EvolvedId = 105, RequiredLevel = 20, RequiredBond = 4, RequiredItems = {{Id = 105, Quantity = 5}}, RequiredBattles = 30},
	[6] = {EvolvedId = 106, RequiredLevel = 12, RequiredBond = 3, RequiredItems = {{Id = 106, Quantity = 5}}, RequiredBattles = 12},
	[7] = {EvolvedId = 107, RequiredLevel = 14, RequiredBond = 3, RequiredItems = {{Id = 107, Quantity = 5}}, RequiredBattles = 14},
	[8] = {EvolvedId = 108, RequiredLevel = 13, RequiredBond = 3, RequiredItems = {{Id = 108, Quantity = 5}}, RequiredBattles = 13},
	[9] = {EvolvedId = 109, RequiredLevel = 13, RequiredBond = 3, RequiredItems = {{Id = 109, Quantity = 5}}, RequiredBattles = 13},
	[10] = {EvolvedId = 110, RequiredLevel = 14, RequiredBond = 3, RequiredItems = {{Id = 110, Quantity = 5}}, RequiredBattles = 14},
	[11] = {EvolvedId = 111, RequiredLevel = 14, RequiredBond = 3, RequiredItems = {{Id = 111, Quantity = 5}}, RequiredBattles = 14},
	[12] = {EvolvedId = 112, RequiredLevel = 14, RequiredBond = 3, RequiredItems = {{Id = 112, Quantity = 5}}, RequiredBattles = 14},
	[13] = {EvolvedId = 113, RequiredLevel = 14, RequiredBond = 3, RequiredItems = {{Id = 113, Quantity = 5}}, RequiredBattles = 14},
	[14] = {EvolvedId = 114, RequiredLevel = 14, RequiredBond = 3, RequiredItems = {{Id = 114, Quantity = 5}}, RequiredBattles = 14},
	[15] = {EvolvedId = 115, RequiredLevel = 14, RequiredBond = 3, RequiredItems = {{Id = 115, Quantity = 5}}, RequiredBattles = 14},
}

function SpiritDatabase.Get(id)
	return SpiritDatabase.Spirits[id]
end

function SpiritDatabase.GetPrimary(spiritOrId)
	local spirit = type(spiritOrId) == "table" and spiritOrId or SpiritDatabase.Spirits[spiritOrId]
	if not spirit then
		return "Earth"
	end
	return spirit.PrimaryElement or spirit.Element or "Earth"
end

function SpiritDatabase.GetAspect(spiritOrId)
	local spirit = type(spiritOrId) == "table" and spiritOrId or SpiritDatabase.Spirits[spiritOrId]
	if not spirit then
		return "Earth"
	end
	return spirit.Aspect or spirit.PrimaryElement or spirit.Element or "Earth"
end

function SpiritDatabase.FormatElementLabel(spiritOrId)
	local primary = SpiritDatabase.GetPrimary(spiritOrId)
	local aspect = SpiritDatabase.GetAspect(spiritOrId)
	local pRu = SpiritDatabase.PrimaryLabelsRu[primary] or primary
	local aRu = SpiritDatabase.AspectLabelsRu[aspect] or aspect
	if aspect == primary or aRu == pRu then
		return pRu
	end
	return string.format("%s (%s)", pRu, aRu)
end

--- Returns multiplier, tag ("Strong"|"Weak"|"Neutral"), atkEl, defEl
function SpiritDatabase.GetElementMultiplier(attacker, defender)
	local atkEl = SpiritDatabase.GetPrimary(attacker)
	local defEl = SpiritDatabase.GetPrimary(defender)
	local chart = SpiritDatabase.ElementChart[atkEl]
	local mult, tag = 1, "Neutral"
	if chart then
		if table.find(chart.Strong, defEl) then
			mult, tag = 1.5, "Strong"
		elseif table.find(chart.Weak, defEl) then
			mult, tag = 0.7, "Weak"
		end
	end
	return mult, tag, atkEl, defEl
end

--- Short RU tag for battle log (nil when Neutral)
function SpiritDatabase.FormatElementMatchup(attacker, defender)
	local mult, tag, atkEl, defEl = SpiritDatabase.GetElementMultiplier(attacker, defender)
	local aRu = SpiritDatabase.PrimaryLabelsRu[atkEl] or atkEl
	local dRu = SpiritDatabase.PrimaryLabelsRu[defEl] or defEl
	if tag == "Strong" then
		return string.format("Сильно! %s → %s ×1.5", aRu, dRu), mult, tag
	elseif tag == "Weak" then
		return string.format("Слабо… %s → %s ×0.7", aRu, dRu), mult, tag
	end
	return nil, mult, tag
end

--- Battle-start agency tip: your Primary vs enemy + cycle reminder
function SpiritDatabase.FormatElementAgencyTip(attacker, defender)
	local mult, tag, atkEl, defEl = SpiritDatabase.GetElementMultiplier(attacker, defender)
	local aRu = SpiritDatabase.PrimaryLabelsRu[atkEl] or atkEl
	local dRu = SpiritDatabase.PrimaryLabelsRu[defEl] or defEl
	local verdict = "равно"
	if tag == "Strong" then
		verdict = "Сильно ×1.5"
	elseif tag == "Weak" then
		verdict = "Слабо ×0.7"
	end
	return string.format("%s vs %s — %s · Огонь→Земля→Ветер→Вода→Огонь", aRu, dRu, verdict), mult, tag
end

function SpiritDatabase.GetSkillNames(spirit)
	if not spirit then return {} end
	if spirit.SkillIds then
		local names = {}
		for _, skillId in ipairs(spirit.SkillIds) do
			local s = SkillCatalog.Get(skillId)
			if s then table.insert(names, s.Name) end
		end
		return names
	end
	if not spirit.Skills then return {} end
	if type(spirit.Skills[1]) == "table" then
		local names = {}
		for _, skill in ipairs(spirit.Skills) do
			table.insert(names, skill.Name)
		end
		return names
	end
	return spirit.Skills
end

function SpiritDatabase.GetAbilities(spiritId)
	return SkillCatalog.BuildAbilities(spiritId, 3)
end

function SpiritDatabase.GetDisplay(id)
	local spirit = SpiritDatabase.Spirits[id]
	if not spirit then return nil end
	return {
		Name = spirit.Name,
		Element = spirit.Element,
		PrimaryElement = SpiritDatabase.GetPrimary(spirit),
		Aspect = SpiritDatabase.GetAspect(spirit),
		ElementLabel = SpiritDatabase.FormatElementLabel(spirit),
		Rarity = spirit.Rarity,
	}
end

function SpiritDatabase.GetEvolutionRule(id)
	return SpiritDatabase.EvolutionRules[id]
end

function SpiritDatabase.GetEvolutionTarget(id)
	local rule = SpiritDatabase.GetEvolutionRule(id)
	if not rule then return nil end
	return SpiritDatabase.Get(rule.EvolvedId)
end

function SpiritDatabase.CalculateDamage(attacker, defender, skill)
	local damage = (skill.Damage or 10) + ((attacker.BaseStats and attacker.BaseStats.Attack or 10) * 0.5)
	damage = damage - ((defender.BaseStats and defender.BaseStats.Defense or 0) * 0.3)
	local elementBonus = SpiritDatabase.GetElementMultiplier(attacker, defender)
	damage = damage * elementBonus * (math.random(85, 115) / 100)
	return math.max(1, math.floor(damage))
end

return SpiritDatabase
