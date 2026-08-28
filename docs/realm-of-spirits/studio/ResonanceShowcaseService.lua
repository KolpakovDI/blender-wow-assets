-- ResonanceShowcaseService: Haven spirit showcase (glass cabinet + working E)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local realm = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local ResonanceEvent = realm:WaitForChild("ResonanceEvent")
local DataEvent = realm:WaitForChild("DataSync")
local SpiritMeshResolve = require(realm:WaitForChild("SpiritMeshResolve"))

local FOLDER_NAME = "ResonanceShowcase"
local PLAZA_NAME = "ShowcasePlaza"

local showcaseSet
local showcaseClear

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

-- Fill ParentIds/Kind from roster so Resonant mesh resolve works for old Showcase saves
local function enrichShowcaseEntry(playerData, entry)
	if type(entry) ~= "table" or entry.Id == nil then
		return entry
	end
	if type(entry.ParentIds) == "table" and #entry.ParentIds > 0 then
		return entry
	end
	local want = tonumber(entry.Id)
	for _, spirit in ipairs(playerData.Spirits or {}) do
		if tonumber(spirit.Id) == want then
			if type(spirit.ParentIds) == "table" then
				entry.ParentIds = table.clone(spirit.ParentIds)
			end
			entry.Kind = entry.Kind or spirit.Kind
			entry.Element = entry.Element or spirit.PrimaryElement or spirit.HybridPrimary or spirit.Element
			entry.Name = entry.Name or spirit.Name
			break
		end
	end
	return entry
end

local function getPlazaPosition()
	local qm = workspace:FindFirstChild("QuestMaster")
	if qm then
		local p = qm:GetPivot().Position
		return Vector3.new(p.X, 0.55, p.Z + 28)
	end
	return Vector3.new(-12, 0.55, -10)
end

local function part(props)
	local p = Instance.new("Part")
	p.Name = props.Name or "Part"
	p.Anchored = true
	p.CanCollide = props.CanCollide == true
	p.CanQuery = props.CanQuery ~= false
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.Color = props.Color or Color3.fromRGB(80, 70, 100)
	p.Transparency = props.Transparency or 0
	p.CastShadow = props.CastShadow ~= false
	if props.Size then
		p.Size = props.Size
	end
	if props.CFrame then
		p.CFrame = props.CFrame
	elseif props.Position then
		p.Position = props.Position
	end
	p.Parent = props.Parent
	return p
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
	local face = CFrame.new(pos)
	local model = Instance.new("Model")
	model.Name = PLAZA_NAME

	local base = part({
		Name = "Base",
		Size = Vector3.new(12, 0.45, 8),
		CFrame = face,
		Color = Color3.fromRGB(48, 40, 62),
		Material = Enum.Material.SmoothPlastic,
		CanCollide = true,
		Parent = model,
	})
	part({
		Name = "BaseTrim",
		Size = Vector3.new(12.3, 0.12, 8.3),
		CFrame = face * CFrame.new(0, 0.28, 0),
		Color = Color3.fromRGB(160, 130, 220),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = model,
	})

	part({
		Name = "CabinetBack",
		Size = Vector3.new(9.2, 5.2, 0.35),
		CFrame = face * CFrame.new(0, 2.9, -3.2),
		Color = Color3.fromRGB(36, 30, 48),
		Material = Enum.Material.SmoothPlastic,
		CanCollide = true,
		Parent = model,
	})
	part({
		Name = "CabinetLeft",
		Size = Vector3.new(0.3, 5.2, 2.4),
		CFrame = face * CFrame.new(-4.6, 2.9, -2.1),
		Color = Color3.fromRGB(42, 34, 55),
		CanCollide = true,
		Parent = model,
	})
	part({
		Name = "CabinetRight",
		Size = Vector3.new(0.3, 5.2, 2.4),
		CFrame = face * CFrame.new(4.6, 2.9, -2.1),
		Color = Color3.fromRGB(42, 34, 55),
		CanCollide = true,
		Parent = model,
	})
	part({
		Name = "CabinetRoof",
		Size = Vector3.new(9.6, 0.3, 2.8),
		CFrame = face * CFrame.new(0, 5.55, -2.15),
		Color = Color3.fromRGB(55, 42, 78),
		CanCollide = true,
		Parent = model,
	})
	part({
		Name = "GlassFront",
		Size = Vector3.new(8.8, 4.6, 0.12),
		CFrame = face * CFrame.new(0, 2.9, -0.95),
		Color = Color3.fromRGB(180, 220, 255),
		Material = Enum.Material.Glass,
		Transparency = 0.55,
		CanCollide = false,
		CastShadow = false,
		Parent = model,
	})
	part({
		Name = "Shelf",
		Size = Vector3.new(8.4, 0.2, 1.8),
		CFrame = face * CFrame.new(0, 1.35, -2.15),
		Color = Color3.fromRGB(70, 55, 95),
		CanCollide = false,
		Parent = model,
	})
	part({
		Name = "FrameTop",
		Size = Vector3.new(9.0, 0.12, 0.12),
		CFrame = face * CFrame.new(0, 5.2, -0.95),
		Color = Color3.fromRGB(170, 120, 255),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = model,
	})
	part({
		Name = "FrameBottom",
		Size = Vector3.new(9.0, 0.12, 0.12),
		CFrame = face * CFrame.new(0, 0.7, -0.95),
		Color = Color3.fromRGB(120, 220, 255),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = model,
	})

	local titlePart = part({
		Name = "TitlePanel",
		Size = Vector3.new(7.2, 1.1, 0.08),
		CFrame = face * CFrame.new(0, 4.55, -3.0),
		Color = Color3.fromRGB(30, 24, 42),
		CanCollide = false,
		Parent = model,
	})
	local gui = Instance.new("SurfaceGui")
	gui.Name = "TitleGui"
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = titlePart
	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size = UDim2.new(1, 0, 0.62, 0)
	titleLbl.Position = UDim2.new(0, 0, 0, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = "ВИТРИНА HAVEN"
	titleLbl.TextColor3 = Color3.fromRGB(235, 220, 255)
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.TextScaled = true
	titleLbl.Parent = gui

	local hint = Instance.new("TextLabel")
	hint.Name = "Hint"
	hint.Size = UDim2.new(1, 0, 0.35, 0)
	hint.Position = UDim2.new(0, 0, 0.65, 0)
	hint.BackgroundTransparency = 1
	hint.Text = "E — выставить активного духа"
	hint.TextColor3 = Color3.fromRGB(180, 200, 255)
	hint.Font = Enum.Font.Gotham
	hint.TextScaled = true
	hint.Parent = gui

	local glow = part({
		Name = "InnerGlow",
		Size = Vector3.new(0.6, 0.6, 0.6),
		CFrame = face * CFrame.new(0, 3.2, -2.2),
		Color = Color3.fromRGB(200, 150, 255),
		Material = Enum.Material.Neon,
		Transparency = 0.35,
		CanCollide = false,
		CanQuery = false,
		CastShadow = false,
		Parent = model,
	})
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(190, 150, 255)
	light.Brightness = 1.4
	light.Range = 14
	light.Parent = glow

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "ShowcasePrompt"
	prompt.ActionText = "Выставить духа"
	prompt.ObjectText = "Витрина Haven"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 16
	prompt.RequiresLineOfSight = false
	prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = base
	prompt.Triggered:Connect(function(player)
		if showcaseSet then
			showcaseSet(player, { Slot = 1 })
		end
	end)

	local cd = Instance.new("ClickDetector")
	cd.Name = "ShowcaseClick"
	cd.MaxActivationDistance = 16
	cd.Parent = base
	cd.MouseClick:Connect(function(player)
		if showcaseSet then
			showcaseSet(player, { Slot = 1 })
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
	local origin = plaza and plaza.PrimaryPart and plaza.PrimaryPart.CFrame or CFrame.new(getPlazaPosition())
	local slotIndex = 0
	for _, ch in ipairs(folder:GetChildren()) do
		if ch.Name:match("^Pad_") then
			slotIndex += 1
		end
	end
	local col = slotIndex % 4
	local row = math.floor(slotIndex / 4)
	local localPos = Vector3.new(-4.5 + col * 3, 0.35, 2.2 + row * 2.8)
	local worldCF = origin * CFrame.new(localPos)

	local model = Instance.new("Model")
	model.Name = name

	local pedestal = part({
		Name = "Pedestal",
		Size = Vector3.new(2.2, 0.35, 2.2),
		CFrame = worldCF,
		Color = Color3.fromRGB(58, 46, 78),
		Material = Enum.Material.SmoothPlastic,
		CanCollide = true,
		Parent = model,
	})
	part({
		Name = "PedestalRing",
		Size = Vector3.new(2.35, 0.08, 2.35),
		CFrame = worldCF * CFrame.new(0, 0.2, 0),
		Color = Color3.fromRGB(140, 110, 220),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = model,
	})

	local orb = Instance.new("Part")
	orb.Name = "Orb"
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(1.35, 1.35, 1.35)
	orb.Anchored = true
	orb.CanCollide = false
	orb.Material = Enum.Material.Neon
	orb.Color = Color3.fromRGB(180, 140, 255)
	orb.CFrame = worldCF * CFrame.new(0, 1.35, 0)
	orb.Parent = model
	local orbLight = Instance.new("PointLight")
	orbLight.Brightness = 0.9
	orbLight.Range = 8
	orbLight.Color = Color3.fromRGB(200, 160, 255)
	orbLight.Parent = orb

	model.PrimaryPart = pedestal
	model.Parent = folder
	return model
end

local function refreshPad(player)
	local pad = ensurePlayerPad(player)
	local orb = pad:FindFirstChild("Orb")
	if not orb then
		return
	end
	local playerData = getPlayerData(player)
	local entry = playerData and type(playerData.Showcase) == "table" and playerData.Showcase[1] or nil
	if entry then
		entry = enrichShowcaseEntry(playerData, entry)
	end
	orb.Color = entry and Color3.fromRGB(255, 200, 120) or Color3.fromRGB(180, 140, 255)

	-- Offline mesh preview: parent template or placeholder (no AI AssetId)
	local oldMesh = pad:FindFirstChild("DisplayMesh")
	if oldMesh then
		oldMesh:Destroy()
	end
	if entry and orb then
		local mesh = SpiritMeshResolve.CloneResolvedModel(entry, entry.Name)
		mesh.Name = "DisplayMesh"
		local pivot = orb.CFrame * CFrame.new(0, 1.6, 0)
		if mesh.PrimaryPart then
			mesh:PivotTo(pivot)
		end
		for _, d in ipairs(mesh:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
				d.CanTouch = false
				d.CanQuery = false
				d.Massless = true
			end
		end
		-- Prefer mesh over orb when real template; keep orb for empty/placeholder cue
		local isPh = mesh:GetAttribute("IsMeshPlaceholder") == true
		orb.Transparency = isPh and 0 or 1
		mesh.Parent = pad
	elseif orb then
		orb.Transparency = 0
	end
end

showcaseSet = function(player, data)
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
		Name = spirit.Name or (cat and cat.Name) or ("Дух " .. tostring(spirit.Id)),
		Level = spirit.Level or 1,
		Bond = spirit.Bond or 0,
		Element = spirit.PrimaryElement or spirit.HybridPrimary or spirit.Element or (cat and cat.Element) or nil,
		Kind = spirit.Kind,
		ParentIds = type(spirit.ParentIds) == "table" and table.clone(spirit.ParentIds) or nil,
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

showcaseClear = function(player, data)
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

_G.RoS_ShowcaseSet = function(...)
	return showcaseSet(...)
end
_G.RoS_ShowcaseClear = function(...)
	return showcaseClear(...)
end
-- Studio SoT uses carousel rebuildCarousel; docs mirror keeps pad refreshPad
_G.RoS_ShowcaseOnSpiritEvolved = function(player, oldId, newSpirit)
	if not player or not newSpirit then
		return false
	end
	local data = getPlayerData(player)
	if not data then
		return false
	end
	ensureShowcaseData(data)
	local changed = false
	for _, entry in pairs(data.Showcase) do
		if type(entry) == "table" and tonumber(entry.Id) == tonumber(oldId) then
			entry.Id = newSpirit.Id
			entry.Name = newSpirit.Name or entry.Name
			entry.Level = newSpirit.Level or entry.Level
			entry.Bond = newSpirit.Bond or entry.Bond
			changed = true
		end
	end
	if type(rebuildCarousel) == "function" then
		rebuildCarousel(player.UserId)
	elseif type(refreshPad) == "function" then
		refreshPad(player)
	end
	return changed
end

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
	for _ = 1, 40 do
		if workspace:FindFirstChild("QuestMaster") then
			break
		end
		task.wait(0.25)
	end
	ensurePlaza()
	for _, p in ipairs(Players:GetPlayers()) do
		ensurePlayerPad(p)
		refreshPad(p)
	end
end)

print("Realm of Spirits - ResonanceShowcaseService ready")
