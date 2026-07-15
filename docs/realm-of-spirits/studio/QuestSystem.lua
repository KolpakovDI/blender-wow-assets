-- ============================================
-- Realm of Spirits - Quest System
-- РЎРёСЃС‚РµРјР° РєРІРµСЃС‚РѕРІ СЃ РјРѕРЅРµС‚Р°РјРё, РѕРїС‹С‚РѕРј, СЂРµРїСѓС‚Р°С†РёРµР№ Рё СѓРЅРёРєР°Р»СЊРЅС‹РјРё РїСЂРµРґРјРµС‚Р°РјРё
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- RemoteEvents (РёСЃРїРѕР»СЊР·СѓРµРј РїР°РїРєСѓ RealmOfSpirits)
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
-- РЈРЅРёРєР°Р»СЊРЅС‹Рµ РїСЂРµРґРјРµС‚С‹ (РЅР°РіСЂР°РґС‹ Р·Р° РєРІРµСЃС‚С‹)
-- ============================================

local UniqueItemDatabase = {
	[1] = {Id = 1, Name = "РђРјСѓР»РµС‚ Р”СЂРµРІРЅРµРіРѕ РњР°СЃС‚РµСЂР°", Rarity = "Legendary", Description = "РЈРІРµР»РёС‡РёРІР°РµС‚ РѕРїС‹С‚ РЅР° 15%"},
	[2] = {Id = 2, Name = "РљРѕР»СЊС†Рѕ РЎС‚РёС…РёР№", Rarity = "Epic", Description = "+10% СѓСЂРѕРЅ РІСЃРµРј РґСѓС…Р°Рј"},
	[3] = {Id = 3, Name = "РЎРІРёС‚РѕРє РџСЂРёР·С‹РІР°", Rarity = "Rare", Description = "РџРѕР·РІРѕР»СЏРµС‚ РїСЂРёР·РІР°С‚СЊ СЃР»СѓС‡Р°Р№РЅРѕРіРѕ РґСѓС…Р°"},
	[4] = {Id = 4, Name = "РџР»Р°С‰ РњСѓРґСЂРµС†Р°", Rarity = "Epic", Description = "+20% Р·Р°С‰РёС‚Р°, +10% СЃРєРѕСЂРѕСЃС‚СЊ"},
	[5] = {Id = 5, Name = "РљРѕСЂРѕРЅР° Р”СЂР°РєРѕРЅР°", Rarity = "Legendary", Description = "+30% РѕРїС‹С‚, +15% СЂРµРїСѓС‚Р°С†РёСЏ"},
	[6] = {Id = 6, Name = "РљСЂРёСЃС‚Р°Р»Р» РЈРґР°С‡Рё", Rarity = "Rare", Description = "РЈРІРµР»РёС‡РёРІР°РµС‚ С€Р°РЅСЃ РїРѕРёРјРєРё РґСѓС…РѕРІ"},
	[7] = {Id = 7, Name = "РџРѕСЃРѕС… РҐСЂР°РЅРёС‚РµР»СЏ", Rarity = "Epic", Description = "+25% СѓСЂРѕРЅ РІ Р±РѕСЏС…"},
}

-- ============================================
-- Р”Р°РЅРЅС‹Рµ РєРІРµСЃС‚РѕРІ
-- ============================================

local QuestDatabase = {
	-- РћСЃРЅРѕРІРЅР°СЏ СЃСЋР¶РµС‚РЅР°СЏ Р»РёРЅРёСЏ
	[1] = {
		Id = 1,
		Name = "РџРµСЂРІС‹Рµ С€Р°РіРё",
		Description = "РџРѕР№РјР°Р№С‚Рµ СЃРІРѕРµРіРѕ РїРµСЂРІРѕРіРѕ РґСѓС…Р° РІ РґРёРєРѕР№ РїСЂРёСЂРѕРґРµ",
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
		Name = "РўСЂРµРЅРёСЂРѕРІРєР°",
		Description = "РџРѕР±РµРґРёС‚Рµ 5 РІСЂР°РіРѕРІ РЅР° С‚СЂРµРЅРёСЂРѕРІРѕС‡РЅРѕР№ РїР»РѕС‰Р°РґРєРµ",
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
		Name = "РљРѕР»Р»РµРєС†РёРѕРЅРµСЂ",
		Description = "РџРѕР№РјР°Р№С‚Рµ 3 СЂР°Р·РЅС‹С… РґСѓС…РѕРІ",
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
			UniqueItems = {{Id = 6, Quantity = 1}}, -- РљСЂРёСЃС‚Р°Р»Р» РЈРґР°С‡Рё
			Items = {{Id = 3, Quantity = 1}}
		},
		Prerequisites = {1}
	},
	[4] = {
		Id = 4,
		Name = "Р‘РѕРµРІРѕРµ РёСЃРїС‹С‚Р°РЅРёРµ",
		Description = "РџРѕР±РµРґРёС‚Рµ 10 РІСЂР°РіРѕРІ РІ Р±РёС‚РІРµ",
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
			UniqueItems = {{Id = 2, Quantity = 1}}, -- РљРѕР»СЊС†Рѕ РЎС‚РёС…РёР№
			Items = {{Id = 4, Quantity = 1}}
		},
		Prerequisites = {2, 3}
	},
	[5] = {
		Id = 5,
		Name = "РњР°СЃС‚РµСЂ Р”СѓС…РѕРІ",
		Description = "РџСЂРѕРєР°С‡Р°Р№С‚Рµ РґСѓС…Р° РґРѕ 10 СѓСЂРѕРІРЅСЏ",
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
			UniqueItems = {{Id = 7, Quantity = 1}}, -- РџРѕСЃРѕС… РҐСЂР°РЅРёС‚РµР»СЏ
			Items = {{Id = 5, Quantity = 2}}
		},
		Prerequisites = {4}
	},
	[6] = {
		Id = 6,
		Name = "Р›РµРіРµРЅРґР°СЂРЅС‹Р№ РњР°СЃС‚РµСЂ",
		Description = "РџРѕР№РјР°Р№С‚Рµ РІСЃРµС… 5 СЂР°Р·Р»РёС‡РЅС‹С… РґСѓС…РѕРІ РІ РјРёСЂРµ",
		Type = "Story",
		Level = 10,
		Objectives = {
			{Type = "CatchDifferentSpirits", Count = 5}
		},
		Rewards = {
			Experience = 1500,
			CopperCoins = 500,
			SilverCoins = 100,
			GoldCoins = 10,
			Reputation = 250,
			UniqueItems = {{Id = 5, Quantity = 1}}, -- РљРѕСЂРѕРЅР° Р”СЂР°РєРѕРЅР°
			Items = {{Id = 6, Quantity = 3}}
		},
		Prerequisites = {5}
	},

	-- РџРѕР±РѕС‡РЅС‹Рµ РєРІРµСЃС‚С‹
	[101] = {
		Id = 101,
		Name = "РџРѕРјРѕС‰СЊ С‚РѕСЂРіРѕРІС†Сѓ",
		Description = "РЎРѕР±РµСЂРёС‚Рµ 5 РѕРіРЅРµРЅРЅС‹С… РєСЂРёСЃС‚Р°Р»Р»РѕРІ",
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
		Name = "РћС…РѕС‚РЅРёРє Р·Р° СЃРѕРєСЂРѕРІРёС‰Р°РјРё",
		Description = "РќР°Р№РґРёС‚Рµ 3 СЃРєСЂС‹С‚С‹С… СЃСѓРЅРґСѓРєР° РІ РјРёСЂРµ",
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
			UniqueItems = {{Id = 3, Quantity = 1}}, -- РЎРІРёС‚РѕРє РџСЂРёР·С‹РІР°
			Items = {}
		},
		Prerequisites = {}
	},
	[103] = {
		Id = 103,
		Name = "РўСЂРµРЅРµСЂ РґСѓС…РѕРІ",
		Description = "РџРѕР±РµРґРёС‚Рµ 20 РІСЂР°РіРѕРІ Р»СЋР±РѕРіРѕ С‚РёРїР°",
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
			UniqueItems = {},
			Items = {{Id = 7, Quantity = 1}}
		},
		Prerequisites = {}
	},
	[104] = {
		Id = 104,
		Name = "РҐСЂР°РЅРёС‚РµР»СЊ РјРёСЂР°",
		Description = "РџРѕР№РјР°Р№С‚Рµ 5 РґСѓС…РѕРІ РґР»СЏ Р·Р°С‰РёС‚С‹ РєРѕСЂРѕР»РµРІСЃС‚РІР°",
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
			UniqueItems = {{Id = 4, Quantity = 1}}, -- РџР»Р°С‰ РњСѓРґСЂРµС†Р°
			Items = {}
		},
		Prerequisites = {1}
	},
	[105] = {
		Id = 105,
		Name = "Р›РµРіРµРЅРґР° Рѕ РњР°СЃС‚РµСЂРµ",
		Description = "Р’С‹РїРѕР»РЅРёС‚Рµ РІСЃРµ РїРѕР±РѕС‡РЅС‹Рµ РєРІРµСЃС‚С‹ Рё СЃС‚Р°РЅСЊС‚Рµ Р»РµРіРµРЅРґРѕР№",
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
			UniqueItems = {{Id = 1, Quantity = 1}}, -- РђРјСѓР»РµС‚ Р”СЂРµРІРЅРµРіРѕ РњР°СЃС‚РµСЂР°
			Items = {}
		},
		Prerequisites = {104}
	},
}

-- ============================================
-- РЎРёСЃС‚РµРјР° РєРІРµСЃС‚РѕРІ РёРіСЂРѕРєР°
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
	if not quest then return false, "РљРІРµСЃС‚ РЅРµ РЅР°Р№РґРµРЅ" end

	-- РџСЂРѕРІРµСЂСЏРµРј prerequisites
	for _, prereqId in ipairs(quest.Prerequisites) do
		if not self.CompletedQuests[prereqId] then
			return false, "РќРµ РІС‹РїРѕР»РЅРµРЅС‹ РїСЂРµРґРІР°СЂРёС‚РµР»СЊРЅС‹Рµ СѓСЃР»РѕРІРёСЏ"
		end
	end

	-- РџСЂРѕРІРµСЂСЏРµРј, РЅРµ РІР·СЏС‚ Р»Рё СѓР¶Рµ РєРІРµСЃС‚
	if self.ActiveQuests[questId] then
		return false, "РљРІРµСЃС‚ СѓР¶Рµ РІР·СЏС‚"
	end

	-- Р‘РµСЂС‘Рј РєРІРµСЃС‚
	self.ActiveQuests[questId] = true
	self.QuestProgress[questId] = {}

	for i, objective in ipairs(quest.Objectives) do
		self.QuestProgress[questId][i] = {
			Type = objective.Type,
			Current = 0,
			Target = objective.Count or objective.TargetLevel or 1
		}
	end

	QuestEvent:FireClient(self.Player, "QuestAccepted", {QuestId = questId})

	return true, "РљРІРµСЃС‚ РїСЂРёРЅСЏС‚!"
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

					-- РџСЂРѕРІРµСЂСЏРµРј РІС‹РїРѕР»РЅРµРЅРёРµ
					if self:AreAllObjectivesComplete(questId) then self:MarkReadyToTurnIn(questId)
					end

					-- РћС‚РїСЂР°РІР»СЏРµРј РѕР±РЅРѕРІР»РµРЅРёРµ
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
	QuestEvent:FireClient(self.Player, "QuestReadyToTurnIn", {QuestId = questId, QuestName = quest and quest.Name or "РљРІРµСЃС‚"})
end

function QuestSystem:TurnInQuest(questId)
	if not self.ReadyToTurnIn[questId] then return false, "РЎРЅР°С‡Р°Р»Р° РІС‹РїРѕР»РЅРёС‚Рµ РІСЃРµ С†РµР»Рё РєРІРµСЃС‚Р°" end
	if not self.ActiveQuests[questId] then return false, "РљРІРµСЃС‚ РЅРµ Р°РєС‚РёРІРµРЅ" end
	self:CompleteQuest(questId)
	return true, "РљРІРµСЃС‚ СЃРґР°РЅ!"
end

function QuestSystem:CompleteQuest(questId)
	local quest = QuestDatabase[questId]
	if not quest then return end

	-- Р’С‹РґР°С‘Рј РЅР°РіСЂР°РґС‹ С‡РµСЂРµР· DataStoreManager
	local DataStoreManagerModule = require(script.Parent.DataStoreManager)
	local dataStore = DataStoreManagerModule.new()
	local playerData = dataStore:GetPlayerData(self.Player.UserId)
	if playerData then
		-- РњРѕРЅРµС‚С‹ (С‚СЂРё С‚РёРїР°)
		playerData.CopperCoins = (playerData.CopperCoins or 0) + (quest.Rewards.CopperCoins or 0)
		playerData.SilverCoins = (playerData.SilverCoins or 0) + (quest.Rewards.SilverCoins or 0)
		playerData.GoldCoins = (playerData.GoldCoins or 0) + (quest.Rewards.GoldCoins or 0)

		-- РћРїС‹С‚ Рё СЂРµРїСѓС‚Р°С†РёСЏ
		playerData.Experience = (playerData.Experience or 0) + (quest.Rewards.Experience or 0)
		playerData.Reputation = (playerData.Reputation or 0) + (quest.Rewards.Reputation or 0)

		-- РЎС‚Р°С‚РёСЃС‚РёРєР°
		playerData.Stats.QuestsCompleted = (playerData.Stats.QuestsCompleted or 0) + 1
		NormalizeCurrency(playerData)

		-- РЈРЅРёРєР°Р»СЊРЅС‹Рµ РїСЂРµРґРјРµС‚С‹
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

		-- РћР±С‹С‡РЅС‹Рµ РїСЂРµРґРјРµС‚С‹
		if quest.Rewards.Items then
			for _, item in ipairs(quest.Rewards.Items) do
				local found = false
				for _, invItem in ipairs(playerData.Inventory) do
					if invItem.Id == item.Id then
						invItem.Quantity = invItem.Quantity + item.Quantity
						found = true
						break
					end
				end
				if not found then
					table.insert(playerData.Inventory, {Id = item.Id, Quantity = item.Quantity})
				end
			end
		end

		-- РћС‚РїСЂР°РІР»СЏРµРј РѕР±РЅРѕРІР»РµРЅРёРµ РєР»РёРµРЅС‚Сѓ
		DataEvent:FireClient(self.Player, "FullSync", playerData)
	end

	-- РћС‚РјРµС‡Р°РµРј РєР°Рє РІС‹РїРѕР»РЅРµРЅРЅРѕРµ
	self.ReadyToTurnIn[questId] = nil
	self.CompletedQuests[questId] = true
	self.ActiveQuests[questId] = nil
	self.QuestProgress[questId] = nil

	QuestEvent:FireClient(self.Player, "QuestCompleted", {
		QuestId = questId,
		Rewards = quest.Rewards,
		QuestName = quest.Name
	})

	print(self.Player.Name .. " РІС‹РїРѕР»РЅРёР» РєРІРµСЃС‚: " .. quest.Name)
end

function QuestSystem:GetQuestInfo(questId)
	return QuestDatabase[questId]
end

function QuestSystem:GetActiveQuests()
	local quests = {}
	for questId, _ in pairs(self.ActiveQuests) do
		table.insert(quests, {
			Quest = QuestDatabase[questId],
			Progress = self.QuestProgress[questId],
			ReadyToTurnIn = self.ReadyToTurnIn[questId] or false
		})
	end
	return quests
end

-- ============================================
-- РћР±СЂР°Р±РѕС‚С‡РёРєРё СЃРѕР±С‹С‚РёР№
-- ============================================

local function TriggerQuestMasterReaction(reaction)
	local qm = Workspace:FindFirstChild("QuestMaster")
	if qm then qm:SetAttribute("Reaction", reaction) end
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
			QuestEvent:FireClient(player, "QuestResult", {Success = false, Message = "РљРІРµСЃС‚С‹ РІС‹РґР°С‘С‚ С‚РѕР»СЊРєРѕ РєРІРµСЃС‚РѕСЂ СЂСЏРґРѕРј СЃ РІР°РјРё"})
			return
		end
		local questId = data.QuestId
		local success, message = questSystem:AcceptQuest(questId)
		QuestEvent:FireClient(player, "QuestResult", {Success = success, Message = message})

	elseif action == "GetActiveQuests" then
		local activeQuests = questSystem:GetActiveQuests()
		QuestEvent:FireClient(player, "ActiveQuests", {Quests = activeQuests})

	elseif action == "TurnInQuest" then
		if not CanUseQuestMasterAction(player, 26, 10) then
			QuestEvent:FireClient(player, "QuestResult", {Success = false, Message = "РЎРґР°С‚СЊ РєРІРµСЃС‚ РјРѕР¶РЅРѕ С‚РѕР»СЊРєРѕ Сѓ РєРІРµСЃС‚РѕСЂР°"})
			return
		end
		local questId = data.QuestId
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
-- РРЅС‚РµРіСЂР°С†РёСЏ NPC (ProximityPrompt)
-- ============================================

task.spawn(function()
	local questMaster = Workspace:WaitForChild("QuestMaster", 10)
	if not questMaster then
		warn("QuestMaster NPC РЅРµ РЅР°Р№РґРµРЅ РІ Workspace!")
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
		prompt.ActionText = "РџРѕРіРѕРІРѕСЂРёС‚СЊ"
		prompt.ObjectText = "РњРёРєР° В· РљРІРµСЃС‚РѕСЂ"
		prompt.Enabled = true
		prompt.MaxActivationDistance = 18
		prompt.RequiresLineOfSight = false
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		if not hookedPrompts[prompt] then
			hookedPrompts[prompt] = true
			prompt.Triggered:Connect(openFor)
			print("Quest Master ProximityPrompt РїРѕРґРєР»СЋС‡С‘РЅ!")
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
			print("Quest Master ClickDetector РїРѕРґРєР»СЋС‡С‘РЅ!")
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
-- РџСѓР±Р»РёС‡РЅР°СЏ С„СѓРЅРєС†РёСЏ РґР»СЏ РѕР±РЅРѕРІР»РµРЅРёСЏ РїСЂРѕРіСЂРµСЃСЃР°
-- ============================================

local function updateQuestProgress(player, progressType, data)
	local questSystem = PlayerQuestSystems[player.UserId]
	if questSystem then
		questSystem:UpdateProgress(progressType, data)
	end
end

-- Р­РєСЃРїРѕСЂС‚РёСЂСѓРµРј РґР»СЏ РґСЂСѓРіРёС… СЃРєСЂРёРїС‚РѕРІ
_G.UpdateQuestProgress = updateQuestProgress

-- ============================================
-- РРЅРёС†РёР°Р»РёР·Р°С†РёСЏ
-- ============================================

Players.PlayerAdded:Connect(function(player)
	GetOrCreateQuestSystem(player)
end)

-- РћР±СЂР°Р±РѕС‚РєР° РёРіСЂРѕРєРѕРІ СѓР¶Рµ РІ РёРіСЂРµ
for _, player in ipairs(Players:GetPlayers()) do
	GetOrCreateQuestSystem(player)
end

Players.PlayerRemoving:Connect(function(player)
	PlayerQuestSystems[player.UserId] = nil
	RecentQuestMasterInteraction[player.UserId] = nil
end)

print("Realm of Spirits - Quest System Р·Р°РіСЂСѓР¶РµРЅ!")

