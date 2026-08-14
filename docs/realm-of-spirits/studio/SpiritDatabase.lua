-- Shared spirit database for Realm of Spirits
-- Skills: SkillIds → SkillCatalog; shop → ItemCatalog
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local realmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local SkillCatalog = require(realmFolder:WaitForChild("SkillCatalog"))
local ItemCatalog = require(realmFolder:WaitForChild("ItemCatalog"))

local SpiritDatabase = {}

SpiritDatabase.Spirits = {
	[11] = {
		MovementType = "Walk",
		Code = "1.1", LegacyId = 1, CrystalItemId = 101, Id = 11, Name = "Огненный Кот", Element = "Fire", Rarity = "Common",
		Color = Color3.fromRGB(255, 100, 50), Size = 3,
		BaseStats = {HP = 110, Attack = 18, Defense = 12, Speed = 12},
		SkillIds = {1, 2},
		CatchRate = 0.65,
	},
	[42] = {
		Code = "4.2", LegacyId = 2, CrystalItemId = 102, Id = 42, Name = "Ледяная Птица", Element = "Ice", Rarity = "Uncommon",
		Color = Color3.fromRGB(100, 200, 255), Size = 2.5,
		BaseStats = {HP = 85, Attack = 14, Defense = 9, Speed = 18},
		SkillIds = {11, 12},
		CatchRate = 0.45,
	},
	[33] = {
		Code = "3.3", LegacyId = 3, CrystalItemId = 103, Id = 33, Name = "Теневой Пёс", Element = "Dark", Rarity = "Rare",
		Color = Color3.fromRGB(100, 50, 150), Size = 3.5,
		BaseStats = {HP = 120, Attack = 18, Defense = 12, Speed = 15},
		SkillIds = {21, 22},
		CatchRate = 0.22,
	},
	[32] = {
		MovementType = "Walk",
		Code = "3.2", LegacyId = 4, CrystalItemId = 104, Id = 32, Name = "Грозовой Дракон", Element = "Lightning", Rarity = "Epic",
		Color = Color3.fromRGB(200, 200, 100), Size = 5,
		BaseStats = {HP = 150, Attack = 22, Defense = 15, Speed = 20},
		SkillIds = {31, 32},
		CatchRate = 0.05,
	},
	[13] = {
		Code = "1.3", LegacyId = 5, CrystalItemId = 105, Id = 13, Name = "Световой Единорог", Element = "Light", Rarity = "Legendary",
		Color = Color3.fromRGB(255, 255, 200), Size = 4,
		BaseStats = {HP = 180, Attack = 25, Defense = 20, Speed = 16},
		SkillIds = {41, 42},
		CatchRate = 0.01,
	},
	[41] = {
		MovementType = "Swim",
		Code = "4.1", LegacyId = 6, CrystalItemId = 106, Id = 41, Name = "Водный Карп", Element = "Water", Rarity = "Uncommon",
		Color = Color3.fromRGB(25, 40, 85), Size = 3.2,
		BaseStats = {HP = 100, Attack = 15, Defense = 14, Speed = 14},
		SkillIds = {51, 52},
		CatchRate = 0.4,
	},
	[21] = {
		MovementType = "Walk",
		Code = "2.1", LegacyId = 7, CrystalItemId = 107, Id = 21, Name = "Каменный Голем", Element = "Earth", Rarity = "Uncommon",
		Color = Color3.fromRGB(140, 110, 70), Size = 3.8,
		BaseStats = {HP = 130, Attack = 16, Defense = 20, Speed = 9},
		SkillIds = {61, 62},
		CatchRate = 0.38,
	},
	[12] = {
		MovementType = "Walk",
		Code = "1.2", LegacyId = 8, CrystalItemId = 108, Id = 12, Name = "Пепельный Саламандр", Element = "Fire", Rarity = "Uncommon",
		Color = Color3.fromRGB(220, 90, 40), Size = 3.4,
		BaseStats = {HP = 105, Attack = 19, Defense = 12, Speed = 15},
		SkillIds = {71, 72},
		CatchRate = 0.42,
	},
	[31] = {
		MovementType = "Walk",
		Code = "3.1", LegacyId = 9, CrystalItemId = 109, Id = 31, Name = "Ветряной Лис", Element = "Wind", Rarity = "Uncommon",
		Color = Color3.fromRGB(120, 200, 180), Size = 3.2,
		BaseStats = {HP = 95, Attack = 18, Defense = 10, Speed = 20},
		SkillIds = {81, 82},
		CatchRate = 0.40,
	},
	[22] = {
		MovementType = "Walk",
		Code = "2.2", LegacyId = 10, CrystalItemId = 110, Id = 22, Name = "Моховой Олень", Element = "Nature", Rarity = "Uncommon",
		Color = Color3.fromRGB(80, 160, 70), Size = 3.5,
		BaseStats = {HP = 115, Attack = 17, Defense = 14, Speed = 14},
		SkillIds = {91, 92},
		CatchRate = 0.40,
	},
	[43] = {
		MovementType = "Walk",
		Code = "4.3", LegacyId = 11, CrystalItemId = 111, Id = 43, Name = "Лунный Кролик", Element = "Moon", Rarity = "Uncommon",
		Color = Color3.fromRGB(200, 210, 255), Size = 3.2,
		BaseStats = {HP = 100, Attack = 18, Defense = 11, Speed = 19},
		SkillIds = {101, 102},
		CatchRate = 0.40,
	},
	[24] = {
		MovementType = "Walk",
		Code = "2.4", LegacyId = 12, CrystalItemId = 112, Id = 24, Name = "Ядовитая Гадюка", Element = "Poison", Rarity = "Uncommon",
		Color = Color3.fromRGB(90, 180, 60), Size = 3.3,
		BaseStats = {HP = 98, Attack = 19, Defense = 12, Speed = 17},
		SkillIds = {111, 112},
		CatchRate = 0.39,
	},
	[25] = {
		MovementType = "Walk",
		Code = "2.5", LegacyId = 13, CrystalItemId = 113, Id = 25, Name = "Пустынный Скорпион", Element = "Sand", Rarity = "Uncommon",
		Color = Color3.fromRGB(210, 170, 90), Size = 3.4,
		BaseStats = {HP = 105, Attack = 20, Defense = 14, Speed = 15},
		SkillIds = {114, 115},
		CatchRate = 0.37,
	},
	[23] = {
		MovementType = "Walk",
		Code = "2.3", LegacyId = 14, CrystalItemId = 114, Id = 23, Name = "Стальной Жук", Element = "Metal", Rarity = "Uncommon",
		Color = Color3.fromRGB(140, 155, 175), Size = 3.5,
		BaseStats = {HP = 110, Attack = 21, Defense = 16, Speed = 13},
		SkillIds = {117, 118},
		CatchRate = 0.36,
	},
	[26] = {
		MovementType = "Walk",
		Code = "2.6", LegacyId = 15, CrystalItemId = 115, Id = 26, Name = "Хрустальный Лис", Element = "Crystal", Rarity = "Uncommon",
		Color = Color3.fromRGB(180, 220, 255), Size = 3.4,
		BaseStats = {HP = 108, Attack = 22, Defense = 14, Speed = 18},
		SkillIds = {120, 121},
		CatchRate = 0.35,
	},
	[14] = {
		MovementType = "Walk",
		Code = "1.4", LegacyId = 16, CrystalItemId = 116, Id = 14, Name = "Лавовый Краб", Element = "Magma", Rarity = "Uncommon",
		Color = Color3.fromRGB(255, 90, 40), Size = 3.5,
		BaseStats = {HP = 112, Attack = 23, Defense = 15, Speed = 14},
		SkillIds = {123, 124},
		CatchRate = 0.34,
	},
	[44] = {
		MovementType = "Fly",
		Code = "4.4", LegacyId = 17, CrystalItemId = 117, Id = 44, Name = "Туманный Дух", Element = "Mist", Rarity = "Uncommon",
		Color = Color3.fromRGB(160, 190, 220), Size = 3.3,
		BaseStats = {HP = 100, Attack = 20, Defense = 12, Speed = 20},
		SkillIds = {126, 127},
		CatchRate = 0.34,
	},
	[34] = {
		MovementType = "Fly",
		Code = "3.4", LegacyId = 18, CrystalItemId = 118, Id = 34, Name = "Небесный Сокол", Element = "Sky", Rarity = "Uncommon",
		Color = Color3.fromRGB(180, 210, 255), Size = 3.4,
		BaseStats = {HP = 98, Attack = 21, Defense = 11, Speed = 22},
		SkillIds = {129, 130},
		CatchRate = 0.34,
	},
	[1011] = {Code = "1.1e", LegacyId = 101, CrystalItemId = 101, Id = 1011, Name = "Огненный Тигр", Element = "Fire", Rarity = "Rare", BaseStats = {HP = 150, Attack = 25, Defense = 15, Speed = 18}, SkillIds = {3, 1, 2}, CatchRate = 0.1},
	[1042] = {MovementType = "Fly", Code = "4.2e", LegacyId = 102, CrystalItemId = 102, Id = 1042, Name = "Ледяной Феникс", Element = "Ice", Rarity = "Rare", BaseStats = {HP = 120, Attack = 22, Defense = 12, Speed = 28}, SkillIds = {13, 11, 12}, CatchRate = 0.08},
	[1033] = {Code = "3.3e", LegacyId = 103, CrystalItemId = 103, Id = 1033, Name = "Теневой Волк", Element = "Dark", Rarity = "Epic", BaseStats = {HP = 180, Attack = 30, Defense = 18, Speed = 22}, SkillIds = {23, 21, 22}, CatchRate = 0.05},
	[1032] = {MovementType = "Fly", Code = "3.2e", LegacyId = 104, CrystalItemId = 104, Id = 1032, Name = "Грозовой Левиафан", Element = "Lightning", Rarity = "Legendary", BaseStats = {HP = 220, Attack = 35, Defense = 22, Speed = 30}, SkillIds = {33, 31, 32}, CatchRate = 0.02},
	[1013] = {Code = "1.3e", LegacyId = 105, CrystalItemId = 105, Id = 1013, Name = "Световой Альфа", Element = "Light", Rarity = "Legendary", BaseStats = {HP = 280, Attack = 40, Defense = 28, Speed = 25}, SkillIds = {43, 41, 42}, CatchRate = 0.01},
	[1041] = {Code = "4.1e", LegacyId = 106, CrystalItemId = 106, Id = 1041, Name = "Цунами-Карп", Element = "Water", Rarity = "Rare", Color = Color3.fromRGB(30, 100, 200), Size = 4.5, BaseStats = {HP = 160, Attack = 24, Defense = 20, Speed = 16}, SkillIds = {53, 51, 52}, CatchRate = 0.08},
	[1021] = {MovementType = "Walk", Code = "2.1e", LegacyId = 107, CrystalItemId = 107, Id = 1021, Name = "Горный Титан", Element = "Earth", Rarity = "Rare", Color = Color3.fromRGB(160, 130, 80), Size = 5.2, BaseStats = {HP = 200, Attack = 26, Defense = 28, Speed = 11}, SkillIds = {63, 61, 62}, CatchRate = 0.07},
	[1012] = {MovementType = "Walk", Code = "1.2e", LegacyId = 108, CrystalItemId = 108, Id = 1012, Name = "Инферно-Дракон", Element = "Fire", Rarity = "Rare", Color = Color3.fromRGB(255, 80, 30), Size = 5.0, BaseStats = {HP = 170, Attack = 28, Defense = 18, Speed = 17}, SkillIds = {73, 71, 72}, CatchRate = 0.07},
	[1031] = {MovementType = "Walk", Code = "3.1e", LegacyId = 109, CrystalItemId = 109, Id = 1031, Name = "Буревой Кицунэ", Element = "Wind", Rarity = "Rare", Color = Color3.fromRGB(90, 220, 200), Size = 4.8, BaseStats = {HP = 155, Attack = 27, Defense = 14, Speed = 24}, SkillIds = {83, 81, 82}, CatchRate = 0.07},
	[1022] = {MovementType = "Walk", Code = "2.2e", LegacyId = 110, CrystalItemId = 110, Id = 1022, Name = "Древний Энт", Element = "Nature", Rarity = "Rare", Color = Color3.fromRGB(60, 130, 55), Size = 5.4, BaseStats = {HP = 190, Attack = 24, Defense = 26, Speed = 12}, SkillIds = {93, 91, 92}, CatchRate = 0.07},
	[1043] = {MovementType = "Walk", Code = "4.3e", LegacyId = 111, CrystalItemId = 111, Id = 1043, Name = "Цукуёми-Страж", Element = "Moon", Rarity = "Rare", Color = Color3.fromRGB(160, 175, 255), Size = 5.0, BaseStats = {HP = 165, Attack = 27, Defense = 16, Speed = 22}, SkillIds = {103, 101, 102}, CatchRate = 0.07},
	[1024] = {MovementType = "Walk", Code = "2.4e", LegacyId = 112, CrystalItemId = 112, Id = 1024, Name = "Василиск-Гидра", Element = "Poison", Rarity = "Rare", Color = Color3.fromRGB(70, 150, 45), Size = 5.2, BaseStats = {HP = 175, Attack = 28, Defense = 18, Speed = 16}, SkillIds = {113, 111, 112}, CatchRate = 0.07},
	[1025] = {MovementType = "Walk", Code = "2.5e", LegacyId = 113, CrystalItemId = 113, Id = 1025, Name = "Песчаный Император", Element = "Sand", Rarity = "Rare", Color = Color3.fromRGB(190, 150, 70), Size = 5.3, BaseStats = {HP = 185, Attack = 29, Defense = 20, Speed = 15}, SkillIds = {116, 114, 115}, CatchRate = 0.07},
	[1023] = {MovementType = "Walk", Code = "2.3e", LegacyId = 114, CrystalItemId = 114, Id = 1023, Name = "Железный Колосс", Element = "Metal", Rarity = "Rare", Color = Color3.fromRGB(100, 115, 135), Size = 5.5, BaseStats = {HP = 195, Attack = 30, Defense = 24, Speed = 12}, SkillIds = {119, 117, 118}, CatchRate = 0.07},
	[1026] = {MovementType = "Walk", Code = "2.6e", LegacyId = 115, CrystalItemId = 115, Id = 1026, Name = "Призматический Страж", Element = "Crystal", Rarity = "Rare", Color = Color3.fromRGB(140, 200, 255), Size = 5.2, BaseStats = {HP = 180, Attack = 31, Defense = 20, Speed = 20}, SkillIds = {122, 120, 121}, CatchRate = 0.07},
	[1014] = {MovementType = "Walk", Code = "1.4e", LegacyId = 116, CrystalItemId = 116, Id = 1014, Name = "Вулканический Титан", Element = "Magma", Rarity = "Rare", Color = Color3.fromRGB(220, 50, 20), Size = 5.4, BaseStats = {HP = 190, Attack = 32, Defense = 22, Speed = 14}, SkillIds = {125, 123, 124}, CatchRate = 0.06},
	[1044] = {MovementType = "Fly", Code = "4.4e", LegacyId = 117, CrystalItemId = 117, Id = 1044, Name = "Призрачный Кирин", Element = "Mist", Rarity = "Rare", Color = Color3.fromRGB(120, 160, 210), Size = 5.1, BaseStats = {HP = 170, Attack = 30, Defense = 18, Speed = 24}, SkillIds = {128, 126, 127}, CatchRate = 0.06},
	[1034] = {MovementType = "Fly", Code = "3.4e", LegacyId = 118, CrystalItemId = 118, Id = 1034, Name = "Небесный Феникс", Element = "Sky", Rarity = "Rare", Color = Color3.fromRGB(140, 190, 255), Size = 5.2, BaseStats = {HP = 165, Attack = 31, Defense = 16, Speed = 26}, SkillIds = {131, 129, 130}, CatchRate = 0.06},
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
	[11] = { "Fire", "Fire" },
	[1011] = { "Fire", "Fire" },
	[12] = { "Fire", "Ash" },
	[1012] = { "Fire", "Ash" },
	[13] = { "Fire", "Light" },
	[1013] = { "Fire", "Light" },
	[41] = { "Water", "Water" },
	[1041] = { "Water", "Water" },
	[42] = { "Water", "Ice" },
	[1042] = { "Water", "Ice" },
	[43] = { "Water", "Moon" },
	[1043] = { "Water", "Moon" },
	[21] = { "Earth", "Earth" },
	[1021] = { "Earth", "Earth" },
	[22] = { "Earth", "Nature" },
	[1022] = { "Earth", "Nature" },
	[25] = { "Earth", "Sand" },
	[1025] = { "Earth", "Sand" },
	[23] = { "Earth", "Metal" },
	[1023] = { "Earth", "Metal" },
	[26] = { "Earth", "Crystal" },
	[1026] = { "Earth", "Crystal" },
	[14] = { "Fire", "Magma" },
	[1014] = { "Fire", "Magma" },
	[44] = { "Water", "Mist" },
	[1044] = { "Water", "Mist" },
	[34] = { "Wind", "Sky" },
	[1034] = { "Wind", "Sky" },
	[24] = { "Earth", "Poison" },
	[1024] = { "Earth", "Poison" },
	[31] = { "Wind", "Wind" },
	[1031] = { "Wind", "Wind" },
	[32] = { "Wind", "Storm" },
	[1032] = { "Wind", "Storm" },
	[33] = { "Wind", "Dark" },
	[1033] = { "Wind", "Dark" },
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
	Magma = "Лава",
	Mist = "Туман",
	Sky = "Небо",
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

-- Иерархия канона 4×4: Primary → линия (Aspect) → база → эво
-- IsCore = Aspect совпадает с Primary («основной дух стихии»)
SpiritDatabase.HierarchyOrder = { "Fire", "Earth", "Wind", "Water" }

SpiritDatabase.Hierarchy = {
	Fire = {
		{ Aspect = "Fire", Code = "1.1", BaseId = 11, EvoId = 1011, IsCore = true },
		{ Aspect = "Ash", Code = "1.2", BaseId = 12, EvoId = 1012, IsCore = false },
		{ Aspect = "Light", Code = "1.3", BaseId = 13, EvoId = 1013, IsCore = false },
		{ Aspect = "Magma", Code = "1.4", BaseId = 14, EvoId = 1014, IsCore = false },
	},
	Earth = {
		{ Aspect = "Earth", Code = "2.1", BaseId = 21, EvoId = 1021, IsCore = true },
		{ Aspect = "Nature", Code = "2.2", BaseId = 22, EvoId = 1022, IsCore = false },
		{ Aspect = "Metal", Code = "2.3", BaseId = 23, EvoId = 1023, IsCore = false },
		{ Aspect = "Poison", Code = "2.4", BaseId = 24, EvoId = 1024, IsCore = false },
	},
	Wind = {
		{ Aspect = "Wind", Code = "3.1", BaseId = 31, EvoId = 1031, IsCore = true },
		{ Aspect = "Storm", Code = "3.2", BaseId = 32, EvoId = 1032, IsCore = false },
		{ Aspect = "Dark", Code = "3.3", BaseId = 33, EvoId = 1033, IsCore = false },
		{ Aspect = "Sky", Code = "3.4", BaseId = 34, EvoId = 1034, IsCore = false },
	},
	Water = {
		{ Aspect = "Water", Code = "4.1", BaseId = 41, EvoId = 1041, IsCore = true },
		{ Aspect = "Ice", Code = "4.2", BaseId = 42, EvoId = 1042, IsCore = false },
		{ Aspect = "Moon", Code = "4.3", BaseId = 43, EvoId = 1043, IsCore = false },
		{ Aspect = "Mist", Code = "4.4", BaseId = 44, EvoId = 1044, IsCore = false },
	},
}

-- Архив (вне канона spawn): Primary всё ещё Earth, но не в Hierarchy
SpiritDatabase.DeprecatedHierarchy = {
	Earth = {
		{ Aspect = "Sand", Code = "2.5", BaseId = 25, EvoId = 1025, IsCore = false },
		{ Aspect = "Crystal", Code = "2.6", BaseId = 26, EvoId = 1026, IsCore = false },
	},
}

for _, primary in ipairs(SpiritDatabase.HierarchyOrder) do
	local lines = SpiritDatabase.Hierarchy[primary]
	if lines then
		for _, line in ipairs(lines) do
			local base = SpiritDatabase.Spirits[line.BaseId]
			local evo = SpiritDatabase.Spirits[line.EvoId]
			if base then
				base.IsCoreLine = line.IsCore == true
				base.LineAspect = line.Aspect
			end
			if evo then
				evo.IsCoreLine = line.IsCore == true
				evo.LineAspect = line.Aspect
			end
		end
	end
end

--- Flat list of hierarchy rows for Dex / UI / docs export.
--- @param includeDeprecated boolean?
function SpiritDatabase.GetHierarchy(includeDeprecated)
	local rows = {}
	for _, primary in ipairs(SpiritDatabase.HierarchyOrder) do
		local lines = SpiritDatabase.Hierarchy[primary]
		if lines then
			for _, line in ipairs(lines) do
				local base = SpiritDatabase.Spirits[line.BaseId]
				local evo = SpiritDatabase.Spirits[line.EvoId]
				table.insert(rows, {
					Primary = primary,
					PrimaryRu = SpiritDatabase.PrimaryLabelsRu[primary] or primary,
					Aspect = line.Aspect,
					AspectRu = SpiritDatabase.AspectLabelsRu[line.Aspect] or line.Aspect,
					Code = line.Code or SpiritDatabase.GetCode(line.BaseId),
					IsCore = line.IsCore == true,
					BaseId = line.BaseId,
					BaseName = base and base.Name or ("#" .. tostring(line.BaseId)),
					EvoId = line.EvoId,
					EvoName = evo and evo.Name or ("#" .. tostring(line.EvoId)),
					Deprecated = false,
				})
			end
		end
		if includeDeprecated then
			local dep = SpiritDatabase.DeprecatedHierarchy[primary]
			if dep then
				for _, line in ipairs(dep) do
					local base = SpiritDatabase.Spirits[line.BaseId]
					local evo = SpiritDatabase.Spirits[line.EvoId]
					table.insert(rows, {
						Primary = primary,
						PrimaryRu = SpiritDatabase.PrimaryLabelsRu[primary] or primary,
						Aspect = line.Aspect,
						AspectRu = SpiritDatabase.AspectLabelsRu[line.Aspect] or line.Aspect,
						IsCore = false,
						BaseId = line.BaseId,
						BaseName = base and base.Name or ("#" .. tostring(line.BaseId)),
						EvoId = line.EvoId,
						EvoName = evo and evo.Name or ("#" .. tostring(line.EvoId)),
						Deprecated = true,
					})
				end
			end
		end
	end
	return rows
end

--- Основной (core) дух Primary: база линии Aspect==Primary.
function SpiritDatabase.GetCoreSpiritId(primary)
	local lines = SpiritDatabase.Hierarchy[primary]
	if not lines then
		return nil
	end
	for _, line in ipairs(lines) do
		if line.IsCore then
			return line.BaseId
		end
	end
	return nil
end

function SpiritDatabase.IsCoreLine(spiritOrId)
	local spirit = type(spiritOrId) == "table" and spiritOrId or SpiritDatabase.Spirits[spiritOrId]
	if not spirit then
		return false
	end
	if spirit.IsCoreLine ~= nil then
		return spirit.IsCoreLine == true
	end
	local primary = SpiritDatabase.GetPrimary(spirit)
	local aspect = SpiritDatabase.GetAspect(spirit)
	return primary == aspect
end

-- Only purchasable shop rows (not evolution materials)
SpiritDatabase.ShopItems = {}
for _, shopId in ipairs(ItemCatalog.ShopIds) do
	SpiritDatabase.ShopItems[shopId] = ItemCatalog.ById[shopId]
end

SpiritDatabase.EvolutionRules = {
	-- RequiredBond: Spirit Resonance track B (Haven care)
	[11] = {EvolvedId = 1011, RequiredLevel = 10, RequiredBond = 3, RequiredItems = {{Id = 101, Quantity = 5}}, RequiredBattles = 10},
	[42] = {EvolvedId = 1042, RequiredLevel = 12, RequiredBond = 3, RequiredItems = {{Id = 102, Quantity = 5}}, RequiredBattles = 15},
	[33] = {EvolvedId = 1033, RequiredLevel = 15, RequiredBond = 3, RequiredItems = {{Id = 103, Quantity = 5}}, RequiredBattles = 20},
	[32] = {EvolvedId = 1032, RequiredLevel = 18, RequiredBond = 4, RequiredItems = {{Id = 104, Quantity = 5}}, RequiredBattles = 25},
	[13] = {EvolvedId = 1013, RequiredLevel = 20, RequiredBond = 4, RequiredItems = {{Id = 105, Quantity = 5}}, RequiredBattles = 30},
	[41] = {EvolvedId = 1041, RequiredLevel = 12, RequiredBond = 3, RequiredItems = {{Id = 106, Quantity = 5}}, RequiredBattles = 12},
	[21] = {EvolvedId = 1021, RequiredLevel = 14, RequiredBond = 3, RequiredItems = {{Id = 107, Quantity = 5}}, RequiredBattles = 14},
	[12] = {EvolvedId = 1012, RequiredLevel = 13, RequiredBond = 3, RequiredItems = {{Id = 108, Quantity = 5}}, RequiredBattles = 13},
	[31] = {EvolvedId = 1031, RequiredLevel = 13, RequiredBond = 3, RequiredItems = {{Id = 109, Quantity = 5}}, RequiredBattles = 13},
	[22] = {EvolvedId = 1022, RequiredLevel = 14, RequiredBond = 3, RequiredItems = {{Id = 110, Quantity = 5}}, RequiredBattles = 14},
	[43] = {EvolvedId = 1043, RequiredLevel = 14, RequiredBond = 3, RequiredItems = {{Id = 111, Quantity = 5}}, RequiredBattles = 14},
	[24] = {EvolvedId = 1024, RequiredLevel = 14, RequiredBond = 3, RequiredItems = {{Id = 112, Quantity = 5}}, RequiredBattles = 14},
	[25] = {EvolvedId = 1025, RequiredLevel = 14, RequiredBond = 3, RequiredItems = {{Id = 113, Quantity = 5}}, RequiredBattles = 14},
	[23] = {EvolvedId = 1023, RequiredLevel = 14, RequiredBond = 3, RequiredItems = {{Id = 114, Quantity = 5}}, RequiredBattles = 14},
	[26] = {EvolvedId = 1026, RequiredLevel = 14, RequiredBond = 3, RequiredItems = {{Id = 115, Quantity = 5}}, RequiredBattles = 14},
	[14] = {EvolvedId = 1014, RequiredLevel = 14, RequiredBond = 3, RequiredItems = {{Id = 116, Quantity = 5}}, RequiredBattles = 14},
	[44] = {EvolvedId = 1044, RequiredLevel = 14, RequiredBond = 3, RequiredItems = {{Id = 117, Quantity = 5}}, RequiredBattles = 14},
	[34] = {EvolvedId = 1034, RequiredLevel = 14, RequiredBond = 3, RequiredItems = {{Id = 118, Quantity = 5}}, RequiredBattles = 14},
}

-- Soft-deprecate: not in 4×4 canon spawn (data kept for old hunts/saves)
SpiritDatabase.DeprecatedSpiritIds = {
	[25] = true, [1025] = true, -- Sand
	[26] = true, [1026] = true, -- Crystal
}


SpiritDatabase.LegacyToId = {
	[1] = 11,
	[2] = 42,
	[3] = 33,
	[4] = 32,
	[5] = 13,
	[6] = 41,
	[7] = 21,
	[8] = 12,
	[9] = 31,
	[10] = 22,
	[11] = 43,
	[12] = 24,
	[13] = 25,
	[14] = 23,
	[15] = 26,
	[16] = 14,
	[17] = 44,
	[18] = 34,
	[101] = 1011,
	[102] = 1042,
	[103] = 1033,
	[104] = 1032,
	[105] = 1013,
	[106] = 1041,
	[107] = 1021,
	[108] = 1012,
	[109] = 1031,
	[110] = 1022,
	[111] = 1043,
	[112] = 1024,
	[113] = 1025,
	[114] = 1023,
	[115] = 1026,
	[116] = 1014,
	[117] = 1044,
	[118] = 1034,
}

SpiritDatabase.CodeByBaseId = {
	[11] = "1.1",
	[12] = "1.2",
	[13] = "1.3",
	[14] = "1.4",
	[21] = "2.1",
	[22] = "2.2",
	[23] = "2.3",
	[24] = "2.4",
	[25] = "2.5",
	[26] = "2.6",
	[31] = "3.1",
	[32] = "3.2",
	[33] = "3.3",
	[34] = "3.4",
	[41] = "4.1",
	[42] = "4.2",
	[43] = "4.3",
	[44] = "4.4",
}

SpiritDatabase.PrimaryIndex = { Fire = 1, Earth = 2, Wind = 3, Water = 4 }
SpiritDatabase.PrimaryByIndex = { [1] = "Fire", [2] = "Earth", [3] = "Wind", [4] = "Water" }

function SpiritDatabase.MigrateId(id)
	local n = tonumber(id)
	if not n then return id end
	if SpiritDatabase.Spirits[n] then return n end
	return SpiritDatabase.LegacyToId[n] or n
end

function SpiritDatabase.GetCode(spiritOrId)
	local raw = type(spiritOrId) == "table" and spiritOrId.Id or spiritOrId
	local id = SpiritDatabase.MigrateId(raw)
	local spirit = type(spiritOrId) == "table" and spiritOrId or SpiritDatabase.Spirits[id]
	if spirit and spirit.Code then return spirit.Code end
	if type(id) ~= "number" then return "?" end
	if id >= 1000 then
		local base = id - 1000
		local c = SpiritDatabase.CodeByBaseId[base]
		return c and (c .. "e") or tostring(id)
	end
	return SpiritDatabase.CodeByBaseId[id] or tostring(id)
end

function SpiritDatabase.IsCanonical(id)
	return SpiritDatabase.Spirits[id] ~= nil and not SpiritDatabase.DeprecatedSpiritIds[id]
end

function SpiritDatabase.Get(id)
	return SpiritDatabase.Spirits[SpiritDatabase.MigrateId(id)]
end

function SpiritDatabase.GetPrimary(spiritOrId)
	local spirit = type(spiritOrId) == "table" and spiritOrId or SpiritDatabase.Spirits[spiritOrId]
	if not spirit then
		return "Earth"
	end
	return spirit.HybridPrimary or spirit.PrimaryElement or spirit.Element or "Earth"
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

--- Battle-start agency tip: your Primary vs enemy + cycle + ElementPassives
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
	local tip = string.format("%s vs %s — %s · Огонь→Земля→Ветер→Вода→Огонь", aRu, dRu, verdict)
	local passTip = SkillCatalog.FormatElementPassivesTip and SkillCatalog.FormatElementPassivesTip(atkEl)
	if passTip then
		tip = tip .. " · " .. passTip
	end
	return tip, mult, tag
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
	if type(spirit.Skills[11]) == "table" then
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
