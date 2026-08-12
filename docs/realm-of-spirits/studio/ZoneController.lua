-- ZoneController - client feedback for Otaku Haven zones
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local RealmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local zoneChanged = RealmFolder:WaitForChild("ZoneChanged")
local ZoneConfig = require(RealmFolder:WaitForChild("ZoneConfig"))
local ToastRouter = require(RealmFolder:WaitForChild("ToastRouter"))

local hubIntroShown = false
local prepHintShown = false
local elementCycleHintShown = false

local gui = Instance.new("ScreenGui")
gui.Name = "ZoneUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 150
gui.Parent = player:WaitForChild("PlayerGui")

local banner = Instance.new("TextLabel")
banner.Name = "ZoneBanner"
banner.AnchorPoint = Vector2.new(0.5, 0.5)
banner.Position = UDim2.new(0.5, 0, 0.22, 0)
banner.Size = UDim2.new(0, 420, 0, 56)
banner.BackgroundColor3 = Color3.fromRGB(18, 16, 28)
banner.BackgroundTransparency = 0.2
banner.TextColor3 = Color3.fromRGB(255, 235, 245)
banner.Text = ""
banner.TextSize = 28
banner.Font = Enum.Font.GothamBold
banner.Visible = false
banner.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = banner

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(255, 180, 220)
stroke.Thickness = 1.5
stroke.Transparency = 0.35
stroke.Parent = banner

local toast = Instance.new("TextLabel")
toast.Name = "ZoneToast"
toast.AnchorPoint = Vector2.new(0.5, 1)
toast.Position = UDim2.new(0.5, 0, 1, -80)
toast.Size = UDim2.new(0, 520, 0, 36)
toast.TextWrapped = true
toast.BackgroundTransparency = 1
toast.TextColor3 = Color3.fromRGB(200, 255, 220)
toast.Text = ""
toast.TextSize = 16
toast.Font = Enum.Font.Gotham
toast.Visible = false
toast.Parent = gui

local bannerToken = 0
local ZONE_TITLE_DURATION = 1.5

local function showZoneTitle(text, color)
	if not text or text == "" then
		return
	end
	bannerToken += 1
	local token = bannerToken
	banner.Text = text
	banner.TextColor3 = color or Color3.fromRGB(255, 235, 245)
	banner.TextTransparency = 0
	banner.BackgroundTransparency = 0.2
	stroke.Transparency = 0.35
	banner.Visible = true
	task.delay(ZONE_TITLE_DURATION, function()
		if token ~= bannerToken then
			return
		end
		local fade = TweenService:Create(banner, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = 1,
			BackgroundTransparency = 1,
		})
		local fadeStroke = TweenService:Create(stroke, TweenInfo.new(0.35), { Transparency = 1 })
		fade:Play()
		fadeStroke:Play()
		fade.Completed:Connect(function()
			if token == bannerToken then
				banner.Visible = false
			end
		end)
	end)
end

-- legacy alias
local function showBanner(text, color)
	showZoneTitle(text, color)
end

local function showToast(text, duration)
	-- Tip priority; shares queue with battle/loot notifications (UI package A)
	ToastRouter.Tip(text, duration or 2.5)
end

local MESSAGES = {
	Genkan = "Генкан: надеты домашние тапочки",
	Safe = "Otaku Haven — Safe Zone",
	Exit = "Выход в боевую зону: Акихабара",
	Combat = "Акихабара — Combat Zone",
	Akihabara = "Акихабара — Combat Zone",
	MistPond = "Прибрежное море — Водный Карп",
	FrostRidge = "Морозный хребет — Ледяная Птица",
	ShadowHollow = "Теневая лощина — Теневой Пёс",
	StormSpire = "Грозовой шпиль — Грозовой Дракон",
	DawnMeadow = "Луг рассвета — Световой Единорог",
	StoneBasin = "Каменный бассейн — Каменный Голем",
	AshGarden = "Пепельный сад — Пепельный Саламандр",
	GaleCliff = "Ветряной утёс — Ветряной Лис",
	MossGlade = "Моховая поляна — Моховой Олень",
	Moonwell = "Лунный колодец — Лунный Кролик",
	VenomHollow = "Ядовитое ущелье — Ядовитая Гадюка",
	SandDunes = "Песчаные дюны — [архив] Пустынный Скорпион",
	IronWastes = "Железные пустоши — Стальной Жук",
	CrystalCaves = "Кристальные пещеры — [архив] Хрустальный Лис",
	MagmaFissure = "Лавовый разлом — Лавовый Краб",
	FogBasin = "Туманная низина — Туманный Дух",
	SkyRidge = "Небесный хребет — Небесный Сокол",
}

local HABITAT_BANNERS = {
	MistPond = {Title = "Прибрежное море", Color = Color3.fromRGB(80, 160, 220)},
	FrostRidge = {Title = "Морозный хребет", Color = Color3.fromRGB(140, 210, 255)},
	ShadowHollow = {Title = "Теневая лощина", Color = Color3.fromRGB(140, 90, 200)},
	StormSpire = {Title = "Грозовой шпиль", Color = Color3.fromRGB(230, 220, 100)},
	DawnMeadow = {Title = "Луг рассвета", Color = Color3.fromRGB(255, 240, 180)},
	StoneBasin = {Title = "Каменный бассейн", Color = Color3.fromRGB(180, 140, 90)},
	AshGarden = {Title = "Пепельный сад", Color = Color3.fromRGB(255, 100, 40)},
	GaleCliff = {Title = "Ветряной утёс", Color = Color3.fromRGB(120, 200, 180)},
	MossGlade = {Title = "Моховая поляна", Color = Color3.fromRGB(80, 160, 70)},
	Moonwell = {Title = "Лунный колодец", Color = Color3.fromRGB(180, 195, 255)},
	VenomHollow = {Title = "Ядовитое ущелье", Color = Color3.fromRGB(90, 180, 60)},
	SandDunes = {Title = "Песчаные дюны (архив)", Color = Color3.fromRGB(210, 170, 90)},
	IronWastes = {Title = "Железные пустоши", Color = Color3.fromRGB(140, 155, 175)},
	CrystalCaves = {Title = "Кристальные пещеры (архив)", Color = Color3.fromRGB(180, 220, 255)},
	MagmaFissure = {Title = "Лавовый разлом", Color = Color3.fromRGB(255, 90, 40)},
	FogBasin = {Title = "Туманная низина", Color = Color3.fromRGB(160, 190, 220)},
	SkyRidge = {Title = "Небесный хребет", Color = Color3.fromRGB(180, 210, 255)},
}

local SLIPPER_COLOR = Color3.fromRGB(255, 170, 200)
local SLIPPER_SOLE = Color3.fromRGB(245, 245, 250)
local wearingSlippers = false

local function restoreHiddenShoes(character)
	if not character then return end
	for _, d in ipairs(character:GetDescendants()) do
		if d:IsA("BasePart") then
			local prev = d:GetAttribute("GenkanPrevTransparency")
			if typeof(prev) == "number" then
				d.Transparency = prev
				d:SetAttribute("GenkanPrevTransparency", nil)
			end
		end
	end
end

local function hideOutdoorShoes(character)
	if not character then return end
	for _, d in ipairs(character:GetDescendants()) do
		local hide = false
		if d:IsA("Accessory") then
			local n = string.lower(d.Name)
			if string.find(n, "shoe", 1, true)
				or string.find(n, "boot", 1, true)
				or string.find(n, "sneaker", 1, true)
				or string.find(n, "sandal", 1, true)
				or string.find(n, "foot", 1, true)
			then
				hide = true
			end
		end
		if hide then
			for _, p in ipairs(d:GetDescendants()) do
				if p:IsA("BasePart") and p:GetAttribute("GenkanPrevTransparency") == nil then
					p:SetAttribute("GenkanPrevTransparency", p.Transparency)
					p.Transparency = 1
				end
			end
		end
	end
	-- слегка прячем стопы R15 под тапочками
	for _, footName in ipairs({ "LeftFoot", "RightFoot" }) do
		local foot = character:FindFirstChild(footName)
		if foot and foot:IsA("BasePart") and foot:GetAttribute("GenkanPrevTransparency") == nil then
			foot:SetAttribute("GenkanPrevTransparency", foot.Transparency)
			foot.Transparency = math.max(foot.Transparency, 0.35)
		end
	end
end

local function clearSlippers(character)
	if not character then return end
	local folder = character:FindFirstChild("GenkanSlippers")
	if folder then
		folder:Destroy()
	end
	restoreHiddenShoes(character)
	wearingSlippers = false
end

local function makeSlipperPart(folder, foot, name, size, offset, color)
	local slipper = Instance.new("Part")
	slipper.Name = name
	slipper.Size = size
	slipper.Color = color
	slipper.Material = Enum.Material.Fabric
	slipper.CanCollide = false
	slipper.CanQuery = false
	slipper.CanTouch = false
	slipper.Massless = true
	slipper.CastShadow = false
	slipper.CFrame = foot.CFrame * offset
	slipper.Parent = folder
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = foot
	weld.Part1 = slipper
	weld.Parent = slipper
	return slipper
end

local function attachSlipper(folder, foot, name)
	if not foot or not foot:IsA("BasePart") then return end
	local w = math.max(0.75, foot.Size.X * 1.1)
	local d = math.max(1.15, foot.Size.Z * 1.35)
	-- подошва
	makeSlipperPart(
		folder,
		foot,
		name .. "Sole",
		Vector3.new(w, 0.16, d),
		CFrame.new(0, -foot.Size.Y * 0.5 - 0.06, 0.1),
		SLIPPER_SOLE
	)
	-- верх тапочка
	makeSlipperPart(
		folder,
		foot,
		name .. "Upper",
		Vector3.new(w * 0.92, 0.22, d * 0.72),
		CFrame.new(0, -foot.Size.Y * 0.5 + 0.08, 0.02),
		SLIPPER_COLOR
	)
	-- ремешок
	makeSlipperPart(
		folder,
		foot,
		name .. "Strap",
		Vector3.new(w * 0.95, 0.08, 0.18),
		CFrame.new(0, -foot.Size.Y * 0.5 + 0.22, -0.15),
		Color3.fromRGB(230, 120, 170)
	)
end

local function applySlippers(character)
	if not character then return end
	clearSlippers(character)
	local left = character:FindFirstChild("LeftFoot") or character:FindFirstChild("Left Leg")
	local right = character:FindFirstChild("RightFoot") or character:FindFirstChild("Right Leg")
	if not left or not right then return end
	hideOutdoorShoes(character)
	local folder = Instance.new("Folder")
	folder.Name = "GenkanSlippers"
	folder.Parent = character
	attachSlipper(folder, left, "LeftSlipper")
	attachSlipper(folder, right, "RightSlipper")
	wearingSlippers = true
end

local function setIndoorFootwear(enabled)
	local character = player.Character
	if enabled then
		applySlippers(character)
	else
		clearSlippers(character)
	end
end

local function shouldWearSlippers(zone, detail)
	if zone == "Combat" then
		return false
	end
	if detail == "Exit" then
		return false
	end
	-- Spawn в Haven тоже indoor (спавн в Genkan/Safe)
	if zone == "Safe" then
		return true
	end
	if detail == "Genkan" or detail == "Safe" or detail == "Spawn" then
		return true
	end
	return false
end

local havenBellWelcomed = false
local function syncFootwearFromZone(ringBellIfEnter)
	local character = player.Character
	if not character then
		return
	end
	local zone = player:GetAttribute("CurrentZone")
	local detail = player:GetAttribute("ZoneDetail")
	local want = shouldWearSlippers(zone, detail)
	local has = character:FindFirstChild("GenkanSlippers") ~= nil
	if want and not has then
		applySlippers(character)
	elseif want and has then
		wearingSlippers = true
	elseif not want and has then
		clearSlippers(character)
		havenBellWelcomed = false
	end
end

player.CharacterAdded:Connect(function(character)
	task.wait(0.35)
	syncFootwearFromZone(false)
	task.delay(1, function()
		if player.Character == character then
			syncFootwearFromZone(true)
		end
	end)
end)

player:GetAttributeChangedSignal("CurrentZone"):Connect(function()
	syncFootwearFromZone(true)
end)
player:GetAttributeChangedSignal("ZoneDetail"):Connect(function()
	syncFootwearFromZone(true)
end)

local bellSound = Instance.new("Sound")
bellSound.Name = "EntranceBellLocal"
bellSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
bellSound.Volume = 1.5
bellSound.RollOffMaxDistance = 1000
bellSound.Parent = gui

local bellDebounce = false
local function ringEntranceBell(showBellToast)
	if bellDebounce then return end
	bellDebounce = true
	bellSound.TimePosition = 0
	bellSound:Play()
	-- дублируем на 3D-колокольчик, если есть
	local haven = workspace:FindFirstChild("OtakuHaven")
	local bell = haven and haven:FindFirstChild("EntranceBell", true)
	local worldSnd = bell and bell:FindFirstChild("BellSound")
	if worldSnd then
		worldSnd.TimePosition = 0
		worldSnd:Play()
	end
	if showBellToast ~= false then
		showToast("Колокольчик — иррасшаймасе!", 2)
	end
	task.delay(2.5, function()
		bellDebounce = false
	end)
end

local ZONE_TITLES = {
	Genkan = { Title = "Otaku Haven", Color = Color3.fromRGB(255, 180, 220) },
	Safe = { Title = "Otaku Haven", Color = Color3.fromRGB(255, 180, 220) },
	Spawn = { Title = "Otaku Haven", Color = Color3.fromRGB(255, 180, 220) },
	Exit = { Title = "Выход в Акихабару", Color = Color3.fromRGB(255, 200, 120) },
	Combat = { Title = "Акихабара", Color = Color3.fromRGB(255, 180, 80) },
	Akihabara = { Title = "Акихабара", Color = Color3.fromRGB(255, 180, 80) },
}

local function resolveZoneTitle(zoneType, detail)
	local habitat = HABITAT_BANNERS[detail]
	if habitat then
		return habitat.Title, habitat.Color
	end
	local z = ZONE_TITLES[detail] or ZONE_TITLES[zoneType]
	if z then
		return z.Title, z.Color
	end
	return nil, nil
end

local function showHubIntro()
	if hubIntroShown then return end
	hubIntroShown = true
	showZoneTitle("Otaku Haven", Color3.fromRGB(255, 180, 220))
	showToast("Мика у входа -> магазин (генкан) -> Выход в Акихабару", 5)
end

zoneChanged.OnClientEvent:Connect(function(zoneType, detail)
	detail = detail or zoneType

	if detail == "Spawn" then
		showHubIntro()
		syncFootwearFromZone(false)
		return
	end

	local title, color = resolveZoneTitle(zoneType, detail)
	if title then
		showZoneTitle(title, color)
	end

	if zoneType == "Combat" then
		syncFootwearFromZone(false)
		if not elementCycleHintShown then
			elementCycleHintShown = true
			task.delay(1.6, function()
				showToast("Огонь→Земля→Ветер→Вода→Огонь · ×1.5 / ×0.7", 3.5)
			end)
		end
	elseif zoneType == "Safe" then
		if detail == "Genkan" then
			syncFootwearFromZone(false)
			if not havenBellWelcomed then
				havenBellWelcomed = true
				ringEntranceBell(false)
			end
		elseif detail == "Exit" then
			syncFootwearFromZone(false)
			showToast("Снаружи: огонь / лёд / манга / сундук (E) — разный лут", 4)
		elseif detail == "Safe" then
			syncFootwearFromZone(true)
			if not prepHintShown then
				prepHintShown = true
				task.delay(1.6, function()
					showToast("Подготовка: манга «Путь Меча» или примерочная", 3.5)
				end)
			end
		end
	end
end)

task.defer(function()
	if (player:GetAttribute("ZoneDetail") or "Spawn") == "Spawn" then
		showHubIntro()
	end
end)

task.spawn(function()
	local haven = workspace:WaitForChild("OtakuHaven", 30)
	if not haven then return end

	local bell = haven:FindFirstChild("EntranceBell", true)
	if bell then
		local snd = bell:FindFirstChild("BellSound")
		if not snd then
			snd = Instance.new("Sound")
			snd.Name = "BellSound"
			snd.SoundId = "rbxasset://sounds/electronicpingshort.wav"
			snd.Volume = 1.5
			snd.Parent = bell
		end
		snd.Volume = 1.5
	end

	-- триггер колокольчика = объём генкана (не хардкод world pos)
	local genkan = ZoneConfig.Zones and ZoneConfig.Zones.Genkan
	local trigger = haven:FindFirstChild("BellTrigger", true)
	if not trigger then
		trigger = Instance.new("Part")
		trigger.Name = "BellTrigger"
		trigger.Anchored = true
		trigger.CanCollide = false
		trigger.CanTouch = true
		trigger.CanQuery = false
		trigger.Transparency = 1
		trigger.Parent = haven:FindFirstChild("Decor") or haven
	end
	if genkan then
		trigger.Size = Vector3.new(math.max(10, genkan.Size.X), 8, math.max(6, genkan.Size.Z))
		trigger.Position = genkan.Center + Vector3.new(0, 1, 0)
	end

	local function onBellTouch(hit)
		if not hit or not hit:IsA("BasePart") then return end
		local character = player.Character
		if not character then return end
		if hit:IsDescendantOf(character) then
			ringEntranceBell(true)
		end
	end

	trigger.Touched:Connect(onBellTouch)
	if bell then
		local bellPart = bell:IsA("BasePart") and bell
			or (bell:IsA("Model") and (bell.PrimaryPart or bell:FindFirstChildWhichIsA("BasePart", true)))
		if bellPart then
			bellPart.Touched:Connect(onBellTouch)
		end
	end

	-- лёгкое мерцание LED/PointLight витрин
	for _, light in ipairs(haven:GetDescendants()) do
		if light:IsA("PointLight") then
			local base = light.Brightness
			task.spawn(function()
				while light.Parent do
					light.Brightness = base * (0.75 + 0.35 * math.noise(os.clock() * 0.7, 0))
					task.wait(0.12)
				end
			end)
		end
	end
end)

task.defer(function()
	task.wait(0.5)
	syncFootwearFromZone(false)
	local zone = player:GetAttribute("CurrentZone")
	local detail = player:GetAttribute("ZoneDetail")
	if shouldWearSlippers(zone, detail) and not havenBellWelcomed then
		havenBellWelcomed = true
		ringEntranceBell(true)
	end
	task.wait(1.5)
	syncFootwearFromZone(false)
end)

print("Realm of Spirits - ZoneController loaded!")
