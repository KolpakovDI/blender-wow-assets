-- TradeSystem - shop buy/sell, daily caps, gold sinks, exp scroll
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RealmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local SpiritDatabase = require(RealmFolder:WaitForChild("SpiritDatabase"))
local ItemCatalog = require(RealmFolder:WaitForChild("ItemCatalog"))

local TradeSystem = {}
TradeSystem.__index = TradeSystem

local function getTotalCopper(playerData)
	local c = tonumber(playerData.CopperCoins) or 0
	local s = tonumber(playerData.SilverCoins) or 0
	local g = tonumber(playerData.GoldCoins) or 0
	return c + s * 100 + g * 10000
end

local function setFromTotalCopper(playerData, totalCopper)
	totalCopper = math.max(0, math.floor(totalCopper or 0))
	playerData.GoldCoins = math.floor(totalCopper / 10000)
	totalCopper = totalCopper % 10000
	playerData.SilverCoins = math.floor(totalCopper / 100)
	playerData.CopperCoins = totalCopper % 100
end

local function normalizeCurrency(playerData)
	setFromTotalCopper(playerData, getTotalCopper(playerData))
end

local function todayKey()
	return os.date("%Y-%m-%d")
end

local function ensureShopDaily(playerData)
	local d = todayKey()
	if type(playerData.ShopDaily) ~= "table" or playerData.ShopDaily.Date ~= d then
		playerData.ShopDaily = { Date = d, Counts = {} }
	end
	if type(playerData.ShopDaily.Counts) ~= "table" then
		playerData.ShopDaily.Counts = {}
	end
end

local function addInventory(playerData, itemId, quantity)
	for _, inv in ipairs(playerData.Inventory or {}) do
		if inv.Id == itemId then
			inv.Quantity = (inv.Quantity or 0) + quantity
			return
		end
	end
	playerData.Inventory = playerData.Inventory or {}
	table.insert(playerData.Inventory, { Id = itemId, Quantity = quantity })
end

local function applyGrant(playerData, shopItem, quantity)
	local grant = shopItem.Grant
	if grant == "ShowcaseSlot" then
		playerData.ShowcaseSlots = (tonumber(playerData.ShowcaseSlots) or 0) + quantity
		return true, "Слоты витрины: " .. tostring(playerData.ShowcaseSlots)
	elseif grant == "RenameToken" then
		addInventory(playerData, shopItem.Id, quantity)
		return true, "Жетон имени x" .. quantity
	elseif shopItem.CosmeticGrant then
		playerData.Cosmetics = playerData.Cosmetics or {}
		for _ = 1, quantity do
			local cid = tostring(shopItem.CosmeticGrant) .. "_" .. tostring(os.time()) .. "_" .. tostring(math.random(100, 999))
			table.insert(playerData.Cosmetics, {
				Id = cid,
				Name = shopItem.Name,
				Rarity = "Rare",
				ObtainedAt = os.time(),
				Source = "GoldShop",
			})
		end
		return true, "Косметика: " .. shopItem.Name
	end
	addInventory(playerData, shopItem.Id, quantity)
	return true, "Куплено: " .. shopItem.Name .. " x" .. quantity
end

function TradeSystem.new()
	return setmetatable({}, TradeSystem)
end

function TradeSystem:GetShopItems()
	local items = {}
	for id, item in pairs(SpiritDatabase.ShopItems) do
		table.insert(items, item)
	end
	table.sort(items, function(a, b) return a.Id < b.Id end)
	return items
end

function TradeSystem:BuyItem(playerData, itemId, quantity)
	quantity = math.max(1, math.min(99, math.floor(tonumber(quantity) or 1)))
	local shopItem = SpiritDatabase.ShopItems[itemId] or ItemCatalog.Get(itemId)
	if not shopItem or not SpiritDatabase.ShopItems[itemId] then
		return false, "Товар не найден"
	end

	ensureShopDaily(playerData)
	local dailyCap = tonumber(shopItem.DailyBuyCap)
	if dailyCap and dailyCap > 0 then
		local bought = tonumber(playerData.ShopDaily.Counts[itemId]) or 0
		if bought + quantity > dailyCap then
			return false, string.format("Лимит покупки %d/день (уже %d)", dailyCap, bought)
		end
	end

	local goldPrice = tonumber(shopItem.GoldPrice) or 0
	if goldPrice > 0 then
		local totalCostGold = goldPrice * quantity
		local totalCopper = getTotalCopper(playerData)
		local need = totalCostGold * 10000
		if totalCopper < need then
			return false, "Недостаточно золота"
		end
		setFromTotalCopper(playerData, totalCopper - need)
	else
		local unitPrice = tonumber(shopItem.Price) or 0
		local totalCost = unitPrice * quantity
		local totalCopper = getTotalCopper(playerData)
		if totalCopper < totalCost then
			return false, "Недостаточно монет"
		end
		setFromTotalCopper(playerData, totalCopper - totalCost)
	end

	if dailyCap and dailyCap > 0 then
		playerData.ShopDaily.Counts[itemId] = (tonumber(playerData.ShopDaily.Counts[itemId]) or 0) + quantity
	end

	local ok, message = applyGrant(playerData, shopItem, quantity)
	normalizeCurrency(playerData)
	return ok, message
end

function TradeSystem:SellItem(playerData, itemId, quantity)
	quantity = math.max(1, math.min(99, math.floor(tonumber(quantity) or 1)))
	local def = ItemCatalog.Get(itemId)
	if not def or not ItemCatalog.CanSell(itemId) then
		return false, "Предмет нельзя продать"
	end
	local sellPrice = tonumber(def.SellPrice) or 0
	for i, inv in ipairs(playerData.Inventory or {}) do
		if inv.Id == itemId then
			if (inv.Quantity or 0) < quantity then
				return false, "Недостаточно предметов"
			end
			inv.Quantity = inv.Quantity - quantity
			if inv.Quantity <= 0 then
				table.remove(playerData.Inventory, i)
			end
			setFromTotalCopper(playerData, getTotalCopper(playerData) + sellPrice * quantity)
			normalizeCurrency(playerData)
			return true, "Продано: " .. (def.Name or "?") .. " x" .. quantity
		end
	end
	return false, "Предмет не найден в инвентаре"
end

function TradeSystem:UseExpScroll(playerData, itemId)
	if itemId ~= 3 then
		return false, "Этот предмет нельзя использовать"
	end
	local def = ItemCatalog.Get(3)
	local xp = (def and tonumber(def.ExpAmount)) or 120
	for i, inv in ipairs(playerData.Inventory or {}) do
		if inv.Id == itemId and (inv.Quantity or 0) > 0 then
			inv.Quantity = inv.Quantity - 1
			if inv.Quantity <= 0 then
				table.remove(playerData.Inventory, i)
			end
			playerData.Experience = (playerData.Experience or 0) + xp
			local LevelingSystem = require(script.Parent.LevelingSystem)
			LevelingSystem.new():CheckLevelUp(playerData)
			return true, string.format("+%d опыта!", xp)
		end
	end
	return false, "Свиток не найден"
end

function TradeSystem:CountItem(playerData, itemId)
	local total = 0
	for _, inv in ipairs(playerData.Inventory or {}) do
		if inv.Id == itemId then
			total += inv.Quantity or 0
		end
	end
	return total
end

--- Consume one inventory item. Returns ok, message, itemDef
function TradeSystem:ConsumeItem(playerData, itemId)
	local def = ItemCatalog.Get(itemId)
	if not def then
		return false, "Неизвестный предмет", nil
	end
	for i, inv in ipairs(playerData.Inventory or {}) do
		if inv.Id == itemId and (inv.Quantity or 0) > 0 then
			inv.Quantity -= 1
			if inv.Quantity <= 0 then
				table.remove(playerData.Inventory, i)
			end
			return true, def.Name, def
		end
	end
	return false, "Нет в инвентаре", def
end

return TradeSystem
