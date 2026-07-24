-- ============================================
-- Realm of Spirits - Quest System
-- Система квестов с монетами, опытом, репутацией и уникальными предметами
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- RemoteEvents (используем папку RealmOfSpirits)
local realmFolder = ReplicatedStorage:FindFirstChild("RealmOfSpirits")
if not realmFolder then
	realmFolder = Instance.new("Folder")
	realmFolder.Name = "RealmOfSpirits"
	realmFolder.Parent = ReplicatedStorage
end
local QuestEvent = realmFolder:FindFirstChild("Quest")
if not QuestEvent then
	QuestEvent = Instance.new("RemoteEvent")
	QuestEvent.Name = "Quest"
	QuestEvent.Parent = realmFolder
end
local DataEvent = realmFolder:FindFirstChild("DataSync")
if not DataEvent then
	DataEvent = Instance.new("RemoteEvent")
	DataEvent.Name = "DataSync"
	DataEvent.Parent = realmFolder
end

-- ============================================
-- Уникальные предметы (награды за квесты)
-- ============================================

local UniqueItemDatabase = {
	[1] = {Id = 1, Name = "Амулет Древнего Мастера", Rarity = "Legendary", Description = "Увеличивает опыт на 15%"},
	[2] = {Id = 2, Name = "Кольцо Стихий", Rarity = "Epic", Description = "+10% урон всем духам"},
	[3] = {Id = 3, Name = "Свиток Призыва", Rarity = "Rare", Description = "Позволяет призвать случайного духа"},
	[4] = {Id = 4, Name = "Плащ Мудреца", Rarity = "Epic", Description = "+20% защита, +10% скорость"},
	[5] = {Id = 5, Name = "Корона Дракона", Rarity = "Legendary", Description = "+30% опыт, +15% репутация"},
	[6] = {Id = 6, Name = "Кристалл Удачи", Rarity = "Rare", Description = "Увеличивает шанс поимки духов"},
	[7] = {Id = 7, Name = "Посох Хранителя", Rarity = "Epic", Description = "+25% урон в боях"},
	-- Трофеи Пути Охотника (habitats)
	[8] = {Id = 8, Name = "Знак Угольного Двора", Rarity = "Uncommon", Description = "Трофей: Огненный Кот. +5% урон огнём"},
	[9] = {Id = 9, Name = "Перо Морозного Хребта", Rarity = "Uncommon", Description = "Трофей: Ледяная Птица. +5% скорость"},
	[10] = {Id = 10, Name = "Чешуя Туманного Пруда", Rarity = "Rare", Description = "Трофей: Водный Карп. +5% защита"},
	[11] = {Id = 11, Name = "Клык Теневой Лощины", Rarity = "Rare", Description = "Трофей: Теневой Пёс. +8% крит"},
	[12] = {Id = 12, Name = "Искра Грозового Шпиля", Rarity = "Epic", Description = "Трофей: Грозовой Дракон. +10% урон"},
	[13] = {Id = 13, Name = "Корона Рассвета", Rarity = "Legendary", Description = "Трофей: Световой Единорог. +20% опыт, +10% репутация"},
}

-- ============================================
-- Данные квестов
-- ============================================

local QuestDatabase = {
	-- Основная сюжетная линия
	[1] = {
		Id = 1,
		Name = "Первые шаги",
		Description = "Поймайте своего первого духа в дикой природе",
		Type = "Story",
		Level = 1,
		Objectives = {
			{Type = "CatchSpirit", Count = 1}
		},
		Rewards = {
			Experience = 100,
			CopperCoins = 50,
			SilverCoins = 5,
			GoldCoins = 0,
			Reputation = 10,
			UniqueItems = {},
			Items = {{Id = 1, Quantity = 3}}
		},
		Prerequisites = {}
	},
	[2] = {
		Id = 2,
		Name = "Тренировка",
		Description = "Победите 5 врагов на тренировочной площадке",
		Type = "Story",
		Level = 2,
		Objectives = {
			{Type = "DefeatEnemies", Count = 5}
		},
		Rewards = {
			Experience = 200,
			CopperCoins = 100,
			SilverCoins = 10,
			GoldCoins = 0,
			Reputation = 20,
			UniqueItems = {},
			Items = {{Id = 2, Quantity = 5}}
		},
		Prerequisites = {1}
	},
	[3] = {
		Id = 3,
		Name = "Коллекционер",
		Description = "Поймайте 3 разных духов",
		Type = "Story",
		Level = 3,
		Objectives = {
			{Type = "CatchDifferentSpirits", Count = 3}
		},
		Rewards = {
			Experience = 350,
			CopperCoins = 150,
			SilverCoins = 15,
			GoldCoins = 0,
			Reputation = 30,
			UniqueItems = {{Id = 6, Quantity = 1}}, -- Кристалл Удачи
			Items = {{Id = 3, Quantity = 1}}
		},
		Prerequisites = {1}
	},
	[4] = {
		Id = 4,
		Name = "Боевое испытание",
		Description = "Победите 10 врагов в битве",
		Type = "Story",
		Level = 5,
		Objectives = {
			{Type = "DefeatEnemies", Count = 10}
		},
		Rewards = {
			Experience = 500,
			CopperCoins = 200,
			SilverCoins = 25,
			GoldCoins = 1,
			Reputation = 50,
			UniqueItems = {{Id = 2, Quantity = 1}}, -- Кольцо Стихий
			Items = {{Id = 1, Quantity = 5}} -- ловушки (ItemCatalog)
		},
		Prerequisites = {2, 3}
	},
	[5] = {
		Id = 5,
		Name = "Мастер Духов",
		Description = "Прокачайте духа до 10 уровня",
		Type = "Story",
		Level = 8,
		Objectives = {
			{Type = "LevelUpSpirit", TargetLevel = 10}
		},
		Rewards = {
			Experience = 800,
			CopperCoins = 300,
			SilverCoins = 50,
			GoldCoins = 3,
			Reputation = 100,
			UniqueItems = {{Id = 7, Quantity = 1}}, -- Посох Хранителя
			Items = {{Id = 2, Quantity = 3}} -- зелья
		},
		Prerequisites = {4}
	},
	[6] = {
		Id = 6,
		Name = "Легендарный Мастер",
		Description = "Поймайте всех 6 различных духов в мире",
		Type = "Story",
		Level = 10,
		Objectives = {
			{Type = "CatchDifferentSpirits", Count = 6}
		},
		Rewards = {
			Experience = 1500,
			CopperCoins = 500,
			SilverCoins = 100,
			GoldCoins = 10,
			Reputation = 250,
			UniqueItems = {{Id = 5, Quantity = 1}}, -- Корона Дракона
			Items = {{Id = 3, Quantity = 3}} -- свитки опыта
		},
		Prerequisites = {5}
	},

	-- Побочные квесты
	[101] = {
		Id = 101,
		Name = "Помощь торговцу",
		Description = "Соберите 5 огненных кристаллов",
		Type = "Side",
		Level = 1,
		Objectives = {
			{Type = "CollectItem", ItemId = 101, Count = 5}
		},
		Rewards = {
			Experience = 50,
			CopperCoins = 80,
			SilverCoins = 5,
			GoldCoins = 0,
			Reputation = 5,
			UniqueItems = {},
			Items = {{Id = 2, Quantity = 2}}
		},
		Prerequisites = {}
	},
	[102] = {
		Id = 102,
		Name = "Охотник за сокровищами",
		Description = "Найдите 3 скрытых сундука в мире",
		Type = "Side",
		Level = 3,
		Objectives = {
			{Type = "FindChests", Count = 3}
		},
		Rewards = {
			Experience = 150,
			CopperCoins = 120,
			SilverCoins = 15,
			GoldCoins = 0,
			Reputation = 15,
			UniqueItems = {{Id = 3, Quantity = 1}}, -- Свиток Призыва
			Items = {}
		},
		Prerequisites = {}
	},
	[103] = {
		Id = 103,
		Name = "Тренер духов",
		Description = "Победите 20 врагов любого типа",
		Type = "Side",
		Level = 4,
		Objectives = {
			{Type = "DefeatEnemies", Count = 20}
		},
		Rewards = {
			Experience = 300,
			CopperCoins = 200,
			SilverCoins = 20,
			GoldCoins = 1,
			Reputation = 25,
			UniqueItems = {{Id = 7, Quantity = 1}}, -- Посох Хранителя (UniqueItemDatabase)
			Items = {{Id = 2, Quantity = 3}} -- зелья в инвентарь
		},
		Prerequisites = {}
	},
	[104] = {
		Id = 104,
		Name = "Хранитель мира",
		Description = "Поймайте 5 духов для защиты королевства",
		Type = "Side",
		Level = 5,
		Objectives = {
			{Type = "CatchSpirit", Count = 5}
		},
		Rewards = {
			Experience = 400,
			CopperCoins = 250,
			SilverCoins = 30,
			GoldCoins = 2,
			Reputation = 50,
			UniqueItems = {{Id = 4, Quantity = 1}}, -- Плащ Мудреца
			Items = {}
		},
		Prerequisites = {1}
	},
	[105] = {
		Id = 105,
		Name = "Легенда о Мастере",
		Description = "Завершите побочные 101–104 и победите 50 врагов",
		Type = "Side",
		Level = 10,
		Objectives = {
			{Type = "DefeatEnemies", Count = 50}
		},
		Rewards = {
			Experience = 2000,
			CopperCoins = 500,
			SilverCoins = 100,
			GoldCoins = 15,
			Reputation = 500,
			UniqueItems = {{Id = 1, Quantity = 1}}, -- Амулет Древнего Мастера
			Items = {{Id = 3, Quantity = 2}} -- свитки опыта
		},
		Prerequisites = {101, 102, 103, 104}
	},

	-- ============================================
	-- Путь Охотника: ловить духов по HuntOrder (ZoneConfig.SpiritHabitats)
	-- ============================================
	[201] = {
		Id = 201,
		Name = "Путь Охотника I: Огонь",
		Description = "Поймайте Огненного Кота у Угольного двора (Акихабара, восток от Haven)",
		Type = "Hunt",
		Level = 1,
		Objectives = {
			{Type = "CatchSpecificSpirit", SpiritId = 1, Count = 1, SpiritName = "Огненный Кот"}
		},
		Rewards = {
			Experience = 120,
			CopperCoins = 80,
			SilverCoins = 5,
			GoldCoins = 0,
			Reputation = 15,
			UniqueItems = {{Id = 8, Quantity = 1}},
			Items = {{Id = 101, Quantity = 2}, {Id = 1, Quantity = 2}}
		},
		Prerequisites = {}
	},
	[202] = {
		Id = 202,
		Name = "Путь Охотника II: Лёд",
		Description = "Поймайте Ледяную Птицу на Морозном хребте (северо-запад, у пруда)",
		Type = "Hunt",
		Level = 2,
		Objectives = {
			{Type = "CatchSpecificSpirit", SpiritId = 2, Count = 1, SpiritName = "Ледяная Птица"}
		},
		Rewards = {
			Experience = 180,
			CopperCoins = 100,
			SilverCoins = 8,
			GoldCoins = 0,
			Reputation = 20,
			UniqueItems = {{Id = 9, Quantity = 1}},
			Items = {{Id = 102, Quantity = 2}, {Id = 1, Quantity = 2}}
		},
		Prerequisites = {201}
	},
	[203] = {
		Id = 203,
		Name = "Путь Охотника III: Вода",
		Description = "Поймайте Водного Карпа в Туманном пруду (север от Combat по камням)",
		Type = "Hunt",
		Level = 3,
		Objectives = {
			{Type = "CatchSpecificSpirit", SpiritId = 6, Count = 1, SpiritName = "Водный Карп"}
		},
		Rewards = {
			Experience = 220,
			CopperCoins = 120,
			SilverCoins = 12,
			GoldCoins = 0,
			Reputation = 25,
			UniqueItems = {{Id = 10, Quantity = 1}},
			Items = {{Id = 106, Quantity = 3}, {Id = 2, Quantity = 2}}
		},
		Prerequisites = {202}
	},
	[204] = {
		Id = 204,
		Name = "Путь Охотника IV: Тень",
		Description = "Поймайте Теневого Пса в Теневой лощине (юг от арены)",
		Type = "Hunt",
		Level = 4,
		Objectives = {
			{Type = "CatchSpecificSpirit", SpiritId = 3, Count = 1, SpiritName = "Теневой Пёс"}
		},
		Rewards = {
			Experience = 320,
			CopperCoins = 160,
			SilverCoins = 18,
			GoldCoins = 1,
			Reputation = 35,
			UniqueItems = {{Id = 11, Quantity = 1}},
			Items = {{Id = 103, Quantity = 3}, {Id = 1, Quantity = 3}}
		},
		Prerequisites = {203}
	},
	[205] = {
		Id = 205,
		Name = "Путь Охотника V: Гроза",
		Description = "Поймайте Грозового Дракона у Грозового шпиля (север от арены)",
		Type = "Hunt",
		Level = 6,
		Objectives = {
			{Type = "CatchSpecificSpirit", SpiritId = 4, Count = 1, SpiritName = "Грозовой Дракон"}
		},
		Rewards = {
			Experience = 450,
			CopperCoins = 220,
			SilverCoins = 30,
			GoldCoins = 2,
			Reputation = 50,
			UniqueItems = {{Id = 12, Quantity = 1}},
			Items = {{Id = 104, Quantity = 3}, {Id = 2, Quantity = 3}}
		},
		Prerequisites = {204}
	},
	[206] = {
		Id = 206,
		Name = "Путь Охотника VI: Свет",
		Description = "Поймайте Светового Единорога на Лугу рассвета (далеко на северо-востоке)",
		Type = "Hunt",
		Level = 8,
		Objectives = {
			{Type = "CatchSpecificSpirit", SpiritId = 5, Count = 1, SpiritName = "Световой Единорог"}
		},
		Rewards = {
			Experience = 800,
			CopperCoins = 350,
			SilverCoins = 50,
			GoldCoins = 5,
			Reputation = 100,
			UniqueItems = {{Id = 13, Quantity = 1}},
			Items = {{Id = 105, Quantity = 5}, {Id = 3, Quantity = 2}}
		},
		Prerequisites = {205}
	},
}

-- ============================================
-- Система квестов игрока
-- ============================================

local QuestSystem = {}
QuestSystem.__index = QuestSystem

local function NormalizeCurrency(playerData)
	local c = tonumber(playerData.CopperCoins) or 0
	local s = tonumber(playerData.SilverCoins) or 0
	local g = tonumber(playerData.GoldCoins) or 0
	local total = c + s * 100 + g * 10000
	total = math.max(0, math.floor(total))
	playerData.GoldCoins = math.floor(total / 10000)
	total = total % 10000
	playerData.SilverCoins = math.floor(total / 100)
	playerData.CopperCoins = total % 100
end

function QuestSystem.new(player)
	local self = setmetatable({}, QuestSystem)

	self.Player = player
	self.ActiveQuests = {}
	self.CompletedQuests = {}
	self.ReadyToTurnIn = {}
	self.QuestProgress = {}

	return self
end

function QuestSystem:AcceptQuest(questId)
	local quest = QuestDatabase[questId]
	if not quest then return false, "Квест не найден" end

	-- Проверяем prerequisites
	for _, prereqId in ipairs(quest.Prerequisites or {}) do
		if not self.CompletedQuests[prereqId] then
			return false, "Не выполнены предварительные условия"
		end
	end

	-- Проверяем, не взят ли уже квест
	if self.ActiveQuests[questId] then
		return false, "Квест уже взят"
	end

	-- Берём квест
	self.ActiveQuests[questId] = true
	self.QuestProgress[questId] = {}

	for i, objective in ipairs(quest.Objectives) do
		self.QuestProgress[questId][i] = {
			Type = objective.Type,
			Current = 0,
			Target = objective.Count or objective.TargetLevel or 1
		}
	end

	-- Зачёт уже имеющихся уровней / предметов / разных духов
	-- CatchSpirit НЕ сидим: стартовый дух ≠ «поимка в дикой природе»
	do
		local playerData = nil
		if _G.GetPlayerData then
			playerData = _G.GetPlayerData(self.Player)
		else
			local ok, DataStoreManagerModule = pcall(require, script.Parent.DataStoreManager)
			if ok and DataStoreManagerModule then
				playerData = DataStoreManagerModule.new():GetPlayerData(self.Player.UserId)
			end
		end
		if playerData then
			local spirits = playerData.Spirits or {}
			local uniqueIds = {}
			local uniqueCount = 0
			local maxSpiritLevel = 0
			for _, spiritEntry in ipairs(spirits) do
				local key = tostring(spiritEntry.Id)
				if not uniqueIds[key] then
					uniqueIds[key] = true
					uniqueCount += 1
				end
				maxSpiritLevel = math.max(maxSpiritLevel, spiritEntry.Level or 1)
			end
			local function countInv(itemId)
				local n = 0
				for _, inv in ipairs(playerData.Inventory or {}) do
					if inv.Id == itemId then
						n += (inv.Quantity or 0)
					end
				end
				return n
			end
			for i, objective in ipairs(quest.Objectives) do
				local progress = self.QuestProgress[questId][i]
				if objective.Type == "CatchDifferentSpirits" then
					progress.CaughtIds = {}
					for key in pairs(uniqueIds) do
						progress.CaughtIds[key] = true
					end
					progress.Current = math.min(uniqueCount, progress.Target)
				elseif objective.Type == "CatchSpecificSpirit" and objective.SpiritId then
					local want = tonumber(objective.SpiritId)
					for _, spiritEntry in ipairs(spirits) do
						if tonumber(spiritEntry.Id) == want then
							progress.Current = progress.Target
							break
						end
					end
				elseif objective.Type == "LevelUpSpirit" then
					progress.Current = math.min(maxSpiritLevel, progress.Target)
				elseif objective.Type == "CollectItem" and objective.ItemId then
					progress.Current = math.min(countInv(objective.ItemId), progress.Target)
				end
			end
			if self:AreAllObjectivesComplete(questId) then
				self:MarkReadyToTurnIn(questId)
			end
		end
	end

	QuestEvent:FireClient(self.Player, "QuestAccepted", {QuestId = questId})

	return true, "Квест принят!"
end

function QuestSystem:UpdateProgress(progressType, data)
	for questId, _ in pairs(self.ActiveQuests) do
		local quest = QuestDatabase[questId]
		if quest then
			for i, objective in ipairs(quest.Objectives) do
				if objective.Type == progressType then
					local progress = self.QuestProgress[questId][i]

					if progressType == "CatchSpirit" then
						progress.Current = progress.Current + 1
					elseif progressType == "CatchSpecificSpirit" then
						if data and data.SpiritId and objective.SpiritId
							and tonumber(data.SpiritId) == tonumber(objective.SpiritId) then
							progress.Current = math.min((progress.Current or 0) + 1, progress.Target or 1)
						end
					elseif progressType == "DefeatEnemies" then
						progress.Current = progress.Current + 1
					elseif progressType == "CatchDifferentSpirits" then
						if data and data.SpiritId then
							progress.CaughtIds = progress.CaughtIds or {}
							local spiritKey = tostring(data.SpiritId)
							if not progress.CaughtIds[spiritKey] then
								progress.CaughtIds[spiritKey] = true
								progress.Current = progress.Current + 1
							end
						end
					elseif progressType == "LevelUpSpirit" then
						local reached = (data and (data.Level or data.NewLevel)) or 0
						if reached > progress.Current then
							progress.Current = reached
						end
					elseif progressType == "FindChests" then
						progress.Current = progress.Current + (data and data.Count or 1)
					elseif progressType == "CollectItem" then
						if data and data.ItemId == objective.ItemId then
							progress.Current = progress.Current + (data.Count or 1)
						end
					end

					-- Проверяем выполнение
					if self:AreAllObjectivesComplete(questId) then self:MarkReadyToTurnIn(questId)
					end

					-- Отправляем обновление
					QuestEvent:FireClient(self.Player, "QuestProgress", {
						QuestId = questId,
						ObjectiveIndex = i,
						Progress = progress
					})
				end
			end
		end
	end
end

function QuestSystem:AreAllObjectivesComplete(questId)
	local quest = QuestDatabase[questId]
	local progress = self.QuestProgress[questId]
	if not quest or not progress then return false end
	for i, objective in ipairs(quest.Objectives) do
		local p = progress[i]
		if not p then return false end
		local target = objective.Count or objective.TargetLevel or 1
		if p.Current < target then return false end
	end
	return true
end

function QuestSystem:MarkReadyToTurnIn(questId)
	if self.ReadyToTurnIn[questId] or not self.ActiveQuests[questId] then return end
	if not self:AreAllObjectivesComplete(questId) then return end
	self.ReadyToTurnIn[questId] = true
	local quest = QuestDatabase[questId]
	QuestEvent:FireClient(self.Player, "QuestReadyToTurnIn", {QuestId = questId, QuestName = quest and quest.Name or "Квест"})
end

function QuestSystem:TurnInQuest(questId)
	if not self.ReadyToTurnIn[questId] then return false, "Сначала выполните все цели квеста" end
	if not self.ActiveQuests[questId] then return false, "Квест не активен" end
	local quest = QuestDatabase[questId]
	if quest then
		local playerData = nil
		if _G.GetPlayerData then
			playerData = _G.GetPlayerData(self.Player)
		else
			local ok, DSM = pcall(require, script.Parent.DataStoreManager)
			if ok and DSM then
				playerData = DSM.new():GetPlayerData(self.Player.UserId)
			end
		end
		if playerData then
			for _, objective in ipairs(quest.Objectives or {}) do
				if objective.Type == "CollectItem" and objective.ItemId then
					local need = objective.Count or 1
					local have = 0
					for _, inv in ipairs(playerData.Inventory or {}) do
						if inv.Id == objective.ItemId then
							have += (inv.Quantity or 0)
						end
					end
					if have < need then
						return false, "Недостаточно предметов для сдачи квеста"
					end
				end
			end
		end
	end
	self:CompleteQuest(questId)
	return true, "Квест сдан!"
end

function QuestSystem:CompleteQuest(questId)
	local quest = QuestDatabase[questId]
	if not quest then return end

	local playerData = nil
	if _G.GetPlayerData then
		playerData = _G.GetPlayerData(self.Player)
	else
		local DataStoreManagerModule = require(script.Parent.DataStoreManager)
		playerData = DataStoreManagerModule.new():GetPlayerData(self.Player.UserId)
	end
	if playerData then
		playerData.Stats = playerData.Stats or {}
		playerData.Inventory = playerData.Inventory or {}
		playerData.UniqueItems = playerData.UniqueItems or {}

		-- Списываем предметы CollectItem при сдаче
		for _, objective in ipairs(quest.Objectives or {}) do
			if objective.Type == "CollectItem" and objective.ItemId then
				local need = objective.Count or 1
				for _, invItem in ipairs(playerData.Inventory) do
					if invItem.Id == objective.ItemId then
						invItem.Quantity = math.max(0, (invItem.Quantity or 0) - need)
						break
					end
				end
			end
		end

		-- Монеты (три типа)
		playerData.CopperCoins = (playerData.CopperCoins or 0) + (quest.Rewards.CopperCoins or 0)
		playerData.SilverCoins = (playerData.SilverCoins or 0) + (quest.Rewards.SilverCoins or 0)
		playerData.GoldCoins = (playerData.GoldCoins or 0) + (quest.Rewards.GoldCoins or 0)

		-- Опыт и репутация
		playerData.Experience = (playerData.Experience or 0) + (quest.Rewards.Experience or 0)
		playerData.Reputation = (playerData.Reputation or 0) + (quest.Rewards.Reputation or 0)

		local LevelingSystem = require(script.Parent.LevelingSystem)
		local levelingSystem = LevelingSystem.new()
		local leveledUp, _, levelRewards = levelingSystem:CheckLevelUp(playerData)
		if leveledUp then
			for _, reward in ipairs(levelRewards) do
				DataEvent:FireClient(self.Player, "LevelUp", {
					NewLevel = reward.Level,
					BonusCoins = reward.CopperCoins or reward.Coins or 0,
				})
			end
		end

		-- Статистика
		playerData.Stats.QuestsCompleted = (playerData.Stats.QuestsCompleted or 0) + 1
		NormalizeCurrency(playerData)

		-- Уникальные предметы
		if quest.Rewards.UniqueItems then
			for _, item in ipairs(quest.Rewards.UniqueItems) do
				local itemInfo = UniqueItemDatabase[item.Id]
				table.insert(playerData.UniqueItems, {
					Id = item.Id,
					Name = itemInfo and itemInfo.Name or "Unknown",
					Rarity = itemInfo and itemInfo.Rarity or "Common",
					Description = itemInfo and itemInfo.Description or "",
					Quantity = item.Quantity
				})
			end
		end

		-- Обычные предметы
		if quest.Rewards.Items then
			for _, item in ipairs(quest.Rewards.Items) do
				local found = false
				for _, invItem in ipairs(playerData.Inventory) do
					if invItem.Id == item.Id then
						invItem.Quantity = (invItem.Quantity or 0) + (item.Quantity or 1)
						found = true
						break
					end
				end
				if not found then
					table.insert(playerData.Inventory, {Id = item.Id, Quantity = item.Quantity or 1})
				end
			end
		end

		-- Отправляем обновление клиенту
		DataEvent:FireClient(self.Player, "FullSync", playerData)
	end

	-- Отмечаем как выполненное
	self.ReadyToTurnIn[questId] = nil
	self.CompletedQuests[questId] = true
	self.ActiveQuests[questId] = nil
	self.QuestProgress[questId] = nil

	QuestEvent:FireClient(self.Player, "QuestCompleted", {
		QuestId = questId,
		Rewards = quest.Rewards,
		QuestName = quest.Name
	})

	print(self.Player.Name .. " выполнил квест: " .. quest.Name)
end

function QuestSystem:GetQuestInfo(questId)
	return QuestDatabase[questId]
end

function QuestSystem:SyncInventoryObjectives(questId)
	local quest = QuestDatabase[questId]
	local progress = self.QuestProgress[questId]
	if not quest or not progress then return end
	local playerData = _G.GetPlayerData and _G.GetPlayerData(self.Player) or nil
	if not playerData then return end
	local function countInv(itemId)
		local n = 0
		for _, inv in ipairs(playerData.Inventory or {}) do
			if inv.Id == itemId then
				n += (inv.Quantity or 0)
			end
		end
		return n
	end
	for i, objective in ipairs(quest.Objectives or {}) do
		local p = progress[i]
		if p and objective.Type == "CollectItem" and objective.ItemId then
			p.Current = math.min(countInv(objective.ItemId), p.Target or objective.Count or 1)
		end
	end
	if self:AreAllObjectivesComplete(questId) then
		self:MarkReadyToTurnIn(questId)
	end
end

function QuestSystem:GetActiveQuests()
	local quests = {}
	for questId, _ in pairs(self.ActiveQuests) do
		self:SyncInventoryObjectives(questId)
		local progOut = {}
		local srcProg = self.QuestProgress[questId] or {}
		local quest = QuestDatabase[questId]
		local n = quest and #(quest.Objectives or {}) or 0
		for i = 1, n do
			local p = srcProg[i] or {}
			progOut[i] = {
				Type = p.Type,
				Current = tonumber(p.Current) or 0,
				Target = tonumber(p.Target) or 1,
			}
		end
		table.insert(quests, {
			Quest = quest,
			Progress = progOut,
			ReadyToTurnIn = self.ReadyToTurnIn[questId] or false
		})
	end
	return quests
end

-- ============================================
-- Обработчики событий
-- ============================================

local function TriggerQuestMasterReaction(reaction)
	local qm = Workspace:FindFirstChild("QuestMaster")
	if not qm then return end
	-- сброс, чтобы повтор той же эмоции снова сработал
	qm:SetAttribute("Reaction", nil)
	qm:SetAttribute("Reaction", reaction)
end

local function FaceQuestMasterToPlayer(player)
	local qm = Workspace:FindFirstChild("QuestMaster")
	if not qm or not player then return end
	qm:SetAttribute("FaceUserId", player.UserId)
end

local PlayerQuestSystems = {}
local RecentQuestMasterInteraction = {}

local function GetOrCreateQuestSystem(player)
	local questSystem = PlayerQuestSystems[player.UserId]
	if not questSystem then
		questSystem = QuestSystem.new(player)
		PlayerQuestSystems[player.UserId] = questSystem
	end
	return questSystem
end

local function BuildAvailableQuests(questSystem)
	local availableQuests = {}
	for questId, quest in pairs(QuestDatabase) do
		if not questSystem.ActiveQuests[questId] and not questSystem.CompletedQuests[questId] then
			local canTake = true
			for _, prereqId in ipairs(quest.Prerequisites or {}) do
				if not questSystem.CompletedQuests[prereqId] then
					canTake = false
					break
				end
			end
			if canTake then
				table.insert(availableQuests, quest)
			end
		end
	end
	-- Стабильный порядок: уровень → Id (иначе pairs() прячет побочные ниже скролла)
	table.sort(availableQuests, function(a, b)
		local la = tonumber(a.Level) or 1
		local lb = tonumber(b.Level) or 1
		if la ~= lb then
			return la < lb
		end
		return (tonumber(a.Id) or 0) < (tonumber(b.Id) or 0)
	end)
	return availableQuests
end

local function BuildCompletedQuests(questSystem)
	local completed = {}
	for questId, _ in pairs(questSystem.CompletedQuests) do
		table.insert(completed, QuestDatabase[questId])
	end
	return completed
end

local function OpenQuestUIForPlayer(player, questSystem)
	RecentQuestMasterInteraction[player.UserId] = os.clock()
	FaceQuestMasterToPlayer(player)
	TriggerQuestMasterReaction("Talk")
	QuestEvent:FireClient(player, "OpenQuestUI", {
		Available = BuildAvailableQuests(questSystem),
		Active = questSystem:GetActiveQuests(),
		Completed = BuildCompletedQuests(questSystem),
		PreferredTab = "Available"
	})
end

local function IsPlayerNearQuestMaster(player, maxDistance)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local questMaster = Workspace:FindFirstChild("QuestMaster")
	if not root or not questMaster then
		return false
	end
	local distance = (root.Position - questMaster:GetPivot().Position).Magnitude
	return distance <= (maxDistance or 18)
end

local function CanUseQuestMasterAction(player, maxDistance, graceSeconds)
	if IsPlayerNearQuestMaster(player, maxDistance) then
		return true
	end
	local lastInteraction = RecentQuestMasterInteraction[player.UserId]
	if not lastInteraction then
		return false
	end
	return (os.clock() - lastInteraction) <= (graceSeconds or 8)
end

QuestEvent.OnServerEvent:Connect(function(player, action, data)
	local questSystem = GetOrCreateQuestSystem(player)

	if action == "GetQuests" then
		local availableQuests = BuildAvailableQuests(questSystem)
		QuestEvent:FireClient(player, "QuestList", {Quests = availableQuests})

	elseif action == "AcceptQuest" then
		if not CanUseQuestMasterAction(player, 26, 10) then
			QuestEvent:FireClient(player, "QuestResult", {Success = false, Message = "Квесты выдаёт только квестор рядом с вами"})
			return
		end
		local questId = data and data.QuestId
		if not questId then
			QuestEvent:FireClient(player, "QuestResult", {Success = false, Message = "Некорректный запрос квеста"})
			return
		end
		local success, message = questSystem:AcceptQuest(questId)
		TriggerQuestMasterReaction(success and "Point" or "Fail")
		QuestEvent:FireClient(player, "QuestResult", {Success = success, Message = message})

	elseif action == "GetActiveQuests" then
		local activeQuests = questSystem:GetActiveQuests()
		QuestEvent:FireClient(player, "ActiveQuests", {Quests = activeQuests})

	elseif action == "TurnInQuest" then
		if not CanUseQuestMasterAction(player, 26, 10) then
			QuestEvent:FireClient(player, "QuestResult", {Success = false, Message = "Сдать квест можно только у квестора"})
			return
		end
		local questId = data and data.QuestId
		if not questId then
			QuestEvent:FireClient(player, "QuestResult", {Success = false, Message = "Некорректный запрос квеста"})
			return
		end
		local success, message = questSystem:TurnInQuest(questId)
		TriggerQuestMasterReaction(success and "Success" or "Fail")
		QuestEvent:FireClient(player, "QuestResult", {Success = success, Message = message, TurnIn = true})
		if success then
			QuestEvent:FireClient(player, "ActiveQuests", {Quests = questSystem:GetActiveQuests()})
			QuestEvent:FireClient(player, "CompletedQuests", {Quests = BuildCompletedQuests(questSystem)})
		end

	elseif action == "GetCompletedQuests" then
		local completed = {}
		for questId, _ in pairs(questSystem.CompletedQuests) do
			table.insert(completed, QuestDatabase[questId])
		end
		QuestEvent:FireClient(player, "CompletedQuests", {Quests = completed})
	end
end)

-- ============================================
-- Интеграция NPC (ProximityPrompt)
-- ============================================

task.spawn(function()
	local questMaster = Workspace:WaitForChild("QuestMaster", 10)
	if not questMaster then
		warn("QuestMaster NPC не найден в Workspace!")
		return
	end

	local hookedPrompts = {}
	local hookedClicks = {}

	local function openFor(player)
		local questSystem = GetOrCreateQuestSystem(player)
		if questSystem then
			OpenQuestUIForPlayer(player, questSystem)
		end
	end

	local function ensureAndHook()
		local anchor = questMaster:FindFirstChild("QuestInteractAnchor")
		if not anchor then
			anchor = Instance.new("Part")
			anchor.Name = "QuestInteractAnchor"
			anchor.Size = Vector3.new(2.5, 5, 2.5)
			anchor.Transparency = 1
			anchor.Anchored = true
			anchor.CanCollide = false
			anchor.CanQuery = true
			anchor.CanTouch = false
			anchor.Massless = true
			anchor.Parent = questMaster
		end
		anchor.CFrame = questMaster:GetPivot() * CFrame.new(0, 2.5, 0)

		local prompt = anchor:FindFirstChild("QuestPrompt")
		if not prompt then
			prompt = Instance.new("ProximityPrompt")
			prompt.Name = "QuestPrompt"
			prompt.Parent = anchor
		end
		prompt.ActionText = "Поговорить"
		prompt.ObjectText = "Мика · Квестор"
		prompt.Enabled = true
		prompt.MaxActivationDistance = 18
		prompt.RequiresLineOfSight = false
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		if not hookedPrompts[prompt] then
			hookedPrompts[prompt] = true
			prompt.Triggered:Connect(openFor)
			print("Quest Master ProximityPrompt подключён!")
		end

		local clickDetector = anchor:FindFirstChildOfClass("ClickDetector")
		if not clickDetector then
			clickDetector = Instance.new("ClickDetector")
			clickDetector.Name = "QuestMasterClick"
			clickDetector.MaxActivationDistance = 26
			clickDetector.Parent = anchor
		end
		if not hookedClicks[clickDetector] then
			hookedClicks[clickDetector] = true
			clickDetector.MouseClick:Connect(openFor)
			print("Quest Master ClickDetector подключён!")
		end
	end

	ensureAndHook()
	for _, delaySec in ipairs({0.5, 1.5, 3}) do
		task.delay(delaySec, ensureAndHook)
	end
	questMaster.ChildAdded:Connect(function(child)
		if child.Name == "QuestInteractAnchor" then
			task.defer(ensureAndHook)
		end
	end)
end)

-- ============================================
-- Публичная функция для обновления прогресса
-- ============================================

local function updateQuestProgress(player, progressType, data)
	local questSystem = PlayerQuestSystems[player.UserId]
	if questSystem then
		questSystem:UpdateProgress(progressType, data)
	end
end

-- Экспортируем для других скриптов
_G.UpdateQuestProgress = updateQuestProgress

-- ============================================
-- Инициализация
-- ============================================

Players.PlayerAdded:Connect(function(player)
	GetOrCreateQuestSystem(player)
end)

-- Обработка игроков уже в игре
for _, player in ipairs(Players:GetPlayers()) do
	GetOrCreateQuestSystem(player)
end

Players.PlayerRemoving:Connect(function(player)
	PlayerQuestSystems[player.UserId] = nil
	RecentQuestMasterInteraction[player.UserId] = nil
end)

print("Realm of Spirits - Quest System загружен!")
