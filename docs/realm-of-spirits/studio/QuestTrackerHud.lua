local ReplicatedStorage = game:GetService("ReplicatedStorage")

local realmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local ItemCatalog = require(realmFolder:WaitForChild("ItemCatalog"))

local QuestTrackerHud = {}

local GOLD = Color3.fromRGB(255, 210, 60)
local EMERALD = Color3.fromRGB(40, 200, 120)
local PANEL_BG = Color3.fromRGB(22, 16, 32)
local TITLE_COLOR = Color3.fromRGB(255, 220, 140)
local TEXT_COLOR = Color3.fromRGB(230, 220, 205)
local MUTED = Color3.fromRGB(160, 150, 140)

local rootFrame
local listFrame
local emptyLabel
local rowPool = {}

local function getProgressEntry(progress, index)
	if type(progress) ~= "table" then
		return nil
	end
	return progress[index] or progress[tostring(index)]
end

local function objectiveName(obj)
	local objType = obj and obj.Type or ""
	if objType == "CatchSpirit" then
		return "Поймать духов"
	elseif objType == "CatchSpecificSpirit" then
		return (obj.SpiritName and ("Поймать: " .. obj.SpiritName)) or "Поймать духа"
	elseif objType == "DefeatEnemies" then
		return "Победить врагов"
	elseif objType == "CatchDifferentSpirits" then
		return "Разные духи"
	elseif objType == "CollectItem" then
		local item = obj.ItemId and ItemCatalog.ById and ItemCatalog.ById[obj.ItemId]
		if item and item.Name then
			return item.Name
		end
		local def = ItemCatalog.Get and ItemCatalog.Get(obj.ItemId)
		return (def and def.Name) or "Собрать предметы"
	elseif objType == "LevelUpSpirit" then
		return "Уровень духа"
	elseif objType == "CareSpirit" then
		return "Уход за духом"
	elseif objType == "TemperSpirit" then
		return "Закалка духа"
	elseif objType == "FindChests" then
		return "Найти сундуки"
	end
	return objType ~= "" and objType or "Цель"
end

local function objectiveCounts(obj, progress)
	local target = (progress and tonumber(progress.Target)) or obj.Count or obj.TargetLevel or 1
	local current = (progress and tonumber(progress.Current)) or 0
	return math.floor(current), math.floor(tonumber(target) or 1)
end

local function clearRows()
	for _, row in ipairs(rowPool) do
		row:Destroy()
	end
	table.clear(rowPool)
end

local function buildRow(parent, entry, y)
	local quest = entry.Quest or {}
	local ready = entry.ReadyToTurnIn == true
	local progress = entry.Progress or {}
	local objectives = quest.Objectives or {}

	local objCount = math.max(1, #objectives)
	local rowH = 22 + objCount * 15

	local row = Instance.new("Frame")
	row.Name = "QuestRow"
	row.Size = UDim2.new(1, -8, 0, rowH)
	row.Position = UDim2.new(0, 4, 0, y)
	row.BackgroundColor3 = Color3.fromRGB(28, 20, 40)
	row.BackgroundTransparency = 0.05
	row.BorderSizePixel = 0
	row.ZIndex = 14
	row.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = row

	local marker = Instance.new("TextLabel")
	marker.Name = "Marker"
	marker.Size = UDim2.fromOffset(22, 22)
	marker.Position = UDim2.new(0, 4, 0, 2)
	marker.BackgroundTransparency = 1
	marker.Text = ready and "?" or "!"
	marker.TextColor3 = ready and EMERALD or GOLD
	marker.Font = Enum.Font.GothamBlack
	marker.TextSize = 20
	marker.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	marker.TextStrokeTransparency = 0.2
	marker.ZIndex = 16
	marker.Parent = row

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -32, 0, 18)
	title.Position = UDim2.new(0, 28, 0, 2)
	title.BackgroundTransparency = 1
	title.Text = quest.Name or "Квест"
	title.TextColor3 = ready and Color3.fromRGB(120, 255, 180) or Color3.fromRGB(255, 248, 220)
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextYAlignment = Enum.TextYAlignment.Center
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	title.TextStrokeTransparency = 0.15
	title.ZIndex = 16
	title.Parent = row

	local lineY = 20
	if #objectives == 0 then
		local stub = Instance.new("TextLabel")
		stub.Size = UDim2.new(1, -32, 0, 14)
		stub.Position = UDim2.new(0, 28, 0, lineY)
		stub.BackgroundTransparency = 1
		stub.Text = ready and "Готово к сдаче у Мики" or "В процессе…"
		stub.TextColor3 = MUTED
		stub.Font = Enum.Font.Gotham
		stub.TextSize = 11
		stub.TextXAlignment = Enum.TextXAlignment.Left
		stub.Parent = row
	else
		for i, obj in ipairs(objectives) do
			local p = getProgressEntry(progress, i)
			local cur, tgt = objectiveCounts(obj, p)
			local done = cur >= tgt

			local line = Instance.new("TextLabel")
			line.Name = "ObjName"
			line.Size = UDim2.new(1, -72, 0, 14)
			line.Position = UDim2.new(0, 28, 0, lineY)
			line.BackgroundTransparency = 1
			line.Text = "· " .. objectiveName(obj)
			line.TextColor3 = done and EMERALD or TEXT_COLOR
			line.Font = Enum.Font.Gotham
			line.TextSize = 11
			line.TextXAlignment = Enum.TextXAlignment.Left
			line.TextTruncate = Enum.TextTruncate.AtEnd
			line.ZIndex = 15
			line.Parent = row

			local count = Instance.new("TextLabel")
			count.Name = "ObjCount"
			count.Size = UDim2.fromOffset(40, 14)
			count.Position = UDim2.new(1, -44, 0, lineY)
			count.BackgroundTransparency = 1
			count.Text = string.format("%d/%d", cur, tgt)
			count.TextColor3 = done and EMERALD or GOLD
			count.Font = Enum.Font.GothamBold
			count.TextSize = 11
			count.TextXAlignment = Enum.TextXAlignment.Right
			count.ZIndex = 16
			count.Parent = row

			lineY += 15
		end
	end

	table.insert(rowPool, row)
	return rowH + 4
end

function QuestTrackerHud.refresh(quests)
	if not listFrame then return end
	clearRows()
	quests = quests or {}
	if #quests == 0 then
		emptyLabel.Visible = true
		emptyLabel.ZIndex = 14
		listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
		return
	end
	emptyLabel.Visible = false
	emptyLabel.ZIndex = 1
	table.sort(quests, function(a, b)
		local function careIncomplete(entry)
			local objs = entry.Quest and entry.Quest.Objectives or {}
			local prog = entry.Progress or {}
			for i, obj in ipairs(objs) do
				if obj.Type == "CareSpirit" then
					local p = prog[i] or prog[tostring(i)] or {}
					local cur = tonumber(p.Current) or 0
					local tgt = tonumber(p.Target) or obj.Count or 1
					if cur < tgt then return true end
				end
			end
			return false
		end
		local ac = careIncomplete(a) and 1 or 0
		local bc = careIncomplete(b) and 1 or 0
		if ac ~= bc then return ac > bc end
		local ar = a.ReadyToTurnIn and 1 or 0
		local br = b.ReadyToTurnIn and 1 or 0
		if ar ~= br then return ar > br end
		local aid = a.Quest and a.Quest.Id or 0
		local bid = b.Quest and b.Quest.Id or 0
		return aid < bid
	end)
	local y = 0
	for _, entry in ipairs(quests) do
		y += buildRow(listFrame, entry, y)
	end
	listFrame.CanvasSize = UDim2.new(0, 0, 0, y + 4)
end

function QuestTrackerHud.init(screenGui, opts)
	opts = opts or {}
	local width = opts.Width or 200
	local height = opts.Height or 140
	local pos = opts.Position or UDim2.new(1, -(width + 12), 0, 268)

	local existing = screenGui:FindFirstChild("QuestTrackerFrame")
	if existing then existing:Destroy() end

	rootFrame = Instance.new("Frame")
	rootFrame.Name = "QuestTrackerFrame"
	rootFrame.Size = UDim2.fromOffset(width, height)
	rootFrame.Position = pos
	rootFrame.BackgroundColor3 = PANEL_BG
	rootFrame.BackgroundTransparency = 0.12
	rootFrame.BorderSizePixel = 0
	rootFrame.ZIndex = 12
	rootFrame.Parent = screenGui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = rootFrame
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(180, 140, 70)
	stroke.Thickness = 1.5
	stroke.Transparency = 0.25
	stroke.Parent = rootFrame

	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, -12, 0, 20)
	header.Position = UDim2.new(0, 8, 0, 4)
	header.BackgroundTransparency = 1
	header.Text = "Активные квесты"
	header.TextColor3 = TITLE_COLOR
	header.Font = Enum.Font.GothamBold
	header.TextSize = 13
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.ZIndex = 13
	header.Parent = rootFrame

	listFrame = Instance.new("ScrollingFrame")
	listFrame.Name = "QuestList"
	listFrame.Size = UDim2.new(1, -8, 1, -28)
	listFrame.Position = UDim2.new(0, 4, 0, 24)
	listFrame.BackgroundTransparency = 1
	listFrame.BorderSizePixel = 0
	listFrame.ScrollBarThickness = 4
	listFrame.ScrollBarImageColor3 = Color3.fromRGB(200, 160, 80)
	listFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	listFrame.ZIndex = 13
	listFrame.Parent = rootFrame

	emptyLabel = Instance.new("TextLabel")
	emptyLabel.Name = "EmptyLabel"
	emptyLabel.Size = UDim2.new(1, -12, 0, 40)
	emptyLabel.Position = UDim2.new(0, 6, 0, 8)
	emptyLabel.BackgroundTransparency = 1
	emptyLabel.Text = "Нет активных квестов\nПоговорите с Микой"
	emptyLabel.TextColor3 = MUTED
	emptyLabel.Font = Enum.Font.Gotham
	emptyLabel.TextSize = 11
	emptyLabel.TextWrapped = true
	emptyLabel.Active = false
	emptyLabel.ZIndex = 14
	emptyLabel.Parent = rootFrame
	emptyLabel.Position = UDim2.new(0, 10, 0, 28)
	emptyLabel.Size = UDim2.new(1, -20, 0, 40)
end

function QuestTrackerHud.setVisible(visible)
	if rootFrame then
		rootFrame.Visible = visible
	end
end

function QuestTrackerHud.bind(questEvent)
	if not questEvent then return end
	questEvent.OnClientEvent:Connect(function(action, data)
		if action == "ActiveQuests" then
			QuestTrackerHud.refresh(data and data.Quests)
		elseif action == "OpenQuestUI" then
			if data and type(data.Active) == "table" then
				QuestTrackerHud.refresh(data.Active)
			else
				questEvent:FireServer("GetActiveQuests", {})
			end
		elseif action == "QuestProgress" or action == "QuestAccepted"
			or action == "QuestCompleted" or action == "QuestReadyToTurnIn" then
			questEvent:FireServer("GetActiveQuests", {})
		end
	end)
	task.defer(function()
		questEvent:FireServer("GetActiveQuests", {})
	end)
end

return QuestTrackerHud
