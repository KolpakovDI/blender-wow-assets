-- ============================================
-- Realm of Spirits - Evolution System
-- Система эволюции духов
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SpiritDatabase = require(ReplicatedStorage:WaitForChild("RealmOfSpirits"):WaitForChild("SpiritDatabase"))

-- ============================================
-- Конфигурация эволюции
-- ============================================

-- Таблица эволюций: [SpiritId] = {EvolutionConditions, EvolvedSpiritId, NewStats}
local EvolutionDatabase = SpiritDatabase.EvolutionRules or {
	-- Огненный Кот → Огненный Тигр (уровень 10)
	[1] = {
		EvolvedId = 101,
		RequiredLevel = 10, RequiredBond = 3,
		RequiredItems = {
			{Id = 101, Quantity = 5}, -- Огненные кристаллы
		},
		RequiredBattles = 10, -- Количество побед в боях
		NewStats = {
			HP = 150,
			Attack = 25,
			Defense = 15,
			Speed = 18
		},
		NewSkills = {"Огненный коготь", "Пламенный всплеск", "Огненный шторм"},
		NewName = "Огненный Тигр"
	},

	-- Ледяная Птица → Ледяной Феникс (уровень 12)
	[2] = {
		EvolvedId = 102,
		RequiredLevel = 12, RequiredBond = 3,
		RequiredItems = {
			{Id = 102, Quantity = 5}, -- Ледяные кристаллы
		},
		RequiredBattles = 15,
		NewStats = {
			HP = 120,
			Attack = 22,
			Defense = 12,
			Speed = 28
		},
		NewSkills = {"Ледяная стрела", "Морозный ветер", "Ледяной шторм"},
		NewName = "Ледяной Феникс"
	},

	-- Теневой Пёс → Теневой Волк (уровень 15)
	[3] = {
		EvolvedId = 103,
		RequiredLevel = 15, RequiredBond = 3,
		RequiredItems = {
			{Id = 103, Quantity = 5}, -- Тёмные кристаллы
		},
		RequiredBattles = 20,
		NewStats = {
			HP = 180,
			Attack = 30,
			Defense = 18,
			Speed = 22
		},
		NewSkills = {"Теневой укус", "Ночная аура", "Теневой шторм"},
		NewName = "Теневой Волк"
	},

	-- Грозовой Дракон → Грозовой Левиафан (уровень 18)
	[4] = {
		EvolvedId = 104,
		RequiredLevel = 18, RequiredBond = 4,
		RequiredItems = {
			{Id = 104, Quantity = 5}, -- Грозовые кристаллы
		},
		RequiredBattles = 25,
		NewStats = {
			HP = 220,
			Attack = 35,
			Defense = 22,
			Speed = 30
		},
		NewSkills = {"Молниеносный удар", "Грозовой щит", "Грозовой шторм"},
		NewName = "Грозовой Левиафан"
	},

	-- Световой Единорог → Световой Альфа (уровень 20)
	[5] = {
		EvolvedId = 105,
		RequiredLevel = 20, RequiredBond = 4,
		RequiredItems = {
			{Id = 105, Quantity = 5}, -- Световые кристаллы
		},
		RequiredBattles = 30,
		NewStats = {
			HP = 280,
			Attack = 40,
			Defense = 28,
			Speed = 25
		},
		NewSkills = {"Световой луч", "Божественная благодать", "Световой шторм"},
		NewName = "Световой Альфа"
	}
}

-- ============================================
-- База данных эволюционированных духов
-- ============================================

local EvolvedSpiritDatabase = {
	[101] = {
		Id = 101,
		Name = "Огненный Тигр",
		Element = "Fire",
		Rarity = "Rare",
		BaseStats = {
			HP = 150,
			Attack = 25,
			Defense = 15,
			Speed = 18
		},
		Skills = {"Огненный коготь", "Пламенный всплеск", "Огненный шторм"},
		CatchRate = 0.1,
		Description = "Эволюция Огненного Кота. Мощнее и быстрее."
	},

	[102] = {
		Id = 102,
		Name = "Ледяной Феникс",
		Element = "Ice",
		Rarity = "Rare",
		BaseStats = {
			HP = 120,
			Attack = 22,
			Defense = 12,
			Speed = 28
		},
		Skills = {"Ледяная стрела", "Морозный ветер", "Ледяной шторм"},
		CatchRate = 0.08,
		Description = "Эволюция Ледяной Птицы. Невероятно быстр."
	},

	[103] = {
		Id = 103,
		Name = "Теневой Волк",
		Element = "Dark",
		Rarity = "Epic",
		BaseStats = {
			HP = 180,
			Attack = 30,
			Defense = 18,
			Speed = 22
		},
		Skills = {"Теневой укус", "Ночная аура", "Теневой шторм"},
		CatchRate = 0.05,
		Description = "Эволюция Теневого Пса. Мастер теней."
	},

	[104] = {
		Id = 104,
		Name = "Грозовой Левиафан",
		Element = "Lightning",
		Rarity = "Legendary",
		BaseStats = {
			HP = 220,
			Attack = 35,
			Defense = 22,
			Speed = 30
		},
		Skills = {"Молниеносный удар", "Грозовой щит", "Грозовой шторм"},
		CatchRate = 0.02,
		Description = "Эволюция Грозового Дракона. Владыка бурь."
	},

	[105] = {
		Id = 105,
		Name = "Световой Альфа",
		Element = "Light",
		Rarity = "Legendary",
		BaseStats = {
			HP = 280,
			Attack = 40,
			Defense = 28,
			Speed = 25
		},
		Skills = {"Световой луч", "Божественная благодать", "Световой шторм"},
		CatchRate = 0.01,
		Description = "Эволюция Светового Единорога. Божественная сила."
	}
}

-- ============================================
-- Evolution System
-- ============================================

local EvolutionSystem = {}
EvolutionSystem.__index = EvolutionSystem

function EvolutionSystem.new()
	local self = setmetatable({}, EvolutionSystem)
	return self
end

-- ============================================
-- Проверка условий эволюции
-- ============================================

function EvolutionSystem:CanEvolve(spirit, playerData)
	if type(spirit) ~= "table" or type(playerData) ~= "table" then
		return false, "Дух не найден"
	end
	local evolutionData = EvolutionDatabase[spirit.Id]
	if not evolutionData then
		return false, "Этот дух не может эволюционировать"
	end

	playerData.Inventory = playerData.Inventory or {}
	playerData.Stats = playerData.Stats or {}

	-- Проверяем уровень
	local lvl = tonumber(spirit.Level) or 1
	if lvl < (tonumber(evolutionData.RequiredLevel) or 1) then
		return false, "Нужен уровень " .. evolutionData.RequiredLevel .. " (текущий: " .. lvl .. ")"
	end

	-- Spirit Resonance: RequiredBond
	local needBond = tonumber(evolutionData.RequiredBond) or 0
	if needBond > 0 then
		local bond = tonumber(spirit.Bond) or 0
		if bond < needBond then
			return false, "Нужен резонанс Bond " .. needBond .. " (текущий: " .. bond .. ")"
		end
	end

	-- Проверяем предметы
	if evolutionData.RequiredItems then
		for _, requiredItem in ipairs(evolutionData.RequiredItems) do
			local hasItem = false
			for _, inventoryItem in ipairs(playerData.Inventory) do
				if inventoryItem.Id == requiredItem.Id and inventoryItem.Quantity >= requiredItem.Quantity then
					hasItem = true
					break
				end
			end
			if not hasItem then
				return false, "Недостаточно предметов для эволюции"
			end
		end
	end

	-- Проверяем количество побед
	if evolutionData.RequiredBattles then
		if (playerData.Stats.EnemiesDefeated or 0) < evolutionData.RequiredBattles then
			return false, "Нужно одержать " .. evolutionData.RequiredBattles .. " побед (текущее: " .. (playerData.Stats.EnemiesDefeated or 0) .. ")"
		end
	end

	return true, "Можно эволюционировать"
end

-- ============================================
-- Получение информации об эволюции
-- ============================================

function EvolutionSystem:GetEvolutionInfo(spiritId)
	local evolutionData = EvolutionDatabase[spiritId]
	if not evolutionData then
		return nil
	end

	local evolvedSpirit = SpiritDatabase.Get(evolutionData.EvolvedId)

	return {
		RequiredLevel = evolutionData.RequiredLevel,
		RequiredItems = evolutionData.RequiredItems,
		RequiredBattles = evolutionData.RequiredBattles,
		EvolvedName = (evolvedSpirit and evolvedSpirit.Name) or evolutionData.NewName,
		NewStats = (evolvedSpirit and evolvedSpirit.BaseStats) or evolutionData.NewStats,
		NewSkills = (evolvedSpirit and SpiritDatabase.GetSkillNames(evolvedSpirit)) or evolutionData.NewSkills,
		EvolvedSpirit = evolvedSpirit
	}
end

-- ============================================
-- Эволюция духа
-- ============================================

function EvolutionSystem:EvolveSpirit(spiritIndex, playerData)
	local spirit = playerData.Spirits[spiritIndex]
	if not spirit then
		return false, "Дух не найден"
	end

	local canEvolve, reason = self:CanEvolve(spirit, playerData)
	if not canEvolve then
		return false, reason
	end

	local evolutionData = EvolutionDatabase[spirit.Id]

	-- Удаляем необходимые предметы
	if evolutionData.RequiredItems then
		for _, requiredItem in ipairs(evolutionData.RequiredItems) do
			for i, inventoryItem in ipairs(playerData.Inventory) do
				if inventoryItem.Id == requiredItem.Id then
					inventoryItem.Quantity = inventoryItem.Quantity - requiredItem.Quantity
					if inventoryItem.Quantity <= 0 then
						table.remove(playerData.Inventory, i)
					end
					break
				end
			end
		end
	end

	-- Обновляем духа на данные из единой SpiritDatabase
	local preCatalog = SpiritDatabase.Get(spirit.Id)
	local oldName = spirit.Name or (preCatalog and preCatalog.Name) or "Неизвестный"
	local evolvedSpirit = SpiritDatabase.Get(evolutionData.EvolvedId)
	spirit.Id = evolutionData.EvolvedId
	spirit.Name = (evolvedSpirit and evolvedSpirit.Name) or evolutionData.NewName
	spirit.Skills = (evolvedSpirit and SpiritDatabase.GetSkillNames(evolvedSpirit)) or evolutionData.NewSkills
	if evolvedSpirit and evolvedSpirit.SkillIds then
		spirit.SkillIds = table.clone(evolvedSpirit.SkillIds)
	end
	spirit.EvolvedAt = os.time()
	spirit.EvolutionCount = (spirit.EvolutionCount or 0) + 1

	-- Бонус к характеристикам за эволюцию
	spirit.BonusHP = (spirit.BonusHP or 0) + 20
	spirit.BonusAttack = (spirit.BonusAttack or 0) + 5
	spirit.BonusDefense = (spirit.BonusDefense or 0) + 3
	spirit.BonusSpeed = (spirit.BonusSpeed or 0) + 3

	local unlockedSkill = nil
	if type(spirit.Skills) == "table" and #spirit.Skills > 0 then
		-- Identity: signature evolved skill is slot 1 after SkillIds reorder
		local first = spirit.Skills[1]
		if type(first) == "table" then
			unlockedSkill = first.Name
		elseif type(first) == "string" then
			unlockedSkill = first
		end
	end

	print(oldName .. " эволюционировал в " .. spirit.Name .. "!")

	return true, spirit, {
		OldName = oldName,
		UnlockedSkill = unlockedSkill,
	}
end

-- ============================================
-- Получение доступных эволюций
-- ============================================

function EvolutionSystem:GetAvailableEvolutions(playerData)
	local availableEvolutions = {}

	for i, spirit in ipairs(playerData.Spirits) do
		local canEvolve, reason = self:CanEvolve(spirit, playerData)
		local evolutionInfo = self:GetEvolutionInfo(spirit.Id)

		if evolutionInfo then
			table.insert(availableEvolutions, {
				SpiritIndex = i,
				Spirit = spirit,
				CanEvolve = canEvolve,
				Reason = reason,
				EvolutionInfo = evolutionInfo
			})
		end
	end

	return availableEvolutions
end

-- ============================================
-- Получение всех эволюций
-- ============================================

function EvolutionSystem:GetAllEvolutions()
	local allEvolutions = {}

	for spiritId, evolutionData in pairs(EvolutionDatabase) do
		local evolvedSpirit = SpiritDatabase.Get(evolutionData.EvolvedId)
		table.insert(allEvolutions, {
			SpiritId = spiritId,
			EvolvedId = evolutionData.EvolvedId,
			RequiredLevel = evolutionData.RequiredLevel,
			RequiredItems = evolutionData.RequiredItems,
			RequiredBattles = evolutionData.RequiredBattles,
			NewName = (evolvedSpirit and evolvedSpirit.Name) or evolutionData.NewName,
			EvolvedSpirit = evolvedSpirit
		})
	end

	return allEvolutions
end

return EvolutionSystem
