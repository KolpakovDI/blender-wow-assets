-- OtakuHavenController
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local RealmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local havenEvent = RealmFolder:WaitForChild("OtakuHaven")
local tradeEvent = RealmFolder:WaitForChild("Trade")
local ToastRouter = require(RealmFolder:WaitForChild("ToastRouter"))
local function getMainGui()
	return player:WaitForChild("PlayerGui"):FindFirstChild("RealmOfSpiritsUI")
end
local function showToast(text, color)
	if not text or text == "" then return end
	local priority = "Tip"
	if string.find(text, "Собран", 1, true)
		or string.find(text, "Сундук", 1, true)
		or string.find(text, "Гача", 1, true)
		or string.find(text, "меди", 1, true)
	then
		priority = "Reward"
	end
	ToastRouter.Notify(text, 3.5, priority, color)
end

local function ensureGachaPopup()
	local pg = player:WaitForChild("PlayerGui")
	local gui = pg:FindFirstChild("GachaResultGui")
	if gui then return gui end
	gui = Instance.new("ScreenGui")
	gui.Name = "GachaResultGui"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 450
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = pg

	local dim = Instance.new("Frame")
	dim.Name = "Dim"
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	dim.BackgroundTransparency = 0.45
	dim.BorderSizePixel = 0
	dim.Visible = false
	dim.Parent = gui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.38)
	panel.Size = UDim2.new(0, 380, 0, 200)
	panel.BackgroundColor3 = Color3.fromRGB(36, 28, 48)
	panel.BorderSizePixel = 0
	panel.ZIndex = 20
	panel.Parent = dim
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 170, 220)
	stroke.Thickness = 2
	stroke.Parent = panel

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -24, 0, 32)
	title.Position = UDim2.new(0, 12, 0, 14)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 22
	title.TextColor3 = Color3.fromRGB(255, 210, 120)
	title.Text = "Гашапон!"
	title.Parent = panel

	local body = Instance.new("TextLabel")
	body.Name = "Body"
	body.Size = UDim2.new(1, -24, 0, 44)
	body.Position = UDim2.new(0, 12, 0, 54)
	body.BackgroundTransparency = 1
	body.Font = Enum.Font.Gotham
	body.TextSize = 18
	body.TextColor3 = Color3.fromRGB(240, 230, 255)
	body.TextWrapped = true
	body.Text = ""
	body.Parent = panel

	local disclaimer = Instance.new("TextLabel")
	disclaimer.Name = "Disclaimer"
	disclaimer.Size = UDim2.new(1, -24, 0, 22)
	disclaimer.Position = UDim2.new(0, 12, 0, 100)
	disclaimer.BackgroundTransparency = 1
	disclaimer.Font = Enum.Font.Gotham
	disclaimer.TextSize = 14
	disclaimer.TextColor3 = Color3.fromRGB(255, 200, 140)
	disclaimer.TextWrapped = true
	disclaimer.Text = "Только косметика — без бонусов в бою"
	disclaimer.Parent = panel

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "Close"
	closeBtn.AnchorPoint = Vector2.new(0.5, 1)
	closeBtn.Position = UDim2.new(0.5, 0, 1, -14)
	closeBtn.Size = UDim2.new(0, 140, 0, 34)
	closeBtn.BackgroundColor3 = Color3.fromRGB(180, 90, 160)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 16
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.Text = "OK"
	closeBtn.Parent = panel
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = closeBtn
	closeBtn.MouseButton1Click:Connect(function()
		dim.Visible = false
	end)
	return gui
end

local function showGachaPopup(data)
	data = data or {}
	local gui = ensureGachaPopup()
	local dim = gui.Dim
	local panel = dim.Panel
	local typeLabel = data.Title or data.Type or "Награда"
	panel.Title.Text = "Гашапон — " .. tostring(typeLabel)
	panel.Body.Text = data.Message or "Получена награда!"
	local disclaimer = panel:FindFirstChild("Disclaimer")
	if not disclaimer then
		disclaimer = Instance.new("TextLabel")
		disclaimer.Name = "Disclaimer"
		disclaimer.Size = UDim2.new(1, -24, 0, 22)
		disclaimer.Position = UDim2.new(0, 12, 0, 100)
		disclaimer.BackgroundTransparency = 1
		disclaimer.Font = Enum.Font.Gotham
		disclaimer.TextWrapped = true
		disclaimer.Parent = panel
	end
	disclaimer.TextSize = 14
	disclaimer.TextColor3 = Color3.fromRGB(255, 200, 140)
	disclaimer.Text = "Только косметика — без бонусов в бою"
	if panel.Size.Y.Offset < 200 then
		panel.Size = UDim2.new(0, 380, 0, 200)
	end
	gui.DisplayOrder = 450
	gui.Enabled = true
	dim.Visible = true
	local msg = panel.Body.Text
	task.delay(5, function()
		if dim.Parent and panel.Body.Text == msg then
			dim.Visible = false
		end
	end)
	showToast("Гача: " .. msg, Color3.fromRGB(255, 140, 200))
end

local function openTradePanel()
	local gui = getMainGui(); if not gui then return end
	local tradeFrame = gui:FindFirstChild("TradeFrame")
	if tradeFrame then tradeFrame.Visible = true; tradeEvent:FireServer("GetShop", {}) end
end

local function ensureFlexWardrobe()
	local pg = player:WaitForChild("PlayerGui")
	local gui = pg:FindFirstChild("FlexWardrobeGui")
	if gui then return gui end
	gui = Instance.new("ScreenGui")
	gui.Name = "FlexWardrobeGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 440
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Enabled = false
	gui.Parent = pg

	local dim = Instance.new("Frame")
	dim.Name = "Dim"
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	dim.BackgroundTransparency = 0.45
	dim.BorderSizePixel = 0
	dim.Parent = gui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(0, 420, 0, 420)
	panel.BackgroundColor3 = Color3.fromRGB(32, 26, 42)
	panel.BorderSizePixel = 0
	panel.Parent = dim
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(200, 170, 255)
	stroke.Thickness = 2
	stroke.Parent = panel

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -80, 0, 36)
	title.Position = UDim2.new(0, 16, 0, 12)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 22
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Color3.fromRGB(255, 220, 160)
	title.Text = "Гардероб · Flex"
	title.Parent = panel

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "Close"
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.Position = UDim2.new(1, -12, 0, 12)
	closeBtn.Size = UDim2.new(0, 36, 0, 36)
	closeBtn.BackgroundColor3 = Color3.fromRGB(90, 50, 70)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 18
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.Text = "X"
	closeBtn.Parent = panel
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeBtn
	closeBtn.MouseButton1Click:Connect(function()
		gui.Enabled = false
	end)

	local list = Instance.new("ScrollingFrame")
	list.Name = "List"
	list.Position = UDim2.new(0, 16, 0, 56)
	list.Size = UDim2.new(1, -32, 1, -120)
	list.BackgroundColor3 = Color3.fromRGB(22, 18, 30)
	list.BackgroundTransparency = 0.2
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 6
	list.CanvasSize = UDim2.new(0, 0, 0, 0)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.Parent = panel
	local listCorner = Instance.new("UICorner")
	listCorner.CornerRadius = UDim.new(0, 8)
	listCorner.Parent = list
	local layout = Instance.new("UIListLayout")
	layout.Name = "Layout"
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 6)
	layout.Parent = list
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	pad.Parent = list

	local empty = Instance.new("TextLabel")
	empty.Name = "Empty"
	empty.Size = UDim2.new(1, -16, 0, 40)
	empty.BackgroundTransparency = 1
	empty.Font = Enum.Font.Gotham
	empty.TextSize = 15
	empty.TextColor3 = Color3.fromRGB(180, 170, 200)
	empty.TextWrapped = true
	empty.Text = "Пока пусто — крути гашапон"
	empty.Visible = false
	empty.Parent = list

	local footer = Instance.new("Frame")
	footer.Name = "Footer"
	footer.AnchorPoint = Vector2.new(0, 1)
	footer.Position = UDim2.new(0, 16, 1, -14)
	footer.Size = UDim2.new(1, -32, 0, 40)
	footer.BackgroundTransparency = 1
	footer.Parent = panel

	local unequipAll = Instance.new("TextButton")
	unequipAll.Name = "UnequipAll"
	unequipAll.Size = UDim2.new(0.48, -4, 1, 0)
	unequipAll.BackgroundColor3 = Color3.fromRGB(70, 60, 90)
	unequipAll.Font = Enum.Font.GothamBold
	unequipAll.TextSize = 15
	unequipAll.TextColor3 = Color3.new(1, 1, 1)
	unequipAll.Text = "Снять всё"
	unequipAll.Parent = footer
	local uCorner = Instance.new("UICorner")
	uCorner.CornerRadius = UDim.new(0, 8)
	uCorner.Parent = unequipAll
	unequipAll.MouseButton1Click:Connect(function()
		havenEvent:FireServer("EquipCosmetic", { CosmeticId = "" })
	end)

	local shopBtn = Instance.new("TextButton")
	shopBtn.Name = "Shop"
	shopBtn.AnchorPoint = Vector2.new(1, 0)
	shopBtn.Position = UDim2.new(1, 0, 0, 0)
	shopBtn.Size = UDim2.new(0.48, -4, 1, 0)
	shopBtn.BackgroundColor3 = Color3.fromRGB(160, 100, 70)
	shopBtn.Font = Enum.Font.GothamBold
	shopBtn.TextSize = 15
	shopBtn.TextColor3 = Color3.new(1, 1, 1)
	shopBtn.Text = "Магазин"
	shopBtn.Parent = footer
	local sCorner = Instance.new("UICorner")
	sCorner.CornerRadius = UDim.new(0, 8)
	sCorner.Parent = shopBtn
	shopBtn.MouseButton1Click:Connect(function()
		gui.Enabled = false
		openTradePanel()
	end)

	return gui
end

local function showFlexWardrobe(data)
	data = data or {}
	local gui = ensureFlexWardrobe()
	local panel = gui.Dim.Panel
	local list = panel.List
	local equippedId = data.EquippedCosmeticId
	for _, child in ipairs(list:GetChildren()) do
		if child:IsA("Frame") and child.Name == "Row" then
			child:Destroy()
		end
	end
	local cosmetics = data.Cosmetics or {}
	local empty = list:FindFirstChild("Empty")
	if empty then
		empty.Visible = #cosmetics == 0
	end
	for i, cos in ipairs(cosmetics) do
		if type(cos) == "table" then
			local id = tostring(cos.Id or "")
			local name = tostring(cos.Name or "Cosmetic")
			local rarity = tostring(cos.Rarity or "Common")
			local isEquipped = equippedId ~= nil and tostring(equippedId) == id
			local row = Instance.new("Frame")
			row.Name = "Row"
			row.Size = UDim2.new(1, -8, 0, 44)
			row.BackgroundColor3 = Color3.fromRGB(40, 34, 55)
			row.BorderSizePixel = 0
			row.LayoutOrder = i
			row.Parent = list
			local rowCorner = Instance.new("UICorner")
			rowCorner.CornerRadius = UDim.new(0, 6)
			rowCorner.Parent = row
			local label = Instance.new("TextLabel")
			label.Name = "Label"
			label.Size = UDim2.new(1, -110, 1, 0)
			label.Position = UDim2.new(0, 10, 0, 0)
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.Gotham
			label.TextSize = 15
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextColor3 = Color3.fromRGB(235, 230, 255)
			label.Text = name .. " (" .. rarity .. ")"
			label.Parent = row
			local btn = Instance.new("TextButton")
			btn.Name = "Equip"
			btn.AnchorPoint = Vector2.new(1, 0.5)
			btn.Position = UDim2.new(1, -8, 0.5, 0)
			btn.Size = UDim2.new(0, 90, 0, 30)
			btn.Font = Enum.Font.GothamBold
			btn.TextSize = 14
			btn.TextColor3 = Color3.new(1, 1, 1)
			if isEquipped then
				btn.Text = "Снять"
				btn.BackgroundColor3 = Color3.fromRGB(90, 70, 110)
			else
				btn.Text = "Надеть"
				btn.BackgroundColor3 = Color3.fromRGB(100, 140, 90)
			end
			btn.Parent = row
			local btnCorner = Instance.new("UICorner")
			btnCorner.CornerRadius = UDim.new(0, 6)
			btnCorner.Parent = btn
			btn.MouseButton1Click:Connect(function()
				if isEquipped then
					havenEvent:FireServer("EquipCosmetic", { CosmeticId = "" })
				else
					havenEvent:FireServer("EquipCosmetic", { CosmeticId = id })
				end
			end)
		end
	end
	gui.Enabled = true
end

local pg = player:WaitForChild("PlayerGui")
local buffGui = Instance.new("ScreenGui")
buffGui.Name = "BuffTimerGui"
buffGui.ResetOnSpawn = false
buffGui.DisplayOrder = 20
buffGui.Parent = pg
local buffLabel = Instance.new("TextLabel")
buffLabel.Name = "BuffTimer"
buffLabel.AnchorPoint = Vector2.new(1, 0)
buffLabel.Position = UDim2.new(1, -12, 0, 52)
buffLabel.Size = UDim2.new(0, 240, 0, 32)
buffLabel.BackgroundColor3 = Color3.fromRGB(40, 30, 55)
buffLabel.BackgroundTransparency = 0.15
buffLabel.TextColor3 = Color3.fromRGB(255, 200, 120)
buffLabel.TextSize = 15
buffLabel.Font = Enum.Font.GothamBold
buffLabel.Visible = false
buffLabel.Parent = buffGui
local buffCorner = Instance.new("UICorner"); buffCorner.CornerRadius = UDim.new(0, 6); buffCorner.Parent = buffLabel
local function updateBuffLabel(payload)
	if not payload or not payload.Name then buffLabel.Visible = false; return end
	buffLabel.Visible = true
	task.spawn(function()
		local left = payload.Duration or 1800
		while left > 0 and buffLabel.Visible do
			buffLabel.Text = string.format("%s +15%% (%d:%02d)", payload.Name, math.floor(left/60), left%60)
			task.wait(1); left = left - 1
		end
		if left <= 0 then buffLabel.Visible = false end
	end)
end
local function formatFomo(seconds)
	seconds = math.max(0, math.floor(seconds or 0))
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60
	return string.format("%d:%02d:%02d", h, m, s)
end

local function updateWorldFomoLabel(secondsLeft)
	local haven = workspace:FindFirstChild("OtakuHaven")
	local gacha = haven and haven:FindFirstChild("GachaMachine", true)
	local label = gacha and gacha:FindFirstChild("FomoLabel", true)
	if label then
		if secondsLeft <= 0 then
			label.Text = "Коллекция закрыта"
		else
			label.Text = "Лимит: " .. formatFomo(secondsLeft)
		end
	end
end

havenEvent.OnClientEvent:Connect(function(action, data)
	data = data or {}
	if action == "OpenTrade" then openTradePanel(); showToast("Примерочная — магазин открыт", Color3.fromRGB(255,220,180))
	elseif action == "OpenWardrobe" then showFlexWardrobe(data)
	elseif action == "EquipResult" then showToast(data.Message or "Экипировка обновлена", Color3.fromRGB(200, 220, 255))
	elseif action == "BuffApplied" then showToast(data.Message or "Бафф!", Color3.fromRGB(255,180,100)); updateBuffLabel(data)
	elseif action == "GachaResult" then
		showGachaPopup(data)
		if data.FomoSecondsLeft then updateWorldFomoLabel(data.FomoSecondsLeft) end
	elseif action == "Toast" then showToast(data.Text or "")
	elseif action == "BuffList" then
		for _, b in ipairs(data.Buffs or {}) do if b.Id == "MangaDamage" then updateBuffLabel({Name=b.Name, Duration=b.SecondsLeft}) end end
	elseif action == "GachaFomo" then
		updateWorldFomoLabel(data.SecondsLeft or 0)
	end
end)

-- Activity Pass / Season dock (Studio SoT mirror)
local PlayersSvc = game:GetService("Players")
local localPlayer = PlayersSvc.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local function ensurePassGui()
	local gui = playerGui:FindFirstChild("SeasonPassGui")
	if gui then return gui end
	gui = Instance.new("ScreenGui")
	gui.Name = "SeasonPassGui"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 125
	gui.Parent = playerGui

	local dock = Instance.new("TextButton")
	dock.Name = "OpenPassButton"
	dock.Size = UDim2.fromOffset(176, 36)
	dock.Position = UDim2.new(0, 16, 1, -92)
	dock.BackgroundColor3 = Color3.fromRGB(255, 196, 80)
	dock.BackgroundTransparency = 0.05
	dock.Text = "Сезон · 0 жетонов"
	dock.Font = Enum.Font.GothamBold
	dock.TextSize = 15
	dock.TextColor3 = Color3.fromRGB(40, 28, 8)
	dock.Parent = gui
	do
		local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 10) c.Parent = dock
		local s = Instance.new("UIStroke") s.Color = Color3.fromRGB(255, 230, 150) s.Thickness = 2 s.Parent = dock
	end

	local hint = Instance.new("TextLabel")
	hint.Name = "DockHint"
	hint.Size = UDim2.fromOffset(176, 16)
	hint.Position = UDim2.new(0, 16, 1, -52)
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.BackgroundTransparency = 1
	hint.Font = Enum.Font.Gotham
	hint.TextSize = 11
	hint.TextColor3 = Color3.fromRGB(255, 235, 180)
	hint.Text = "Жетоны: Уход · Закалка · бой · лут"
	hint.Parent = gui

	local passPanel = Instance.new("Frame")
	passPanel.Name = "PassPanelFrame"
	passPanel.Size = UDim2.new(0, 380, 0, 400)
	passPanel.Position = UDim2.new(0.5, -190, 0.5, -200)
	passPanel.BackgroundColor3 = Color3.fromRGB(22, 20, 32)
	passPanel.Visible = false
	passPanel.Parent = gui
	do
		local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 12) c.Parent = passPanel
		local s = Instance.new("UIStroke") s.Color = Color3.fromRGB(255, 196, 80) s.Thickness = 2 s.Parent = passPanel
	end

	local passTitle = Instance.new("TextLabel")
	passTitle.Name = "Title"
	passTitle.Size = UDim2.new(1, -48, 0, 32)
	passTitle.Position = UDim2.new(0, 14, 0, 10)
	passTitle.BackgroundTransparency = 1
	passTitle.Font = Enum.Font.GothamBold
	passTitle.TextSize = 18
	passTitle.TextXAlignment = Enum.TextXAlignment.Left
	passTitle.TextColor3 = Color3.fromRGB(255, 220, 140)
	passTitle.Text = "Сезонный пропуск"
	passTitle.Parent = passPanel

	local passClose = Instance.new("TextButton")
	passClose.Name = "Close"
	passClose.Size = UDim2.new(0, 30, 0, 30)
	passClose.Position = UDim2.new(1, -38, 0, 10)
	passClose.BackgroundColor3 = Color3.fromRGB(60, 45, 40)
	passClose.Text = "X"
	passClose.TextColor3 = Color3.fromRGB(255, 230, 200)
	passClose.Font = Enum.Font.GothamBold
	passClose.Parent = passPanel
	do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = passClose end
	passClose.MouseButton1Click:Connect(function() passPanel.Visible = false end)

	local howBox = Instance.new("Frame")
	howBox.Name = "HowBox"
	howBox.Size = UDim2.new(1, -28, 0, 78)
	howBox.Position = UDim2.new(0, 14, 0, 48)
	howBox.BackgroundColor3 = Color3.fromRGB(40, 32, 28)
	howBox.Parent = passPanel
	do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = howBox end
	local howTitle = Instance.new("TextLabel")
	howTitle.Size = UDim2.new(1, -16, 0, 20)
	howTitle.Position = UDim2.new(0, 10, 0, 6)
	howTitle.BackgroundTransparency = 1
	howTitle.Font = Enum.Font.GothamBold
	howTitle.TextSize = 13
	howTitle.TextXAlignment = Enum.TextXAlignment.Left
	howTitle.TextColor3 = Color3.fromRGB(255, 210, 120)
	howTitle.Text = "Как получить жетоны"
	howTitle.Parent = howBox
	local howBody = Instance.new("TextLabel")
	howBody.Size = UDim2.new(1, -16, 0, 48)
	howBody.Position = UDim2.new(0, 10, 0, 26)
	howBody.BackgroundTransparency = 1
	howBody.Font = Enum.Font.Gotham
	howBody.TextSize = 12
	howBody.TextXAlignment = Enum.TextXAlignment.Left
	howBody.TextYAlignment = Enum.TextYAlignment.Top
	howBody.TextColor3 = Color3.fromRGB(235, 220, 200)
	howBody.TextWrapped = true
	howBody.Text = "• Уход за духом  → +2\n• Закалка (Temper) → +3\n• Победа в бою / лут → +1 (+ Daily Board)"
	howBody.Parent = howBox

	local passBody = Instance.new("ScrollingFrame")
	passBody.Name = "Body"
	passBody.Size = UDim2.new(1, -28, 0, 140)
	passBody.Position = UDim2.new(0, 14, 0, 136)
	passBody.BackgroundTransparency = 1
	passBody.BorderSizePixel = 0
	passBody.ScrollBarThickness = 5
	passBody.ScrollBarImageColor3 = Color3.fromRGB(255, 196, 80)
	passBody.CanvasSize = UDim2.new(0, 0, 0, 0)
	passBody.AutomaticCanvasSize = Enum.AutomaticSize.Y
	passBody.ScrollingDirection = Enum.ScrollingDirection.Y
	passBody.Parent = passPanel
	local passBodyText = Instance.new("TextLabel")
	passBodyText.Name = "BodyText"
	passBodyText.Size = UDim2.new(1, -8, 0, 0)
	passBodyText.AutomaticSize = Enum.AutomaticSize.Y
	passBodyText.BackgroundTransparency = 1
	passBodyText.Font = Enum.Font.Gotham
	passBodyText.TextSize = 13
	passBodyText.TextXAlignment = Enum.TextXAlignment.Left
	passBodyText.TextYAlignment = Enum.TextYAlignment.Top
	passBodyText.TextColor3 = Color3.fromRGB(220, 225, 240)
	passBodyText.TextWrapped = true
	passBodyText.Text = "Загрузка сезона…"
	passBodyText.Parent = passBody

	local passActions = Instance.new("ScrollingFrame")
	passActions.Name = "Actions"
	passActions.Size = UDim2.new(1, -28, 0, 100)
	passActions.Position = UDim2.new(0, 14, 1, -110)
	passActions.BackgroundTransparency = 1
	passActions.BorderSizePixel = 0
	passActions.ScrollBarThickness = 5
	passActions.ScrollBarImageColor3 = Color3.fromRGB(255, 196, 80)
	passActions.CanvasSize = UDim2.new(0, 0, 0, 0)
	passActions.AutomaticCanvasSize = Enum.AutomaticSize.Y
	passActions.ScrollingDirection = Enum.ScrollingDirection.Y
	passActions.ClipsDescendants = true
	passActions.Parent = passPanel
	local lay = Instance.new("UIListLayout")
	lay.Padding = UDim.new(0, 5)
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Parent = passActions
	local actPad = Instance.new("UIPadding")
	actPad.PaddingTop = UDim.new(0, 2)
	actPad.PaddingBottom = UDim.new(0, 4)
	actPad.Parent = passActions

	dock.MouseButton1Click:Connect(function()
		passPanel.Visible = true
		havenEvent:FireServer("RequestSeason", {})
	end)
	return gui
end

local function setDockTokens(n)
	local gui = playerGui:FindFirstChild("SeasonPassGui")
	local dock = gui and gui:FindFirstChild("OpenPassButton")
	if dock then
		dock.Text = string.format("Сезон · %d жетонов", tonumber(n) or 0)
	end
end

local function refreshPassPanel(state)
	local gui = ensurePassGui()
	local panel = gui.PassPanelFrame
	local bodyScroll = panel:FindFirstChild("Body")
	local body = bodyScroll and bodyScroll:FindFirstChild("BodyText") or bodyScroll
	local title = panel.Title
	local actions = panel.Actions
	for _, ch in ipairs(actions:GetChildren()) do
		if ch:IsA("TextButton") then ch:Destroy() end
	end
	local season = state.Season or {}
	local sp = state.SeasonPass or {}
	local pity = state.CrystalPity or {}
	local tokens = tonumber(state.EventTokens) or 0
	setDockTokens(tokens)
	local lines = { string.format("Сезон: %s", tostring(season.Name or "?")) }
	if state.DaysLeft ~= nil then
		table.insert(lines, string.format("До конца: %d дн.", tonumber(state.DaysLeft) or 0))
	end
	table.insert(lines, string.format("Баланс: %d %s", tokens, tostring(state.TokenName or "жетонов")))
	table.insert(lines, string.format("Pass XP: %d", tonumber(sp.Xp) or 0))
	table.insert(lines, string.format("Pity кристаллов: %d/%d (до гаранта %d)",
		tonumber(pity.Misses) or 0, tonumber(pity.Threshold) or 10, tonumber(pity.Remaining) or 0))
	local soft = state.SoftBuffs or {}
	if soft.BondXpMult and (tonumber(soft.BondSecondsLeft) or 0) > 0 then
		local hrs = math.ceil((tonumber(soft.BondSecondsLeft) or 0) / 3600)
		table.insert(lines, string.format("Bond soft: ×%s · ещё ~%d ч", tostring(soft.BondXpMult), hrs))
	end
	table.insert(lines, "")
	table.insert(lines, "Награды пропуска:")
	local levels = (state.BattlePass and state.BattlePass.Levels) or {}
	for i, row in ipairs(levels) do
		local claimed = sp.Claimed and (sp.Claimed[i] or sp.Claimed[tostring(i)])
		local mark = claimed and "✓" or ((tonumber(sp.Xp) or 0) >= (tonumber(row.Need) or 0) and "★" or "·")
		table.insert(lines, string.format("%s L%d (нужно %d XP) — %s", mark, i, tonumber(row.Need) or 0, (row.Reward and row.Reward.Note) or ""))
	end
	if body then
		body.Text = table.concat(lines, "\n")
	end
	title.Text = "Сезонный пропуск"
	local function btn(text, color, cb)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1, 0, 0, 28)
		b.BackgroundColor3 = color or Color3.fromRGB(70, 90, 130)
		b.Text = text
		b.Font = Enum.Font.GothamBold
		b.TextSize = 13
		b.TextColor3 = Color3.fromRGB(255, 245, 220)
		b.Parent = actions
		do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = b end
		b.MouseButton1Click:Connect(cb)
	end
	for i, row in ipairs(levels) do
		local claimed = sp.Claimed and (sp.Claimed[i] or sp.Claimed[tostring(i)])
		local ready = (tonumber(sp.Xp) or 0) >= (tonumber(row.Need) or 0)
		if ready and not claimed then
			btn("Забрать награду L" .. tostring(i), Color3.fromRGB(60, 130, 80), function()
				havenEvent:FireServer("ClaimSeasonPass", { LevelIndex = i })
			end)
		end
	end
	btn("Сезонная форма — 50 жетонов", Color3.fromRGB(160, 110, 50), function()
		havenEvent:FireServer("BuySeasonOffer", { OfferId = "seasonal_form" })
	end)
end

havenEvent.OnClientEvent:Connect(function(action, data)
	if action == "SeasonState" then
		refreshPassPanel(data or {})
	elseif action == "SeasonBuyResult" or action == "SeasonClaimResult" then
		showToast((data and data.Message) or "Сезон")
		havenEvent:FireServer("RequestSeason", {})
	end
end)

do
	local dataSync = nil
	pcall(function()
		dataSync = ReplicatedStorage:WaitForChild("RealmOfSpirits"):WaitForChild("DataSync", 5)
	end)
	if dataSync then
		dataSync.OnClientEvent:Connect(function(action, data)
			if action == "FullSync" and type(data) == "table" then
				ensurePassGui()
				setDockTokens(data.EventTokens)
				local gui = playerGui:FindFirstChild("SeasonPassGui")
				local panel = gui and gui:FindFirstChild("PassPanelFrame")
				if panel and panel.Visible then
					havenEvent:FireServer("RequestSeason", {})
				end
			end
		end)
	end
end

task.defer(function()
	havenEvent:FireServer("RequestBuffs")
	havenEvent:FireServer("RequestFomo")
	ensurePassGui()
	havenEvent:FireServer("RequestSeason", {})
end)
print("Realm of Spirits - OtakuHavenController loaded!")
