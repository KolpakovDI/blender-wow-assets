-- ResonanceTemperService: Temper pedestal (build once; live prompts; same pattern as Care)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local realm = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local ResonanceEvent = realm:WaitForChild("ResonanceEvent")

local PEDESTAL_NAME = "ResonanceTemperPedestal"
local PROMPT_NAME = "TemperPrompt"

local builtOnce = false
local lastOpen = {}

local function openTemper(player)
	if not player then return end
	local uid = player.UserId
	local now = os.clock()
	if lastOpen[uid] and (now - lastOpen[uid]) < 0.8 then return end
	lastOpen[uid] = now
	print("[TemperPedestal] Open picker for", player.Name)
	ResonanceEvent:FireClient(player, "OpenTemperPicker", {})
end

local function buildPedestal()
	local qm = workspace:FindFirstChild("QuestMaster")
	if not qm then return false end

	local existing = workspace:FindFirstChild(PEDESTAL_NAME)
	if existing then existing:Destroy() end

	local pivot = qm:GetPivot().Position
	local pos = Vector3.new(pivot.X - 22, 0.55, pivot.Z + 14)

	local model = Instance.new("Model")
	model.Name = PEDESTAL_NAME

	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(4, 0.6, 4)
	base.Anchored = true
	base.CanCollide = true
	base.Material = Enum.Material.SmoothPlastic
	base.Color = Color3.fromRGB(40, 48, 72)
	base.CFrame = CFrame.new(pos)
	base.Parent = model

	local anvil = Instance.new("Part")
	anvil.Name = "Anvil"
	anvil.Size = Vector3.new(2.2, 1.2, 1.4)
	anvil.Anchored = true
	anvil.CanCollide = false
	anvil.CanQuery = false
	anvil.Material = Enum.Material.Metal
	anvil.Color = Color3.fromRGB(90, 110, 160)
	anvil.CFrame = CFrame.new(pos + Vector3.new(0, 0.85, 0))
	anvil.Parent = model

	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(120, 170, 255)
	glow.Brightness = 1.4
	glow.Range = 10
	glow.Parent = anvil

	local bill = Instance.new("BillboardGui")
	bill.Name = "TemperLabel"
	bill.Size = UDim2.fromOffset(160, 40)
	bill.StudsOffset = Vector3.new(0, 2.4, 0)
	bill.AlwaysOnTop = true
	bill.Parent = base
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "Закалка · клик или E"
	label.TextColor3 = Color3.fromRGB(180, 210, 255)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 16
	label.TextStrokeTransparency = 0.3
	label.Parent = bill

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = PROMPT_NAME
	prompt.ActionText = "Закалка"
	prompt.ObjectText = "Пьедестал temper"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Enabled = true
	prompt.Parent = base
	prompt.Triggered:Connect(function(player)
		openTemper(player)
	end)

	local cd = Instance.new("ClickDetector")
	cd.Name = "TemperClick"
	cd.MaxActivationDistance = 14
	cd.Parent = base
	cd.MouseClick:Connect(function(player)
		openTemper(player)
	end)

	model.PrimaryPart = base
	model.Parent = workspace
	builtOnce = true
	print("[TemperPedestal] Ready at", pos)
	return true
end

local function tryBuild()
	if workspace:FindFirstChild(PEDESTAL_NAME) and builtOnce then
		return
	end
	buildPedestal()
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
