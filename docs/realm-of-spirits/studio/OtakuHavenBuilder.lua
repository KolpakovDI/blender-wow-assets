-- OtakuHavenBuilder - Safe Zone hub (GDD v2.0)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local RealmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local ZoneConfig = require(RealmFolder:WaitForChild("ZoneConfig"))

local OtakuHavenBuilder = {}

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
		CanQuery = false,
		Color = Color3.fromRGB(170, 120, 255),
		Parent = parent,
	})
	z:SetAttribute("ZoneType", zoneType)
	return z
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
	light.Brightness = 2
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
				Brightness = 1.2 + math.random() * 1.5,
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
	pl.Brightness = 1.5
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
			pl.Brightness = 1 + math.random() * 1.2
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

	local bb = Instance.new("BillboardGui")
	bb.Name = "FomoBillboard"
	bb.Size = UDim2.new(0, 180, 0, 40)
	bb.StudsOffset = Vector3.new(0, 3.2, 0)
	bb.AlwaysOnTop = true
	bb.Parent = g
	local label = Instance.new("TextLabel")
	label.Name = "FomoLabel"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(40, 20, 50)
	label.BackgroundTransparency = 0.25
	label.TextColor3 = Color3.fromRGB(255, 180, 220)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.Text = "Лимит: 2:00:00"
	label.Parent = bb
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = label
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
	prompt.ActionText = "Магазин / Трейд"
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Enabled = true
	prompt.Parent = room
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

	local bb = Instance.new("BillboardGui")
	bb.Name = "MangaHint"
	bb.Size = UDim2.new(0, 260, 0, 70)
	bb.StudsOffset = Vector3.new(0, 5.2, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 60
	bb.Parent = shelf
	local hint = Instance.new("TextLabel")
	hint.Size = UDim2.fromScale(1, 1)
	hint.BackgroundColor3 = Color3.fromRGB(40, 25, 60)
	hint.BackgroundTransparency = 0.1
	hint.TextColor3 = Color3.fromRGB(255, 230, 180)
	hint.Font = Enum.Font.GothamBold
	hint.TextSize = 16
	hint.Text = "Читай мангу «Путь Меча»\nПодойди сюда → нажми E\nБафф: +15% урона на 30 мин"
	hint.TextWrapped = true
	hint.Parent = bb
	local hc = Instance.new("UICorner")
	hc.CornerRadius = UDim.new(0, 8)
	hc.Parent = hint

	local mat = bookPart({
		Name = "MangaFloorArrow",
		Size = Vector3.new(3.5, 0.12, 3.5),
		Position = Vector3.new(position.X, 1.08, position.Z - 2.5),
		Color = Color3.fromRGB(160, 80, 220),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = model,
	})
	local matGui = Instance.new("SurfaceGui")
	matGui.Face = Enum.NormalId.Top
	matGui.Parent = mat
	local matLbl = Instance.new("TextLabel")
	matLbl.Size = UDim2.fromScale(1, 1)
	matLbl.BackgroundTransparency = 1
	matLbl.Text = "МАНГА"
	matLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	matLbl.TextScaled = true
	matLbl.Font = Enum.Font.GothamBold
	matLbl.Parent = matGui

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

	if billboardText then
		local sign = Instance.new("BillboardGui")
		sign.Size = UDim2.new(0, 200, 0, 40)
		sign.StudsOffset = Vector3.new(0, 5.5, 0)
		sign.AlwaysOnTop = true
		sign.Parent = sensor
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundTransparency = 1
		lbl.Text = billboardText
		lbl.TextColor3 = Color3.fromRGB(255, 220, 100)
		lbl.TextScaled = true
		lbl.Font = Enum.Font.GothamBold
		lbl.Parent = sign
	end

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
	local doorW = 6
	local panelW = (38 - doorW) / 2 -- 16 each side
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
	local floorY = 1.0

	makePart({
		Name = "Floor",
		Size = Vector3.new(38, 1, 38),
		Position = center + Vector3.new(0, floorY, 0),
		Color = Color3.fromRGB(255, 245, 235),
		Material = Enum.Material.WoodPlanks,
		Parent = haven,
	})

	local wallH, wallT = 10, 1
	local half = 19
	-- фасад (юг): стекло + раздвижная дверь вместо глухой WallBack
	addGlassFacadeAndSlidingDoor(haven, center, half, wallH)
	makePart({ Name = "WallLeft", Size = Vector3.new(wallT, wallH, 38), Position = center + Vector3.new(-half, wallH / 2, 0), Color = Color3.fromRGB(230, 210, 255), Parent = haven })
	makePart({ Name = "WallRight", Size = Vector3.new(wallT, wallH, 38), Position = center + Vector3.new(half, wallH / 2, 0), Color = Color3.fromRGB(230, 210, 255), Parent = haven })

	-- стенка напротив стеклянной витрины (север), с проёмом на выход в Акихабару
	do
		local backZ = center.Z + half
		local exitW = 10
		local panelW = (38 - exitW) / 2
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

	makePart({
		Name = "Counter",
		Size = Vector3.new(10, 3.2, 2.5),
		Position = ZoneConfig.CounterPosition + Vector3.new(0, 2.1, 0),
		Color = Color3.fromRGB(139, 90, 60),
		Material = Enum.Material.Wood,
		Parent = haven,
	})

	makePart({
		Name = "GenkanMat",
		Size = Vector3.new(8, 0.15, 4),
		Position = ZoneConfig.Zones.Genkan.Center + Vector3.new(0, 1.08, 0),
		Color = Color3.fromRGB(180, 140, 100),
		Parent = decor,
	})

	local bell = makePart({
		Name = "EntranceBell",
		Size = Vector3.new(0.8, 0.8, 0.8),
		Position = ZoneConfig.Zones.Genkan.Center + Vector3.new(3.5, 4, -1),
		Color = Color3.fromRGB(255, 210, 80),
		Material = Enum.Material.Metal,
		Parent = decor,
	})
	bell:SetAttribute("RingOnTouch", true)
	local bellTrigger = makePart({
		Name = "BellTrigger",
		Size = Vector3.new(10, 8, 6),
		Position = Vector3.new(center.X, 4, center.Z - 13),
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

	addNeonSign(haven, center + Vector3.new(0, 9, -14))
	addLEDDisplay(decor, center + Vector3.new(-12, 5, -8), "NEW\nSPIRITS")
	addLEDDisplay(decor, center + Vector3.new(12, 5, -8), "LO-FI\nON")
	addPoster(decor, center + Vector3.new(-17, 5, -5), Color3.fromRGB(255, 100, 150))
	addPoster(decor, center + Vector3.new(17, 5, -5), Color3.fromRGB(100, 180, 255))
	addStandee(decor, center + Vector3.new(-10, 3.5, 10))
	addGacha(decor, center + Vector3.new(14, 3, 8))
	addMangaBuff(decor, center + Vector3.new(-14, 2.5, 8))
	addFittingRoom(decor, center + Vector3.new(8, 3.5, -6))
	addSlidingGlassDoor(haven, {
		CenterX = center.X,
		FacadeZ = center.Z + half,
		WallH = wallH,
		DoorW = 10,
		Slide = 5.2,
		ModelName = "ShopExit",
		ObjectText = "Выход в Акихабару",
		BillboardText = "-> Akihabara",
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
	local signPart = makePart({
		Name = "ZoneSign",
		Size = Vector3.new(12, 1, 12),
		Position = combat.Center + Vector3.new(0, 0.5, -50),
		Color = Color3.fromRGB(80, 80, 100),
		Parent = akihabara,
	})
	local bg = Instance.new("BillboardGui")
	bg.Size = UDim2.new(0, 180, 0, 40)
	bg.StudsOffset = Vector3.new(0, 3, 0)
	bg.Parent = signPart
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = "Akihabara - Combat Zone"
	t.TextColor3 = Color3.fromRGB(255, 200, 80)
	t.TextScaled = true
	t.Font = Enum.Font.GothamBold
	t.Parent = bg

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

	return haven
end

return OtakuHavenBuilder
