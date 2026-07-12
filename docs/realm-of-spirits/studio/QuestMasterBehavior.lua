local Players = game:GetService("Players")
local questMaster = script.Parent

local basePivot = nil
local isAnimating = false

local function buildQuestMasterCFrame(pos, faceDir)
	local dir = Vector3.new(faceDir.X, 0, faceDir.Z)
	if dir.Magnitude < 0.01 then
		dir = Vector3.new(1, 0, 0)
	else
		dir = dir.Unit
	end
	return CFrame.lookAt(pos, pos + dir, Vector3.yAxis)
end

local function getFaceDir()
	local attr = questMaster:GetAttribute("FaceDir")
	if typeof(attr) == "Vector3" then
		return attr
	end
	return Vector3.new(1, 0, 0)
end

local function setFaceDir(dir)
	local flat = Vector3.new(dir.X, 0, dir.Z)
	if flat.Magnitude < 0.01 then return end
	questMaster:SetAttribute("FaceDir", flat.Unit)
end

local function pinFeetToGround()
	local groundY = questMaster:GetAttribute("FootGroundY")
	if typeof(groundY) ~= "number" then
		groundY = 1.05
	end
	local footBottom = math.huge
	for _, desc in ipairs(questMaster:GetDescendants()) do
		if desc:IsA("BasePart") and desc.Name == "BootFoot" then
			local cf = desc.CFrame
			local half = desc.Size * 0.5
			for _, ox in ipairs({-half.X, half.X}) do
				for _, oy in ipairs({-half.Y, half.Y}) do
					for _, oz in ipairs({-half.Z, half.Z}) do
						local y = cf:PointToWorldSpace(Vector3.new(ox, oy, oz)).Y
						if y < footBottom then footBottom = y end
					end
				end
			end
		end
	end
	if footBottom < math.huge then
		local delta = groundY - footBottom
		if math.abs(delta) > 0.001 then
			questMaster:PivotTo(questMaster:GetPivot() + Vector3.new(0, delta, 0))
		end
	end
end

local function applyPose(faceDir)
	questMaster.PrimaryPart = nil
	local pos = questMaster:GetPivot().Position
	questMaster:PivotTo(buildQuestMasterCFrame(Vector3.new(pos.X, pos.Y, pos.Z), faceDir or getFaceDir()))
	pinFeetToGround()
	basePivot = questMaster:GetPivot()
end

local function SetHighlight(color)
	local hl = questMaster:FindFirstChild("QuestHighlight")
	if hl then hl.FillColor = color end
end

local function FacePlayer(player)
	if not player or not player.Character then return end
	local root = player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local fromPos = questMaster:GetPivot().Position
	local flat = Vector3.new(root.Position.X - fromPos.X, 0, root.Position.Z - fromPos.Z)
	if flat.Magnitude < 0.05 then return end
	setFaceDir(flat)
	applyPose(flat)
end

local function PlayBow()
	if isAnimating then return end
	isAnimating = true
	local start = basePivot or questMaster:GetPivot()
	for i = 1, 4 do
		questMaster:PivotTo(start + Vector3.new(0, -0.03 * i, 0))
		task.wait(0.04)
	end
	questMaster:PivotTo(start)
	pinFeetToGround()
	basePivot = questMaster:GetPivot()
	isAnimating = false
end

local function PlayCheer()
	if isAnimating then return end
	isAnimating = true
	local start = basePivot or questMaster:GetPivot()
	for _ = 1, 3 do
		questMaster:PivotTo(start + Vector3.new(0, 0.25, 0))
		task.wait(0.1)
		questMaster:PivotTo(start)
		task.wait(0.1)
	end
	pinFeetToGround()
	basePivot = questMaster:GetPivot()
	SetHighlight(Color3.fromRGB(255, 220, 120))
	task.delay(0.8, function() SetHighlight(Color3.fromRGB(180, 120, 255)) end)
	isAnimating = false
end

local function PlayChibiFail()
	if isAnimating then return end
	isAnimating = true
	SetHighlight(Color3.fromRGB(255, 80, 80))
	local start = basePivot or questMaster:GetPivot()
	for i = 1, 4 do
		local wobble = (i % 2 == 0) and 0.12 or -0.12
		questMaster:PivotTo(start + Vector3.new(wobble, 0, 0))
		task.wait(0.07)
	end
	questMaster:PivotTo(start)
	pinFeetToGround()
	basePivot = questMaster:GetPivot()
	SetHighlight(Color3.fromRGB(180, 120, 255))
	isAnimating = false
end

local promptHooked = nil

local function ensurePrompt()
	local anchor = questMaster:FindFirstChild("QuestInteractAnchor")
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
		anchor.Parent = questMaster
	end
	local pivot = questMaster:GetPivot()
	anchor.CFrame = pivot * CFrame.new(0, 2.5, 0)

	local prompt = anchor:FindFirstChild("QuestPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "QuestPrompt"
		prompt.Parent = anchor
	end
	prompt.ActionText = "РџРѕРіРѕРІРѕСЂРёС‚СЊ"
	prompt.ObjectText = "РњРёРєР° В· РљРІРµСЃС‚РѕСЂ"
	prompt.MaxActivationDistance = 18
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Enabled = true
	return prompt
end

local function hookPrompt()
	local prompt = ensurePrompt()
	if not prompt or prompt == promptHooked then return prompt end
	promptHooked = prompt
	prompt.Triggered:Connect(function(player)
		FacePlayer(player)
		PlayBow()
	end)
	return prompt
end

task.defer(function()
	task.wait(0.3)
	applyPose(getFaceDir())
	hookPrompt()
	task.delay(1.5, function()
		applyPose(getFaceDir())
		hookPrompt()
	end)
end)

questMaster:GetAttributeChangedSignal("Reaction"):Connect(function()
	local reaction = questMaster:GetAttribute("Reaction")
	if reaction == "Success" then
		PlayCheer()
	elseif reaction == "Fail" then
		PlayChibiFail()
	elseif reaction == "Bow" then
		PlayBow()
	end
end)

questMaster:GetAttributeChangedSignal("FaceUserId"):Connect(function()
	local userId = tonumber(questMaster:GetAttribute("FaceUserId"))
	if not userId then return end
	local player = Players:GetPlayerByUserId(userId)
	if player then
		FacePlayer(player)
	end
end)

print("QuestMaster behavior loaded (upright, prompt ensured)")

