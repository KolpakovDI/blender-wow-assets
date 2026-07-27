-- ResonanceCareService: Care pedestal (rebuild once; never loop on ChildAdded)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local realm = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local ResonanceEvent = realm:WaitForChild("ResonanceEvent")
local rosServer = ServerScriptService:WaitForChild("RealmOfSpirits")

local PEDESTAL_NAME = "ResonanceCarePedestal"
local PROMPT_NAME = "CarePrompt"

local lastCareAt = {}
local builtOnce = false

local function playCareVfx(at)
	local part = Instance.new("Part")
	part.Name = "CareBurst"
	part.Size = Vector3.new(0.4, 0.4, 0.4)
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CFrame = CFrame.new(at + Vector3.new(0, 2, 0))
	part.Parent = workspace
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 200, 120)
	light.Brightness = 3
	light.Range = 14
	light.Parent = part
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 230, 160)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 140, 80)),
	})
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Lifetime = NumberRange.new(0.7, 1.1)
	emitter.Speed = NumberRange.new(2, 6)
	emitter.SpreadAngle = Vector2.new(360, 360)
	emitter.Rate = 0
	emitter.Parent = part
	emitter:Emit(28)
	TweenService:Create(light, TweenInfo.new(0.9), {Brightness = 0}):Play()
	Debris:AddItem(part, 1.2)
end

local function doCareFromPedestal(player)
	if not player then return end
	local uid = player.UserId
	local now = os.clock()
	if lastCareAt[uid] and (now - lastCareAt[uid]) < 1.0 then return end
	lastCareAt[uid] = now

	print("[CarePedestal] CARE", player.Name)
	local idx = tonumber(player:GetAttribute("ActiveSpiritIndex")) or 1
	if idx < 1 then idx = 1 end

	ResonanceEvent:FireClient(player, "RequestPedestalCare", {})

	local bf = rosServer:FindFirstChild("DoResonanceCareBF") or rosServer:WaitForChild("DoResonanceCareBF", 5)
	if bf and bf:IsA("BindableFunction") then
		local ok, result = pcall(function()
			return bf:Invoke(player, { SpiritIndex = idx, UseTreat = false, FromPedestal = true })
		end)
		print("[CarePedestal] BF", ok, result)
		if ok and result then
			local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if hrp then playCareVfx(hrp.Position) end
		end
	end
end

local function buildPedestal()
	local qm = workspace:FindFirstChild("QuestMaster")
	if not qm then return false end

	local existing = workspace:FindFirstChild(PEDESTAL_NAME)
	if existing then existing:Destroy() end

	local pivot = qm:GetPivot().Position
	local pos = Vector3.new(pivot.X + 22, 0.55, pivot.Z + 14)

	local model = Instance.new("Model")
	model.Name = PEDESTAL_NAME

	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(4, 0.6, 4)
	base.Anchored = true
	base.CanCollide = true
	base.Material = Enum.Material.SmoothPlastic
	base.Color = Color3.fromRGB(72, 52, 40)
	base.CFrame = CFrame.new(pos)
	base.Parent = model

	local bowl = Instance.new("Part")
	bowl.Name = "Bowl"
	bowl.Shape = Enum.PartType.Cylinder
	bowl.Size = Vector3.new(0.45, 2.2, 2.2)
	bowl.Anchored = true
	bowl.CanCollide = false
	bowl.CanQuery = false
	bowl.Material = Enum.Material.Neon
	bowl.Color = Color3.fromRGB(255, 180, 90)
	bowl.CFrame = CFrame.new(pos + Vector3.new(0, 0.7, 0)) * CFrame.Angles(0, 0, math.rad(90))
	bowl.Parent = model

	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 200, 120)
	glow.Brightness = 1.2
	glow.Range = 10
	glow.Parent = bowl

	local bill = Instance.new("BillboardGui")
	bill.Name = "CareLabel"
	bill.Size = UDim2.fromOffset(160, 40)
	bill.StudsOffset = Vector3.new(0, 2.4, 0)
	bill.AlwaysOnTop = true
	bill.Parent = base
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "Уход · клик или E"
	label.TextColor3 = Color3.fromRGB(255, 230, 160)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.TextStrokeTransparency = 0.3
	label.Parent = bill

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = PROMPT_NAME
	prompt.ActionText = "Уход"
	prompt.ObjectText = "Пьедестал резонанса"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Enabled = true
	prompt.Parent = base
	prompt.Triggered:Connect(function(player)
		doCareFromPedestal(player)
	end)

	local cd = Instance.new("ClickDetector")
	cd.Name = "CareClick"
	cd.MaxActivationDistance = 14
	cd.Parent = base
	cd.MouseClick:Connect(function(player)
		doCareFromPedestal(player)
	end)

	model.PrimaryPart = base
	model.Parent = workspace
	builtOnce = true
	print("[CarePedestal] Ready at", pos)
	return true
end

local function tryBuild()
	if workspace:FindFirstChild(PEDESTAL_NAME) and builtOnce then
		return
	end
	if buildPedestal() then return end
end

tryBuild()
task.spawn(function()
	for _ = 1, 20 do
		if builtOnce and workspace:FindFirstChild(PEDESTAL_NAME) then return end
		tryBuild()
		task.wait(0.5)
	end
end)

workspace.ChildAdded:Connect(function(child)
	if child.Name == "QuestMaster" then
		task.defer(function()
			builtOnce = false
			tryBuild()
		end)
	end
end)
