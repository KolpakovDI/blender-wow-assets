-- ============================================
-- Realm of Spirits - Game Manager
-- Серверная логика управления игрой с DataStore
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- AutoLoads true: Studio Play always gets a character (false caused empty-sky void)
Players.CharacterAutoLoads = true

-- Папка с RemoteEvents
local realmFolder = ReplicatedStorage:FindFirstChild("RealmOfSpirits")
if not realmFolder then
	realmFolder = Instance.new("Folder")
	realmFolder.Name = "RealmOfSpirits"
	realmFolder.Parent = ReplicatedStorage
end

local function GetRemoteEvent(name)
	local event = realmFolder:FindFirstChild(name)
	if not event then
		event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = realmFolder
	end
	return event
end

-- Подключаем DataStoreManager
local DataStoreManager = require(script.Parent.DataStoreManager)
local dataStore = DataStoreManager.new()

-- Подключаем EvolutionSystem
local EvolutionSystem = require(script.Parent.EvolutionSystem)
local evolutionSystem = EvolutionSystem.new()

-- Studio MCP QA hooks (same Server DataModel as game Scripts; _G is isolated in MCP)
do
	local function ensureBF(name)
		local bf = realmFolder:FindFirstChild(name)
		if bf and not bf:IsA("BindableFunction") then
			bf:Destroy()
			bf = nil
		end
		if not bf then
			bf = Instance.new("BindableFunction")
			bf.Name = name
			bf.Parent = realmFolder
		end
		return bf
	end

	ensureBF("GetPlayerDataBF").OnInvoke = function(userId)
		if not game:GetService("RunService"):IsStudio() then
			return nil
		end
		return dataStore:GetPlayerData(userId)
	end

	ensureBF("PrepareEvoBF").OnInvoke = function(userId, spiritId)
		local SpiritDatabase = require(realmFolder:WaitForChild("SpiritDatabase"))
		local data = dataStore:GetPlayerData(userId)
		if not data then
			return false, "no data"
		end
		local rule = SpiritDatabase.GetEvolutionRule(spiritId)
		if not rule then
			return false, "no evo rule"
		end
		local base = SpiritDatabase.Get(spiritId)
		if not base then
			return false, "no spirit"
		end
		data.Spirits = data.Spirits or {}
		local idx = nil
		for i, s in ipairs(data.Spirits) do
			if s.Id == spiritId then
				idx = i
				break
			end
		end
		if not idx then
			table.insert(data.Spirits, {
				Id = spiritId,
				Name = base.Name,
				Element = base.Element,
				Level = rule.RequiredLevel,
				Experience = 0,
				Stats = base.BaseStats,
				SkillIds = base.SkillIds,
				EnemiesDefeated = rule.RequiredBattles or 0,
				Bond = rule.RequiredBond or 0,
			})
			idx = #data.Spirits
		else
			local s = data.Spirits[idx]
			s.Level = math.max(s.Level or 1, rule.RequiredLevel or 1)
			s.EnemiesDefeated = math.max(s.EnemiesDefeated or 0, rule.RequiredBattles or 0)
			s.Bond = math.max(s.Bond or 0, rule.RequiredBond or 0)
		end
		data.Inventory = data.Inventory or {}
		for _, req in ipairs(rule.RequiredItems or {}) do
			local found = false
			for _, it in ipairs(data.Inventory) do
				if it.Id == req.Id then
					it.Quantity = math.max(it.Quantity or 0, req.Quantity or 1)
					found = true
					break
				end
			end
			if not found then
				table.insert(data.Inventory, {Id = req.Id, Quantity = req.Quantity or 1})
			end
		end
		data.Level = math.max(data.Level or 1, rule.RequiredLevel or 1)
		data.Stats = data.Stats or {}
		-- EvolutionSystem checks global Stats.EnemiesDefeated (same counter battle wins use)
		data.Stats.EnemiesDefeated = math.max(data.Stats.EnemiesDefeated or 0, rule.RequiredBattles or 0)
		return true, idx
	end

	ensureBF("EvolveSpiritBF").OnInvoke = function(userId, spiritIndex)
		if not game:GetService("RunService"):IsStudio() then
			return false, "studio only"
		end
		local data = dataStore:GetPlayerData(userId)
		if not data then
			return false, "no data"
		end
		local ok, result, meta = evolutionSystem:EvolveSpirit(spiritIndex, data)
		if ok then
			data.CurrentSpiritId = result.Id
			local plr = game.Players:GetPlayerByUserId(userId)
			if plr and (tonumber(data.ActiveSpiritIndex) or 1) == spiritIndex then
				plr:SetAttribute("ActiveSpiritName", result.Name or "")
			end
			local DataEvent = realmFolder:FindFirstChild("DataSync")
			if DataEvent and plr then
				DataEvent:FireClient(plr, "FullSync", data)
			end
		end
		return ok, result, meta or data.Spirits[spiritIndex]
	end

	-- Studio MCP QA: grant catch + quest progress without RNG / interaction lock
	ensureBF("ForceCatchBF").OnInvoke = function(userId, spiritId)
		spiritId = tonumber(spiritId)
		local player = Players:GetPlayerByUserId(userId)
		local data = dataStore:GetPlayerData(userId)
		if not player or not data then
			return false, "no player/data"
		end
		local SpiritDatabase = require(realmFolder:WaitForChild("SpiritDatabase"))
		local spirit = SpiritDatabase.Get(spiritId)
		if not spirit then
			return false, "no spirit"
		end
		data.Spirits = data.Spirits or {}
		table.insert(data.Spirits, {
			Id = spiritId,
			Name = spirit.Name,
			Level = 1,
			Experience = 0,
			Skills = SpiritDatabase.GetSkillNames(spirit),
			SkillIds = spirit.SkillIds and table.clone(spirit.SkillIds) or nil,
			CaughtAt = os.time(),
		})
		data.Stats = data.Stats or {}
		data.Stats.SpiritsCaught = (data.Stats.SpiritsCaught or 0) + 1
		data.Experience = (data.Experience or 0) + 50
		if _G.UpdateQuestProgress then
			_G.UpdateQuestProgress(player, "CatchSpirit")
			_G.UpdateQuestProgress(player, "CatchDifferentSpirits", {SpiritId = spiritId})
			_G.UpdateQuestProgress(player, "CatchSpecificSpirit", {SpiritId = spiritId})
		end
		local DataEvent = realmFolder:FindFirstChild("DataSync")
		if DataEvent then
			DataEvent:FireClient(player, "FullSync", data)
		end
		return true, spirit.Name, #data.Spirits
	end

	ensureBF("GrantItemBF").OnInvoke = function(userId, itemId, quantity)
		if not game:GetService("RunService"):IsStudio() then
			return false, "studio only"
		end
		userId = tonumber(userId)
		itemId = tonumber(itemId)
		quantity = tonumber(quantity) or 1
		local player = Players:GetPlayerByUserId(userId)
		local data = dataStore:GetPlayerData(userId)
		if not data then
			return false, "no data"
		end
		if _G.AddInventoryItem and player then
			_G.AddInventoryItem(player, itemId, quantity)
		else
			data.Inventory = data.Inventory or {}
			local found = false
			for _, inv in ipairs(data.Inventory) do
				if tonumber(inv.Id) == itemId then
					inv.Quantity = (inv.Quantity or 0) + quantity
					found = true
					break
				end
			end
			if not found then
				table.insert(data.Inventory, { Id = itemId, Quantity = quantity })
			end
		end
		if player and _G.UpdateQuestProgress then
			_G.UpdateQuestProgress(player, "CollectItem", { ItemId = itemId, Count = quantity })
		end
		local DataEvent = realmFolder:FindFirstChild("DataSync")
		if DataEvent and player then
			DataEvent:FireClient(player, "FullSync", dataStore:GetPlayerData(userId))
		end
		return true, itemId, quantity
	end
end

-- Подключаем LevelingSystem
local LevelingSystem = require(script.Parent.LevelingSystem)
local levelingSystem = LevelingSystem.new()

-- Подключаем RankSystem
local RankSystem = require(script.Parent.RankSystem)
local rankSystem = RankSystem.new()

local SpiritDatabase = require(realmFolder:WaitForChild("SpiritDatabase"))
local SkillCatalog = require(realmFolder:WaitForChild("SkillCatalog"))
local EffectCatalog = require(realmFolder:WaitForChild("EffectCatalog"))
local ItemCatalog = require(realmFolder:WaitForChild("ItemCatalog"))
local SpiritResonance = require(realmFolder:WaitForChild("SpiritResonance"))
local BattleOrchestrator = require(script.Parent:WaitForChild("BattleOrchestrator"))
local TradeSystem = require(script.Parent.TradeSystem)
local tradeSystem = TradeSystem.new()
local BuffSystem = require(script.Parent.BuffSystem)
local SpiritAnimation = require(script.Parent.SpiritAnimation)

local function GetSpirit(id)
	return SpiritDatabase.Get(id)
end

-- Resonant / custom roster entries are not in SpiritDatabase (Id 9xxx).
local function ResolveBattleSpiritInfo(playerSpirit)
	if type(playerSpirit) ~= "table" then
		return nil
	end
	local info = GetSpirit(playerSpirit.Id)
	if info then
		return info
	end
	local kind = tostring(playerSpirit.Kind or "")
	local idNum = tonumber(playerSpirit.Id) or 0
	if kind ~= "Resonant" and idNum < 9000 then
		return nil
	end
	local parentId = nil
	if type(playerSpirit.ParentIds) == "table" then
		parentId = tonumber(playerSpirit.ParentIds[1])
	end
	local parent = parentId and GetSpirit(parentId) or nil
	local base = (parent and parent.BaseStats) or { HP = 100, Attack = 20, Defense = 10, Speed = 10 }
	local el = playerSpirit.PrimaryElement or playerSpirit.HybridPrimary or playerSpirit.Element
		or (parent and (parent.PrimaryElement or parent.Element)) or "Fire"
	return {
		Id = playerSpirit.Id,
		Name = playerSpirit.Name or "Kami",
		BaseStats = {
			HP = tonumber(base.HP) or 100,
			Attack = tonumber(base.Attack) or 20,
			Defense = tonumber(base.Defense) or 10,
			Speed = tonumber(base.Speed) or 10,
		},
		SkillIds = playerSpirit.SkillIds,
		PrimaryElement = el,
		Element = el,
		Kind = "Resonant",
	}
end

-- RemoteEvents (используем папку RealmOfSpirits)
local CatchSpiritEvent = GetRemoteEvent("CatchSpirit")
local BattleEvent = GetRemoteEvent("Battle")
local TradeEvent = GetRemoteEvent("Trade")
local QuestEvent = GetRemoteEvent("Quest")
local DataEvent = GetRemoteEvent("DataSync")
local EvolutionEvent = GetRemoteEvent("EvolveSpirit")
local LevelingEvent = GetRemoteEvent("Leveling")
local RankEvent = GetRemoteEvent("Rank")
local ResonanceEvent = GetRemoteEvent("ResonanceEvent")

-- ============================================
-- Отслеживание активных боев
-- ============================================
local activeBattles = {}
local fullSyncCooldown = {} -- RequestFullSync anti-spam

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

-- Forward declarations for functions defined later
local GetPlayerData
local CreateSpiritModel
local HandlePlayerDeath
local UpdateSpiritHUD
local PlaySpiritDeathAnimation

-- ============================================
-- Обновление HUD духа (BillboardGui над головой)
-- ============================================
UpdateSpiritHUD = function(spiritModel, hp, maxHp, mp, maxMp)
	if not spiritModel or not spiritModel.Parent then return end
	local hud = spiritModel:FindFirstChild("StatsHUD")
	if not hud then return end

	local hpBar = hud:FindFirstChild("HPBar")
	local hpFill = hpBar and hpBar:FindFirstChild("HPFill")
	local hpText = hud:FindFirstChild("HPText")
	local mpBar = hud:FindFirstChild("MPBar")
	local mpFill = mpBar and mpBar:FindFirstChild("MPFill")
	local mpText = hud:FindFirstChild("MPText")

	if hpFill then
		local pct = maxHp > 0 and math.clamp(hp / maxHp, 0, 1) or 0
		hpFill.Size = UDim2.new(pct, 0, 1, 0)
		hpFill.BackgroundColor3 = Color3.fromRGB(
			math.floor(220 * (1 - pct) + 80 * pct),
			math.floor(80 * (1 - pct) + 220 * pct),
			80
		)
	end
	if hpText then
		hpText.Text = "HP " .. math.floor(hp) .. "/" .. math.floor(maxHp)
	end
	if mpFill then
		local pct = maxMp > 0 and math.clamp(mp / maxMp, 0, 1) or 0
		mpFill.Size = UDim2.new(pct, 0, 1, 0)
	end
	if mpText then
		mpText.Text = "MP " .. math.floor(mp) .. "/" .. math.floor(maxMp)
	end
end

-- ============================================
-- Анимация смерти духа: 2-сек исчезновение + вспышка
-- ============================================
local function SpawnCatchTrapUnderSpirit(spiritModel)
	if not spiritModel or not spiritModel.Parent then
		return nil
	end

	local function makeProceduralTrap()
		local model = Instance.new("Model")
		model.Name = "CatchTrapFX"
		local ring = Instance.new("Part")
		ring.Name = "TrapRing"
		ring.Shape = Enum.PartType.Cylinder
		ring.Size = Vector3.new(0.35, 5.5, 5.5)
		ring.Material = Enum.Material.Neon
		ring.Color = Color3.fromRGB(80, 220, 255)
		ring.Transparency = 0.15
		ring.Anchored = true
		ring.CanCollide = false
		ring.CanQuery = false
		ring.CanTouch = false
		ring.CFrame = CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0, math.rad(90))
		ring.Parent = model
		local core = Instance.new("Part")
		core.Name = "TrapCore"
		core.Shape = Enum.PartType.Ball
		core.Size = Vector3.new(1.8, 1.8, 1.8)
		core.Material = Enum.Material.Neon
		core.Color = Color3.fromRGB(255, 230, 120)
		core.Transparency = 0.1
		core.Anchored = true
		core.CanCollide = false
		core.CanQuery = false
		core.CanTouch = false
		core.Position = Vector3.new(0, 1.1, 0)
		core.Parent = model
		local light = Instance.new("PointLight")
		light.Brightness = 4
		light.Range = 16
		light.Color = Color3.fromRGB(120, 230, 255)
		light.Parent = core
		local bill = Instance.new("BillboardGui")
		bill.Size = UDim2.fromOffset(120, 28)
		bill.StudsOffset = Vector3.new(0, 2.4, 0)
		bill.AlwaysOnTop = true
		bill.Parent = core
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = "ЛОВУШКА"
		label.Font = Enum.Font.GothamBlack
		label.TextSize = 16
		label.TextColor3 = Color3.fromRGB(255, 240, 160)
		label.TextStrokeTransparency = 0.3
		label.Parent = bill
		model.PrimaryPart = ring
		return model
	end

	local template = nil
	local folder = ReplicatedStorage:FindFirstChild("SpiritTemplates")
	if folder then
		template = folder:FindFirstChild("SpiritTrapTemplate")
	end
	if not template then
		local ss = game:GetService("ServerStorage"):FindFirstChild("RealmOfSpirits")
		template = ss and ss:FindFirstChild("SpiritTrapTemplate")
	end

	local fx
	if template then
		local okClone, cloned = pcall(function()
			return template:Clone()
		end)
		if okClone and cloned then
			fx = cloned
		end
	end
	if not fx then
		warn("[RoS] SpiritTrapTemplate missing — procedural CatchTrapFX")
		fx = makeProceduralTrap()
	end

	fx.Name = "CatchTrapFX"
	for _, d in ipairs(fx:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			if d.Transparency > 0.55 then
				d.Transparency = 0.25
			end
			if typeof(d.LocalTransparencyModifier) == "number" and d.LocalTransparencyModifier > 0 then
				d.LocalTransparencyModifier = 0
			end
		end
		if d:IsA("Decal") or d:IsA("Texture") then
			if d.Transparency > 0.7 then
				d.Transparency = 0.2
			end
		end
	end
	if not fx.PrimaryPart then
		for _, d in ipairs(fx:GetDescendants()) do
			if d:IsA("BasePart") then
				fx.PrimaryPart = d
				break
			end
		end
	end
	fx.Parent = workspace

	local okPlace, errPlace = pcall(function()
		local bboxCF, bboxSize = spiritModel:GetBoundingBox()
		local groundY = bboxCF.Position.Y - bboxSize.Y * 0.5
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.FilterDescendantsInstances = { spiritModel, fx }
		local origin = bboxCF.Position + Vector3.new(0, 6, 0)
		local hit = workspace:Raycast(origin, Vector3.new(0, -120, 0), rayParams)
		if hit then
			groundY = hit.Position.Y
		end
		local tcf, tsz = fx:GetBoundingBox()
		local bottom = tcf.Position - Vector3.new(0, tsz.Y * 0.5, 0)
		local targetBottom = Vector3.new(bboxCF.Position.X, groundY + 0.08, bboxCF.Position.Z)
		fx:PivotTo(fx:GetPivot() + (targetBottom - bottom))
	end)
	if not okPlace then
		warn("[RoS] CatchTrap place failed: ", errPlace)
		local root = spiritModel.PrimaryPart or spiritModel:FindFirstChildWhichIsA("BasePart", true)
		if root then
			fx:PivotTo(CFrame.new(root.Position + Vector3.new(0, 0.5, 0)))
		end
	end
	return fx
end

local function PlaySpiritCatchAnimation(spiritModel, trapModel, succeeded, callback)
	if not spiritModel or not spiritModel.Parent then
		if trapModel and trapModel.Parent then trapModel:Destroy() end
		if callback then callback() end
		return
	end

	SpiritAnimation.Clear(spiritModel)
	spiritModel:SetAttribute("Dying", true)

	local TweenService = game:GetService("TweenService")
	local startCF = spiritModel:GetPivot()
	local trapPos = (trapModel and trapModel:GetPivot().Position) or startCF.Position
	local suckPos = Vector3.new(trapPos.X, trapPos.Y + 1.15, trapPos.Z)

	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < 0.4 do
			if not spiritModel.Parent then break end
			local shake = Vector3.new((math.random() - 0.5) * 0.4, (math.random() - 0.5) * 0.25, (math.random() - 0.5) * 0.4)
			spiritModel:PivotTo(startCF + shake)
			SpiritAnimation.ApplyFrame(spiritModel)
			task.wait()
		end

		local parts = {}
		for _, d in ipairs(spiritModel:GetDescendants()) do
			if d:IsA("BasePart") then
				table.insert(parts, { part = d, size = d.Size, trans = d.Transparency })
			end
		end

		local pullDur = 0.75
		local pullStart = os.clock()
		while os.clock() - pullStart < pullDur do
			if not spiritModel.Parent then break end
			local a = math.clamp((os.clock() - pullStart) / pullDur, 0, 1)
			local pos = startCF.Position:Lerp(suckPos, a)
			local scale = 1 - 0.88 * a
			spiritModel:PivotTo(CFrame.new(pos) * (startCF - startCF.Position))
			for _, info in ipairs(parts) do
				if info.part.Parent then
					info.part.Size = info.size * math.max(0.08, scale)
					info.part.Transparency = info.trans + (1 - info.trans) * a * 0.9
				end
			end
			task.wait()
		end

		if succeeded then
			if trapModel and trapModel.Parent then
				for _, d in ipairs(trapModel:GetDescendants()) do
					if d:IsA("BasePart") then
						TweenService:Create(d, TweenInfo.new(0.4), { Transparency = 1 }):Play()
					end
					if d:IsA("PointLight") then
						TweenService:Create(d, TweenInfo.new(0.4), { Brightness = 0 }):Play()
					end
				end
			end
			task.wait(0.45)
			if spiritModel.Parent then spiritModel:Destroy() end
			if trapModel and trapModel.Parent then trapModel:Destroy() end
		else
			for _, info in ipairs(parts) do
				if info.part.Parent then
					info.part.Size = info.size
					info.part.Transparency = info.trans
				end
			end
			if spiritModel.Parent then
				spiritModel:SetAttribute("Dying", false)
				spiritModel:PivotTo(startCF)
				SpiritAnimation.ApplyFrame(spiritModel)
			end
			if trapModel and trapModel.Parent then
				for _, d in ipairs(trapModel:GetDescendants()) do
					if d:IsA("BasePart") then
						TweenService:Create(d, TweenInfo.new(0.35), { Transparency = 1 }):Play()
					end
				end
				task.delay(0.4, function()
					if trapModel.Parent then trapModel:Destroy() end
				end)
			end
		end

		if callback then callback() end
	end)
end

PlaySpiritDeathAnimation = function(spiritModel, callback)
	if not spiritModel or not spiritModel.Parent then
		if callback then callback() end
		return
	end

	SpiritAnimation.Clear(spiritModel)
	spiritModel:SetAttribute("Dying", true)

	local TweenService = game:GetService("TweenService")
	local parts = {}
	for _, desc in ipairs(spiritModel:GetDescendants()) do
		if desc:IsA("BasePart") then
			table.insert(parts, desc)
		end
	end

	-- Плавное исчезновение (короче — быстрее цикл квеста)
	for _, part in ipairs(parts) do
		TweenService:Create(part, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Transparency = 1}):Play()
	end

	task.delay(0.85, function()
		if not spiritModel.PrimaryPart then
			spiritModel.Parent = nil
			if callback then callback() end
			return
		end

		-- Вспышка: расширяющийся неоновый шар + свет
		local flashPart = Instance.new("Part")
		flashPart.Shape = Enum.PartType.Ball
		flashPart.Material = Enum.Material.Neon
		flashPart.Color = Color3.fromRGB(255, 255, 255)
		flashPart.Size = Vector3.new(1, 1, 1)
		flashPart.Anchored = true
		flashPart.CanCollide = false
		flashPart.Transparency = 0
		flashPart.Position = spiritModel.PrimaryPart.Position
		flashPart.Parent = workspace

		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 255, 255)
		light.Brightness = 10
		light.Range = 15
		light.Parent = flashPart

		TweenService:Create(flashPart, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(12, 12, 12),
			Transparency = 1
		}):Play()
		TweenService:Create(light, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Brightness = 0
		}):Play()

		task.delay(0.5, function()
			flashPart.Parent = nil
		end)

		spiritModel.Parent = nil

		if callback then callback() end
	end)
end

-- ============================================
-- Обработка смерти игрока (анимация падения + респавн)
-- ============================================
local deathDebounce = {}

-- Soft respawn: keep PlayerGui / progress (no LoadCharacter wipe)
local function SoftRespawnAtSpawn(player, reason)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
	if humanoid and hrp and spawn then
		humanoid.Health = humanoid.MaxHealth
		local pos = spawn.Position + Vector3.new(0, 4, 0)
		character:PivotTo(CFrame.lookAt(pos, pos + Vector3.new(0, 0, 20)))
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	elseif player.Parent then
		player:LoadCharacter()
	end
	local data = GetPlayerData(player)
	if data then
		DataEvent:FireClient(player, "FullSync", data)
	end
	if reason then
		print("[RoS] SoftRespawn", player.Name, reason)
	end
end

HandlePlayerDeath = function(player)
	if deathDebounce[player.UserId] then return end
	deathDebounce[player.UserId] = true

	local character = player.Character
	if not character then
		if player.Parent then
			player:LoadCharacter()
		end
		task.defer(function()
			local data = GetPlayerData(player)
			if data then DataEvent:FireClient(player, "FullSync", data) end
		end)
		deathDebounce[player.UserId] = nil
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Не разбиваем персонажа на части — будет анимация падения
		humanoid.BreakJointsOnDeath = false
		if humanoid.Health > 0 then
			humanoid.Health = 0
		end
	end

	-- Респавн через 1.5 секунды на точке спавна
	task.delay(1.5, function()
		deathDebounce[player.UserId] = nil
		if player.Parent then
			player:LoadCharacter()
			task.defer(function()
				local data = GetPlayerData(player)
				if data then DataEvent:FireClient(player, "FullSync", data) end
			end)
		end
	end)
end

-- ============================================
-- Способности / эффекты — общие каталоги
-- ============================================
local function ResolveSkill(rawSkill, baseAttack)
	return SkillCatalog.Resolve(rawSkill, baseAttack)
end

local function BuildPlayerAbilities(spiritInfo)
	return BattleOrchestrator.BuildAbilities(spiritInfo, 3)
end

local function GetEnemyAbilities(enemyInfo)
	return BattleOrchestrator.BuildAbilities(enemyInfo, 3)
end

local function CreateEffectsState()
	return BattleOrchestrator.CreateEffectsState()
end

local function ApplySkillEffect(effect, sourceEffects, targetEffects)
	return EffectCatalog.Apply(effect, sourceEffects, targetEffects)
end

local function StepTimedEffects(effects)
	EffectCatalog.Step(effects)
end

local function ComputeDamage(baseDamage, attackerEffects, defenderEffects)
	return EffectCatalog.ComputeDamage(baseDamage, attackerEffects, defenderEffects)
end

local function ApplyBurnTick(currentHp, effects)
	return EffectCatalog.ApplyBurnTick(currentHp, effects)
end

-- ============================================
-- Вспомогательные функции боя
-- ============================================

local function GetInventoryCount(playerData, itemId)
	if not playerData or not tradeSystem then return 0 end
	return tradeSystem:CountItem(playerData, itemId)
end

local function GetBattleState(player, battle, message)
	local playerCooldowns = {}
	for i = 1, #battle.PlayerAbilities do
		local remaining = (battle.PlayerCooldowns[i] or 0) - os.clock()
		playerCooldowns[i] = math.max(0, remaining)
	end
	local playerSkills = {}
	for i, ability in ipairs(battle.PlayerAbilities or {}) do
		playerSkills[i] = {
			Name = ability.Name,
			Type = ability.Type,
			Element = ability.Element,
			Cost = ability.Cost or 0,
			Cooldown = playerCooldowns[i] or 0,
			MaxCooldown = tonumber(ability.Cooldown) or 0,
		}
	end
	local playerData = player and GetPlayerData(player)
	local potionCount = GetInventoryCount(playerData, 2)
	local potionCd = math.max(0, (battle.PotionCooldownUntil or 0) - os.clock())
	local SpiritDatabase = require(realmFolder:WaitForChild("SpiritDatabase"))
	local pRef = battle.PlayerSpirit and battle.PlayerSpirit.Id
	local eRef = (battle.EnemyInfo and battle.EnemyInfo.Id) or (battle.EnemySpirit and battle.EnemySpirit.Id)
	local elementTip, playerEl, enemyEl = "", "", ""
	if pRef and eRef and SpiritDatabase.FormatElementAgencyTip then
		elementTip = select(1, SpiritDatabase.FormatElementAgencyTip(pRef, eRef))
		playerEl = SpiritDatabase.FormatElementLabel(pRef)
		enemyEl = SpiritDatabase.FormatElementLabel(eRef)
	end
	local msg = message or ""
	if msg == "" and elementTip ~= "" then
		msg = elementTip
	end
	return {
		PlayerHP = battle.PlayerHP,
		PlayerMaxHP = battle.PlayerMaxHP,
		EnemyHP = battle.EnemyHP,
		EnemyMaxHP = battle.EnemyMaxHP,
		PlayerMP = math.floor(battle.PlayerMP),
		PlayerMaxMP = 100,
		EnemyMP = math.floor(battle.EnemyMP),
		EnemyMaxMP = 100,
		PlayerCooldowns = playerCooldowns,
		PlayerSkills = playerSkills,
		PotionCount = potionCount,
		PotionCooldown = potionCd,
		PotionHeal = 40,
		Turn = battle.Turn or 1,
		Message = msg,
		ElementTip = elementTip,
		PlayerElementLabel = playerEl,
		EnemyElementLabel = enemyEl,
	}
end

local function SetSpiritInteractionLocked(spiritModel, locked)
	if not spiritModel then return end
	if locked then
		spiritModel:SetAttribute("InteractionLocked", true)
		SpiritAnimation.SetMoving(spiritModel, false)
	else
		spiritModel:SetAttribute("InteractionLocked", nil)
		if not spiritModel:GetAttribute("Dying") then
			SpiritAnimation.SetMoving(spiritModel, true)
		end
	end
end

local function PlaySpiritAttackAnimation(spiritModel, targetPos)
	if not spiritModel or not spiritModel.Parent or spiritModel:GetAttribute("Dying") then return end
	local startCF = spiritModel:GetPivot()
	local startPos = startCF.Position
	local forward = startCF.LookVector
	if targetPos then
		local flat = Vector3.new(targetPos.X - startPos.X, 0, targetPos.Z - startPos.Z)
		if flat.Magnitude > 0.05 then
			forward = flat.Unit
		end
	end
	SpiritAnimation.SetMoving(spiritModel, false)
	task.spawn(function()
		local outDur = 0.14
		local outStart = os.clock()
		while os.clock() - outStart < outDur do
			if not spiritModel.Parent or spiritModel:GetAttribute("Dying") then return end
			local a = math.clamp((os.clock() - outStart) / outDur, 0, 1)
			local pos = startPos + forward * (1.25 * a) + Vector3.new(0, 0.08 * a, 0)
			spiritModel:PivotTo(CFrame.lookAt(pos, pos + forward))
			SpiritAnimation.ApplyFrame(spiritModel)
			task.wait()
		end

		local backDur = 0.12
		local backStart = os.clock()
		while os.clock() - backStart < backDur do
			if not spiritModel.Parent or spiritModel:GetAttribute("Dying") then return end
			local a = math.clamp((os.clock() - backStart) / backDur, 0, 1)
			local t = 1 - a
			local pos = startPos + forward * (1.25 * t) + Vector3.new(0, 0.08 * t, 0)
			spiritModel:PivotTo(CFrame.lookAt(pos, pos + forward))
			SpiritAnimation.ApplyFrame(spiritModel)
			task.wait()
		end

		if spiritModel.Parent and not spiritModel:GetAttribute("Dying") then
			spiritModel:PivotTo(startCF)
			SpiritAnimation.ResetPose(spiritModel)
		end
	end)
end

local function EndBattle(player, winner, battle)
	battle.Active = false
	activeBattles[player.UserId] = nil
	if _G.HideBattleBlade then
		_G.HideBattleBlade(player)
	end
	SetSpiritInteractionLocked(battle and battle.EnemyModel, false)

	if winner == "Player" then
		if battle.EnemyModel and battle.EnemyModel.Parent then
			local respawnPos = battle.EnemyModel:GetAttribute("SpawnPosition")
			if not respawnPos and battle.EnemyModel.PrimaryPart then
				respawnPos = battle.EnemyModel.PrimaryPart.Position
			end
			local respawnId = battle.EnemyId
			PlaySpiritDeathAnimation(battle.EnemyModel, function()
				-- Быстрый респавн для квестов Defeat/фарма (было 10с)
				task.delay(2, function()
					CreateSpiritModel(respawnId, respawnPos)
				end)
			end)
		end

		local expReward = 50
		local playerData = GetPlayerData(player)
		local ItemCatalog = require(ReplicatedStorage:WaitForChild("RealmOfSpirits"):WaitForChild("ItemCatalog"))
		local coinReward = ItemCatalog.BattleCoinReward(playerData.Level)
		playerData.Experience = playerData.Experience + expReward
		playerData.CopperCoins = (playerData.CopperCoins or 0) + coinReward
		NormalizeCurrency(playerData)
		do
			local okLive, SeasonLiveOps = pcall(function()
				return require(script.Parent.SeasonLiveOps)
			end)
			if okLive and SeasonLiveOps and SeasonLiveOps.OnBattleWin then
				SeasonLiveOps.OnBattleWin(playerData)
			end
			if SpiritResonance and SpiritResonance.MarkDailySlot then
				SpiritResonance.MarkDailySlot(playerData, "BattleWin")
			end
		end
		playerData.Stats.EnemiesDefeated = playerData.Stats.EnemiesDefeated + 1

		local leveledUp, _, rewards = levelingSystem:CheckLevelUp(playerData)
		if leveledUp then
			for _, reward in ipairs(rewards) do
				DataEvent:FireClient(player, "LevelUp", {
					NewLevel = reward.Level,
					BonusCoins = reward.Coins
				})
			end
		end

		BattleEvent:FireClient(player, "End", {
			Winner = "Player",
			Rewards = {Experience = expReward, Coins = coinReward, CopperCoins = coinReward}
		})
		DataEvent:FireClient(player, "FullSync", playerData)

		if _G.UpdateQuestProgress then
			_G.UpdateQuestProgress(player, "DefeatEnemies")
		end

		-- Spirit Resonance: battle XP + party share
		SpiritResonance.EnsurePlayer(playerData)
		SpiritResonance.RegenStamina(playerData, 8)
		local currentId = playerData.CurrentSpiritId
		local activeSpirit = nil
		for _, s in ipairs(playerData.Spirits or {}) do
			if s.Id == currentId then
				activeSpirit = s
				break
			end
		end
		local baseXp = activeSpirit and SpiritResonance.BattleXpForSpirit(activeSpirit) or 25
		local maxSpiritLevel = SpiritResonance.GrantBattleXp(playerData, currentId, baseXp)
		if _G.UpdateQuestProgress and maxSpiritLevel > 0 then
			_G.UpdateQuestProgress(player, "LevelUpSpirit", {Level = maxSpiritLevel})
		end
		DataEvent:FireClient(player, "FullSync", playerData)
	else
		BattleEvent:FireClient(player, "End", {
			Winner = "Enemy",
			Rewards = {Experience = 0, Coins = 0}
		})
		-- Не LoadCharacter: иначе StarterGui/UI сбрасывает прогресс на клиенте
		SoftRespawnAtSpawn(player, "battle_defeat")
		local loseData = GetPlayerData(player)
		if loseData then
			DataEvent:FireClient(player, "FullSync", loseData)
		end
	end
end

local function PopupsFromAttackResult(player, battle, result, targetSide)
	local popups = {}
	if not result or not result.Ok or result.Kind ~= "Attack" then
		return popups
	end
	local pos
	if targetSide == "Enemy" and battle.EnemyModel and battle.EnemyModel.Parent then
		pos = battle.EnemyModel:GetPivot().Position + Vector3.new(0, 3, 0)
	elseif targetSide == "Player" then
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			pos = root.Position + Vector3.new(0, 2.5, 0)
		end
	end
	if not pos then
		return popups
	end
	local function add(amount, yOffset)
		amount = math.floor(tonumber(amount) or 0)
		if amount <= 0 then return end
		local offset = yOffset or 0
		table.insert(popups, {
			Amount = amount,
			Target = targetSide,
			Position = pos + Vector3.new(0, offset, 0),
		})
	end
	add(result.Damage, 0)
	add(result.BurnDamage, 0.6)
	return popups
end

local function SendBattleUpdate(player, battle, message, damagePopups)
	if not battle or not battle.Active or activeBattles[player.UserId] ~= battle then
		return
	end
	local state = GetBattleState(player, battle, message)
	if damagePopups and #damagePopups > 0 then
		state.DamagePopups = damagePopups
	end
	BattleEvent:FireClient(player, "Update", state)
	-- Обновляем HUD духа-противника в 3D мире
	if battle.EnemyModel and battle.EnemyModel.Parent then
		UpdateSpiritHUD(battle.EnemyModel, battle.EnemyHP, battle.EnemyMaxHP, battle.EnemyMP, 100)
	end
end

local function StartEnemyAI(player, battle)
	task.spawn(function()
		while battle.Active and activeBattles[player.UserId] do
			task.wait(0.3)
			BattleOrchestrator.RegenMana(battle, 0.5, 0.3)

			local skillIndex = BattleOrchestrator.PickReadyEnemySkill(battle)
			if not skillIndex then
				continue
			end

			local result = BattleOrchestrator.ExecuteEnemySkill(battle, skillIndex, {})
			if result.Kind == "Stun" then
				SendBattleUpdate(player, battle, result.Message)
				continue
			end
			if not result.Ok then
				continue
			end

			if battle.EnemyModel and battle.EnemyModel.Parent then
				PlaySpiritAttackAnimation(battle.EnemyModel, player.Character and player.Character.PrimaryPart and player.Character.PrimaryPart.Position)
			end

			if result.Ended then
				SendBattleUpdate(player, battle, result.Message, PopupsFromAttackResult(player, battle, result, "Player"))
				EndBattle(player, result.Winner or "Enemy", battle)
				return
			end
			SendBattleUpdate(player, battle, result.Message, PopupsFromAttackResult(player, battle, result, "Player"))
		end
	end)
end

-- ============================================
-- Начальные позиции спавна духов в мире
-- ============================================

local function GetGroundPosition(x, z, excludeList)
	local rayParams = RaycastParams.new()
	local exclude = {}
	if excludeList then
		for _, inst in ipairs(excludeList) do
			table.insert(exclude, inst)
		end
	end
	for _, modelName in ipairs({ "OtakuHaven", "Akihabara", "BattleArena" }) do
		local model = workspace:FindFirstChild(modelName)
		if model then
			local zones = model:FindFirstChild("Zones")
			if zones then
				for _, part in ipairs(zones:GetChildren()) do
					table.insert(exclude, part)
				end
			end
			for _, desc in ipairs(model:GetDescendants()) do
				if desc:IsA("BasePart") and desc:GetAttribute("ZoneType") then
					table.insert(exclude, desc)
				end
			end
		end
	end
	local spiritsFolder = workspace:FindFirstChild("Spirits")
	if spiritsFolder then
		for _, spiritModel in ipairs(spiritsFolder:GetChildren()) do
			if spiritModel:IsA("Model") then
				table.insert(exclude, spiritModel)
			end
		end
	end
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = exclude

	local origin = Vector3.new(x, 200, z)
	local direction = Vector3.new(0, -400, 0)
	for _ = 1, 12 do
		local result = workspace:Raycast(origin, direction, rayParams)
		if not result then
			break
		end
		local hit = result.Instance
		if hit:GetAttribute("ZoneType") or (hit.Parent and hit.Parent.Name == "Zones") then
			table.insert(exclude, hit)
			rayParams.FilterDescendantsInstances = exclude
		elseif hit:FindFirstAncestor("BattleArena") then
			table.insert(exclude, hit)
			rayParams.FilterDescendantsInstances = exclude
		else
			return result.Position
		end
	end
	return Vector3.new(x, 0.5, z)
end

local function GetModelLowestY(model)
	local lowest = math.huge
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then
			local cf = desc.CFrame
			local half = desc.Size * 0.5
			for _, ox in ipairs({-half.X, half.X}) do
				for _, oy in ipairs({-half.Y, half.Y}) do
					for _, oz in ipairs({-half.Z, half.Z}) do
						local y = cf:PointToWorldSpace(Vector3.new(ox, oy, oz)).Y
						if y < lowest then
							lowest = y
						end
					end
				end
			end
		end
	end
	return lowest
end

local function EnsureModelPrimaryPart(model)
	if model.PrimaryPart then return model.PrimaryPart end
	local body = model:FindFirstChild("body")
	if body then
		local geom = body:FindFirstChild("body_geom") or body:FindFirstChildWhichIsA("BasePart")
		if geom then model.PrimaryPart = geom return geom end
	end
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") and desc.Name:find("body_geom") then
			model.PrimaryPart = desc
			return desc
		end
	end
	-- AI meshes / simple templates: pick largest BasePart
	local best, bestVol = nil, -1
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then
			local v = desc.Size.X * desc.Size.Y * desc.Size.Z
			if v > bestVol then
				bestVol = v
				best = desc
			end
		end
	end
	if best then
		model.PrimaryPart = best
		return best
	end
	return nil
end

local function PlaceModelOnGround(model, targetPos)
	if not EnsureModelPrimaryPart(model) then return end
	local current = model:GetPivot()
	local look = current.LookVector
	local flatLook = Vector3.new(look.X, 0, look.Z)
	if flatLook.Magnitude < 0.01 then
		flatLook = Vector3.new(0, 0, -1)
	end
	local upright = CFrame.lookAt(Vector3.new(targetPos.X, 0, targetPos.Z), Vector3.new(targetPos.X, 0, targetPos.Z) + flatLook.Unit, Vector3.new(0, 1, 0))
	model:PivotTo(upright)
	local ground = GetGroundPosition(targetPos.X, targetPos.Z, { model })
	local lowestY = GetModelLowestY(model)
	if lowestY < math.huge then
		model:PivotTo(model:GetPivot() + Vector3.new(0, ground.Y + 0.05 - lowestY, 0))
	end
end

local SpiritSpawnPositions = require(ReplicatedStorage:WaitForChild("RealmOfSpirits"):WaitForChild("ZoneConfig")).GetSpiritSpawnPositions()

CreateSpiritModel = function(spiritId, position, spiritRow)
	local spiritInfo = GetSpirit(spiritId)
	if not spiritInfo and type(spiritRow) == "table" then
		-- Resonant / custom: synthetic catalog row for naming/animation
		spiritInfo = {
			Id = spiritId,
			Name = spiritRow.Name or ("Дух " .. tostring(spiritId)),
			Element = spiritRow.PrimaryElement or spiritRow.HybridPrimary or spiritRow.Element or "Earth",
			PrimaryElement = spiritRow.PrimaryElement or spiritRow.HybridPrimary,
		}
	end
	if not spiritInfo then return nil end

	local SpiritMeshResolve = require(ReplicatedStorage:WaitForChild("RealmOfSpirits"):WaitForChild("SpiritMeshResolve"))
	-- Offline: template by Id/ParentIds, else geometric placeholder (AI MeshAssetId deferred)
	local spirit = SpiritMeshResolve.CloneResolvedModel(spiritRow or spiritId, spiritInfo.Name)
	spirit.Name = spiritInfo.Name

	-- Устанавливаем PrimaryPart (AI meshes often lack body_geom)
	EnsureModelPrimaryPart(spirit)

	-- Размещаем модель в точке спавна
	PlaceModelOnGround(spirit, position)
	if spiritId == 32 then
		PlaceModelOnGround(spirit, spirit:GetPivot().Position)
		SpiritAnimation.ResetPose(spirit)
	end
	SpiritAnimation.Setup(spirit, spiritInfo, GetGroundPosition)
	SpiritAnimation.StartLoop(spirit)
	local moveType = SpiritAnimation.GetMovementType(spiritInfo)
	if moveType == "Fly" or moveType == "Swim" then
		SpiritAnimation.Place(spirit, position, PlaceModelOnGround, GetGroundPosition)
		if moveType == "Swim" then
			local swimCenter = spirit:GetAttribute("SwimCenter")
			if typeof(swimCenter) == "Vector3" then
				spirit:SetAttribute("SpawnPosition", swimCenter)
			end
		end
	else
		SpiritAnimation.ResetPose(spirit)
	end
	position = spirit:GetPivot().Position

	-- Сохраняем позицию спавна для случайного перемещения
	spirit:SetAttribute("SpawnPosition", position)
	spirit:SetAttribute("Dying", false)
	spirit:SetAttribute("SpiritInstanceId", game:GetService("HttpService"):GenerateGUID(false))

	for _, desc in ipairs(spirit:GetDescendants()) do
		if desc:IsA("BasePart") then
			-- Match classic spirit templates: no physics tumble while wandering
			desc.Anchored = true
			desc.CanCollide = false
			desc.CanTouch = false
			desc.CanQuery = true
			desc.Massless = true
		end
	end

	-- Добавляем SpiritId
	local spiritIdValue = Instance.new("IntValue")
	spiritIdValue.Name = "SpiritId"
	spiritIdValue.Value = spiritId
	spiritIdValue.Parent = spirit

	-- Вычисляем высоту модели для смещения HUD
	local _, size = spirit:GetBoundingBox()
	local hudHeight = size.Y + 2

	-- HUD (BillboardGui): скрыт по умолчанию, клиент показывает 1.5с при наведении
	local hud = Instance.new("BillboardGui")
	hud.Name = "StatsHUD"
	hud.Size = UDim2.new(0, 140, 0, 55)
	hud.StudsOffset = Vector3.new(0, hudHeight, 0)
	hud.MaxDistance = 200
	hud.Enabled = false
	if spirit.PrimaryPart then
		hud.Adornee = spirit.PrimaryPart
	end
	hud.Parent = spirit

	-- Имя духа
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "SpiritName"
	nameLabel.Size = UDim2.new(1, 0, 0, 16)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = spiritInfo.Name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 12
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.Parent = hud

	-- HP бар (фон)
	local hpBar = Instance.new("Frame")
	hpBar.Name = "HPBar"
	hpBar.Size = UDim2.new(1, -4, 0, 12)
	hpBar.Position = UDim2.new(0, 2, 0, 18)
	hpBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	hpBar.BorderSizePixel = 0
	hpBar.Parent = hud
	local hpCorner = Instance.new("UICorner")
	hpCorner.CornerRadius = UDim.new(0, 4)
	hpCorner.Parent = hpBar

	-- HP бар (заливка)
	local hpFill = Instance.new("Frame")
	hpFill.Name = "HPFill"
	hpFill.Size = UDim2.new(1, 0, 1, 0)
	hpFill.BackgroundColor3 = Color3.fromRGB(80, 220, 80)
	hpFill.BorderSizePixel = 0
	hpFill.Parent = hpBar
	local hpFillCorner = Instance.new("UICorner")
	hpFillCorner.CornerRadius = UDim.new(0, 4)
	hpFillCorner.Parent = hpFill

	-- HP текст
	local hpText = Instance.new("TextLabel")
	hpText.Name = "HPText"
	hpText.Size = UDim2.new(1, 0, 0, 12)
	hpText.Position = UDim2.new(0, 0, 0, 18)
	hpText.BackgroundTransparency = 1
	hpText.Text = "HP " .. spiritInfo.BaseStats.HP .. "/" .. spiritInfo.BaseStats.HP
	hpText.TextColor3 = Color3.fromRGB(255, 255, 255)
	hpText.TextSize = 9
	hpText.Font = Enum.Font.SourceSans
	hpText.Parent = hud

	-- MP бар (фон)
	local mpBar = Instance.new("Frame")
	mpBar.Name = "MPBar"
	mpBar.Size = UDim2.new(1, -4, 0, 12)
	mpBar.Position = UDim2.new(0, 2, 0, 33)
	mpBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	mpBar.BorderSizePixel = 0
	mpBar.Parent = hud
	local mpCorner = Instance.new("UICorner")
	mpCorner.CornerRadius = UDim.new(0, 4)
	mpCorner.Parent = mpBar

	-- MP бар (заливка)
	local mpFill = Instance.new("Frame")
	mpFill.Name = "MPFill"
	mpFill.Size = UDim2.new(1, 0, 1, 0)
	mpFill.BackgroundColor3 = Color3.fromRGB(80, 80, 255)
	mpFill.BorderSizePixel = 0
	mpFill.Parent = mpBar
	local mpFillCorner = Instance.new("UICorner")
	mpFillCorner.CornerRadius = UDim.new(0, 4)
	mpFillCorner.Parent = mpFill

	-- MP текст
	local mpText = Instance.new("TextLabel")
	mpText.Name = "MPText"
	mpText.Size = UDim2.new(1, 0, 0, 12)
	mpText.Position = UDim2.new(0, 0, 0, 33)
	mpText.BackgroundTransparency = 1
	mpText.Text = "MP 100/100"
	mpText.TextColor3 = Color3.fromRGB(255, 255, 255)
	mpText.TextSize = 9
	mpText.Font = Enum.Font.SourceSans
	mpText.Parent = hud

	-- Помещаем в папку Spirits
	local spiritsFolder = workspace:FindFirstChild("Spirits")
	if not spiritsFolder then
		spiritsFolder = Instance.new("Folder")
		spiritsFolder.Name = "Spirits"
		spiritsFolder.Parent = workspace
	end
	spirit.Parent = spiritsFolder

	-- Случайное перемещение в радиусе 5 стадов
	task.spawn(function()
		while spirit.Parent and not spirit:GetAttribute("Dying") do
			task.wait(math.random(2, 5))
			if not spirit.Parent or spirit:GetAttribute("Dying") then break end
			if spirit:GetAttribute("InteractionLocked") then
				SpiritAnimation.SetMoving(spirit, false)
				continue
			end
			local spawnPos = spirit:GetAttribute("SpawnPosition")
			if spawnPos then
				local angle = math.random() * math.pi * 2
				local maxRadius = 5
				if spirit:GetAttribute("MovementType") == "Swim" then
					local swimCenter = spirit:GetAttribute("SwimCenter")
					if typeof(swimCenter) == "Vector3" then
						spawnPos = swimCenter
					end
					maxRadius = tonumber(spirit:GetAttribute("SwimRadius")) or 14
				end
				local radius = math.random() * maxRadius
				local targetPos = spawnPos + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
				local startCF = spirit:GetPivot()
				local moveDir = Vector3.new(targetPos.X - startCF.Position.X, 0, targetPos.Z - startCF.Position.Z)
				local targetRot = startCF - startCF.Position
				if moveDir.Magnitude > 0.1 then targetRot = CFrame.lookAt(Vector3.zero, moveDir) end
				local targetCF = CFrame.new(Vector3.new(targetPos.X, startCF.Position.Y, targetPos.Z)) * targetRot
				local duration = 1.5
				SpiritAnimation.SetMoving(spirit, true)
				local startTime = os.clock()
				while os.clock() - startTime < duration do
					if not spirit.Parent or spirit:GetAttribute("Dying") or spirit:GetAttribute("InteractionLocked") then break end
					local alpha = math.clamp((os.clock() - startTime) / duration, 0, 1)
					alpha = alpha * alpha * (3 - 2 * alpha)
					SpiritAnimation.MoveStep(spirit, startCF, targetPos, alpha, PlaceModelOnGround, GetGroundPosition)
					SpiritAnimation.ApplyFrame(spirit)
					task.wait()
				end
				SpiritAnimation.SetMoving(spirit, false)
				if not spirit:GetAttribute("InteractionLocked") then
					SpiritAnimation.Place(spirit, targetPos, PlaceModelOnGround, GetGroundPosition)
					spirit:SetAttribute("SpawnPosition", spirit:GetPivot().Position)
				end
			end
		end
	end)

	return spirit
end

local function FindSpiritByInstanceId(instanceId)
	if not instanceId or instanceId == "" then return nil end
	local spirits = workspace:FindFirstChild("Spirits")
	if not spirits then return nil end
	for _, spirit in ipairs(spirits:GetChildren()) do
		if spirit:GetAttribute("SpiritInstanceId") == instanceId then
			return spirit
		end
	end
	return nil
end

local function ValidateSpiritTarget(player, spiritModel, maxDistance)
	if not spiritModel or not spiritModel.Parent or spiritModel:GetAttribute("Dying") then
		return false, "Дух недоступен"
	end
	if spiritModel:GetAttribute("InteractionLocked") then
		return false, "Дух занят"
	end
	local char = player.Character
	local root = char and (char.PrimaryPart or char:FindFirstChild("HumanoidRootPart"))
	local spiritRoot = spiritModel.PrimaryPart or EnsureModelPrimaryPart(spiritModel)
	if not root or not spiritRoot then
		return false, "Подойдите ближе"
	end
	local dist = (root.Position - spiritRoot.Position).Magnitude
	if dist > (maxDistance or 45) then
		return false, "Слишком далеко!"
	end
	return true
end

local function FindSpiritModel(enemyId, playerPosition)
	local spirits = workspace:FindFirstChild("Spirits")
	if not spirits then return nil end

	local closestSpirit = nil
	local closestDistance = math.huge

	for _, spirit in ipairs(spirits:GetChildren()) do
		local spiritIdValue = spirit:FindFirstChild("SpiritId")
		if spiritIdValue and spiritIdValue.Value == enemyId and spirit.PrimaryPart then
			local distance = (spirit.PrimaryPart.Position - playerPosition).Magnitude
			if distance < closestDistance then
				closestDistance = distance
				closestSpirit = spirit
			end
		end
	end

	return closestSpirit
end

-- ============================================
-- Получение данных игрока
-- ============================================
GetPlayerData = function(player)
	return dataStore:GetPlayerData(player.UserId)
end
_G.GetPlayerData = GetPlayerData

local function NormalizeInventoryServer(inventory)
	local byId = {}
	if type(inventory) == "table" then
		for _, inv in pairs(inventory) do
			if type(inv) == "table" then
				local id = tonumber(inv.Id) or tonumber(inv.id)
				local qty = math.floor(tonumber(inv.Quantity) or tonumber(inv.quantity) or 0)
				if id and qty > 0 then
					byId[id] = (byId[id] or 0) + qty
				end
			end
		end
	end
	local out = {}
	local ids = {}
	for id in pairs(byId) do
		table.insert(ids, id)
	end
	table.sort(ids)
	for _, id in ipairs(ids) do
		table.insert(out, { Id = id, Quantity = byId[id] })
	end
	return out
end

function _G.AddInventoryItem(player, itemId, quantity)
	local playerData = GetPlayerData(player)
	if not playerData then
		return false, 0
	end
	itemId = tonumber(itemId)
	quantity = math.max(1, math.floor(tonumber(quantity) or 1))
	if not itemId then
		return false, 0
	end
	playerData.Inventory = NormalizeInventoryServer(playerData.Inventory)
	local total = quantity
	local found = false
	for _, inv in ipairs(playerData.Inventory) do
		if inv.Id == itemId then
			inv.Quantity = (tonumber(inv.Quantity) or 0) + quantity
			total = inv.Quantity
			found = true
			break
		end
	end
	if not found then
		table.insert(playerData.Inventory, { Id = itemId, Quantity = quantity })
		total = quantity
	end
	playerData.Inventory = NormalizeInventoryServer(playerData.Inventory)
	local invIds, invQtys = {}, {}
	for i, item in ipairs(playerData.Inventory) do
		invIds[i] = item.Id
		invQtys[i] = item.Quantity
	end
	if DataEvent then
		DataEvent:FireClient(player, "InventorySync", {
			InvIds = invIds,
			InvQtys = invQtys,
			ItemId = itemId,
			Quantity = total,
			Type = "Item",
			CopperCoins = playerData.CopperCoins,
			SilverCoins = playerData.SilverCoins,
			GoldCoins = playerData.GoldCoins,
		})
	end
	return true, total
end

-- ============================================
-- Обновление данных игрока
-- ============================================
local function UpdatePlayerData(player, updateFunc)
	dataStore:UpdateData(player.UserId, updateFunc)
end

-- ============================================
-- Обработчики событий
-- ============================================

-- Ловля духов
CatchSpiritEvent.OnServerEvent:Connect(function(player, spiritId, instanceId)
	local data = GetPlayerData(player)
	if not data then return end
	spiritId = tonumber(spiritId)
	if typeof(instanceId) ~= "string" then
		instanceId = tostring(instanceId or "")
	end
	if not spiritId or instanceId == "" then
		return
	end
	data.Inventory = data.Inventory or {}
	data.Stats = data.Stats or {}

	local spirit = GetSpirit(spiritId)
	if not spirit then return end

	local spiritModel = FindSpiritByInstanceId(instanceId)
	if not spiritModel then
		DataEvent:FireClient(player, "Error", {Message = "Цель не найдена"})
		return
	end
	do
		local sid = spiritModel:FindFirstChild("SpiritId")
		if not sid or sid.Value ~= spiritId then return end
		local ok, errMsg = ValidateSpiritTarget(player, spiritModel, 45)
		if not ok then
			DataEvent:FireClient(player, "Error", {Message = errMsg})
			return
		end
		SetSpiritInteractionLocked(spiritModel, true)
		-- Safety: never leave spirit permanently locked/dying after a catch attempt
		task.delay(5, function()
			if spiritModel and spiritModel.Parent then
				if spiritModel:GetAttribute("InteractionLocked") or spiritModel:GetAttribute("Dying") then
					spiritModel:SetAttribute("Dying", false)
					SetSpiritInteractionLocked(spiritModel, false)
				end
			end
		end)
	end

	-- Проверяем наличие ловушки
	local trapIndex = nil
	for i, item in ipairs(data.Inventory) do
		if item.Id == 1 and item.Quantity > 0 then
			trapIndex = i
			break
		end
	end

	if not trapIndex then
		if spiritModel then
			SetSpiritInteractionLocked(spiritModel, false)
		end
		DataEvent:FireClient(player, "Error", {Message = "Нет ловушек!"})
		return
	end

	-- Уменьшаем количество ловушек (рюкзак)
	data.Inventory[trapIndex].Quantity = data.Inventory[trapIndex].Quantity - 1

	-- Ловушка появляется под духом + анимация поимки
	local catchTrap = nil
	if spiritModel and spiritModel.Parent then
		catchTrap = SpawnCatchTrapUnderSpirit(spiritModel)
	end

	-- Проверяем шанс поимки (обычные духи ловятся заметно чаще на старте)
	local catchChance = tonumber(spirit.CatchRate) or 0.2
	local rarity = spirit.Rarity or "Common"
	if rarity == "Common" then
		catchChance = math.max(catchChance, 0.62)
	elseif rarity == "Uncommon" then
		catchChance = math.max(catchChance, 0.42)
	end
	local pLevel = tonumber(data.Level) or 1
	if pLevel <= 5 then
		catchChance = math.min(0.9, catchChance + (6 - pLevel) * 0.03)
	end
	local success = math.random() <= catchChance

	local function afterCatchVisual()
		CatchSpiritEvent:FireClient(player, success, spirit.Name)
	end

	if success then
		local newSpirit = {
			Id = spiritId,
			Name = spirit.Name,
			Level = 1,
			Experience = 0,
			Skills = SpiritDatabase.GetSkillNames(spirit),
			SkillIds = spirit.SkillIds and table.clone(spirit.SkillIds) or nil,
			CaughtAt = os.time()
		}
		table.insert(data.Spirits, newSpirit)

		data.Experience = data.Experience + 50
		data.Stats.SpiritsCaught = data.Stats.SpiritsCaught + 1

		local leveledUp, levelsGained, rewards = levelingSystem:CheckLevelUp(data)
		if leveledUp then
			for _, reward in ipairs(rewards) do
				DataEvent:FireClient(player, "LevelUp", {
					NewLevel = reward.Level,
					BonusCoins = reward.Coins
				})
			end
		end

		DataEvent:FireClient(player, "SpiritCaught", {
			Spirit = newSpirit,
			SpiritInfo = spirit
		})
		DataEvent:FireClient(player, "FullSync", data)

		print(player.Name .. " поймал " .. spirit.Name)

		if _G.UpdateQuestProgress then
			_G.UpdateQuestProgress(player, "CatchSpirit")
			_G.UpdateQuestProgress(player, "CatchDifferentSpirits", {SpiritId = spiritId})
			_G.UpdateQuestProgress(player, "CatchSpecificSpirit", {SpiritId = spiritId})
		end
		if SpiritResonance and SpiritResonance.MarkDailySlot then
			SpiritResonance.MarkDailySlot(data, "CatchOrChest")
		end

		PlaySpiritCatchAnimation(spiritModel, catchTrap, true, afterCatchVisual)
	else
		DataEvent:FireClient(player, "CatchFailed", {
			SpiritName = spirit.Name
		})
		DataEvent:FireClient(player, "FullSync", data)
		print(player.Name .. " не смог поймать " .. spirit.Name)

		PlaySpiritCatchAnimation(spiritModel, catchTrap, false, function()
			if spiritModel and spiritModel.Parent then
				spiritModel:SetAttribute("Dying", false)
				SetSpiritInteractionLocked(spiritModel, false)
			end
			afterCatchVisual()
		end)
	end
end)

-- Битва
BattleEvent.OnServerEvent:Connect(function(player, action, data)
	if typeof(action) ~= "string" then
		return
	end
	if _G.PvPDuelHandleBattleAction and _G.PvPDuelHandleBattleAction(player, action, data) then
		return
	end
	local playerData = GetPlayerData(player)
	if not playerData then return end

	if action == "Start" then
		if _G.PvPDuelIsBusy and _G.PvPDuelIsBusy(player) then
			DataEvent:FireClient(player, "Error", {Message = "Сначала завершите дуэль"})
			return
		end
		local enemyId = tonumber(data and data.EnemyId)
		if not enemyId then return end
		-- Проверяем, есть ли у игрока дух
		local spirits = playerData.Spirits or {}
		if #spirits == 0 then
			DataEvent:FireClient(player, "Error", {Message = "У вас нет духов!"})
			return
		end

		-- Проверяем, не в бою ли уже игрок
		if activeBattles[player.UserId] then
			DataEvent:FireClient(player, "Error", {Message = "Вы уже в бою!"})
			return
		end

		-- Active spirit is server-authoritative (ignore spoofed client PlayerSpiritId)
		local idx = tonumber(playerData.ActiveSpiritIndex)
		if not idx or not spirits[idx] then
			idx = 1
			local want = tonumber(playerData.CurrentSpiritId)
			if want then
				for i, s in ipairs(spirits) do
					if s.Id == want then
						idx = i
						break
					end
				end
			end
			playerData.ActiveSpiritIndex = idx
		end
		local playerSpirit = spirits[idx]
		playerData.CurrentSpiritId = playerSpirit.Id

		local spiritInfo = ResolveBattleSpiritInfo(playerSpirit)
		local enemyInfo = GetSpirit(enemyId)

		if not spiritInfo or not enemyInfo then return end

		-- Создаём данные битвы (серверное состояние)
		-- Ранняя игра: чуть больше HP игроку, враг чуть слабее по запасу
		local maxPlayerHP = spiritInfo.BaseStats.HP + (playerSpirit.Level * 12) + 15 + (playerSpirit.BonusHP or 0)
		local maxEnemyHP = enemyInfo.BaseStats.HP
		if playerSpirit.Level <= 5 then
			maxEnemyHP = math.max(40, math.floor(maxEnemyHP * (0.72 + playerSpirit.Level * 0.04)))
		end

		-- Находим модель духа в мире
		local playerChar = player.Character
		local playerPos = playerChar and playerChar.PrimaryPart and playerChar.PrimaryPart.Position or Vector3.new(0, 0, 0)
		local enemyModel = FindSpiritByInstanceId(data and data.TargetInstanceId)
		if not enemyModel then
			DataEvent:FireClient(player, "Error", {Message = "Цель не найдена"})
			return
		end
		local ok, errMsg = ValidateSpiritTarget(player, enemyModel, 45)
		if not ok then
			DataEvent:FireClient(player, "Error", {Message = errMsg})
			return
		end
		local sid = enemyModel:FindFirstChild("SpiritId")
		if not sid or sid.Value ~= enemyId then
			DataEvent:FireClient(player, "Error", {Message = "Неверная цель"})
			return
		end

		local battleData = {
			PlayerSpiritId = playerSpirit.Id,
			EnemyId = enemyId,
			PlayerHP = maxPlayerHP,
			PlayerMaxHP = maxPlayerHP,
			EnemyHP = maxEnemyHP,
			EnemyMaxHP = maxEnemyHP,
			PlayerMP = 100,
			EnemyMP = 100,
			Turn = 1,
			Active = true,
			PlayerSpirit = playerSpirit,
			EnemyInfo = enemyInfo,
			SpiritInfo = spiritInfo,
			EnemyModel = enemyModel,
			PlayerAbilities = BuildPlayerAbilities({
				Id = playerSpirit.Id,
				BaseStats = spiritInfo.BaseStats,
				BonusAttack = playerSpirit.BonusAttack,
				SkillIds = playerSpirit.SkillIds or spiritInfo.SkillIds,
				UniqueSkill = playerSpirit.UniqueSkill,
			}),
			PlayerCooldowns = {},
			EnemyAbilities = GetEnemyAbilities(enemyInfo),
			EnemyCooldowns = {},
			PlayerEffects = CreateEffectsState(),
			EnemyEffects = CreateEffectsState(),
			DexAttackPct = 0,
			DexDefensePct = 0,
		}
		do
			local dex = SpiritResonance.GetDexBonus(playerData, SpiritDatabase)
			battleData.DexAttackPct = tonumber(dex and dex.AttackPct) or 0
			battleData.DexDefensePct = tonumber(dex and dex.DefensePct) or 0
		end
		do
			local SkillCatalog = require(realmFolder:WaitForChild("SkillCatalog"))
			local pAtk, pDef = SkillCatalog.GetElementPassiveMods(SpiritDatabase.GetPrimary(spiritInfo))
			local eAtk, eDef = SkillCatalog.GetElementPassiveMods(SpiritDatabase.GetPrimary(enemyInfo))
			battleData.ElementPassiveAtkPct = pAtk
			battleData.ElementPassiveDefPct = pDef
			battleData.EnemyElementPassiveAtkPct = eAtk
			battleData.EnemyElementPassiveDefPct = eDef
		end

		activeBattles[player.UserId] = battleData
		if _G.ShowBattleBlade then
			_G.ShowBattleBlade(player)
		end

		if enemyModel then
			SetSpiritInteractionLocked(enemyModel, true)
			PlaySpiritAttackAnimation(enemyModel, playerPos)
		end
		SendBattleUpdate(player, battleData, "Битва началась! " .. enemyInfo.Name .. " готовится к атаке!")
		StartEnemyAI(player, battleData)
		print(player.Name .. " начал битву с " .. enemyInfo.Name)

	elseif action == "Attack" then
		local battle = activeBattles[player.UserId]
		if not battle then return end

		local skillIndex = math.clamp(math.floor(tonumber(data and data.SkillIndex) or 1), 1, 3)
		local playerData = GetPlayerData(player)
		local dmgMul = playerData and BuffSystem.GetDamageMultiplier(playerData) or 1
		local result = BattleOrchestrator.ExecutePlayerSkill(battle, skillIndex, {
			DamageMultiplier = dmgMul,
		})
		if not result.Ok then
			SendBattleUpdate(player, battle, result.Message or "Навык недоступен")
			return
		end

		local targetPos = nil
		if battle.EnemyModel and battle.EnemyModel.Parent then
			targetPos = battle.EnemyModel:GetPivot().Position
		end
		if _G.ShowBattleBlade then
			_G.ShowBattleBlade(player)
		end
		BattleEvent:FireClient(player, "PlayPlayerAttack", {
			Mode = "Battle",
			TargetPosition = targetPos,
			SkillId = result.Ability and result.Ability.Id,
		})
		if battle.EnemyModel and battle.EnemyModel.Parent then
			PlaySpiritAttackAnimation(battle.EnemyModel, player.Character and player.Character.PrimaryPart and player.Character.PrimaryPart.Position)
		end

		local popups = PopupsFromAttackResult(player, battle, result, "Enemy")
		if result.Ended then
			SendBattleUpdate(player, battle, result.Message, popups)
			EndBattle(player, result.Winner or "Player", battle)
		else
			SendBattleUpdate(player, battle, result.Message, popups)
		end

	elseif action == "UsePotion" then
		local battle = activeBattles[player.UserId]
		if not battle or not battle.Active then return end
		if battle.PlayerHP <= 0 then return end
		if os.clock() < (battle.PotionCooldownUntil or 0) then
			local left = math.max(0, battle.PotionCooldownUntil - os.clock())
			SendBattleUpdate(player, battle, string.format("Зелье перезаряжается: %.1fс", left))
			return
		end
		if battle.PlayerHP >= battle.PlayerMaxHP then
			SendBattleUpdate(player, battle, "HP уже полное")
			return
		end
		local ok, msg, def = tradeSystem:ConsumeItem(playerData, 2)
		if not ok then
			SendBattleUpdate(player, battle, msg or "Нет зелий")
			return
		end
		local heal = (def and def.HealAmount) or 40
		local before = battle.PlayerHP
		battle.PlayerHP = math.min(battle.PlayerMaxHP, battle.PlayerHP + heal)
		local gained = battle.PlayerHP - before
		battle.PotionCooldownUntil = os.clock() + 3
		DataEvent:FireClient(player, "FullSync", playerData)
		SendBattleUpdate(player, battle, string.format("Зелье: +%d HP (осталось %d)", gained, GetInventoryCount(playerData, 2)))

	elseif action == "Flee" then
		local battle = activeBattles[player.UserId]
		if not battle then return end

		local fleeChance = math.random(1, 100)
		if fleeChance > 50 then
			-- Успешный побег
			battle.Active = false
			activeBattles[player.UserId] = nil
			if _G.HideBattleBlade then
				_G.HideBattleBlade(player)
			end
			SetSpiritInteractionLocked(battle.EnemyModel, false)
			BattleEvent:FireClient(player, "Flee", {Success = true})
		else
			-- Не удалось сбежать — враг продолжит атаковать через AI
			BattleEvent:FireClient(player, "Flee", {Success = false})
			SendBattleUpdate(player, battle, "Не удалось сбежать!")
		end
	end
end)

-- ============================================
-- Spirit Resonance (Bond / Temper / Dex snapshot)
-- ============================================
ResonanceEvent.OnServerEvent:Connect(function(player, action, data)
	local playerData = GetPlayerData(player)
	if not playerData then
		return
	end
	SpiritResonance.EnsurePlayer(playerData)

	if action == "GetState" then
		ResonanceEvent:FireClient(player, "State", SpiritResonance.GetClientSnapshot(playerData))
		return
	end

	if action == "Care" then
		local idx = math.floor(tonumber(data and data.SpiritIndex) or (playerData.ActiveSpiritIndex or 1))
		local useTreat = data and data.UseTreat == true
		local ok, msg = SpiritResonance.Care(playerData, idx, useTreat)
		if ok then
			-- Prefer _G; Studio UpdateQuestProgressBF expects UserId (not Player)
			if _G.UpdateQuestProgress then
				_G.UpdateQuestProgress(player, "CareSpirit", {Count = 1})
			else
				local qbf = script.Parent:FindFirstChild("UpdateQuestProgressBF")
				if qbf and qbf:IsA("BindableFunction") then
					pcall(function()
						qbf:Invoke(player.UserId, "CareSpirit", {Count = 1})
					end)
				end
			end
			ResonanceEvent:FireClient(player, "CareSuccess", {Message = msg, Snapshot = SpiritResonance.GetClientSnapshot(playerData)})
			DataEvent:FireClient(player, "FullSync", playerData)
		else
			ResonanceEvent:FireClient(player, "CareFailed", {Reason = msg})
		end
		return
	end

	if action == "Temper" then
		local idx = math.floor(tonumber(data and data.SpiritIndex) or (playerData.ActiveSpiritIndex or 1))
		local focus = (data and data.Focus) or "Attack"
		local ok, msg = SpiritResonance.Temper(playerData, idx, focus)
		if ok then
			if _G.UpdateQuestProgress then
				_G.UpdateQuestProgress(player, "TemperSpirit", {Count = 1})
			else
				local qbf = script.Parent:FindFirstChild("UpdateQuestProgressBF")
				if qbf and qbf:IsA("BindableFunction") then
					pcall(function()
						qbf:Invoke(player.UserId, "TemperSpirit", {Count = 1})
					end)
				end
			end
			ResonanceEvent:FireClient(player, "TemperSuccess", {Message = msg, Snapshot = SpiritResonance.GetClientSnapshot(playerData)})
			DataEvent:FireClient(player, "FullSync", playerData)
		else
			ResonanceEvent:FireClient(player, "TemperFailed", {Reason = msg})
		end
		return
	end

	if action == "GetDex" then
		local bonus = SpiritResonance.GetDexBonus(playerData, SpiritDatabase)
		ResonanceEvent:FireClient(player, "DexBonus", bonus)
	end
end)

-- ============================================
-- Эволюция духов
-- ============================================
EvolutionEvent.OnServerEvent:Connect(function(player, action, data)
	if typeof(action) ~= "string" then
		return
	end
	local playerData = GetPlayerData(player)
	if not playerData then return end

	if action == "GetEvolutions" then
		local evolutions = evolutionSystem:GetAvailableEvolutions(playerData)
		EvolutionEvent:FireClient(player, "EvolutionsList", {Evolutions = evolutions})

	elseif action == "Evolve" then
		local spiritIndex = math.floor(tonumber(data and data.SpiritIndex) or 1)
		local spirits = playerData.Spirits or {}
		if spiritIndex < 1 or spiritIndex > #spirits then
			EvolutionEvent:FireClient(player, "EvolutionFailed", {Reason = "Дух не найден"})
			return
		end
		local before = spirits[spiritIndex]
		local oldId = before and before.Id
		local success, result, meta = evolutionSystem:EvolveSpirit(spiritIndex, playerData)
		if success then
			playerData.CurrentSpiritId = result.Id
			if (tonumber(playerData.ActiveSpiritIndex) or 1) == spiritIndex then
				player:SetAttribute("ActiveSpiritName", result.Name or "")
			end
			-- Identity slice 2: showcase entry Id/Name follow evolve → mesh refresh
			if type(playerData.Showcase) == "table" and oldId ~= nil then
				for _, entry in pairs(playerData.Showcase) do
					if type(entry) == "table" and tonumber(entry.Id) == tonumber(oldId) then
						entry.Id = result.Id
						entry.Name = result.Name or entry.Name
						entry.Level = result.Level or entry.Level
						entry.Bond = result.Bond or entry.Bond
					end
				end
			end
			if type(_G.RoS_ShowcaseOnSpiritEvolved) == "function" then
				pcall(_G.RoS_ShowcaseOnSpiritEvolved, player, oldId, result)
			end
			EvolutionEvent:FireClient(player, "EvolutionSuccess", {
				NewSpirit = result,
				SpiritIndex = spiritIndex,
				OldName = meta and meta.OldName,
				UnlockedSkill = meta and meta.UnlockedSkill,
			})
			DataEvent:FireClient(player, "FullSync", playerData)
		else
			EvolutionEvent:FireClient(player, "EvolutionFailed", {Reason = result})
		end

	elseif action == "SetActiveSpirit" then
		local spirits = playerData.Spirits or {}
		local idx = math.floor(tonumber(data and data.SpiritIndex) or 0)
		if idx < 1 or not spirits[idx] then
			EvolutionEvent:FireClient(player, "ActiveSpiritChanged", {
				Success = false,
				Message = "Нет такого духа",
			})
			return
		end
		playerData.ActiveSpiritIndex = idx
		playerData.CurrentSpiritId = spirits[idx].Id
		player:SetAttribute("ActiveSpiritIndex", idx)
		player:SetAttribute("ActiveSpiritName", spirits[idx].Name or "")
		EvolutionEvent:FireClient(player, "ActiveSpiritChanged", {
			Success = true,
			Index = idx,
			Spirit = spirits[idx],
		})

	elseif action == "CycleActiveSpirit" then
		local spirits = playerData.Spirits or {}
		if #spirits == 0 then return end
		local idx = tonumber(playerData.ActiveSpiritIndex) or 1
		idx = (idx % #spirits) + 1
		playerData.ActiveSpiritIndex = idx
		playerData.CurrentSpiritId = spirits[idx].Id
		player:SetAttribute("ActiveSpiritIndex", idx)
		player:SetAttribute("ActiveSpiritName", spirits[idx].Name or "")
		EvolutionEvent:FireClient(player, "ActiveSpiritChanged", {
			Success = true,
			Index = idx,
			Spirit = spirits[idx],
		})

	elseif action == "DevBoostIdentity" then
		if not game:GetService("RunService"):IsStudio() then return end
		local spirit = playerData.Spirits and playerData.Spirits[1]
		if not spirit then return end
		spirit.Level = math.max(spirit.Level or 1, 10)
		spirit.Bond = math.max(tonumber(spirit.Bond) or 0, 3)
		playerData.Stats = playerData.Stats or {}
		playerData.Stats.EnemiesDefeated = math.max(playerData.Stats.EnemiesDefeated or 0, 10)
		playerData.Inventory = playerData.Inventory or {}
		local found = false
		for _, item in ipairs(playerData.Inventory) do
			if item.Id == 101 then
				item.Quantity = math.max(item.Quantity or 0, 5)
				found = true
				break
			end
		end
		if not found then
			table.insert(playerData.Inventory, {Id = 101, Quantity = 5})
		end
		DataEvent:FireClient(player, "FullSync", playerData)
		EvolutionEvent:FireClient(player, "DevBoostReady", {
			Level = spirit.Level,
			Wins = playerData.Stats.EnemiesDefeated,
			Crystals = 5,
		})
	end
end)

-- ============================================
-- Система прокачки
-- ============================================
LevelingEvent.OnServerEvent:Connect(function(player, action, data)
	local playerData = GetPlayerData(player)
	if not playerData then return end

	if action == "GetProgressInfo" then
		local info = levelingSystem:GetProgressInfo(playerData)
		LevelingEvent:FireClient(player, "ProgressInfo", {Info = info})

	elseif action == "GetUnlockedSkills" then
		local skills = levelingSystem:GetUnlockedSkills(playerData.Level)
		LevelingEvent:FireClient(player, "UnlockedSkills", {Skills = skills})

	elseif action == "GetStats" then
		local stats = levelingSystem:GetStatsWithBonuses({HP = 100, Attack = 10, Defense = 5, Speed = 10}, playerData)
		LevelingEvent:FireClient(player, "Stats", {Stats = stats})
	end
end)

-- ============================================
-- Система рангов
-- ============================================
RankEvent.OnServerEvent:Connect(function(player, action, data)
	local playerData = GetPlayerData(player)
	if not playerData then return end

	if action == "GetRankInfo" then
		local currentRankId = rankSystem:GetCurrentRank(playerData)
		local currentRank = rankSystem:GetRankInfo(currentRankId)
		local nextRankInfo = rankSystem:GetNextRankInfo(playerData)

		local response = {
			CurrentRank = {
				Id = currentRank.Id,
				Name = currentRank.Name,
				Title = currentRank.Title,
				Description = currentRank.Description,
				Color = currentRank.Color
			}
		}
		if nextRankInfo then
			response.NextRank = nextRankInfo
		end

		RankEvent:FireClient(player, "RankInfo", response)

	elseif action == "Promote" then
		local success, result = rankSystem:PromoteRank(playerData)
		if success then
			RankEvent:FireClient(player, "RankPromoted", {NewRank = result})
			DataEvent:FireClient(player, "FullSync", playerData)
		else
			RankEvent:FireClient(player, "RankPromotionFailed", {Reason = result})
		end
	end
end)

-- ============================================
-- Торговля (NPC магазин)
-- ============================================
TradeEvent.OnServerEvent:Connect(function(player, action, data)
	if typeof(action) ~= "string" then
		return
	end
	local playerData = GetPlayerData(player)
	if not playerData then return end
	if type(data) ~= "table" then
		data = {}
	end

	local function canUseNpcShop()
		local detail = player:GetAttribute("ZoneDetail")
		if detail == "Genkan" or detail == "Safe" or detail == "Exit" or detail == "Spawn" then
			return true
		end
		if player:GetAttribute("CurrentZone") == "Safe" then
			return true
		end
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then
			return false
		end
		local haven = workspace:FindFirstChild("OtakuHaven")
		local shop = haven and haven:FindFirstChild("ShopEntrance")
		local shopPart = nil
		if shop then
			if shop:IsA("BasePart") then
				shopPart = shop
			elseif shop:IsA("Model") then
				shopPart = shop.PrimaryPart or shop:FindFirstChildWhichIsA("BasePart", true)
			end
		end
		return shopPart ~= nil and (hrp.Position - shopPart.Position).Magnitude <= 45
	end

	if action == "Buy" or action == "Sell" then
		if not canUseNpcShop() then
			TradeEvent:FireClient(player, "TradeResult", {Success = false, Message = "Покупка и продажа только в Otaku Haven"})
			return
		end
	end

	if action == "GetShop" then
		TradeEvent:FireClient(player, "ShopList", {Items = tradeSystem:GetShopItems()})

	elseif action == "Buy" then
		local success, message = tradeSystem:BuyItem(playerData, data.ItemId, data.Quantity or 1)
		TradeEvent:FireClient(player, "TradeResult", {Success = success, Message = message})
		if success then DataEvent:FireClient(player, "FullSync", playerData) end

	elseif action == "Sell" then
		local success, message = tradeSystem:SellItem(playerData, data.ItemId, data.Quantity or 1)
		TradeEvent:FireClient(player, "TradeResult", {Success = success, Message = message})
		if success then DataEvent:FireClient(player, "FullSync", playerData) end

	elseif action == "UseItem" then
		local success, message = tradeSystem:UseExpScroll(playerData, data.ItemId)
		if success then
			local leveledUp, _, rewards = levelingSystem:CheckLevelUp(playerData)
			if leveledUp then
				for _, reward in ipairs(rewards) do
					DataEvent:FireClient(player, "LevelUp", {NewLevel = reward.Level, BonusCoins = reward.CopperCoins or reward.Coins})
				end
			end
		end
		TradeEvent:FireClient(player, "TradeResult", {Success = success, Message = message})
		if success then DataEvent:FireClient(player, "FullSync", playerData) end

	elseif action == "RenameSpirit" then
		local idx = math.floor(tonumber(data.SpiritIndex) or 0)
		local rawName = tostring(data.Name or "")
		local name = rawName:gsub("^%s+", ""):gsub("%s+$", "")
		if idx < 1 or not playerData.Spirits or not playerData.Spirits[idx] then
			TradeEvent:FireClient(player, "TradeResult", {Success = false, Message = "Дух не найден"})
			return
		end
		if #name < 2 or #name > 20 then
			TradeEvent:FireClient(player, "TradeResult", {Success = false, Message = "Имя: 2–20 символов"})
			return
		end
		if name:find("[%c]") then
			TradeEvent:FireClient(player, "TradeResult", {Success = false, Message = "Недопустимые символы в имени"})
			return
		end
		local okConsume, msgConsume = tradeSystem:ConsumeItem(playerData, 203)
		if not okConsume then
			TradeEvent:FireClient(player, "TradeResult", {Success = false, Message = msgConsume or "Нужен жетон имени"})
			return
		end
		playerData.Spirits[idx].Name = name
		TradeEvent:FireClient(player, "TradeResult", {Success = true, Message = "Дух переименован: " .. name})
		DataEvent:FireClient(player, "FullSync", playerData)
	end
end)

-- ============================================
-- Клиентский FullSync (после Catch Error/Fail)
-- ============================================
DataEvent.OnServerEvent:Connect(function(player, action)
	if action == "RequestFullSync" then
		local now = os.clock()
		if (fullSyncCooldown[player.UserId] or 0) > now then
			return
		end
		fullSyncCooldown[player.UserId] = now + 1.5
		local data = GetPlayerData(player)
		if data then
			DataEvent:FireClient(player, "FullSync", data)
		end
	end
end)

-- ============================================
-- Загрузка данных игрока при входе
-- ============================================
local diedConnections = {}

local function SetupCharacter(player, character)
	local humanoid = character:WaitForChild("Humanoid")
	-- Гарантируем анимацию падения при любой смерти
	humanoid.BreakJointsOnDeath = false
	local prev = diedConnections[player.UserId]
	if prev then
		prev:Disconnect()
	end
	diedConnections[player.UserId] = humanoid.Died:Connect(function()
		HandlePlayerDeath(player)
	end)
end

local function OnPlayerAdded(player)
	-- Обработчик смерти для всех новых персонажей
	player.CharacterAdded:Connect(function(character)
		-- RoS_ForceSpawnAtPad: avoid void/magenta if LoadCharacter misses SpawnLocation
		task.defer(function()
			local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
			if not spawn then return end
			local hrp = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 8)
			if not hrp then return end
			local pos = spawn.Position + Vector3.new(0, 4, 0)
			local look = pos + Vector3.new(0, 0, 20) -- face into Haven floor
			character:PivotTo(CFrame.lookAt(pos, look))
			hrp.AssemblyLinearVelocity = Vector3.zero
		end)
		SetupCharacter(player, character)
	end)

	-- Ensure character exists (AutoLoads true + safety LoadCharacter)
	if player.Character then
		SetupCharacter(player, player.Character)
	else
		pcall(function() player:LoadCharacter() end)
	end
	task.defer(function()
		if player.Parent and not player.Character then
			pcall(function() player:LoadCharacter() end)
		end
	end)
	task.delay(1.5, function()
		if player.Parent and not player.Character then
			warn("[RoS] LoadCharacter retry for " .. player.Name)
			pcall(function() player:LoadCharacter() end)
		end
	end)

	local data = dataStore:LoadData(player)
	if data then
		if _G.InitQuestSystemForPlayer then
			_G.InitQuestSystemForPlayer(player, data)
		end
		local leveledUp, _, rewards = levelingSystem:CheckLevelUp(data)
		if leveledUp then
			for _, reward in ipairs(rewards) do
				DataEvent:FireClient(player, "LevelUp", {
					NewLevel = reward.Level,
					BonusCoins = reward.CopperCoins or reward.Coins or 0,
				})
			end
		end
		-- Отправляем данные клиенту
		task.wait(1) -- Ждём загрузки клиента
		DataEvent:FireClient(player, "FullSync", data)
		local spirits = data.Spirits or {}
		local idx = tonumber(data.ActiveSpiritIndex) or 1
		if spirits[idx] then
			player:SetAttribute("ActiveSpiritIndex", idx)
			player:SetAttribute("ActiveSpiritName", spirits[idx].Name or "")
		end
	end
end

Players.PlayerAdded:Connect(OnPlayerAdded)

-- Очищаем бои и дебаунс смерти при выходе игрока
Players.PlayerRemoving:Connect(function(player)
	activeBattles[player.UserId] = nil
	deathDebounce[player.UserId] = nil
	if fullSyncCooldown then
		fullSyncCooldown[player.UserId] = nil
	end
	local diedConn = diedConnections[player.UserId]
	if diedConn then
		diedConn:Disconnect()
		diedConnections[player.UserId] = nil
	end
end)

-- Обрабатываем игроков, которые уже в игре
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		OnPlayerAdded(player)
	end)
end

-- ============================================
-- Инициализация DataStore
-- ============================================
dataStore:Initialize()

-- ============================================
-- Спавн начальных духов в мире
-- ============================================
task.spawn(function()
	task.wait(2)
	local spiritsFolder = workspace:FindFirstChild("Spirits")
	if not spiritsFolder then
		spiritsFolder = Instance.new("Folder")
		spiritsFolder.Name = "Spirits"
		spiritsFolder.Parent = workspace
	end

	-- Удаляем старые модели духов перед стартовым спавном, чтобы исключить дубли (земля + воздух)
	for _, child in ipairs(spiritsFolder:GetChildren()) do
		if child:IsA("Model") then
			child:Destroy()
		end
	end

	for spiritId, pos in pairs(SpiritSpawnPositions) do
		local SpiritDatabase = require(ReplicatedStorage:WaitForChild("RealmOfSpirits"):WaitForChild("SpiritDatabase"))
		if SpiritDatabase.IsCanonical and not SpiritDatabase.IsCanonical(spiritId) then
			continue
		end
		CreateSpiritModel(spiritId, pos)
	end
	print("Спавн начальных духов завершён!")
end)

print("Realm of Spirits - Game Manager загружен!")

task.defer(function()
	local HttpService = game:GetService("HttpService")
	local spirits = workspace:FindFirstChild("Spirits")
	if spirits then
		for _, spirit in ipairs(spirits:GetChildren()) do
			if spirit:IsA("Model") and not spirit:GetAttribute("SpiritInstanceId") then
				spirit:SetAttribute("SpiritInstanceId", HttpService:GenerateGUID(false))
			end
		end
	end
end)

task.spawn(function()
	task.wait(3)
	while true do
		local spirits = workspace:FindFirstChild("Spirits")
		if spirits then
			for _, spirit in ipairs(spirits:GetChildren()) do
				if spirit:IsA("Model") and spirit.Parent and not spirit:GetAttribute("Dying") then
					local movementType = spirit:GetAttribute("MovementType") or "Walk"
					local spiritIdVal = spirit:FindFirstChild("SpiritId")
					local sid = spiritIdVal and spiritIdVal.Value
					if (sid == 4 or spirit.Name == "Грозовой Дракон") and movementType ~= "Walk" then
						spirit:SetAttribute("MovementType", "Walk")
						movementType = "Walk"
						SpiritAnimation.ResetPose(spirit)
					end
					if spirit.Name == "Огненный Кот" and movementType ~= "Walk" then
						spirit:SetAttribute("MovementType", "Walk")
						movementType = "Walk"
					end

					if movementType == "Walk" then
						local pos = spirit:GetPivot().Position
						local ground = GetGroundPosition(pos.X, pos.Z, { spirit })
						local lowestY = GetModelLowestY(spirit)
						if lowestY < math.huge then
							local clearance = lowestY - ground.Y
							if clearance > 0.45 or clearance < -0.2 then
								PlaceModelOnGround(spirit, pos)
								SpiritAnimation.ResetPose(spirit)
							end
						end
					end
				end
			end
		end
		task.wait(2.5)
	end
end)