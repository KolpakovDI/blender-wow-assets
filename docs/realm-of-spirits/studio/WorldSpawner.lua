-- ============================================
-- Realm of Spirits - World Spawner
-- GDD v2.0: Otaku Haven hub + legacy world pieces
-- ============================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RealmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local ZoneConfig = require(RealmFolder:WaitForChild("ZoneConfig"))
local OtakuHavenBuilder = require(ServerScriptService.RealmOfSpirits.OtakuHavenBuilder)

local function GetGroundPosition(x, z, excludeList)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	local exclude = {}
	if excludeList then
		for _, inst in ipairs(excludeList) do
			table.insert(exclude, inst)
		end
	end
	rayParams.FilterDescendantsInstances = exclude

	local function isWalkable(part)
		local n = part.Name
		-- РєРІРµСЃС‚РѕСЂ РІСЃРµРіРґР° С‚РѕР»СЊРєРѕ РЅР° СѓР»РёС†Рµ (Baseplate), РЅРµ РІРЅСѓС‚СЂРё SafeZone/РјР°РіР°Р·РёРЅР°
		if n == "Baseplate" then
			return true
		end
		if n == "SafeZone" or n == "CombatZone" then
			return false
		end
		if string.find(n, "Wall") or string.find(n, "Roof") or string.find(n, "Ceiling") then
			return false
		end
		if n == "GenkanMat" or string.find(n, "Floor") or string.find(n, "Ground") or string.find(n, "Genkan") then
			return true
		end
		return false
	end

	-- РЅРµСЃРєРѕР»СЊРєРѕ РїРѕРїС‹С‚РѕРє: РїСЂРѕРїСѓСЃРєР°РµРј СЃС‚РµРЅС‹/РєСЂС‹С€Рё/combat Рё РёС‰РµРј РїРѕР»
	local originY = 12
	for _ = 1, 8 do
		local result = workspace:Raycast(Vector3.new(x, originY, z), Vector3.new(0, -40, 0), rayParams)
		if not result then
			break
		end
		if isWalkable(result.Instance) then
			return result.Position
		end
		table.insert(exclude, result.Instance)
		rayParams.FilterDescendantsInstances = exclude
	end

	return Vector3.new(x, 0.5, z)
end

local function GetPartWorldMinMaxY(part)
	local cf = part.CFrame
	local half = part.Size * 0.5
	local minY, maxY = math.huge, -math.huge
	for _, ox in ipairs({-half.X, half.X}) do
		for _, oy in ipairs({-half.Y, half.Y}) do
			for _, oz in ipairs({-half.Z, half.Z}) do
				local y = cf:PointToWorldSpace(Vector3.new(ox, oy, oz)).Y
				if y < minY then minY = y end
				if y > maxY then maxY = y end
			end
		end
	end
	return minY, maxY
end

local function GetQuestMasterExtents(model)
	local footBottom = math.huge
	local headTop = -math.huge
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then
			if desc.Name == "BootFoot" then
				local minY = GetPartWorldMinMaxY(desc)
				if minY < footBottom then footBottom = minY end
			elseif desc.Name == "HeadBase" then
				local _, maxY = GetPartWorldMinMaxY(desc)
				if maxY > headTop then headTop = maxY end
			end
		end
	end
	if footBottom == math.huge or headTop == -math.huge then
		local boxCf, boxSize = model:GetBoundingBox()
		footBottom = boxCf.Position.Y - boxSize.Y * 0.5
		headTop = boxCf.Position.Y + boxSize.Y * 0.5
	end
	return footBottom, headTop, math.max(0.1, headTop - footBottom)
end

local function BuildQuestMasterCFrame(pos, faceDir)
	local dir = Vector3.new(faceDir.X, 0, faceDir.Z)
	if dir.Magnitude < 0.01 then
		dir = Vector3.new(1, 0, 0) -- СЃРјРѕС‚СЂРёС‚ Рє РјР°РіР°Р·РёРЅСѓ СЃ СѓР»РёС†С‹ СЃР»РµРІР°
	else
		dir = dir.Unit
	end
	return CFrame.lookAt(pos, pos + dir, Vector3.yAxis)
end

local function PinQuestMasterFeetToGround(model, groundY)
	local footBottom, _, fullHeight = GetQuestMasterExtents(model)
	local targetFootY = groundY + 0.05
	local delta = targetFootY - footBottom
	if math.abs(delta) > 0.001 then
		model:PivotTo(model:GetPivot() + Vector3.new(0, delta, 0))
	end
	model:SetAttribute("FullHeight", fullHeight)
	model:SetAttribute("FootGroundY", targetFootY)
end

local function AlignModelToGround(model, targetPos)
	if not model or not model:IsA("Model") then return end

	local exclude = {model}
	local ground = GetGroundPosition(targetPos.X, targetPos.Z, exclude)
	local pos = Vector3.new(targetPos.X, ground.Y, targetPos.Z)

	if model.Name == "QuestMaster" then
		model.PrimaryPart = nil
		local faceAttr = model:GetAttribute("FaceDir")
		local faceDir = Vector3.new(1, 0, 0)
		if typeof(faceAttr) == "Vector3" then
			faceDir = faceAttr
		end
		-- РІСЃРµРіРґР° Baseplate (РІРµСЂС…), С‡С‚РѕР±С‹ РЅРµ РїР°СЂРёС‚СЊ РёР·вЂ‘Р·Р° РґСЂСѓРіРёС… hit'РѕРІ Р»СѓС‡Р°
		local bp = workspace:FindFirstChild("Baseplate")
		local groundY = bp and (bp.Position.Y + bp.Size.Y * 0.5) or ground.Y
		model:PivotTo(BuildQuestMasterCFrame(Vector3.new(pos.X, groundY, pos.Z), faceDir))
		PinQuestMasterFeetToGround(model, groundY)
	else
		local current = model:GetPivot()
		local look = current.LookVector
		local flatLook = Vector3.new(look.X, 0, look.Z)
		if flatLook.Magnitude < 0.01 then
			flatLook = Vector3.new(0, 0, -1)
		end
		model:PivotTo(CFrame.lookAt(pos, pos + flatLook.Unit, Vector3.yAxis))

		local lowestY = math.huge
		for _, desc in ipairs(model:GetDescendants()) do
			if desc:IsA("BasePart") and desc.Name == "BootFoot" then
				local minY = GetPartWorldMinMaxY(desc)
				if minY < lowestY then lowestY = minY end
			end
		end
		if lowestY < math.huge then
			model:PivotTo(model:GetPivot() + Vector3.new(0, ground.Y + 0.05 - lowestY, 0))
		end
	end

	if model.Name == "QuestMaster" then
		-- Skirt РєР°Рє PrimaryPart Р»РѕРјР°РµС‚ WorldPivot: СЂРёРі Р»РµР¶РёС‚ РЅР° Р±РѕРєСѓ
		model.PrimaryPart = nil
	else
		local skirt = model:FindFirstChild("Skirt", true)
		if skirt then model.PrimaryPart = skirt end
	end
end

local function LockQuestMasterPhysics(model)
	if not model then return end
	model.PrimaryPart = nil
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.Anchored = true
			desc.CanCollide = false
			desc.CanQuery = true
			desc.CanTouch = true
			desc.AssemblyLinearVelocity = Vector3.zero
			desc.AssemblyAngularVelocity = Vector3.zero
		end
	end
end

-- РџСЂРѕРјРїС‚ РќР• РЅР° HeadBase РІРЅСѓС‚СЂРё Generated: РїСЂРѕС†РµРґСѓСЂРЅР°СЏ РіРµРЅРµСЂР°С†РёСЏ СЃРЅРѕСЃРёС‚ РґРѕС‡РµСЂРЅРёРµ РёРЅСЃС‚Р°РЅСЃС‹.
local function EnsureQuestMasterInteract(model)
	if not model then return end
	local anchor = model:FindFirstChild("QuestInteractAnchor")
	if not anchor then
		anchor = Instance.new("Part")
		anchor.Name = "QuestInteractAnchor"
		anchor.Size = Vector3.new(2.5, 5, 2.5)
		anchor.Transparency = 1
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.CanQuery = true
		anchor.CanTouch = false
		anchor.Massless = true
		anchor.Parent = model
	end
	local pivot = model:GetPivot()
	anchor.CFrame = pivot * CFrame.new(0, 2.5, 0)

	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("ProximityPrompt") and not desc:IsDescendantOf(anchor) then
			desc:Destroy()
		end
	end

	local prompt = anchor:FindFirstChild("QuestPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "QuestPrompt"
		prompt.Parent = anchor
	end
	prompt.ActionText = "РџРѕРіРѕРІРѕСЂРёС‚СЊ"
	prompt.ObjectText = "РњРёРєР° В· РљРІРµСЃС‚РѕСЂ"
	prompt.Enabled = true
	prompt.MaxActivationDistance = 18
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E

	local click = anchor:FindFirstChildOfClass("ClickDetector")
	if not click then
		click = Instance.new("ClickDetector")
		click.Name = "QuestMasterClick"
		click.MaxActivationDistance = 26
		click.Parent = anchor
	end
	return prompt, click
end

local function EnsureQuestMasterStable()
	local questMaster = workspace:FindFirstChild("QuestMaster")
	if not questMaster then return end

	questMaster.PrimaryPart = nil

	local targetBase = ZoneConfig.QuestMasterPosition or ZoneConfig.CounterPosition
	local current = questMaster:GetPivot().Position
	local flatDrift = Vector3.new(current.X - targetBase.X, 0, current.Z - targetBase.Z).Magnitude

	local footBottom, headTop = GetQuestMasterExtents(questMaster)
	local visualTilted = headTop < footBottom + 2
	local upTilt = math.deg(math.acos(math.clamp(questMaster:GetPivot().UpVector:Dot(Vector3.yAxis), -1, 1)))

	if flatDrift > 4 or visualTilted or upTilt > 25 then
		LockQuestMasterPhysics(questMaster)
		AlignModelToGround(questMaster, targetBase)
		LockQuestMasterPhysics(questMaster)
	end
	EnsureQuestMasterInteract(questMaster)
end


local function SetupSpawn()
	local spawn = workspace:FindFirstChild("SpawnLocation")
	if spawn then
		local pos = ZoneConfig.SpawnPosition
		spawn.Position = Vector3.new(pos.X, pos.Y, pos.Z)
		spawn.Neutral = true
	end
end

local function SetupQuestMaster()
	local questMaster = workspace:FindFirstChild("QuestMaster")
	if not questMaster then return end

	questMaster:SetAttribute("FaceDir", Vector3.new(1, 0, 0))
	local questMasterPos = ZoneConfig.QuestMasterPosition or ZoneConfig.CounterPosition

	local function settle()
		AlignModelToGround(questMaster, questMasterPos)
		LockQuestMasterPhysics(questMaster)
		EnsureQuestMasterInteract(questMaster)
		local nameTag = questMaster:FindFirstChild("NameTag", true)
		if nameTag then
			local label = nameTag:FindFirstChildWhichIsA("TextLabel")
			if label then
				label.Text = "РњРёРєР° В· РљРІРµСЃС‚РѕСЂ"
			end
		end
	end

	settle()
	-- РїСЂРѕС†РµРґСѓСЂРЅР°СЏ РјРѕРґРµР»СЊ РїРµСЂРµСЃРѕР±РёСЂР°РµС‚ Generated РїРѕСЃР»Рµ СЃС‚Р°СЂС‚Р°
	task.delay(0.5, settle)
	task.delay(1.5, settle)
	task.delay(3, settle)

	local generated = questMaster:FindFirstChild("Generated")
	if generated and not generated:GetAttribute("QMSettleHooked") then
		generated:SetAttribute("QMSettleHooked", true)
		generated.ChildAdded:Connect(function()
			task.defer(settle)
		end)
	end
end

local function CreateWorld()
	if not workspace:FindFirstChild("Baseplate") then
		local baseplate = Instance.new("Part")
		baseplate.Name = "Baseplate"
		baseplate.Size = Vector3.new(500, 1, 500)
		baseplate.Position = Vector3.new(0, 0, 0)
		baseplate.Anchored = true
		baseplate.BrickColor = BrickColor.new("Dark green")
		baseplate.Parent = workspace
	end

	if not workspace:FindFirstChild("PlayerHouse") then
		local house = Instance.new("Model")
		house.Name = "PlayerHouse"
		local base = Instance.new("Part")
		base.Name = "Base"
		base.Size = Vector3.new(20, 1, 20)
		base.Position = Vector3.new(0, 0.5, 0)
		base.Anchored = true
		base.BrickColor = BrickColor.new("Light brown")
		base.Parent = house
		house.Parent = workspace
	end

	if not workspace:FindFirstChild("BattleArena") then
		local arena = Instance.new("Model")
		arena.Name = "BattleArena"
		local arenaBase = Instance.new("Part")
		arenaBase.Name = "Base"
		arenaBase.Size = Vector3.new(50, 1, 50)
		arenaBase.Position = Vector3.new(100, 0.5, 0)
		arenaBase.Anchored = true
		arenaBase.BrickColor = BrickColor.new("Dark stone grey")
		arenaBase.Parent = arena
		arena.Parent = workspace
	end

	if not workspace:FindFirstChild("Spirits") then
		local folder = Instance.new("Folder")
		folder.Name = "Spirits"
		folder.Parent = workspace
	end

	OtakuHavenBuilder.Build()
	SetupSpawn()
	SetupQuestMaster()
end

CreateWorld()

task.spawn(function()
	task.wait(1)
	EnsureQuestMasterStable()
	-- СЂРµРґРєР°СЏ СЃС‚СЂР°С…РѕРІРєР°, Р±РµР· РїРѕСЃС‚РѕСЏРЅРЅРѕРіРѕ РїРµСЂРµРІРѕСЂРѕС‚Р°
	while true do
		task.wait(8)
		EnsureQuestMasterStable()
	end
end)

print("Realm of Spirits - World Spawner loaded!")

