-- ZoneController - client feedback for Otaku Haven zones
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local RealmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local zoneChanged = RealmFolder:WaitForChild("ZoneChanged")
local ZoneConfig = require(RealmFolder:WaitForChild("ZoneConfig"))

local hubIntroShown = false
local prepHintShown = false

local gui = Instance.new("ScreenGui")
gui.Name = "ZoneUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local banner = Instance.new("TextLabel")
banner.Name = "ZoneBanner"
banner.AnchorPoint = Vector2.new(1, 0)
banner.Position = UDim2.new(1, -16, 0, 12)
banner.Size = UDim2.new(0, 220, 0, 32)
banner.BackgroundColor3 = Color3.fromRGB(30, 25, 40)
banner.BackgroundTransparency = 0.25
banner.TextColor3 = Color3.fromRGB(255, 220, 240)
banner.Text = ""
banner.TextSize = 18
banner.Font = Enum.Font.GothamMedium
banner.Visible = false
banner.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = banner

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

local function showBanner(text, color)
	banner.Text = text
	banner.TextColor3 = color or Color3.fromRGB(255, 220, 240)
	banner.Visible = true
	banner.BackgroundTransparency = 0.25
	local tween = TweenService:Create(banner, TweenInfo.new(2.5), { BackgroundTransparency = 0.6 })
	tween:Play()
end

local function showToast(text, duration)
	toast.Text = text
	toast.Visible = true
	task.delay(duration or 2.5, function()
		if toast.Text == text then
			toast.Visible = false
		end
	end)
end

local MESSAGES = {
	Genkan = "Генкан: надеты домашние тапочки",
	Safe = "Otaku Haven — Safe Zone",
	Exit = "Выход в боевую зону: Акихабара",
	Combat = "Акихабара — Combat Zone",
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

player.CharacterAdded:Connect(function(character)
	task.wait(0.3)
	local zone = player:GetAttribute("CurrentZone")
	local detail = player:GetAttribute("ZoneDetail")
	if zone == "Safe" and detail ~= "Exit" and detail ~= "Spawn" then
		applySlippers(character)
	elseif detail == "Genkan" then
		applySlippers(character)
	end
end)

local bellSound = Instance.new("Sound")
bellSound.Name = "EntranceBellLocal"
bellSound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
bellSound.Volume = 1
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

local function showHubIntro()
	if hubIntroShown then return end
	hubIntroShown = true
	showBanner("Otaku Haven", Color3.fromRGB(255, 180, 220))
	showToast("Поговори с Микой у входа, затем зайди в магазин", 4.5)
end

zoneChanged.OnClientEvent:Connect(function(zoneType, detail)
	detail = detail or zoneType
	local msg = MESSAGES[detail] or MESSAGES[zoneType]
	if not msg and detail ~= "Spawn" then return end

	if detail == "Spawn" then
		showHubIntro()
		return
	end

	if zoneType == "Combat" then
		setIndoorFootwear(false)
		showBanner("Акихабара", Color3.fromRGB(255, 180, 80))
		showToast("Музыка: Lo-Fi → J-Rock", 3)
	elseif zoneType == "Safe" then
		if detail == "Genkan" then
			showBanner("Otaku Haven", Color3.fromRGB(255, 180, 220))
			setIndoorFootwear(true)
			ringEntranceBell(false)
			showToast("Колокольчик — иррасшаймасе!  ·  " .. MESSAGES.Genkan, 3)
		elseif detail == "Exit" then
			setIndoorFootwear(false)
			showBanner(MESSAGES.Exit, Color3.fromRGB(255, 200, 120))
			showToast("Впереди боевая зона — проверь мангу и инвентарь", 3)
		elseif detail == "Safe" then
			showBanner("Otaku Haven", Color3.fromRGB(255, 180, 220))
			setIndoorFootwear(true)
			if not prepHintShown then
				prepHintShown = true
				showToast("Подготовка: манга «Путь Меча» (+урон) или примерочная", 4)
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
			snd.Volume = 1
			snd.Parent = bell
		end
		snd.Volume = 1
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
		bell.Touched:Connect(onBellTouch)
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

print("Realm of Spirits - ZoneController loaded!")
