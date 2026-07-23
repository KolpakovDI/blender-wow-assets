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
	local ok, DataStoreManager = pcall(require, script.Parent.DataStoreManager)
	if ok and DataStoreManager then
		return DataStoreManager.new():GetPlayerData(player.UserId)
	end
	return nil
end

local function giveItem(playerData, itemId, quantity)
	playerData.Inventory = playerData.Inventory or {}
	for _, inv in ipairs(playerData.Inventory) do
		if inv.Id == itemId then
			inv.Quantity = (inv.Quantity or 0) + quantity
			return
		end
	end
	table.insert(playerData.Inventory, { Id = itemId, Quantity = quantity })
end

local function makeBillboard(parent, text, color)
	local bb = Instance.new("BillboardGui")
	bb.Name = "LootLabel"
	bb.Size = UDim2.new(0, 140, 0, 28)
	bb.StudsOffset = Vector3.new(0, 2.2, 0)
	bb.AlwaysOnTop = true
	bb.Parent = parent
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = bb
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

	local part = Instance.new("Part")
	part.Name = "Crystal_" .. tostring(itemId) .. "_" .. index
	part.Size = Vector3.new(1.2, 1.8, 1.2)
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.Neon
	part.Color = color
	part.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(index * 35), math.rad(15))
	part.Parent = lootFolder
	part:SetAttribute("ItemId", itemId)

	local light = Instance.new("PointLight")
	light.Color = lightColor
	light.Brightness = 2
	light.Range = 10
	light.Parent = part

	makeBillboard(part, label, lightColor)
	local prompt = makePrompt(part, "Собрать", "Кристалл")

	local taken = {}
	prompt.Triggered:Connect(function(player)
		if taken[player.UserId] then return end
		local data = getPlayerData(player)
		if not data then return end
		taken[player.UserId] = true
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
		local data = getPlayerData(player)
		if not data then return end
		looted[player.UserId] = true
		data.CopperCoins = (data.CopperCoins or 0) + 25
		if _G.UpdateQuestProgress then
			_G.UpdateQuestProgress(player, "FindChests", { Count = 1 })
		end
		DataEvent:FireClient(player, "FullSync", data)
		HavenEvent:FireClient(player, "Toast", { Text = "Сундук: +25 меди" })
		lid.CFrame = lid.CFrame * CFrame.Angles(math.rad(-35), 0, 0)
	end)
end

local crystalSpots = {
	Vector3.new(40, 2, 20),
	Vector3.new(55, 2, 50),
	Vector3.new(90, 2, 15),
	Vector3.new(85, 2, 55),
	Vector3.new(100, 2, 40),
	Vector3.new(60, 2, 70),
	Vector3.new(45, 2, 40),
}

local chestSpots = {
	Vector3.new(35, 1.2, 60),
	Vector3.new(95, 1.2, 70),
	Vector3.new(110, 1.2, 25),
	Vector3.new(50, 1.2, 10),
}

local waterCrystalSpots = {
	Vector3.new(95, 2, 118),
	Vector3.new(115, 2, 128),
	Vector3.new(100, 2, 135),
}

for i, pos in ipairs(crystalSpots) do
	spawnCrystal(pos, i)
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
	"Realm of Spirits - WorldLootService loaded! fire=",
	#crystalSpots,
	"water=",
	#waterCrystalSpots,
	"chests=",
	#chestSpots
)
