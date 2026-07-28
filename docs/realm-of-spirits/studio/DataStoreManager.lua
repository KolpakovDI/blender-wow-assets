-- ============================================
-- Realm of Spirits - DataStore Manager
-- Сохранение и загрузка данных игроков
-- ============================================

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SpiritDatabase = require(ReplicatedStorage:WaitForChild("RealmOfSpirits"):WaitForChild("SpiritDatabase"))

-- ============================================
-- Конфигурация
-- ============================================

local DATA_STORE_NAME = "RealmOfSpirits_v2"
local AUTO_SAVE_INTERVAL = 300 -- 5 минут
local MAX_RETRIES = 3

-- ============================================
-- DataStore Manager
-- ============================================

local DataStoreManager = {}
DataStoreManager.__index = DataStoreManager

local function NormalizeCurrency(data)
	local c = tonumber(data.CopperCoins) or 0
	local s = tonumber(data.SilverCoins) or 0
	local g = tonumber(data.GoldCoins) or 0
	local total = c + s * 100 + g * 10000
	total = math.max(0, math.floor(total))
	data.GoldCoins = math.floor(total / 10000)
	total = total % 10000
	data.SilverCoins = math.floor(total / 100)
	data.CopperCoins = total % 100
end

local function NormalizeSpirits(data)
	if type(data.Spirits) ~= "table" then return end
	data.SpiritStamina = math.clamp(tonumber(data.SpiritStamina) or 100, 0, 100)
	if type(data.ResonanceDaily) ~= "table" then
		data.ResonanceDaily = { Date = "", Care = false, Temper = false }
	end
	if type(data.DailyBoard) ~= "table" then
		data.DailyBoard = {
			DayKey = "",
			Care = false,
			Temper = false,
			BattleWin = false,
			CatchOrChest = false,
			BonusNextDay = false,
			ClaimedSlots = {},
		}
	elseif type(data.DailyBoard.ClaimedSlots) ~= "table" then
		data.DailyBoard.ClaimedSlots = {}
	end
	if type(data.ShopDaily) ~= "table" then
		data.ShopDaily = { Date = "", Counts = {} }
	end
	data.ShowcaseSlots = math.max(0, math.floor(tonumber(data.ShowcaseSlots) or 0))
	if type(data.Showcase) ~= "table" then
		data.Showcase = {}
	end
	data.EventTokens = math.max(0, math.floor(tonumber(data.EventTokens) or 0))
	if type(data.SeasonPass) ~= "table" then
		data.SeasonPass = { SeasonId = "S1_Pilot", Xp = 0, Claimed = {} }
	end
	if type(data.SoftBuffs) ~= "table" then
		data.SoftBuffs = {}
	end
	if type(data.CrystalPity) ~= "table" then
		data.CrystalPity = { Misses = 0 }
	end
	data.CrystalPity.Misses = math.max(0, math.floor(tonumber(data.CrystalPity.Misses) or 0))
	for _, spirit in ipairs(data.Spirits) do
		if type(spirit) ~= "table" or not spirit.Id then continue end
		local catalog = SpiritDatabase.Get(spirit.Id)
		if not catalog then continue end
		if not spirit.Name or spirit.Name == "" or spirit.Name == "Неизвестный" then
			spirit.Name = catalog.Name
		end
		if not spirit.SkillIds and catalog.SkillIds then
			spirit.SkillIds = table.clone(catalog.SkillIds)
		end
		if (not spirit.Skills or #spirit.Skills == 0) then
			spirit.Skills = SpiritDatabase.GetSkillNames(catalog)
		end
		spirit.Bond = math.clamp(tonumber(spirit.Bond) or 0, 0, 10)
		spirit.BondXp = tonumber(spirit.BondXp) or 0
		if type(spirit.TemperPoints) ~= "table" then
			spirit.TemperPoints = { Attack = 0, Defense = 0, Spirit = 0 }
		end
	end
	local spirits = data.Spirits
	local idx = tonumber(data.ActiveSpiritIndex)
	if not idx or not spirits[idx] then
		idx = 1
		local want = tonumber(data.CurrentSpiritId)
		if want then
			for i, s in ipairs(spirits) do
				if s.Id == want then
					idx = i
					break
				end
			end
		end
		data.ActiveSpiritIndex = idx
	end
	if spirits[idx] then
		data.CurrentSpiritId = spirits[idx].Id
	end
end

local _instance = nil

function DataStoreManager.new()
	if _instance then
		return _instance
	end

	local self = setmetatable({}, DataStoreManager)

	self.DataStore = nil
	pcall(function()
		self.DataStore = DataStoreService:GetDataStore(DATA_STORE_NAME)
	end)
	if not self.DataStore then
		warn("DataStore недоступен (игра не опубликована). Данные будут храниться только в памяти.")
	end
	self.PlayerData = {}
	self.SaveQueue = {}
	self.IsSaving = {}

	_instance = self
	return self
end

function DataStoreManager:GetDefaultData()
	return {
		Level = 1,
		Experience = 0,
		SkillPoints = 0,
		BonusHP = 0,
		BonusAttack = 0,
		BonusDefense = 0,
		BonusSpeed = 0,
		BonusMP = 0,
		Rank = 1,
		RankTitle = "Новичок",
		CopperCoins = 50,
		SilverCoins = 10,
		GoldCoins = 0,
		Reputation = 0,
		Crystals = 10,
		Spirits = {
			{
				Id = 1,
				Name = "Огненный Кот",
				Level = 1,
				Experience = 0,
				Bond = 0,
				BondXp = 0,
				TemperFocus = nil,
				TemperPoints = { Attack = 0, Defense = 0, Spirit = 0 },
				Skills = {"Огненный коготь", "Пламенный всплеск"},
				SkillIds = {1, 2},
				CaughtAt = 0,
			},
		},
		CurrentSpiritId = 1,
		ActiveSpiritIndex = 1,
		SpiritStamina = 100,
		ResonanceDaily = { Date = "", Care = false, Temper = false },
		DailyBoard = {
			DayKey = "",
			Care = false,
			Temper = false,
			BattleWin = false,
			CatchOrChest = false,
			BonusNextDay = false,
			ClaimedSlots = {},
		},
		ShopDaily = { Date = "", Counts = {} },
		ShowcaseSlots = 0,
		Showcase = {},
		EventTokens = 0,
		SeasonPass = { SeasonId = "S1_Pilot", Xp = 0, Claimed = {} },
		SoftBuffs = {},
		CrystalPity = { Misses = 0 },
		Inventory = {
			{Id = 1, Quantity = 5},
			{Id = 2, Quantity = 3},
			{Id = 4, Quantity = 3},
			{Id = 5, Quantity = 2},
		},
		UniqueItems = {},
		Buffs = {},
		Cosmetics = {},
		ProcessedReceipts = {},
		ActiveQuests = {},
		CompletedQuests = {},
		QuestProgress = {},
		Stats = {
			EnemiesDefeated = 0,
			SpiritsCaught = 0,
			QuestsCompleted = 0,
			TotalPlayTime = 0,
		},
		Settings = {
			MusicVolume = 0.5,
			SFXVolume = 0.7,
			AutoLogin = true,
		},
		LastLogin = 0,
		FirstJoin = 0,
		TotalJoins = 0,
	}
end

function DataStoreManager:LoadData(player)
	local userId = player.UserId
	local success = false
	local data = nil
	local attempts = 0

	if not self.DataStore then
		success = true
	else
		while not success and attempts < MAX_RETRIES do
			attempts = attempts + 1
			local ok, result = pcall(function()
				return self.DataStore:GetAsync("Player_" .. userId)
			end)
			if ok then
				success = true
				data = result
			else
				warn("DataStore Load Attempt " .. attempts .. " failed for " .. player.Name .. ": " .. tostring(result))
				task.wait(1)
			end
		end
	end

	if not data then
		data = self:GetDefaultData()
		data.FirstJoin = os.time()
		data.TotalJoins = 1
		print(player.Name .. " - новые данные созданы")
	else
		data.LastLogin = os.time()
		data.TotalJoins = (data.TotalJoins or 0) + 1
		print(player.Name .. " - данные загружены (уровень: " .. data.Level .. ")")
	end

	NormalizeCurrency(data)
	NormalizeSpirits(data)
	self.PlayerData[userId] = data
	return data
end

function DataStoreManager:SaveData(player)
	local userId = player.UserId
	local data = self.PlayerData[userId]
	if not data then
		warn("No data to save for " .. player.Name)
		return false
	end
	if self.IsSaving[userId] then
		return false
	end
	self.IsSaving[userId] = true
	local success = false
	local attempts = 0
	if not self.DataStore then
		success = true
	else
		while not success and attempts < MAX_RETRIES do
			attempts = attempts + 1
			local ok, err = pcall(function()
				self.DataStore:SetAsync("Player_" .. userId, data)
			end)
			if ok then
				success = true
			else
				warn("DataStore Save Attempt " .. attempts .. " failed for " .. player.Name .. ": " .. tostring(err))
				task.wait(1)
			end
		end
	end
	self.IsSaving[userId] = nil
	if success then
		print(player.Name .. " - данные сохранены")
	else
		warn(player.Name .. " - ОШИБКА сохранения после " .. MAX_RETRIES .. " попыток")
	end
	return success
end

function DataStoreManager:GetPlayerData(userId)
	return self.PlayerData[userId]
end

function DataStoreManager:UpdateData(userId, updateFunc)
	local data = self.PlayerData[userId]
	if data then
		updateFunc(data)
		NormalizeCurrency(data)
		NormalizeSpirits(data)
	end
end

function DataStoreManager:StartAutoSave()
	task.spawn(function()
		while true do
			task.wait(AUTO_SAVE_INTERVAL)
			for _, player in ipairs(Players:GetPlayers()) do
				task.spawn(function()
					self:SaveData(player)
				end)
			end
			print("Auto-save completed for " .. #Players:GetPlayers() .. " players")
		end
	end)
end

function DataStoreManager:OnPlayerRemoving(player)
	self:SaveData(player)
	local userId = player.UserId
	local waitTime = 0
	while self.IsSaving[userId] and waitTime < 10 do
		task.wait(0.1)
		waitTime = waitTime + 0.1
	end
	self.PlayerData[userId] = nil
end

function DataStoreManager:BindToClose()
	game:BindToClose(function()
		print("Game closing - saving all players...")
		for _, player in ipairs(Players:GetPlayers()) do
			self:SaveData(player)
		end
		local waitTime = 0
		local anySaving = true
		while anySaving and waitTime < 10 do
			anySaving = false
			for userId, _ in pairs(self.IsSaving) do
				anySaving = true
				break
			end
			if anySaving then
				task.wait(0.1)
				waitTime = waitTime + 0.1
			end
		end
		print("All players saved")
	end)
end

function DataStoreManager:Initialize()
	self:StartAutoSave()
	Players.PlayerRemoving:Connect(function(player)
		self:OnPlayerRemoving(player)
	end)
	self:BindToClose()
	print("DataStore Manager инициализирован")
end

return DataStoreManager
