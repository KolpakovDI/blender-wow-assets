-- OtakuHavenController
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local RealmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local havenEvent = RealmFolder:WaitForChild("OtakuHaven")
local tradeEvent = RealmFolder:WaitForChild("Trade")
local function getMainGui()
	return player:WaitForChild("PlayerGui"):FindFirstChild("RealmOfSpiritsUI")
end
local function showToast(text, color)
	if not text or text == "" then return end
	local pg = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui", 5)
	if not pg then return end
	-- Отдельный GUI выше XP-бара и основного UI (не ZoneToast внизу экрана)
	local gui = pg:FindFirstChild("OtakuHavenToastGui")
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "OtakuHavenToastGui"
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true
		gui.DisplayOrder = 400
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.Parent = pg
	end
	gui.DisplayOrder = 400
	gui.Enabled = true
	local label = gui:FindFirstChild("Toast")
	if not label then
		label = Instance.new("TextLabel")
		label.Name = "Toast"
		label.AnchorPoint = Vector2.new(0.5, 0)
		label.Position = UDim2.new(0.5, 0, 0.14, 0)
		label.Size = UDim2.new(0, 460, 0, 40)
		label.BackgroundColor3 = Color3.fromRGB(20, 18, 28)
		label.BackgroundTransparency = 0.15
		label.Font = Enum.Font.GothamBold
		label.TextSize = 17
		label.TextWrapped = true
		label.ZIndex = 10
		label.Parent = gui
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 8)
		c.Parent = label
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 12)
		pad.PaddingRight = UDim.new(0, 12)
		pad.Parent = label
	end
	label.Position = UDim2.new(0.5, 0, 0.14, 0)
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(200, 255, 220)
	label.Visible = true
	task.delay(3.5, function()
		if label and label.Parent and label.Text == text then
			label.Visible = false
		end
	end)
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
task.defer(function()
	havenEvent:FireServer("RequestBuffs")
	havenEvent:FireServer("RequestFomo")
end)
print("Realm of Spirits - OtakuHavenController loaded!")
