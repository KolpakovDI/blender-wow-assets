-- PlayerTradeController — P2P 1-slot trade UI (item OR cosmetic, Safe zone)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local RealmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local ItemCatalog = require(RealmFolder:WaitForChild("ItemCatalog"))
local tradeEvent = RealmFolder:WaitForChild("PlayerTrade")
local dataEvent = RealmFolder:WaitForChild("DataSync")

local inventory = {}
local cosmetics = {}
local inTrade = false
local partnerName = ""
local myOffer = {}
local partnerOffer = {}
local myReady = false
local partnerReady = false

local function itemName(itemId)
	local def = itemId and ItemCatalog.Get(itemId)
	return def and def.Name or ("#" .. tostring(itemId or "?"))
end

local function formatOffer(offer)
	offer = offer or {}
	if type(offer.CosmeticId) == "string" and offer.CosmeticId ~= "" then
		local label = offer.Name or offer.CosmeticId
		if offer.Rarity then
			return string.format("Косметика: %s (%s)", tostring(label), tostring(offer.Rarity))
		end
		return "Косметика: " .. tostring(label)
	end
	if offer.ItemId and (offer.Quantity or 0) > 0 then
		return string.format("%s x%d", itemName(offer.ItemId), offer.Quantity or 1)
	end
	return "(пусто)"
end

local function showToast(text)
	if not text or text == "" then
		return
	end
	local pg = player:WaitForChild("PlayerGui")
	local gui = pg:FindFirstChild("PlayerTradeToastGui")
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "PlayerTradeToastGui"
		gui.ResetOnSpawn = false
		gui.DisplayOrder = 500
		gui.IgnoreGuiInset = true
		gui.Parent = pg
	end
	local label = gui:FindFirstChild("Toast")
	if not label then
		label = Instance.new("TextLabel")
		label.Name = "Toast"
		label.AnchorPoint = Vector2.new(0.5, 0)
		label.Position = UDim2.new(0.5, 0, 0.12, 0)
		label.Size = UDim2.new(0, 520, 0, 52)
		label.BackgroundColor3 = Color3.fromRGB(24, 18, 34)
		label.BackgroundTransparency = 0.08
		label.Font = Enum.Font.GothamBold
		label.TextSize = 17
		label.TextWrapped = true
		label.TextColor3 = Color3.fromRGB(220, 245, 255)
		label.Parent = gui
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 8)
		c.Parent = label
	end
	label.Text = text
	label.Visible = true
	task.delay(5, function()
		if label.Parent and label.Text == text then
			label.Visible = false
		end
	end)
end

local guiRoot, panel, titleLabel, myOfferLabel, partnerOfferLabel, readyLabel, invList, cosList

local function refreshInvList()
	if not invList then
		return
	end
	for _, child in ipairs(invList:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	local y = 0
	for _, entry in ipairs(inventory) do
		local id = entry.Id or entry.ItemId
		local qty = entry.Quantity or 0
		if id and qty > 0 then
			local btn = Instance.new("TextButton")
			btn.Name = "Inv_" .. tostring(id)
			btn.Size = UDim2.new(1, -8, 0, 26)
			btn.Position = UDim2.new(0, 4, 0, y)
			btn.BackgroundColor3 = Color3.fromRGB(48, 36, 64)
			btn.Font = Enum.Font.Gotham
			btn.TextSize = 13
			btn.TextColor3 = Color3.fromRGB(240, 230, 255)
			btn.TextXAlignment = Enum.TextXAlignment.Left
			btn.TextTruncate = Enum.TextTruncate.AtEnd
			btn.Text = string.format("  %s x%d", itemName(id), qty)
			btn.Parent = invList
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 6)
			corner.Parent = btn
			btn.MouseButton1Click:Connect(function()
				if not inTrade then
					return
				end
				tradeEvent:FireServer("SetOffer", { ItemId = id, Quantity = 1 })
			end)
			y += 30
		end
	end
	invList.CanvasSize = UDim2.new(0, 0, 0, y)
end

local function refreshCosList()
	if not cosList then
		return
	end
	for _, child in ipairs(cosList:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end
	local y = 0
	for _, entry in ipairs(cosmetics) do
		local id = type(entry) == "table" and entry.Id or nil
		if type(id) == "string" and id ~= "" then
			local btn = Instance.new("TextButton")
			btn.Name = "Cos_" .. id
			btn.Size = UDim2.new(1, -8, 0, 26)
			btn.Position = UDim2.new(0, 4, 0, y)
			btn.BackgroundColor3 = Color3.fromRGB(40, 48, 72)
			btn.Font = Enum.Font.Gotham
			btn.TextSize = 13
			btn.TextColor3 = Color3.fromRGB(220, 235, 255)
			btn.TextXAlignment = Enum.TextXAlignment.Left
			btn.TextTruncate = Enum.TextTruncate.AtEnd
			local nm = entry.Name or id
			local rarity = entry.Rarity
			btn.Text = rarity and string.format("  %s (%s)", tostring(nm), tostring(rarity)) or ("  " .. tostring(nm))
			btn.Parent = cosList
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 6)
			corner.Parent = btn
			btn.MouseButton1Click:Connect(function()
				if not inTrade then
					return
				end
				tradeEvent:FireServer("SetOffer", { CosmeticId = id })
			end)
			y += 30
		end
	end
	cosList.CanvasSize = UDim2.new(0, 0, 0, y)
end

local function refreshPanel()
	if not panel then
		return
	end
	panel.Visible = inTrade
	if not inTrade then
		return
	end
	titleLabel.Text = "Обмен с " .. (partnerName ~= "" and partnerName or "игроком")
	myOfferLabel.Text = "Вы: " .. formatOffer(myOffer)
	partnerOfferLabel.Text = "Партнёр: " .. formatOffer(partnerOffer)
	readyLabel.Text = string.format(
		"Готовность: вы %s · партнёр %s",
		myReady and "OK" or "...",
		partnerReady and "OK" or "..."
	)
	refreshInvList()
	refreshCosList()
end

local function ensureGui()
	if guiRoot then
		return
	end
	local pg = player:WaitForChild("PlayerGui")
	guiRoot = Instance.new("ScreenGui")
	guiRoot.Name = "PlayerTradeGui"
	guiRoot.ResetOnSpawn = false
	guiRoot.DisplayOrder = 430
	guiRoot.IgnoreGuiInset = true
	guiRoot.Parent = pg

	panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.48)
	panel.Size = UDim2.new(0, 440, 0, 460)
	panel.BackgroundColor3 = Color3.fromRGB(28, 22, 40)
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = guiRoot
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(120, 200, 255)
	stroke.Thickness = 2
	stroke.Parent = panel

	titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -20, 0, 28)
	titleLabel.Position = UDim2.new(0, 10, 0, 10)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 20
	titleLabel.TextColor3 = Color3.fromRGB(200, 235, 255)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Text = "Обмен"
	titleLabel.Parent = panel

	myOfferLabel = Instance.new("TextLabel")
	myOfferLabel.Name = "MyOffer"
	myOfferLabel.Size = UDim2.new(1, -20, 0, 22)
	myOfferLabel.Position = UDim2.new(0, 10, 0, 44)
	myOfferLabel.BackgroundTransparency = 1
	myOfferLabel.Font = Enum.Font.Gotham
	myOfferLabel.TextSize = 15
	myOfferLabel.TextColor3 = Color3.fromRGB(230, 220, 210)
	myOfferLabel.TextXAlignment = Enum.TextXAlignment.Left
	myOfferLabel.Parent = panel

	partnerOfferLabel = Instance.new("TextLabel")
	partnerOfferLabel.Name = "PartnerOffer"
	partnerOfferLabel.Size = UDim2.new(1, -20, 0, 22)
	partnerOfferLabel.Position = UDim2.new(0, 10, 0, 68)
	partnerOfferLabel.BackgroundTransparency = 1
	partnerOfferLabel.Font = Enum.Font.Gotham
	partnerOfferLabel.TextSize = 15
	partnerOfferLabel.TextColor3 = Color3.fromRGB(230, 220, 210)
	partnerOfferLabel.TextXAlignment = Enum.TextXAlignment.Left
	partnerOfferLabel.Parent = panel

	readyLabel = Instance.new("TextLabel")
	readyLabel.Name = "ReadyState"
	readyLabel.Size = UDim2.new(1, -20, 0, 20)
	readyLabel.Position = UDim2.new(0, 10, 0, 92)
	readyLabel.BackgroundTransparency = 1
	readyLabel.Font = Enum.Font.GothamBold
	readyLabel.TextSize = 14
	readyLabel.TextColor3 = Color3.fromRGB(180, 255, 200)
	readyLabel.TextXAlignment = Enum.TextXAlignment.Left
	readyLabel.Parent = panel

	local invTitle = Instance.new("TextLabel")
	invTitle.Size = UDim2.new(1, -20, 0, 18)
	invTitle.Position = UDim2.new(0, 10, 0, 118)
	invTitle.BackgroundTransparency = 1
	invTitle.Font = Enum.Font.GothamBold
	invTitle.TextSize = 13
	invTitle.TextColor3 = Color3.fromRGB(180, 170, 160)
	invTitle.TextXAlignment = Enum.TextXAlignment.Left
	invTitle.Text = "Инвентарь — клик = предложить"
	invTitle.Parent = panel

	invList = Instance.new("ScrollingFrame")
	invList.Name = "InvList"
	invList.Size = UDim2.new(1, -20, 0, 100)
	invList.Position = UDim2.new(0, 10, 0, 138)
	invList.BackgroundColor3 = Color3.fromRGB(18, 14, 28)
	invList.BorderSizePixel = 0
	invList.ScrollBarThickness = 6
	invList.CanvasSize = UDim2.new(0, 0, 0, 0)
	invList.ClipsDescendants = true
	invList.Parent = panel
	local invCorner = Instance.new("UICorner")
	invCorner.CornerRadius = UDim.new(0, 8)
	invCorner.Parent = invList

	local cosTitle = Instance.new("TextLabel")
	cosTitle.Size = UDim2.new(1, -20, 0, 18)
	cosTitle.Position = UDim2.new(0, 10, 0, 246)
	cosTitle.BackgroundTransparency = 1
	cosTitle.Font = Enum.Font.GothamBold
	cosTitle.TextSize = 13
	cosTitle.TextColor3 = Color3.fromRGB(180, 170, 160)
	cosTitle.TextXAlignment = Enum.TextXAlignment.Left
	cosTitle.Text = "Косметика — клик = предложить"
	cosTitle.Parent = panel

	cosList = Instance.new("ScrollingFrame")
	cosList.Name = "CosList"
	cosList.Size = UDim2.new(1, -20, 0, 100)
	cosList.Position = UDim2.new(0, 10, 0, 266)
	cosList.BackgroundColor3 = Color3.fromRGB(14, 18, 28)
	cosList.BorderSizePixel = 0
	cosList.ScrollBarThickness = 6
	cosList.CanvasSize = UDim2.new(0, 0, 0, 0)
	cosList.ClipsDescendants = true
	cosList.Parent = panel
	local cosCorner = Instance.new("UICorner")
	cosCorner.CornerRadius = UDim.new(0, 8)
	cosCorner.Parent = cosList

	local clearBtn = Instance.new("TextButton")
	clearBtn.Name = "ClearOffer"
	clearBtn.Size = UDim2.new(0, 120, 0, 32)
	clearBtn.Position = UDim2.new(0, 10, 1, -48)
	clearBtn.BackgroundColor3 = Color3.fromRGB(70, 55, 80)
	clearBtn.Font = Enum.Font.GothamBold
	clearBtn.TextSize = 14
	clearBtn.TextColor3 = Color3.new(1, 1, 1)
	clearBtn.Text = "Убрать"
	clearBtn.Parent = panel
	local clearCorner = Instance.new("UICorner")
	clearCorner.CornerRadius = UDim.new(0, 8)
	clearCorner.Parent = clearBtn
	clearBtn.MouseButton1Click:Connect(function()
		if inTrade then
			tradeEvent:FireServer("SetOffer", {})
		end
	end)

	local readyBtn = Instance.new("TextButton")
	readyBtn.Name = "Ready"
	readyBtn.Size = UDim2.new(0, 120, 0, 32)
	readyBtn.Position = UDim2.new(0.5, -60, 1, -48)
	readyBtn.BackgroundColor3 = Color3.fromRGB(50, 140, 90)
	readyBtn.Font = Enum.Font.GothamBold
	readyBtn.TextSize = 14
	readyBtn.TextColor3 = Color3.new(1, 1, 1)
	readyBtn.Text = "Готово"
	readyBtn.Parent = panel
	local readyCorner = Instance.new("UICorner")
	readyCorner.CornerRadius = UDim.new(0, 8)
	readyCorner.Parent = readyBtn
	readyBtn.MouseButton1Click:Connect(function()
		if inTrade then
			tradeEvent:FireServer("Ready", { Ready = not myReady })
		end
	end)

	local cancelBtn = Instance.new("TextButton")
	cancelBtn.Name = "Cancel"
	cancelBtn.Size = UDim2.new(0, 120, 0, 32)
	cancelBtn.Position = UDim2.new(1, -130, 1, -48)
	cancelBtn.BackgroundColor3 = Color3.fromRGB(150, 60, 70)
	cancelBtn.Font = Enum.Font.GothamBold
	cancelBtn.TextSize = 14
	cancelBtn.TextColor3 = Color3.new(1, 1, 1)
	cancelBtn.Text = "Отмена"
	cancelBtn.Parent = panel
	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0, 8)
	cancelCorner.Parent = cancelBtn
	cancelBtn.MouseButton1Click:Connect(function()
		if inTrade then
			tradeEvent:FireServer("Cancel", {})
		end
	end)
end

local function openTrade(name)
	ensureGui()
	inTrade = true
	player:SetAttribute("InPlayerTrade", true)
	partnerName = name or partnerName
	myOffer, partnerOffer = {}, {}
	myReady, partnerReady = false, false
	refreshPanel()
end

local function closeTrade()
	inTrade = false
	player:SetAttribute("InPlayerTrade", nil)
	partnerName = ""
	myOffer, partnerOffer = {}, {}
	myReady, partnerReady = false, false
	refreshPanel()
end

local function applyState(data)
	data = data or {}
	myOffer = data.Offer or {}
	partnerOffer = data.PartnerOffer or {}
	myReady = data.Ready == true
	partnerReady = data.PartnerReady == true
	if data.PartnerName then
		partnerName = data.PartnerName
	end
	inTrade = true
	player:SetAttribute("InPlayerTrade", true)
	ensureGui()
	refreshPanel()
end

tradeEvent.OnClientEvent:Connect(function(action, payload)
	payload = payload or {}
	if action == "TradeOpened" then
		openTrade(payload.PartnerName)
		showToast("Обмен открыт")
	elseif action == "TradeIncoming" then
		openTrade(payload.FromName)
		showToast((payload.FromName or "Игрок") .. " предлагает обмен")
	elseif action == "TradeState" then
		applyState(payload)
	elseif action == "Toast" then
		showToast(payload.Text or "")
	elseif action == "TradeComplete" then
		local msg = payload.Text
		if not msg or msg == "" then
			msg = string.format(
				"✓ Обмен успешен! Отдали: %s · Получили: %s",
				formatOffer(payload.Gave),
				formatOffer(payload.Received)
			)
		end
		showToast(msg)
		closeTrade()
	elseif action == "TradeCancelled" then
		showToast(payload.Text or "Обмен отменён")
		closeTrade()
	end
end)

dataEvent.OnClientEvent:Connect(function(action, data)
	if action == "FullSync" and type(data) == "table" then
		inventory = data.Inventory or {}
		cosmetics = data.Cosmetics or {}
		if inTrade then
			refreshInvList()
			refreshCosList()
		end
	end
end)

ensureGui()
print("Realm of Spirits - PlayerTradeController loaded (item/cosmetic)!")
