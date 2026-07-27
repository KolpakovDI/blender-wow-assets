-- PlayerWeaponService — меч в правой руке ТОЛЬКО в бою (Weld/Motor6D, не Tool)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")

local RealmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local MODEL_NAME = "RealmBlade"

local function weldParts(a, b, c0)
	local w = Instance.new("Weld")
	w.Part0 = a
	w.Part1 = b
	w.C0 = c0 or CFrame.new()
	w.Parent = a
	return w
end

local function createBladeModel()
	local model = Instance.new("Model")
	model.Name = MODEL_NAME

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.2, 0.2, 0.85)
	handle.Color = Color3.fromRGB(72, 42, 28)
	handle.Material = Enum.Material.Wood
	handle.Massless = true
	handle.CanCollide = false
	handle.CanQuery = false
	handle.Anchored = false
	handle.Parent = model
	model.PrimaryPart = handle

	local blade = Instance.new("Part")
	blade.Name = "Blade"
	blade.Size = Vector3.new(0.16, 0.06, 2.5)
	blade.Color = Color3.fromRGB(200, 210, 230)
	blade.Material = Enum.Material.Metal
	blade.Reflectance = 0.35
	blade.Massless = true
	blade.CanCollide = false
	blade.CanQuery = false
	blade.Parent = model
	weldParts(handle, blade, CFrame.new(0, 0, -1.5))

	local tip = Instance.new("WedgePart")
	tip.Name = "Tip"
	tip.Size = Vector3.new(0.06, 0.16, 0.32)
	tip.Color = blade.Color
	tip.Material = Enum.Material.Metal
	tip.Massless = true
	tip.CanCollide = false
	tip.CanQuery = false
	tip.Parent = model
	weldParts(handle, tip, CFrame.new(0, 0, -2.9) * CFrame.Angles(0, 0, math.rad(90)))

	local guard = Instance.new("Part")
	guard.Name = "Guard"
	guard.Size = Vector3.new(0.7, 0.1, 0.16)
	guard.Color = Color3.fromRGB(220, 170, 60)
	guard.Material = Enum.Material.Metal
	guard.Massless = true
	guard.CanCollide = false
	guard.CanQuery = false
	guard.Parent = model
	weldParts(handle, guard, CFrame.new(0, 0, -0.5))

	local pommel = Instance.new("Part")
	pommel.Name = "Pommel"
	pommel.Shape = Enum.PartType.Ball
	pommel.Size = Vector3.new(0.26, 0.26, 0.26)
	pommel.Color = Color3.fromRGB(220, 170, 60)
	pommel.Material = Enum.Material.Metal
	pommel.Massless = true
	pommel.CanCollide = false
	pommel.CanQuery = false
	pommel.Parent = model
	weldParts(handle, pommel, CFrame.new(0, 0, 0.5))

	return model
end

-- Убрать старые Tool/шаблоны из StarterPack (иначе меч появляется при спавне)
for _, child in ipairs(StarterPack:GetChildren()) do
	if child.Name == MODEL_NAME or child.Name == (MODEL_NAME .. "Template") then
		child:Destroy()
	end
end

local function prepareTemplate()
	local existing = RealmFolder:FindFirstChild(MODEL_NAME .. "Template")
	if existing then
		existing:Destroy()
	end
	local importFolder = RealmFolder:FindFirstChild("MeshImports")
	local imported = importFolder and importFolder:FindFirstChild("RealmKatana")
	local model
	if imported and imported:IsA("Model") then
		model = imported:Clone()
		model.Name = MODEL_NAME .. "Template"
		for _, c in ipairs(model:GetChildren()) do
			if c:IsA("Model") then
				for _, ch in ipairs(c:GetChildren()) do
					ch.Parent = model
				end
				c:Destroy()
			end
		end
		local handle = model:FindFirstChild("Handle", true) or model:FindFirstChild("KatanaHandle", true) or model.PrimaryPart
		if handle and handle:IsA("BasePart") then
			handle.Name = "Handle"
			model.PrimaryPart = handle
		end
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = false
				d.CanCollide = false
				d.CanQuery = false
				d.Massless = true
			end
		end
		if not (model.PrimaryPart and model:FindFirstChild("Handle", true)) then
			model:Destroy()
			model = createBladeModel()
			model.Name = MODEL_NAME .. "Template"
		end
	else
		model = createBladeModel()
		model.Name = MODEL_NAME .. "Template"
	end
	model.Parent = RealmFolder
	return model
end

local template = prepareTemplate()

-- Сабельный хват: рукоять как рукопожатие, клинок — продолжение предплечья (без залома запястья).
local function computeRestC0(hand)
	if not hand then
		return CFrame.new(0, -0.1, 0) * CFrame.Angles(math.rad(90), math.rad(90), 0)
	end
	local character = hand.Parent
	local lower = character and character:FindFirstChild("RightLowerArm")
	local grip = hand:FindFirstChild("RightGripAttachment")

	local bladeWorld
	if lower then
		local axis = hand.Position - lower.Position
		if axis.Magnitude > 0.05 then
			bladeWorld = axis.Unit
		end
	end
	if not bladeWorld then
		bladeWorld = -hand.CFrame.UpVector
	end

	local localZ = hand.CFrame:VectorToObjectSpace(bladeWorld)
	if localZ.Magnitude < 0.05 then
		localZ = Vector3.new(0, -1, 0)
	else
		localZ = localZ.Unit
	end

	local thumbWorld = hand.CFrame.RightVector
	local localDown = hand.CFrame:VectorToObjectSpace(Vector3.new(0, -1, 0))
	local localX = localDown:Cross(localZ)
	if localX.Magnitude < 0.2 then
		localX = hand.CFrame:VectorToObjectSpace(thumbWorld):Cross(localZ)
	end
	if localX.Magnitude < 0.05 then
		localX = Vector3.new(1, 0, 0)
	else
		localX = localX.Unit
	end
	local localY = localZ:Cross(localX).Unit
	localX = localY:Cross(localZ).Unit

	local pos = grip and grip.Position or Vector3.new(0, -0.08, 0)
	pos = pos + Vector3.new(0, 0.02, 0.02)
	return CFrame.fromMatrix(pos, localX, localY, localZ)
end

local REST_C0 = CFrame.new(0, -0.1, 0) * CFrame.Angles(math.rad(90), math.rad(90), 0)

local function getRightHand(character)
	return character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
end

local function stripNamedBlades(container)
	if not container then
		return
	end
	for _, c in ipairs(container:GetChildren()) do
		if c.Name == MODEL_NAME then
			c:Destroy()
		end
	end
end

local function hideBlade(player)
	if not player then
		return
	end
	local char = player.Character
	if char then
		stripNamedBlades(char)
	end
	stripNamedBlades(player:FindFirstChild("Backpack"))
	player:SetAttribute("BattleBladeEquipped", false)
end

local function showBlade(player)
	if not player then
		return nil
	end
	local character = player.Character
	if not character then
		return nil
	end
	local hand = getRightHand(character)
	if not hand then
		return nil
	end
	local existing = character:FindFirstChild(MODEL_NAME)
	if existing and existing:IsA("Model") then
		local handle = existing:FindFirstChild("Handle", true) or existing.PrimaryPart
		local motor = handle and handle:FindFirstChild("BladeMotor")
		if motor and motor:IsA("Motor6D") then
			player:SetAttribute("BattleBladeEquipped", true)
			return existing
		end
		existing:Destroy()
	end
	hideBlade(player)
	local model = template:Clone()
	model.Name = MODEL_NAME
	model.Parent = character
	local handle = model:FindFirstChild("Handle", true) or model.PrimaryPart
	if not (handle and handle:IsA("BasePart")) then
		warn("[PlayerWeaponService] RealmBlade missing Handle")
		model:Destroy()
		return nil
	end
	if handle.Name ~= "Handle" then
		handle.Name = "Handle"
	end
	model.PrimaryPart = handle
	local motor = Instance.new("Motor6D")
	motor.Name = "BladeMotor"
	motor.Part0 = hand
	motor.Part1 = handle
	motor.C0 = computeRestC0(hand)
	motor.C1 = CFrame.new()
	motor.Parent = handle
	player:SetAttribute("BattleBladeEquipped", true)
	return model
end

_G.ShowBattleBlade = showBlade
_G.HideBattleBlade = hideBlade
_G.BattleBladeRestC0 = REST_C0

local function stripOnSpawn(player)
	-- Повторно чистим: CharacterAdded / Tool / чужой код могут дать клинок с задержкой
	hideBlade(player)
	task.defer(function()
		hideBlade(player)
	end)
	task.delay(0.35, function()
		if player.Parent and not player:GetAttribute("BattleBladeEquipped") then
			hideBlade(player)
		end
	end)
	task.delay(1.0, function()
		if player.Parent and not player:GetAttribute("BattleBladeEquipped") then
			hideBlade(player)
		end
	end)
end

local function hookPlayer(player)
	player.CharacterAdded:Connect(function()
		player:SetAttribute("BattleBladeEquipped", false)
		stripOnSpawn(player)
	end)
	if player.Character then
		stripOnSpawn(player)
	end
end

for _, plr in ipairs(Players:GetPlayers()) do
	hookPlayer(plr)
end
Players.PlayerAdded:Connect(hookPlayer)

print("Realm of Spirits - PlayerWeaponService loaded (hand weld, battle-only)!")
