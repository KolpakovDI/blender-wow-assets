-- OtakuHavenBuilder - Safe Zone hub (GDD v2.0)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local RealmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local ZoneConfig = require(RealmFolder:WaitForChild("ZoneConfig"))

local OtakuHavenBuilder = {}

local HUB_WAYFIND_BB_NAMES = {
	ExitWayfindBillboard = true,
	DuelWayfindBillboard = true,
	ExploreHub2WayfindBillboard = true,
	ChestClusterWayfindBillboard = true,
}

local function clearHubWayfindBillboards(root)
	if not root then
		return
	end
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BillboardGui") and (d:GetAttribute("HubWayfind") == true or HUB_WAYFIND_BB_NAMES[d.Name]) then
			d:Destroy()
		end
	end
end

local function destroyHubWayfindFolders(haven)
	if not haven then
		return
	end
	for _, name in ipairs({ "DuelWayfind", "ExploreHub2Wayfind", "ChestClusterWayfind" }) do
		local old = haven:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
	local trail = workspace:FindFirstChild("ExploreHub2Trail")
	if trail then
		trail:Destroy()
	end
	clearHubWayfindBillboards(haven)
end

local function makePart(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = props.CanCollide ~= false
	p.CanQuery = props.CanQuery ~= false
	p.CanTouch = props.CanTouch ~= false
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.Color = props.Color or Color3.fromRGB(240, 230, 220)
	p.Size = props.Size
	p.CFrame = props.CFrame or CFrame.new(props.Position or Vector3.zero)
	p.Transparency = props.Transparency or 0
	p.Reflectance = props.Reflectance or 0
	p.Name = props.Name or "Part"
	if props.Parent then p.Parent = props.Parent end
	return p
end

local function makeZone(name, zoneType, center, size, parent)
	local z = makePart({
		Name = name,
		Size = size,
		Position = center,
		Transparency = 1,
		CanCollide = false,
		CanTouch = true,
		CanQuery = true,
		CastShadow = false,
		Color = Color3.fromRGB(170, 120, 255),
		Parent = parent,
	})
	z:SetAttribute("ZoneType", zoneType)
	z:AddTag("ZoneVolume")
	return z
end

local function addGenkanMat(parent, position)
	-- стильный коврик генкана: рамка + ткань + неоновая полоса
	local model = Instance.new("Model")
	model.Name = "GenkanMat"
	model.Parent = parent

	local function matPart(name, size, offset, color, material)
		local p = makePart({
			Name = name,
			Size = size,
			Position = position + offset,
			Color = color,
			Material = material or Enum.Material.Fabric,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
			Parent = model,
		})
		return p
	end

	-- тёмная рамка (индиго)
	matPart("MatFrame", Vector3.new(8.4, 0.12, 4.4), Vector3.new(0, 0, 0), Color3.fromRGB(35, 28, 55), Enum.Material.SmoothPlastic)
	-- основной ковёр (пыльная роза / сакура)
	local pad = matPart("MatPad", Vector3.new(7.6, 0.14, 3.6), Vector3.new(0, 0.04, 0), Color3.fromRGB(255, 185, 210), Enum.Material.Fabric)
	-- внутреннее поле (крем)
	matPart("MatInner", Vector3.new(6.2, 0.05, 2.4), Vector3.new(0, 0.1, 0), Color3.fromRGB(255, 245, 250), Enum.Material.Fabric)
	-- неоновая полоса-акцент
	local stripe = matPart("MatStripe", Vector3.new(6.0, 0.04, 0.22), Vector3.new(0, 0.12, -0.85), Color3.fromRGB(255, 110, 200), Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 120, 200)
	light.Brightness = 0.45
	light.Range = 6
	light.Parent = stripe
	-- вторая тонкая полоса
	matPart("MatStripe2", Vector3.new(6.0, 0.04, 0.12), Vector3.new(0, 0.12, 0.9), Color3.fromRGB(180, 140, 255), Enum.Material.Neon)

	local gui = Instance.new("SurfaceGui")
	gui.Name = "MatLabel"
	gui.Face = Enum.NormalId.Top
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0.2
	gui.Parent = pad
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "GENKAN  ·  いらっしゃいませ"
	label.TextColor3 = Color3.fromRGB(90, 50, 90)
	label.TextTransparency = 0.15
	label.Font = Enum.Font.GothamMedium
	label.TextScaled = true
	label.Parent = gui
	local padText = Instance.new("UIPadding")
	padText.PaddingLeft = UDim.new(0.08, 0)
	padText.PaddingRight = UDim.new(0.08, 0)
	padText.PaddingTop = UDim.new(0.28, 0)
	padText.PaddingBottom = UDim.new(0.28, 0)
	padText.Parent = label

	return model
end

local function addNeonSign(parent, position)
	local sign = Instance.new("Model")
	sign.Name = "NeonSign"
	sign.Parent = parent

	local board = makePart({
		Name = "Board",
		Size = Vector3.new(14, 2.5, 0.4),
		Position = position,
		Color = Color3.fromRGB(25, 25, 35),
		Parent = sign,
	})

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 120, 200)
	light.Range = 18
	light.Brightness = 1.1
	light.Parent = board

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "Otaku Haven"
	label.TextColor3 = Color3.fromRGB(255, 140, 220)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui

	task.spawn(function()
		while board.Parent do
			local t = TweenService:Create(light, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Brightness = 0.7 + math.random() * 0.7,
			})
			t:Play()
			task.wait(0.4 + math.random() * 0.3)
		end
	end)

	return sign
end

local function addLEDDisplay(parent, position, text)
	local part = makePart({
		Name = "LEDDisplay",
		Size = Vector3.new(4, 3, 0.3),
		Position = position,
		Color = Color3.fromRGB(15, 15, 25),
		Parent = parent,
	})
	local pl = Instance.new("PointLight")
	pl.Color = Color3.fromRGB(80, 200, 255)
	pl.Brightness = 0.75
	pl.Range = 8
	pl.Parent = part

	local gui = Instance.new("SurfaceGui")
	gui.Parent = part
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = Color3.fromRGB(100, 255, 255)
	lbl.TextScaled = true
	lbl.Font = Enum.Font.Code
	lbl.Parent = gui

	task.spawn(function()
		while part.Parent do
			pl.Brightness = 0.5 + math.random() * 0.5
			task.wait(0.15 + math.random() * 0.2)
		end
	end)
end

local function addPoster(parent, position, color)
	makePart({
		Name = "Poster",
		Size = Vector3.new(0.2, 5, 3.5),
		Position = position,
		Color = color,
		Parent = parent,
	})
end

local function addStandee(parent, position)
	makePart({
		Name = "Standee",
		Size = Vector3.new(0.3, 6, 2.5),
		Position = position,
		Color = Color3.fromRGB(255, 180, 220),
		Parent = parent,
	})
end

local function addGacha(parent, position)
	local g = makePart({
		Name = "GachaMachine",
		Size = Vector3.new(3, 5, 3),
		Position = position,
		Color = Color3.fromRGB(255, 90, 140),
		Parent = parent,
	})
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "Гашапон"
	prompt.ActionText = "Крутить (50 меди)"
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Enabled = true
	prompt.Parent = g
end

local function addFittingRoom(parent, position)
	local room = makePart({
		Name = "FittingRoom",
		Size = Vector3.new(5, 7, 4),
		Position = position,
		Color = Color3.fromRGB(200, 160, 220),
		Parent = parent,
	})
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "Примерочная"
	prompt.ActionText = "Магазин / косметика"
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Enabled = true
	prompt.Parent = room

	-- P2P trade wayfinding (Social gate): обмен = T у другого игрока в Safe
	local sign = makePart({
		Name = "TradePlazaSign",
		Size = Vector3.new(6, 2.2, 0.3),
		Position = position + Vector3.new(0, 5.2, 3.5),
		Color = Color3.fromRGB(40, 32, 55),
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
		Parent = parent,
	})
end

local function addMangaBuff(parent, position)
	local model = Instance.new("Model")
	model.Name = "MangaBuffStand"
	model.Parent = parent

	local function bookPart(props)
		local p = makePart(props)
		p.Parent = model
		return p
	end

	local shelf = bookPart({
		Name = "ShelfBody",
		Size = Vector3.new(5.5, 5.5, 1.2),
		Position = position,
		Color = Color3.fromRGB(110, 70, 40),
		Material = Enum.Material.Wood,
		Parent = model,
	})
	bookPart({
		Name = "ShelfBack",
		Size = Vector3.new(5.3, 5.2, 0.15),
		Position = position + Vector3.new(0, 0, 0.55),
		Color = Color3.fromRGB(70, 45, 30),
		Material = Enum.Material.Wood,
		Parent = model,
	})

	local colors = {
		Color3.fromRGB(220, 70, 90),
		Color3.fromRGB(80, 140, 255),
		Color3.fromRGB(255, 200, 60),
		Color3.fromRGB(120, 220, 140),
		Color3.fromRGB(180, 100, 255),
		Color3.fromRGB(255, 140, 80),
	}
	for i, col in ipairs(colors) do
		local x = -2.1 + (i - 1) * 0.75
		bookPart({
			Name = "MangaVol" .. i,
			Size = Vector3.new(0.55, 2.2, 0.9),
			Position = position + Vector3.new(x, 0.4, -0.05),
			Color = col,
			Parent = model,
		})
	end

	local featured = bookPart({
		Name = "FeaturedManga",
		Size = Vector3.new(1.4, 1.8, 0.35),
		Position = position + Vector3.new(0, -0.2, -1.1),
		Color = Color3.fromRGB(40, 40, 55),
		Parent = model,
	})
	local coverGui = Instance.new("SurfaceGui")
	coverGui.Face = Enum.NormalId.Front
	coverGui.Parent = featured
	local cover = Instance.new("TextLabel")
	cover.Size = UDim2.fromScale(1, 1)
	cover.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
	cover.Text = "ПУТЬ\nМЕЧА\nтом 1"
	cover.TextColor3 = Color3.fromRGB(255, 220, 120)
	cover.TextScaled = true
	cover.Font = Enum.Font.GothamBold
	cover.Parent = coverGui

	local signBoard = bookPart({
		Name = "MangaSign",
		Size = Vector3.new(6, 1.4, 0.3),
		Position = position + Vector3.new(0, 4.2, 0),
		Color = Color3.fromRGB(25, 20, 40),
		Parent = model,
	})
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.Parent = signBoard
	local signLbl = Instance.new("TextLabel")
	signLbl.Size = UDim2.fromScale(1, 1)
	signLbl.BackgroundTransparency = 1
	signLbl.Text = "УГОЛОК МАНГИ"
	signLbl.TextColor3 = Color3.fromRGB(255, 180, 220)
	signLbl.TextScaled = true
	signLbl.Font = Enum.Font.GothamBold
	signLbl.Parent = signGui

	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "Манга «Путь Меча»"
	prompt.ActionText = "Читать"
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Enabled = true
	prompt.Parent = shelf

	model.PrimaryPart = shelf
	return model
end

local function addWayfindPad(parent, name, position, label, color)
	local mat = makePart({
		Name = name,
		Size = Vector3.new(3.4, 0.12, 3.4),
		Position = position,
		Color = color or Color3.fromRGB(255, 180, 220),
		Material = Enum.Material.Neon,
		CanCollide = false,
		CanQuery = false,
		Parent = parent,
	})
	local matGui = Instance.new("SurfaceGui")
	matGui.Face = Enum.NormalId.Top
	matGui.Parent = mat
	local matLbl = Instance.new("TextLabel")
	matLbl.Size = UDim2.fromScale(1, 1)
	matLbl.BackgroundTransparency = 1
	matLbl.Text = label
	matLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	matLbl.TextScaled = true
	matLbl.Font = Enum.Font.GothamBold
	matLbl.Parent = matGui
	local bb = Instance.new("BillboardGui")
	bb.Name = "WayBillboard"
	bb.Size = UDim2.new(0, 140, 0, 40)
	bb.StudsOffset = Vector3.new(0, 3.5, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 90
	bb.Parent = mat
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundColor3 = color or Color3.fromRGB(255, 180, 220)
	lbl.BackgroundTransparency = 0.2
	lbl.Text = label
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextScaled = true
	lbl.Parent = bb
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = lbl
	return mat
end


local function addSlidingGlassDoor(parent, opts)
	local centerX = opts.CenterX
	local facadeZ = opts.FacadeZ
	local wallH = opts.WallH
	local doorW = opts.DoorW
	local slide = opts.Slide
	local modelName = opts.ModelName
	local objectText = opts.ObjectText
	local billboardText = opts.BillboardText
	local leftName = opts.LeftName
	local rightName = opts.RightName
	local sensorName = opts.SensorName
	local promptName = opts.PromptName
	local clickName = opts.ClickName

	local glassColor = Color3.fromRGB(170, 220, 245)
	local entrance = Instance.new("Model")
	entrance.Name = modelName
	entrance.Parent = parent

	local leafH = wallH - 1.4
	local leafY = leafH / 2
	local leftClosed = CFrame.new(centerX - doorW / 4, leafY, facadeZ)
	local rightClosed = CFrame.new(centerX + doorW / 4, leafY, facadeZ)
	local leftOpen = leftClosed * CFrame.new(-slide, 0, 0)
	local rightOpen = rightClosed * CFrame.new(slide, 0, 0)

	local leftDoor = makePart({
		Name = leftName,
		Size = Vector3.new(doorW / 2 - 0.15, leafH, 0.3),
		CFrame = leftClosed,
		Color = glassColor,
		Material = Enum.Material.Glass,
		Transparency = 0.5,
		Reflectance = 0.4,
		Parent = entrance,
	})
	local rightDoor = makePart({
		Name = rightName,
		Size = Vector3.new(doorW / 2 - 0.15, leafH, 0.3),
		CFrame = rightClosed,
		Color = glassColor,
		Material = Enum.Material.Glass,
		Transparency = 0.5,
		Reflectance = 0.4,
		Parent = entrance,
	})

	local sensor = makePart({
		Name = sensorName,
		Size = Vector3.new(doorW, leafH, 2),
		Position = Vector3.new(centerX, leafY, facadeZ),
		Transparency = 1,
		CanCollide = false,
		CanQuery = true,
		CanTouch = false,
		Parent = entrance,
	})

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = promptName
	prompt.ObjectText = objectText
	prompt.ActionText = "Открыть дверь"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Enabled = true
	prompt.Parent = sensor

	local click = Instance.new("ClickDetector")
	click.Name = clickName
	click.MaxActivationDistance = 22
	click.Parent = sensor

	local isOpen = false
	local busy = false
	local autoCloseToken = 0
	local tweenInfo = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local function setOpen(open)
		if busy or open == isOpen then return end
		busy = true
		isOpen = open
		leftDoor.CanCollide = not open
		rightDoor.CanCollide = not open
		TweenService:Create(leftDoor, tweenInfo, { CFrame = open and leftOpen or leftClosed }):Play()
		TweenService:Create(rightDoor, tweenInfo, { CFrame = open and rightOpen or rightClosed }):Play()
		prompt.ActionText = open and "Закрыть дверь" or "Открыть дверь"
		task.delay(0.5, function()
			busy = false
		end)
		if open then
			autoCloseToken += 1
			local token = autoCloseToken
			task.delay(4, function()
				if token == autoCloseToken and isOpen then
					setOpen(false)
				end
			end)
		end
	end

	local function toggle()
		setOpen(not isOpen)
	end

	prompt.Triggered:Connect(toggle)
	click.MouseClick:Connect(toggle)
	return entrance
end


local function addGlassFacadeAndSlidingDoor(parent, center, half, wallH)
	local facadeZ = center.Z - half
	local glassY = wallH / 2
	local doorW = 8
	local facadeWidth = half * 2
	local panelW = (facadeWidth - doorW) / 2
	local glassColor = Color3.fromRGB(170, 220, 245)
	local frameColor = Color3.fromRGB(40, 45, 55)

	-- боковые стеклянные панели фасада
	makePart({
		Name = "GlassFacadeLeft",
		Size = Vector3.new(panelW, wallH, 0.35),
		Position = Vector3.new(center.X - doorW / 2 - panelW / 2, glassY, facadeZ),
		Color = glassColor,
		Material = Enum.Material.Glass,
		Transparency = 0.55,
		Reflectance = 0.35,
		Parent = parent,
	})
	makePart({
		Name = "GlassFacadeRight",
		Size = Vector3.new(panelW, wallH, 0.35),
		Position = Vector3.new(center.X + doorW / 2 + panelW / 2, glassY, facadeZ),
		Color = glassColor,
		Material = Enum.Material.Glass,
		Transparency = 0.55,
		Reflectance = 0.35,
		Parent = parent,
	})

	-- верхняя перемычка над дверью
	makePart({
		Name = "DoorHeader",
		Size = Vector3.new(doorW + 1.2, 1.2, 0.5),
		Position = Vector3.new(center.X, wallH - 0.6, facadeZ),
		Color = frameColor,
		Material = Enum.Material.Metal,
		Parent = parent,
	})

	local entrance = Instance.new("Model")
	entrance.Name = "ShopEntrance"
	entrance.Parent = parent

	local leafH = wallH - 1.4
	local leafY = leafH / 2
	local leafDepth = 0.3
	local slide = 3.2

	local leftClosed = CFrame.new(center.X - doorW / 4, leafY, facadeZ)
	local rightClosed = CFrame.new(center.X + doorW / 4, leafY, facadeZ)
	local leftOpen = leftClosed * CFrame.new(-slide, 0, 0)
	local rightOpen = rightClosed * CFrame.new(slide, 0, 0)

	local leftDoor = makePart({
		Name = "DoorLeft",
		Size = Vector3.new(doorW / 2 - 0.1, leafH, leafDepth),
		CFrame = leftClosed,
		Color = glassColor,
		Material = Enum.Material.Glass,
		Transparency = 0.5,
		Reflectance = 0.4,
		Parent = entrance,
	})
	local rightDoor = makePart({
		Name = "DoorRight",
		Size = Vector3.new(doorW / 2 - 0.1, leafH, leafDepth),
		CFrame = rightClosed,
		Color = glassColor,
		Material = Enum.Material.Glass,
		Transparency = 0.5,
		Reflectance = 0.4,
		Parent = entrance,
	})

	-- невидимый сенсор для промпта/клика
	local sensor = makePart({
		Name = "DoorSensor",
		Size = Vector3.new(doorW, leafH, 2),
		Position = Vector3.new(center.X, leafY, facadeZ),
		Transparency = 1,
		CanCollide = false,
		CanQuery = true,
		CanTouch = false,
		Parent = entrance,
	})

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "DoorPrompt"
	prompt.ObjectText = "Вход Otaku Haven"
	prompt.ActionText = "Открыть дверь"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Enabled = true
	prompt.Parent = sensor

	local click = Instance.new("ClickDetector")
	click.Name = "DoorClick"
	click.MaxActivationDistance = 22
	click.Parent = sensor

	local isOpen = false
	local busy = false
	local autoCloseToken = 0
	local tweenInfo = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local function setOpen(open)
		if busy or open == isOpen then return end
		busy = true
		isOpen = open
		local lTarget = open and leftOpen or leftClosed
		local rTarget = open and rightOpen or rightClosed
		leftDoor.CanCollide = not open
		rightDoor.CanCollide = not open
		TweenService:Create(leftDoor, tweenInfo, { CFrame = lTarget }):Play()
		TweenService:Create(rightDoor, tweenInfo, { CFrame = rTarget }):Play()
		prompt.ActionText = open and "Закрыть дверь" or "Открыть дверь"
		task.delay(0.5, function()
			busy = false
		end)
		if open then
			autoCloseToken += 1
			local token = autoCloseToken
			task.delay(4, function()
				if token == autoCloseToken and isOpen then
					setOpen(false)
				end
			end)
		end
	end

	local function toggle()
		setOpen(not isOpen)
	end

	prompt.Triggered:Connect(function()
		toggle()
	end)
	click.MouseClick:Connect(function()
		toggle()
	end)

	entrance:SetAttribute("IsOpen", false)
	return entrance
end

local function decorateFusumaFace(part, face, kind)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = part

	local bg = Instance.new("Frame")
	bg.Name = "Paper"
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(245, 235, 210)
	bg.BorderSizePixel = 0
	bg.Parent = gui

	-- деревянная сетка фусумы
	for i = 1, 3 do
		local v = Instance.new("Frame")
		v.Size = UDim2.new(0, 4, 1, 0)
		v.Position = UDim2.fromScale(i / 4, 0)
		v.BackgroundColor3 = Color3.fromRGB(90, 55, 30)
		v.BorderSizePixel = 0
		v.Parent = bg
	end
	for i = 1, 4 do
		local h = Instance.new("Frame")
		h.Size = UDim2.new(1, 0, 0, 4)
		h.Position = UDim2.fromScale(0, i / 5)
		h.BackgroundColor3 = Color3.fromRGB(90, 55, 30)
		h.BorderSizePixel = 0
		h.Parent = bg
	end

	if kind == "dragon" then
		local dragon = Instance.new("TextLabel")
		dragon.Size = UDim2.fromScale(0.9, 0.7)
		dragon.Position = UDim2.fromScale(0.05, 0.1)
		dragon.BackgroundTransparency = 1
		dragon.Text = "龍\n雲"
		dragon.TextColor3 = Color3.fromRGB(160, 40, 45)
		dragon.TextScaled = true
		dragon.Font = Enum.Font.GothamBold
		dragon.Parent = bg
		local sub = Instance.new("TextLabel")
		sub.Size = UDim2.fromScale(0.9, 0.18)
		sub.Position = UDim2.fromScale(0.05, 0.78)
		sub.BackgroundTransparency = 1
		sub.Text = "〜 dragon 〜"
		sub.TextColor3 = Color3.fromRGB(120, 70, 40)
		sub.TextScaled = true
		sub.Font = Enum.Font.Gotham
		sub.Parent = bg
	else
		-- бамбук: стебли + листья текстом
		for i = 1, 5 do
			local stalk = Instance.new("Frame")
			stalk.Size = UDim2.new(0, 10, 0.78, 0)
			stalk.Position = UDim2.new(0.12 + (i - 1) * 0.16, 0, 0.12, 0)
			stalk.BackgroundColor3 = Color3.fromRGB(70, 130, 55)
			stalk.BorderSizePixel = 0
			stalk.Parent = bg
			for n = 1, 4 do
				local node = Instance.new("Frame")
				node.Size = UDim2.new(1.4, 0, 0, 5)
				node.Position = UDim2.new(-0.2, 0, n / 5, 0)
				node.BackgroundColor3 = Color3.fromRGB(45, 90, 35)
				node.BorderSizePixel = 0
				node.Parent = stalk
			end
		end
		local leaf = Instance.new("TextLabel")
		leaf.Size = UDim2.fromScale(0.9, 0.22)
		leaf.Position = UDim2.fromScale(0.05, 0.02)
		leaf.BackgroundTransparency = 1
		leaf.Text = "竹  竹  竹"
		leaf.TextColor3 = Color3.fromRGB(40, 100, 50)
		leaf.TextScaled = true
		leaf.Font = Enum.Font.GothamBold
		leaf.Parent = bg
	end
end

local function addFusumaRoomDoor(parent, center, half, floor2Y, wall2H, floorSize)
	local wood = Color3.fromRGB(110, 70, 40)
	local paper = Color3.fromRGB(240, 228, 200)
	local wallT = 1
	local doorW = 0.45 -- thickness on X
	local doorH = wall2H - 1.4
	-- в 2 раза шире + южный коридор свободен для выхода на балкон
	local leafD = 11 -- depth along Z per leaf (was 5.5)
	local openingD = leafD * 2 + 0.4
	local openingZ = center.Z
	local divX = center.X
	local yMid = floor2Y + wall2H / 2

	local balconyClearZ = center.Z - half + 12
	local zMax = center.Z + half - 1
	local open0 = openingZ - openingD / 2
	local open1 = openingZ + openingD / 2

	local function divPanel(name, z0, z1)
		if z1 - z0 < 0.5 then return end
		makePart({
			Name = name,
			Size = Vector3.new(wallT, wall2H - 0.4, z1 - z0),
			Position = Vector3.new(divX, yMid, (z0 + z1) / 2),
			Color = Color3.fromRGB(220, 200, 235),
			Parent = parent,
		})
	end
	divPanel("RoomDividerS", balconyClearZ, open0)
	divPanel("RoomDividerN", open1, zMax)

	-- верхняя перемычка над проёмом
	makePart({
		Name = "FusumaHeader",
		Size = Vector3.new(wallT + 0.4, 1.1, openingD + 1),
		Position = Vector3.new(divX, floor2Y + wall2H - 0.55, openingZ),
		Color = wood,
		Material = Enum.Material.Wood,
		Parent = parent,
	})
	-- порог
	makePart({
		Name = "FusumaSill",
		Size = Vector3.new(wallT + 0.6, 0.35, openingD + 0.6),
		Position = Vector3.new(divX, floor2Y + 0.55, openingZ),
		Color = wood,
		Material = Enum.Material.Wood,
		Parent = parent,
	})

	local fusuma = Instance.new("Model")
	fusuma.Name = "FusumaDoor"
	fusuma.Parent = parent

	local leftClosed = CFrame.new(divX, floor2Y + 0.7 + doorH / 2, openingZ - leafD / 2)
	local rightClosed = CFrame.new(divX, floor2Y + 0.7 + doorH / 2, openingZ + leafD / 2)
	local slide = leafD - 0.3
	local leftOpen = leftClosed * CFrame.new(0, 0, -slide)
	local rightOpen = rightClosed * CFrame.new(0, 0, slide)

	local function makeLeaf(name, cf, artKind)
		local leaf = makePart({
			Name = name,
			Size = Vector3.new(doorW, doorH, leafD - 0.15),
			CFrame = cf,
			Color = paper,
			Material = Enum.Material.SmoothPlastic,
			Parent = fusuma,
		})
		decorateFusumaFace(leaf, Enum.NormalId.Left, artKind)
		decorateFusumaFace(leaf, Enum.NormalId.Right, artKind)
		return leaf
	end

	local leftDoor = makeLeaf("FusumaLeft", leftClosed, "dragon")
	local rightDoor = makeLeaf("FusumaRight", rightClosed, "bamboo")

	local sensor = makePart({
		Name = "FusumaSensor",
		Size = Vector3.new(4, doorH, openingD),
		Position = Vector3.new(divX, floor2Y + 0.7 + doorH / 2, openingZ),
		Transparency = 1,
		CanCollide = false,
		CanQuery = true,
		CanTouch = false,
		Parent = fusuma,
	})

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "FusumaPrompt"
	prompt.ObjectText = "Фусума"
	prompt.ActionText = "Раздвинуть"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = sensor

	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 20
	click.Parent = sensor

	local isOpen = false
	local busy = false
	local autoCloseToken = 0
	local tweenInfo = TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local function setOpen(open)
		if busy or open == isOpen then return end
		busy = true
		isOpen = open
		leftDoor.CanCollide = not open
		rightDoor.CanCollide = not open
		TweenService:Create(leftDoor, tweenInfo, { CFrame = open and leftOpen or leftClosed }):Play()
		TweenService:Create(rightDoor, tweenInfo, { CFrame = open and rightOpen or rightClosed }):Play()
		prompt.ActionText = open and "Закрыть" or "Раздвинуть"
		task.delay(0.6, function()
			busy = false
		end)
		if open then
			autoCloseToken += 1
			local token = autoCloseToken
			task.delay(5, function()
				if token == autoCloseToken and isOpen then
					setOpen(false)
				end
			end)
		end
	end

	local function toggle()
		setOpen(not isOpen)
	end
	prompt.Triggered:Connect(toggle)
	click.MouseClick:Connect(toggle)
	return fusuma
end

local function addUpperFloorRoofAndBalcony(haven, center, half, floor1H)
	local upper = Instance.new("Folder")
	upper.Name = "UpperFloor"
	upper.Parent = haven

	local floorSize = half * 2
	local floor2Y = floor1H + 0.5
	local wall2H = 12
	local wallT = 1
	local wood = Color3.fromRGB(255, 240, 225)
	local wallPink = Color3.fromRGB(235, 210, 245)
	local tileColor = Color3.fromRGB(170, 55, 50)
	local tileDark = Color3.fromRGB(130, 40, 40)

	-- Перекрытие 2 этажа с проёмом под лестницу (SW)
	do
		local t = 0.8
		local holeW, holeD = 8, 22
		local holeX = center.X - half + 5
		local holeZ = center.Z - half + 18
		local y = floor2Y
		local xMin, xMax = center.X - half + 0.5, center.X + half - 0.5
		local zMin, zMax = center.Z - half + 0.5, center.Z + half - 0.5
		local hx0, hx1 = holeX - holeW / 2, holeX + holeW / 2
		local hz0, hz1 = holeZ - holeD / 2, holeZ + holeD / 2
		local function floorPanel(name, x0, x1, z0, z1)
			if x1 - x0 < 0.5 or z1 - z0 < 0.5 then return end
			makePart({
				Name = name,
				Size = Vector3.new(x1 - x0, t, z1 - z0),
				Position = Vector3.new((x0 + x1) / 2, y, (z0 + z1) / 2),
				Color = wood,
				Material = Enum.Material.WoodPlanks,
				Parent = upper,
			})
		end
		floorPanel("Floor2_N", xMin, xMax, hz1, zMax)
		floorPanel("Floor2_S", xMin, xMax, zMin, hz0)
		floorPanel("Floor2_W", xMin, hx0, hz0, hz1)
		floorPanel("Floor2_E", hx1, xMax, hz0, hz1)
	end

	-- Стены 2 этажа
	makePart({ Name = "Wall2Left", Size = Vector3.new(wallT, wall2H, floorSize), Position = center + Vector3.new(-half, floor2Y + wall2H / 2, 0), Color = wallPink, Parent = upper })
	makePart({ Name = "Wall2Right", Size = Vector3.new(wallT, wall2H, floorSize), Position = center + Vector3.new(half, floor2Y + wall2H / 2, 0), Color = wallPink, Parent = upper })
	makePart({ Name = "Wall2North", Size = Vector3.new(floorSize, wall2H, wallT), Position = center + Vector3.new(0, floor2Y + wall2H / 2, half), Color = wallPink, Parent = upper })
	-- Юг 2 этажа с проёмом на балкон
	do
		local doorW = 14
		local panelW = (floorSize - doorW) / 2
		local z = center.Z - half
		makePart({ Name = "Wall2SouthL", Size = Vector3.new(panelW, wall2H, wallT), Position = Vector3.new(center.X - doorW / 2 - panelW / 2, floor2Y + wall2H / 2, z), Color = wallPink, Parent = upper })
		makePart({ Name = "Wall2SouthR", Size = Vector3.new(panelW, wall2H, wallT), Position = Vector3.new(center.X + doorW / 2 + panelW / 2, floor2Y + wall2H / 2, z), Color = wallPink, Parent = upper })
		makePart({ Name = "Wall2SouthHeader", Size = Vector3.new(doorW + 0.5, 1.2, wallT), Position = Vector3.new(center.X, floor2Y + wall2H - 0.6, z), Color = wallPink, Parent = upper })
	end

	-- Перегородка + раздвижная фусума (дракон / бамбук) между комнатами
	addFusumaRoomDoor(upper, center, half, floor2Y, wall2H, floorSize)

	local roomA = Instance.new("Folder")
	roomA.Name = "RoomA"
	roomA.Parent = upper
	local roomB = Instance.new("Folder")
	roomB.Name = "RoomB"
	roomB.Parent = upper

	-- Комната A (запад): lounge / манга
	makePart({
		Name = "RoomA_TatamiHint",
		Size = Vector3.new(half - 4, 0.12, half - 6),
		Position = center + Vector3.new(-half / 2, floor2Y + 0.5, 0),
		Color = Color3.fromRGB(230, 210, 150),
		Material = Enum.Material.Fabric,
		CanCollide = false,
		Parent = roomA,
	})
	makePart({
		Name = "RoomA_Shelf",
		Size = Vector3.new(10, 4, 1.2),
		Position = center + Vector3.new(-half + 6, floor2Y + 2.5, half - 6),
		Color = Color3.fromRGB(120, 80, 50),
		Material = Enum.Material.Wood,
		Parent = roomA,
	})

	-- Комната B (восток): cosplay / staff
	makePart({
		Name = "RoomB_Carpet",
		Size = Vector3.new(half - 4, 0.12, half - 6),
		Position = center + Vector3.new(half / 2, floor2Y + 0.5, 0),
		Color = Color3.fromRGB(255, 180, 210),
		Material = Enum.Material.Fabric,
		CanCollide = false,
		Parent = roomB,
	})
	makePart({
		Name = "RoomB_Mirror",
		Size = Vector3.new(0.4, 5, 6),
		Position = center + Vector3.new(half - 2, floor2Y + 3.2, 0),
		Color = Color3.fromRGB(200, 230, 255),
		Material = Enum.Material.Glass,
		Transparency = 0.35,
		Parent = roomB,
	})

	-- Лестница аниме-стиль (у левой стены, от входа вверх)
	local stairs = Instance.new("Model")
	stairs.Name = "AnimeStairs"
	stairs.Parent = upper
	local steps = math.max(14, math.ceil(floor2Y / 0.78))
	local stepH = floor2Y / steps
	local stepD = 1.35
	local stairX = center.X - half + 5
	local startZ = center.Z - half + 10
	for i = 1, steps do
		local y = 1 + i * stepH
		local z = startZ + (i - 1) * stepD
		makePart({
			Name = "Step" .. i,
			Size = Vector3.new(5.5, math.max(0.35, stepH * 0.9), stepD * 0.95),
			Position = Vector3.new(stairX, y, z),
			Color = Color3.fromRGB(190, 140, 95),
			Material = Enum.Material.Wood,
			Parent = stairs,
		})
		-- розовый акцент на торце
		if i % 2 == 0 then
			makePart({
				Name = "StepAccent" .. i,
				Size = Vector3.new(5.6, 0.12, 0.2),
				Position = Vector3.new(stairX, y + stepH * 0.4, z + stepD * 0.35),
				Color = Color3.fromRGB(255, 140, 190),
				Material = Enum.Material.Neon,
				CanCollide = false,
				Transparency = 0.35,
				Parent = stairs,
			})
		end
	end
	-- перила
	for i = 1, steps, 2 do
		local y = 1 + i * stepH + 1.4
		local z = startZ + (i - 1) * stepD
		makePart({
			Name = "RailPost" .. i,
			Size = Vector3.new(0.25, 2.6, 0.25),
			Position = Vector3.new(stairX + 2.6, y, z),
			Color = Color3.fromRGB(255, 200, 230),
			Material = Enum.Material.SmoothPlastic,
			Parent = stairs,
		})
	end
	makePart({
		Name = "Handrail",
		Size = Vector3.new(0.28, 0.28, steps * stepD),
		Position = Vector3.new(stairX + 2.6, floor2Y + 1.2, startZ + (steps * stepD) / 2 - stepD),
		Color = Color3.fromRGB(255, 170, 210),
		Material = Enum.Material.SmoothPlastic,
		Parent = stairs,
	})

	-- Балкон на южном фасаде
	local balcony = Instance.new("Model")
	balcony.Name = "Balcony"
	balcony.Parent = upper
	local balZ = center.Z - half - 5
	makePart({
		Name = "BalconyFloor",
		Size = Vector3.new(28, 0.6, 10),
		Position = Vector3.new(center.X, floor2Y + 0.2, balZ),
		Color = Color3.fromRGB(240, 220, 200),
		Material = Enum.Material.WoodPlanks,
		Parent = balcony,
	})
	-- ограждение
	for _, off in ipairs({
		{Vector3.new(0, 1.4, -4.7), Vector3.new(28, 2.4, 0.3)},
		{Vector3.new(-13.7, 1.4, 0), Vector3.new(0.3, 2.4, 10)},
		{Vector3.new(13.7, 1.4, 0), Vector3.new(0.3, 2.4, 10)},
	}) do
		makePart({
			Name = "BalconyRail",
			Size = off[2],
			Position = Vector3.new(center.X, floor2Y + 0.2, balZ) + off[1],
			Color = Color3.fromRGB(255, 190, 220),
			Material = Enum.Material.SmoothPlastic,
			Parent = balcony,
		})
	end
	-- столрики на перилах
	for i = -4, 4 do
		makePart({
			Name = "BalconyPick" .. i,
			Size = Vector3.new(0.2, 2.2, 0.2),
			Position = Vector3.new(center.X + i * 3, floor2Y + 1.4, balZ - 4.7),
			Color = Color3.fromRGB(255, 255, 255),
			Parent = balcony,
		})
	end

		-- Сплошная черепичная крыша (без просветов), приподнята над стенами
	local roof = Instance.new("Folder")
	roof.Name = "TileRoof"
	roof.Parent = upper
	local roofLift = 2.5 -- зазор над стеной, чтобы не цеплять головой у скатов
	local roofBaseY = floor2Y + wall2H + roofLift
	local roofLen = floorSize + 10
	local pitch = math.rad(28)

	-- Герметичный потолок под скатами
	makePart({
		Name = "RoofCeiling",
		Size = Vector3.new(floorSize + 2, 1.2, floorSize + 2),
		Position = center + Vector3.new(0, floor2Y + wall2H + 0.6, 0),
		Color = tileDark,
		Material = Enum.Material.Slate,
		Parent = roof,
	})

	-- Сплошные скаты (левый / правый) — выше стен
	for _, side in ipairs({-1, 1}) do
		local span = half + 5
		makePart({
			Name = side < 0 and "RoofSlopeL" or "RoofSlopeR",
			Size = Vector3.new(span + 4, 1.8, roofLen),
			CFrame = CFrame.new(center.X + side * (span * 0.45), roofBaseY + 4.5, center.Z)
				* CFrame.Angles(0, 0, side * (-pitch)),
			Color = tileColor,
			Material = Enum.Material.Slate,
			Parent = roof,
		})
	end

	-- Декоративная черепица поверх (с перекрытием, без дыр)
	local rows = 12
	local cols = 22
	for row = 0, rows - 1 do
		local t = row / math.max(1, rows - 1)
		local y = roofBaseY + 0.5 + t * 9.2
		local xOff = (half + 3) * (1 - t * 0.92)
		for _, side in ipairs({-1, 1}) do
			for col = 0, cols - 1 do
				local z = center.Z - half - 3 + col * ((floorSize + 8) / (cols - 0.01))
				makePart({
					Name = "Tile",
					Size = Vector3.new(3.6, 0.5, 2.8),
					CFrame = CFrame.new(center.X + side * xOff, y, z)
						* CFrame.Angles(0, 0, side * (-pitch)),
					Color = ((row + col) % 2 == 0) and tileColor or tileDark,
					Material = Enum.Material.Slate,
					CanCollide = false,
					Parent = roof,
				})
			end
		end
	end

	makePart({
		Name = "RoofRidge",
		Size = Vector3.new(4, 1.6, floorSize + 12),
		Position = center + Vector3.new(0, roofBaseY + 9.5, 0),
		Color = tileDark,
		Material = Enum.Material.Slate,
		Parent = roof,
	})
	for _, side in ipairs({-1, 1}) do
		makePart({
			Name = "RoofOrnament",
			Size = Vector3.new(2, 3, 2),
			Position = center + Vector3.new(0, roofBaseY + 11.5, side * (half + 1)),
			Color = Color3.fromRGB(255, 210, 80),
			Material = Enum.Material.SmoothPlastic,
			Parent = roof,
		})
	end
end

-- Атмосферный декор (GDD Scene 1 polish): гирлянды, ковровая дорожка, фонари, баннеры, растения
local function addAtmosphereDecor(decor, haven, center, half, wallH)
	local folder = Instance.new("Folder")
	folder.Name = "AtmosphereDecor"
	folder.Parent = decor

	-- ковровая дорожка Genkan → касса
	do
		local counter = ZoneConfig.CounterPosition
		local genkan = ZoneConfig.Zones.Genkan.Center
		local mid = (Vector3.new(genkan.X, 0, genkan.Z) + Vector3.new(counter.X, 0, counter.Z)) * 0.5
		local delta = Vector3.new(counter.X - genkan.X, 0, counter.Z - genkan.Z)
		local len = math.max(8, delta.Magnitude + 2)
		local runnerCF = CFrame.lookAt(
			Vector3.new(mid.X, 1.56, mid.Z),
			Vector3.new(counter.X, 1.56, counter.Z)
		) * CFrame.Angles(0, math.rad(90), 0)
		local runner = makePart({
			Name = "AisleRunner",
			Size = Vector3.new(3.2, 0.08, len),
			CFrame = runnerCF,
			Color = Color3.fromRGB(190, 60, 110),
			Material = Enum.Material.Fabric,
			CanCollide = false,
			Parent = folder,
		})
		makePart({
			Name = "AisleRunnerEdge",
			Size = Vector3.new(3.4, 0.04, len + 0.2),
			CFrame = runner.CFrame * CFrame.new(0, -0.04, 0),
			Color = Color3.fromRGB(255, 210, 230),
			Material = Enum.Material.Fabric,
			CanCollide = false,
			Parent = folder,
		})
	end

	-- потолочная гирлянда (неоновые бусины)
	do
		local y = wallH - 1.2
		local idx = 0
		for z = -half + 6, half - 6, 4 do
			for x = -18, 18, 6 do
				idx += 1
				local hue = (idx % 3)
				local col = if hue == 0
					then Color3.fromRGB(255, 140, 220)
					elseif hue == 1 then Color3.fromRGB(120, 220, 255)
					else Color3.fromRGB(255, 210, 120)
				local bead = makePart({
					Name = "FairyLight",
					Size = Vector3.new(0.35, 0.35, 0.35),
					Position = center + Vector3.new(x + (idx % 2) * 0.8, y, z),
					Color = col,
					Material = Enum.Material.Neon,
					CanCollide = false,
					Parent = folder,
				})
				bead.Shape = Enum.PartType.Ball
				local pl = Instance.new("PointLight")
				pl.Color = col
				pl.Brightness = 0.1
				pl.Range = 3.5
				pl.Parent = bead
			end
		end
	end

	-- PaperLanterns у двери убраны

	-- ClothBanner CATCH/BATTLE/EVOLVE/COLLECT убраны

	-- доп. постеры + standee у входа
	addPoster(folder, center + Vector3.new(-17, 5, 8), Color3.fromRGB(255, 160, 80))
	addPoster(folder, center + Vector3.new(17, 5, 8), Color3.fromRGB(140, 255, 200))
	addPoster(folder, center + Vector3.new(-17, 5, 18), Color3.fromRGB(200, 120, 255))
	addStandee(folder, center + Vector3.new(10, 3.5, 14))

	-- растения у входа / выхода
	local function addPlanter(name, pos)
		local pot = makePart({
			Name = name .. "_Pot",
			Size = Vector3.new(1.6, 1.2, 1.6),
			Position = pos,
			Color = Color3.fromRGB(90, 55, 40),
			Material = Enum.Material.Concrete,
			Parent = folder,
		})
		makePart({
			Name = name .. "_Foliage",
			Size = Vector3.new(2.2, 2.4, 2.2),
			Position = pos + Vector3.new(0, 1.6, 0),
			Color = Color3.fromRGB(55, 140, 70),
			Material = Enum.Material.SmoothPlastic, -- avoid Grass Part shimmer near Genkan
			CanCollide = false,
			Parent = folder,
		})
		return pot
	end
	addPlanter("PlantEntranceL", center + Vector3.new(-6, 2.1, -half + 3))
	addPlanter("PlantEntranceR", center + Vector3.new(6, 2.1, -half + 3))
	addPlanter("PlantExitL", center + Vector3.new(-8, 2.1, half - 3))
	addPlanter("PlantExitR", center + Vector3.new(8, 2.1, half - 3))

	-- тёплые потолочные споты над залом
	for i, xz in ipairs({
		Vector3.new(-12, 0, -8),
		Vector3.new(12, 0, -8),
		Vector3.new(-12, 0, 10),
		Vector3.new(12, 0, 10),
		Vector3.new(0, 0, 0),
	}) do
		local fixture = makePart({
			Name = "CeilingSpot" .. i,
			Size = Vector3.new(0.6, 0.25, 0.6),
			Position = center + Vector3.new(xz.X, wallH - 0.4, xz.Z),
			Color = Color3.fromRGB(40, 40, 50),
			CanCollide = false,
			Parent = folder,
		})
		local spot = Instance.new("SpotLight")
		spot.Face = Enum.NormalId.Bottom
		spot.Color = Color3.fromRGB(255, 230, 210)
		spot.Brightness = 0.55
		spot.Range = 24
		spot.Angle = 70
		spot.Parent = fixture
	end

	-- PathLanterns removed

	-- мягкий «парковочный» плейсхолдер (соц. статус) — детальные машины в CityDistrict
	for i, ox in ipairs({ -18, 18 }) do
		makePart({
			Name = "ParkingPad" .. i,
			Size = Vector3.new(6, 0.15, 10),
			Position = center + Vector3.new(ox, 1.12, -half - 9),
			Color = Color3.fromRGB(55, 55, 70),
			Material = Enum.Material.Asphalt,
			CanCollide = false,
			Parent = folder,
		})
	end
end

local function ensureHavenMoodLighting()
	-- Prevent opaque magenta/fog: only one Sky + one Atmosphere
	for _, c in ipairs(Lighting:GetChildren()) do
		if c:IsA("Atmosphere") and c.Name ~= "OtakuHavenAtmosphere" then
			c:Destroy()
		elseif c:IsA("Sky") and c.Name ~= "Sky" then
			c:Destroy()
		end
	end
	for _, name in ipairs({ "CoastColor", "CoastBloom", "CoastSunRays", "CoastAtmosphere", "CoastSky" }) do
		local e = Lighting:FindFirstChild(name)
		if e then
			if e:IsA("Atmosphere") or e:IsA("Sky") then
				e:Destroy()
			elseif e:IsA("PostEffect") then
				e.Enabled = false
			end
		end
	end

	local mood = Lighting:FindFirstChild("OtakuHavenMood")
	if not mood then
		mood = Instance.new("ColorCorrectionEffect")
		mood.Name = "OtakuHavenMood"
		mood.Parent = Lighting
	end
	mood.TintColor = Color3.fromRGB(255, 245, 250)
	mood.Saturation = 0.05
	mood.Contrast = 0.02
	mood.Brightness = 0
	mood.Enabled = true

	local bloom = Lighting:FindFirstChild("OtakuHavenBloom")
	if not bloom then
		bloom = Instance.new("BloomEffect")
		bloom.Name = "OtakuHavenBloom"
		bloom.Parent = Lighting
	end
	bloom.Intensity = 0.12
	bloom.Size = 24
	bloom.Threshold = 2.0

	Lighting.Brightness = 2
	Lighting.ExposureCompensation = 0
	Lighting.EnvironmentDiffuseScale = 0.5
	Lighting.EnvironmentSpecularScale = 0.3
	Lighting.OutdoorAmbient = Color3.fromRGB(140, 135, 150)
	Lighting.Ambient = Color3.fromRGB(120, 115, 130)
	Lighting.FogEnd = 100000

	local atmosphere = Lighting:FindFirstChild("OtakuHavenAtmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Name = "OtakuHavenAtmosphere"
		atmosphere.Parent = Lighting
	end
	atmosphere.Density = 0.22
	atmosphere.Offset = 0.1
	atmosphere.Color = Color3.fromRGB(200, 190, 210)
	atmosphere.Decay = Color3.fromRGB(120, 100, 140)
	atmosphere.Glare = 0.08
	atmosphere.Haze = 0.4

	local globalBloom = Lighting:FindFirstChild("Bloom")
	if globalBloom and globalBloom:IsA("BloomEffect") then
		globalBloom.Intensity = 0.25
		globalBloom.Size = 18
		globalBloom.Threshold = 2.2
	end
	local sun = Lighting:FindFirstChild("SunRays")
	if sun and sun:IsA("SunRaysEffect") then
		sun.Intensity = 0.01
		sun.Spread = 0.1
	end
end

function OtakuHavenBuilder.Build()
	local existing = workspace:FindFirstChild("OtakuHaven")
	if existing then existing:Destroy() end

	local haven = Instance.new("Model")
	haven.Name = "OtakuHaven"
	haven.Parent = workspace

	local zonesFolder = Instance.new("Folder")
	zonesFolder.Name = "Zones"
	zonesFolder.Parent = haven

	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	decor.Parent = haven

	local center = ZoneConfig.HavenCenter
	local floorY = 0.5
	local floorSize = 76
	local half = floorSize / 2
	local wallH, wallT = 12, 1

	makePart({
		Name = "Floor",
		Size = Vector3.new(floorSize, 1, floorSize),
		Position = center + Vector3.new(0, floorY, 0),
		Color = Color3.fromRGB(255, 245, 235),
		Material = Enum.Material.WoodPlanks,
		Parent = haven,
	})

	-- фасад (юг): стекло + раздвижная дверь вместо глухой WallBack
	addGlassFacadeAndSlidingDoor(haven, center, half, wallH)
	makePart({ Name = "WallLeft", Size = Vector3.new(wallT, wallH, floorSize), Position = center + Vector3.new(-half, wallH / 2, 0), Color = Color3.fromRGB(230, 210, 255), Parent = haven })
	makePart({ Name = "WallRight", Size = Vector3.new(wallT, wallH, floorSize), Position = center + Vector3.new(half, wallH / 2, 0), Color = Color3.fromRGB(230, 210, 255), Parent = haven })

	-- стенка напротив стеклянной витрины (север), с проёмом на выход в Акихабару
	do
		local backZ = center.Z + half
		local exitW = 12
		local panelW = (floorSize - exitW) / 2
		local wallColor = Color3.fromRGB(245, 225, 240)
		makePart({
			Name = "WallNorthLeft",
			Size = Vector3.new(panelW, wallH, wallT),
			Position = Vector3.new(center.X - exitW / 2 - panelW / 2, wallH / 2, backZ),
			Color = wallColor,
			Parent = haven,
		})
		makePart({
			Name = "WallNorthRight",
			Size = Vector3.new(panelW, wallH, wallT),
			Position = Vector3.new(center.X + exitW / 2 + panelW / 2, wallH / 2, backZ),
			Color = wallColor,
			Parent = haven,
		})
		makePart({
			Name = "WallNorthHeader",
			Size = Vector3.new(exitW + 0.5, 1.2, wallT),
			Position = Vector3.new(center.X, wallH - 0.6, backZ),
			Color = wallColor,
			Parent = haven,
		})
	end

	addUpperFloorRoofAndBalcony(haven, center, half, wallH)

	makePart({
		Name = "Counter",
		Size = Vector3.new(10, 3.2, 2.5),
		Position = ZoneConfig.CounterPosition + Vector3.new(0, 2.1, 0),
		Color = Color3.fromRGB(139, 90, 60),
		Material = Enum.Material.Wood,
		Parent = haven,
	})

	addGenkanMat(decor, Vector3.new(ZoneConfig.Zones.Genkan.Center.X, 1.05, ZoneConfig.Zones.Genkan.Center.Z))

	local bell = makePart({
		Name = "EntranceBell",
		Size = Vector3.new(0.8, 0.8, 0.8),
		Position = ZoneConfig.Zones.Genkan.Center + Vector3.new(3.5, 4, -1),
		Color = Color3.fromRGB(255, 210, 80),
		Material = Enum.Material.Metal,
		Parent = decor,
	})
	bell:SetAttribute("RingOnTouch", true)
	local genkanCfg = ZoneConfig.Zones and ZoneConfig.Zones.Genkan
	local bellCenter = genkanCfg and genkanCfg.Center or Vector3.new(center.X, 3, center.Z - 34)
	local bellSize = genkanCfg and genkanCfg.Size or Vector3.new(12, 10, 8)
	local bellTrigger = makePart({
		Name = "BellTrigger",
		Size = Vector3.new(math.max(10, bellSize.X), 8, math.max(6, bellSize.Z)),
		Position = Vector3.new(bellCenter.X, 4, bellCenter.Z),
		Transparency = 1,
		CanCollide = false,
		CanTouch = true,
		CanQuery = false,
		Parent = decor,
	})
	local bellSound = Instance.new("Sound")
	bellSound.Name = "BellSound"
	bellSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
	bellSound.Volume = 0.85
	bellSound.Parent = bell

	-- Вывеска над дверью на балкон (2 этаж, юг)
	do
		local floor2Y = wallH + 0.5
		local wall2H = 12
		addNeonSign(haven, Vector3.new(center.X, floor2Y + wall2H + 1.4, center.Z - half - 0.55))
	end
	addLEDDisplay(decor, center + Vector3.new(-12, 5, -8), "NEW\nSPIRITS")
	addLEDDisplay(decor, center + Vector3.new(12, 5, -8), "LO-FI\nON")
	addPoster(decor, center + Vector3.new(-17, 5, -5), Color3.fromRGB(255, 100, 150))
	addPoster(decor, center + Vector3.new(17, 5, -5), Color3.fromRGB(100, 180, 255))
	addStandee(decor, center + Vector3.new(-10, 3.5, 10))
	addGacha(decor, center + Vector3.new(14, 3, 8))
	addMangaBuff(decor, center + Vector3.new(-14, 2.5, 8))
	addFittingRoom(decor, center + Vector3.new(8, 3.5, -6))
	-- Onboarding wayfind (P0 Hub): Mika → Manga → Exit
	do
		local qm = ZoneConfig.QuestMasterPosition or Vector3.new(-12, 0, -38)
		local exitZ = (ZoneConfig.Zones and ZoneConfig.Zones.Exit and ZoneConfig.Zones.Exit.Center.Z) or (center.Z + half - 4)
		-- wayfind pads removed (no permanent world pointers)
	end
	addAtmosphereDecor(decor, haven, center, half, wallH)
	ensureHavenMoodLighting()
	addSlidingGlassDoor(haven, {
		CenterX = center.X,
		FacadeZ = center.Z + half,
		WallH = wallH,
		DoorW = 10,
		Slide = 5.2,
		ModelName = "ShopExit",
		ObjectText = "Выход в Акихабару",
		BillboardText = "Exit → Combat",
		ShowBillboard = false,
		LeftName = "ExitDoorLeft",
		RightName = "ExitDoorRight",
		SensorName = "ExitDoorSensor",
		PromptName = "ExitDoorPrompt",
		ClickName = "ExitDoorClick",
	})

	for name, data in pairs(ZoneConfig.Zones) do
		if name ~= "Combat" then
			makeZone(name .. "Zone", name, data.Center, data.Size, zonesFolder)
		end
	end

	local akihabara = workspace:FindFirstChild("Akihabara")
	if akihabara then akihabara:Destroy() end
	akihabara = Instance.new("Model")
	akihabara.Name = "Akihabara"
	akihabara.Parent = workspace
	local combat = ZoneConfig.Zones.Combat
	makeZone("CombatZone", "Combat", combat.Center, combat.Size, akihabara)

	local atmosphere = Lighting:FindFirstChild("OtakuHavenAtmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Name = "OtakuHavenAtmosphere"
		atmosphere.Density = 0.25
		atmosphere.Offset = 0.1
		atmosphere.Color = Color3.fromRGB(255, 220, 240)
		atmosphere.Decay = Color3.fromRGB(180, 140, 200)
		atmosphere.Parent = Lighting
	end

	-- Стены/декор непрозрачны; стекло/зоны-триггеры не трогаем
	for _, d in ipairs(haven:GetDescendants()) do
		if d:IsA("BasePart") then
			local name = string.lower(d.Name)
			local mat = d.Material
			local isGlass = mat == Enum.Material.Glass
				or mat == Enum.Material.ForceField
				or string.find(name, "glass", 1, true)
				or string.find(name, "window", 1, true)
			local isZoneTrigger = d.Transparency >= 1 or string.find(name, "zone", 1, true)
			if not isGlass and not isZoneTrigger and d.Transparency > 0 then
				d.Transparency = 0
			end
		end
		if d:IsA("BillboardGui") then
			if d:GetAttribute("HubWayfind") == true or HUB_WAYFIND_BB_NAMES[d.Name] then
				d:Destroy()
			else
				d.AlwaysOnTop = false
			end
		end
	end

	OtakuHavenBuilder.BuildDirtRoadToArena()

	local buildCity = require(script.Parent:WaitForChild("OtakuCityDistrict"))({
		makePart = makePart,
		addPoster = addPoster,
		addStandee = addStandee,
		addLEDDisplay = addLEDDisplay,
		ZoneConfig = ZoneConfig,
	})
	buildCity(haven, center, half)

	-- Q3 Haven brand accent: lantern posts at Genkan / Exit approach
	do
		local accents = Instance.new("Folder")
		accents.Name = "BrandAccents"
		accents.Parent = decor
		for i, off in ipairs({
			Vector3.new(-18, 0, -half + 4),
			Vector3.new(18, 0, -half + 4),
			Vector3.new(-10, 0, half - 6),
			Vector3.new(10, 0, half - 6),
		}) do
			local post = makePart({
				Name = "LanternPost" .. i,
				Size = Vector3.new(0.6, 8, 0.6),
				Position = center + off + Vector3.new(0, 4, 0),
				Color = Color3.fromRGB(60, 45, 80),
				Material = Enum.Material.Metal,
				Parent = accents,
			})
			makePart({
				Name = "LanternGlow" .. i,
				Size = Vector3.new(1.4, 1.4, 1.4),
				Position = post.Position + Vector3.new(0, 4.2, 0),
				Color = Color3.fromRGB(255, 200, 120),
				Material = Enum.Material.Neon,
				CanCollide = false,
				Parent = accents,
			})
		end
	end

	-- Q3 Slice 2: Exit wayfind → арена / дуэль (читается из хаба)
	OtakuHavenBuilder.EnsureDuelWayfind(haven)
	-- B2 Explore hub 2: второй маршрут Haven→Combat (восточный обход)
	OtakuHavenBuilder.EnsureExploreHub2Route(haven)
	-- F2 scout line W1: wayfind Exit → ChestCluster (quest 109)
	OtakuHavenBuilder.EnsureChestClusterWayfind(haven)
	OtakuHavenBuilder.EnsureHubColdStartCopy(haven)

	return haven
end

function OtakuHavenBuilder.EnsureDuelWayfind(haven)
	haven = haven or workspace:FindFirstChild("OtakuHaven")
	destroyHubWayfindFolders(haven)
	return nil
end

-- Navigation wayfind removed; cleanup only on rebuild.
function OtakuHavenBuilder.EnsureExploreHub2Route(haven)
	haven = haven or workspace:FindFirstChild("OtakuHaven")
	destroyHubWayfindFolders(haven)
	return nil
end

-- F2 scout line W1: wayfind Exit → ChestCluster (quest 109)
function OtakuHavenBuilder.EnsureHubColdStartCopy(haven)
	haven = haven or workspace:FindFirstChild("OtakuHaven")
	if haven then
		clearHubWayfindBillboards(haven)
	end
	local qm = workspace:FindFirstChild("QuestMaster")
	if not qm then
		return
	end
	local anchor = qm:FindFirstChild("QuestInteractAnchor")
	if not anchor then
		return
	end
	local hint = anchor:FindFirstChild("TalkHint")
	if not hint then
		return
	end
	hint.Enabled = false
	hint.Size = UDim2.new(0, 140, 0, 36)
	local lbl = hint:FindFirstChild("Label")
	if lbl and lbl:IsA("TextLabel") then
		lbl.Text = "Мика [E]"
	end
end

function OtakuHavenBuilder.EnsureChestClusterWayfind(haven)
	haven = haven or workspace:FindFirstChild("OtakuHaven")
	destroyHubWayfindFolders(haven)
	return nil
end

function OtakuHavenBuilder.BuildDirtRoadToArena()
	local old = workspace:FindFirstChild("DirtRoad_HavenToArena")
	if old then old:Destroy() end

	local model = Instance.new("Model")
	model.Name = "DirtRoad_HavenToArena"
	model.Parent = workspace

	local function part(props)
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = props.CanCollide ~= false
		p.CanQuery = false
		p.CastShadow = true
		p.Material = props.Material or Enum.Material.SmoothPlastic
		p.Color = props.Color or Color3.fromRGB(91, 93, 105)
		p.Size = props.Size
		p.CFrame = props.CFrame or CFrame.new(props.Position)
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Name = props.Name or "RoadPart"
		p.Parent = model
		return p
	end

	-- Cross-section from free Creator Store "Anime Road" (asset 10235862952):
	-- asphalt 16 wide + double yellow center + sidewalks; uniform color (no zebra banding)
	local ptsXZ = {
		Vector3.new(-25, 0, 70),
		Vector3.new(-8, 0, 80),
		Vector3.new(18, 0, 78),
		Vector3.new(48, 0, 68),
		Vector3.new(78, 0, 54),
		Vector3.new(102, 0, 44),
		Vector3.new(118, 0, 40),
	}

	local THICK, ASPHALT_W, SIDEWALK_W, SEG_LEN = 0.35, 16, 4.5, 2.8
	local ASPHALT = Color3.fromRGB(91, 93, 105)
	local SIDEWALK = Color3.fromRGB(205, 205, 205)
	local CURB = Color3.fromRGB(163, 162, 165)
	local YELLOW = Color3.fromRGB(255, 176, 0)
	local GRASS = Color3.fromRGB(78, 160, 82)

	local rayExclude = { model }
	local aki = workspace:FindFirstChild("Akihabara")
	if aki then
		local cz = aki:FindFirstChild("CombatZone", true)
		if cz then table.insert(rayExclude, cz) end
	end
	local haven = workspace:FindFirstChild("OtakuHaven")
	if haven then table.insert(rayExclude, haven) end
	local arena = workspace:FindFirstChild("BattleArena")
	if arena then table.insert(rayExclude, arena) end

	local function groundY(x, z)
		local bestBp, bestArea = nil, -1
		for _, d in ipairs(workspace:GetChildren()) do
			if d.Name == "Baseplate" and d:IsA("BasePart") then
				local area = d.Size.X * d.Size.Z
				if area > bestArea then
					bestBp = d
					bestArea = area
				end
			end
		end
		local baseTop = if bestBp then bestBp.Position.Y + bestBp.Size.Y * 0.5 else 0
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = rayExclude
		local hit = workspace:Raycast(Vector3.new(x, 60, z), Vector3.new(0, -120, 0), params)
		if hit and hit.Instance.Transparency < 0.9 and hit.Position.Y <= baseTop + 0.2 then
			return hit.Position.Y
		end
		return baseTop
	end

	local function catmullRom(p0, p1, p2, p3, t)
		local t2, t3 = t * t, t * t * t
		return 0.5 * (
			(2 * p1)
			+ (-p0 + p2) * t
			+ (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2
			+ (-p0 + 3 * p1 - 3 * p2 + p3) * t3
		)
	end

	local function pointAt(i)
		return ptsXZ[math.clamp(i, 1, #ptsXZ)]
	end

	local samples = {}
	local dens = 28
	for seg = 1, #ptsXZ - 1 do
		local p0, p1, p2, p3 = pointAt(seg - 1), pointAt(seg), pointAt(seg + 1), pointAt(seg + 2)
		for s = 0, dens - 1 do
			local flat = catmullRom(p0, p1, p2, p3, s / dens)
			table.insert(samples, Vector3.new(flat.X, 0, flat.Z))
		end
	end
	table.insert(samples, ptsXZ[#ptsXZ])

	local cum, lens = { 0 }, {}
	local totalLen = 0
	for i = 1, #samples - 1 do
		lens[i] = (samples[i + 1] - samples[i]).Magnitude
		totalLen += lens[i]
		cum[i + 1] = totalLen
	end

	local function samplePath(t)
		t = math.clamp(t, 0, 1)
		local d = t * totalLen
		local idx = 1
		for i = 1, #lens do
			if d <= cum[i + 1] or i == #lens then
				idx = i
				break
			end
		end
		local segLen = lens[idx]
		local u = if segLen > 1e-4 then math.clamp((d - cum[idx]) / segLen, 0, 1) else 0
		local a, b = samples[idx], samples[idx + 1] or samples[idx]
		local flat = a:Lerp(b, u)
		local dir = b - a
		if dir.Magnitude < 1e-3 then
			dir = a - samples[math.max(1, idx - 1)]
		end
		dir = Vector3.new(dir.X, 0, dir.Z)
		if dir.Magnitude < 1e-3 then dir = Vector3.new(1, 0, 0) end
		local y = groundY(flat.X, flat.Z) + THICK * 0.5
		return Vector3.new(flat.X, y, flat.Z), dir.Unit
	end

	local nSeg = math.max(28, math.floor(totalLen / SEG_LEN))
	local halfAsphalt = ASPHALT_W * 0.5

	for i = 0, nSeg - 1 do
		local t0, t1 = i / nSeg, (i + 1) / nSeg
		local tm = (t0 + t1) * 0.5
		local pos, dir = samplePath(tm)
		local pA = samplePath(t0)
		local pB = samplePath(t1)
		local segLen = Vector3.new(pB.X - pA.X, 0, pB.Z - pA.Z).Magnitude + 0.4
		local cf = CFrame.lookAt(pos, pos + dir) * CFrame.Angles(0, math.rad(90), 0)

		-- single uniform asphalt deck (two lanes) — no alternating colors
		part({
			Name = "Asphalt",
			Size = Vector3.new(ASPHALT_W, THICK, segLen),
			CFrame = cf,
			Color = ASPHALT,
			Material = Enum.Material.SmoothPlastic,
		})

		-- double yellow center (Anime Road style)
		for _, xOff in ipairs({ -0.22, 0.22 }) do
			part({
				Name = "CenterYellow",
				Size = Vector3.new(0.22, 0.06, segLen),
				CFrame = cf * CFrame.new(xOff, THICK * 0.5 + 0.02, 0),
				Color = YELLOW,
				Material = Enum.Material.SmoothPlastic,
				CanCollide = false,
			})
		end

		-- white lane edge lines
		for _, side in ipairs({ -1, 1 }) do
			part({
				Name = "EdgeLine",
				Size = Vector3.new(0.28, 0.05, segLen),
				CFrame = cf * CFrame.new(side * (halfAsphalt - 0.35), THICK * 0.5 + 0.02, 0),
				Color = Color3.fromRGB(245, 245, 248),
				Material = Enum.Material.SmoothPlastic,
				CanCollide = false,
			})
			part({
				Name = "Curb",
				Size = Vector3.new(0.4, THICK * 1.15, segLen),
				CFrame = cf * CFrame.new(side * (halfAsphalt + 0.25), 0.03, 0),
				Color = CURB,
				Material = Enum.Material.SmoothPlastic,
				CanCollide = false,
			})
			part({
				Name = "Sidewalk",
				Size = Vector3.new(SIDEWALK_W, THICK * 0.85, segLen),
				CFrame = cf * CFrame.new(side * (halfAsphalt + 0.45 + SIDEWALK_W * 0.5), 0.06, 0),
				Color = SIDEWALK,
				Material = Enum.Material.SmoothPlastic,
				CanCollide = false,
			})
			part({
				Name = "Shoulder",
				Size = Vector3.new(1.45, THICK * 0.45, segLen),
				CFrame = cf * CFrame.new(side * (halfAsphalt + 0.45 + SIDEWALK_W + 0.8), 0.05, 0),
				Color = GRASS,
				Material = Enum.Material.Ground, -- Ground: green look without Grass Part shimmer
				CanCollide = false,
			})
		end
	end

	local yHaven = groundY(-25, 70) + THICK * 0.5
	local yArena = groundY(116, 40) + THICK * 0.5
	part({ Name = "HavenCap", Size = Vector3.new(ASPHALT_W + SIDEWALK_W * 2, THICK, 7), Position = Vector3.new(-25, yHaven, 70), Color = ASPHALT })
	part({ Name = "ArenaCap", Size = Vector3.new(ASPHALT_W + SIDEWALK_W * 2, THICK, 8), Position = Vector3.new(116, yArena, 40), Color = ASPHALT })

	-- StreetLamps along Haven road removed

	local function waySign(name, t, label)
		local pos, dir = samplePath(t)
		local right = Vector3.new(-dir.Z, 0, dir.X)
		local base = pos + right * (halfAsphalt + SIDEWALK_W * 0.7)
		local pole = part({
			Name = name .. "Pole",
			Size = Vector3.new(0.28, 4.2, 0.28),
			Position = base + Vector3.new(0, 2.0, 0),
			Color = Color3.fromRGB(50, 52, 62),
			Material = Enum.Material.Metal,
			CanCollide = false,
		})
		local board = part({
			Name = name .. "Board",
			Size = Vector3.new(5.5, 1.6, 0.25),
			CFrame = CFrame.lookAt(pole.Position + Vector3.new(0, 2.5, 0) + dir * 0.2, pole.Position + Vector3.new(0, 2.5, 0) + dir),
			Color = Color3.fromRGB(35, 40, 55),
			Material = Enum.Material.SmoothPlastic,
			CanCollide = false,
		})
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		gui.Parent = board
		local text = Instance.new("TextLabel")
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.Text = label
		text.TextColor3 = Color3.fromRGB(255, 230, 160)
		text.Font = Enum.Font.GothamBold
		text.TextScaled = true
		text.Parent = gui
	end
	waySign("SignHaven", 0.08, "← Haven")
	waySign("SignArena", 0.55, "Арена → дуэль · Y")
	waySign("SignArenaNear", 0.92, "Дуэль · Y у плиток")

	model:SetAttribute("From", "OtakuHavenExit")
	model:SetAttribute("To", "BattleArenaEntrance")
	model:SetAttribute("Style", "AnimeTwoLane")
	model:SetAttribute("RefAssetId", 10235862952)
	model:SetAttribute("RefName", "Anime Road")
	return model
end

return OtakuHavenBuilder
