-- BagContentUI: grid + detail panel (UI package D)
local BagContentUI = {}

function BagContentUI.Mount(screenGui, deps)
	local CreateFrame = deps.CreateFrame
	local CreateTextLabel = deps.CreateTextLabel
	local CreateTextButton = deps.CreateTextButton
	local StylePanel = deps.StylePanel
	local ItemCatalog = deps.ItemCatalog
	local bagCapacities = deps.bagCapacities

	local frame = CreateFrame(screenGui, "BagContentFrame",
		UDim2.new(0.5, -270, 0.5, -175),
		UDim2.new(0, 540, 0, 350),
		Color3.fromRGB(28, 28, 40)
	)
	frame.Visible = false
	StylePanel(frame, "stone")

	local title = CreateTextLabel(frame, "BagContentTitle",
		UDim2.new(0, 12, 0, 8),
		UDim2.new(1, -24, 0, 26),
		"Сумка",
		Color3.fromRGB(255, 215, 0),
		18
	)
	title.TextXAlignment = Enum.TextXAlignment.Left

	local list = Instance.new("ScrollingFrame")
	list.Name = "BagContentList"
	list.Position = UDim2.new(0, 12, 0, 42)
	list.Size = UDim2.new(0, 300, 0, 210)
	list.BackgroundColor3 = Color3.fromRGB(36, 36, 50)
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 6
	list.CanvasSize = UDim2.new(0, 0, 0, 0)
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.Parent = frame
	do
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 8)
		c.Parent = list
		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 8)
		pad.PaddingLeft = UDim.new(0, 8)
		pad.PaddingRight = UDim.new(0, 8)
		pad.PaddingBottom = UDim.new(0, 8)
		pad.Parent = list
		local grid = Instance.new("UIGridLayout")
		grid.Name = "BagGrid"
		grid.CellSize = UDim2.fromOffset(64, 64)
		grid.CellPadding = UDim2.fromOffset(6, 6)
		grid.SortOrder = Enum.SortOrder.LayoutOrder
		grid.Parent = list
	end

	local detail = CreateFrame(frame, "BagDetailPanel",
		UDim2.new(0, 324, 0, 42),
		UDim2.new(0, 204, 0, 210),
		Color3.fromRGB(40, 36, 52)
	)
	StylePanel(detail, "parchment")

	local detailIcon = CreateTextLabel(detail, "DetailIcon",
		UDim2.new(0, 8, 0, 8), UDim2.new(0, 40, 0, 40),
		"📦", Color3.fromRGB(255, 255, 255), 28)
	detailIcon.TextXAlignment = Enum.TextXAlignment.Center

	local detailName = CreateTextLabel(detail, "DetailName",
		UDim2.new(0, 52, 0, 8), UDim2.new(1, -60, 0, 22),
		"Выберите предмет", Color3.fromRGB(255, 230, 160), 14)
	detailName.TextXAlignment = Enum.TextXAlignment.Left
	detailName.TextTruncate = Enum.TextTruncate.AtEnd

	local detailWhy = CreateTextLabel(detail, "DetailWhy",
		UDim2.new(0, 52, 0, 30), UDim2.new(1, -60, 0, 18),
		"", Color3.fromRGB(160, 220, 255), 12)
	detailWhy.TextXAlignment = Enum.TextXAlignment.Left

	local detailQty = CreateTextLabel(detail, "DetailQty",
		UDim2.new(0, 8, 0, 56), UDim2.new(1, -16, 0, 18),
		"", Color3.fromRGB(200, 200, 210), 12)
	detailQty.TextXAlignment = Enum.TextXAlignment.Left

	local detailDescScroll = Instance.new("ScrollingFrame")
	detailDescScroll.Name = "DetailDescScroll"
	detailDescScroll.Position = UDim2.new(0, 8, 0, 78)
	detailDescScroll.Size = UDim2.new(1, -16, 1, -86)
	detailDescScroll.BackgroundTransparency = 1
	detailDescScroll.BorderSizePixel = 0
	detailDescScroll.ScrollBarThickness = 5
	detailDescScroll.ScrollBarImageColor3 = Color3.fromRGB(180, 160, 120)
	detailDescScroll.ScrollingDirection = Enum.ScrollingDirection.Y
	detailDescScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	detailDescScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	detailDescScroll.ClipsDescendants = true
	detailDescScroll.Parent = detail
	local detailDesc = CreateTextLabel(detailDescScroll, "DetailDesc",
		UDim2.new(0, 0, 0, 0), UDim2.new(1, -6, 0, 0),
		"Клик по ячейке — описание из каталога.", Color3.fromRGB(220, 210, 200), 12)
	detailDesc.AutomaticSize = Enum.AutomaticSize.Y
	detailDesc.TextXAlignment = Enum.TextXAlignment.Left
	detailDesc.TextYAlignment = Enum.TextYAlignment.Top
	detailDesc.TextWrapped = true

	local currencyPanel = CreateFrame(frame, "BagCurrencyPanel",
		UDim2.new(0, 12, 1, -88), UDim2.new(1, -24, 0, 36), Color3.fromRGB(50, 45, 32))
	StylePanel(currencyPanel, "wood")

	local currencyLabel = CreateTextLabel(currencyPanel, "BagCurrencyLabel",
		UDim2.new(0, 10, 0, 0), UDim2.new(1, -20, 1, 0),
		"💰 0 🥇 | 0 🥈 | 0 🥉", Color3.fromRGB(255, 230, 170), 13)
	currencyLabel.TextXAlignment = Enum.TextXAlignment.Left

	local closeBtn = CreateTextButton(frame, "CloseBagContentButton",
		UDim2.new(0.5, -60, 1, -44), UDim2.new(0, 120, 0, 32),
		"Закрыть", Color3.fromRGB(100, 100, 100), "❌")

	local openedIndex = nil
	local selectedIndex = nil
	local currentPacked = {}

	local function clearDetail()
		selectedIndex = nil
		detailIcon.Text = "📦"
		detailName.Text = "Выберите предмет"
		detailWhy.Text = ""
		detailQty.Text = ""
		detailDesc.Text = "Клик по ячейке — описание из каталога."
		detailDescScroll.CanvasPosition = Vector2.new(0, 0)
	end

	local function showDetail(item)
		if not item then
			clearDetail()
			return
		end
		detailIcon.Text = item.Icon or ItemCatalog.GetIconEmoji(item.Id)
		detailName.Text = item.Name or ("#" .. tostring(item.Id))
		local why = item.Why or ItemCatalog.GetWhyTag(item.Id)
		detailWhy.Text = why and ("· " .. why) or ""
		detailQty.Text = string.format("Стак: ×%d", tonumber(item.Quantity) or 1)
		detailDesc.Text = item.Description or ""
		detailDescScroll.CanvasPosition = Vector2.new(0, 0)
	end

	local function buildPacked(inventory, bags)
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
				bagIndex += 1
			end
			if bagIndex > 9 then
				break
			end
			local def = ItemCatalog.Get(item.Id)
			local name = (def and def.Name) or ("Предмет #" .. tostring(item.Id))
			table.insert(packed[bagIndex].Items, {
				Id = item.Id,
				Name = name,
				Why = ItemCatalog.GetWhyTag(item.Id),
				Quantity = tonumber(item.Quantity) or 1,
				Description = (def and def.Description) or "",
				Icon = ItemCatalog.GetIconEmoji(item.Id),
				RarityColor = ItemCatalog.GetRarityColor(item.Id),
			})
		end
		return packed
	end

	local function refresh(index)
		local bag = currentPacked[index] or {Capacity = bagCapacities[index], Items = {}}
		title.Text = string.format("Сумка %d (%d слотов)", index, bag.Capacity)
		for _, child in ipairs(list:GetChildren()) do
			if not child:IsA("UIGridLayout") and not child:IsA("UIPadding") and not child:IsA("UICorner") then
				child:Destroy()
			end
		end
		if #bag.Items == 0 then
			clearDetail()
			local emptyLabel = CreateTextLabel(list, "BagEmpty",
				UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 24),
				"Пусто", Color3.fromRGB(180, 180, 200), 14)
			emptyLabel.TextXAlignment = Enum.TextXAlignment.Left
			emptyLabel.LayoutOrder = 0
			return
		end
		if not selectedIndex or selectedIndex < 1 or selectedIndex > #bag.Items then
			selectedIndex = 1
		end
		for i, item in ipairs(bag.Items) do
			local cell = Instance.new("TextButton")
			cell.Name = "BagItemCell" .. i
			cell.BackgroundColor3 = Color3.fromRGB(48, 44, 60)
			cell.BorderSizePixel = 0
			cell.Text = ""
			cell.AutoButtonColor = true
			cell.LayoutOrder = i
			cell.Parent = list
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 8)
			corner.Parent = cell
			local stroke = Instance.new("UIStroke")
			stroke.Color = item.RarityColor or Color3.fromRGB(170, 170, 180)
			stroke.Thickness = (i == selectedIndex) and 2.5 or 1.5
			stroke.Parent = cell
			local icon = Instance.new("TextLabel")
			icon.Name = "Icon"
			icon.BackgroundTransparency = 1
			icon.Size = UDim2.new(1, 0, 0, 36)
			icon.Position = UDim2.new(0, 0, 0, 4)
			icon.Text = item.Icon or "📦"
			icon.TextSize = 24
			icon.Font = Enum.Font.GothamBold
			icon.TextColor3 = Color3.fromRGB(255, 255, 255)
			icon.Parent = cell
			local qty = Instance.new("TextLabel")
			qty.Name = "Qty"
			qty.BackgroundTransparency = 1
			qty.Size = UDim2.new(1, -4, 0, 16)
			qty.Position = UDim2.new(0, 2, 1, -18)
			qty.Text = "×" .. tostring(item.Quantity)
			qty.TextSize = 11
			qty.Font = Enum.Font.GothamBold
			qty.TextColor3 = Color3.fromRGB(230, 230, 240)
			qty.TextXAlignment = Enum.TextXAlignment.Right
			qty.Parent = cell
			cell.MouseButton1Click:Connect(function()
				selectedIndex = i
				showDetail(item)
				for _, sibling in ipairs(list:GetChildren()) do
					if sibling:IsA("TextButton") then
						local s = sibling:FindFirstChildOfClass("UIStroke")
						if s then
							s.Thickness = (sibling == cell) and 2.5 or 1.5
						end
					end
				end
			end)
		end
		showDetail(bag.Items[selectedIndex])
	end

	local api = {}

	function api.BuildFromInventory(inventory, bags)
		currentPacked = buildPacked(inventory, bags)
		return currentPacked
	end

	function api.GetPacked()
		return currentPacked
	end

	function api.Open(index)
		openedIndex = index
		selectedIndex = 1
		frame.Visible = true
		refresh(index)
	end

	function api.Close()
		frame.Visible = false
		openedIndex = nil
		clearDetail()
	end

	function api.GetOpenedIndex()
		return openedIndex
	end

	function api.RefreshOpened()
		if openedIndex then
			refresh(openedIndex)
		end
	end

	function api.SetCurrency(g, s, c)
		currencyLabel.Text = string.format("💰 %d 🥇 | %d 🥈 | %d 🥉", g, s, c)
	end

	closeBtn.MouseButton1Click:Connect(function()
		api.Close()
	end)

	return api
end

return BagContentUI
