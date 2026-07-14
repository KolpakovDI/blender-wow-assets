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
	local steps = 14
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
	local floorSize = 76
	local half = floorSize / 2
	local wallH, wallT = 11, 1

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

	addGenkanMat(decor, Vector3.new(ZoneConfig.Zones.Genkan.Center.X, 1.55, ZoneConfig.Zones.Genkan.Center.Z))

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
			d.AlwaysOnTop = false
		end
	end

	return haven
end

return OtakuHavenBuilder
