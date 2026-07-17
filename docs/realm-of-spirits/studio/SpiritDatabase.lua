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
	[101] = {Id = 101, Name = "Огненный Тигр", Element = "Fire", Rarity = "Rare", BaseStats = {HP = 150, Attack = 25, Defense = 15, Speed = 18}, SkillIds = {1, 2, 3}, CatchRate = 0.1},
	[102] = {MovementType = "Fly", Id = 102, Name = "Ледяной Феникс", Element = "Ice", Rarity = "Rare", BaseStats = {HP = 120, Attack = 22, Defense = 12, Speed = 28}, SkillIds = {11, 12, 13}, CatchRate = 0.08},
	[103] = {Id = 103, Name = "Теневой Волк", Element = "Dark", Rarity = "Epic", BaseStats = {HP = 180, Attack = 30, Defense = 18, Speed = 22}, SkillIds = {21, 22, 23}, CatchRate = 0.05},
	[104] = {MovementType = "Fly", Id = 104, Name = "Грозовой Левиафан", Element = "Lightning", Rarity = "Legendary", BaseStats = {HP = 220, Attack = 35, Defense = 22, Speed = 30}, SkillIds = {31, 32, 33}, CatchRate = 0.02},
	[105] = {Id = 105, Name = "Световой Альфа", Element = "Light", Rarity = "Legendary", BaseStats = {HP = 280, Attack = 40, Defense = 28, Speed = 25}, SkillIds = {41, 42, 43}, CatchRate = 0.01},
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

SpiritDatabase.ElementChart = {
	Fire = {Strong = {"Ice", "Dark"}, Weak = {"Water", "Earth"}},
	Ice = {Strong = {"Fire", "Lightning"}, Weak = {"Fire", "Lightning"}},
	Dark = {Strong = {"Light", "Lightning"}, Weak = {"Light", "Fire"}},
	Lightning = {Strong = {"Ice", "Water"}, Weak = {"Earth", "Dark"}},
	Light = {Strong = {"Dark"}, Weak = {"Dark"}},
	Water = {Strong = {"Fire", "Earth"}, Weak = {"Lightning", "Ice"}},
	Earth = {Strong = {"Lightning", "Fire"}, Weak = {"Water", "Ice"}},
}

-- Only purchasable shop rows (not evolution materials)
SpiritDatabase.ShopItems = {}
for _, shopId in ipairs(ItemCatalog.ShopIds) do
	SpiritDatabase.ShopItems[shopId] = ItemCatalog.ById[shopId]
end

SpiritDatabase.EvolutionRules = {
	[1] = {EvolvedId = 101, RequiredLevel = 10, RequiredItems = {{Id = 101, Quantity = 5}}, RequiredBattles = 10},
	[2] = {EvolvedId = 102, RequiredLevel = 12, RequiredItems = {{Id = 102, Quantity = 5}}, RequiredBattles = 15},
	[3] = {EvolvedId = 103, RequiredLevel = 15, RequiredItems = {{Id = 103, Quantity = 5}}, RequiredBattles = 20},
	[4] = {EvolvedId = 104, RequiredLevel = 18, RequiredItems = {{Id = 104, Quantity = 5}}, RequiredBattles = 25},
	[5] = {EvolvedId = 105, RequiredLevel = 20, RequiredItems = {{Id = 105, Quantity = 5}}, RequiredBattles = 30},
}

function SpiritDatabase.Get(id)
	return SpiritDatabase.Spirits[id]
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
	local element = attacker.Element
	local damage = (skill.Damage or 10) + ((attacker.BaseStats and attacker.BaseStats.Attack or 10) * 0.5)
	damage = damage - ((defender.BaseStats and defender.BaseStats.Defense or 0) * 0.3)
	local elementBonus = 1
	local chart = SpiritDatabase.ElementChart[element]
	if chart then
		if table.find(chart.Strong, defender.Element) then
			elementBonus = 1.5
		elseif table.find(chart.Weak, defender.Element) then
			elementBonus = 0.7
		end
	end
	damage = damage * elementBonus * (math.random(85, 115) / 100)
	return math.max(1, math.floor(damage))
end

return SpiritDatabase
