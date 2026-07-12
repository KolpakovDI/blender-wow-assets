-- ============================================
-- Realm of Spirits - Quest UI Client
-- Интерфейс системы квестов
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

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
questPanel.Size = UDim2.new(0, 700, 0, 500)
questPanel.Position = UDim2.new(0.5, -350, 0.5, -250)
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
titleLabel.Size = UDim2.new(1, -50, 0, 50)
titleLabel.Position = UDim2.new(0, 20, 0, 10)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Мика · Квестор"
titleLabel.TextColor3 = COLORS.Accent
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.FredokaOne
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = questPanel

local dialogueLabel = Instance.new("TextLabel")
dialogueLabel.Name = "MikaDialogue"
dialogueLabel.Size = UDim2.new(1, -40, 0, 48)
dialogueLabel.Position = UDim2.new(0, 20, 0, 52)
dialogueLabel.BackgroundColor3 = Color3.fromRGB(45, 35, 70)
dialogueLabel.BackgroundTransparency = 0.2
dialogueLabel.TextColor3 = COLORS.Text
dialogueLabel.TextWrapped = true
dialogueLabel.TextSize = 14
dialogueLabel.Font = Enum.Font.Gotham
dialogueLabel.TextXAlignment = Enum.TextXAlignment.Left
dialogueLabel.Text = "Мика: Добро пожаловать в Otaku Haven! Тебе как раз нужна помощь героя..."
dialogueLabel.Parent = questPanel
local dlgCorner = Instance.new("UICorner")
dlgCorner.CornerRadius = UDim.new(0, 8)
dlgCorner.Parent = dialogueLabel

-- Кнопка закрытия
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -50, 0, 15)
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
	questPanel.Visible = false
end)

-- Вкладки (Доступные / Активные / Выполненные)
local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1, -30, 0, 40)
tabContainer.Position = UDim2.new(0, 15, 0, 65)
tabContainer.BackgroundTransparency = 1
tabContainer.Parent = questPanel

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
tabLayout.Padding = UDim.new(0, 10)
tabLayout.Parent = tabContainer

local currentTab = "Available"
local tabButtons = {}

local function createTab(name, text)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 140, 0, 35)
	btn.BackgroundColor3 = COLORS.Button
	btn.Text = text
	btn.TextColor3 = COLORS.Text
	btn.Font = Enum.Font.GothamBold
	btn.TextScaled = true
	btn.Parent = tabContainer

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
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

-- Список квестов (левая панель)
local questListFrame = Instance.new("ScrollingFrame")
questListFrame.Name = "QuestList"
questListFrame.Size = UDim2.new(0, 280, 1, -130)
questListFrame.Position = UDim2.new(0, 15, 0, 115)
questListFrame.BackgroundColor3 = COLORS.Panel
questListFrame.BorderSizePixel = 0
questListFrame.ScrollBarThickness = 4
questListFrame.ScrollBarImageColor3 = COLORS.Accent
questListFrame.Parent = questPanel

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 8)
listCorner.Parent = questListFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = questListFrame

-- Детали квеста (правая панель)
local questDetailFrame = Instance.new("Frame")
questDetailFrame.Name = "QuestDetail"
questDetailFrame.Size = UDim2.new(0, 380, 1, -130)
questDetailFrame.Position = UDim2.new(0, 305, 0, 115)
questDetailFrame.BackgroundColor3 = COLORS.Panel
questDetailFrame.BorderSizePixel = 0
questDetailFrame.Parent = questPanel

local detailCorner = Instance.new("UICorner")
detailCorner.CornerRadius = UDim.new(0, 8)
detailCorner.Parent = questDetailFrame

local detailPadding = Instance.new("UIPadding")
detailPadding.PaddingTop = UDim.new(0, 15)
detailPadding.PaddingBottom = UDim.new(0, 15)
detailPadding.PaddingLeft = UDim.new(0, 15)
detailPadding.PaddingRight = UDim.new(0, 15)
detailPadding.Parent = questDetailFrame

local detailLayout = Instance.new("UIListLayout")
detailLayout.Padding = UDim.new(0, 10)
detailLayout.SortOrder = Enum.SortOrder.LayoutOrder
detailLayout.Parent = questDetailFrame

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
		if not child:IsA("UIListLayout") then
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
end

local function getRarityColor(rarity)
	if rarity == "Legendary" then return COLORS.Legendary
	elseif rarity == "Epic" then return COLORS.Epic
	elseif rarity == "Rare" then return COLORS.Rare
	else return COLORS.Text end
end

local function createRewardLabel(parent, icon, text, color)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, 25)
	frame.BackgroundTransparency = 1
	frame.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	layout.Parent = frame

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(0, 25, 0, 25)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = icon
	iconLabel.TextColor3 = color
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.TextScaled = true
	iconLabel.Parent = frame

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, -35, 0, 25)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = text
	textLabel.TextColor3 = color
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextScaled = true
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.Parent = frame
end

local function showQuestDetail(quest, isActive, progress, readyToTurnIn)
	clearDetail()

	-- Название
	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(1, 0, 0, 30)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = quest.Name or "Unknown"
	nameLbl.TextColor3 = (quest.Type == "Story") and COLORS.Story or COLORS.Side
	nameLbl.Font = Enum.Font.FredokaOne
	nameLbl.TextScaled = true
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.Parent = questDetailFrame

	-- Тип и уровень
	local typeLbl = Instance.new("TextLabel")
	typeLbl.Size = UDim2.new(1, 0, 0, 20)
	typeLbl.BackgroundTransparency = 1
	typeLbl.Text = (quest.Type == "Story" and "Сюжетный" or "Побочный") .. " квест · Ур. " .. (quest.Level or 1)
	typeLbl.TextColor3 = COLORS.SubText
	typeLbl.Font = Enum.Font.Gotham
	typeLbl.TextScaled = true
	typeLbl.TextXAlignment = Enum.TextXAlignment.Left
	typeLbl.Parent = questDetailFrame

	-- Описание
	local descLbl = Instance.new("TextLabel")
	descLbl.Size = UDim2.new(1, 0, 0, 50)
	descLbl.BackgroundTransparency = 1
	descLbl.Text = quest.Description or ""
	descLbl.TextColor3 = COLORS.Text
	descLbl.Font = Enum.Font.Gotham
	descLbl.TextWrapped = true
	descLbl.TextScaled = true
	descLbl.TextXAlignment = Enum.TextXAlignment.Left
	descLbl.TextYAlignment = Enum.TextYAlignment.Top
	descLbl.Parent = questDetailFrame

	-- Цели
	local objTitle = Instance.new("TextLabel")
	objTitle.Size = UDim2.new(1, 0, 0, 20)
	objTitle.BackgroundTransparency = 1
	objTitle.Text = "Цели:"
	objTitle.TextColor3 = COLORS.Accent
	objTitle.Font = Enum.Font.GothamBold
	objTitle.TextScaled = true
	objTitle.TextXAlignment = Enum.TextXAlignment.Left
	objTitle.Parent = questDetailFrame

	if quest.Objectives then
		for i, obj in ipairs(quest.Objectives) do
			local objFrame = Instance.new("Frame")
			objFrame.Size = UDim2.new(1, 0, 0, 25)
			objFrame.BackgroundTransparency = 1
			objFrame.Parent = questDetailFrame

			local objText = obj.Type or "Objective"
			if obj.Type == "CatchSpirit" then objText = "Поймать духов: " .. obj.Count
			elseif obj.Type == "DefeatEnemies" then objText = "Победить врагов: " .. obj.Count
			elseif obj.Type == "CatchDifferentSpirits" then objText = "Поймать разных духов: " .. obj.Count
			elseif obj.Type == "CollectItem" then objText = "Собрать предметы: " .. obj.Count
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
			objLbl.TextScaled = true
			objLbl.TextXAlignment = Enum.TextXAlignment.Left
			objLbl.Parent = objFrame
		end
	end

	-- Награды
	local rewTitle = Instance.new("TextLabel")
	rewTitle.Size = UDim2.new(1, 0, 0, 20)
	rewTitle.BackgroundTransparency = 1
	rewTitle.Text = "Награды:"
	rewTitle.TextColor3 = COLORS.Accent
	rewTitle.Font = Enum.Font.GothamBold
	rewTitle.TextScaled = true
	rewTitle.TextXAlignment = Enum.TextXAlignment.Left
	rewTitle.Parent = questDetailFrame

	local rewardsFrame = Instance.new("Frame")
	rewardsFrame.Size = UDim2.new(1, 0, 0, 120)
	rewardsFrame.BackgroundTransparency = 1
	rewardsFrame.Parent = questDetailFrame

	local rewLayout = Instance.new("UIListLayout")
	rewLayout.Padding = UDim.new(0, 5)
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
		local turnInBtn = Instance.new("TextButton")
		turnInBtn.Size = UDim2.new(1, 0, 0, 40)
		turnInBtn.BackgroundColor3 = COLORS.Gold
		turnInBtn.Text = "Сдать квест"
		turnInBtn.TextColor3 = Color3.fromRGB(30, 20, 10)
		turnInBtn.Font = Enum.Font.FredokaOne
		turnInBtn.TextScaled = true
		turnInBtn.Parent = questDetailFrame
		local turnInCorner = Instance.new("UICorner")
		turnInCorner.CornerRadius = UDim.new(0, 8)
		turnInCorner.Parent = turnInBtn
		turnInBtn.MouseButton1Click:Connect(function()
			QuestEvent:FireServer("TurnInQuest", {QuestId = quest.Id})
		end)
	elseif not isActive and not quest._completed then
		local acceptBtn = Instance.new("TextButton")
		acceptBtn.Size = UDim2.new(1, 0, 0, 40)
		acceptBtn.BackgroundColor3 = COLORS.Accent
		acceptBtn.Text = "Принять квест"
		acceptBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		acceptBtn.Font = Enum.Font.FredokaOne
		acceptBtn.TextScaled = true
		acceptBtn.Parent = questDetailFrame

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
	entry.Size = UDim2.new(1, -10, 0, 50)
	entry.BackgroundColor3 = COLORS.Button
	entry.Text = ""
	entry.LayoutOrder = order or 0
	entry.Parent = questListFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = entry

	local entryLayout = Instance.new("UIListLayout")
	entryLayout.Padding = UDim.new(0, 2)
	entryLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	entryLayout.Parent = entry

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(1, -16, 0, 22)
	nameLbl.Position = UDim2.new(0, 8, 0, 4)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = quest.Name or "Unknown"
	nameLbl.TextColor3 = (quest.Type == "Story") and COLORS.Story or COLORS.Side
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextScaled = true
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.Parent = entry

	local infoLbl = Instance.new("TextLabel")
	infoLbl.Size = UDim2.new(1, -16, 0, 18)
	infoLbl.Position = UDim2.new(0, 8, 0, 26)
	infoLbl.BackgroundTransparency = 1
	infoLbl.TextColor3 = COLORS.SubText
	infoLbl.Font = Enum.Font.Gotham
	infoLbl.TextScaled = true
	infoLbl.TextXAlignment = Enum.TextXAlignment.Left
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
