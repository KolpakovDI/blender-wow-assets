-- ZoneController - client feedback for Otaku Haven zones
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local RealmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local zoneChanged = RealmFolder:WaitForChild("ZoneChanged")

local gui = Instance.new("ScreenGui")
gui.Name = "ZoneUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local banner = Instance.new("TextLabel")
banner.Name = "ZoneBanner"
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 12)
banner.Size = UDim2.new(0, 420, 0, 36)
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
toast.Size = UDim2.new(0, 360, 0, 32)
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

zoneChanged.OnClientEvent:Connect(function(zoneType, detail)
	detail = detail or zoneType
	local msg = MESSAGES[detail] or MESSAGES[zoneType]
	if not msg then return end

	if zoneType == "Combat" then
		showBanner("Акихабара", Color3.fromRGB(255, 180, 80))
		showToast("Музыка: Lo-Fi → J-Rock", 3)
	elseif zoneType == "Safe" and detail ~= "Spawn" then
		showBanner("Otaku Haven", Color3.fromRGB(255, 180, 220))
		if detail == "Genkan" then
			ringEntranceBell(false)
			showToast("Колокольчик — иррасшаймасе!  ·  " .. MESSAGES.Genkan, 3)
		elseif detail == "Exit" then
			showToast(MESSAGES.Exit, 2.5)
		end
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

	-- широкий триггер в зоне входа (колокольчик сам слишком высоко)
	local trigger = haven:FindFirstChild("BellTrigger", true)
	if not trigger then
		trigger = Instance.new("Part")
		trigger.Name = "BellTrigger"
		trigger.Size = Vector3.new(10, 8, 6)
		trigger.Position = Vector3.new(0, 4, 22)
		trigger.Anchored = true
		trigger.CanCollide = false
		trigger.CanTouch = true
		trigger.CanQuery = false
		trigger.Transparency = 1
		trigger.Parent = haven:FindFirstChild("Decor") or haven
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
