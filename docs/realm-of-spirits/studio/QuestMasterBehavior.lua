local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local questMaster = script.Parent

local basePivot = nil
local isAnimating = false

-- 2D-Live лица (GDD Scene 2): procedural face panel вместо глифов
local FACE_SKIN = Color3.fromRGB(255, 224, 210)
local EMOTIONS = {
	Idle = { title = "", color = Color3.fromRGB(210, 195, 230), eye = "dot", mouth = "flat", brow = 0 },
	Talk = { title = "いらっしゃいませ!", color = Color3.fromRGB(255, 170, 220), eye = "happy", mouth = "open", brow = -2 },
	Success = { title = "やった！", color = Color3.fromRGB(255, 220, 90), eye = "happy", mouth = "grin", brow = -4 },
	Joy = { title = "やった！", color = Color3.fromRGB(255, 220, 90), eye = "happy", mouth = "grin", brow = -4 },
	Fail = { title = "ええっ!?", color = Color3.fromRGB(255, 110, 130), eye = "wide", mouth = "shock", brow = 6 },
	Panic = { title = "ええっ!?", color = Color3.fromRGB(255, 110, 130), eye = "wide", mouth = "shock", brow = 6 },
	Point = { title = "がんばれ!", color = Color3.fromRGB(120, 210, 255), eye = "determined", mouth = "smile", brow = -1 },
	Bow = { title = "よろしく", color = Color3.fromRGB(180, 220, 255), eye = "soft", mouth = "smile", brow = 0 },
}

local liveGui, livePanel, liveFace, liveTitle
local leftEye, rightEye, mouth, leftBrow, rightBrow, blushL, blushR
local emotionToken = 0

local function makeFacePart(parent, name, size, pos, color, radius)
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = size
	f.Position = pos
	f.BackgroundColor3 = color
	f.BorderSizePixel = 0
	f.Parent = parent
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = f
	return f
end

local function ensureLive2D()
	-- Отключено: окно с эмодзи над головой Мики
	local existing = questMaster:FindFirstChild("Live2DEmotion")
	if existing then existing:Destroy() end
	liveGui = nil
	facePanel = nil
end

local function showEmotion(key, duration)
	if true then return end -- Live2D emoji billboard disabled
	ensureLive2D()
	local emo = EMOTIONS[key] or EMOTIONS.Idle
	emotionToken += 1
	local token = emotionToken
	liveGui.Enabled = true
	liveTitle.Text = emo.title
	applyFaceStyle(emo)
	local stroke = livePanel:FindFirstChild("Stroke")
	if stroke then stroke.Color = emo.color end
	livePanel.Size = UDim2.new(0.75, 0, 0.75, 0)
	livePanel.Position = UDim2.new(0.125, 0, 0.125, 0)
	TweenService:Create(livePanel, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
	}):Play()
	task.delay(duration or 2.2, function()
		if token ~= emotionToken then return end
		local idle = EMOTIONS.Idle
		liveTitle.Text = idle.title
		applyFaceStyle(idle)
		if stroke then stroke.Color = idle.color end
	end)
end

ensureLive2D()
showEmotion("Idle", 0.1)

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
	prompt.ActionText = "Поговорить"
	prompt.ObjectText = "Мика · Квестор"
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
	if not reaction then return end
	if reaction == "Success" or reaction == "Joy" then
		showEmotion("Joy", 2.5)
		PlayCheer()
	elseif reaction == "Fail" or reaction == "Panic" then
		showEmotion("Panic", 2.2)
		PlayChibiFail()
	elseif reaction == "Bow" then
		showEmotion("Bow", 2.0)
		PlayBow()
	elseif reaction == "Talk" then
		showEmotion("Talk", 2.4)
	elseif reaction == "Point" then
		showEmotion("Point", 2.4)
		SetHighlight(Color3.fromRGB(120, 200, 255))
		task.delay(0.8, function() SetHighlight(Color3.fromRGB(180, 120, 255)) end)
	else
		showEmotion("Idle", 1.0)
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
