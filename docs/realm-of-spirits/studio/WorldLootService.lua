-- WorldLootService - crystals + chests for side quests
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RealmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local DataEvent = RealmFolder:FindFirstChild("DataSync")
if not DataEvent then
	DataEvent = Instance.new("RemoteEvent")
	DataEvent.Name = "DataSync"
	DataEvent.Parent = RealmFolder
end
local HavenEvent = RealmFolder:FindFirstChild("OtakuHaven")
if not HavenEvent then
	HavenEvent = Instance.new("RemoteEvent")
	HavenEvent.Name = "OtakuHaven"
	HavenEvent.Parent = RealmFolder
end

local CRYSTAL_ITEM_ID = 101
local lootFolder = Workspace:FindFirstChild("WorldLoot")
if lootFolder then
	lootFolder:Destroy()
end
lootFolder = Instance.new("Folder")
lootFolder.Name = "WorldLoot"
lootFolder.Parent = Workspace

local function getPlayerData(player)
	if _G.GetPlayerData then
		return _G.GetPlayerData(player)
	end
	local bf = RealmFolder:FindFirstChild("GetPlayerDataBF")
	if bf and bf:IsA("BindableFunction") then
		local ok, data = pcall(function()
			return bf:Invoke(player.UserId)
		end)
		if ok and data then
			return data
		end
	end
	return nil
end

local function giveItem(playerData, itemId, quantity)
	itemId = tonumber(itemId) or itemId
	quantity = tonumber(quantity) or 1
	playerData.Inventory = playerData.Inventory or {}
	for _, inv in ipairs(playerData.Inventory) do
		if tonumber(inv.Id) == tonumber(itemId) then
			inv.Quantity = (inv.Quantity or 0) + quantity
			return
		end
	end
	table.insert(playerData.Inventory, { Id = itemId, Quantity = quantity })
end

local function makeBillboard(parent, text, color, opts)
	opts = opts or {}
	local bb = Instance.new("BillboardGui")
	bb.Name = "LootLabel"
	bb.Size = opts.Size or UDim2.new(0, 160, 0, 32)
	bb.StudsOffset = Vector3.new(0, opts.OffsetY or 2.6, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = opts.MaxDistance or 90
	bb.Enabled = opts.Visible ~= false
	bb.Parent = parent
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = bb
	return bb
end

local function makePrompt(parent, actionText, objectText)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = parent
	return prompt
end

local function spawnCrystal(position, index, opts)
	opts = opts or {}
	local itemId = opts.ItemId or CRYSTAL_ITEM_ID
	local label = opts.Label or "Огненный кристалл"
	local color = opts.Color or Color3.fromRGB(255, 90, 40)
	local lightColor = opts.LightColor or Color3.fromRGB(255, 120, 50)
	local highlight = opts.Highlight == true

	local part = Instance.new("Part")
	part.Name = "Crystal_" .. tostring(itemId) .. "_" .. index
	if highlight then
		part.Size = Vector3.new(1.8, 2.8, 1.8)
	else
		part.Size = Vector3.new(1.2, 1.8, 1.2)
	end
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Neon
	part.Color = color
	part.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(index * 35), math.rad(15))
	part.Parent = lootFolder
	part:SetAttribute("ItemId", itemId)
	if highlight then
		part:SetAttribute("ExploreFunnel", true)
	end

	local light = Instance.new("PointLight")
	light.Color = lightColor
	if highlight then
		light.Brightness = 4
		light.Range = 18
	else
		light.Brightness = 2
		light.Range = 10
	end
	light.Parent = part

	local bbOpts = {
		Visible = true,
		MaxDistance = 90,
		OffsetY = 2.6,
	}
	if highlight then
		bbOpts.MaxDistance = 120
		bbOpts.OffsetY = 3.4
		bbOpts.Size = UDim2.new(0, 200, 0, 40)
	end
	makeBillboard(part, label, lightColor, bbOpts)
	local prompt = makePrompt(part, "Собрать", highlight and "Лут у выхода" or "Кристалл")
	if highlight then
		prompt.MaxActivationDistance = 16
	end

	local taken = {}
	prompt.Triggered:Connect(function(player)
		if taken[player.UserId] then return end
		taken[player.UserId] = true
		local data = getPlayerData(player)
		if not data then
			taken[player.UserId] = nil
			return
		end
		local id = part:GetAttribute("ItemId") or itemId
		giveItem(data, id, 1)
		if _G.UpdateQuestProgress then
			_G.UpdateQuestProgress(player, "CollectItem", { ItemId = id, Count = 1 })
		end
		DataEvent:FireClient(player, "FullSync", data)
		HavenEvent:FireClient(player, "Toast", { Text = "Собран: " .. label })
		part.Transparency = 1
		prompt.Enabled = false
		local lightObj = part:FindFirstChildOfClass("PointLight")
		if lightObj then lightObj.Enabled = false end
		local bb = part:FindFirstChild("LootLabel")
		if bb then bb.Enabled = false end
		task.delay(45, function()
			if not part.Parent then return end
			part.Transparency = 0
			prompt.Enabled = true
			if lightObj then lightObj.Enabled = true end
			if bb then bb.Enabled = true end
			table.clear(taken)
		end)
	end)
end

local function spawnChest(position, index)
	local chest = Instance.new("Model")
	chest.Name = "TreasureChest_" .. index
	chest.Parent = lootFolder

	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(2.4, 1.4, 1.8)
	base.Anchored = true
	base.Material = Enum.Material.Wood
	base.Color = Color3.fromRGB(120, 75, 35)
	base.Position = position
	base.Parent = chest

	local lid = Instance.new("Part")
	lid.Name = "Lid"
	lid.Size = Vector3.new(2.5, 0.35, 1.9)
	lid.Anchored = true
	lid.Material = Enum.Material.Wood
	lid.Color = Color3.fromRGB(150, 95, 45)
	lid.Position = position + Vector3.new(0, 0.9, 0)
	lid.Parent = chest

	local trim = Instance.new("Part")
	trim.Name = "Trim"
	trim.Size = Vector3.new(2.6, 0.2, 0.2)
	trim.Anchored = true
	trim.Material = Enum.Material.Metal
	trim.Color = Color3.fromRGB(220, 180, 60)
	trim.Position = position + Vector3.new(0, 0.55, 0.9)
	trim.Parent = chest

	chest.PrimaryPart = base
	makeBillboard(base, "Сундук", Color3.fromRGB(255, 220, 120))
	local prompt = makePrompt(base, "Открыть", "Сундук")

	local looted = {}
	prompt.Triggered:Connect(function(player)
		if looted[player.UserId] then return end
		looted[player.UserId] = true
		local data = getPlayerData(player)
		if not data then
			looted[player.UserId] = nil
			return
		end
		data.CopperCoins = (data.CopperCoins or 0) + 25
		local crystalId, forced = nil, false
		do
			local ok, SeasonLiveOps = pcall(function()
				return require(script.Parent.SeasonLiveOps)
			end)
			if ok and SeasonLiveOps and SeasonLiveOps.RollCrystalDrop then
				crystalId, forced = SeasonLiveOps.RollCrystalDrop(data)
				if crystalId then
					giveItem(data, crystalId, 1)
				end
			end
		end
		if _G.UpdateQuestProgress then
			_G.UpdateQuestProgress(player, "FindChests", { Count = 1 })
		end
		do
			local okSR, SR = pcall(function()
				return require(game:GetService("ReplicatedStorage").RealmOfSpirits.SpiritResonance)
			end)
			if okSR and SR and SR.MarkDailySlot then
				SR.MarkDailySlot(data, "CatchOrChest")
			end
		end
		DataEvent:FireClient(player, "FullSync", data)
		local toast = "Сундук: +25 меди"
		if crystalId then
			local catName = nil
			pcall(function()
				local ItemCatalog = require(game:GetService("ReplicatedStorage").RealmOfSpirits.ItemCatalog)
				local row = ItemCatalog.Get(crystalId)
				catName = row and row.Name
			end)
			toast = toast
				.. " + "
				.. (forced and "Pity! " or "")
				.. (catName or ("кристалл " .. tostring(crystalId)))
		end
		HavenEvent:FireClient(player, "Toast", { Text = toast })
		lid.CFrame = lid.CFrame * CFrame.Angles(math.rad(-35), 0, 0)
	end)
end

local crystalSpots = {
	-- Explore funnel diversity (≤4 мин с Exit): огонь + лёд + манга — 3 разных типа
	{ Pos = Vector3.new(8, 2, 58), ItemId = 101, Label = "Огненный кристалл · лут", Color = Color3.fromRGB(255, 90, 40), LightColor = Color3.fromRGB(255, 120, 50), Highlight = true },
	{ Pos = Vector3.new(22, 2, 56), ItemId = 102, Label = "Ледяной кристалл · лут", Color = Color3.fromRGB(120, 200, 255), LightColor = Color3.fromRGB(180, 230, 255), Highlight = true },
	{ Pos = Vector3.new(-20, 2, 68), ItemId = 120, Label = "Коробка редкой манги · лут", Color = Color3.fromRGB(220, 90, 120), LightColor = Color3.fromRGB(255, 140, 170), Highlight = true },
	-- Second fire on Combat path (quest 101 still has EmberCourt ×5)
	{ Pos = Vector3.new(28, 2, 52), ItemId = 101, Label = "Огненный кристалл · лут", Color = Color3.fromRGB(255, 90, 40), LightColor = Color3.fromRGB(255, 120, 50), Highlight = true },
	-- EmberCourt / Fire (#1) — side 101 needs 5; keep ≥5 spots so no 45s respawn wait
	{ Pos = Vector3.new(62, 2, 24), ItemId = 101, Label = "Огненный кристалл", Color = Color3.fromRGB(255, 90, 40), LightColor = Color3.fromRGB(255, 120, 50) },
	{ Pos = Vector3.new(78, 2, 36), ItemId = 101, Label = "Огненный кристалл", Color = Color3.fromRGB(255, 90, 40), LightColor = Color3.fromRGB(255, 120, 50) },
	{ Pos = Vector3.new(70, 2, 48), ItemId = 101, Label = "Огненный кристалл", Color = Color3.fromRGB(255, 90, 40), LightColor = Color3.fromRGB(255, 120, 50) },
	{ Pos = Vector3.new(88, 2, 28), ItemId = 101, Label = "Огненный кристалл", Color = Color3.fromRGB(255, 90, 40), LightColor = Color3.fromRGB(255, 120, 50) },
	{ Pos = Vector3.new(55, 2, 38), ItemId = 101, Label = "Огненный кристалл", Color = Color3.fromRGB(255, 90, 40), LightColor = Color3.fromRGB(255, 120, 50) },
	-- FrostRidge / Ice (#2)
	{ Pos = Vector3.new(12, 2, 152), ItemId = 102, Label = "Ледяной кристалл", Color = Color3.fromRGB(120, 200, 255), LightColor = Color3.fromRGB(180, 230, 255) },
	{ Pos = Vector3.new(28, 2, 168), ItemId = 102, Label = "Ледяной кристалл", Color = Color3.fromRGB(120, 200, 255), LightColor = Color3.fromRGB(180, 230, 255) },
	-- ShadowHollow / Dark (#3)
	{ Pos = Vector3.new(148, 2, -88), ItemId = 103, Label = "Теневой кристалл", Color = Color3.fromRGB(120, 60, 180), LightColor = Color3.fromRGB(160, 100, 220) },
	{ Pos = Vector3.new(162, 2, -72), ItemId = 103, Label = "Теневой кристалл", Color = Color3.fromRGB(120, 60, 180), LightColor = Color3.fromRGB(160, 100, 220) },
	-- StormSpire / Lightning (#4)
	{ Pos = Vector3.new(222, 2, 168), ItemId = 104, Label = "Грозовой кристалл", Color = Color3.fromRGB(230, 220, 80), LightColor = Color3.fromRGB(255, 250, 140) },
	{ Pos = Vector3.new(238, 2, 182), ItemId = 104, Label = "Грозовой кристалл", Color = Color3.fromRGB(230, 220, 80), LightColor = Color3.fromRGB(255, 250, 140) },
	-- DawnMeadow / Light (#5)
	{ Pos = Vector3.new(332, 2, 212), ItemId = 105, Label = "Световой кристалл", Color = Color3.fromRGB(255, 245, 180), LightColor = Color3.fromRGB(255, 255, 220) },
	{ Pos = Vector3.new(348, 2, 228), ItemId = 105, Label = "Световой кристалл", Color = Color3.fromRGB(255, 245, 180), LightColor = Color3.fromRGB(255, 255, 220) },
	-- StoneBasin / Earth (#7)
	{ Pos = Vector3.new(-88, 2, -128), ItemId = 107, Label = "Земляной кристалл", Color = Color3.fromRGB(160, 120, 70), LightColor = Color3.fromRGB(200, 160, 100) },
	{ Pos = Vector3.new(-72, 2, -112), ItemId = 107, Label = "Земляной кристалл", Color = Color3.fromRGB(160, 120, 70), LightColor = Color3.fromRGB(200, 160, 100) },
	-- GaleCliff / Wind (#9)
	{ Pos = Vector3.new(-148, 2, 172), ItemId = 109, Label = "Ветряной кристалл", Color = Color3.fromRGB(180, 230, 210), LightColor = Color3.fromRGB(210, 255, 235) },
	{ Pos = Vector3.new(-128, 2, 192), ItemId = 109, Label = "Ветряной кристалл", Color = Color3.fromRGB(180, 230, 210), LightColor = Color3.fromRGB(210, 255, 235) },
	-- AshGarden / Fire ash (#8)
	{ Pos = Vector3.new(168, 2, 42), ItemId = 108, Label = "Пепельный кристалл", Color = Color3.fromRGB(255, 90, 40), LightColor = Color3.fromRGB(255, 140, 60) },
	{ Pos = Vector3.new(182, 2, 58), ItemId = 108, Label = "Пепельный кристалл", Color = Color3.fromRGB(255, 90, 40), LightColor = Color3.fromRGB(255, 140, 60) },
	-- GaleCliff / Wind (#9)
	{ Pos = Vector3.new(-148, 2, 172), ItemId = 109, Label = "Ветряной кристалл", Color = Color3.fromRGB(120, 200, 180), LightColor = Color3.fromRGB(160, 230, 210) },
	{ Pos = Vector3.new(-132, 2, 188), ItemId = 109, Label = "Ветряной кристалл", Color = Color3.fromRGB(120, 200, 180), LightColor = Color3.fromRGB(160, 230, 210) },
	-- MossGlade / Nature (#10)
	{ Pos = Vector3.new(42, 2, -208), ItemId = 110, Label = "Природный кристалл", Color = Color3.fromRGB(80, 160, 70), LightColor = Color3.fromRGB(120, 200, 100) },
	{ Pos = Vector3.new(58, 2, -192), ItemId = 110, Label = "Природный кристалл", Color = Color3.fromRGB(80, 160, 70), LightColor = Color3.fromRGB(120, 200, 100) },
	-- Moonwell / Moon (#11)
	{ Pos = Vector3.new(-228, 2, -168), ItemId = 111, Label = "Лунный кристалл", Color = Color3.fromRGB(180, 195, 255), LightColor = Color3.fromRGB(210, 220, 255) },
	{ Pos = Vector3.new(-212, 2, -152), ItemId = 111, Label = "Лунный кристалл", Color = Color3.fromRGB(180, 195, 255), LightColor = Color3.fromRGB(210, 220, 255) },
	-- VenomHollow / Poison (#12)
	{ Pos = Vector3.new(272, 2, -168), ItemId = 112, Label = "Ядовитый кристалл", Color = Color3.fromRGB(90, 180, 60), LightColor = Color3.fromRGB(140, 220, 80) },
	{ Pos = Vector3.new(288, 2, -152), ItemId = 112, Label = "Ядовитый кристалл", Color = Color3.fromRGB(90, 180, 60), LightColor = Color3.fromRGB(140, 220, 80) },
	-- SandDunes / Sand (#13)
	{ Pos = Vector3.new(352, 2, -48), ItemId = 113, Label = "Песчаный кристалл", Color = Color3.fromRGB(210, 170, 90), LightColor = Color3.fromRGB(240, 210, 130) },
	{ Pos = Vector3.new(368, 2, -32), ItemId = 113, Label = "Песчаный кристалл", Color = Color3.fromRGB(210, 170, 90), LightColor = Color3.fromRGB(240, 210, 130) },
	-- IronWastes / Metal (#14)
	{ Pos = Vector3.new(442, 2, 188), ItemId = 114, Label = "Металлический кристалл", Color = Color3.fromRGB(140, 155, 175), LightColor = Color3.fromRGB(180, 195, 215) },
	{ Pos = Vector3.new(458, 2, 212), ItemId = 114, Label = "Металлический кристалл", Color = Color3.fromRGB(140, 155, 175), LightColor = Color3.fromRGB(180, 195, 215) },
	-- CrystalCaves / Crystal (#15)
	{ Pos = Vector3.new(512, 2, 268), ItemId = 115, Label = "Кристальный кристалл", Color = Color3.fromRGB(180, 220, 255), LightColor = Color3.fromRGB(210, 240, 255) },
	{ Pos = Vector3.new(528, 2, 292), ItemId = 115, Label = "Кристальный кристалл", Color = Color3.fromRGB(180, 220, 255), LightColor = Color3.fromRGB(210, 240, 255) },
	-- MagmaFissure / Magma (#16)
	{ Pos = Vector3.new(582, 2, 228), ItemId = 116, Label = "Лавовый кристалл", Color = Color3.fromRGB(255, 90, 40), LightColor = Color3.fromRGB(255, 140, 60) },
	{ Pos = Vector3.new(598, 2, 252), ItemId = 116, Label = "Лавовый кристалл", Color = Color3.fromRGB(255, 90, 40), LightColor = Color3.fromRGB(255, 140, 60) },
	-- FogBasin / Mist (#17)
	{ Pos = Vector3.new(652, 2, 188), ItemId = 117, Label = "Туманный кристалл", Color = Color3.fromRGB(160, 190, 220), LightColor = Color3.fromRGB(200, 220, 245) },
	{ Pos = Vector3.new(668, 2, 212), ItemId = 117, Label = "Туманный кристалл", Color = Color3.fromRGB(160, 190, 220), LightColor = Color3.fromRGB(200, 220, 245) },
	-- SkyRidge / Sky (#18)
	{ Pos = Vector3.new(-212, 2, 208), ItemId = 118, Label = "Небесный кристалл", Color = Color3.fromRGB(140, 190, 255), LightColor = Color3.fromRGB(180, 220, 255) },
	{ Pos = Vector3.new(-188, 2, 232), ItemId = 118, Label = "Небесный кристалл", Color = Color3.fromRGB(140, 190, 255), LightColor = Color3.fromRGB(180, 220, 255) },
	-- Haven Exit / Akihabara — запас манги для квеста 7 (не highlight)
	{ Pos = Vector3.new(-25, 2, 72), ItemId = 120, Label = "Коробка редкой манги", Color = Color3.fromRGB(220, 90, 120), LightColor = Color3.fromRGB(255, 140, 170) },
	{ Pos = Vector3.new(-18, 2, 85), ItemId = 120, Label = "Коробка редкой манги", Color = Color3.fromRGB(220, 90, 120), LightColor = Color3.fromRGB(255, 140, 170) },
}

local chestSpots = {
	Vector3.new(18, 1.2, 54), -- Explore funnel: сундук у Exit→Combat (4-й тип: медь)
	Vector3.new(55, 1.2, 40),
	Vector3.new(30, 1.2, 150),
	Vector3.new(165, 1.2, -70),
	Vector3.new(240, 1.2, 170),
	Vector3.new(345, 1.2, 215),
	Vector3.new(-75, 1.2, -115),
	Vector3.new(-140, 1.2, 180),
	Vector3.new(50, 1.2, -200),
}

local waterCrystalSpots = {
	Vector3.new(10, 2, -860),
	Vector3.new(45, 2, -900),
	Vector3.new(25, 2, -840),
}

for i, spot in ipairs(crystalSpots) do
	spawnCrystal(spot.Pos, i, {
		ItemId = spot.ItemId,
		Label = spot.Label,
		Color = spot.Color,
		LightColor = spot.LightColor,
		Highlight = spot.Highlight,
	})
end
for i, pos in ipairs(waterCrystalSpots) do
	spawnCrystal(pos, 100 + i, {
		ItemId = 106,
		Label = "Водный кристалл",
		Color = Color3.fromRGB(40, 140, 230),
		LightColor = Color3.fromRGB(120, 200, 255),
	})
end
for i, pos in ipairs(chestSpots) do
	spawnChest(pos, i)
end

print(
	"Realm of Spirits - WorldLootService loaded! crystals=",
	#crystalSpots,
	"water=",
	#waterCrystalSpots,
	"chests=",
	#chestSpots
)
