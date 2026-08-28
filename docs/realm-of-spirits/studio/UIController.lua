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
local ResonanceEvent = realmFolder:WaitForChild("ResonanceEvent")
local QuestEvent = realmFolder:WaitForChild("Quest")

local SpiritDatabaseModule = require(realmFolder:WaitForChild("SpiritDatabase"))
local SkillCatalog = require(realmFolder:WaitForChild("SkillCatalog"))
local ItemCatalog = require(realmFolder:WaitForChild("ItemCatalog"))
local SpiritMeshResolve = require(realmFolder:WaitForChild("SpiritMeshResolve"))
local SpiritResonance = require(realmFolder:WaitForChild("SpiritResonance"))
local ToastRouter = require(realmFolder:WaitForChild("ToastRouter"))
local WoWUITheme = require(realmFolder:WaitForChild("WoWUITheme"))
local QuestTrackerHud = require(realmFolder:WaitForChild("QuestTrackerHud"))
local function GetSpiritInfo(id)
	return SpiritDatabaseModule.GetDisplay(id) or SpiritDatabaseModule.Get(id)
end

-- Resonant (Ками, Id 9xxx) нет в SpiritDatabase — display из инстанса (как ResolveBattleSpiritInfo)
local function ResolveOwnedSpiritDisplay(spirit)
	if type(spirit) ~= "table" then
		return nil
	end
	local info = GetSpiritInfo(spirit.Id)
	if info then
		return {
			Id = spirit.Id,
			Name = spirit.Name or info.Name,
			Element = info.Element or spirit.Element,
			PrimaryElement = info.PrimaryElement or spirit.PrimaryElement or spirit.HybridPrimary,
			Aspect = info.Aspect,
			ElementLabel = info.ElementLabel
				or SpiritDatabaseModule.FormatElementLabel and SpiritDatabaseModule.FormatElementLabel(spirit),
			Rarity = info.Rarity or "-",
			Kind = spirit.Kind,
			ParentIds = spirit.ParentIds,
		}
	end
	local kind = tostring(spirit.Kind or "")
	local idNum = tonumber(spirit.Id) or 0
	if kind ~= "Resonant" and idNum < 9000 then
		return nil
	end
	local parentId = nil
	if type(spirit.ParentIds) == "table" then
		parentId = tonumber(spirit.ParentIds[1])
	end
	local parent = parentId and GetSpiritInfo(parentId) or nil
	local el = spirit.PrimaryElement or spirit.HybridPrimary or spirit.Element
		or (parent and (parent.PrimaryElement or parent.Element)) or "Fire"
	local elLabel = el
	if SpiritDatabaseModule.FormatElementLabel then
		elLabel = SpiritDatabaseModule.FormatElementLabel({
			PrimaryElement = el,
			Aspect = el,
			Element = el,
		}) or el
	end
	return {
		Id = spirit.Id,
		Name = spirit.Name or "Ками",
		Element = el,
		PrimaryElement = el,
		HybridPrimary = spirit.HybridPrimary or el,
		Aspect = el,
		ElementLabel = elLabel,
		Rarity = "Resonant",
		Kind = "Resonant",
		ParentIds = spirit.ParentIds,
	}
end

local function isResonantSpirit(spirit)
	if type(spirit) ~= "table" then
		return false
	end
	return spirit.Kind == "Resonant" or (tonumber(spirit.Id) or 0) >= 9000
end

local function formatParentIds(parentIds)
	if type(parentIds) ~= "table" or #parentIds == 0 then
		return "—"
	end
	local parts = {}
	for _, pid in ipairs(parentIds) do
		table.insert(parts, "#" .. tostring(pid))
	end
	return table.concat(parts, ", ")
end

local function formatStarTierHint(starScore, resonancePower)
	local score = tonumber(starScore)
	if score then
		if score >= 0.75 then
			return "★★★ III"
		elseif score >= 0.4 then
			return "★★ II"
		elseif score >= 0.15 then
			return "★ I"
		end
		return "без тира"
	end
	local pow = tonumber(resonancePower)
	if pow then
		return string.format("сила %.2f", pow)
	end
	return "—"
end

local function buildResonantDexLines(spirits)
	local lines = {}
	for i, s in ipairs(spirits or {}) do
		if isResonantSpirit(s) then
			local name = s.Name or ("Ками #" .. tostring(s.Id))
			local lvl = tonumber(s.Level) or 1
			local parents = formatParentIds(s.ParentIds)
			local stars = formatStarTierHint(s.StarScore, s.ResonancePower)
			table.insert(lines, string.format("[R] %d. %s Lv%d", i, name, lvl))
			table.insert(lines, string.format("    vid %s · %s", parents, stars))
		end
	end
	return lines
end

-- Маппинг числового ранга в буквенный
local RankNames = {[1] = "D", [2] = "C", [3] = "B", [4] = "A", [5] = "S", [6] = "SS", [7] = "SSS"}

-- Иконки духов для меню (Id 1.x–4.x + evo; fallback по Element)
local ElementIcons = {
	Fire = {Color = Color3.fromRGB(255, 100, 50), Emoji = "🔥"},
	Ash = {Color = Color3.fromRGB(220, 90, 40), Emoji = "🦎"},
	Light = {Color = Color3.fromRGB(255, 255, 200), Emoji = "✨"},
	Magma = {Color = Color3.fromRGB(220, 50, 20), Emoji = "🌋"},
	Earth = {Color = Color3.fromRGB(140, 110, 70), Emoji = "🪨"},
	Nature = {Color = Color3.fromRGB(80, 160, 70), Emoji = "🦌"},
	Metal = {Color = Color3.fromRGB(100, 115, 135), Emoji = "🪲"},
	Poison = {Color = Color3.fromRGB(90, 180, 60), Emoji = "🐍"},
	Sand = {Color = Color3.fromRGB(190, 150, 70), Emoji = "🦂"},
	Crystal = {Color = Color3.fromRGB(140, 200, 255), Emoji = "💎"},
	Wind = {Color = Color3.fromRGB(120, 200, 180), Emoji = "🦊"},
	Storm = {Color = Color3.fromRGB(200, 200, 100), Emoji = "⚡"},
	Lightning = {Color = Color3.fromRGB(200, 200, 100), Emoji = "⚡"},
	Dark = {Color = Color3.fromRGB(100, 50, 150), Emoji = "🌑"},
	Sky = {Color = Color3.fromRGB(140, 190, 255), Emoji = "🦅"},
	Water = {Color = Color3.fromRGB(25, 100, 200), Emoji = "🐟"},
	Ice = {Color = Color3.fromRGB(100, 200, 255), Emoji = "❄️"},
	Moon = {Color = Color3.fromRGB(200, 210, 255), Emoji = "🐰"},
	Mist = {Color = Color3.fromRGB(120, 160, 210), Emoji = "🌫️"},
}

local SpiritIcons = {
	-- Fire 1.x
	[11] = {Color = Color3.fromRGB(255, 100, 50), Emoji = "🔥"}, -- Огненный Кот
	[12] = {Color = Color3.fromRGB(220, 90, 40), Emoji = "🦎"}, -- Пепельный Саламандр
	[13] = {Color = Color3.fromRGB(255, 255, 200), Emoji = "✨"}, -- Световой Единорог
	[14] = {Color = Color3.fromRGB(220, 50, 20), Emoji = "🌋"}, -- Лавовый Краб
	-- Earth 2.x
	[21] = {Color = Color3.fromRGB(140, 110, 70), Emoji = "🪨"}, -- Каменный Голем
	[22] = {Color = Color3.fromRGB(80, 160, 70), Emoji = "🦌"}, -- Моховой Олень
	[23] = {Color = Color3.fromRGB(100, 115, 135), Emoji = "🪲"}, -- Стальной Жук
	[24] = {Color = Color3.fromRGB(90, 180, 60), Emoji = "🐍"}, -- Ядовитая Гадюка
	[25] = {Color = Color3.fromRGB(190, 150, 70), Emoji = "🦂"}, -- Пустынный Скорпион
	[26] = {Color = Color3.fromRGB(140, 200, 255), Emoji = "💎"}, -- Хрустальный Лис
	-- Wind 3.x
	[31] = {Color = Color3.fromRGB(120, 200, 180), Emoji = "🦊"}, -- Ветряной Лис
	[32] = {Color = Color3.fromRGB(200, 200, 100), Emoji = "⚡"}, -- Грозовой Дракон
	[33] = {Color = Color3.fromRGB(100, 50, 150), Emoji = "🌑"}, -- Теневой Пёс
	[34] = {Color = Color3.fromRGB(140, 190, 255), Emoji = "🦅"}, -- Небесный Сокол
	-- Water 4.x
	[41] = {Color = Color3.fromRGB(25, 100, 200), Emoji = "🐟"}, -- Водный Карп
	[42] = {Color = Color3.fromRGB(100, 200, 255), Emoji = "❄️"}, -- Ледяная Птица
	[43] = {Color = Color3.fromRGB(200, 210, 255), Emoji = "🐰"}, -- Лунный Кролик
	[44] = {Color = Color3.fromRGB(120, 160, 210), Emoji = "🌫️"}, -- Туманный Дух
	-- Evolved
	[1011] = {Color = Color3.fromRGB(255, 120, 50), Emoji = "🐯"}, -- Огненный Тигр (Identity look)
	[1012] = {Color = Color3.fromRGB(255, 80, 30), Emoji = "🐉"},
	[1013] = {Color = Color3.fromRGB(255, 255, 200), Emoji = "✨"},
	[1014] = {Color = Color3.fromRGB(220, 50, 20), Emoji = "🌋"},
	[1021] = {Color = Color3.fromRGB(160, 130, 80), Emoji = "⛰️"},
	[1022] = {Color = Color3.fromRGB(60, 130, 55), Emoji = "🌳"},
	[1023] = {Color = Color3.fromRGB(100, 115, 135), Emoji = "🛡️"},
	[1024] = {Color = Color3.fromRGB(70, 150, 45), Emoji = "☠️"},
	[1025] = {Color = Color3.fromRGB(190, 150, 70), Emoji = "🦂"},
	[1026] = {Color = Color3.fromRGB(140, 200, 255), Emoji = "💎"},
	[1031] = {Color = Color3.fromRGB(90, 220, 200), Emoji = "🌬️"},
	[1032] = {Color = Color3.fromRGB(200, 200, 100), Emoji = "⚡"},
	[1033] = {Color = Color3.fromRGB(100, 50, 150), Emoji = "🌑"},
	[1034] = {Color = Color3.fromRGB(140, 190, 255), Emoji = "🦅"},
	[1041] = {Color = Color3.fromRGB(30, 100, 200), Emoji = "🌊"},
	[1042] = {Color = Color3.fromRGB(100, 200, 255), Emoji = "❄️"},
	[1043] = {Color = Color3.fromRGB(160, 175, 255), Emoji = "🌙"},
	[1044] = {Color = Color3.fromRGB(120, 160, 210), Emoji = "🌫️"},
}

local function getSpiritIconData(spiritId, spiritRow)
	local candidates = SpiritMeshResolve.IconLookupId(spiritRow or spiritId)
	if #candidates == 0 then
		local id = tonumber(spiritId)
		if SpiritDatabaseModule.MigrateId then
			id = SpiritDatabaseModule.MigrateId(id) or id
		end
		if id then
			candidates = {id}
		end
	end
	for _, rawId in ipairs(candidates) do
		local id = tonumber(rawId)
		if SpiritDatabaseModule.MigrateId then
			id = SpiritDatabaseModule.MigrateId(id) or id
		end
		local byId = id and SpiritIcons[id]
		if byId then
			return byId
		end
		local info = id and GetSpiritInfo(id)
		local el = info and (info.Aspect or info.Element or info.PrimaryElement)
		if type(el) == "string" and ElementIcons[el] then
			return ElementIcons[el]
		end
	end
	if type(spiritRow) == "table" then
		local el = spiritRow.PrimaryElement or spiritRow.HybridPrimary or spiritRow.Element or spiritRow.Aspect
		if type(el) == "string" and ElementIcons[el] then
			return ElementIcons[el]
		end
	end
	return {Color = Color3.fromRGB(80, 80, 80), Emoji = "✦"}
end

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
	local old = playerGui:FindFirstChild("RealmOfSpiritsUI")
	if old then
		old:Destroy()
	end
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "RealmOfSpiritsUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 100
	-- Sibling: иначе Global + parent.ZIndex=50 прячет детей (пустой SpiritDetail без Закрыть)
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
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
	textButton.TextTransparency = 1
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
		textButton.TextTransparency = 0
		textButton.Text = text
	end

	return textButton
end

-- ============================================
-- Основной интерфейс
-- ============================================

local screenGui = CreateScreenGui()

-- Phase 1: daily Resonance activity bar + quest tracker
local activityBar = Instance.new("Frame")
activityBar.Name = "ResonanceActivityBar"
activityBar.Size = UDim2.fromOffset(340, 28)
activityBar.Position = UDim2.new(0.5, -170, 0, 8)
activityBar.BackgroundColor3 = Color3.fromRGB(22, 16, 32)
activityBar.BackgroundTransparency = 0.15
activityBar.BorderSizePixel = 0
activityBar.ZIndex = 20
activityBar.Parent = screenGui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = activityBar
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(180, 140, 70)
	s.Thickness = 1
	s.Transparency = 0.3
	s.Parent = activityBar
end
local activityLabel = Instance.new("TextLabel")
activityLabel.Name = "ActivityLabel"
activityLabel.Size = UDim2.new(1, -10, 1, 0)
activityLabel.Position = UDim2.new(0, 5, 0, 0)
activityLabel.BackgroundTransparency = 1
activityLabel.Font = Enum.Font.GothamBold
activityLabel.TextSize = 13
activityLabel.TextXAlignment = Enum.TextXAlignment.Center
activityLabel.TextColor3 = Color3.fromRGB(255, 230, 170)
activityLabel.Text = "День 0/4 · Уход ○ · Закалка ○ · Бой ○ · Лут ○"
activityLabel.TextSize = 12
activityLabel.TextTruncate = Enum.TextTruncate.AtEnd
activityLabel.ZIndex = 21
activityLabel.Parent = activityBar

local RefreshDexPanel

local function RefreshActivityBar(snapshot)
	local board = (snapshot and snapshot.DailyBoard)
		or (PlayerData and PlayerData.DailyBoard)
		or {}
	local daily = (snapshot and snapshot.ResonanceDaily) or (PlayerData and PlayerData.ResonanceDaily) or {}
	local care = (board.Care or daily.Care) and "✓" or "○"
	local temper = (board.Temper or daily.Temper) and "✓" or "○"
	local battle = board.BattleWin and "✓" or "○"
	local loot = board.CatchOrChest and "✓" or "○"
	local n = 0
	if care == "✓" then n += 1 end
	if temper == "✓" then n += 1 end
	if battle == "✓" then n += 1 end
	if loot == "✓" then n += 1 end
	local bonus = board.BonusNextDay and " · Бонус" or ""
	activityLabel.Text = string.format("День %d/4 · Уход %s · Закалка %s · Бой %s · Лут %s%s", n, care, temper, battle, loot, bonus)
	activityLabel.TextColor3 = (n >= 4)
		and Color3.fromRGB(120, 255, 180)
		or (board.BonusNextDay and Color3.fromRGB(255, 210, 120) or Color3.fromRGB(255, 230, 170))
	if snapshot and snapshot.Dex then
		pcall(function()
			if RefreshDexPanel then RefreshDexPanel(snapshot.Dex) end
		end)
	end
end

local dexPanel = Instance.new("Frame")
dexPanel.Name = "DexPanelFrame"
dexPanel.Size = UDim2.new(0, 320, 0, 260)
dexPanel.Position = UDim2.new(0.5, -160, 0.5, -130)
dexPanel.BackgroundColor3 = Color3.fromRGB(28, 24, 40)
dexPanel.BorderSizePixel = 0
dexPanel.Visible = false
dexPanel.ZIndex = 60
dexPanel.Parent = screenGui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = dexPanel
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(160, 120, 220)
	s.Thickness = 2
	s.Parent = dexPanel
end
local dexTitle = Instance.new("TextLabel")
dexTitle.Size = UDim2.new(1, -40, 0, 32)
dexTitle.Position = UDim2.new(0, 12, 0, 8)
dexTitle.BackgroundTransparency = 1
dexTitle.Font = Enum.Font.GothamBold
dexTitle.TextSize = 18
dexTitle.TextXAlignment = Enum.TextXAlignment.Left
dexTitle.TextColor3 = Color3.fromRGB(230, 210, 255)
dexTitle.Text = "Dex · Коллекция"
dexTitle.ZIndex = 61
dexTitle.Parent = dexPanel
local dexClose = Instance.new("TextButton")
dexClose.Size = UDim2.new(0, 28, 0, 28)
dexClose.Position = UDim2.new(1, -34, 0, 8)
dexClose.BackgroundColor3 = Color3.fromRGB(60, 40, 70)
dexClose.Text = "X"
dexClose.TextColor3 = Color3.fromRGB(255, 220, 255)
dexClose.Font = Enum.Font.GothamBold
dexClose.TextSize = 14
dexClose.ZIndex = 62
dexClose.Parent = dexPanel
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = dexClose end
dexClose.MouseButton1Click:Connect(function() dexPanel.Visible = false end)
local dexScroll = Instance.new("ScrollingFrame")
dexScroll.Name = "DexScroll"
dexScroll.Size = UDim2.new(1, -24, 1, -90)
dexScroll.Position = UDim2.new(0, 12, 0, 44)
dexScroll.BackgroundTransparency = 1
dexScroll.BorderSizePixel = 0
dexScroll.ScrollBarThickness = 6
dexScroll.ScrollBarImageColor3 = Color3.fromRGB(180, 140, 220)
dexScroll.ScrollingDirection = Enum.ScrollingDirection.Y
dexScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
dexScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
dexScroll.ClipsDescendants = true
dexScroll.ZIndex = 61
dexScroll.Parent = dexPanel
local dexBody = Instance.new("TextLabel")
dexBody.Name = "DexBody"
dexBody.Size = UDim2.new(1, -8, 0, 0)
dexBody.AutomaticSize = Enum.AutomaticSize.Y
dexBody.BackgroundTransparency = 1
dexBody.Font = Enum.Font.Gotham
dexBody.TextSize = 14
dexBody.TextXAlignment = Enum.TextXAlignment.Left
dexBody.TextYAlignment = Enum.TextYAlignment.Top
dexBody.TextColor3 = Color3.fromRGB(220, 210, 240)
dexBody.TextWrapped = true
dexBody.Text = "Соберите 3 / 6 / 12 духов одной Primary-стихии (Огонь · Земля · Ветер · Вода)."
dexBody.ZIndex = 62
dexBody.Parent = dexScroll
local dexHint = Instance.new("TextLabel")
dexHint.Size = UDim2.new(1, -24, 0, 36)
dexHint.Position = UDim2.new(0, 12, 1, -44)
dexHint.BackgroundTransparency = 1
dexHint.Font = Enum.Font.Gotham
dexHint.TextSize = 12
dexHint.TextColor3 = Color3.fromRGB(180, 160, 210)
dexHint.TextXAlignment = Enum.TextXAlignment.Left
dexHint.TextWrapped = true
dexHint.Text = "Primary: 3=+2% ATK · 6=+3% DEF · 12=+3% ATK/DEF · Aspect не дробит сет"
dexHint.ZIndex = 61
dexHint.Parent = dexPanel

RefreshDexPanel = function(dex)
	if not dex then return end
	local lines = {}
	local by = dex.ByElement or {}
	local primaryOrder = { "Fire", "Earth", "Wind", "Water" }
	local labels = (SpiritDatabaseModule.PrimaryLabelsRu)
		or { Fire = "Огонь", Earth = "Земля", Wind = "Ветер", Water = "Вода" }
	local shown = {}
	local function addLine(el)
		local n = by[el] or 0
		if n <= 0 then return end
		shown[el] = true
		local mark = (n >= 12 and "★★★") or (n >= 6 and "★★") or (n >= 3 and "★") or "·"
		local name = labels[el] or tostring(el)
		table.insert(lines, string.format("%s  %s  ×%d", mark, name, n))
	end
	for _, el in ipairs(primaryOrder) do
		addLine(el)
	end
	local extras = {}
	for el, n in pairs(by) do
		if not shown[el] and (tonumber(n) or 0) > 0 then
			table.insert(extras, el)
		end
	end
	table.sort(extras)
	for _, el in ipairs(extras) do
		addLine(el)
	end
	if #lines == 0 then
		table.insert(lines, "Пока нет духов в коллекции.")
	end
	local resonantLines = buildResonantDexLines((PlayerData and PlayerData.Spirits) or {})
	if #resonantLines > 0 then
		table.insert(lines, "")
		table.insert(lines, "── Resonant [R] ──")
		for _, rl in ipairs(resonantLines) do
			table.insert(lines, rl)
		end
	end
	local atk = math.floor((tonumber(dex.AttackPct) or 0) * 1000 + 0.5) / 10
	local def = math.floor((tonumber(dex.DefensePct) or 0) * 1000 + 0.5) / 10
	table.insert(lines, "")
	table.insert(lines, string.format("Бонус боя: ATK +%s%%  DEF +%s%%", tostring(atk), tostring(def)))
	dexBody.Text = table.concat(lines, "\n")
	dexScroll.CanvasPosition = Vector2.new(0, 0)
end

local function OpenDexPanel()
	dexPanel.Visible = true
	ResonanceEvent:FireServer("GetDex", {})
end

local dexButton = Instance.new("TextButton")
dexButton.Name = "DexButton"
dexButton.Size = UDim2.new(0, 56, 0, 22)
dexButton.Position = UDim2.new(1, -60, 0, 2)
dexButton.BackgroundColor3 = Color3.fromRGB(70, 50, 100)
dexButton.Text = "DEX"
dexButton.Font = Enum.Font.GothamBold
dexButton.TextSize = 12
dexButton.TextColor3 = Color3.fromRGB(230, 210, 255)
dexButton.ZIndex = 22
dexButton.Parent = activityBar
do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = dexButton end
dexButton.MouseButton1Click:Connect(OpenDexPanel)

local function PulseFrame(frame, color, times)
	if not frame then return end
	times = times or 3
	local stroke = frame:FindFirstChildOfClass("UIStroke")
	if not stroke then
		stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Parent = frame
	end
	local base = stroke.Color
	local baseT = stroke.Transparency
	task.spawn(function()
		for _ = 1, times do
			stroke.Color = color or Color3.fromRGB(255, 220, 100)
			stroke.Transparency = 0
			stroke.Thickness = 3
			task.wait(0.18)
			stroke.Transparency = 0.45
			stroke.Thickness = 1.5
			task.wait(0.18)
		end
		stroke.Color = base
		stroke.Transparency = baseT
		stroke.Thickness = 1
	end)
end

local careRewardCard
local function ShowCareRewardFeedback(payload)
	payload = payload or {}
	local progress = payload.Progress or {}
	local achievements = payload.Achievements or {}

	if careRewardCard then
		careRewardCard:Destroy()
		careRewardCard = nil
	end

	local card = Instance.new("Frame")
	card.Name = "CareRewardCard"
	card.Size = UDim2.fromOffset(320, 168)
	-- Keep clear of TradeFrame (shop) when open — pin under activity bar
	local tradeOpen = screenGui:FindFirstChild("TradeFrame")
	if tradeOpen and tradeOpen.Visible then
		card.Position = UDim2.new(0.5, -160, 0, 48)
	else
		card.Position = UDim2.new(0.5, -160, 0.14, 0)
	end
	card.BackgroundColor3 = Color3.fromRGB(24, 16, 36)
	card.BackgroundTransparency = 0.05
	card.BorderSizePixel = 0
	card.ClipsDescendants = true
	card.ZIndex = 90
	card.Parent = screenGui
	careRewardCard = card
	do
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 12)
		c.Parent = card
		local s = Instance.new("UIStroke")
		s.Color = Color3.fromRGB(255, 200, 90)
		s.Thickness = 2
		s.Parent = card
	end

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 28)
	title.Position = UDim2.new(0, 10, 0, 8)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 20
	title.TextColor3 = Color3.fromRGB(255, 230, 150)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Text = payload.FromPedestal and "✦ Уход у пьедестала" or "✦ Уход выполнен"
	title.ZIndex = 81
	title.Parent = card

	local bond = tonumber(progress.Bond) or 0
	local bondXp = tonumber(progress.BondXp) or 0
	local bondNeed = math.max(1, tonumber(progress.BondNeed) or 30)
	local xpGained = tonumber(progress.XpGained) or SpiritResonance.CARE_BOND_XP

	local progLabel = Instance.new("TextLabel")
	progLabel.Size = UDim2.new(1, -20, 0, 18)
	progLabel.Position = UDim2.new(0, 10, 0, 40)
	progLabel.BackgroundTransparency = 1
	progLabel.Font = Enum.Font.GothamBold
	progLabel.TextSize = 13
	progLabel.TextColor3 = Color3.fromRGB(230, 220, 200)
	progLabel.TextXAlignment = Enum.TextXAlignment.Left
	progLabel.TextTruncate = Enum.TextTruncate.AtEnd
	progLabel.Text = string.format("Резонанс Bond %d  ·  +%d XP  (%d/%d)", bond, xpGained, bondXp, bondNeed)
	progLabel.ZIndex = 81
	progLabel.Parent = card

	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(1, -20, 0, 12)
	barBg.Position = UDim2.new(0, 10, 0, 62)
	barBg.BackgroundColor3 = Color3.fromRGB(40, 30, 50)
	barBg.BorderSizePixel = 0
	barBg.ZIndex = 81
	barBg.Parent = card
	do
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(1, 0)
		c.Parent = barBg
	end
	local barFill = Instance.new("Frame")
	barFill.Name = "Fill"
	barFill.Size = UDim2.new(0, 0, 1, 0)
	barFill.BackgroundColor3 = Color3.fromRGB(255, 190, 80)
	barFill.BorderSizePixel = 0
	barFill.ZIndex = 82
	barFill.Parent = barBg
	do
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(1, 0)
		c.Parent = barFill
	end
	local ratio = math.clamp(bondXp / bondNeed, 0, 1)
	TweenService:Create(barFill, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(ratio, 0, 1, 0),
	}):Play()

	local y = 82
	for i, ach in ipairs(achievements) do
		if i > 3 then break end
		local row = Instance.new("TextLabel")
		row.Size = UDim2.new(1, -20, 0, 20)
		row.Position = UDim2.new(0, 10, 0, y)
		row.BackgroundTransparency = 1
		row.Font = Enum.Font.Gotham
		row.TextSize = 13
		row.TextColor3 = Color3.fromRGB(160, 255, 190)
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.TextTruncate = Enum.TextTruncate.AtEnd
		row.Text = string.format("★ %s — %s", tostring(ach.Title or ""), tostring(ach.Detail or ""))
		row.ZIndex = 81
		row.Parent = card
		y += 20
	end

	PulseFrame(activityBar, Color3.fromRGB(120, 255, 160), 4)
	local tracker = screenGui:FindFirstChild("QuestTrackerFrame")
	PulseFrame(tracker, Color3.fromRGB(255, 210, 80), 4)

	task.delay(4.2, function()
		if careRewardCard == card then
			card:Destroy()
			careRewardCard = nil
		end
	end)
end

local function PlayCareClientVfx()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local att = Instance.new("Attachment")
	att.Parent = hrp
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(Color3.fromRGB(255, 210, 120))
	pe.Size = NumberSequence.new(0.5, 0)
	pe.Lifetime = NumberRange.new(0.6, 1)
	pe.Speed = NumberRange.new(1, 4)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Rate = 0
	pe.Parent = att
	pe:Emit(18)
	game:GetService("Debris"):AddItem(att, 1.1)
end

pcall(function()
	QuestTrackerHud.init(screenGui, { Width = 210, Height = 200, Position = UDim2.new(1, -220, 0, 220) })
	QuestTrackerHud.bind(QuestEvent)
end)

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
	spiritNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	spiritNameLabel.TextXAlignment = Enum.TextXAlignment.Center
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

local BagContentUI = require(realmFolder:WaitForChild("BagContentUI"))
local bagUI = BagContentUI.Mount(screenGui, {
	CreateFrame = CreateFrame,
	CreateTextLabel = CreateTextLabel,
	CreateTextButton = CreateTextButton,
	StylePanel = WoWUITheme.StylePanel,
	ItemCatalog = ItemCatalog,
	bagCapacities = bagCapacities,
})
local bagContentFrame = screenGui:FindFirstChild("BagContentFrame")

local function BuildBagContentsFromInventory(inventory, bags)
	return bagUI.BuildFromInventory(inventory, bags)
end

OpenBag = function(index)
	openedBagIndex = index
	bagUI.Open(index)
end

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
	currentBagContents = bagUI.BuildFromInventory(PlayerData.Inventory, bags)
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
	openedBagIndex = bagUI.GetOpenedIndex()
	bagUI.RefreshOpened()
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
	UDim2.new(0.5, -275, 1, -152),
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
	UDim2.new(0.5, -320, 1, -96),
	UDim2.new(0, 640, 0, 54),
	WoWUITheme.Colors.Stone
)
WoWUITheme.StylePanel(actionsFrame, "stone")
pcall(function()
	screenGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
end)

-- Кнопка ловли
local catchButton = CreateTextButton(actionsFrame, "CatchButton",
	UDim2.new(0, 10, 0, 5),
	UDim2.new(0, 88, 0, 44),
	"Поймать [E]",
	Color3.fromRGB(70, 180, 70),
	"🎯"
)

-- Кнопка битвы
local battleButton = CreateTextButton(actionsFrame, "BattleButton",
	UDim2.new(0, 108, 0, 5),
	UDim2.new(0, 88, 0, 44),
	"Бой [F]",
	Color3.fromRGB(180, 70, 70),
	"⚔️"
)

-- Кнопка меню
local menuButton = CreateTextButton(actionsFrame, "MenuButton",
	UDim2.new(0, 206, 0, 5),
	UDim2.new(0, 88, 0, 44),
	"Меню [Tab]",
	Color3.fromRGB(70, 130, 180),
	"📜"
)

-- Магазин (Haven / пьедестал)
local shopButton = CreateTextButton(actionsFrame, "ShopButton",
	UDim2.new(0, 304, 0, 5),
	UDim2.new(0, 88, 0, 44),
	"Магазин",
	Color3.fromRGB(180, 140, 70),
	"🛒"
)

WoWUITheme.StyleActionButton(catchButton)
WoWUITheme.StyleActionButton(battleButton)
WoWUITheme.StyleActionButton(menuButton)
WoWUITheme.StyleActionButton(shopButton)

-- ============================================
-- Боевой интерфейс (нижняя панель, не перекрывает центр экрана)
-- ============================================

local battleFrame = CreateFrame(screenGui, "BattleFrame",
	UDim2.new(0, 0, 1, -188),
	UDim2.new(1, 0, 0, 178),
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

local battleElementTip = CreateTextLabel(battleFrame, "BattleElementTip",
	UDim2.new(0, 110, 0, 5),
	UDim2.new(0, 220, 0, 25),
	"",
	Color3.fromRGB(255, 220, 140),
	12
)
battleElementTip.TextXAlignment = Enum.TextXAlignment.Left
battleElementTip.TextTruncate = Enum.TextTruncate.AtEnd

local battleAgencyFlash = Instance.new("Frame")
battleAgencyFlash.Name = "BattleAgencyFlash"
battleAgencyFlash.Size = UDim2.new(1, 0, 1, 0)
battleAgencyFlash.BackgroundColor3 = Color3.fromRGB(120, 255, 160)
battleAgencyFlash.BackgroundTransparency = 1
battleAgencyFlash.BorderSizePixel = 0
battleAgencyFlash.ZIndex = 20
battleAgencyFlash.Visible = false
battleAgencyFlash.Parent = battleFrame

local function PulseBattleAgency(kind)
	if not battleAgencyFlash then return end
	local color = Color3.fromRGB(200, 200, 200)
	if kind == "strong" then
		color = Color3.fromRGB(80, 255, 140)
	elseif kind == "weak" then
		color = Color3.fromRGB(255, 120, 90)
	end
	battleAgencyFlash.BackgroundColor3 = color
	battleAgencyFlash.Visible = true
	battleAgencyFlash.BackgroundTransparency = 0.55
	task.spawn(function()
		for t = 1, 8 do
			battleAgencyFlash.BackgroundTransparency = 0.55 + t * 0.05
			task.wait(0.04)
		end
		battleAgencyFlash.Visible = false
		battleAgencyFlash.BackgroundTransparency = 1
	end)
end

-- Лог боя (справа, скролл истории — не пересекается с ElementTip)
local battleLogLines = {}
local BATTLE_LOG_MAX = 14
local battleLogScroll = Instance.new("ScrollingFrame")
battleLogScroll.Name = "BattleLogScroll"
battleLogScroll.Position = UDim2.new(1, -310, 0, 8)
battleLogScroll.Size = UDim2.fromOffset(295, 100)
battleLogScroll.BackgroundColor3 = Color3.fromRGB(22, 20, 28)
battleLogScroll.BackgroundTransparency = 0.35
battleLogScroll.BorderSizePixel = 0
battleLogScroll.ScrollBarThickness = 5
battleLogScroll.ScrollBarImageColor3 = Color3.fromRGB(200, 160, 100)
battleLogScroll.ScrollingDirection = Enum.ScrollingDirection.Y
battleLogScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
battleLogScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
battleLogScroll.ClipsDescendants = true
battleLogScroll.ZIndex = 5
battleLogScroll.Parent = battleFrame
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = battleLogScroll
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 4)
	pad.PaddingBottom = UDim.new(0, 4)
	pad.PaddingLeft = UDim.new(0, 6)
	pad.PaddingRight = UDim.new(0, 6)
	pad.Parent = battleLogScroll
end
local battleLogLabel = CreateTextLabel(battleLogScroll, "BattleLogLabel",
	UDim2.new(0, 0, 0, 0),
	UDim2.new(1, -4, 0, 0),
	"",
	Color3.fromRGB(200, 200, 200),
	12
)
battleLogLabel.AutomaticSize = Enum.AutomaticSize.Y
battleLogLabel.TextWrapped = true
battleLogLabel.TextXAlignment = Enum.TextXAlignment.Left
battleLogLabel.TextYAlignment = Enum.TextYAlignment.Top
battleLogLabel.ZIndex = 6

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
	UDim2.new(0.20, 5, 0, 118),
	UDim2.new(0.125, 0, 0, 48),
	"Коготь Духа",
	Color3.fromRGB(180, 70, 70),
	"🐾"
)

local attack2Button = CreateTextButton(battleFrame, "Attack2Button",
	UDim2.new(0.325, 0, 0, 118),
	UDim2.new(0.125, 0, 0, 48),
	"Призрачный Вихрь",
	Color3.fromRGB(180, 70, 70),
	"🌀"
)

local attack3Button = CreateTextButton(battleFrame, "Attack3Button",
	UDim2.new(0.45, -5, 0, 118),
	UDim2.new(0.125, 0, 0, 48),
	"Навык 3",
	Color3.fromRGB(180, 70, 70),
	"✦"
)
attack3Button.Visible = false

do
	for _, btn in ipairs({attack1Button, attack2Button, attack3Button}) do
		local icon = btn:FindFirstChild("IconLabel")
		local label = btn:FindFirstChild("ButtonLabel")
		if icon and icon:IsA("TextLabel") then
			icon.Size = UDim2.new(1, 0, 0.42, 0)
			icon.TextSize = 18
		end
		if label and label:IsA("TextLabel") then
			label.Position = UDim2.new(0, 2, 0.42, 0)
			label.Size = UDim2.new(1, -4, 0.58, 0)
			label.TextSize = 11
			label.TextScaled = true
			label.TextWrapped = true
			local constraint = label:FindFirstChildOfClass("UITextSizeConstraint")
			if not constraint then
				constraint = Instance.new("UITextSizeConstraint")
				constraint.Parent = label
			end
			constraint.MinTextSize = 8
			constraint.MaxTextSize = 12
		end
	end
end

local potionButton = CreateTextButton(battleFrame, "PotionButton",
	UDim2.new(0.58, -5, 0, 118),
	UDim2.new(0.1, 0, 0, 48),
	"Зелье x0",
	Color3.fromRGB(70, 160, 100),
	"🧪"
)

local fleeButton = CreateTextButton(battleFrame, "FleeButton",
	UDim2.new(0.68, -5, 0, 118),
	UDim2.new(0.1, 0, 0, 48),
	"Побег",
	Color3.fromRGB(100, 100, 180),
	"🏃"
)
WoWUITheme.StyleActionButton(attack1Button)
WoWUITheme.StyleActionButton(attack2Button)
WoWUITheme.StyleActionButton(attack3Button)
WoWUITheme.StyleActionButton(potionButton)
WoWUITheme.StyleActionButton(fleeButton)

-- ============================================
-- Подсказки
-- ============================================

local hintFrame = CreateFrame(screenGui, "HintFrame",
	UDim2.new(0.5, -280, 1, -128),
	UDim2.new(0, 560, 0, 48),
	Color3.fromRGB(28, 22, 40)
)
hintFrame.Visible = false
hintFrame.BackgroundTransparency = 0.25
hintFrame.ZIndex = 40

local hintText = CreateTextLabel(hintFrame, "HintText",
	UDim2.new(0, 12, 0, 0),
	UDim2.new(1, -24, 1, 0),
	"",
	Color3.fromRGB(255, 245, 210),
	16
)
hintText.TextWrapped = true
hintText.TextTruncate = Enum.TextTruncate.AtEnd
hintText.ZIndex = 41

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
			if element == hintFrame then
				element.Visible = hintText.Text ~= ""
			else
				element.Visible = true
			end
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
	if spiritDetailFrame then
		spiritDetailFrame.Visible = false
	end
	if UpdateBattleLog then
		UpdateBattleLog("")
	end
	if battleElementTip then
		battleElementTip.Text = ""
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
	UDim2.new(0.5, -200, 0.5, -230),
	UDim2.new(0, 400, 0, 450),
	Color3.fromRGB(30, 30, 40)
)
spiritDetailFrame.Visible = false
spiritDetailFrame.ClipsDescendants = true
spiritDetailFrame.ZIndex = 50

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
detailSpiritName.TextXAlignment = Enum.TextXAlignment.Left
detailSpiritName.TextTruncate = Enum.TextTruncate.AtEnd

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

-- Навыки духа (scroll — каталог может быть длинным)
local detailSkillsScroll = Instance.new("ScrollingFrame")
detailSkillsScroll.Name = "DetailSkillsScroll"
detailSkillsScroll.Position = UDim2.new(0, 10, 0, 190)
detailSkillsScroll.Size = UDim2.new(1, -20, 0, 56)
detailSkillsScroll.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
detailSkillsScroll.BorderSizePixel = 0
detailSkillsScroll.ScrollBarThickness = 5
detailSkillsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
detailSkillsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
detailSkillsScroll.ScrollingDirection = Enum.ScrollingDirection.Y
detailSkillsScroll.ClipsDescendants = true
detailSkillsScroll.Parent = spiritDetailFrame
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = detailSkillsScroll
end

local detailSpiritSkills = Instance.new("TextLabel")
detailSpiritSkills.Name = "DetailSpiritSkills"
detailSpiritSkills.Size = UDim2.new(1, -10, 0, 0)
detailSpiritSkills.AutomaticSize = Enum.AutomaticSize.Y
detailSpiritSkills.BackgroundTransparency = 1
detailSpiritSkills.Font = Enum.Font.Gotham
detailSpiritSkills.TextSize = 12
detailSpiritSkills.TextColor3 = Color3.fromRGB(200, 200, 200)
detailSpiritSkills.TextXAlignment = Enum.TextXAlignment.Left
detailSpiritSkills.TextYAlignment = Enum.TextYAlignment.Top
detailSpiritSkills.TextWrapped = true
detailSpiritSkills.Text = "Навыки:\n- Базовая атака (ур. 1)"
detailSpiritSkills.Parent = detailSkillsScroll

-- Кнопка эволюции (активна если достаточно прокачаны скилы)
local evolveButtonEnabled = false
local detailEvolveButton = CreateTextButton(spiritDetailFrame, "DetailEvolveButton",
	UDim2.new(0.5, -100, 0, 318),
	UDim2.new(0, 200, 0, 36),
	"ЭВОЛЮЦИЯ",
	Color3.fromRGB(80, 80, 80),
	"🧬"
)

local detailEvoProgressLabel = CreateTextLabel(spiritDetailFrame, "DetailEvoProgress",
	UDim2.new(0, 10, 0, 278),
	UDim2.new(0.9, 0, 0, 36),
	"Эволюция: —",
	Color3.fromRGB(255, 220, 140),
	12
)
if detailEvoProgressLabel then
	detailEvoProgressLabel.TextXAlignment = Enum.TextXAlignment.Left
	detailEvoProgressLabel.TextYAlignment = Enum.TextYAlignment.Top
	detailEvoProgressLabel.TextWrapped = true
end

local detailResonanceLabel = CreateTextLabel(spiritDetailFrame, "DetailResonance",
	UDim2.new(0, 10, 0, 250),
	UDim2.new(0.9, 0, 0, 26),
	"Резонанс: Bond 0 | Temper —",
	Color3.fromRGB(180, 220, 255),
	13
)
detailResonanceLabel.TextTruncate = Enum.TextTruncate.AtEnd

local detailCareButton = CreateTextButton(spiritDetailFrame, "DetailCareButton",
	UDim2.new(0.5, -185, 0, 360),
	UDim2.new(0, 170, 0, 34),
	"УХОД",
	Color3.fromRGB(70, 140, 90),
	"💚"
)

local detailTemperButton = CreateTextButton(spiritDetailFrame, "DetailTemperButton",
	UDim2.new(0.5, 15, 0, 360),
	UDim2.new(0, 170, 0, 34),
	"ЗАКАЛКА",
	Color3.fromRGB(70, 100, 160),
	"⚔"
)

-- Кнопка закрытия
local detailCloseButton = CreateTextButton(spiritDetailFrame, "DetailCloseButton",
	UDim2.new(0.5, -60, 0, 400),
	UDim2.new(0, 120, 0, 32),
	"Закрыть",
	Color3.fromRGB(100, 100, 100),
	"❌"
)
-- На случай Global: дети должны быть выше фона панели
do
	local baseZ = spiritDetailFrame.ZIndex
	for _, d in ipairs(spiritDetailFrame:GetDescendants()) do
		if d:IsA("GuiObject") then
			d.ZIndex = math.max(d.ZIndex, baseZ + 1)
		end
	end
end

-- Пикер закалки (пьедестал шлёт OpenTemperPicker; кнопка ЗАКАЛКА тоже)
local temperPickerFrame = CreateFrame(screenGui, "TemperPickerFrame",
	UDim2.new(0.5, -170, 0.5, -120),
	UDim2.new(0, 340, 0, 240),
	Color3.fromRGB(28, 32, 48)
)
temperPickerFrame.Visible = false
temperPickerFrame.ZIndex = 70
WoWUITheme.StylePanel(temperPickerFrame, "stone")

CreateTextLabel(temperPickerFrame, "TemperPickerTitle",
	UDim2.new(0, 12, 0, 10),
	UDim2.new(1, -24, 0, 28),
	"ЗАКАЛКА · выберите фокус",
	Color3.fromRGB(180, 210, 255),
	18
).TextXAlignment = Enum.TextXAlignment.Left

local temperPickerHint = CreateTextLabel(temperPickerFrame, "TemperPickerHint",
	UDim2.new(0, 12, 0, 42),
	UDim2.new(1, -24, 0, 40),
	"Нужно 15 Stam или камень закалки",
	Color3.fromRGB(200, 200, 220),
	13
)
temperPickerHint.TextXAlignment = Enum.TextXAlignment.Left
temperPickerHint.TextWrapped = true

local function OpenTemperPicker()
	if not selectedSpiritIndex then
		selectedSpiritIndex = (PlayerData and tonumber(PlayerData.ActiveSpiritIndex)) or 1
	end
	local stam = (PlayerData and tonumber(PlayerData.SpiritStamina)) or 0
	local stones = 0
	for _, inv in ipairs((PlayerData and PlayerData.Inventory) or {}) do
		if tonumber(inv.Id) == 5 then
			stones = tonumber(inv.Quantity) or 0
			break
		end
	end
	temperPickerHint.Text = string.format(
		"Слот %d · Stam %d/15 · камней закалки: %d\nАтака / Защита / Дух",
		selectedSpiritIndex, stam, stones
	)
	temperPickerFrame.Visible = true
end

do
	local focuses = {
		{ Key = "Attack", Label = "АТАКА", Color = Color3.fromRGB(180, 70, 70), Pos = UDim2.new(0, 16, 0, 95) },
		{ Key = "Defense", Label = "ЗАЩИТА", Color = Color3.fromRGB(70, 120, 180), Pos = UDim2.new(0, 16, 0, 138) },
		{ Key = "Spirit", Label = "ДУХ", Color = Color3.fromRGB(120, 80, 180), Pos = UDim2.new(0, 16, 0, 181) },
	}
	for _, f in ipairs(focuses) do
		local btn = CreateTextButton(temperPickerFrame, "TemperFocus_" .. f.Key,
			f.Pos, UDim2.new(1, -32, 0, 36), f.Label, f.Color, nil)
		btn.MouseButton1Click:Connect(function()
			local idx = selectedSpiritIndex or (PlayerData and PlayerData.ActiveSpiritIndex) or 1
			temperPickerFrame.Visible = false
			ResonanceEvent:FireServer("Temper", { SpiritIndex = idx, Focus = f.Key })
		end)
	end
	local closeTemper = CreateTextButton(temperPickerFrame, "TemperPickerClose",
		UDim2.new(1, -44, 0, 8), UDim2.new(0, 32, 0, 28), "X", Color3.fromRGB(90, 90, 100), nil)
	closeTemper.MouseButton1Click:Connect(function()
		temperPickerFrame.Visible = false
	end)
	local baseZ = temperPickerFrame.ZIndex
	for _, d in ipairs(temperPickerFrame:GetDescendants()) do
		if d:IsA("GuiObject") then
			d.ZIndex = math.max(d.ZIndex, baseZ + 1)
		end
	end
end

-- Identity slice 3: evo progress on spirit card (lvl/bond/wins/crystals + skill teaser)
local function countInventoryItem(itemId)
	local have = 0
	for _, inv in ipairs((PlayerData and PlayerData.Inventory) or {}) do
		if tonumber(inv.Id) == tonumber(itemId) then
			have = tonumber(inv.Quantity) or 0
			break
		end
	end
	return have
end

local function ApplyEvoProgressUI(spirit)
	if not detailEvoProgressLabel then
		return false
	end
	if not spirit then
		detailEvoProgressLabel.Text = "Эволюция: —"
		evolveButtonEnabled = false
		detailEvolveButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		local lbl = detailEvolveButton:FindFirstChild("ButtonLabel")
		if lbl then lbl.Text = "ЭВОЛЮЦИЯ" end
		return false
	end
	local rule = SpiritDatabaseModule.GetEvolutionRule and SpiritDatabaseModule.GetEvolutionRule(spirit.Id)
	if not rule then
		detailEvoProgressLabel.Text = "Эволюция: финальная форма"
		evolveButtonEnabled = false
		detailEvolveButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		local lbl = detailEvolveButton:FindFirstChild("ButtonLabel")
		if lbl then lbl.Text = "Макс. форма" end
		return false
	end
	local evoInfo = SpiritDatabaseModule.GetDisplay and SpiritDatabaseModule.GetDisplay(rule.EvolvedId)
		or SpiritDatabaseModule.Get(rule.EvolvedId)
	local evoName = (evoInfo and evoInfo.Name) or ("#" .. tostring(rule.EvolvedId))
	local teaser = ""
	if SpiritDatabaseModule.GetSkillNames and evoInfo then
		local names = SpiritDatabaseModule.GetSkillNames(evoInfo)
		if type(names) == "table" and names[1] then
			teaser = " · удар «" .. tostring(names[1]) .. "»"
		end
	end
	local lvl = tonumber(spirit.Level) or 1
	local needLvl = tonumber(rule.RequiredLevel) or 1
	local bond = tonumber(spirit.Bond) or 0
	local needBond = tonumber(rule.RequiredBond) or 0
	local wins = tonumber(PlayerData and PlayerData.Stats and PlayerData.Stats.EnemiesDefeated) or 0
	local needWins = tonumber(rule.RequiredBattles) or 0
	local cryHave, cryNeed, cryName = 0, 0, "кристаллы"
	local req = rule.RequiredItems and rule.RequiredItems[1]
	if type(req) == "table" then
		cryNeed = tonumber(req.Quantity) or 0
		cryHave = countInventoryItem(req.Id)
		local item = ItemCatalog.Get and ItemCatalog.Get(req.Id)
		cryName = (item and item.Name) or ("#" .. tostring(req.Id))
	end
	local can = lvl >= needLvl and bond >= needBond and wins >= needWins and cryHave >= cryNeed
	detailEvoProgressLabel.Text = string.format(
		"→ %s%s\nУр.%d/%d · Bond %d/%d · Побед %d/%d · %s %d/%d",
		evoName, teaser,
		lvl, needLvl, bond, needBond, wins, needWins, cryName, cryHave, cryNeed
	)
	evolveButtonEnabled = can
	detailEvolveButton.BackgroundColor3 = can and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(80, 80, 80)
	local lbl = detailEvolveButton:FindFirstChild("ButtonLabel")
	if lbl then lbl.Text = can and "ЭВОЛЮЦИЯ" or "Ещё рано" end
	return can
end

-- Функция открытия панели свойств духа
OpenSpiritDetail = function(index)
	local spirit = PlayerData.Spirits and PlayerData.Spirits[index]
	if not spirit then
		ShowNotification("Слот " .. index .. " пуст!")
		return
	end

	local spiritInfo = ResolveOwnedSpiritDisplay(spirit)
	if not spiritInfo then return end

	-- Заполняем информацию
	detailSpiritName.Text = "Имя: " .. tostring(spiritInfo.Name)
	detailSpiritLevel.Text = "Уровень: " .. (spirit.Level or 1)
	local rarityText = spiritInfo.Rarity or "-"
	if isResonantSpirit(spirit) then
		rarityText = "[R] Resonant"
	end
	detailSpiritElement.Text = "Элемент: "
		.. (spiritInfo.ElementLabel or spiritInfo.Element or "-")
		.. " | "
		.. rarityText

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

	local bond = spirit.Bond or 0
	local bondXp = spirit.BondXp or 0
	local bondNeed = SpiritResonance.BondXpToNext(bond)
	local tp = spirit.TemperPoints or {}
	detailResonanceLabel.Text = string.format(
		"Резонанс: Bond %d (%d/%d) | Temper A%d/D%d/S%d | Stam %d",
		bond, bondXp, bondNeed,
		tp.Attack or 0, tp.Defense or 0, tp.Spirit or 0,
		PlayerData.SpiritStamina or 100
	)

	-- Навыки: каталог / SkillIds инстанса (Identity: после эволюции слот 1 виден)
	local skillsText = "Навыки:\n"
	local skillNames = {}
	if type(spirit.Skills) == "table" and #spirit.Skills > 0 then
		for _, sk in ipairs(spirit.Skills) do
			if type(sk) == "string" then
				table.insert(skillNames, sk)
			elseif type(sk) == "table" and sk.Name then
				table.insert(skillNames, tostring(sk.Name))
			end
		end
	end
	if #skillNames == 0 and SpiritDatabaseModule.GetSkillNames then
		local fromDb = SpiritDatabaseModule.GetSkillNames(spiritInfo)
		if type(fromDb) == "table" then
			for _, name in ipairs(fromDb) do
				table.insert(skillNames, tostring(name))
			end
		end
	end
	if #skillNames == 0 and type(spirit.SkillIds) == "table" then
		for _, sid in ipairs(spirit.SkillIds) do
			local sk = SkillCatalog.Get and SkillCatalog.Get(sid)
			table.insert(skillNames, (sk and sk.Name) or ("#" .. tostring(sid)))
		end
	end
	if #skillNames > 0 then
		for i, name in ipairs(skillNames) do
			skillsText = skillsText .. string.format("- %s%s\n", name, i == 1 and " ★" or "")
		end
	else
		skillsText = skillsText .. "- нет данных\n"
	end
	detailSpiritSkills.Text = skillsText

	if isResonantSpirit(spirit) then
		local parents = formatParentIds(spirit.ParentIds)
		local stars = formatStarTierHint(spirit.StarScore, spirit.ResonancePower)
		local pow = tonumber(spirit.ResonancePower) or 0
		detailEvoProgressLabel.Text = string.format(
			"[R] Resonant · слот %d\nvid %s · %s · сила %.2f",
			index, parents, stars, pow
		)
		detailEvoProgressLabel.TextColor3 = Color3.fromRGB(200, 180, 255)
		evolveButtonEnabled = false
		detailEvolveButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		local evoLbl = detailEvolveButton:FindFirstChild("ButtonLabel")
		if evoLbl then
			evoLbl.Text = "Ками"
		end
	else
		detailEvoProgressLabel.TextColor3 = Color3.fromRGB(255, 220, 140)
		ApplyEvoProgressUI(spirit)
	end

	spiritDetailFrame.Visible = true

	-- Запрашиваем информацию об эволюции у сервера (тихо обновит карточку)
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
skillsFrame.ClipsDescendants = true

local skillsTitle = CreateTextLabel(skillsFrame, "SkillsTitle",
	UDim2.new(0, 10, 0, 5),
	UDim2.new(0.9, 0, 0, 20),
	"Разблокированные навыки:",
	Color3.fromRGB(255, 215, 0),
	12
)

local skillsScroll = Instance.new("ScrollingFrame")
skillsScroll.Name = "SkillsScroll"
skillsScroll.Position = UDim2.new(0, 6, 0, 26)
skillsScroll.Size = UDim2.new(1, -12, 1, -32)
skillsScroll.BackgroundTransparency = 1
skillsScroll.BorderSizePixel = 0
skillsScroll.ScrollBarThickness = 5
skillsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
skillsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
skillsScroll.ScrollingDirection = Enum.ScrollingDirection.Y
skillsScroll.ClipsDescendants = true
skillsScroll.Parent = skillsFrame

local skillsListLabel = Instance.new("TextLabel")
skillsListLabel.Name = "SkillsListLabel"
skillsListLabel.Size = UDim2.new(1, -8, 0, 0)
skillsListLabel.AutomaticSize = Enum.AutomaticSize.Y
skillsListLabel.BackgroundTransparency = 1
skillsListLabel.Font = Enum.Font.Gotham
skillsListLabel.TextSize = 11
skillsListLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
skillsListLabel.TextXAlignment = Enum.TextXAlignment.Left
skillsListLabel.TextYAlignment = Enum.TextYAlignment.Top
skillsListLabel.TextWrapped = true
skillsListLabel.Text = "- Касание Призрака (ур. 1)\n- Удар силой (ур. 3)\n- Первая помощь (ур. 5)"
skillsListLabel.Parent = skillsScroll


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
local requirementsScroll = Instance.new("ScrollingFrame")
requirementsScroll.Name = "RequirementsScroll"
requirementsScroll.Position = UDim2.new(0, 10, 0, 130)
requirementsScroll.Size = UDim2.new(0.9, 0, 0, 100)
requirementsScroll.BackgroundTransparency = 1
requirementsScroll.BorderSizePixel = 0
requirementsScroll.ScrollBarThickness = 5
requirementsScroll.ScrollBarImageColor3 = Color3.fromRGB(180, 160, 100)
requirementsScroll.ScrollingDirection = Enum.ScrollingDirection.Y
requirementsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
requirementsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
requirementsScroll.ClipsDescendants = true
requirementsScroll.Parent = rankFrame
local requirementsLabel = CreateTextLabel(requirementsScroll, "RequirementsLabel",
	UDim2.new(0, 0, 0, 0),
	UDim2.new(1, -6, 0, 0),
	"Требования:\n- Уровень: 11 (текущий: 1)\n- Победы: 20 (текущие: 0)\n- Духи: 5 (текущие: 0)\n- Квесты: 3 (текущие: 0)",
	Color3.fromRGB(200, 200, 200),
	12
)
requirementsLabel.AutomaticSize = Enum.AutomaticSize.Y
requirementsLabel.TextWrapped = true
requirementsLabel.TextYAlignment = Enum.TextYAlignment.Top
requirementsLabel.TextXAlignment = Enum.TextXAlignment.Left

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
profileRankLabel.TextTruncate = Enum.TextTruncate.AtEnd

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
-- Интерфейс магазина (TradePanelUI — вынесен из-за лимита 200 locals)
-- ============================================

local TradePanelUI = require(realmFolder:WaitForChild("TradePanelUI"))
local tradeUI = TradePanelUI.Mount(screenGui, {
	CreateFrame = CreateFrame,
	CreateTextLabel = CreateTextLabel,
	CreateTextButton = CreateTextButton,
	ItemCatalog = ItemCatalog,
	SpiritDatabaseModule = SpiritDatabaseModule,
	TradeEvent = TradeEvent,
	getPlayerData = function()
		return PlayerData
	end,
})

local function RefreshTradeInventory()
	tradeUI.RefreshInventory()
end

local function RefreshShopList(items)
	tradeUI.RefreshShop(items)
end

-- ============================================
-- Уведомления
-- ============================================

local notificationFrame = CreateFrame(screenGui, "NotificationFrame",
	UDim2.new(0.5, -230, 0, 88),
	UDim2.new(0, 460, 0, 48),
	Color3.fromRGB(40, 40, 50)
)
notificationFrame.BackgroundTransparency = 1
notificationFrame.Visible = false
notificationFrame.ZIndex = 40
notificationFrame.ClipsDescendants = true

local notificationLabel = CreateTextLabel(notificationFrame, "NotificationLabel",
	UDim2.new(0, 10, 0, 0),
	UDim2.new(1, -20, 1, 0),
	"",
	Color3.fromRGB(255, 230, 120),
	16
)
notificationLabel.ZIndex = 41
notificationLabel.TextWrapped = true
notificationLabel.TextTruncate = Enum.TextTruncate.AtEnd
notificationLabel.TextStrokeTransparency = 0.35
notificationLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)

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

UpdateHint = function(_text)
	-- Transient TargetHint bar disabled (UX cleanup 2026-08-28)
	if hintText then
		hintText.Text = ""
	end
	if hintFrame then
		hintFrame.Visible = false
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
	bagUI.SetCurrency(g, s, c)
	tradeUI.SetCoins(g, s, c)
end

local function UpdateRank(_rankName, _rankTitle, _rankColor)
	-- ранг доступен через кнопку «Ранг»
end

local currentTrapCount = 0

local function UpdateTraps(trapCount)
	currentTrapCount = math.max(0, tonumber(trapCount) or 0)
	local catchReady = currentTrapCount > 0 and player:GetAttribute("CatchUiActive") == true
	if catchButton then
		catchButton.AutoButtonColor = currentTrapCount > 0
		catchButton.Active = true
		local caption = "Поймать [E]"
		if catchReady then
			catchButton.BackgroundTransparency = 0
			catchButton.BackgroundColor3 = Color3.fromRGB(90, 230, 100)
			caption = string.format("Поймать [E]! ×%d", currentTrapCount)
		elseif currentTrapCount > 0 then
			-- Dim outside catch context (Safe / no target)
			catchButton.BackgroundTransparency = 0.35
			catchButton.BackgroundColor3 = Color3.fromRGB(55, 110, 60)
			caption = string.format("Поймать [E] ×%d", currentTrapCount)
		else
			catchButton.BackgroundTransparency = 0.15
			catchButton.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
			caption = "Нет ловушек"
		end
		-- Never set TextButton.Text when ButtonLabel exists (double text ghosting)
		catchButton.Text = ""
		catchButton.TextTransparency = 1
		local label = catchButton:FindFirstChild("ButtonLabel")
		if label and label:IsA("TextLabel") then
			label.Text = caption
		end
	end
end

_G.GetTrapCount = function()
	return currentTrapCount
end

_G.ConsumeLocalTrap = function()
	if currentTrapCount > 0 then
		UpdateTraps(currentTrapCount - 1)
	end
end

_G.ShowNoTrapMessage = function()
	if ShowNotification then
		ShowNotification("Нет ловушек! Купите в магазине Otaku Haven.", 3)
	end
end

_G.UpdateCatchAvailability = function()
	UpdateTraps(currentTrapCount)
end

player:GetAttributeChangedSignal("CatchUiActive"):Connect(function()
	UpdateTraps(currentTrapCount)
end)

local notificationToken = 0
pcall(function()
	ToastRouter.Bind(notificationFrame, notificationLabel)
end)
_G.RoS_Notify = function(text, duration, priority, color)
	ToastRouter.Notify(text, duration, priority, color)
end
ShowNotification = function(text, duration, priority)
	if type(text) ~= "string" or text == "" then
		return
	end
	if not priority then
		if string.find(text, "Недостаточно", 1, true)
			or string.find(text, "перезаряжается", 1, true)
			or string.find(text, "Ошибка", 1, true)
			or string.find(text, "Не удалось", 1, true)
			or string.find(text, "пуст", 1, true)
		then
			priority = "Critical"
		elseif string.find(text, "Собран", 1, true)
			or string.find(text, "XP", 1, true)
			or string.find(text, "меди", 1, true)
			or string.find(text, "поймали", 1, true)
			or string.find(text, "Победа", 1, true)
			or string.find(text, "награда", 1, true)
		then
			priority = "Reward"
		else
			priority = "Tip"
		end
	end
	ToastRouter.Notify(text, duration or 4, priority)
end

UpdateBattleLog = function(text)
	if type(text) ~= "string" or text == "" then
		table.clear(battleLogLines)
		battleLogLabel.Text = ""
		battleLogScroll.CanvasPosition = Vector2.new(0, 0)
		return
	end
	table.insert(battleLogLines, text)
	while #battleLogLines > BATTLE_LOG_MAX do
		table.remove(battleLogLines, 1)
	end
	battleLogLabel.Text = table.concat(battleLogLines, "\n")
	task.defer(function()
		local canvasH = battleLogLabel.AbsoluteSize.Y
		local viewH = battleLogScroll.AbsoluteWindowSize.Y
		if viewH <= 0 then
			viewH = battleLogScroll.AbsoluteSize.Y
		end
		battleLogScroll.CanvasPosition = Vector2.new(0, math.max(0, canvasH - viewH))
	end)
end

local function SetBattleSkillButton(button, defaultText, skillData, playerMP, hotkey)
	local label = button:FindFirstChild("ButtonLabel")
	local title = defaultText
	local hk = hotkey and ("[" .. tostring(hotkey) .. "] ") or ""
	local remainingCd = 0
	local cost = 0
	local maxCd = 0
	local lowMp = false
	if skillData then
		remainingCd = tonumber(skillData.Cooldown) or 0
		cost = tonumber(skillData.Cost) or 0
		maxCd = tonumber(skillData.MaxCooldown) or 0
		local name = skillData.Name or defaultText
		lowMp = (tonumber(playerMP) or 0) < cost
		if remainingCd > 0.05 then
			if cost > 0 then
				title = string.format("%s%s\nCD %.1fс · %dMP", hk, name, remainingCd, cost)
			else
				title = string.format("%s%s\nCD %.1fс", hk, name, remainingCd)
			end
		elseif cost > 0 and maxCd > 0.05 then
			title = string.format("%s%s\n%dMP · CD%.0fс", hk, name, cost, maxCd)
		elseif cost > 0 then
			title = string.format("%s%s\n%dMP", hk, name, cost)
		elseif maxCd > 0.05 then
			title = string.format("%s%s\nCD%.0fс", hk, name, maxCd)
		else
			title = hk .. name
		end
	else
		title = hk .. title
	end
	if label then
		label.Text = title
		if lowMp and remainingCd <= 0.05 then
			label.TextColor3 = Color3.fromRGB(255, 190, 160)
		elseif remainingCd > 0.05 then
			label.TextColor3 = Color3.fromRGB(210, 210, 220)
		else
			label.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	else
		button.Text = title
	end

	local onCd = skillData ~= nil and remainingCd > 0.05
	local disabled = (not skillData) or onCd or lowMp
	local readyColor = Color3.fromRGB(180, 70, 70)
	if skillData and skillData.Element then
		local el = skillData.Element
		if el == "Fire" or el == "Ash" or el == "Magma" or el == "Light" then
			readyColor = Color3.fromRGB(200, 80, 50)
		elseif el == "Earth" or el == "Nature" or el == "Metal" or el == "Poison" then
			readyColor = Color3.fromRGB(120, 150, 70)
		elseif el == "Wind" or el == "Storm" or el == "Dark" or el == "Sky" or el == "Lightning" then
			readyColor = Color3.fromRGB(70, 160, 200)
		elseif el == "Water" or el == "Ice" or el == "Moon" or el == "Mist" then
			readyColor = Color3.fromRGB(60, 120, 210)
		end
	end
	local disabledColor = Color3.fromRGB(95, 95, 95)
	if lowMp and not onCd then
		disabledColor = Color3.fromRGB(95, 70, 90)
	end
	button.BackgroundColor3 = disabled and disabledColor or readyColor
	button.Active = not disabled
	button.AutoButtonColor = not disabled

	-- Visual CD fill (remaining ratio); text CD/MP stays
	local fill = button:FindFirstChild("CdFill")
	if not fill then
		fill = Instance.new("Frame")
		fill.Name = "CdFill"
		fill.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
		fill.BackgroundTransparency = 0.4
		fill.BorderSizePixel = 0
		fill.ZIndex = math.max(1, (button.ZIndex or 1))
		fill.AnchorPoint = Vector2.new(0, 1)
		fill.Position = UDim2.new(0, 0, 1, 0)
		fill.Parent = button
	end
	if label then
		label.ZIndex = fill.ZIndex + 1
	end
	if onCd and maxCd > 0.05 then
		local ratio = math.clamp(remainingCd / maxCd, 0, 1)
		fill.Size = UDim2.new(1, 0, ratio, 0)
		fill.Visible = true
	else
		fill.Visible = false
	end
end

local function UpdateBattleSkillButtons(battleData)
	local skills = battleData and battleData.PlayerSkills or nil
	local mp = battleData and battleData.PlayerMP or 0
	SetBattleSkillButton(attack1Button, "Коготь Духа", skills and skills[1], mp, 1)
	SetBattleSkillButton(attack2Button, "Призрачный Вихрь", skills and skills[2], mp, 2)
	SetBattleSkillButton(attack3Button, "Навык 3", skills and skills[3], mp, 3)
	attack2Button.Visible = skills ~= nil and skills[2] ~= nil
	attack3Button.Visible = skills ~= nil and skills[3] ~= nil

	local count = tonumber(battleData and battleData.PotionCount) or 0
	local cd = tonumber(battleData and battleData.PotionCooldown) or 0
	local hpFull = false
	if battleData and battleData.PlayerHP and battleData.PlayerMaxHP then
		hpFull = battleData.PlayerHP >= battleData.PlayerMaxHP
	end
	local potionTitle
	if cd > 0.05 then
		potionTitle = string.format("%.1fс", cd)
	else
		potionTitle = string.format("Зелье x%d", count)
	end
	local potionLabel = potionButton:FindFirstChild("ButtonLabel")
	if potionLabel then
		potionLabel.Text = potionTitle
	else
		potionButton.Text = potionTitle
	end
	local disabled = count <= 0 or cd > 0.05 or hpFull
	potionButton.BackgroundColor3 = disabled and Color3.fromRGB(95, 95, 95) or Color3.fromRGB(70, 160, 100)
	potionButton.Active = not disabled
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
				local iconData = getSpiritIconData(spiritInfo.Id, spiritInfo)
				if iconFrame then iconFrame.BackgroundColor3 = iconData.Color end
				if iconEmoji then iconEmoji.Text = iconData.Emoji end
				if nameLabel then
					local prefix = isResonantSpirit(spiritInfo) and "[R] " or ""
					nameLabel.Text = prefix .. shortName .. " Ур." .. (spiritInfo.Level or 1)
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
	if currentTrapCount <= 0 then
		if _G.ShowNoTrapMessage then _G.ShowNoTrapMessage() end
		UpdateHint("Нет ловушек")
		return
	end

	local tween = TweenService:Create(catchButton,
		TweenInfo.new(0.1, Enum.EasingStyle.Quad),
		{BackgroundColor3 = Color3.fromRGB(100, 220, 100)}
	)
	tween:Play()

	task.wait(0.1)

	local tween2 = TweenService:Create(catchButton,
		TweenInfo.new(0.1, Enum.EasingStyle.Quad),
		{BackgroundColor3 = currentTrapCount > 0
			and (player:GetAttribute("CatchUiActive") and Color3.fromRGB(90, 230, 100) or Color3.fromRGB(70, 180, 70))
			or Color3.fromRGB(80, 80, 90)}
	)
	tween2:Play()

	-- Сигналим ClientController: бросок SpiritTrap
	player:SetAttribute("CatchRequest", os.clock())
	UpdateHint("Бросаем ловушку...")
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
local function TryBattleSkill(skillIndex)
	if not CurrentBattle then return end
	local s = CurrentBattle.PlayerSkills and CurrentBattle.PlayerSkills[skillIndex]
	if not s then
		ShowNotification("Слот " .. tostring(skillIndex) .. " пуст")
		return
	end
	local cd = tonumber(s.Cooldown) or 0
	local cost = tonumber(s.Cost) or 0
	local mp = tonumber(CurrentBattle.PlayerMP) or 0
	local skillName = s.Name or ("Навык " .. tostring(skillIndex))
	if cd > 0.05 then
		ShowNotification(string.format("«%s» перезаряжается: %.1fс", skillName, cd))
		return
	end
	if mp < cost then
		ShowNotification(string.format("Недостаточно MP: нужно %d (есть %d)", cost, math.floor(mp)))
		return
	end
	BattleEvent:FireServer("Attack", {SkillIndex = skillIndex})
end

local function TryBattlePotion()
	if not CurrentBattle then return end
	local count = tonumber(CurrentBattle.PotionCount) or 0
	local cd = tonumber(CurrentBattle.PotionCooldown) or 0
	if count <= 0 then
		ShowNotification("Нет зелий здоровья")
		return
	end
	if cd > 0.05 then
		ShowNotification("Зелье перезаряжается")
		return
	end
	if CurrentBattle.PlayerHP and CurrentBattle.PlayerMaxHP and CurrentBattle.PlayerHP >= CurrentBattle.PlayerMaxHP then
		ShowNotification("HP уже полное")
		return
	end
	BattleEvent:FireServer("UsePotion", {})
end

attack1Button.MouseButton1Click:Connect(function()
	TryBattleSkill(1)
end)

attack2Button.MouseButton1Click:Connect(function()
	TryBattleSkill(2)
end)

attack3Button.MouseButton1Click:Connect(function()
	TryBattleSkill(3)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not CurrentBattle then return end
	-- Keypad1-3: same as 1-3; Studio MCP VirtualInput can send Keypad, not top-row One/Two
	if input.KeyCode == Enum.KeyCode.One or input.KeyCode == Enum.KeyCode.KeypadOne then
		TryBattleSkill(1)
	elseif input.KeyCode == Enum.KeyCode.Two or input.KeyCode == Enum.KeyCode.KeypadTwo then
		TryBattleSkill(2)
	elseif input.KeyCode == Enum.KeyCode.Three or input.KeyCode == Enum.KeyCode.KeypadThree then
		if attack3Button.Visible then TryBattleSkill(3) end
	elseif input.KeyCode == Enum.KeyCode.H then
		TryBattlePotion()
	end
end)

potionButton.MouseButton1Click:Connect(function()
	TryBattlePotion()
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

detailCareButton.MouseButton1Click:Connect(function()
	if not selectedSpiritIndex then return end
	ResonanceEvent:FireServer("Care", {SpiritIndex = selectedSpiritIndex, UseTreat = false})
end)

detailTemperButton.MouseButton1Click:Connect(function()
	if not selectedSpiritIndex then
		selectedSpiritIndex = (PlayerData and tonumber(PlayerData.ActiveSpiritIndex)) or 1
	end
	OpenTemperPicker()
end)

ResonanceEvent.OnClientEvent:Connect(function(action, data)
	if action == "OpenTemperPicker" then
		OpenTemperPicker()
		return
	end
	if action == "CareSuccess" or action == "TemperSuccess" then
		ShowNotification((data and data.Message) or "Готово")
		if action == "CareSuccess" then
			PlayCareClientVfx()
			ShowCareRewardFeedback(data)
		elseif action == "TemperSuccess" and data then
			ShowCareRewardFeedback(data)
		end
		if data and data.Snapshot then
			RefreshActivityBar(data.Snapshot)
		end
		ResonanceEvent:FireServer("GetState", {})
		pcall(function()
			QuestEvent:FireServer("GetActiveQuests", {})
		end)
		if temperPickerFrame then
			temperPickerFrame.Visible = false
		end
	elseif action == "CareFailed" or action == "TemperFailed" then
		ShowNotification((data and data.Reason) or "Не удалось")
	elseif action == "DexBonus" and data then
		RefreshDexPanel(data)
	elseif action == "State" and data then
		RefreshActivityBar(data)
		if data.Spirits and selectedSpiritIndex and PlayerData and PlayerData.Spirits then
			local snap = data.Spirits[selectedSpiritIndex]
			if snap and detailResonanceLabel then
				detailResonanceLabel.Text = string.format(
					"Резонанс: Bond %d (%d/%d) | Temper A%d/D%d/S%d | Stam %d",
					snap.Bond or 0, snap.BondXp or 0, snap.BondNeed or 0,
					(snap.TemperPoints and snap.TemperPoints.Attack) or 0,
					(snap.TemperPoints and snap.TemperPoints.Defense) or 0,
					(snap.TemperPoints and snap.TemperPoints.Spirit) or 0,
					data.SpiritStamina or 0
				)
			end
		end
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

shopButton.MouseButton1Click:Connect(function()
	tradeUI.Open()
	UpdateCoins(
		tonumber(PlayerData.CopperCoins) or 0,
		tonumber(PlayerData.SilverCoins) or 0,
		tonumber(PlayerData.GoldCoins) or 0
	)
end)

-- ============================================
-- Обработка событий от сервера
-- ============================================

DataEvent.OnClientEvent:Connect(function(action, data)
	if action == "FullSync" then
		-- Полная синхронизация данных
		data = data or {}
		PlayerData = data
		RefreshActivityBar(data)
		-- Не открывать панель свойств на каждый FullSync (после боя и т.п.)
		if spiritDetailFrame.Visible and selectedSpiritIndex and OpenSpiritDetail then
			pcall(function() OpenSpiritDetail(selectedSpiritIndex) end)
		end
		local level = tonumber(data.Level) or 1
		UpdateLevel(level)
		UpdateExp(data.Experience or 0, level * 100)
		UpdateCoins(data.CopperCoins or 0, data.SilverCoins or 0, data.GoldCoins or 0)

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

		-- Обновляем слоты духов (вкл. Resonant / Ками без записи в каталоге)
		local spiritDisplayData = {}
		for i, spirit in ipairs(data.Spirits or {}) do
			local spiritInfo = ResolveOwnedSpiritDisplay(spirit)
			if spiritInfo then
				table.insert(spiritDisplayData, {
					Id = spirit.Id,
					Name = spiritInfo.Name,
					Level = spirit.Level,
					Kind = spirit.Kind,
					PrimaryElement = spiritInfo.PrimaryElement,
					HybridPrimary = spirit.HybridPrimary,
					Element = spiritInfo.Element,
					ParentIds = spirit.ParentIds,
				})
			end
		end
		UpdateSpiritSlots(spiritDisplayData)
		UpdateBagSlots(data.Bags or {})

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
		if tradeUI.IsVisible() then
			RefreshTradeInventory()
			tradeUI.RefreshAfford()
		end
		RefreshProfileSummary()

		if not hasDataBeenLoaded then
			ShowNotification("Данные загружены! ")
			hasDataBeenLoaded = true
		end
		-- Subsequent FullSync is silent (catch/battle toast their own feedback)

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
		data = data or {}
		ShowNotification("Не удалось поймать " .. tostring(data.SpiritName or "духа") .. "!")

	elseif action == "Error" then
		EnterNormalMode()
		data = data or {}
		ShowNotification("Ошибка: " .. tostring(data.Message or "неизвестно"))

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

local battleAgencyHintShown = false

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
		-- P0 agency: once per fight, nudge hotkeys 1–2 when slot 2 exists
		if (tonumber(data.Turn) or 0) <= 1 and data.PlayerSkills and data.PlayerSkills[2] then
			if not battleAgencyHintShown then
				battleAgencyHintShown = true
				if UpdateHint then
					UpdateHint("Бой: 1 / 2 / 3 — навыки · H — зелье")
					task.delay(2.2, function()
						if UpdateHint and battleAgencyHintShown then
							UpdateHint("")
						end
					end)
				end
			end
		end

		if battleElementTip then
			local tip = data.ElementTip
			if (not tip or tip == "") and data.PlayerElementLabel and data.EnemyElementLabel then
				tip = data.PlayerElementLabel .. " vs " .. data.EnemyElementLabel
			end
			battleElementTip.Text = tip or ""
			if tip and string.find(tip, "Сильно", 1, true) then
				battleElementTip.TextColor3 = Color3.fromRGB(120, 255, 160)
			elseif tip and string.find(tip, "Слабо", 1, true) then
				battleElementTip.TextColor3 = Color3.fromRGB(255, 160, 120)
			else
				battleElementTip.TextColor3 = Color3.fromRGB(255, 220, 140)
			end
		end

		-- Обновляем лог
		if data.Message and data.Message ~= "" then
			UpdateBattleLog("Ход " .. data.Turn .. " | " .. data.Message)
			if string.find(data.Message, "Сильно", 1, true) then
				battleLogLabel.TextColor3 = Color3.fromRGB(120, 255, 160)
				if PulseBattleAgency then PulseBattleAgency("strong") end
			elseif string.find(data.Message, "Слабо", 1, true) then
				battleLogLabel.TextColor3 = Color3.fromRGB(255, 160, 120)
				if PulseBattleAgency then PulseBattleAgency("weak") end
			else
				battleLogLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
			end
		else
			UpdateBattleLog("Ход " .. data.Turn)
			battleLogLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		end

	elseif action == "End" then
		-- Конец боя
		battleAgencyHintShown = false
		EnterNormalMode()
		data = data or {}

		if data.Winner == "Player" then
			local rewards = data.Rewards or {}
			local rewardText = "Победа!"
			if rewards.Experience then rewardText = rewardText .. " +" .. rewards.Experience .. " опыта" end
			local copper = tonumber(rewards.CopperCoins) or tonumber(rewards.Coins) or 0
			if copper > 0 then rewardText = rewardText .. ", +" .. copper .. " 🥉" end
			if rewards.SilverCoins and rewards.SilverCoins > 0 then rewardText = rewardText .. ", +" .. rewards.SilverCoins .. " 🥈" end
			if rewards.GoldCoins and rewards.GoldCoins > 0 then rewardText = rewardText .. ", +" .. rewards.GoldCoins .. " 🥇" end
			ShowNotification(rewardText, 4.5)
		elseif data.Winner == "Enemy" then
			ShowNotification("Поражение — прогресс сохранён. Отдыхай у спавна.", 4.5)
		else
			ShowNotification("Бой окончен", 3)
		end

	elseif action == "Flee" then
		if data.Success then
			battleAgencyHintShown = false
			EnterNormalMode()
			ShowNotification("Вы сбежали!")
		else
			ShowNotification("Не удалось сбежать!")
		end

	elseif action == "Error" then
		battleAgencyHintShown = false
		EnterNormalMode()
		ShowNotification("Бой: " .. (data.Message or "ошибка"))
	end
end)

-- ============================================
-- Обработка событий эволюции
-- ============================================

EvolutionEvent.OnClientEvent:Connect(function(action, data)
	if action == "EvolutionsList" then
		-- Identity slice 3: refresh card progress; no spam toast
		local evolutions = data and data.Evolutions or {}
		local idx = selectedSpiritIndex or (PlayerData and PlayerData.ActiveSpiritIndex) or 1
		local spirit = PlayerData and PlayerData.Spirits and PlayerData.Spirits[idx]
		local canLocal = ApplyEvoProgressUI(spirit)
		for _, row in ipairs(evolutions) do
			if tonumber(row.SpiritIndex) == tonumber(idx) then
				if row.CanEvolve == true then
					evolveButtonEnabled = true
					detailEvolveButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
					local lbl = detailEvolveButton:FindFirstChild("ButtonLabel")
					if lbl then lbl.Text = "ЭВОЛЮЦИЯ" end
				elseif row.CanEvolve == false and not canLocal then
					evolveButtonEnabled = false
					detailEvolveButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
					local lbl = detailEvolveButton:FindFirstChild("ButtonLabel")
					if lbl then lbl.Text = "Ещё рано" end
				end
				break
			end
		end

	elseif action == "EvolutionInfo" then
		-- Показываем информацию об эволюции
		local info = data.Info
		if info then
			ShowNotification("Эволюция: " .. info.EvolvedName)
		end

	elseif action == "CanEvolve" then
		local idx = (data and data.SpiritIndex) or selectedSpiritIndex or (PlayerData and PlayerData.ActiveSpiritIndex) or 1
		if OpenSpiritDetail then
			OpenSpiritDetail(idx)
		end
		local toName = (data and (data.EvolveToName or data.EvolvedName)) or "новую форму"
		ShowNotification("Доступна эволюция → " .. tostring(toName))

	elseif action == "SpiritLevelUp" then
		local idx = data and data.SpiritIndex
		local newLevel = data and tonumber(data.NewLevel) or 0
		-- Открыть панель только на порогах улучшения (новый навык / эволюция)
		if idx and OpenSpiritDetail and (newLevel == 5 or newLevel == 10) then
			local sp = PlayerData and PlayerData.Spirits and PlayerData.Spirits[idx]
			if sp then sp.Level = newLevel end
			OpenSpiritDetail(idx)
			if newLevel >= 10 then
				ShowNotification("Дух ур. " .. newLevel .. " — проверьте эволюцию!")
			else
				ShowNotification("Дух ур. " .. newLevel .. " — новый навык!")
			end
		end

	elseif action == "EvolutionSuccess" then
		-- Identity slice 2: toast Old→New, slots + reopen card with real skills
		local newSpirit = data.NewSpirit
		local idx = tonumber(data.SpiritIndex) or selectedSpiritIndex or (PlayerData and PlayerData.ActiveSpiritIndex) or 1
		if newSpirit and PlayerData then
			PlayerData.Spirits = PlayerData.Spirits or {}
			PlayerData.Spirits[idx] = newSpirit
			PlayerData.CurrentSpiritId = newSpirit.Id
		end
		local newName = tostring(newSpirit and newSpirit.Name or "новую форму")
		local oldName = data.OldName and tostring(data.OldName) or nil
		local msg
		if oldName and oldName ~= "" and oldName ~= newName then
			msg = oldName .. " → " .. newName .. "!"
		else
			msg = "Дух эволюционировал в " .. newName .. "!"
		end
		if data.UnlockedSkill then
			msg = msg .. " Удар: " .. tostring(data.UnlockedSkill)
		end
		ShowNotification(msg, 4.5)

		if PlayerData and PlayerData.Spirits then
			local spiritDisplayData = {}
			for i, spirit in ipairs(PlayerData.Spirits) do
				local spiritInfo = ResolveOwnedSpiritDisplay(spirit)
				local name = (spiritInfo and spiritInfo.Name) or spirit.Name or ("Дух " .. tostring(spirit.Id))
				table.insert(spiritDisplayData, {
					Id = spirit.Id,
					Name = name,
					Level = spirit.Level,
					Kind = spirit.Kind,
					PrimaryElement = spiritInfo and spiritInfo.PrimaryElement,
					HybridPrimary = spirit.HybridPrimary,
					Element = spiritInfo and spiritInfo.Element,
					ParentIds = spirit.ParentIds,
				})
			end
			UpdateSpiritSlots(spiritDisplayData)
		end
		selectedSpiritIndex = idx
		OpenSpiritDetail(idx)

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
		RefreshShopList(data and data.Items)
		-- Prefetch from zone enter must not force-open; intentional opens set Visible first
		if tradeUI.IsVisible() then
			RefreshTradeInventory()
			UpdateCoins(
				tonumber(PlayerData.CopperCoins) or 0,
				tonumber(PlayerData.SilverCoins) or 0,
				tonumber(PlayerData.GoldCoins) or 0
			)
		end
	elseif action == "OpenTrade" then
		tradeUI.Open()
	elseif action == "TradeResult" then
		ShowNotification(data.Message or "")
		if data.Success and tradeUI.IsVisible() then
			RefreshTradeInventory()
			tradeUI.RefreshAfford()
		elseif not data.Success and tradeUI.IsVisible() and data.Message then
			-- Keep catalog visible; purchase may fail outside Haven
			tradeUI.RefreshAfford()
		end
	end
end)

-- ============================================
-- Инициализация
-- ============================================

UpdateLevel(1)
UpdateExp(0, 100)
ShowNotification("Загрузка данных...", 2)

tradeUI.BindZoneSilentRefresh(player)

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
		if hrp then

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
					local iconData = getSpiritIconData(spiritId)
					table.insert(targets, {
						pos = spirit.PrimaryPart.Position,
						color = iconData.Color,
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

		-- Q2 QuestLocations (pads / markers)
		local qlFolder = workspace:FindFirstChild("QuestLocations")
		if qlFolder then
			for _, loc in ipairs(qlFolder:GetChildren()) do
				local pad = loc:FindFirstChild("Pad") or loc:FindFirstChild("Marker") or loc.PrimaryPart
				if pad and pad:IsA("BasePart") then
					table.insert(targets, {
						pos = pad.Position,
						color = Color3.fromRGB(120, 190, 255),
						size = 5,
					})
				end
			end
		end
		local scout = workspace:FindFirstChild("ScoutQuestor")
		if scout then
			local root = scout:FindFirstChild("HumanoidRootPart") or scout.PrimaryPart
			if root and root:IsA("BasePart") then
				table.insert(targets, {
					pos = root.Position,
					color = Color3.fromRGB(255, 200, 80),
					size = 6,
				})
			end
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
		end -- hrp
	end
end)

print("Realm of Spirits - UI Controller загружен!")

