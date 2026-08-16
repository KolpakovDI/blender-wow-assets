-- TradePanelUI: shop + sell inventory (extracted from UIController — 200 locals)
local TradePanelUI = {}

function TradePanelUI.Mount(screenGui, deps)
	local CreateFrame = deps.CreateFrame
	local CreateTextLabel = deps.CreateTextLabel
	local CreateTextButton = deps.CreateTextButton
	local ItemCatalog = deps.ItemCatalog
	local SpiritDatabaseModule = deps.SpiritDatabaseModule
	local TradeEvent = deps.TradeEvent
	local getPlayerData = deps.getPlayerData

	local tradeFrame = CreateFrame(screenGui, "TradeFrame",
		UDim2.new(0.5, -250, 0.5, -200),
		UDim2.new(0, 500, 0, 400),
		Color3.fromRGB(30, 30, 40)
	)
	tradeFrame.Visible = false
	tradeFrame.ZIndex = 55
	tradeFrame.ClipsDescendants = false

	CreateTextLabel(tradeFrame, "TradeTitle",
		UDim2.new(0, 10, 0, 10),
		UDim2.new(0.9, 0, 0, 28),
		"МАГАЗИН",
		Color3.fromRGB(255, 215, 0),
		22
	)

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
	shopListFrame.ClipsDescendants = true

	CreateTextLabel(shopListFrame, "ShopListTitle",
		UDim2.new(0, 5, 0, 5),
		UDim2.new(1, -10, 0, 20),
		"Товары",
		Color3.fromRGB(255, 255, 255),
		14
	)

	local shopScroll = Instance.new("ScrollingFrame")
	shopScroll.Name = "ShopScroll"
	shopScroll.Position = UDim2.new(0, 4, 0, 28)
	shopScroll.Size = UDim2.new(1, -8, 1, -34)
	shopScroll.BackgroundTransparency = 1
	shopScroll.BorderSizePixel = 0
	shopScroll.ScrollBarThickness = 6
	shopScroll.ScrollBarImageColor3 = Color3.fromRGB(180, 160, 120)
	shopScroll.ScrollingDirection = Enum.ScrollingDirection.Y
	shopScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	shopScroll.AutomaticCanvasSize = Enum.AutomaticSize.None
	shopScroll.ClipsDescendants = true
	shopScroll.ZIndex = 2
	shopScroll.Parent = shopListFrame

	local inventoryListFrame = CreateFrame(tradeFrame, "InventoryListFrame",
		UDim2.new(0.55, 5, 0, 75),
		UDim2.new(0.45, -15, 0, 250),
		Color3.fromRGB(40, 40, 50)
	)
	inventoryListFrame.ClipsDescendants = true

	CreateTextLabel(inventoryListFrame, "InventoryListTitle",
		UDim2.new(0, 5, 0, 5),
		UDim2.new(1, -10, 0, 20),
		"Инвентарь",
		Color3.fromRGB(255, 255, 255),
		14
	)

	local inventoryScroll = Instance.new("ScrollingFrame")
	inventoryScroll.Name = "InventoryScroll"
	inventoryScroll.Position = UDim2.new(0, 4, 0, 28)
	inventoryScroll.Size = UDim2.new(1, -8, 1, -34)
	inventoryScroll.BackgroundTransparency = 1
	inventoryScroll.BorderSizePixel = 0
	inventoryScroll.ScrollBarThickness = 6
	inventoryScroll.ScrollBarImageColor3 = Color3.fromRGB(180, 160, 120)
	inventoryScroll.ScrollingDirection = Enum.ScrollingDirection.Y
	inventoryScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	inventoryScroll.AutomaticCanvasSize = Enum.AutomaticSize.None
	inventoryScroll.ClipsDescendants = true
	inventoryScroll.ZIndex = 2
	inventoryScroll.Parent = inventoryListFrame

	local closeTradeButton = CreateTextButton(tradeFrame, "CloseTradeButton",
		UDim2.new(0.5, -60, 0, 335),
		UDim2.new(0, 120, 0, 35),
		"Закрыть",
		Color3.fromRGB(100, 100, 100),
		"❌"
	)
	closeTradeButton.ZIndex = 5
	closeTradeButton.MouseButton1Click:Connect(function()
		tradeFrame.Visible = false
	end)

	local shopItemButtons = {}
	local inventoryItemButtons = {}
	local lastShopItems = {}

	local function clearButtons(buttonList)
		for _, btn in ipairs(buttonList) do
			btn:Destroy()
		end
		table.clear(buttonList)
	end

	local function formatCopperPrice(copperAmount)
		local total = math.max(0, math.floor(tonumber(copperAmount) or 0))
		local gold = math.floor(total / 10000)
		total = total % 10000
		local silver = math.floor(total / 100)
		local copper = total % 100
		local parts = {}
		if gold > 0 then
			table.insert(parts, tostring(gold) .. "🥇")
		end
		if silver > 0 then
			table.insert(parts, tostring(silver) .. "🥈")
		end
		if copper > 0 or #parts == 0 then
			table.insert(parts, tostring(copper) .. "🥉")
		end
		return table.concat(parts, " ")
	end

	local function formatShopPrice(item)
		local goldPrice = tonumber(item and item.GoldPrice) or 0
		if goldPrice > 0 then
			return tostring(goldPrice) .. "🥇"
		end
		return formatCopperPrice(item and item.Price or 0)
	end

	local function itemDef(itemId)
		return ItemCatalog.Get(itemId) or (SpiritDatabaseModule.ShopItems and SpiritDatabaseModule.ShopItems[itemId])
	end

	local function walletTotals(playerData)
		local pd = playerData or {}
		local copper = tonumber(pd.CopperCoins) or 0
		local silver = tonumber(pd.SilverCoins) or 0
		local gold = tonumber(pd.GoldCoins) or 0
		return {
			Gold = gold,
			TotalCopper = copper + silver * 100 + gold * 10000,
		}
	end

	local function resolveShopPrices(item)
		local def = itemDef(item and item.Id)
		return {
			GoldPrice = tonumber(item and item.GoldPrice) or (def and tonumber(def.GoldPrice)) or 0,
			Price = tonumber(item and item.Price) or (def and tonumber(def.Price)) or 0,
			Name = (item and item.Name) or (def and def.Name),
			Id = item and item.Id,
		}
	end

	local function canAffordShopItem(priced, wallet)
		local goldPrice = priced.GoldPrice or 0
		if goldPrice > 0 then
			return (wallet.Gold or 0) >= goldPrice
		end
		return (wallet.TotalCopper or 0) >= (priced.Price or 0)
	end

	local api = {}

	function api.IsVisible()
		return tradeFrame.Visible == true
	end

	function api.SetVisible(visible)
		tradeFrame.Visible = visible == true
	end

	function api.SetCoins(gold, silver, copper)
		tradeCoinsLabel.Text = string.format("Монеты: %d 🥇 %d 🥈 %d 🥉", gold, silver, copper)
	end

	function api.RefreshInventory()
		clearButtons(inventoryItemButtons)
		local playerData = getPlayerData() or {}
		local y = 4
		for _, item in ipairs(playerData.Inventory or {}) do
			local def = itemDef(item.Id)
			local itemName = (def and def.Name) or ("Предмет #" .. item.Id)
			local canSell = ItemCatalog.CanSell(item.Id)
			local sellPriceText = canSell and formatCopperPrice((def and def.SellPrice) or 0) or "—"
			local showUse = (item.Id == 3 or item.Id == 203)
			local rightPad = showUse and 150 or 76

			local btn = CreateTextButton(inventoryScroll, "InvItem" .. item.Id,
				UDim2.new(0, 2, 0, y),
				UDim2.new(1, -14, 0, 45),
				"",
				Color3.fromRGB(70, 100, 140),
				nil
			)
			btn.Text = ""
			btn.TextTransparency = 1
			btn.ClipsDescendants = true

			local nameLbl = Instance.new("TextLabel")
			nameLbl.Name = "ItemName"
			nameLbl.BackgroundTransparency = 1
			nameLbl.Position = UDim2.new(0, 8, 0, 0)
			nameLbl.Size = UDim2.new(1, -rightPad, 1, 0)
			nameLbl.Font = Enum.Font.GothamBold
			nameLbl.TextSize = 13
			nameLbl.TextColor3 = Color3.fromRGB(245, 240, 230)
			nameLbl.TextXAlignment = Enum.TextXAlignment.Left
			nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
			nameLbl.Text = itemName .. " x" .. tostring(item.Quantity or 1)
			nameLbl.ZIndex = (btn.ZIndex or 1) + 1
			nameLbl.Parent = btn

			local sellBtn = CreateTextButton(btn, "SellBtn",
				UDim2.new(1, -72, 0, 5),
				UDim2.new(0, 68, 0, 35),
				"Продать",
				Color3.fromRGB(180, 100, 70),
				nil
			)
			sellBtn.Text = canSell and ("Продать\n" .. sellPriceText) or "Нельзя"
			sellBtn.TextScaled = true
			sellBtn.Active = canSell
			sellBtn.AutoButtonColor = canSell
			local useBtn = CreateTextButton(btn, "UseBtn",
				UDim2.new(1, -146, 0, 5),
				UDim2.new(0, 70, 0, 35),
				"Исп.",
				Color3.fromRGB(100, 180, 100),
				nil
			)
			useBtn.Visible = showUse
			if item.Id == 203 then
				useBtn.Text = "Имя"
			end
			local itemId = item.Id
			sellBtn.MouseButton1Click:Connect(function()
				if not ItemCatalog.CanSell(itemId) then
					return
				end
				TradeEvent:FireServer("Sell", { ItemId = itemId, Quantity = 1 })
			end)
			useBtn.MouseButton1Click:Connect(function()
				if itemId == 203 then
					TradeEvent:FireServer("RenameSpirit", {
						SpiritIndex = playerData.ActiveSpiritIndex or 1,
						Name = "Дух",
					})
				else
					TradeEvent:FireServer("UseItem", { ItemId = itemId })
				end
			end)
			table.insert(inventoryItemButtons, btn)
			y = y + 50
		end
		inventoryScroll.CanvasSize = UDim2.new(0, 0, 0, math.max(y, 4))
		inventoryScroll.CanvasPosition = Vector2.zero
	end

	function api.RefreshShop(items)
		if type(items) == "table" then
			lastShopItems = items
		end
		clearButtons(shopItemButtons)
		local wallet = walletTotals(getPlayerData())
		local y = 4
		for _, item in ipairs(lastShopItems or {}) do
			local priced = resolveShopPrices(item)
			local priceText = formatShopPrice(priced)
			local affordable = canAffordShopItem(priced, wallet)
			local displayName = tostring(priced.Name or ("#" .. tostring(priced.Id)))

			local btn = CreateTextButton(shopScroll, "ShopItem" .. tostring(priced.Id),
				UDim2.new(0, 2, 0, y),
				UDim2.new(1, -14, 0, 52),
				"",
				Color3.fromRGB(70, 130, 180),
				nil
			)
			btn.Text = ""
			btn.TextTransparency = 1
			btn.ClipsDescendants = true

			local nameLbl = Instance.new("TextLabel")
			nameLbl.Name = "ItemName"
			nameLbl.BackgroundTransparency = 1
			nameLbl.Position = UDim2.new(0, 8, 0, 2)
			nameLbl.Size = UDim2.new(1, -80, 0, 22)
			nameLbl.Font = Enum.Font.GothamBold
			nameLbl.TextSize = 13
			nameLbl.TextColor3 = Color3.fromRGB(245, 240, 230)
			nameLbl.TextXAlignment = Enum.TextXAlignment.Left
			nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
			nameLbl.Text = displayName
			nameLbl.ZIndex = (btn.ZIndex or 1) + 1
			nameLbl.Parent = btn

			local priceLbl = Instance.new("TextLabel")
			priceLbl.Name = "ItemPrice"
			priceLbl.BackgroundTransparency = 1
			priceLbl.Position = UDim2.new(0, 8, 0, 24)
			priceLbl.Size = UDim2.new(1, -80, 0, 22)
			priceLbl.Font = Enum.Font.Gotham
			priceLbl.TextSize = 12
			priceLbl.TextColor3 = affordable and Color3.fromRGB(160, 230, 160) or Color3.fromRGB(255, 140, 140)
			priceLbl.TextXAlignment = Enum.TextXAlignment.Left
			priceLbl.TextTruncate = Enum.TextTruncate.AtEnd
			priceLbl.Text = affordable and ("Цена: " .. priceText) or ("Цена: " .. priceText .. " (мало)")
			priceLbl.ZIndex = (btn.ZIndex or 1) + 1
			priceLbl.Parent = btn

			local buyBtn = CreateTextButton(btn, "BuyBtn",
				UDim2.new(1, -72, 0, 8),
				UDim2.new(0, 68, 0, 36),
				"Купить",
				affordable and Color3.fromRGB(70, 180, 70) or Color3.fromRGB(110, 90, 90),
				nil
			)
			buyBtn.Text = "Купить\n" .. priceText
			buyBtn.TextScaled = true
			buyBtn.TextColor3 = affordable and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(220, 180, 180)
			local itemId = priced.Id
			buyBtn.MouseButton1Click:Connect(function()
				TradeEvent:FireServer("Buy", { ItemId = itemId, Quantity = 1 })
			end)
			table.insert(shopItemButtons, btn)
			y = y + 58
		end
		shopScroll.CanvasSize = UDim2.new(0, 0, 0, math.max(y, 4))
		shopScroll.CanvasPosition = Vector2.zero
	end

	function api.RefreshAfford()
		if tradeFrame.Visible and #lastShopItems > 0 then
			api.RefreshShop(lastShopItems)
		end
	end

	function api.Open()
		tradeFrame.Visible = true
		TradeEvent:FireServer("GetShop", {})
		api.RefreshInventory()
	end

	function api.BindZoneSilentRefresh(player)
		local function handleShopZoneActivation()
			if tradeFrame.Visible then
				TradeEvent:FireServer("GetShop", {})
			end
		end
		player:GetAttributeChangedSignal("CurrentZone"):Connect(handleShopZoneActivation)
		task.defer(handleShopZoneActivation)
	end

	return api
end

return TradePanelUI
