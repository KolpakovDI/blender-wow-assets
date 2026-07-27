-- ResonanceShowcaseService: Haven spirit showcase billboard (Spirit Resonance Phase 3)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local realm = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local ResonanceEvent = realm:WaitForChild("ResonanceEvent")
local DataEvent = realm:WaitForChild("DataSync")

local FOLDER_NAME = "ResonanceShowcase"
local PLAZA_NAME = "ShowcasePlaza"

local function getPlayerData(player)
	if _G.GetPlayerData then
		return _G.GetPlayerData(player)
	end
	return nil
end

local function maxSlots(playerData)
	return 1 + math.max(0, math.floor(tonumber(playerData.ShowcaseSlots) or 0))
end

local function ensureShowcaseData(playerData)
	if type(playerData.Showcase) ~= "table" then
		playerData.Showcase = {}
	end
end

local function spiritLabel(entry)
	if not entry then
		return "Пусто"
	end
	local name = entry.Name or ("Дух #" .. tostring(entry.Id or "?"))
	local lv = tonumber(entry.Level) or 1
	local bond = tonumber(entry.Bond) or 0
	return string.format("%s  Lv%d  Bond %d", name, lv, bond)
end

local function getPlazaPosition()
	local qm = workspace:FindFirstChild("QuestMaster")
	if qm then
		local p = qm:GetPivot().Position
		-- Южнее Мики и пьедесталов Care/Temper
		return Vector3.new(p.X, 0.55, p.Z + 28)
	end
	return Vector3.new(-12, 0.55, -10)
end

local function ensurePlaza()
	local folder = workspace:FindFirstChild(FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = workspace
	end
	local plaza = folder:FindFirstChild(PLAZA_NAME)
	if plaza then
		plaza:Destroy()
	end
	local pos = getPlazaPosition()
	local model = Instance.new("Model")
	model.Name = PLAZA_NAME

	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(10, 0.5, 6)
	base.Anchored = true
	base.CanCollide = true
	base.Material = Enum.Material.SmoothPlastic
	base.Color = Color3.fromRGB(55, 45, 70)
	base.CFrame = CFrame.new(pos)
	base.Parent = model

	local board = Instance.new("Part")
	board.Name = "Board"
	board.Size = Vector3.new(8, 4.5, 0.4)
	board.Anchored = true
	board.CanCollide = false
	board.Material = Enum.Material.Neon
	board.Color = Color3.fromRGB(90, 70, 140)
	board.CFrame = CFrame.new(pos + Vector3.new(0, 3, -2.2))
	board.Parent = model

	local title = Instance.new("BillboardGui")
	title.Name = "Title"
	title.Size = UDim2.fromOffset(220, 36)
	title.StudsOffset = Vector3.new(0, 3.2, 0)
	title.AlwaysOnTop = true
	title.Parent = board
	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size = UDim2.fromScale(1, 1)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = "Витрина · Showcase"
	titleLbl.TextColor3 = Color3.fromRGB(230, 210, 255)
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextSize = 18
	titleLbl.TextStrokeTransparency = 0.3
	titleLbl.Parent = title

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ShowcasePrompt"
	prompt.ActionText = "Выставить духа"
	prompt.ObjectText = "Витрина Haven"
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = true
	prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = board

	prompt.Triggered:Connect(function(player)
		if typeof(_G.RoS_ShowcaseSet) == "function" then
			_G.RoS_ShowcaseSet(player, { Slot = 1 })
		end
	end)

	model.PrimaryPart = base
	model.Parent = folder
	return model
end

local function ensurePlayerPad(player)
	local folder = workspace:FindFirstChild(FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = workspace
	end
	local name = "Pad_" .. tostring(player.UserId)
	local existing = folder:FindFirstChild(name)
	if existing then
		return existing
	end

	local plaza = folder:FindFirstChild(PLAZA_NAME)
	local origin = plaza and plaza.PrimaryPart and plaza.PrimaryPart.Position or getPlazaPosition()
	local slotIndex = 0
	for _, ch in ipairs(folder:GetChildren()) do
		if ch.Name:match("^Pad_") then
			slotIndex += 1
		end
	end
	local pos = origin + Vector3.new(-6 + (slotIndex % 4) * 4, 0, 4 + math.floor(slotIndex / 4) * 3)

	local model = Instance.new("Model")
	model.Name = name

	local pedestal = Instance.new("Part")
	pedestal.Name = "Pedestal"
	pedestal.Size = Vector3.new(2.4, 0.4, 2.4)
	pedestal.Anchored = true
	pedestal.CanCollide = true
	pedestal.Material = Enum.Material.SmoothPlastic
	pedestal.Color = Color3.fromRGB(70, 55, 95)
	pedestal.CFrame = CFrame.new(pos)
	pedestal.Parent = model

	local orb = Instance.new("Part")
	orb.Name = "Orb"
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(1.4, 1.4, 1.4)
	orb.Anchored = true
	orb.CanCollide = false
	orb.Material = Enum.Material.Neon
	orb.Color = Color3.fromRGB(180, 140, 255)
	orb.CFrame = CFrame.new(pos + Vector3.new(0, 1.4, 0))
	orb.Parent = model

	local bill = Instance.new("BillboardGui")
	bill.Name = "ShowcaseLabel"
	bill.Size = UDim2.fromOffset(180, 54)
	bill.StudsOffset = Vector3.new(0, 2.4, 0)
	bill.AlwaysOnTop = true
	bill.Parent = orb
	local lbl = Instance.new("TextLabel")
	lbl.Name = "Text"
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Text = player.DisplayName .. "\nПусто"
	lbl.TextColor3 = Color3.fromRGB(230, 210, 255)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 13
	lbl.TextStrokeTransparency = 0.35
	lbl.Parent = bill

	model.PrimaryPart = pedestal
	model.Parent = folder
	return model
end

local function refreshPad(player)
	local pad = ensurePlayerPad(player)
	local orb = pad:FindFirstChild("Orb")
	local bill = orb and orb:FindFirstChild("ShowcaseLabel")
	local lbl = bill and bill:FindFirstChild("Text")
	if not lbl then
		return
	end
	local playerData = getPlayerData(player)
	local entry = playerData and type(playerData.Showcase) == "table" and playerData.Showcase[1] or nil
	lbl.Text = player.DisplayName .. "\n" .. spiritLabel(entry)
	if orb then
		orb.Color = entry and Color3.fromRGB(255, 200, 120) or Color3.fromRGB(180, 140, 255)
	end
end

local function showcaseSet(player, data)
	local playerData = getPlayerData(player)
	if not playerData then
		ResonanceEvent:FireClient(player, "ShowcaseFailed", {Reason = "Данные ещё загружаются"})
		return false
	end
	ensureShowcaseData(playerData)
	local spirits = playerData.Spirits
	if type(spirits) ~= "table" or #spirits == 0 then
		ResonanceEvent:FireClient(player, "ShowcaseFailed", {Reason = "Нет духов для витрины"})
		return false
	end
	local idx = tonumber(data and data.SpiritIndex) or tonumber(playerData.ActiveSpiritIndex) or 1
	local spirit = spirits[idx]
	if not spirit then
		spirit = spirits[1]
		idx = 1
	end
	local slot = math.clamp(math.floor(tonumber(data and data.Slot) or 1), 1, maxSlots(playerData))
	local cat = nil
	pcall(function()
		local SD = require(realm:WaitForChild("SpiritDatabase"))
		cat = SD.Get(spirit.Id)
	end)
	playerData.Showcase[slot] = {
		Id = spirit.Id,
		Name = (cat and cat.Name) or spirit.Name or ("Дух " .. tostring(spirit.Id)),
		Level = spirit.Level or 1,
		Bond = spirit.Bond or 0,
		Element = cat and cat.Element or nil,
	}
	refreshPad(player)
	ResonanceEvent:FireClient(player, "ShowcaseSuccess", {
		Message = "Витрина обновлена: " .. spiritLabel(playerData.Showcase[slot]),
		Showcase = playerData.Showcase,
	})
	pcall(function()
		DataEvent:FireClient(player, "FullSync", playerData)
	end)
	return true
end

local function showcaseClear(player, data)
	local playerData = getPlayerData(player)
	if not playerData then
		return false
	end
	ensureShowcaseData(playerData)
	local slot = math.clamp(math.floor(tonumber(data and data.Slot) or 1), 1, maxSlots(playerData))
	playerData.Showcase[slot] = nil
	refreshPad(player)
	ResonanceEvent:FireClient(player, "ShowcaseSuccess", {Message = "Слот витрины очищен", Showcase = playerData.Showcase})
	return true
end

_G.RoS_ShowcaseSet = showcaseSet
_G.RoS_ShowcaseClear = showcaseClear

local function hookPlayer(player)
	task.defer(function()
		task.wait(1)
		ensurePlayerPad(player)
		refreshPad(player)
	end)
end

Players.PlayerAdded:Connect(hookPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	hookPlayer(p)
end
Players.PlayerRemoving:Connect(function(player)
	local folder = workspace:FindFirstChild(FOLDER_NAME)
	local pad = folder and folder:FindFirstChild("Pad_" .. tostring(player.UserId))
	if pad then
		pad:Destroy()
	end
end)

task.defer(function()
	task.wait(1.5)
	ensurePlaza()
	for _, p in ipairs(Players:GetPlayers()) do
		ensurePlayerPad(p)
		refreshPad(p)
	end
end)

print("Realm of Spirits - ResonanceShowcaseService ready")
