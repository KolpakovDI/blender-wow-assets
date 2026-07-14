-- ============================================
-- Realm of Spirits - UI Controller
-- Управление интерфейсом с DataStore
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- RemoteEvents (используем папку RealmOfSpirits)
local realmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local CatchSpiritEvent = realmFolder:WaitForChild("CatchSpirit")
local BattleEvent = realmFolder:WaitForChild("Battle")
local DataEvent = realmFolder:WaitForChild("DataSync")
local EvolutionEvent = realmFolder:WaitForChild("EvolveSpirit")
local LevelingEvent = realmFolder:WaitForChild("Leveling")
local RankEvent = realmFolder:WaitForChild("Rank")
local TradeEvent = realmFolder:WaitForChild("Trade")

local SpiritDatabaseModule = require(realmFolder:WaitForChild("SpiritDatabase"))
local WoWUITheme = require(realmFolder:WaitForChild("WoWUITheme"))
local function GetSpiritInfo(id)
	return SpiritDatabaseModule.GetDisplay(id) or SpiritDatabaseModule.Get(id)
end

-- Маппинг числового ранга в буквенный
local RankNames = {[1] = "D", [2] = "C", [3] = "B", [4] = "A", [5] = "S", [6] = "SS", [7] = "SSS"}

-- Иконки духов для меню (цвет + эмодзи по элементу)
local SpiritIcons = {
	[1] = {Color = Color3.fromRGB(255, 100, 50), Emoji = "🔥"},
	[2] = {Color = Color3.fromRGB(100, 200, 255), Emoji = "❄️"},
	[3] = {Color = Color3.fromRGB(100, 50, 150), Emoji = "🌑"},
	[4] = {Color = Color3.fromRGB(200, 200, 100), Emoji = "⚡"},
	[5] = {Color = Color3.fromRGB(255, 255, 200), Emoji = "✨"},
	[101] = {Color = Color3.fromRGB(255, 120, 50), Emoji = "🔥"},
	[102] = {Color = Color3.fromRGB(100, 200, 255), Emoji = "❄️"},
	[103] = {Color = Color3.fromRGB(100, 50, 150), Emoji = "🌑"},
	[104] = {Color = Color3.fromRGB(200, 200, 100), Emoji = "⚡"},
	[105] = {Color = Color3.fromRGB(255, 255, 200), Emoji = "✨"},
}

-- ============================================
-- Данные игрока (клиент)
-- ============================================
local PlayerData = {}
local CurrentBattle = nil
local suppressBattleUpdates = false
local hasDataBeenLoaded = false

-- ============================================
-- Создание GUI
-- ============================================

local function CreateScreenGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "RealmOfSpiritsUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	return screenGui
end

local function CreateFrame(parent, name, position, size, backgroundColor)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Position = position
	frame.Size = size
	frame.BackgroundColor3 = backgroundColor or Color3.fromRGB(30, 30, 30)
	frame.BorderSizePixel = 0
	frame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	return frame
end

local function CreateTextLabel(parent, name, position, size, text, textColor, textSize)
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = name
	textLabel.Position = position
	textLabel.Size = size
	textLabel.Text = text
	textLabel.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
	textLabel.TextSize = textSize or 14
	textLabel.BackgroundTransparency = 1
	textLabel.Parent = parent

	return textLabel
end

local function CreateTextButton(parent, name, position, size, text, buttonColor, iconEmoji)
	local textButton = Instance.new("TextButton")
	textButton.Name = name
	textButton.Position = position
	textButton.Size = size
	textButton.Text = ""
	textButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	textButton.TextSize = 14
	textButton.BackgroundColor3 = buttonColor or Color3.fromRGB(70, 130, 180)
	textButton.BorderSizePixel = 0
	textButton.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = textButton

	if iconEmoji then
		local iconLabel = Instance.new("TextLabel")
		iconLabel.Name = "IconLabel"
		iconLabel.Position = UDim2.new(0, 0, 0, 2)
		iconLabel.Size = UDim2.new(1, 0, 0.6, 0)
		iconLabel.Text = iconEmoji
		iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		iconLabel.TextSize = 22
		iconLabel.BackgroundTransparency = 1
		iconLabel.Parent = textButton

		local textLabel = Instance.new("TextLabel")
		textLabel.Name = "ButtonLabel"
		textLabel.Position = UDim2.new(0, 0, 0.6, 0)
		textLabel.Size = UDim2.new(1, 0, 0.4, 0)
		textLabel.Text = text
		textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		textLabel.TextSize = 10
		textLabel.BackgroundTransparency = 1
		textLabel.Parent = textButton
	else
		textButton.Text = text
	end

	return textButton
end

-- ============================================
-- Основной интерфейс
-- ============================================

local screenGui = CreateScreenGui()

-- Фон экрана
local mainFrame = CreateFrame(screenGui, "MainFrame", 
	UDim2.new(0, 0, 0, 0), 
	UDim2.new(1, 0, 1, 0), 
	Color3.fromRGB(20, 20, 30)
)
mainFrame.BackgroundTransparency = 1
mainFrame.Active = false

-- HP/MP — только в battleFrame (режим боя)
local hpFill, mpFill

-- ============================================
-- Панель духов
-- ============================================

local spiritsFrame = CreateFrame(screenGui, "SpiritsFrame",
	UDim2.new(1, -100, 0.5, -150),
	UDim2.new(0, 90, 0, 300),
	WoWUITheme.Colors.Wood
)
WoWUITheme.StylePanel(spiritsFrame, "wood")

local spiritsTitle = CreateTextLabel(spiritsFrame, "SpiritsTitle",
	UDim2.new(0, 10, 0, 5),
	UDim2.new(0.9, 0, 0, 25),
	"Мои духи",
	Color3.fromRGB(255, 215, 0),
	16
)

-- Слоты для духов (вертикально)
local OpenSpiritDetail -- forward declaration
local ShowNotification -- forward declaration
local selectedSpiritIndex = nil

for i = 1, 4 do
	local slot = CreateFrame(spiritsFrame, "SpiritSlot" .. i,
		UDim2.new(0, 10, 0, 30 + (i-1) * 65),
		UDim2.new(0, 70, 0, 60),
		Color3.fromRGB(60, 60, 70)
	)

	-- Иконка духа (цветной круг с эмодзи)
	local iconFrame = Instance.new("Frame")
	iconFrame.Name = "SpiritIcon"
	iconFrame.Size = UDim2.new(0, 36, 0, 36)
	iconFrame.Position = UDim2.new(0.5, -18, 0, 4)
	iconFrame.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	iconFrame.BorderSizePixel = 0
	iconFrame.Parent = slot
	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(1, 0)
	iconCorner.Parent = iconFrame

	local iconEmoji = Instance.new("TextLabel")
	iconEmoji.Name = "IconEmoji"
	iconEmoji.Size = UDim2.new(1, 0, 1, 0)
	iconEmoji.BackgroundTransparency = 1
	iconEmoji.Text = "?"
	iconEmoji.TextColor3 = Color3.fromRGB(255, 255, 255)
	iconEmoji.TextSize = 18
	iconEmoji.Parent = iconFrame

	-- Имя и уровень духа
	local spiritNameLabel = Instance.new("TextLabel")
	spiritNameLabel.Name = "SpiritNameLabel"
	spiritNameLabel.Size = UDim2.new(1, 0, 0, 16)
	spiritNameLabel.Position = UDim2.new(0, 0, 0, 42)
	spiritNameLabel.BackgroundTransparency = 1
	spiritNameLabel.Text = tostring(i)
	spiritNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	spiritNameLabel.TextSize = 9
	spiritNameLabel.Parent = slot

	-- TextButton поверх слота для перехвата кликов мыши
	local slotLabel = Instance.new("TextButton")
	slotLabel.Name = "SlotLabel"
	slotLabel.Position = UDim2.new(0, 0, 0, 0)
	slotLabel.Size = UDim2.new(1, 0, 1, 0)
	slotLabel.Text = ""
	slotLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	slotLabel.TextSize = 12
	slotLabel.BackgroundTransparency = 1
	slotLabel.AutoButtonColor = false
	slotLabel.Parent = slot

	-- Левый клик по слоту духа открывает панель свойств
	slotLabel.MouseButton1Click:Connect(function()
		selectedSpiritIndex = i
		if OpenSpiritDetail then
			OpenSpiritDetail(i)
		end
	end)
end

for i = 1, 4 do
	local slot = spiritsFrame:FindFirstChild("SpiritSlot" .. i)
	if slot then WoWUITheme.StylePanel(slot, "stone") end
end

-- Панель сумок (9 слотов) на месте старого блока духов
local bagsFrame = CreateFrame(screenGui, "BagsFrame",
	UDim2.new(1, -285, 1, -310),
	UDim2.new(0, 270, 0, 300),
	WoWUITheme.Colors.Wood
)
WoWUITheme.StylePanel(bagsFrame, "wood")

CreateTextLabel(bagsFrame, "BagsTitle",
	UDim2.new(0, 10, 0, 5),
	UDim2.new(0.9, 0, 0, 25),
	"Сумки",
	Color3.fromRGB(255, 215, 0),
	16
)

local bagCapacities = {6, 8, 10, 12, 14, 16, 18, 20, 24}
local bagSlots = {}
local currentBagContents = {}
local openedBagIndex = nil
local OpenBag

local bagContentFrame = CreateFrame(screenGui, "BagContentFrame",
	UDim2.new(0.5, -190, 0.5, -145),
	UDim2.new(0, 380, 0, 290),
	Color3.fromRGB(28, 28, 40)
)
bagContentFrame.Visible = false
WoWUITheme.StylePanel(bagContentFrame, "stone")

local bagContentTitle = CreateTextLabel(bagContentFrame, "BagContentTitle",
	UDim2.new(0, 12, 0, 8),
	UDim2.new(1, -24, 0, 26),
	"Сумка",
	Color3.fromRGB(255, 215, 0),
	18
)
bagContentTitle.TextXAlignment = Enum.TextXAlignment.Left

local bagContentList = Instance.new("Frame")
bagContentList.Name = "BagContentList"
bagContentList.Position = UDim2.new(0, 12, 0, 42)
bagContentList.Size = UDim2.new(1, -24, 1, -138)
bagContentList.BackgroundColor3 = Color3.fromRGB(36, 36, 50)
bagContentList.BorderSizePixel = 0
bagContentList.Parent = bagContentFrame
local bagContentCorner = Instance.new("UICorner")
bagContentCorner.CornerRadius = UDim.new(0, 8)
bagContentCorner.Parent = bagContentList

local bagCurrencyPanel = CreateFrame(bagContentFrame, "BagCurrencyPanel",
	UDim2.new(0, 12, 1, -88),
	UDim2.new(1, -24, 0, 36),
	Color3.fromRGB(50, 45, 32)
)
WoWUITheme.StylePanel(bagCurrencyPanel, "wood")

local bagCurrencyLabel = CreateTextLabel(bagCurrencyPanel, "BagCurrencyLabel",
	UDim2.new(0, 10, 0, 0),
	UDim2.new(1, -20, 1, 0),
	"💰 0 🥇 | 0 🥈 | 0 🥉",
	Color3.fromRGB(255, 230, 170),
	13
)
bagCurrencyLabel.TextXAlignment = Enum.TextXAlignment.Left

local closeBagContentButton = CreateTextButton(bagContentFrame, "CloseBagContentButton",
	UDim2.new(0.5, -60, 1, -44),
	UDim2.new(0, 120, 0, 32),
	"Закрыть",
	Color3.fromRGB(100, 100, 100),
	"❌"
)

local function BuildBagContentsFromInventory(inventory, bags)
	local packed = {}
	for i = 1, 9 do
		local bagInfo = bags and bags[i]
		packed[i] = {
			Capacity = (bagInfo and bagInfo.Capacity) or bagCapacities[i],
			Items = {},
		}
	end

	local bagIndex = 1
	for _, item in ipairs(inventory or {}) do
		while bagIndex <= 9 and #packed[bagIndex].Items >= packed[bagIndex].Capacity do
			bagIndex = bagIndex + 1
		end
		if bagIndex > 9 then
			break
		end

		local shopInfo = SpiritDatabaseModule.ShopItems and SpiritDatabaseModule.ShopItems[item.Id]
		table.insert(packed[bagIndex].Items, {
			Id = item.Id,
			Name = (shopInfo and shopInfo.Name) or ("Предмет #" .. tostring(item.Id)),
			Quantity = tonumber(item.Quantity) or 1,
		})
	end

	return packed
end

local function RefreshBagContentView(index)
	local bag = currentBagContents[index] or {Capacity = bagCapacities[index], Items = {}}
	bagContentTitle.Text = string.format("Сумка %d (%d слотов)", index, bag.Capacity)

	for _, child in ipairs(bagContentList:GetChildren()) do
		child:Destroy()
	end

	if #bag.Items == 0 then
		local emptyLabel = CreateTextLabel(bagContentList, "BagEmpty",
			UDim2.new(0, 10, 0, 10),
			UDim2.new(1, -20, 0, 24),
			"Пусто",
			Color3.fromRGB(180, 180, 200),
			14
		)
		emptyLabel.TextXAlignment = Enum.TextXAlignment.Left
		return
	end

	for i, item in ipairs(bag.Items) do
		local row = CreateTextLabel(bagContentList, "BagItemRow" .. i,
			UDim2.new(0, 10, 0, 8 + (i - 1) * 24),
			UDim2.new(1, -20, 0, 22),
			string.format("%d. %s x%d", i, item.Name, item.Quantity),
			Color3.fromRGB(220, 220, 240),
			13
		)
		row.TextXAlignment = Enum.TextXAlignment.Left
	end
end

OpenBag = function(index)
	openedBagIndex = index
	bagContentFrame.Visible = true
	RefreshBagContentView(index)
end

closeBagContentButton.MouseButton1Click:Connect(function()
	bagContentFrame.Visible = false
	openedBagIndex = nil
end)

for i = 1, 9 do
	local col = (i - 1) % 3
	local row = math.floor((i - 1) / 3)
	local slot = CreateFrame(bagsFrame, "BagSlot" .. i,
		UDim2.new(0, 10 + col * 85, 0, 35 + row * 85),
		UDim2.new(0, 78, 0, 78),
		Color3.fromRGB(60, 60, 70)
	)
	WoWUITheme.StylePanel(slot, "stone")

	local icon = CreateTextLabel(slot, "BagIcon",
		UDim2.new(0, 0, 0, 6),
		UDim2.new(1, 0, 0, 28),
		"🎒",
		Color3.fromRGB(255, 255, 255),
		22
	)
	icon.TextXAlignment = Enum.TextXAlignment.Center

	local cap = CreateTextLabel(slot, "BagCapacity",
		UDim2.new(0, 0, 0, 38),
		UDim2.new(1, 0, 0, 18),
		bagCapacities[i] .. " слотов",
		Color3.fromRGB(210, 210, 210),
		11
	)
	cap.TextXAlignment = Enum.TextXAlignment.Center

	local usage = CreateTextLabel(slot, "BagUsage",
		UDim2.new(0, 0, 0, 56),
		UDim2.new(1, 0, 0, 16),
		"0/" .. bagCapacities[i],
		Color3.fromRGB(170, 230, 170),
		10
	)
	usage.TextXAlignment = Enum.TextXAlignment.Center

	local clickArea = Instance.new("TextButton")
	clickArea.Name = "BagClickArea"
	clickArea.Size = UDim2.new(1, 0, 1, 0)
	clickArea.Position = UDim2.new(0, 0, 0, 0)
	clickArea.BackgroundTransparency = 1
	clickArea.Text = ""
	clickArea.AutoButtonColor = false
	clickArea.Parent = slot
	clickArea.MouseButton1Click:Connect(function()
		if OpenBag then OpenBag(i) end
	end)

	bagSlots[i] = slot
end

local function UpdateBagSlots(bags)
	currentBagContents = BuildBagContentsFromInventory(PlayerData.Inventory, bags)
	for i = 1, 9 do
		local slot = bagSlots[i]
		local capLabel = slot and slot:FindFirstChild("BagCapacity")
		local usageLabel = slot and slot:FindFirstChild("BagUsage")
		local bagInfo = currentBagContents[i]
		local capacity = (bagInfo and bagInfo.Capacity) or bagCapacities[i]
		local used = bagInfo and #bagInfo.Items or 0
		if capLabel then
			capLabel.Text = tostring(capacity) .. " слотов"
		end
		if usageLabel then
			usageLabel.Text = string.format("%d/%d", used, capacity)
		end
	end
	if openedBagIndex then
		RefreshBagContentView(openedBagIndex)
	end
end

-- Глобальный перехват правого клика
-- Studio может перехватывать правый клик на GUI, поэтому используем глобальный обработчик
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		local mousePos = UserInputService:GetMouseLocation()
		-- Проверяем, наведён ли курсор на какой-либо слот духа
		for i = 1, 4 do
			local slot = spiritsFrame:FindFirstChild("SpiritSlot" .. i)
			if slot then
				local absPos = slot.AbsolutePosition
				local absSize = slot.AbsoluteSize
				if mousePos.X >= absPos.X and mousePos.X <= absPos.X + absSize.X
				   and mousePos.Y >= absPos.Y and mousePos.Y <= absPos.Y + absSize.Y then
					selectedSpiritIndex = i
					if OpenSpiritDetail then
						OpenSpiritDetail(i)
					end
					break
				end
			end
		end
	end
end)

-- ============================================
-- Полоска опыта (над кнопками действий)
-- ============================================

local expBarFrame = CreateFrame(screenGui, "ExpBarFrame",
	UDim2.new(0.5, -275, 1, -98),
	UDim2.new(0, 550, 0, 26),
	WoWUITheme.Colors.Wood
)
WoWUITheme.StylePanel(expBarFrame, "wood")

local expLevelLabel = CreateTextLabel(expBarFrame, "ExpLevelLabel",
	UDim2.new(0, 8, 0, 0),
	UDim2.new(0, 52, 1, 0),
	"Ур. 1",
	WoWUITheme.Colors.TextGold,
	14
)

local _, expBarFill = WoWUITheme.CreateResourceBar(expBarFrame, "ExpBar",
	UDim2.new(0, 58, 0.5, -6),
	UDim2.new(1, -66, 0, 12),
	Color3.fromRGB(80, 160, 60),
	Color3.fromRGB(130, 230, 90)
)
if not expBarFill then
	expBarFill = Instance.new("Frame")
	expBarFill.Size = UDim2.new(1, -66, 0, 12)
	expBarFill.Position = UDim2.new(0, 58, 0.5, -6)
	expBarFill.BackgroundColor3 = Color3.fromRGB(80, 160, 60)
	expBarFill.BorderSizePixel = 0
	expBarFill.Parent = expBarFrame
end
expBarFill.Name = "ExpBarFill"
expBarFill.ZIndex = 2

local expBarLabel = CreateTextLabel(expBarFrame, "ExpBarLabel",
	UDim2.new(0, 58, 0, 0),
	UDim2.new(1, -66, 1, 0),
	"0 / 100",
	Color3.fromRGB(255, 255, 255),
	11
)
expBarLabel.ZIndex = 5

local profileButton = CreateTextButton(expBarFrame, "ProfileButton",
	UDim2.new(0, -62, 0, -4),
	UDim2.new(0, 56, 0, 34),
	"Профиль",
	Color3.fromRGB(90, 120, 180),
	"🧑"
)
WoWUITheme.StyleActionButton(profileButton)

-- ============================================
-- Кнопки действий
-- ============================================

local actionsFrame = CreateFrame(screenGui, "ActionsFrame",
	UDim2.new(0.5, -275, 1, -70),
	UDim2.new(0, 550, 0, 50),
	WoWUITheme.Colors.Stone
)
WoWUITheme.StylePanel(actionsFrame, "stone")

-- Кнопка ловли
local catchButton = CreateTextButton(actionsFrame, "CatchButton",
	UDim2.new(0, 10, 0, 5),
	UDim2.new(0, 80, 0, 40),
	"Поймать [E]",
	Color3.fromRGB(70, 180, 70),
	"🎯"
)

-- Кнопка битвы
local battleButton = CreateTextButton(actionsFrame, "BattleButton",
	UDim2.new(0, 100, 0, 5),
	UDim2.new(0, 80, 0, 40),
	"Бой [F]",
	Color3.fromRGB(180, 70, 70),
	"⚔️"
)

-- Кнопка меню
local menuButton = CreateTextButton(actionsFrame, "MenuButton",
	UDim2.new(0, 190, 0, 5),
	UDim2.new(0, 80, 0, 40),
	"Меню [Tab]",
	Color3.fromRGB(70, 130, 180),
	"📜"
)

WoWUITheme.StyleActionButton(catchButton)
WoWUITheme.StyleActionButton(battleButton)
WoWUITheme.StyleActionButton(menuButton)

-- ============================================
-- Боевой интерфейс (нижняя панель, не перекрывает центр экрана)
-- ============================================

local battleFrame = CreateFrame(screenGui, "BattleFrame",
	UDim2.new(0, 0, 1, -170),
	UDim2.new(1, 0, 0, 170),
	WoWUITheme.Colors.Stone
)
battleFrame.Visible = false
battleFrame.BackgroundTransparency = 0.1
WoWUITheme.StylePanel(battleFrame, "stone")

local battleTitle = CreateTextLabel(battleFrame, "BattleTitle",
	UDim2.new(0, 15, 0, 5),
	UDim2.new(0, 100, 0, 25),
	"БОЙ!",
	Color3.fromRGB(255, 50, 50),
	20
)

-- Лог боя (центр сверху панели)
local battleLogLabel = CreateTextLabel(battleFrame, "BattleLogLabel",
	UDim2.new(0.3, 0, 0, 5),
	UDim2.new(0.4, 0, 0, 25),
	"",
	Color3.fromRGB(200, 200, 200),
	14
)

-- HP/MP игрока (только в режиме боя)
local battleStatsFrame = CreateFrame(battleFrame, "BattleStatsFrame",
	UDim2.new(0, 15, 0, 32),
	UDim2.new(0, 300, 0, 68),
	WoWUITheme.Colors.Wood
)
WoWUITheme.StylePanel(battleStatsFrame, "wood")
WoWUITheme.CreatePortraitRing(battleStatsFrame, "Portrait", UDim2.fromOffset(6, 6), UDim2.fromOffset(56, 56))

CreateTextLabel(battleStatsFrame, "HPLabel",
	UDim2.new(0, 68, 0, 8), UDim2.fromOffset(24, 16), "HP", WoWUITheme.Colors.TextGold, 12)
local _, hpFillNode = WoWUITheme.CreateResourceBar(battleStatsFrame, "HPBar",
	UDim2.new(0, 68, 0, 24), UDim2.new(1, -76, 0, 14),
	WoWUITheme.Colors.HP, WoWUITheme.Colors.HPBright)
hpFillNode.Name = "HPFill"
hpFill = hpFillNode

CreateTextLabel(battleStatsFrame, "MPLabel",
	UDim2.new(0, 68, 0, 42), UDim2.fromOffset(24, 16), "MP", WoWUITheme.Colors.TextGold, 12)
local _, mpFillNode = WoWUITheme.CreateResourceBar(battleStatsFrame, "MPBar",
	UDim2.new(0, 68, 0, 46), UDim2.new(1, -76, 0, 14),
	WoWUITheme.Colors.MP, WoWUITheme.Colors.MPBright)
mpFillNode.Name = "MPFill"
mpFill = mpFillNode

-- ============================================
-- Кнопки действий (центр-низ панели)
-- ============================================

local attack1Button = CreateTextButton(battleFrame, "Attack1Button",
	UDim2.new(0.28, 5, 0, 130),
	UDim2.new(0.1, 0, 0, 35),
	"Коготь Духа",
	Color3.fromRGB(180, 70, 70),
	"🐾"
)

local attack2Button = CreateTextButton(battleFrame, "Attack2Button",
	UDim2.new(0.38, 0, 0, 130),
	UDim2.new(0.1, 0, 0, 35),
	"Призрачный Вихрь",
	Color3.fromRGB(180, 70, 70),
	"🌀"
)

local attack3Button = CreateTextButton(battleFrame, "Attack3Button",
	UDim2.new(0.48, -5, 0, 130),
	UDim2.new(0.1, 0, 0, 35),
	"Навык 3",
	Color3.fromRGB(180, 70, 70),
	"✦"
)

local fleeButton = CreateTextButton(battleFrame, "FleeButton",
	UDim2.new(0.58, -5, 0, 130),
	UDim2.new(0.1, 0, 0, 35),
	"Побег",
	Color3.fromRGB(100, 100, 180),
	"🏃"
)
WoWUITheme.StyleActionButton(attack1Button)
WoWUITheme.StyleActionButton(attack2Button)
WoWUITheme.StyleActionButton(attack3Button)
WoWUITheme.StyleActionButton(fleeButton)

-- ============================================
-- Подсказки
-- ============================================

local hintFrame = CreateFrame(screenGui, "HintFrame",
	UDim2.new(0.5, -150, 0.5, -25),
	UDim2.new(0, 300, 0, 50),
	Color3.fromRGB(40, 40, 50)
)
hintFrame.Visible = false
hintFrame.BackgroundTransparency = 0.5

local hintText = CreateTextLabel(hintFrame, "HintText",
	UDim2.new(0, 10, 0, 0),
	UDim2.new(0.9, 0, 1, 0),
	"",
	Color3.fromRGB(255, 255, 255),
	14
)

-- ============================================
-- Переключение режима боя (скрывает основной UI, показывает боевой)
-- ============================================

local mainUIElements = {expBarFrame, spiritsFrame, bagsFrame, actionsFrame, hintFrame}

local function SetBattleMode(enabled)
	if enabled then
		for _, element in ipairs(mainUIElements) do
			element.Visible = false
		end
		local sdf = screenGui:FindFirstChild("SpiritDetailFrame")
		if sdf then sdf.Visible = false end
		local pf = screenGui:FindFirstChild("ProfileFrame")
		if pf then pf.Visible = false end
		local bcf = screenGui:FindFirstChild("BagContentFrame")
		if bcf then bcf.Visible = false end
		battleFrame.Visible = true
	else
		for _, element in ipairs(mainUIElements) do
			element.Visible = true
		end
		battleFrame.Visible = false
	end
end

local UpdateHint
local UpdateBattleLog

local function EnterNormalMode()
	suppressBattleUpdates = true
	SetBattleMode(false)
	CurrentBattle = nil
	if UpdateBattleLog then
		UpdateBattleLog("")
	end
	local hint = player:GetAttribute("TargetHint")
	if UpdateHint then
		UpdateHint((hint and hint ~= "") and hint or "")
	end
end

-- ============================================
-- Панель свойств духа (открывается по правому клику на слот)
-- ============================================

local spiritDetailFrame = CreateFrame(screenGui, "SpiritDetailFrame",
	UDim2.new(0.5, -200, 0.5, -185),
	UDim2.new(0, 400, 0, 370),
	Color3.fromRGB(30, 30, 40)
)
spiritDetailFrame.Visible = false

local spiritDetailTitle = CreateTextLabel(spiritDetailFrame, "SpiritDetailTitle",
	UDim2.new(0, 10, 0, 10),
	UDim2.new(0.9, 0, 0, 30),
	"СВОЙСТВА ДУХА",
	Color3.fromRGB(255, 215, 0),
	24
)

-- Имя духа
local detailSpiritName = CreateTextLabel(spiritDetailFrame, "DetailSpiritName",
	UDim2.new(0, 10, 0, 50),
	UDim2.new(0.9, 0, 0, 25),
	"Имя: -",
	Color3.fromRGB(255, 255, 255),
	18
)

-- Уровень
local detailSpiritLevel = CreateTextLabel(spiritDetailFrame, "DetailSpiritLevel",
	UDim2.new(0, 10, 0, 80),
	UDim2.new(0.9, 0, 0, 20),
	"Уровень: -",
	Color3.fromRGB(200, 200, 200),
	14
)

-- Элемент и редкость
local detailSpiritElement = CreateTextLabel(spiritDetailFrame, "DetailSpiritElement",
	UDim2.new(0, 10, 0, 105),
	UDim2.new(0.9, 0, 0, 20),
	"Элемент: - | Редкость: -",
	Color3.fromRGB(200, 200, 200),
	14
)

-- Текущее состояние духа
local detailSpiritStatus = CreateTextLabel(spiritDetailFrame, "DetailSpiritStatus",
	UDim2.new(0, 10, 0, 130),
	UDim2.new(0.9, 0, 0, 60),
	"Состояние:\nHP: - | Атака: -\nЗащита: - | Скорость: -",
	Color3.fromRGB(200, 200, 200),
	13
)

-- Навыки духа
local detailSpiritSkills = CreateTextLabel(spiritDetailFrame, "DetailSpiritSkills",
	UDim2.new(0, 10, 0, 195),
	UDim2.new(0.9, 0, 0, 50),
	"Навыки:\n- Базовая атака (ур. 1)",
	Color3.fromRGB(200, 200, 200),
	12
)

-- Кнопка эволюции (активна если достаточно прокачаны скилы)
local evolveButtonEnabled = false
local detailEvolveButton = CreateTextButton(spiritDetailFrame, "DetailEvolveButton",
	UDim2.new(0.5, -100, 0, 260),
	UDim2.new(0, 200, 0, 45),
	"ЭВОЛЮЦИЯ",
	Color3.fromRGB(80, 80, 80),
	"🧬"
)

-- Кнопка закрытия
local detailCloseButton = CreateTextButton(spiritDetailFrame, "DetailCloseButton",
	UDim2.new(0.5, -60, 0, 320),
	UDim2.new(0, 120, 0, 35),
	"Закрыть",
	Color3.fromRGB(100, 100, 100),
	"❌"
)

-- Функция открытия панели свойств духа
OpenSpiritDetail = function(index)
	local spirit = PlayerData.Spirits and PlayerData.Spirits[index]
	if not spirit then
		ShowNotification("Слот " .. index .. " пуст!")
		return
	end

	local spiritInfo = GetSpiritInfo(spirit.Id)
	if not spiritInfo then return end

	-- Заполняем информацию
	detailSpiritName.Text = "Имя: " .. spiritInfo.Name
	detailSpiritLevel.Text = "Уровень: " .. (spirit.Level or 1)
	detailSpiritElement.Text = "Элемент: " .. spiritInfo.Element .. " | Редкость: " .. spiritInfo.Rarity

	-- Текущее состояние (базовые характеристики зависят от уровня)
	local lvl = spirit.Level or 1
	local hp = 100 + lvl * 10
	local attack = 10 + lvl * 2
	local defense = 5 + lvl
	local speed = 10 + lvl
	detailSpiritStatus.Text = string.format(
		"Состояние:\nHP: %d | Атака: %d\nЗащита: %d | Скорость: %d",
		hp, attack, defense, speed
	)

	-- Навыки (зависят от уровня духа)
	local skillsText = "Навыки:\n"
	if lvl >= 1 then skillsText = skillsText .. "- Коготь Духа (ур. 1)\n" end
	if lvl >= 5 then skillsText = skillsText .. "- Призрачный Вихрь (ур. 5)\n" end
	if lvl >= 10 then skillsText = skillsText .. "- Духовный Щит (ур. 10)" end
	detailSpiritSkills.Text = skillsText

	-- Проверяем, можно ли эволюционировать (достаточно ли прокачаны скилы)
	-- Эволюция доступна с уровня 10 (все скилы разблокированы)
	if lvl >= 10 then
		evolveButtonEnabled = true
		detailEvolveButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
		local lbl = detailEvolveButton:FindFirstChild("ButtonLabel")
		if lbl then lbl.Text = "ЭВОЛЮЦИЯ" end
	else
		evolveButtonEnabled = false
		detailEvolveButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		local lbl = detailEvolveButton:FindFirstChild("ButtonLabel")
		if lbl then lbl.Text = "Нужно ур. 10" end
	end

	spiritDetailFrame.Visible = true

	-- Запрашиваем информацию об эволюции у сервера
	EvolutionEvent:FireServer("GetEvolutions", {})
end

-- ============================================
-- Интерфейс прокачки
-- ============================================

local levelingFrame = CreateFrame(screenGui, "LevelingFrame",
	UDim2.new(0.5, -250, 0.5, -200),
	UDim2.new(0, 500, 0, 400),
	Color3.fromRGB(30, 30, 40)
)
levelingFrame.Visible = false

local levelingTitle = CreateTextLabel(levelingFrame, "LevelingTitle",
	UDim2.new(0, 10, 0, 10),
	UDim2.new(0.9, 0, 0, 30),
	"ПРОКАЧКА ИГРОКА",
	Color3.fromRGB(255, 215, 0),
	24
)

-- Информация об уровне
local levelInfoLabel = CreateTextLabel(levelingFrame, "LevelInfoLabel",
	UDim2.new(0, 10, 0, 50),
	UDim2.new(0.9, 0, 0, 20),
	"Уровень: 1 | Опыт: 0/100",
	Color3.fromRGB(200, 200, 200),
	14
)

-- Прогресс бар опыта
local expBarBg = CreateFrame(levelingFrame, "ExpBarBg",
	UDim2.new(0, 10, 0, 75),
	UDim2.new(0.9, 0, 0, 20),
	Color3.fromRGB(60, 60, 60)
)

local expBarFill = CreateFrame(expBarBg, "ExpBarFill",
	UDim2.new(0, 0, 0, 0),
	UDim2.new(0, 0, 1, 0),
	Color3.fromRGB(100, 200, 100)
)

-- Характеристики
local statsLabel = CreateTextLabel(levelingFrame, "StatsLabel",
	UDim2.new(0, 10, 0, 105),
	UDim2.new(0.9, 0, 0, 80),
	"Характеристики:\nHP: 100 (+0) | Атака: 10 (+0)\nЗащита: 5 (+0) | Скорость: 10 (+0)\nМана: 100 (+0)",
	Color3.fromRGB(200, 200, 200),
	12
)

-- Очки навыков
local skillPointsLabel = CreateTextLabel(levelingFrame, "SkillPointsLabel",
	UDim2.new(0, 10, 0, 195),
	UDim2.new(0.9, 0, 0, 20),
	"Очки навыков: 0",
	Color3.fromRGB(255, 215, 0),
	14
)

-- Список навыков
local skillsFrame = CreateFrame(levelingFrame, "SkillsFrame",
	UDim2.new(0, 10, 0, 220),
	UDim2.new(0.9, 0, 0, 100),
	Color3.fromRGB(40, 40, 50)
)

local skillsTitle = CreateTextLabel(skillsFrame, "SkillsTitle",
	UDim2.new(0, 10, 0, 5),
	UDim2.new(0.9, 0, 0, 20),
	"Разблокированные навыки:",
	Color3.fromRGB(255, 215, 0),
	12
)

local skillsListLabel = CreateTextLabel(skillsFrame, "SkillsListLabel",
	UDim2.new(0, 10, 0, 25),
	UDim2.new(0.9, 0, 0.9, 0),
	"- Касание Призрака (ур. 1)\n- Удар силой (ур. 3)\n- Первая помощь (ур. 5)",
	Color3.fromRGB(200, 200, 200),
	11
)

-- Следующее разблокирование
local nextUnlockLabel = CreateTextLabel(levelingFrame, "NextUnlockLabel",
	UDim2.new(0, 10, 0, 330),
	UDim2.new(0.9, 0, 0, 20),
	"Следующее: Духовный щит (ур. 7) - 6 уровней",
	Color3.fromRGB(255, 200, 100),
	12
)

-- Кнопка закрытия
local closeLevelingButton = CreateTextButton(levelingFrame, "CloseLevelingButton",
	UDim2.new(0.5, -60, 0, 355),
	UDim2.new(0, 120, 0, 35),
	"Закрыть",
	Color3.fromRGB(100, 100, 100),
	"❌"
)

-- ============================================
-- Интерфейс рангов
-- ============================================

local rankFrame = CreateFrame(screenGui, "RankFrame",
	UDim2.new(0.5, -250, 0.5, -200),
	UDim2.new(0, 500, 0, 400),
	Color3.fromRGB(30, 30, 40)
)
rankFrame.Visible = false

local rankTitle = CreateTextLabel(rankFrame, "RankTitle",
	UDim2.new(0, 10, 0, 10),
	UDim2.new(0.9, 0, 0, 30),
	"СИСТЕМА РАНГОВ",
	Color3.fromRGB(255, 215, 0),
	24
)

-- Текущий ранг
local currentRankLabel = CreateTextLabel(rankFrame, "CurrentRankLabel",
	UDim2.new(0, 10, 0, 50),
	UDim2.new(0.9, 0, 0, 20),
	"Текущий ранг: D - Новичок",
	Color3.fromRGB(150, 150, 150),
	16
)

-- Описание ранга
local rankDescLabel = CreateTextLabel(rankFrame, "RankDescLabel",
	UDim2.new(0, 10, 0, 75),
	UDim2.new(0.9, 0, 0, 20),
	"Начало пути в мире духов",
	Color3.fromRGB(200, 200, 200),
	12
)

-- Следующий ранг
local nextRankLabel = CreateTextLabel(rankFrame, "NextRankLabel",
	UDim2.new(0, 10, 0, 105),
	UDim2.new(0.9, 0, 0, 20),
	"Следующий ранг: C - Боец",
	Color3.fromRGB(100, 200, 100),
	14
)

-- Требования
local requirementsLabel = CreateTextLabel(rankFrame, "RequirementsLabel",
	UDim2.new(0, 10, 0, 130),
	UDim2.new(0.9, 0, 0, 100),
	"Требования:\n- Уровень: 11 (текущий: 1)\n- Победы: 20 (текущие: 0)\n- Духи: 5 (текущие: 0)\n- Квесты: 3 (текущие: 0)",
	Color3.fromRGB(200, 200, 200),
	12
)

-- Прогресс бар
local rankProgressBg = CreateFrame(rankFrame, "RankProgressBg",
	UDim2.new(0, 10, 0, 240),
	UDim2.new(0.9, 0, 0, 20),
	Color3.fromRGB(60, 60, 60)
)

local rankProgressFill = CreateFrame(rankProgressBg, "RankProgressFill",
	UDim2.new(0, 0, 0, 0),
	UDim2.new(0, 0, 1, 0),
	Color3.fromRGB(100, 200, 100)
)

local rankProgressLabel = CreateTextLabel(rankProgressBg, "RankProgressLabel",
	UDim2.new(0, 0, 0, 0),
	UDim2.new(1, 0, 1, 0),
	"0%",
	Color3.fromRGB(255, 255, 255),
	12
)

-- Кнопка повышения ранга
local promoteButton = CreateTextButton(rankFrame, "PromoteButton",
	UDim2.new(0.5, -80, 0, 270),
	UDim2.new(0, 160, 0, 50),
	"ПОВЫСИТЬ РАНГ",
	Color3.fromRGB(255, 215, 0),
	"🏆"
)

-- Кнопка закрытия
local closeRankButton = CreateTextButton(rankFrame, "CloseRankButton",
	UDim2.new(0.5, -60, 0, 335),
	UDim2.new(0, 120, 0, 35),
	"Закрыть",
	Color3.fromRGB(100, 100, 100),
	"❌"
)

local profileFrame = CreateFrame(screenGui, "ProfileFrame",
	UDim2.new(0.5, -190, 0.5, -140),
	UDim2.new(0, 380, 0, 280),
	Color3.fromRGB(28, 28, 40)
)
profileFrame.Visible = false
WoWUITheme.StylePanel(profileFrame, "stone")

CreateTextLabel(profileFrame, "ProfileTitle",
	UDim2.new(0, 12, 0, 8),
	UDim2.new(1, -24, 0, 28),
	"Профиль героя",
	Color3.fromRGB(255, 215, 0),
	20
)

local profileRankLabel = CreateTextLabel(profileFrame, "ProfileRank",
	UDim2.new(0, 12, 0, 45),
	UDim2.new(1, -24, 0, 24),
	"Ранг: D - Новичок",
	Color3.fromRGB(220, 220, 240),
	14
)
profileRankLabel.TextXAlignment = Enum.TextXAlignment.Left

local profileLevelLabel = CreateTextLabel(profileFrame, "ProfileLevel",
	UDim2.new(0, 12, 0, 74),
	UDim2.new(1, -24, 0, 24),
	"Уровень: 1",
	Color3.fromRGB(220, 220, 240),
	14
)
profileLevelLabel.TextXAlignment = Enum.TextXAlignment.Left

local profileExpLabel = CreateTextLabel(profileFrame, "ProfileExp",
	UDim2.new(0, 12, 0, 103),
	UDim2.new(1, -24, 0, 24),
	"Опыт: 0 / 100",
	Color3.fromRGB(220, 220, 240),
	14
)
profileExpLabel.TextXAlignment = Enum.TextXAlignment.Left

local profileStatsLabel = CreateTextLabel(profileFrame, "ProfileStats",
	UDim2.new(0, 12, 0, 134),
	UDim2.new(1, -24, 0, 90),
	"Победы: 0\nПоймано духов: 0\nКвестов выполнено: 0",
	Color3.fromRGB(200, 200, 220),
	13
)
profileStatsLabel.TextWrapped = true
profileStatsLabel.TextYAlignment = Enum.TextYAlignment.Top
profileStatsLabel.TextXAlignment = Enum.TextXAlignment.Left

local closeProfileButton = CreateTextButton(profileFrame, "CloseProfileButton",
	UDim2.new(0.5, -60, 1, -42),
	UDim2.new(0, 120, 0, 34),
	"Закрыть",
	Color3.fromRGB(100, 100, 100),
	"❌"
)

local function RefreshProfileSummary()
	local lvl = tonumber(PlayerData.Level) or 1
	local exp = tonumber(PlayerData.Experience) or 0
	local expNeed = lvl * 100
	local rankNum = tonumber(PlayerData.Rank) or 1
	local rankName = RankNames[rankNum] or tostring(rankNum)
	local rankTitle = PlayerData.RankTitle or "Новичок"
	local stats = PlayerData.Stats or {}

	profileRankLabel.Text = "Ранг: " .. rankName .. " - " .. rankTitle
	profileLevelLabel.Text = "Уровень: " .. lvl
	profileExpLabel.Text = "Опыт: " .. exp .. " / " .. expNeed
	profileStatsLabel.Text = string.format(
		"Победы: %d\nПоймано духов: %d\nКвестов выполнено: %d",
		tonumber(stats.EnemiesDefeated) or 0,
		tonumber(stats.SpiritsCaught) or 0,
		tonumber(stats.QuestsCompleted) or 0
	)
end

-- ============================================
-- Интерфейс магазина
-- ============================================

local tradeFrame = CreateFrame(screenGui, "TradeFrame",
	UDim2.new(0.5, -250, 0.5, -200),
	UDim2.new(0, 500, 0, 400),
	Color3.fromRGB(30, 30, 40)
)
tradeFrame.Visible = false

local tradeCoinsLabel = CreateTextLabel(tradeFrame, "TradeCoinsLabel",
	UDim2.new(0, 10, 0, 45),
	UDim2.new(0.9, 0, 0, 20),
	"Медные монеты: 0",
	Color3.fromRGB(200, 200, 200),
	14
)

local shopListFrame = CreateFrame(tradeFrame, "ShopListFrame",
	UDim2.new(0, 10, 0, 75),
	UDim2.new(0.45, -15, 0, 250),
	Color3.fromRGB(40, 40, 50)
)

CreateTextLabel(shopListFrame, "ShopListTitle",
	UDim2.new(0, 5, 0, 5),
	UDim2.new(1, -10, 0, 20),
	"Товары",
	Color3.fromRGB(255, 255, 255),
	14
)

local inventoryListFrame = CreateFrame(tradeFrame, "InventoryListFrame",
	UDim2.new(0.55, 5, 0, 75),
	UDim2.new(0.45, -15, 0, 250),
	Color3.fromRGB(40, 40, 50)
)

CreateTextLabel(inventoryListFrame, "InventoryListTitle",
	UDim2.new(0, 5, 0, 5),
	UDim2.new(1, -10, 0, 20),
	"Инвентарь",
	Color3.fromRGB(255, 255, 255),
	14
)

local closeTradeButton = CreateTextButton(tradeFrame, "CloseTradeButton",
	UDim2.new(0.5, -60, 0, 335),
	UDim2.new(0, 120, 0, 35),
	"Закрыть",
	Color3.fromRGB(100, 100, 100),
	"❌"
)

local shopItemButtons = {}
local inventoryItemButtons = {}

local function ClearTradeButtons(container, buttonList)
	for _, btn in ipairs(buttonList) do
		btn:Destroy()
	end
	table.clear(buttonList)
end

local function FormatCopperPrice(copperAmount)
	local total = math.max(0, math.floor(tonumber(copperAmount) or 0))
	local gold = math.floor(total / 10000)
	total = total % 10000
	local silver = math.floor(total / 100)
	local copper = total % 100
	local parts = {}
	if gold > 0 then table.insert(parts, tostring(gold) .. "🥇") end
	if silver > 0 then table.insert(parts, tostring(silver) .. "🥈") end
	if copper > 0 or #parts == 0 then table.insert(parts, tostring(copper) .. "🥉") end
	return table.concat(parts, " ")
end

local function RefreshTradeInventory()
	ClearTradeButtons(inventoryListFrame, inventoryItemButtons)
	local y = 30
	for _, item in ipairs(PlayerData.Inventory or {}) do
		local shopItem = SpiritDatabaseModule.ShopItems[item.Id]
		local itemName = shopItem and shopItem.Name or ("Предмет #" .. item.Id)
		local sellPriceText = shopItem and FormatCopperPrice(shopItem.SellPrice or 0) or FormatCopperPrice(0)
		local btn = CreateTextButton(inventoryListFrame, "InvItem" .. item.Id,
			UDim2.new(0, 5, 0, y),
			UDim2.new(1, -10, 0, 45),
			itemName .. " x" .. item.Quantity .. " • Продажа: " .. sellPriceText,
			Color3.fromRGB(70, 100, 140),
			nil
		)
		local sellBtn = CreateTextButton(btn, "SellBtn",
			UDim2.new(1, -75, 0, 5),
			UDim2.new(0, 70, 0, 35),
			"Продать",
			Color3.fromRGB(180, 100, 70),
			nil
		)
		sellBtn.Text = "Продать\n" .. sellPriceText
		local useBtn = CreateTextButton(btn, "UseBtn",
			UDim2.new(1, -150, 0, 5),
			UDim2.new(0, 70, 0, 35),
			"Исп.",
			Color3.fromRGB(100, 180, 100),
			nil
		)
		if item.Id ~= 3 then useBtn.Visible = false end
		local itemId = item.Id
		sellBtn.MouseButton1Click:Connect(function()
			TradeEvent:FireServer("Sell", {ItemId = itemId, Quantity = 1})
		end)
		useBtn.MouseButton1Click:Connect(function()
			TradeEvent:FireServer("UseItem", {ItemId = itemId})
		end)
		table.insert(inventoryItemButtons, btn)
		y = y + 50
	end
end

local function RefreshShopList(items)
	ClearTradeButtons(shopListFrame, shopItemButtons)
	local y = 30
	for _, item in ipairs(items or {}) do
		local btn = CreateTextButton(shopListFrame, "ShopItem" .. item.Id,
			UDim2.new(0, 5, 0, y),
			UDim2.new(1, -10, 0, 45),
			item.Name .. " — " .. FormatCopperPrice(item.Price),
			Color3.fromRGB(70, 130, 180),
			nil
		)
		local buyBtn = CreateTextButton(btn, "BuyBtn",
			UDim2.new(1, -75, 0, 5),
			UDim2.new(0, 70, 0, 35),
			"Купить",
			Color3.fromRGB(70, 180, 70),
			nil
		)
		local itemId = item.Id
		buyBtn.MouseButton1Click:Connect(function()
			TradeEvent:FireServer("Buy", {ItemId = itemId, Quantity = 1})
		end)
		table.insert(shopItemButtons, btn)
		y = y + 50
	end
end

-- ============================================
-- Уведомления
-- ============================================

local notificationFrame = CreateFrame(screenGui, "NotificationFrame",
	UDim2.new(0.5, -150, 0, 10),
	UDim2.new(0, 300, 0, 50),
	Color3.fromRGB(40, 40, 50)
)
notificationFrame.BackgroundTransparency = 0.3

local notificationLabel = CreateTextLabel(notificationFrame, "NotificationLabel",
	UDim2.new(0, 10, 0, 0),
	UDim2.new(0.9, 0, 1, 0),
	"",
	Color3.fromRGB(255, 215, 0),
	14
)

-- ============================================
-- Миникарта (правый верхний угол)
-- ============================================

local minimapFrame, minimapContainer = WoWUITheme.CreateMinimap(screenGui, "MinimapFrame",
	UDim2.new(1, -210, 0, 10), UDim2.fromOffset(200, 200))
minimapFrame.ZIndex = 10

-- Сетка (перекрестие в центре)
local hLine = Instance.new("Frame")
hLine.Size = UDim2.new(1, 0, 0, 1)
hLine.Position = UDim2.new(0, 0, 0.5, 0)
hLine.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
hLine.BorderSizePixel = 0
hLine.ZIndex = 11
hLine.Parent = minimapContainer

local vLine = Instance.new("Frame")
vLine.Size = UDim2.new(0, 1, 1, 0)
vLine.Position = UDim2.new(0.5, 0, 0, 0)
vLine.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
vLine.BorderSizePixel = 0
vLine.ZIndex = 11
vLine.Parent = minimapContainer

-- Маркер игрока (в центре миникарты)
local playerMarker = Instance.new("Frame")
playerMarker.Name = "PlayerMarker"
playerMarker.Size = UDim2.new(0, 8, 0, 8)
playerMarker.Position = UDim2.new(0.5, -4, 0.5, -4)
playerMarker.BackgroundColor3 = Color3.fromRGB(255, 255, 100)
playerMarker.BorderSizePixel = 0
playerMarker.ZIndex = 14
playerMarker.Parent = minimapContainer
local pmCorner = Instance.new("UICorner")
pmCorner.CornerRadius = UDim.new(1, 0)
pmCorner.Parent = playerMarker

-- Индикатор севера (N сверху)
local northLabel = Instance.new("TextLabel")
northLabel.Name = "NorthLabel"
northLabel.Size = UDim2.new(0, 16, 0, 16)
northLabel.Position = UDim2.new(0.5, -8, 0, 2)
northLabel.BackgroundTransparency = 1
northLabel.Text = "N"
northLabel.TextColor3 = Color3.fromRGB(200, 200, 255)
northLabel.TextSize = 10
northLabel.Font = Enum.Font.SourceSansBold
northLabel.ZIndex = 15
northLabel.Parent = minimapFrame

-- Заголовок миникарты
local minimapTitle = CreateTextLabel(minimapFrame, "MinimapTitle",
	UDim2.new(0, 0, 1, -16),
	UDim2.new(1, 0, 0, 14),
	"Карта мира",
	Color3.fromRGB(180, 180, 200),
	10
)
minimapTitle.ZIndex = 15

-- ============================================
-- Функции обновления UI
-- ============================================

UpdateHint = function(text)
	text = text or ""
	hintText.Text = text
	if hintFrame then
		hintFrame.Visible = text ~= ""
	end
end

player:GetAttributeChangedSignal("TargetHint"):Connect(function()
	local hint = player:GetAttribute("TargetHint")
	UpdateHint((hint and hint ~= "") and hint or "")
end)

local function UpdateHP(percentage)
	if hpFill then
		hpFill.Size = UDim2.new(math.clamp(percentage, 0, 1), 0, 1, 0)
	end
end

local function UpdateMP(percentage)
	if mpFill then
		mpFill.Size = UDim2.new(math.clamp(percentage, 0, 1), 0, 1, 0)
	end
end

local function UpdateLevel(level)
	expLevelLabel.Text = "Ур. " .. level
end

local function UpdateExp(current, needed)
	local pct = (needed and needed > 0) and (current / needed) or 0
	expBarFill.Size = UDim2.new(math.clamp(pct, 0, 1), 0, 1, 0)
	expBarLabel.Text = current .. " / " .. needed
end

local function NormalizeCoins(copper, silver, gold)
	local total = (tonumber(copper) or 0) + (tonumber(silver) or 0) * 100 + (tonumber(gold) or 0) * 10000
	total = math.max(0, math.floor(total))
	local g = math.floor(total / 10000)
	total = total % 10000
	local s = math.floor(total / 100)
	local c = total % 100
	return c, s, g
end

local function UpdateCoins(copper, silver, gold)
	local c, s, g = NormalizeCoins(copper, silver, gold)
	PlayerData.CopperCoins = c
	PlayerData.SilverCoins = s
	PlayerData.GoldCoins = g
	if bagCurrencyLabel then
		bagCurrencyLabel.Text = string.format("💰 %d 🥇 | %d 🥈 | %d 🥉", g, s, c)
	end
	if tradeCoinsLabel then
		tradeCoinsLabel.Text = string.format("Монеты: %d 🥇 %d 🥈 %d 🥉", g, s, c)
	end
end

local function UpdateRank(_rankName, _rankTitle, _rankColor)
	-- ранг доступен через кнопку «Ранг»
end

local function UpdateTraps(_trapCount)
	-- ловушки видны в инвентаре магазина
end

ShowNotification = function(text, duration)
	notificationLabel.Text = text
	notificationFrame.Visible = true

	task.spawn(function()
		task.wait(duration or 3)
		notificationFrame.Visible = false
	end)
end

UpdateBattleLog = function(text)
	battleLogLabel.Text = text
end

local function SetBattleSkillButton(button, defaultText, skillData, playerMP)
	local label = button:FindFirstChild("ButtonLabel")
	local title = defaultText
	if skillData then
		local cd = tonumber(skillData.Cooldown) or 0
		local cost = tonumber(skillData.Cost) or 0
		title = skillData.Name or defaultText
		if cd > 0.05 then
			title = string.format("%s [%.1fс]", title, cd)
		elseif cost > 0 then
			title = string.format("%s [%d MP]", title, cost)
		end
	end
	if label then
		label.Text = title
	else
		button.Text = title
	end

	local disabled = (not skillData)
		or ((tonumber(skillData.Cooldown) or 0) > 0.05)
		or ((tonumber(playerMP) or 0) < (tonumber(skillData.Cost) or 0))
	button.BackgroundColor3 = disabled and Color3.fromRGB(95, 95, 95) or Color3.fromRGB(180, 70, 70)
end

local function UpdateBattleSkillButtons(battleData)
	local skills = battleData and battleData.PlayerSkills or nil
	local mp = battleData and battleData.PlayerMP or 0
	SetBattleSkillButton(attack1Button, "Коготь Духа", skills and skills[1], mp)
	SetBattleSkillButton(attack2Button, "Призрачный Вихрь", skills and skills[2], mp)
	SetBattleSkillButton(attack3Button, "Навык 3", skills and skills[3], mp)
	attack3Button.Visible = skills ~= nil and skills[3] ~= nil
end

-- ============================================
-- Обновление слотов духов
-- ============================================

local function UpdateSpiritSlots(spirits)
	for i = 1, 4 do
		local slot = spiritsFrame:FindFirstChild("SpiritSlot" .. i)
		if slot then
			local iconFrame = slot:FindFirstChild("SpiritIcon")
			local iconEmoji = iconFrame and iconFrame:FindFirstChild("IconEmoji")
			local nameLabel = slot:FindFirstChild("SpiritNameLabel")
			if spirits[i] then
				local spiritInfo = spirits[i]
				local shortName = spiritInfo.Name:match("(%S+)") or spiritInfo.Name
				local iconData = SpiritIcons[spiritInfo.Id]
				if iconData then
					if iconFrame then iconFrame.BackgroundColor3 = iconData.Color end
					if iconEmoji then iconEmoji.Text = iconData.Emoji end
				else
					if iconFrame then iconFrame.BackgroundColor3 = Color3.fromRGB(80, 80, 80) end
					if iconEmoji then iconEmoji.Text = "❓" end
				end
				if nameLabel then
					nameLabel.Text = shortName .. " Ур." .. (spiritInfo.Level or 1)
				end
				slot.BackgroundColor3 = Color3.fromRGB(80, 120, 80)
			else
				if iconFrame then iconFrame.BackgroundColor3 = Color3.fromRGB(80, 80, 80) end
				if iconEmoji then iconEmoji.Text = "?" end
				if nameLabel then nameLabel.Text = tostring(i) end
				slot.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
			end
		end
	end
end

-- ============================================
-- Обработчики кнопок
-- ============================================

catchButton.MouseButton1Click:Connect(function()
	local tween = TweenService:Create(catchButton, 
		TweenInfo.new(0.1, Enum.EasingStyle.Quad), 
		{BackgroundColor3 = Color3.fromRGB(100, 220, 100)}
	)
	tween:Play()

	task.wait(0.1)

	local tween2 = TweenService:Create(catchButton, 
		TweenInfo.new(0.1, Enum.EasingStyle.Quad), 
		{BackgroundColor3 = Color3.fromRGB(70, 180, 70)}
	)
	tween2:Play()

	-- Сигналим ClientController о запросе на ловлю
	player:SetAttribute("CatchRequest", os.clock())
	UpdateHint("Попытка поймать духа...")
end)

battleButton.MouseButton1Click:Connect(function()
	-- Сигналим ClientController о запросе на бой
	player:SetAttribute("BattleRequest", os.clock())
	UpdateHint("Начинаем бой!")
end)

menuButton.MouseButton1Click:Connect(function()
	UpdateHint("Меню открыто")
end)

-- Кнопки боя
attack1Button.MouseButton1Click:Connect(function()
	if not CurrentBattle then return end
	local s = CurrentBattle.PlayerSkills and CurrentBattle.PlayerSkills[1]
	if s and (tonumber(s.Cooldown) or 0) <= 0.05 and (CurrentBattle.PlayerMP or 0) >= (tonumber(s.Cost) or 0) then
		BattleEvent:FireServer("Attack", {SkillIndex = 1})
	else
		ShowNotification("Навык 1 недоступен")
	end
end)

attack2Button.MouseButton1Click:Connect(function()
	if not CurrentBattle then return end
	local s = CurrentBattle.PlayerSkills and CurrentBattle.PlayerSkills[2]
	if s and (tonumber(s.Cooldown) or 0) <= 0.05 and (CurrentBattle.PlayerMP or 0) >= (tonumber(s.Cost) or 0) then
		BattleEvent:FireServer("Attack", {SkillIndex = 2})
	else
		ShowNotification("Навык 2 недоступен")
	end
end)

attack3Button.MouseButton1Click:Connect(function()
	if not CurrentBattle then return end
	local s = CurrentBattle.PlayerSkills and CurrentBattle.PlayerSkills[3]
	if s and (tonumber(s.Cooldown) or 0) <= 0.05 and (CurrentBattle.PlayerMP or 0) >= (tonumber(s.Cost) or 0) then
		BattleEvent:FireServer("Attack", {SkillIndex = 3})
	else
		ShowNotification("Навык 3 недоступен")
	end
end)

fleeButton.MouseButton1Click:Connect(function()
	if CurrentBattle then
		BattleEvent:FireServer("Flee", {})
	end
end)

-- Кнопки панели свойств духа
detailEvolveButton.MouseButton1Click:Connect(function()
	if not evolveButtonEnabled then return end
	if selectedSpiritIndex then
		EvolutionEvent:FireServer("Evolve", {SpiritIndex = selectedSpiritIndex})
	end
end)

detailCloseButton.MouseButton1Click:Connect(function()
	spiritDetailFrame.Visible = false
end)

profileButton.MouseButton1Click:Connect(function()
	profileFrame.Visible = not profileFrame.Visible
	if profileFrame.Visible then
		RefreshProfileSummary()
		LevelingEvent:FireServer("GetProgressInfo", {})
		LevelingEvent:FireServer("GetStats", {})
		RankEvent:FireServer("GetRankInfo", {})
	end
end)

closeProfileButton.MouseButton1Click:Connect(function()
	profileFrame.Visible = false
end)

closeLevelingButton.MouseButton1Click:Connect(function()
	levelingFrame.Visible = false
end)

closeRankButton.MouseButton1Click:Connect(function()
	rankFrame.Visible = false
end)

promoteButton.MouseButton1Click:Connect(function()
	RankEvent:FireServer("Promote", {})
end)

closeTradeButton.MouseButton1Click:Connect(function()
	tradeFrame.Visible = false
end)

-- ============================================
-- Обработка событий от сервера
-- ============================================

DataEvent.OnClientEvent:Connect(function(action, data)
	if action == "FullSync" then
		-- Полная синхронизация данных
		PlayerData = data
		UpdateLevel(data.Level)
		UpdateExp(data.Experience, data.Level * 100)
		UpdateCoins(data.CopperCoins, data.SilverCoins, data.GoldCoins)

		-- Обновляем ранг
		if data.Rank and data.RankTitle then
			-- Получаем цвет ранга из RankSystem
			local rankColors = {
				[1] = Color3.fromRGB(150, 150, 150), -- D
				[2] = Color3.fromRGB(100, 200, 100), -- C
				[3] = Color3.fromRGB(100, 150, 255), -- B
				[4] = Color3.fromRGB(200, 100, 255), -- A
				[5] = Color3.fromRGB(255, 215, 0),   -- S
				[6] = Color3.fromRGB(255, 100, 100), -- SS
				[7] = Color3.fromRGB(255, 215, 0)    -- SSS
			}
			local rankColor = rankColors[data.Rank] or Color3.fromRGB(150, 150, 150)
			local rankNameStr = RankNames[data.Rank] or tostring(data.Rank)
			UpdateRank(rankNameStr, data.RankTitle, rankColor)
		end

		-- Обновляем слоты духов
		local spiritDisplayData = {}
		for i, spirit in ipairs(data.Spirits) do
			local spiritInfo = GetSpiritInfo(spirit.Id)
			if spiritInfo then
				table.insert(spiritDisplayData, {
					Id = spirit.Id,
					Name = spiritInfo.Name,
					Level = spirit.Level
				})
			end
		end
		UpdateSpiritSlots(spiritDisplayData)
		UpdateBagSlots(data.Bags)

		-- Обновляем количество ловушек
		local trapCount = 0
		if data.Inventory then
			for _, item in ipairs(data.Inventory) do
				if item.Id == 1 then
					trapCount = item.Quantity
					break
				end
			end
		end
		UpdateTraps(trapCount)
		if tradeFrame.Visible then
			RefreshTradeInventory()
		end
		RefreshProfileSummary()

		if not hasDataBeenLoaded then
			ShowNotification("Данные загружены! ")
			hasDataBeenLoaded = true
		else
			ShowNotification("Данные синхронизированы!")
		end

	elseif action == "LevelUp" then
		-- Повышение уровня
		UpdateLevel(data.NewLevel)
		local levelMsg = "Уровень повышен до " .. data.NewLevel .. "!"
		if data.BonusCoins and data.BonusCoins > 0 then
			levelMsg = levelMsg .. " +" .. data.BonusCoins .. " монет!"
		end
		ShowNotification(levelMsg)

	elseif action == "SpiritCaught" then
		EnterNormalMode()
		ShowNotification("Вы поймали " .. (data.SpiritInfo and data.SpiritInfo.Name or "духа") .. "!")

	elseif action == "CatchFailed" then
		EnterNormalMode()
		ShowNotification("Не удалось поймать " .. data.SpiritName .. "!")

	elseif action == "Error" then
		EnterNormalMode()
		ShowNotification("Ошибка: " .. data.Message)

	elseif action == "RankUpdated" then
		-- Обновляем ранг
		local rankColors = {
			[1] = Color3.fromRGB(150, 150, 150), -- D
			[2] = Color3.fromRGB(100, 200, 100), -- C
			[3] = Color3.fromRGB(100, 150, 255), -- B
			[4] = Color3.fromRGB(200, 100, 255), -- A
			[5] = Color3.fromRGB(255, 215, 0),   -- S
			[6] = Color3.fromRGB(255, 100, 100), -- SS
			[7] = Color3.fromRGB(255, 215, 0)    -- SSS
		}
		local rankColor = rankColors[data.Rank] or Color3.fromRGB(150, 150, 150)
		local rankNameStr = RankNames[data.Rank] or tostring(data.Rank)
		UpdateRank(rankNameStr, data.RankTitle, rankColor)
		PlayerData.Rank = data.Rank
		PlayerData.RankTitle = data.RankTitle
		RefreshProfileSummary()
	end
end)

player:GetAttributeChangedSignal("BattleEngaged"):Connect(function()
	suppressBattleUpdates = false
end)

player:GetAttributeChangedSignal("BattleRequest"):Connect(function()
	suppressBattleUpdates = false
end)

BattleEvent.OnClientEvent:Connect(function(action, data)
	if action == "Update" then
		if suppressBattleUpdates then return end
		-- Обновление состояния боя
		CurrentBattle = data
		SetBattleMode(true)

		if data.PlayerMaxHP and data.PlayerMaxHP > 0 then
			UpdateHP(data.PlayerHP / data.PlayerMaxHP)
		end
		if data.PlayerMaxMP and data.PlayerMaxMP > 0 then
			UpdateMP(data.PlayerMP / data.PlayerMaxMP)
		end
		UpdateBattleSkillButtons(data)

		-- Обновляем лог
		if data.Message and data.Message ~= "" then
			UpdateBattleLog("Ход " .. data.Turn .. " | " .. data.Message)
		else
			UpdateBattleLog("Ход " .. data.Turn)
		end

	elseif action == "End" then
		-- Конец боя
		EnterNormalMode()

		if data.Winner == "Player" then
			local rewards = data.Rewards or {}
		local rewardText = "Победа!"
		if rewards.Experience then rewardText = rewardText .. " +" .. rewards.Experience .. " опыта" end
		if rewards.CopperCoins and rewards.CopperCoins > 0 then rewardText = rewardText .. ", +" .. rewards.CopperCoins .. " 🥉" end
		if rewards.SilverCoins and rewards.SilverCoins > 0 then rewardText = rewardText .. ", +" .. rewards.SilverCoins .. " 🥈" end
		if rewards.GoldCoins and rewards.GoldCoins > 0 then rewardText = rewardText .. ", +" .. rewards.GoldCoins .. " 🥇" end
		ShowNotification(rewardText)
		else
			ShowNotification("Поражение...")
		end

	elseif action == "Flee" then
		if data.Success then
			EnterNormalMode()
			ShowNotification("Вы сбежали!")
		else
			ShowNotification("Не удалось сбежать!")
		end

	elseif action == "Error" then
		EnterNormalMode()
		ShowNotification("Бой: " .. (data.Message or "ошибка"))
	end
end)

-- ============================================
-- Обработка событий эволюции
-- ============================================

EvolutionEvent.OnClientEvent:Connect(function(action, data)
	if action == "EvolutionsList" then
		-- Обновляем список доступных эволюций
		local evolutions = data.Evolutions
		ShowNotification("Доступно эволюций: " .. #evolutions)

		-- Здесь можно обновить UI эволюции

	elseif action == "EvolutionInfo" then
		-- Показываем информацию об эволюции
		local info = data.Info
		if info then
			ShowNotification("Эволюция: " .. info.EvolvedName)
		end

	elseif action == "EvolutionSuccess" then
		-- Эволюция успешна
		local newSpirit = data.NewSpirit
		ShowNotification("Дух эволюционировал в " .. newSpirit.Name .. "!")
		spiritDetailFrame.Visible = false

		-- Обновляем слоты духов
		if PlayerData.Spirits then
			local spiritDisplayData = {}
			for i, spirit in ipairs(PlayerData.Spirits) do
				local spiritInfo = GetSpiritInfo(spirit.Id)
				if spiritInfo then
						table.insert(spiritDisplayData, {
						Id = spirit.Id,
						Name = spiritInfo.Name,
						Level = spirit.Level
					})
				end
			end
			UpdateSpiritSlots(spiritDisplayData)
		end

	elseif action == "EvolutionFailed" then
		-- Эволюция не удалась
		ShowNotification("Эволюция не удалась: " .. data.Reason)
	end
end)

-- ============================================
-- Обработка событий прокачки
-- ============================================

LevelingEvent.OnClientEvent:Connect(function(action, data)
	if action == "ProgressInfo" then
		-- Обновляем информацию о прогрессе
		local info = data.Info
		levelInfoLabel.Text = "Уровень: " .. info.Level .. " | Опыт: " .. info.Experience .. "/" .. info.ExpNeeded

		-- Обновляем прогресс бар
		expBarFill.Size = UDim2.new(info.Progress, 0, 1, 0)

		-- Обновляем очки навыков
		skillPointsLabel.Text = "Очки навыков: " .. info.SkillPoints
		PlayerData.Level = info.Level
		PlayerData.Experience = info.Experience
		RefreshProfileSummary()

		-- Обновляем следующее разблокирование
		if info.NextUnlock then
			nextUnlockLabel.Text = "Следующее: " .. info.NextUnlock.Name .. " (ур. " .. info.NextUnlock.Level .. ") - " .. info.NextUnlock.LevelsAway .. " уровней"
		else
			nextUnlockLabel.Text = "Все навыки разблокированы!"
		end

	elseif action == "UnlockedSkills" then
		-- Обновляем список навыков
		local skills = data.Skills
		local skillsText = ""
		for i, skill in ipairs(skills) do
			if i > 1 then skillsText = skillsText .. "\n" end
			skillsText = skillsText .. "- " .. skill.Name .. " (ур. " .. skill.Level .. ")"
		end
		skillsListLabel.Text = skillsText or "Нет навыков"

	elseif action == "AllSkills" then
		-- Все навыки
		local skills = data.Skills
		ShowNotification("Доступно навыков: " .. #skills)

	elseif action == "Stats" then
		-- Обновляем характеристики
		local stats = data.Stats
		statsLabel.Text = "Характеристики:\nHP: " .. stats.HP .. " | Атака: " .. stats.Attack .. "\nЗащита: " .. stats.Defense .. " | Скорость: " .. stats.Speed .. "\nМана: " .. stats.MP
		RefreshProfileSummary()

	elseif action == "NewSkillsUnlocked" then
		-- Новые навыки разблокированы
		local skills = data.Skills
		for _, skill in ipairs(skills) do
			ShowNotification("Разблокирован новый навык: " .. skill.Name .. "!")
		end
	end
end)

-- ============================================
-- Обработка событий рангов
-- ============================================

RankEvent.OnClientEvent:Connect(function(action, data)
	if action == "RankInfo" then
		-- Обновляем информацию о ранге
		local currentRank = data.CurrentRank
		local nextRank = data.NextRank

		currentRankLabel.Text = "Текущий ранг: " .. currentRank.Name .. " - " .. currentRank.Title
		rankDescLabel.Text = currentRank.Description

		-- Обновляем цвет ранга
		if currentRank.Color then
			currentRankLabel.TextColor3 = currentRank.Color
		end
		PlayerData.Rank = currentRank.Level or PlayerData.Rank
		PlayerData.RankTitle = currentRank.Title or PlayerData.RankTitle
		RefreshProfileSummary()

		if nextRank then
			nextRankLabel.Text = "Следующий ранг: " .. nextRank.Rank.Name .. " - " .. nextRank.Rank.Title

			-- Обновляем требования
			local reqText = "Требования:\n"
			reqText = reqText .. "- Уровень: " .. nextRank.Rank.MinLevel .. " (нужно: " .. nextRank.LevelsNeeded .. ")\n"
			reqText = reqText .. "- Победы: " .. nextRank.Rank.RequiredEnemiesDefeated .. " (нужно: " .. nextRank.EnemiesNeeded .. ")\n"
			reqText = reqText .. "- Духи: " .. nextRank.Rank.RequiredSpiritsCaught .. " (нужно: " .. nextRank.SpiritsNeeded .. ")\n"
			reqText = reqText .. "- Квесты: " .. nextRank.Rank.RequiredQuestsCompleted .. " (нужно: " .. nextRank.QuestsNeeded .. ")"
			requirementsLabel.Text = reqText

			-- Обновляем прогресс бар
			rankProgressFill.Size = UDim2.new(nextRank.Progress, 0, 1, 0)
			rankProgressLabel.Text = math.floor(nextRank.Progress * 100) .. "%"

			-- Активируем кнопку повышения
			if nextRank.Progress >= 1 then
				promoteButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
				local lbl = promoteButton:FindFirstChild("ButtonLabel")
				if lbl then lbl.Text = "ПОВЫСИТЬ РАНГ" end
			else
				promoteButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
				local lbl2 = promoteButton:FindFirstChild("ButtonLabel")
				if lbl2 then lbl2.Text = "Не выполнено" end
			end
		else
			nextRankLabel.Text = "Максимальный ранг!"
			requirementsLabel.Text = "Вы достигли максимального ранга!"
			rankProgressFill.Size = UDim2.new(1, 0, 1, 0)
			rankProgressLabel.Text = "100%"
			promoteButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			local lbl3 = promoteButton:FindFirstChild("ButtonLabel")
			if lbl3 then lbl3.Text = "Макс. ранг" end
		end

	elseif action == "AllRanks" then
		-- Все ранги
		local ranks = data.Ranks
		ShowNotification("Доступно рангов: " .. #ranks)

	elseif action == "RankPromoted" then
		-- Ранг повышен
		local newRank = data.NewRank
		ShowNotification("Ранг повышен до " .. newRank.Name .. " - " .. newRank.Title .. "!")

		-- Обновляем UI
		currentRankLabel.Text = "Текущий ранг: " .. newRank.Name .. " - " .. newRank.Title
		rankDescLabel.Text = newRank.Description

		if newRank.Color then
			currentRankLabel.TextColor3 = newRank.Color
		end

		-- Обновляем ранг в основном UI
		UpdateRank(newRank.Name, newRank.Title, newRank.Color)
		PlayerData.RankTitle = newRank.Title or PlayerData.RankTitle
		RefreshProfileSummary()

	elseif action == "RankPromotionFailed" then
		-- Повышение не удалось
		ShowNotification("Не удалось повысить ранг: " .. data.Reason)
	end
end)

TradeEvent.OnClientEvent:Connect(function(action, data)
	if action == "ShopList" then
		RefreshShopList(data.Items)
	elseif action == "TradeResult" then
		ShowNotification(data.Message or "")
		if data.Success and tradeFrame.Visible then
			RefreshTradeInventory()
		end
	end
end)

-- ============================================
-- Инициализация
-- ============================================

UpdateLevel(1)
UpdateExp(0, 100)
ShowNotification("Загрузка данных...", 2)

local function HandleShopZoneActivation()
	local zone = player:GetAttribute("CurrentZone")
	if zone == "Safe" or zone == "Genkan" then
		TradeEvent:FireServer("GetShop", {})
	end
end

player:GetAttributeChangedSignal("CurrentZone"):Connect(HandleShopZoneActivation)
task.defer(HandleShopZoneActivation)

-- ============================================
-- Обновление миникарты (цикл)
-- ============================================

task.spawn(function()
	local MAP_RADIUS = 80 -- стадов от центра видимости
	local dotPool = {}

	while true do
		task.wait(0.15)

		local character = player.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if not hrp then continue end

		local playerPos = hrp.Position
		local absSize = minimapContainer.AbsoluteSize
		local mapRadius = math.min(absSize.X, absSize.Y) / 2

		-- Собираем все цели для отображения на миникарте
		local targets = {}

		-- Духи в мире
		local spiritsFolder = workspace:FindFirstChild("Spirits")
		if spiritsFolder then
			for _, spirit in ipairs(spiritsFolder:GetChildren()) do
				if spirit.PrimaryPart and not spirit:GetAttribute("Dying") then
					local spiritIdVal = spirit:FindFirstChild("SpiritId")
					local spiritId = spiritIdVal and spiritIdVal.Value or 1
					local iconData = SpiritIcons[spiritId]
					table.insert(targets, {
						pos = spirit.PrimaryPart.Position,
						color = iconData and iconData.Color or Color3.fromRGB(255, 255, 255),
						size = 6,
					})
				end
			end
		end

		-- Точка спавна
		local spawnLoc = workspace:FindFirstChildOfClass("SpawnLocation")
		if spawnLoc then
			table.insert(targets, {
				pos = spawnLoc.Position,
				color = Color3.fromRGB(100, 255, 100),
				size = 5,
			})
		end

		-- Обновляем пул точек
		for i = #dotPool, 1, -1 do
			dotPool[i]:Destroy()
			dotPool[i] = nil
		end

		for _, target in ipairs(targets) do
			local relX = target.pos.X - playerPos.X
			local relZ = target.pos.Z - playerPos.Z

			-- Масштабируем в координаты миникарты
			local dotX = (relX / MAP_RADIUS) * mapRadius
			local dotY = (relZ / MAP_RADIUS) * mapRadius

			-- Ограничиваем в пределах круга
			local dist = math.sqrt(dotX * dotX + dotY * dotY)
			local maxR = mapRadius - target.size / 2 - 2
			if dist > maxR then
				dotX = dotX / dist * maxR
				dotY = dotY / dist * maxR
			end

			local dot = Instance.new("Frame")
			dot.Name = "MapDot"
			dot.Size = UDim2.new(0, target.size, 0, target.size)
			dot.Position = UDim2.new(0.5, dotX - target.size / 2, 0.5, dotY - target.size / 2)
			dot.BackgroundColor3 = target.color
			dot.BorderSizePixel = 0
			dot.ZIndex = 13
			dot.Parent = minimapContainer

			local dotCorner = Instance.new("UICorner")
			dotCorner.CornerRadius = UDim.new(1, 0)
			dotCorner.Parent = dot

			table.insert(dotPool, dot)
		end
	end
end)

print("Realm of Spirits - UI Controller загружен!")

