-- ============================================
-- Realm of Spirits - Quest UI Client
-- Интерфейс системы квестов
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local focusActive = false
local savedCameraType = nil
local savedAutoRotate = nil
local savedMikaFaceDir = nil

local function endMikaFocus()
	if not focusActive then return end
	focusActive = false
	local camera = workspace.CurrentCamera
	if camera then
		camera.CameraType = savedCameraType or Enum.CameraType.Custom
	end
	savedCameraType = nil

	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and savedAutoRotate ~= nil then
		humanoid.AutoRotate = savedAutoRotate
	end
	savedAutoRotate = nil

	local questMaster = workspace:FindFirstChild("QuestMaster")
	if questMaster and savedMikaFaceDir ~= nil then
		questMaster:SetAttribute("FaceDir", savedMikaFaceDir)
	end
	savedMikaFaceDir = nil
end

local function facePlayerAndMika(questMaster)
	local character = Players.LocalPlayer.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not hrp or not questMaster then
		return hrp
	end

	local mikaPos = questMaster:GetPivot().Position
	local playerPos = hrp.Position
	local toMika = Vector3.new(mikaPos.X - playerPos.X, 0, mikaPos.Z - playerPos.Z)
	if toMika.Magnitude > 0.05 then
		hrp.CFrame = CFrame.lookAt(playerPos, playerPos + toMika.Unit)
	end

	if humanoid then
		if savedAutoRotate == nil then
			savedAutoRotate = humanoid.AutoRotate
		end
		humanoid.AutoRotate = false
	end

	local toPlayer = Vector3.new(playerPos.X - mikaPos.X, 0, playerPos.Z - mikaPos.Z)
	if toPlayer.Magnitude > 0.05 then
		if savedMikaFaceDir == nil then
			local prev = questMaster:GetAttribute("FaceDir")
			savedMikaFaceDir = typeof(prev) == "Vector3" and prev or Vector3.new(1, 0, 0)
		end
		local faceDir = toPlayer.Unit
		questMaster:SetAttribute("FaceDir", faceDir)
		local mikaY = questMaster:GetPivot().Position.Y
		local flat = Vector3.new(mikaPos.X, mikaY, mikaPos.Z)
		questMaster:PivotTo(CFrame.lookAt(flat, flat + faceDir))
	end

	return hrp
end

local function startMikaFocus()
	local questMaster = workspace:FindFirstChild("QuestMaster")
	local camera = workspace.CurrentCamera
	if not questMaster or not camera then return end

	local hrp = facePlayerAndMika(questMaster)
	local pivot = questMaster:GetPivot()
	local mikaPos = pivot.Position
	-- Центр тела: Мика целиком в кадре, верх экрана свободен под UI
	local lookTarget = mikaPos + Vector3.new(0, 1.35, 0)

	local camPos
	if hrp then
		local flat = Vector3.new(mikaPos.X - hrp.Position.X, 0, mikaPos.Z - hrp.Position.Z)
		local dir = flat.Magnitude > 0.05 and flat.Unit or pivot.LookVector
		camPos = mikaPos - dir * 23.2 + Vector3.new(0, 3.4, 0)
	else
		camPos = mikaPos - pivot.LookVector * 23.2 + Vector3.new(0, 3.4, 0)
	end

	if not focusActive then
		savedCameraType = camera.CameraType
	end
	focusActive = true
	camera.CameraType = Enum.CameraType.Scriptable
	TweenService:Create(camera, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		CFrame = CFrame.lookAt(camPos, lookTarget),
	}):Play()
end

-- Escape closing is wired after questPanel is created


local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Получаем RemoteEvent
local realmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local QuestEvent = realmFolder:WaitForChild("Quest")

-- Цвета
local COLORS = {
	Background = Color3.fromRGB(25, 20, 40),
	Panel = Color3.fromRGB(35, 28, 55),
	Button = Color3.fromRGB(50, 40, 80),
	ButtonHover = Color3.fromRGB(70, 55, 110),
	Accent = Color3.fromRGB(180, 140, 255),
	Gold = Color3.fromRGB(255, 215, 0),
	Silver = Color3.fromRGB(192, 192, 192),
	Copper = Color3.fromRGB(184, 115, 51),
	Experience = Color3.fromRGB(100, 200, 255),
	Reputation = Color3.fromRGB(100, 255, 150),
	Text = Color3.fromRGB(240, 235, 250),
	SubText = Color3.fromRGB(180, 170, 200),
	Story = Color3.fromRGB(255, 180, 80),
	Side = Color3.fromRGB(120, 200, 255),
	Complete = Color3.fromRGB(100, 255, 100),
	Legendary = Color3.fromRGB(255, 180, 0),
	Epic = Color3.fromRGB(180, 100, 255),
	Rare = Color3.fromRGB(100, 180, 255),
}

-- ============================================
-- Создание UI
-- ============================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "QuestUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- ============================================
-- Панель квестов (главное окно)
-- ============================================

local questPanel = Instance.new("Frame")
questPanel.Name = "QuestPanel"
questPanel.Size = UDim2.new(0, 260, 0, 340)
questPanel.Position = UDim2.new(0.5, -130, 0, 10)
questPanel.BackgroundColor3 = COLORS.Background
questPanel.BorderSizePixel = 0
questPanel.Visible = false
questPanel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = questPanel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = COLORS.Accent
panelStroke.Thickness = 2
panelStroke.Parent = questPanel

-- Заголовок
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -40, 0, 24)
titleLabel.Position = UDim2.new(0, 12, 0, 6)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Мика · Квестор"
titleLabel.TextColor3 = COLORS.Accent
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.FredokaOne
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = questPanel

local dialogueLabel = Instance.new("TextLabel")
dialogueLabel.Name = "MikaDialogue"
dialogueLabel.Size = UDim2.new(1, -20, 0, 28)
dialogueLabel.Position = UDim2.new(0, 10, 0, 30)
dialogueLabel.BackgroundColor3 = Color3.fromRGB(45, 35, 70)
dialogueLabel.BackgroundTransparency = 0.2
dialogueLabel.TextColor3 = COLORS.Text
dialogueLabel.TextWrapped = true
dialogueLabel.TextSize = 12
dialogueLabel.Font = Enum.Font.Gotham
dialogueLabel.TextXAlignment = Enum.TextXAlignment.Left
dialogueLabel.Text = "Мика: Добро пожаловать в Otaku Haven! Тебе как раз нужна помощь героя..."
dialogueLabel.Parent = questPanel
local dlgCorner = Instance.new("UICorner")
dlgCorner.CornerRadius = UDim.new(0, 8)
dlgCorner.Parent = dialogueLabel

-- Кнопка закрытия
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -36, 0, 8)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.FredokaOne
closeBtn.TextScaled = true
closeBtn.Parent = questPanel

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
	endMikaFocus()
	questPanel.Visible = false
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.Escape and questPanel.Visible then
		endMikaFocus()
		questPanel.Visible = false
	end
end)

-- Вкладки (Доступные / Активные / Выполненные)
local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1, -16, 0, 24)
tabContainer.Position = UDim2.new(0, 8, 0, 58)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = questPanel

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
tabLayout.Padding = UDim.new(0, 4)
tabLayout.Parent = tabContainer

local currentTab = "Available"
local tabButtons = {}

local function createTab(name, text)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.333, -3, 1, -2)
	btn.BackgroundColor3 = COLORS.Button
	btn.Text = text
	btn.TextColor3 = COLORS.Text
	btn.Font = Enum.Font.Gotham
	btn.TextScaled = false
	btn.TextSize = 11
	btn.Parent = tabContainer

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 5)
	corner.Parent = btn

	btn.MouseButton1Click:Connect(function()
		currentTab = name
		for n, b in pairs(tabButtons) do
			b.BackgroundColor3 = (n == name) and COLORS.ButtonHover or COLORS.Button
		end
		showQuestList(name)
	end)

	tabButtons[name] = btn
	return btn
end

createTab("Available", "Доступные")
createTab("Active", "Активные")
createTab("Completed", "Выполненные")

-- Тело: список + описание от вкладок до кнопки Принять/Сдать
-- Окно описания: от нижнего края вкладок до кнопки Принять/Сдать
local QUEST_BODY_TOP = 84
local QUEST_FOOTER_H = 24
local QUEST_LIST_H = 120
local questBody = Instance.new("Frame")
questBody.Name = "QuestBody"
questBody.Size = UDim2.new(1, -16, 1, -(QUEST_BODY_TOP + QUEST_FOOTER_H))
questBody.Position = UDim2.new(0, 8, 0, QUEST_BODY_TOP)
questBody.BackgroundColor3 = COLORS.Panel
questBody.BorderSizePixel = 0
questBody.ClipsDescendants = true
questBody.Parent = questPanel

local bodyCorner = Instance.new("UICorner")
bodyCorner.CornerRadius = UDim.new(0, 8)
bodyCorner.Parent = questBody

-- Описание на всю высоту окна
local questDetailFrame = Instance.new("ScrollingFrame")
questDetailFrame.Name = "QuestDetail"
questDetailFrame.Size = UDim2.new(1, -8, 1, -8)
questDetailFrame.Position = UDim2.new(0, 4, 0, 4)
questDetailFrame.BackgroundTransparency = 1
questDetailFrame.BorderSizePixel = 0
questDetailFrame.ScrollBarThickness = 3
questDetailFrame.ScrollBarImageColor3 = COLORS.Accent
questDetailFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
questDetailFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
questDetailFrame.ScrollingDirection = Enum.ScrollingDirection.Y
questDetailFrame.Parent = questBody

-- Компактный выбор квеста сверху окна описания
local questListFrame = Instance.new("ScrollingFrame")
questListFrame.Name = "QuestList"
questListFrame.Size = UDim2.new(1, -8, 0, QUEST_LIST_H)
questListFrame.Position = UDim2.new(0, 4, 0, 4)
questListFrame.BackgroundColor3 = Color3.fromRGB(35, 28, 55)
questListFrame.BackgroundTransparency = 0.15
questListFrame.BorderSizePixel = 0
questListFrame.ScrollBarThickness = 4
questListFrame.ScrollBarImageColor3 = COLORS.Accent
questListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
questListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
questListFrame.ScrollingDirection = Enum.ScrollingDirection.Y
questListFrame.ZIndex = 6
questListFrame.Parent = questBody

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 6)
listCorner.Parent = questListFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 2)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = questListFrame

local detailPadding = Instance.new("UIPadding")
detailPadding.PaddingTop = UDim.new(0, QUEST_LIST_H + 8)
detailPadding.PaddingBottom = UDim.new(0, 6)
detailPadding.PaddingLeft = UDim.new(0, 8)
detailPadding.PaddingRight = UDim.new(0, 8)
detailPadding.Parent = questDetailFrame

local detailLayout = Instance.new("UIListLayout")
detailLayout.Padding = UDim.new(0, 4)
detailLayout.SortOrder = Enum.SortOrder.LayoutOrder
detailLayout.Parent = questDetailFrame

questDetailFrame.ClipsDescendants = true

local actionFooter = Instance.new("Frame")
actionFooter.Name = "ActionFooter"
actionFooter.Size = UDim2.new(1, -20, 0, 22)
actionFooter.Position = UDim2.new(0, 10, 1, -24)
actionFooter.BackgroundTransparency = 1
actionFooter.ZIndex = 8
actionFooter.Visible = false
actionFooter.Parent = questPanel

-- Переменные для данных
local readyToTurnInIds = {}
local hasAvailableQuests = false

local function updateQuestMasterIndicator()
	local questMaster = workspace:FindFirstChild("QuestMaster")
	if not questMaster then return end
	local indicator = questMaster:FindFirstChild("QuestIndicator")
	if not indicator then return end
	local label = indicator:FindFirstChildOfClass("TextLabel")
	local hasReady = next(readyToTurnInIds) ~= nil
	local showQuestion = hasReady
	local showExclamation = (not hasReady) and hasAvailableQuests
	indicator.Enabled = showQuestion or showExclamation
	if label then
		if showQuestion then
			label.Text = "?"
			label.TextColor3 = Color3.fromRGB(255, 230, 80)
		elseif showExclamation then
			label.Text = "!"
			label.TextColor3 = Color3.fromRGB(255, 170, 60)
		end
		local stroke = label:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
		stroke.Name = "GlowStroke"
		stroke.Color = showQuestion and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 150, 50)
		stroke.Thickness = 3
		stroke.Parent = label
	end
end

local currentQuestData = {
	Available = {},
	Active = {},
	Completed = {}
}

-- ============================================
-- Функции отображения
-- ============================================

local function clearQuestList()
	for _, child in ipairs(questListFrame:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UICorner") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

local function clearDetail()
	for _, child in ipairs(questDetailFrame:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
	local footer = questPanel:FindFirstChild("ActionFooter")
	if footer then
		for _, c in ipairs(footer:GetChildren()) do
			c:Destroy()
		end
		footer.Visible = false
	end
end

local function getRarityColor(rarity)
	if rarity == "Legendary" then return COLORS.Legendary
	elseif rarity == "Epic" then return COLORS.Epic
	elseif rarity == "Rare" then return COLORS.Rare
	else return COLORS.Text end
end

local function createRewardLabel(parent, icon, text, color)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 16)
	frame.BackgroundTransparency = 1
	frame.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 4)
	layout.Parent = frame

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(0, 16, 0, 16)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = icon
	iconLabel.TextColor3 = color
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.TextScaled = true
	iconLabel.Parent = frame

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, -20, 0, 16)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = text
	textLabel.TextColor3 = color
	textLabel.Font = Enum.Font.Gotham
	textLabel.TextScaled = false
	textLabel.TextSize = 11
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.Parent = frame
end

local function showQuestDetail(quest, isActive, progress, readyToTurnIn)
	clearDetail()

	-- Название
	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(1, 0, 0, 18)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = quest.Name or "Unknown"
	nameLbl.TextColor3 = (quest.Type == "Story") and COLORS.Story or COLORS.Side
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextScaled = false
	nameLbl.TextSize = 14
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.Parent = questDetailFrame

	-- Тип и уровень
	local typeLbl = Instance.new("TextLabel")
	typeLbl.Size = UDim2.new(1, 0, 0, 14)
	typeLbl.BackgroundTransparency = 1
	typeLbl.Text = (quest.Type == "Story" and "Сюжетный" or "Побочный") .. " квест · Ур. " .. (quest.Level or 1)
	typeLbl.TextColor3 = COLORS.SubText
	typeLbl.Font = Enum.Font.Gotham
	typeLbl.TextScaled = false
	typeLbl.TextSize = 11
	typeLbl.TextXAlignment = Enum.TextXAlignment.Left
	typeLbl.Parent = questDetailFrame

	-- Описание
	local descLbl = Instance.new("TextLabel")
	descLbl.Size = UDim2.new(1, 0, 0, 0)
	descLbl.AutomaticSize = Enum.AutomaticSize.Y
	descLbl.BackgroundTransparency = 1
	descLbl.Text = quest.Description or ""
	descLbl.TextColor3 = COLORS.Text
	descLbl.Font = Enum.Font.Gotham
	descLbl.TextWrapped = true
	descLbl.TextScaled = false
	descLbl.TextSize = 12
	descLbl.TextXAlignment = Enum.TextXAlignment.Left
	descLbl.TextYAlignment = Enum.TextYAlignment.Top
	descLbl.Parent = questDetailFrame

	-- Цели
	local objTitle = Instance.new("TextLabel")
	objTitle.Size = UDim2.new(1, 0, 0, 14)
	objTitle.BackgroundTransparency = 1
	objTitle.Text = "Цели:"
	objTitle.TextColor3 = COLORS.Accent
	objTitle.Font = Enum.Font.GothamBold
	objTitle.TextScaled = false
	objTitle.TextSize = 12
	objTitle.TextXAlignment = Enum.TextXAlignment.Left
	objTitle.Parent = questDetailFrame

	if quest.Objectives then
		for i, obj in ipairs(quest.Objectives) do
			local objFrame = Instance.new("Frame")
			objFrame.Size = UDim2.new(1, 0, 0, 16)
			objFrame.BackgroundTransparency = 1
			objFrame.Parent = questDetailFrame

			local objText = obj.Type or "Objective"
			if obj.Type == "CatchSpirit" then objText = "Поймать духов: " .. obj.Count
			elseif obj.Type == "DefeatEnemies" then objText = "Победить врагов: " .. obj.Count
			elseif obj.Type == "CatchDifferentSpirits" then objText = "Поймать разных духов: " .. obj.Count
			elseif obj.Type == "CollectItem" then objText = "Собрать огненные кристаллы: " .. obj.Count
			elseif obj.Type == "LevelUpSpirit" then objText = "Прокачать духа до уровня: " .. (obj.TargetLevel or obj.Count)
			elseif obj.Type == "FindChests" then objText = "Найти сундуки: " .. obj.Count
			elseif obj.Type == "LevelUpSpirit" then objText = "Прокачать духа до ур. " .. (obj.TargetLevel or 10)
			elseif obj.Type == "FindChests" then objText = "Найти сундуки: " .. obj.Count
			end

			if isActive and progress and progress[i] then
				objText = objText .. " (" .. (progress[i].Current or 0) .. "/" .. (progress[i].Target or 1) .. ")"
			end

			local objLbl = Instance.new("TextLabel")
			objLbl.Size = UDim2.new(1, 0, 1, 0)
			objLbl.BackgroundTransparency = 1
			objLbl.Text = "• " .. objText
			objLbl.TextColor3 = COLORS.Text
			objLbl.Font = Enum.Font.Gotham
			objLbl.TextScaled = false
			objLbl.TextSize = 11
			objLbl.TextXAlignment = Enum.TextXAlignment.Left
			objLbl.Parent = objFrame
		end
	end

	-- Награды
	local rewTitle = Instance.new("TextLabel")
	rewTitle.Size = UDim2.new(1, 0, 0, 14)
	rewTitle.BackgroundTransparency = 1
	rewTitle.Text = "Награды:"
	rewTitle.TextColor3 = COLORS.Accent
	rewTitle.Font = Enum.Font.GothamBold
	rewTitle.TextScaled = false
	rewTitle.TextSize = 12
	rewTitle.TextXAlignment = Enum.TextXAlignment.Left
	rewTitle.Parent = questDetailFrame

	local rewardsFrame = Instance.new("Frame")
	rewardsFrame.Size = UDim2.new(1, 0, 0, 0)
	rewardsFrame.AutomaticSize = Enum.AutomaticSize.Y
	rewardsFrame.BackgroundTransparency = 1
	rewardsFrame.Parent = questDetailFrame

	local rewLayout = Instance.new("UIListLayout")
	rewLayout.Padding = UDim.new(0, 2)
	rewLayout.Parent = rewardsFrame

	local r = quest.Rewards
	if r then
		if r.Experience and r.Experience > 0 then
			createRewardLabel(rewardsFrame, "✦", "Опыт: +" .. r.Experience, COLORS.Experience)
		end
		if r.CopperCoins and r.CopperCoins > 0 then
			createRewardLabel(rewardsFrame, "●", "Медные монеты: +" .. r.CopperCoins, COLORS.Copper)
		end
		if r.SilverCoins and r.SilverCoins > 0 then
			createRewardLabel(rewardsFrame, "●", "Серебряные монеты: +" .. r.SilverCoins, COLORS.Silver)
		end
		if r.GoldCoins and r.GoldCoins > 0 then
			createRewardLabel(rewardsFrame, "●", "Золотые монеты: +" .. r.GoldCoins, COLORS.Gold)
		end
		if r.Reputation and r.Reputation > 0 then
			createRewardLabel(rewardsFrame, "★", "Репутация: +" .. r.Reputation, COLORS.Reputation)
		end
		if r.UniqueItems then
			for _, item in ipairs(r.UniqueItems) do
				local itemColor = getRarityColor(item.Rarity or "Rare")
				createRewardLabel(rewardsFrame, "◆", (item.Name or "Уникальный предмет") .. " x" .. (item.Quantity or 1), itemColor)
			end
		end
	end

	-- Кнопка принятия (только для доступных квестов)
	if readyToTurnIn then
		local footer = questPanel:FindFirstChild("ActionFooter")
		if footer then footer.Visible = true end
		local turnInBtn = Instance.new("TextButton")
		turnInBtn.Size = UDim2.new(1, 0, 1, 0)
		turnInBtn.BackgroundColor3 = COLORS.Gold
		turnInBtn.Text = "Сдать квест"
		turnInBtn.TextColor3 = Color3.fromRGB(30, 20, 10)
		turnInBtn.Font = Enum.Font.GothamBold
		turnInBtn.TextScaled = false
		turnInBtn.TextSize = 12
		turnInBtn.Parent = footer or questDetailFrame
		local turnInCorner = Instance.new("UICorner")
		turnInCorner.CornerRadius = UDim.new(0, 6)
		turnInCorner.Parent = turnInBtn
		turnInBtn.MouseButton1Click:Connect(function()
			QuestEvent:FireServer("TurnInQuest", {QuestId = quest.Id})
		end)
	elseif not isActive and not quest._completed then
		local footer = questPanel:FindFirstChild("ActionFooter")
		if footer then footer.Visible = true end
		local acceptBtn = Instance.new("TextButton")
		acceptBtn.Size = UDim2.new(1, 0, 1, 0)
		acceptBtn.BackgroundColor3 = COLORS.Accent
		acceptBtn.Text = "Принять квест"
		acceptBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		acceptBtn.Font = Enum.Font.GothamBold
		acceptBtn.TextScaled = false
		acceptBtn.TextSize = 12
		acceptBtn.Parent = footer or questDetailFrame

		local acceptCorner = Instance.new("UICorner")
		acceptCorner.CornerRadius = UDim.new(0, 8)
		acceptCorner.Parent = acceptBtn

		acceptBtn.MouseButton1Click:Connect(function()
			QuestEvent:FireServer("AcceptQuest", {QuestId = quest.Id})
		end)
	end
end

local selectedQuest = nil

local function createQuestEntry(quest, isActive, progress, order, readyToTurnIn)
	local entry = Instance.new("TextButton")
	entry.Size = UDim2.new(1, -6, 0, 26)
	entry.BackgroundColor3 = COLORS.Button
	entry.Text = ""
	entry.LayoutOrder = order or 0
	entry.ZIndex = 7
	entry.Parent = questListFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = entry

	local entryLayout = Instance.new("UIListLayout")
	entryLayout.Padding = UDim.new(0, 2)
	entryLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	entryLayout.Parent = entry

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(1, -12, 0, 12)
	nameLbl.Position = UDim2.new(0, 6, 0, 2)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = quest.Name or "Unknown"
	nameLbl.TextColor3 = (quest.Type == "Story") and COLORS.Story or COLORS.Side
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextScaled = false
	nameLbl.TextSize = 11
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
	nameLbl.Parent = entry

	local infoLbl = Instance.new("TextLabel")
	infoLbl.Size = UDim2.new(1, -12, 0, 11)
	infoLbl.Position = UDim2.new(0, 6, 0, 14)
	infoLbl.BackgroundTransparency = 1
	infoLbl.TextColor3 = COLORS.SubText
	infoLbl.Font = Enum.Font.Gotham
	infoLbl.TextScaled = false
	infoLbl.TextSize = 9
	infoLbl.TextXAlignment = Enum.TextXAlignment.Left
	infoLbl.TextTruncate = Enum.TextTruncate.AtEnd
	infoLbl.Parent = entry

	if readyToTurnIn then
		infoLbl.Text = "Готов к сдаче у квестора!"
		infoLbl.TextColor3 = COLORS.Gold
	elseif isActive then
		infoLbl.Text = "Ур. " .. (quest.Level or 1) .. " · В процессе"
	elseif quest._completed then
		infoLbl.Text = "Выполнено"
		infoLbl.TextColor3 = COLORS.Complete
	else
		infoLbl.Text = "Ур. " .. (quest.Level or 1) .. " · " .. (quest.Type == "Story" and "Сюжетный" or "Побочный")
	end

	entry.MouseButton1Click:Connect(function()
		selectedQuest = quest
		showQuestDetail(quest, isActive, progress, readyToTurnIn)
	end)

	entry.MouseEnter:Connect(function()
		entry.BackgroundColor3 = COLORS.ButtonHover
	end)

	entry.MouseLeave:Connect(function()
		entry.BackgroundColor3 = COLORS.Button
	end)

	return entry
end

function showQuestList(tabName)
	clearQuestList()
	clearDetail()

	if tabName == "Available" then
		for i, quest in ipairs(currentQuestData.Available) do
			createQuestEntry(quest, false, nil, i)
		end
	elseif tabName == "Active" then
		for i, questData in ipairs(currentQuestData.Active) do
			createQuestEntry(questData.Quest, true, questData.Progress, i, questData.ReadyToTurnIn)
		end
	elseif tabName == "Completed" then
		for i, quest in ipairs(currentQuestData.Completed) do
			quest._completed = true
			createQuestEntry(quest, false, nil, i)
		end
	end
end

-- ============================================
-- Уведомления
-- ============================================

local function showNotification(title, text, color)
	color = color or COLORS.Accent

	local notif = Instance.new("Frame")
	notif.Size = UDim2.new(0, 350, 0, 70)
	notif.Position = UDim2.new(0.5, -175, 0, -100)
	notif.BackgroundColor3 = COLORS.Background
	notif.BorderSizePixel = 0
	notif.Parent = screenGui

	local notifCorner = Instance.new("UICorner")
	notifCorner.CornerRadius = UDim.new(0, 10)
	notifCorner.Parent = notif

	local notifStroke = Instance.new("UIStroke")
	notifStroke.Color = color
	notifStroke.Thickness = 2
	notifStroke.Parent = notif

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Size = UDim2.new(1, -20, 0, 30)
	titleLbl.Position = UDim2.new(0, 10, 0, 8)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text = title
	titleLbl.TextColor3 = color
	titleLbl.Font = Enum.Font.FredokaOne
	titleLbl.TextScaled = true
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.Parent = notif

	local textLbl = Instance.new("TextLabel")
	textLbl.Size = UDim2.new(1, -20, 0, 25)
	textLbl.Position = UDim2.new(0, 10, 0, 38)
	textLbl.BackgroundTransparency = 1
	textLbl.Text = text
	textLbl.TextColor3 = COLORS.Text
	textLbl.Font = Enum.Font.Gotham
	textLbl.TextScaled = true
	textLbl.TextXAlignment = Enum.TextXAlignment.Left
	textLbl.Parent = notif

	-- Анимация появления
	TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -175, 0, 20)
	}):Play()

	task.delay(3, function()
		TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, -175, 0, -100)
		}):Play()
		task.wait(0.5)
		notif:Destroy()
	end)
end

-- ============================================
-- Обработка событий сервера
-- ============================================

QuestEvent.OnClientEvent:Connect(function(action, data)
	if action == "OpenQuestUI" then
		local readyCount = 0
		for _, questData in ipairs(data.Active or {}) do
			if questData.ReadyToTurnIn then readyCount += 1 end
		end
		if readyCount > 0 then
			dialogueLabel.Text = "Мика: Ого, ты уже всё сделал? Давай сдадим квест!"
		elseif #(data.Active or {}) > 0 then
			dialogueLabel.Text = "Мика: Удачи с заданием! Я буду ждать у стойки."
		else
			dialogueLabel.Text = "Мика: Добро пожаловать в Otaku Haven! О боже, ты выглядишь как настоящий герой!"
		end
		currentQuestData.Available = data.Available or {}
		currentQuestData.Active = data.Active or {}
		currentQuestData.Completed = data.Completed or {}

		hasAvailableQuests = #currentQuestData.Available > 0
		readyToTurnInIds = {}
		for _, questData in ipairs(currentQuestData.Active) do
			if questData.ReadyToTurnIn and questData.Quest then
				readyToTurnInIds[questData.Quest.Id] = true
			end
		end
		updateQuestMasterIndicator()

		local hasReady = next(readyToTurnInIds) ~= nil
		local preferredTab = data.PreferredTab
		if preferredTab == "Available" and #currentQuestData.Available > 0 then
			currentTab = "Available"
		elseif preferredTab == "Active" and #currentQuestData.Active > 0 then
			currentTab = "Active"
		elseif hasReady then
			currentTab = "Active"
		elseif #currentQuestData.Available > 0 then
			currentTab = "Available"
		elseif #currentQuestData.Active > 0 then
			currentTab = "Active"
		else
			currentTab = "Completed"
		end
		tabButtons.Available.BackgroundColor3 = (currentTab == "Available") and COLORS.ButtonHover or COLORS.Button
		tabButtons.Active.BackgroundColor3 = (currentTab == "Active") and COLORS.ButtonHover or COLORS.Button
		tabButtons.Completed.BackgroundColor3 = (currentTab == "Completed") and COLORS.ButtonHover or COLORS.Button

		questPanel.Visible = true
		startMikaFocus()
		showQuestList(currentTab)

		-- Анимация появления
		questPanel.Size = UDim2.new(0, 700, 0, 0)
		TweenService:Create(questPanel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 700, 0, 500)
		}):Play()

	elseif action == "QuestList" then
		currentQuestData.Available = data.Quests or {}
		hasAvailableQuests = #currentQuestData.Available > 0
		updateQuestMasterIndicator()
		if questPanel.Visible and currentTab == "Available" then showQuestList("Available") end

	elseif action == "QuestResult" then
		if data.Success and data.TurnIn then
			showNotification("Квест сдан!", data.Message or "", COLORS.Gold)
			QuestEvent:FireServer("GetActiveQuests", {})
			QuestEvent:FireServer("GetCompletedQuests", {})
		elseif data.Success then
			showNotification("Квест принят!", data.Message or "", COLORS.Complete)
			-- Обновляем UI
			QuestEvent:FireServer("GetQuests", {})
			QuestEvent:FireServer("GetActiveQuests", {})
		else
			showNotification("Ошибка", data.Message or "Не удалось принять квест", Color3.fromRGB(255, 100, 100))
		end

	elseif action == "QuestReadyToTurnIn" then
		if data.QuestId then readyToTurnInIds[data.QuestId] = true end
		updateQuestMasterIndicator()
		showNotification("Квест выполнен!", (data.QuestName or "Квест") .. " - сдайте его Мастеру Квестов", COLORS.Gold)
		QuestEvent:FireServer("GetActiveQuests", {})

	elseif action == "QuestProgress" then
		QuestEvent:FireServer("GetActiveQuests", {})

	elseif action == "QuestAccepted" then
		showNotification("Новый квест!", "Удачи в выполнении!", COLORS.Accent)

	elseif action == "QuestCompleted" then
		if data.QuestId then readyToTurnInIds[data.QuestId] = nil end
		updateQuestMasterIndicator()
		local questName = data.QuestName or "Квест"
		local rewardText = ""
		local r = data.Rewards
		if r then
			local parts = {}
			if r.Experience then table.insert(parts, "+" .. r.Experience .. " опыта") end
			if r.CopperCoins and r.CopperCoins > 0 then table.insert(parts, "+" .. r.CopperCoins .. " медных") end
			if r.SilverCoins and r.SilverCoins > 0 then table.insert(parts, "+" .. r.SilverCoins .. " серебра") end
			if r.GoldCoins and r.GoldCoins > 0 then table.insert(parts, "+" .. r.GoldCoins .. " золота") end
			if r.Reputation and r.Reputation > 0 then table.insert(parts, "+" .. r.Reputation .. " репутации") end
			rewardText = table.concat(parts, ", ")
		end
		showNotification("Награда получена!", questName .. "\n" .. rewardText, COLORS.Gold)

	elseif action == "CompletedQuests" then
		currentQuestData.Completed = data.Quests or {}
		if questPanel.Visible and currentTab == "Completed" then showQuestList("Completed") end

	elseif action == "ActiveQuests" then
		currentQuestData.Active = data.Quests or {}
		readyToTurnInIds = {}
		for _, questData in ipairs(currentQuestData.Active) do
			if questData.ReadyToTurnIn and questData.Quest then readyToTurnInIds[questData.Quest.Id] = true end
		end
		hasAvailableQuests = #currentQuestData.Available > 0
		updateQuestMasterIndicator()
		if questPanel.Visible then
			showQuestList(currentTab)
		end
	end
end)

task.defer(function()
	QuestEvent:FireServer("GetQuests", {})
	QuestEvent:FireServer("GetActiveQuests", {})
end)

print("Realm of Spirits - Quest UI загружен!")

