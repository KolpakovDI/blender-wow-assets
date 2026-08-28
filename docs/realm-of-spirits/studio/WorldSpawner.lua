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
	-- AI mesh Mika: measure visible MeshParts only (ignore QuestInteractAnchor)
	if footBottom == math.huge or headTop == -math.huge then
		for _, desc in ipairs(model:GetDescendants()) do
			if desc:IsA("MeshPart") or (desc:IsA("BasePart") and desc.Name ~= "QuestInteractAnchor" and desc.Transparency < 1) then
				local minY, maxY = GetPartWorldMinMaxY(desc)
				if minY < footBottom then footBottom = minY end
				if maxY > headTop then headTop = maxY end
			end
		end
	end
	-- AI mesh Mika: measure visible MeshParts only (ignore QuestInteractAnchor)
	if footBottom == math.huge or headTop == -math.huge then
		for _, desc in ipairs(model:GetDescendants()) do
			if desc:IsA("MeshPart") or (desc:IsA("BasePart") and desc.Name ~= "QuestInteractAnchor" and desc.Transparency < 1) then
				local minY, maxY = GetPartWorldMinMaxY(desc)
				if minY < footBottom then footBottom = minY end
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

local function GetQuestMasterMeshMinY(model)
	local minY = math.huge
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") and desc.Name ~= "QuestInteractAnchor" then
			local cf = desc.CFrame
			local half = desc.Size * 0.5
			for _, ox in ipairs({-half.X, half.X}) do
				for _, oy in ipairs({-half.Y, half.Y}) do
					for _, oz in ipairs({-half.Z, half.Z}) do
						minY = math.min(minY, cf:PointToWorldSpace(Vector3.new(ox, oy, oz)).Y)
					end
				end
			end
		end
	end
	return minY
end

-- Procedural Mika: CFrame.lookAt ломает риг. Ставим самую длинную ось AABB → world Y.
local function GetQuestMasterAABB(model)
	local minV = Vector3.new(math.huge, math.huge, math.huge)
	local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") and desc.Name ~= "QuestInteractAnchor" then
			local cf = desc.CFrame
			local half = desc.Size * 0.5
			for _, ox in ipairs({-half.X, half.X}) do
				for _, oy in ipairs({-half.Y, half.Y}) do
					for _, oz in ipairs({-half.Z, half.Z}) do
						local w = cf:PointToWorldSpace(Vector3.new(ox, oy, oz))
						minV = Vector3.new(math.min(minV.X, w.X), math.min(minV.Y, w.Y), math.min(minV.Z, w.Z))
						maxV = Vector3.new(math.max(maxV.X, w.X), math.max(maxV.Y, w.Y), math.max(maxV.Z, w.Z))
					end
				end
			end
		end
	end
	return minV, maxV
end

local function MakeQuestMasterBodyUpright(model)
	for _ = 1, 4 do
		local minV, maxV = GetQuestMasterAABB(model)
		if minV.X > maxV.X then
			return false
		end
		local span = maxV - minV
		local center = (minV + maxV) * 0.5
		-- уже стоит (рост по Y заметно больше ширины)
		if span.Y >= span.X * 1.08 and span.Y >= span.Z * 1.08 then
			return true
		end
		local pivot = model:GetPivot()
		local rot
		if span.X >= span.Z and span.X >= span.Y then
			-- длина вдоль X → крутим вокруг Z, берём знак с большим span.Y
			local cand = {
				CFrame.Angles(0, 0, math.rad(-90)),
				CFrame.Angles(0, 0, math.rad(90)),
			}
			local best, bestSy = nil, -1
			for _, r in ipairs(cand) do
				model:PivotTo(CFrame.new(center) * r * CFrame.new(-center) * pivot)
				local mn, mx = GetQuestMasterAABB(model)
				local sy = (mx - mn).Y
				if sy > bestSy then
					bestSy = sy
					best = r
				end
				model:PivotTo(pivot)
			end
			rot = best or cand[1]
		elseif span.Z >= span.X and span.Z >= span.Y then
			local cand = {
				CFrame.Angles(math.rad(-90), 0, 0),
				CFrame.Angles(math.rad(90), 0, 0),
			}
			local best, bestSy = nil, -1
			for _, r in ipairs(cand) do
				model:PivotTo(CFrame.new(center) * r * CFrame.new(-center) * pivot)
				local mn, mx = GetQuestMasterAABB(model)
				local sy = (mx - mn).Y
				if sy > bestSy then
					bestSy = sy
					best = r
				end
				model:PivotTo(pivot)
			end
			rot = best or cand[1]
		else
			-- Y уже max но недостаточно — переворот
			rot = CFrame.Angles(math.pi, 0, 0)
		end
		model:PivotTo(CFrame.new(center) * rot * CFrame.new(-center) * pivot)
	end
	return true
end

local function YawQuestMasterToFace(model, pos, faceDir)
	local flat = Vector3.new(faceDir.X, 0, faceDir.Z)
	if flat.Magnitude < 0.01 then
		flat = Vector3.new(1, 0, 0)
	else
		flat = flat.Unit
	end
	local pivot = model:GetPivot()
	local look = Vector3.new(pivot.LookVector.X, 0, pivot.LookVector.Z)
	local eye = model:FindFirstChild("LeftEye", true)
	if eye then
		local el = Vector3.new(eye.CFrame.LookVector.X, 0, eye.CFrame.LookVector.Z)
		if el.Magnitude > 0.01 then
			look = el
		end
	end
	if look.Magnitude < 0.01 then
		look = Vector3.new(0, 0, -1)
	else
		look = look.Unit
	end
	local angNow = math.atan2(look.X, look.Z)
	local angWant = math.atan2(flat.X, flat.Z)
	local delta = angWant - angNow
	local rot = pivot - pivot.Position
	model:PivotTo(CFrame.new(pos) * CFrame.Angles(0, delta, 0) * rot)
end

local function PinQuestMasterFeetToGround(model, groundY)
	local targetFootY = groundY + 0.02
	local minY = GetQuestMasterMeshMinY(model)
	if minY < math.huge then
		local delta = targetFootY - minY
		if math.abs(delta) > 0.001 then
			model:PivotTo(model:GetPivot() + Vector3.new(0, delta, 0))
		end
	end
	local _, _, fullHeight = GetQuestMasterExtents(model)
	model:SetAttribute("FullHeight", fullHeight)
	model:SetAttribute("FootGroundY", targetFootY)
end

local function EnsureBaseplateLevel()
	local bp = workspace:FindFirstChild("Baseplate")
	if bp and bp:IsA("BasePart") then
		if bp.Size.X < 800 or bp.Size.Z < 800 then
			bp.Size = Vector3.new(800, 1, 800)
		end
		-- верх базы = Y 0
		local top = bp.Position.Y + bp.Size.Y * 0.5
		if math.abs(top) > 0.05 then
			bp.Position = Vector3.new(bp.Position.X, -bp.Size.Y * 0.5, bp.Position.Z)
		end
		return bp.Position.Y + bp.Size.Y * 0.5
	end
	return 0
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
		local groundY = EnsureBaseplateLevel()
		for _ = 1, 3 do
			MakeQuestMasterBodyUpright(model)
		end
		local pivotY = model:GetPivot().Position.Y
		YawQuestMasterToFace(model, Vector3.new(targetPos.X, pivotY, targetPos.Z), faceDir)
		MakeQuestMasterBodyUpright(model)
		PinQuestMasterFeetToGround(model, groundY)
		model.PrimaryPart = nil
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

local function EnsureQuestMasterInteract(model)
	if not model then return end
	local anchor = model:FindFirstChild("QuestInteractAnchor")
	if not anchor then
		anchor = Instance.new("Part")
		anchor.Name = "QuestInteractAnchor"
		anchor.Transparency = 1
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.CanQuery = true
		anchor.CanTouch = false
		anchor.Massless = true
		anchor.Parent = model
	end
	local maxY, sumX, sumZ, n = -math.huge, 0, 0, 0
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "QuestInteractAnchor" and d.Transparency < 1 then
			local cf, sz = d.CFrame, d.Size
			local hy = math.abs(cf.UpVector.Y) * sz.Y * 0.5
				+ math.abs(cf.RightVector.Y) * sz.X * 0.5
				+ math.abs(cf.LookVector.Y) * sz.Z * 0.5
			maxY = math.max(maxY, cf.Position.Y + hy)
			sumX += cf.Position.X
			sumZ += cf.Position.Z
			n += 1
		end
	end
	local ax, headTop, az
	if n == 0 then
		local cf, sz = model:GetBoundingBox()
		ax, headTop, az = cf.Position.X, cf.Position.Y + sz.Y * 0.5, cf.Position.Z
	else
		ax, headTop, az = sumX / n, maxY, sumZ / n
	end
	anchor.Size = Vector3.new(1.2, 1.2, 1.2)
	anchor.CFrame = CFrame.new(ax, headTop + 0.85, az)

	local hint = anchor:FindFirstChild("TalkHint")
	if not hint then
		hint = Instance.new("BillboardGui")
		hint.Name = "TalkHint"
		hint.Size = UDim2.new(0, 140, 0, 36)
		hint.StudsOffset = Vector3.new(0, 2.2, 0)
		hint.AlwaysOnTop = true
		hint.MaxDistance = 60
		hint.Parent = anchor
		local lbl = Instance.new("TextLabel")
		lbl.Name = "Label"
		lbl.Size = UDim2.fromScale(1, 1)
		lbl.BackgroundColor3 = Color3.fromRGB(40, 20, 50)
		lbl.BackgroundTransparency = 0.25
		lbl.Text = "Мика [E]"
		lbl.TextColor3 = Color3.fromRGB(255, 210, 240)
		lbl.Font = Enum.Font.GothamBold
		lbl.TextScaled = true
		lbl.Parent = hint
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = lbl
	end
	-- F3-W1: TalkHint disabled (UX cleanup 2026-08-28)
	hint.Enabled = false
	hint.Size = UDim2.new(0, 140, 0, 36)
	local hintLbl = hint:FindFirstChild("Label")
	if hintLbl and hintLbl:IsA("TextLabel") then
		hintLbl.Text = "Мика [E]"
	end

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
	prompt.Style = Enum.ProximityPromptStyle.Default
	prompt.UIOffset = Vector2.new(0, 0)

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
	EnsureBaseplateLevel()

	local targetBase = ZoneConfig.QuestMasterPosition or ZoneConfig.CounterPosition
	local current = questMaster:GetPivot().Position
	local flatDrift = Vector3.new(current.X - targetBase.X, 0, current.Z - targetBase.Z).Magnitude

	local minV, maxV = GetQuestMasterAABB(questMaster)
	local span = maxV - minV
	local bodyUpOk = span.Y >= span.X * 1.08 and span.Y >= span.Z * 1.08
	local meshMin = GetQuestMasterMeshMinY(questMaster)
	local groundY = EnsureBaseplateLevel()
	local floating = meshMin < math.huge and math.abs(meshMin - (groundY + 0.02)) > 0.35

	-- Всегда чиним позу: lookAt/ProceduralGeneration часто кладут риг на бок
	if flatDrift > 2 or not bodyUpOk or floating then
		LockQuestMasterPhysics(questMaster)
		AlignModelToGround(questMaster, targetBase)
		LockQuestMasterPhysics(questMaster)
	else
		-- лёгкий pin без полного reset
		PinQuestMasterFeetToGround(questMaster, groundY)
	end
	EnsureQuestMasterInteract(questMaster)
end


local function SetupSpawn()
	local spawn = workspace:FindFirstChild("SpawnLocation") or workspace:FindFirstChildOfClass("SpawnLocation")
	if not spawn then
		spawn = Instance.new("SpawnLocation")
		spawn.Name = "SpawnLocation"
		spawn.Parent = workspace
	end
	local pos = ZoneConfig.SpawnPosition
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Transparency = 1
	local bp = workspace:FindFirstChild("Baseplate")
	local groundY = bp and (bp.Position.Y + bp.Size.Y * 0.5) or 0
	local center = Vector3.new(pos.X, groundY + spawn.Size.Y * 0.5, pos.Z)
	local mika = ZoneConfig.QuestMasterPosition or (center + Vector3.new(-10, 0, 0))
	spawn.CFrame = CFrame.lookAt(center, Vector3.new(mika.X, center.Y, mika.Z))
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
	local center = (cfg and cfg.Center) or ZoneConfig.MistPondCenter or Vector3.new(30, 2, -880)
	local size = (cfg and cfg.Size) or Vector3.new(120, 24, 100)

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

	-- Swim volume for Водный Карп (SpiritAnimation PondWater bounds) — in coastal sea
	local water = part({
		Name = "PondWater",
		Size = Vector3.new(95, 2.2, 75),
		Position = Vector3.new(center.X, 1.35, center.Z),
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(40, 190, 205),
		Transparency = 0.65,
		Reflectance = 0.25,
		CanCollide = false,
	})
	water.Parent = model
	local waterLight = Instance.new("PointLight")
	waterLight.Brightness = 0.4
	waterLight.Range = 36
	waterLight.Color = Color3.fromRGB(120, 210, 220)
	waterLight.Parent = water

	local waterDeep = part({
		Name = "PondWaterDeep",
		Size = Vector3.new(70, 1.6, 55),
		Position = Vector3.new(center.X + 8, 0.9, center.Z - 12),
		Material = Enum.Material.SmoothPlastic,
		Color = Color3.fromRGB(25, 130, 170),
		Transparency = 0.7,
		CanCollide = false,
	})
	waterDeep.Parent = model

	-- Small rocky islet / shore edge on north side (toward beach)
	local islet = part({
		Name = "SeaIslet",
		Size = Vector3.new(28, 1.2, 16),
		Position = Vector3.new(center.X - 25, 0.7, center.Z + 40),
		Material = Enum.Material.Sand,
		Color = Color3.fromRGB(230, 200, 140),
		CanCollide = true,
	})
	islet.Parent = model

	local rockSpecs = {
		{ Vector3.new(-30, 1.0, 35), Vector3.new(6, 3.5, 5) },
		{ Vector3.new(-18, 0.8, 42), Vector3.new(4, 2.5, 4) },
		{ Vector3.new(35, 1.1, -20), Vector3.new(5, 3.0, 4.5) },
		{ Vector3.new(20, 0.9, 30), Vector3.new(3.5, 2.2, 3.5) },
		{ Vector3.new(-40, 0.7, -10), Vector3.new(4.5, 2.0, 5) },
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

	for i = 1, 3 do
		local mist = part({
			Name = "Mist_" .. i,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(18 + i * 4, 4, 18 + i * 4),
			Position = Vector3.new(
				center.X + math.cos(i * 1.7) * 20,
				3.5,
				center.Z + math.sin(i * 1.7) * 16
			),
			Material = Enum.Material.ForceField,
			Color = Color3.fromRGB(180, 220, 230),
			Transparency = 0.78,
		})
		mist.Parent = model
	end

	model.Parent = workspace
	print("Realm of Spirits - MistPond built (coastal sea habitat for Water Carp)")
end

-- Карманы обитания духов (кроме MistPond — у него своя сцена)
local function BuildSpiritHabitats()
	local existing = workspace:FindFirstChild("SpiritHabitats")
	if existing then
		existing:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = "SpiritHabitats"

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

	local habitats = {
		{
			Key = "FrostRidge",
			Accent = Color3.fromRGB(160, 210, 255),
			Ground = Color3.fromRGB(200, 220, 235),
			Material = Enum.Material.Glacier,
		},
		{
			Key = "ShadowHollow",
			Accent = Color3.fromRGB(90, 50, 130),
			Ground = Color3.fromRGB(45, 35, 55),
			Material = Enum.Material.Asphalt,
		},
		{
			Key = "StormSpire",
			Accent = Color3.fromRGB(240, 230, 90),
			Ground = Color3.fromRGB(70, 70, 80),
			Material = Enum.Material.Basalt,
		},
		{
			Key = "DawnMeadow",
			Accent = Color3.fromRGB(255, 245, 180),
			Ground = Color3.fromRGB(120, 170, 90),
			Material = Enum.Material.Grass,
		},
		{
			Key = "StoneBasin",
			Accent = Color3.fromRGB(180, 140, 90),
			Ground = Color3.fromRGB(110, 90, 65),
			Material = Enum.Material.Slate,
		},
		{
			Key = "AshGarden",
			Accent = Color3.fromRGB(255, 100, 40),
			Ground = Color3.fromRGB(90, 45, 30),
			Material = Enum.Material.Basalt,
		},
		{
			Key = "GaleCliff",
			Accent = Color3.fromRGB(120, 200, 180),
			Ground = Color3.fromRGB(70, 95, 100),
			Material = Enum.Material.Sandstone,
		},
		{
			Key = "MossGlade",
			Accent = Color3.fromRGB(80, 160, 70),
			Ground = Color3.fromRGB(55, 90, 45),
			Material = Enum.Material.Grass,
		},
		{
			Key = "Moonwell",
			Accent = Color3.fromRGB(180, 195, 255),
			Ground = Color3.fromRGB(40, 45, 70),
			Material = Enum.Material.Glacier,
		},
		{
			Key = "VenomHollow",
			Accent = Color3.fromRGB(90, 180, 60),
			Ground = Color3.fromRGB(45, 70, 35),
			Material = Enum.Material.LeafyGrass,
		},
		{
			Key = "SandDunes",
			Accent = Color3.fromRGB(210, 170, 90),
			Ground = Color3.fromRGB(190, 155, 85),
			Material = Enum.Material.Sand,
		},
		{
			Key = "IronWastes",
			Accent = Color3.fromRGB(140, 155, 175),
			Ground = Color3.fromRGB(100, 110, 125),
			Material = Enum.Material.Basalt,
		},
		{
			Key = "CrystalCaves",
			Accent = Color3.fromRGB(180, 220, 255),
			Ground = Color3.fromRGB(90, 110, 140),
			Material = Enum.Material.Glacier,
		},
		{
			Key = "MagmaFissure",
			Accent = Color3.fromRGB(255, 90, 40),
			Ground = Color3.fromRGB(70, 30, 20),
			Material = Enum.Material.Basalt,
		},
		{
			Key = "FogBasin",
			Accent = Color3.fromRGB(160, 190, 220),
			Ground = Color3.fromRGB(70, 90, 110),
			Material = Enum.Material.Limestone,
		},
		{
			Key = "SkyRidge",
			Accent = Color3.fromRGB(180, 210, 255),
			Ground = Color3.fromRGB(90, 120, 150),
			Material = Enum.Material.Sandstone,
		},
	}

	for _, h in ipairs(habitats) do
		local cfg = ZoneConfig.Zones and ZoneConfig.Zones[h.Key]
		if cfg then
			local model = Instance.new("Model")
			model.Name = h.Key

			local zone = part({
				Name = h.Key .. "Zone",
				Size = cfg.Size,
				CFrame = CFrame.new(cfg.Center),
				Transparency = 1,
				CanQuery = true,
			})
			zone:SetAttribute("ZoneType", h.Key)
			zone.Parent = model

			local pad = part({
				Name = "HabitatPad",
				Size = Vector3.new(28, 0.6, 28),
				Position = Vector3.new(cfg.Center.X, 0.35, cfg.Center.Z),
				Material = h.Material,
				Color = h.Ground,
				CanCollide = true,
			})
			pad.Parent = model

			local ring = part({
				Name = "HabitatRing",
				Size = Vector3.new(22, 0.25, 22),
				Position = Vector3.new(cfg.Center.X, 0.72, cfg.Center.Z),
				Material = Enum.Material.Neon,
				Color = h.Accent,
				Transparency = 0.35,
			})
			ring.Parent = model

			model.Parent = folder
		end
	end

	folder.Parent = workspace
	print("Realm of Spirits - SpiritHabitats built (FrostRidge/ShadowHollow/StormSpire/DawnMeadow/StoneBasin/AshGarden/GaleCliff/MossGlade/Moonwell/VenomHollow/SandDunes/IronWastes)")
end

-- Q2: named quest locations + landscape markers
local function BuildQuestLocations()
	local existing = workspace:FindFirstChild("QuestLocations")
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "QuestLocations"
	local locs = ZoneConfig.QuestLocations or {}
	for key, cfg in pairs(locs) do
		local model = Instance.new("Model")
		model.Name = key
		local ground = Instance.new("Part")
		ground.Name = "Pad"
		ground.Anchored = true
		ground.Size = Vector3.new(math.max(12, cfg.Size.X * 0.45), 1.2, math.max(12, cfg.Size.Z * 0.45))
		ground.Position = Vector3.new(cfg.Center.X, 0.6, cfg.Center.Z)
		ground.Color = cfg.Color or Color3.fromRGB(120, 120, 140)
		ground.Material = Enum.Material.Slate
		ground.Parent = model
		local pillar = Instance.new("Part")
		pillar.Name = "Marker"
		pillar.Anchored = true
		pillar.Size = Vector3.new(2.5, 10, 2.5)
		pillar.Position = Vector3.new(cfg.Center.X, 5.5, cfg.Center.Z)
		pillar.Color = cfg.Color or Color3.fromRGB(140, 160, 200)
		pillar.Material = Enum.Material.Neon
		pillar.CanCollide = false
		pillar.Parent = model
		local zone = Instance.new("Part")
		zone.Name = key .. "Zone"
		zone.Anchored = true
		zone.Transparency = 1
		zone.CanCollide = false
		zone.CanQuery = true
		zone.Size = cfg.Size
		zone.Position = cfg.Center
		zone:SetAttribute("ZoneType", key)
		zone.Parent = model
		local bill = Instance.new("BillboardGui")
		bill.Name = "Label"
		bill.Size = UDim2.fromOffset(180, 36)
		bill.StudsOffset = Vector3.new(0, 8, 0)
		bill.AlwaysOnTop = true
		bill.Parent = pillar
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Text = tostring(cfg.Label or key)
		t.TextColor3 = Color3.fromRGB(240, 230, 255)
		t.Font = Enum.Font.GothamBold
		t.TextSize = 16
		t.TextStrokeTransparency = 0.4
		t.Parent = bill
		model.PrimaryPart = ground
		model.Parent = folder
	end
	folder.Parent = workspace
	print("Realm of Spirits - QuestLocations built count=", #folder:GetChildren())
end

local function CreateWorld()
	-- Single ground Baseplate (top Y=0); destroy elevated duplicates
	local mainBp, bestArea = nil, -1
	for _, d in ipairs(workspace:GetChildren()) do
		if d.Name == "Baseplate" and d:IsA("BasePart") then
			local area = d.Size.X * d.Size.Z
			if area > bestArea then
				mainBp = d
				bestArea = area
			end
		end
	end
	for _, d in ipairs(workspace:GetChildren()) do
		if d.Name == "Baseplate" and d:IsA("BasePart") and d ~= mainBp then
			d:Destroy()
		end
	end
	if not mainBp then
		local baseplate = Instance.new("Part")
		baseplate.Name = "Baseplate"
		baseplate.Size = Vector3.new(2048, 1, 2048)
		baseplate.Position = Vector3.new(0, -0.5, 0)
		baseplate.Anchored = true
		baseplate.BrickColor = BrickColor.new("Dark green")
		baseplate.Parent = workspace
		mainBp = baseplate
	else
		if mainBp.Size.X < 700 or mainBp.Size.Z < 700 then
			mainBp.Size = Vector3.new(math.max(mainBp.Size.X, 700), 1, math.max(mainBp.Size.Z, 700))
		end
		mainBp.Position = Vector3.new(mainBp.Position.X, -mainBp.Size.Y * 0.5, mainBp.Position.Z)
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
	BuildSpiritHabitats()
	BuildQuestLocations()
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
