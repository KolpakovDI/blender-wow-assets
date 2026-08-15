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
-- Quest catalog (data) — ReplicatedStorage.RealmOfSpirits.QuestCatalog
-- ============================================
local QuestCatalog = require(realmFolder:WaitForChild("QuestCatalog"))

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

local function hasQuestFlag(map, questId)
	if not map then return false end
	local id = tonumber(questId) or questId
	if map[id] then return true end
	if type(id) == "number" and map[tostring(id)] then return true end
	if type(questId) == "string" and map[questId] then return true end
	return false
end

function QuestSystem:AcceptQuest(questId)
	questId = tonumber(questId) or questId
	local quest = QuestCatalog.Quests[questId]
	if not quest then return false, "Квест не найден" end
	if quest.Deprecated then
		return false, "Квест в архиве (вне канона 4×4)"
	end

	-- Проверяем prerequisites
	for _, prereqId in ipairs(quest.Prerequisites or {}) do
		if not hasQuestFlag(self.CompletedQuests, prereqId) then
			return false, "Не выполнены предварительные условия"
		end
	end

	-- Проверяем, не выполнен ли уже квест
	if hasQuestFlag(self.CompletedQuests, questId) then
		return false, "Квест уже выполнен"
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
				-- CatchSpecificSpirit НЕ сидим: уже имеющийся дух ≠ поимка в зоне охоты
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
		local quest = QuestCatalog.Quests[questId]
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
					elseif progressType == "VisitZone" then
						local want = objective.ZoneDetail
						local got = data and data.ZoneDetail
						if want and got and tostring(want) == tostring(got) then
							progress.Current = math.min((progress.Current or 0) + (data.Count or 1), progress.Target or 1)
						end
					elseif progressType == "CareSpirit" or progressType == "TemperSpirit"
						or progressType == "OpenKamiSanctum"
						or progressType == "KamiSynthesize"
						or progressType == "KamiDisintegrate" then
						progress.Current = math.min((progress.Current or 0) + (data and data.Count or 1), progress.Target or 1)
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
	local quest = QuestCatalog.Quests[questId]
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
	local quest = QuestCatalog.Quests[questId]
	QuestEvent:FireClient(self.Player, "QuestReadyToTurnIn", {QuestId = questId, QuestName = quest and quest.Name or "Квест"})
end

function QuestSystem:TurnInQuest(questId)
	questId = tonumber(questId) or questId
	if not self.ReadyToTurnIn[questId] then return false, "Сначала выполните все цели квеста" end
	if not self.ActiveQuests[questId] then return false, "Квест не активен" end
	local quest = QuestCatalog.Quests[questId]
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
					local want = tonumber(objective.ItemId)
					for _, inv in ipairs(playerData.Inventory or {}) do
						if tonumber(inv.Id) == want then
							have += (inv.Quantity or 0)
						end
					end
					if have < need then
						return false, "Недостаточно предметов для сдачи квеста"
					end
				end
			end
		else
			for _, objective in ipairs(quest.Objectives or {}) do
				if objective.Type == "CollectItem" then
					return false, "Данные игрока недоступны"
				end
			end
		end
	end
	local okComplete = self:CompleteQuest(questId)
	if not okComplete then
		return false, "Не удалось выдать награды"
	end
	return true, "Квест сдан!"
end

function QuestSystem:CompleteQuest(questId)
	local quest = QuestCatalog.Quests[questId]
	if not quest then return false end

	local playerData = nil
	if _G.GetPlayerData then
		playerData = _G.GetPlayerData(self.Player)
	else
		local DataStoreManagerModule = require(script.Parent.DataStoreManager)
		playerData = DataStoreManagerModule.new():GetPlayerData(self.Player.UserId)
	end
	if not playerData then
		warn("CompleteQuest: no playerData for", self.Player and self.Player.Name)
		return false
	end

	playerData.Stats = playerData.Stats or {}
	playerData.Inventory = playerData.Inventory or {}
	playerData.UniqueItems = playerData.UniqueItems or {}

		-- Списываем предметы CollectItem при сдаче (все стаки)
		for _, objective in ipairs(quest.Objectives or {}) do
			if objective.Type == "CollectItem" and objective.ItemId then
				local need = objective.Count or 1
				local want = tonumber(objective.ItemId)
				for idx = #playerData.Inventory, 1, -1 do
					if need <= 0 then break end
					local invItem = playerData.Inventory[idx]
					if tonumber(invItem.Id) == want then
						local qty = invItem.Quantity or 0
						local take = math.min(qty, need)
						invItem.Quantity = qty - take
						need -= take
						if invItem.Quantity <= 0 then
							table.remove(playerData.Inventory, idx)
						end
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
				local itemInfo = QuestCatalog.UniqueItems[item.Id]
				table.insert(playerData.UniqueItems, {
					Id = item.Id,
					Name = itemInfo and itemInfo.Name or "Unknown",
					Rarity = itemInfo and itemInfo.Rarity or "Common",
					Description = itemInfo and itemInfo.Description or "",
					Quantity = item.Quantity
				})
			end
		end

		local function grantItem(item)
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

		-- Обычные предметы
		if quest.Rewards.Items then
			for _, item in ipairs(quest.Rewards.Items) do
				grantItem(item)
			end
		end

		-- Шанс предмета (P2 Care treat etc.)
		if quest.Rewards.ItemsChance then
			for _, item in ipairs(quest.Rewards.ItemsChance) do
				local chance = tonumber(item.Chance) or 0
				if math.random() <= chance then
					grantItem(item)
				end
			end
		end

		-- P3: season Care/Temper soft now via SpiritResonance.MarkDailySlot (not quest turn-in)

		-- Отправляем обновление клиенту
		DataEvent:FireClient(self.Player, "FullSync", playerData)

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
	return true
end

function QuestSystem:GetQuestInfo(questId)
	return QuestCatalog.Quests[questId]
end

function QuestSystem:SyncInventoryObjectives(questId)
	questId = tonumber(questId) or questId
	local quest = QuestCatalog.Quests[questId]
	local progress = self.QuestProgress[questId] or self.QuestProgress[tostring(questId)]
	if not quest or not progress then return end
	if self.QuestProgress[questId] == nil and self.QuestProgress[tostring(questId)] then
		self.QuestProgress[questId] = self.QuestProgress[tostring(questId)]
	end
	local playerData = _G.GetPlayerData and _G.GetPlayerData(self.Player) or nil
	if not playerData then return end
	local function countInv(itemId)
		local n = 0
		local want = tonumber(itemId) or itemId
		for _, inv in ipairs(playerData.Inventory or {}) do
			if tonumber(inv.Id) == tonumber(want) or inv.Id == want then
				n += (inv.Quantity or 0)
			end
		end
		return n
	end
	for i, objective in ipairs(quest.Objectives or {}) do
		local p = progress[i]
		if not p and objective.Type == "CollectItem" then
			p = {
				Type = objective.Type,
				Current = 0,
				Target = objective.Count or 1,
			}
			progress[i] = p
		end
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
		local quest = QuestCatalog.Quests[questId]
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
	for questId, quest in pairs(QuestCatalog.Quests) do
		if quest.Deprecated then
			continue
		end
		if not hasQuestFlag(questSystem.ActiveQuests, questId) and not hasQuestFlag(questSystem.CompletedQuests, questId) then
			local canTake = true
			for _, prereqId in ipairs(quest.Prerequisites or {}) do
				if not hasQuestFlag(questSystem.CompletedQuests, prereqId) then
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
	-- Резонанс 301–304 сверху, затем уровень → Id
	table.sort(availableQuests, function(a, b)
		local function prio(q)
			local id = tonumber(q.Id) or 0
			if id >= 301 and id <= 304 then
				return id - 301 -- 0..3
			end
			return 100 + (tonumber(q.Level) or 1)
		end
		local pa, pb = prio(a), prio(b)
		if pa ~= pb then
			return pa < pb
		end
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
		table.insert(completed, QuestCatalog.Quests[questId])
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

local function MarkHubMika(player)
	local ok, HubFunnel = pcall(function()
		local rs = game:GetService("ReplicatedStorage"):FindFirstChild("RealmOfSpirits")
		return rs and require(rs:WaitForChild("HubFunnel"))
	end)
	if ok and HubFunnel and HubFunnel.MarkPlayer then
		HubFunnel.MarkPlayer(player, "Mika")
	end
end

QuestEvent.OnServerEvent:Connect(function(player, action, data)
	if typeof(action) ~= "string" then
		return
	end
	local questSystem = GetOrCreateQuestSystem(player)

	if action == "GetQuests" then
		MarkHubMika(player)
		local availableQuests = BuildAvailableQuests(questSystem)
		QuestEvent:FireClient(player, "QuestList", {Quests = availableQuests})

	elseif action == "AcceptQuest" then
		if not CanUseQuestMasterAction(player, 26, 10) then
			QuestEvent:FireClient(player, "QuestResult", {Success = false, Message = "Квесты выдаёт только квестор рядом с вами"})
			return
		end
		local questId = data and tonumber(data.QuestId)
		if not questId then
			QuestEvent:FireClient(player, "QuestResult", {Success = false, Message = "Некорректный запрос квеста"})
			return
		end
		local success, message = questSystem:AcceptQuest(questId)
		if success then MarkHubMika(player) end
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
		local questId = data and tonumber(data.QuestId)
		if not questId then
			QuestEvent:FireClient(player, "QuestResult", {Success = false, Message = "Некорректный запрос квеста"})
			return
		end
		local success, message = questSystem:TurnInQuest(questId)
		TriggerQuestMasterReaction(success and "Success" or "Fail")
		QuestEvent:FireClient(player, "QuestResult", {Success = success, Message = message, TurnIn = true})
		if success then
			local available = BuildAvailableQuests(questSystem)
			QuestEvent:FireClient(player, "QuestList", {Quests = available})
			QuestEvent:FireClient(player, "ActiveQuests", {Quests = questSystem:GetActiveQuests()})
			QuestEvent:FireClient(player, "CompletedQuests", {Quests = BuildCompletedQuests(questSystem)})
			QuestEvent:FireClient(player, "OpenQuestUI", {
				Available = available,
				Active = questSystem:GetActiveQuests(),
				Completed = BuildCompletedQuests(questSystem),
				PreferredTab = "Available",
			})
		end

	elseif action == "GetCompletedQuests" then
		local completed = {}
		for questId, _ in pairs(questSystem.CompletedQuests) do
			table.insert(completed, QuestCatalog.Quests[questId])
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
		local maxY, sumX, sumZ, n = -math.huge, 0, 0, 0
		for _, d in ipairs(questMaster:GetDescendants()) do
			if d:IsA("BasePart") and d.Name ~= "QuestInteractAnchor" and d.Transparency < 1 then
				local cf, sz = d.CFrame, d.Size
				local hy = math.abs(cf.UpVector.Y) * sz.Y * 0.5
					+ math.abs(cf.RightVector.Y) * sz.X * 0.5
					+ math.abs(cf.LookVector.Y) * sz.Z * 0.5
				maxY = math.max(maxY, cf.Position.Y + hy)
				sumX += cf.Position.X
				sumZ += cf.Position.Z
				n += 1
			end
		end
		local ax, headTop, az
		if n == 0 then
			local cf, sz = questMaster:GetBoundingBox()
			ax, headTop, az = cf.Position.X, cf.Position.Y + sz.Y * 0.5, cf.Position.Z
		else
			ax, headTop, az = sumX / n, maxY, sumZ / n
		end
		anchor.Size = Vector3.new(1.2, 1.2, 1.2)
		anchor.CFrame = CFrame.new(ax, headTop + 0.85, az)

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
		prompt.Style = Enum.ProximityPromptStyle.Default
		prompt.UIOffset = Vector2.new(0, 0)
		local hint = anchor:FindFirstChild("TalkHint")
		if not hint then
			hint = Instance.new("BillboardGui")
			hint.Name = "TalkHint"
			hint.Size = UDim2.new(0, 120, 0, 36)
			hint.StudsOffset = Vector3.new(0, 2.2, 0)
			hint.AlwaysOnTop = true
			hint.MaxDistance = 60
			hint.Parent = anchor
			local lbl = Instance.new("TextLabel")
			lbl.Name = "Label"
			lbl.Size = UDim2.fromScale(1, 1)
			lbl.BackgroundColor3 = Color3.fromRGB(40, 20, 50)
			lbl.BackgroundTransparency = 0.25
			lbl.Text = "КВЕСТ →"
			lbl.TextColor3 = Color3.fromRGB(255, 210, 240)
			lbl.Font = Enum.Font.GothamBold
			lbl.TextScaled = true
			lbl.Parent = hint
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 8)
			corner.Parent = lbl
		end
		hint.Enabled = false
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

if game:GetService("RunService"):IsStudio() then
	_G.GetOrCreateQuestSystem = GetOrCreateQuestSystem
end

-- Studio MCP QA BindableFunctions live under ServerScriptService.RealmOfSpirits
-- (QuestAcceptBF / QuestTurnInBF / QuestSeedCompletedBF / UpdateQuestProgressBF)

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
