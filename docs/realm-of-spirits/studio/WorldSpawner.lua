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
		-- квестор всегда только на улице (Baseplate), не внутри SafeZone/магазина
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

	-- несколько попыток: пропускаем стены/крыши/combat и ищем пол
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
		dir = Vector3.new(1, 0, 0) -- смотрит к магазину с улицы слева
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
		-- всегда Baseplate (верх), чтобы не парить из‑за других hit'ов луча
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
		-- Skirt как PrimaryPart ломает WorldPivot: риг лежит на боку
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

-- Промпт НЕ на HeadBase внутри Generated: процедурная генерация сносит дочерние инстансы.
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
	prompt.ActionText = "Поговорить"
	prompt.ObjectText = "Мика · Квестор"
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
				label.Text = "Мика · Квестор"
			end
		end
	end

	settle()
	-- процедурная модель пересобирает Generated после старта
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

local function BuildMistPond()
	local existing = workspace:FindFirstChild("MistPond")
	if existing then
		existing:Destroy()
	end
	local pathOld = workspace:FindFirstChild("MistPondPath")
	if pathOld then
		pathOld:Destroy()
	end

	local cfg = ZoneConfig.Zones and ZoneConfig.Zones.MistPond
	local center = (cfg and cfg.Center) or ZoneConfig.MistPondCenter or Vector3.new(105, 1, 125)
	local size = (cfg and cfg.Size) or Vector3.new(70, 18, 55)
	-- Stepping-stone approach from Combat north edge (no text signs)
	local pathStart = Vector3.new(center.X, 0, 88)
	local pathEnd = Vector3.new(center.X + 4, 0, center.Z - 24)

	local function part(props)
		local p = Instance.new("Part")
		for k, v in pairs(props) do
			p[k] = v
		end
		p.Anchored = true
		if props.CanCollide == nil then
			p.CanCollide = false
		end
		return p
	end

	local model = Instance.new("Model")
	model.Name = "MistPond"

	local zone = part({
		Name = "MistPondZone",
		Size = size,
		CFrame = CFrame.new(center),
		Transparency = 1,
		CanQuery = true,
	})
	zone:SetAttribute("ZoneType", "MistPond")
	zone.Parent = model

	-- Organic-ish water bowl (layered, natural glass — not neon)
	local waterDeep = part({
		Name = "PondWaterDeep",
		Size = Vector3.new(44, 1.6, 32),
		Position = Vector3.new(center.X - 2, 0.55, center.Z + 1),
		Material = Enum.Material.Glass,
		Color = Color3.fromRGB(25, 70, 95),
		Transparency = 0.25,
	})
	waterDeep.Reflectance = 0.15
	waterDeep.Parent = model

	local water = part({
		Name = "PondWater",
		Size = Vector3.new(48, 1.1, 36),
		Position = Vector3.new(center.X, 1.05, center.Z),
		Material = Enum.Material.Glass,
		Color = Color3.fromRGB(45, 120, 130),
		Transparency = 0.4,
	})
	water.Reflectance = 0.35
	water.Parent = model
	local waterLight = Instance.new("PointLight")
	waterLight.Brightness = 0.55
	waterLight.Range = 22
	waterLight.Color = Color3.fromRGB(140, 190, 200)
	waterLight.Parent = water

	-- Sandy beach ring (Japanese pond shore)
	local sandOuter = part({
		Name = "SandBank",
		Size = Vector3.new(64, 0.85, 52),
		Position = Vector3.new(center.X, 0.35, center.Z),
		Material = Enum.Material.Sand,
		Color = Color3.fromRGB(210, 190, 150),
		CanCollide = true,
	})
	sandOuter.Parent = model

	local sandInner = part({
		Name = "SandShore",
		Size = Vector3.new(54, 0.55, 42),
		Position = Vector3.new(center.X + 1, 0.7, center.Z - 1),
		Material = Enum.Material.Sand,
		Color = Color3.fromRGB(225, 205, 165),
		CanCollide = true,
	})
	sandInner.Parent = model

	-- Wider beach where spirit spawns
	local beach = part({
		Name = "PondBeach",
		Size = Vector3.new(20, 0.7, 14),
		Position = Vector3.new(center.X + 18, 0.85, center.Z - 10),
		Material = Enum.Material.Sand,
		Color = Color3.fromRGB(230, 210, 170),
		CanCollide = true,
	})
	beach.Parent = model

	-- Irregular rocks around the pond
	local rockSpecs = {
		{ Vector3.new(-22, 1.2, -8), Vector3.new(5, 3.2, 4) },
		{ Vector3.new(-18, 0.9, 12), Vector3.new(4, 2.4, 5) },
		{ Vector3.new(20, 1.0, 14), Vector3.new(4.5, 2.8, 3.5) },
		{ Vector3.new(16, 0.8, -16), Vector3.new(3.5, 2.0, 4) },
		{ Vector3.new(-6, 0.7, -20), Vector3.new(6, 1.8, 3) },
		{ Vector3.new(8, 1.1, 18), Vector3.new(3, 2.6, 3) },
	}
	for i, spec in ipairs(rockSpecs) do
		local rock = part({
			Name = "Rock_" .. i,
			Size = spec[2],
			Position = center + spec[1],
			Material = Enum.Material.Slate,
			Color = Color3.fromRGB(95 + (i % 3) * 12, 95, 90),
			CanCollide = true,
		})
		rock.Orientation = Vector3.new((i * 17) % 20, i * 40, (i * 11) % 15)
		rock.Parent = model
	end

	-- Stone lantern (ishidōrō) — landmark without text
	local lanternBase = part({
		Name = "LanternBase",
		Size = Vector3.new(2.2, 1.2, 2.2),
		Position = Vector3.new(center.X - 20, 0.9, center.Z - 14),
		Material = Enum.Material.Limestone,
		Color = Color3.fromRGB(160, 155, 140),
		CanCollide = true,
	})
	lanternBase.Parent = model
	local lanternPole = part({
		Name = "LanternPole",
		Size = Vector3.new(1.0, 4.5, 1.0),
		Position = lanternBase.Position + Vector3.new(0, 2.8, 0),
		Material = Enum.Material.Limestone,
		Color = Color3.fromRGB(150, 145, 130),
		CanCollide = true,
	})
	lanternPole.Parent = model
	local lanternHouse = part({
		Name = "LanternHouse",
		Size = Vector3.new(2.4, 2.0, 2.4),
		Position = lanternPole.Position + Vector3.new(0, 3.0, 0),
		Material = Enum.Material.Limestone,
		Color = Color3.fromRGB(140, 135, 120),
		CanCollide = true,
	})
	lanternHouse.Parent = model
	local lanternGlow = part({
		Name = "LanternGlow",
		Size = Vector3.new(1.4, 1.2, 1.4),
		Position = lanternHouse.Position,
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 210, 140),
		Transparency = 0.35,
	})
	lanternGlow.Parent = model
	local lanternLight = Instance.new("PointLight")
	lanternLight.Brightness = 1.2
	lanternLight.Range = 28
	lanternLight.Color = Color3.fromRGB(255, 200, 130)
	lanternLight.Parent = lanternGlow
	local lanternRoof = part({
		Name = "LanternRoof",
		Size = Vector3.new(3.2, 0.5, 3.2),
		Position = lanternHouse.Position + Vector3.new(0, 1.3, 0),
		Material = Enum.Material.Slate,
		Color = Color3.fromRGB(70, 65, 60),
		CanCollide = true,
	})
	lanternRoof.Parent = model

	-- Soft mist over water
	for i = 1, 4 do
		local mist = part({
			Name = "Mist_" .. i,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(12 + i * 2, 3.5, 12 + i * 2),
			Position = Vector3.new(
				center.X + math.cos(i * 1.4) * 12,
				3.2,
				center.Z + math.sin(i * 1.4) * 10
			),
			Material = Enum.Material.ForceField,
			Color = Color3.fromRGB(200, 215, 220),
			Transparency = 0.72,
		})
		mist.Parent = model
	end

	-- Natural stepping stones Combat → shore (sand/stone, no labels)
	local pathFolder = Instance.new("Model")
	pathFolder.Name = "MistPondPath"
	local steps = 9
	for i = 0, steps do
		local t = i / steps
		local wobble = math.sin(i * 1.3) * 2.5
		local pos = pathStart:Lerp(pathEnd, t) + Vector3.new(wobble, 0.4, 0)
		local stone = part({
			Name = "StepStone_" .. i,
			Size = Vector3.new(3.2 + (i % 3) * 0.4, 0.55, 2.6 + (i % 2) * 0.5),
			Position = pos,
			Material = Enum.Material.Slate,
			Color = Color3.fromRGB(110 + (i % 4) * 8, 105, 95),
			CanCollide = true,
		})
		stone.Orientation = Vector3.new(0, i * 18, 0)
		stone.Parent = pathFolder
		-- thin sand between stones
		if i < steps then
			local mid = pos:Lerp(pathStart:Lerp(pathEnd, (i + 1) / steps) + Vector3.new(math.sin((i + 1) * 1.3) * 2.5, 0.4, 0), 0.5)
			local sand = part({
				Name = "PathSand_" .. i,
				Size = Vector3.new(5.5, 0.25, 4),
				Position = Vector3.new(mid.X, 0.2, mid.Z),
				Material = Enum.Material.Sand,
				Color = Color3.fromRGB(215, 195, 155),
				CanCollide = true,
			})
			sand.Parent = pathFolder
		end
	end
	pathFolder.Parent = workspace

	model.Parent = workspace
	print("Realm of Spirits - MistPond built (Japanese sand pond, no text signs)")
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

	-- PlayerHouse убран: не несёт геймплейной нагрузки
	local legacyHouse = workspace:FindFirstChild("PlayerHouse")
	if legacyHouse then
		legacyHouse:Destroy()
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
	BuildMistPond()
	SetupSpawn()
	SetupQuestMaster()
end

CreateWorld()

task.spawn(function()
	task.wait(1)
	EnsureQuestMasterStable()
	-- редкая страховка, без постоянного переворота
	while true do
		task.wait(8)
		EnsureQuestMasterStable()
	end
end)

print("Realm of Spirits - World Spawner loaded!")
