-- ============================================
-- Realm of Spirits - DataStore Manager
-- Сохранение и загрузка данных игроков
-- Session lock + UpdateAsync (фаза 2 soft-launch)
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
-- Soft session lock: another server cannot overwrite while lock is fresh.
local SESSION_LOCK_TIMEOUT = 1800 -- 30 мин

-- ============================================
-- DataStore Manager
-- ============================================

local DataStoreManager = {}
DataStoreManager.__index = DataStoreManager

local function DeepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in pairs(value) do
		copy[k] = DeepCopy(v)
	end
	return copy
end

local function PlayerKey(userId: number): string
	return "Player_" .. tostring(userId)
end

local function MakeSessionMeta()
	return {
		JobId = game.JobId,
		PlaceId = game.PlaceId,
		Time = os.time(),
	}
end

local function IsForeignLockHeld(session): boolean
	if type(session) ~= "table" then
		return false
	end
	if session.JobId == game.JobId then
		return false
	end
	local lockedAt = tonumber(session.Time) or 0
	return (os.time() - lockedAt) < SESSION_LOCK_TIMEOUT
end

local function StripEphemeral(data)
	if type(data) ~= "table" then
		return data
	end
	local out = DeepCopy(data)
	out._DoNotSave = nil
	return out
end

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
		data.ResonanceDaily = { Date = "", Care = false, Temper = false, SanctumSynth = 0, SanctumDisintegrate = 0 }
	else
		data.ResonanceDaily.SanctumSynth = math.max(0, math.floor(tonumber(data.ResonanceDaily.SanctumSynth) or 0))
		data.ResonanceDaily.SanctumDisintegrate = math.max(0, math.floor(tonumber(data.ResonanceDaily.SanctumDisintegrate) or 0))
	end
	-- Resonant spirits: keep HybridPrimary / SkillIds
	for _, sp in ipairs(data.Spirits) do
		if type(sp) == "table" and sp.Kind == "Resonant" then
			sp.PrimaryElement = sp.HybridPrimary or sp.PrimaryElement or sp.Element or "Earth"
			sp.Element = sp.PrimaryElement
			if type(sp.SkillIds) ~= "table" then
				sp.SkillIds = {}
			end
		end
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
		spirit.Id = SpiritDatabase.MigrateId(spirit.Id)
		if spirit.Code == nil and SpiritDatabase.GetCode then
			spirit.Code = SpiritDatabase.GetCode(spirit.Id)
		end
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
	if data.CurrentSpiritId ~= nil then
		data.CurrentSpiritId = SpiritDatabase.MigrateId(data.CurrentSpiritId)
	end
	if not idx or not spirits[idx] then
		idx = 1
		local want = tonumber(data.CurrentSpiritId)
		if want then
			want = SpiritDatabase.MigrateId(want)
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
	self.LoadFailed = {}
	self.SessionOwned = {}

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
				Id = 11, Name = "Огненный Кот",
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
		CurrentSpiritId = 11,
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
	local key = PlayerKey(userId)
	local success = false
	local data = nil
	local attempts = 0
	local lockDenied = false

	if not self.DataStore then
		success = true
		data = nil
	else
		while not success and attempts < MAX_RETRIES do
			attempts = attempts + 1
			local transformDenied = false
			local ok, result = pcall(function()
				return self.DataStore:UpdateAsync(key, function(old)
					if IsForeignLockHeld(old and old._Session) then
						transformDenied = true
						return nil
					end
					local out
					if type(old) == "table" then
						out = DeepCopy(old)
						out.LastLogin = os.time()
						out.TotalJoins = (tonumber(out.TotalJoins) or 0) + 1
					else
						out = self:GetDefaultData()
						out.FirstJoin = os.time()
						out.TotalJoins = 1
					end
					out._DoNotSave = nil
					out._Session = MakeSessionMeta()
					return out
				end)
			end)
			if transformDenied then
				lockDenied = true
				break
			end
			if ok and type(result) == "table" then
				success = true
				data = result
			else
				warn("DataStore Load Attempt " .. attempts .. " failed for " .. player.Name .. ": " .. tostring(result))
				task.wait(0.5 * attempts)
			end
		end
	end

	if lockDenied then
		warn(player.Name .. " - session lock held elsewhere; DoNotSave")
		data = self:GetDefaultData()
		data.FirstJoin = os.time()
		data.TotalJoins = 1
		data._DoNotSave = true
		self.LoadFailed[userId] = true
		self.SessionOwned[userId] = false
	elseif self.DataStore and not success then
		warn(player.Name .. " - DataStore load FAILED; session marked DoNotSave")
		data = self:GetDefaultData()
		data.FirstJoin = os.time()
		data.TotalJoins = 1
		data._DoNotSave = true
		self.LoadFailed[userId] = true
		self.SessionOwned[userId] = false
	elseif not data then
		-- Unpublished / memory-only: no lock in DataStore
		data = self:GetDefaultData()
		data.FirstJoin = os.time()
		data.TotalJoins = 1
		data._Session = MakeSessionMeta()
		self.SessionOwned[userId] = true
		print(player.Name .. " - новые данные созданы")
	else
		self.SessionOwned[userId] = true
		print(player.Name .. " - данные загружены (уровень: " .. tostring(data.Level) .. ")")
	end

	NormalizeCurrency(data)
	NormalizeSpirits(data)
	self.PlayerData[userId] = data
	return data
end

-- releaseSession: clear _Session after write (leave / BindToClose)
function DataStoreManager:SaveData(player, releaseSession)
	local userId = player.UserId
	local data = self.PlayerData[userId]
	if not data then
		warn("No data to save for " .. player.Name)
		return false
	end
	if data._DoNotSave or self.LoadFailed[userId] then
		warn("Skip save for " .. player.Name .. " (load failed / DoNotSave)")
		return false
	end
	if self.IsSaving[userId] then
		return false
	end
	self.IsSaving[userId] = true
	local success = false
	local attempts = 0
	local key = PlayerKey(userId)

	if not self.DataStore then
		success = true
	else
		while not success and attempts < MAX_RETRIES do
			attempts = attempts + 1
			local skippedLock = false
			local ok, err = pcall(function()
				self.DataStore:UpdateAsync(key, function(old)
					if IsForeignLockHeld(old and old._Session) then
						skippedLock = true
						return nil
					end
					-- Prefer our session: if we never owned lock, still allow if unlocked/expired
					if self.SessionOwned[userId] == false then
						skippedLock = true
						return nil
					end
					local toSave = StripEphemeral(data)
					if releaseSession then
						toSave._Session = nil
					else
						toSave._Session = MakeSessionMeta()
					end
					return toSave
				end)
			end)
			if ok and not skippedLock then
				success = true
			elseif skippedLock then
				warn("DataStore Save skipped for " .. player.Name .. " (foreign session lock)")
				break
			else
				warn("DataStore Save Attempt " .. attempts .. " failed for " .. player.Name .. ": " .. tostring(err))
				task.wait(0.5 * attempts)
			end
		end
	end

	self.IsSaving[userId] = nil
	if success then
		if releaseSession then
			self.SessionOwned[userId] = false
		end
		print(player.Name .. " - данные сохранены" .. (releaseSession and " (session released)" or ""))
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
					self:SaveData(player, false)
				end)
			end
			print("Auto-save completed for " .. #Players:GetPlayers() .. " players")
		end
	end)
end

function DataStoreManager:OnPlayerRemoving(player)
	local userId = player.UserId
	-- Wait for in-flight save, then final save with session release
	local waitTime = 0
	while self.IsSaving[userId] and waitTime < 10 do
		task.wait(0.1)
		waitTime = waitTime + 0.1
	end
	self:SaveData(player, true)
	waitTime = 0
	while self.IsSaving[userId] and waitTime < 10 do
		task.wait(0.1)
		waitTime = waitTime + 0.1
	end
	self.SaveQueue[userId] = nil
	self.PlayerData[userId] = nil
	self.SessionOwned[userId] = nil
	self.LoadFailed[userId] = nil
end

function DataStoreManager:BindToClose()
	game:BindToClose(function()
		print("Game closing - saving all players...")
		for _, player in ipairs(Players:GetPlayers()) do
			self:SaveData(player, true)
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
