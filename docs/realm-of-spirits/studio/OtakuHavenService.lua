-- OtakuHavenService - Scene 3 interactions
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RealmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local BuffSystem = require(script.Parent.BuffSystem)
local havenEvent = RealmFolder:FindFirstChild("OtakuHaven")
if not havenEvent then
	havenEvent = Instance.new("RemoteEvent")
	havenEvent.Name = "OtakuHaven"
	havenEvent.Parent = RealmFolder
end
local GACHA_COST = 50
local ZoneConfig = require(RealmFolder:WaitForChild("ZoneConfig"))
local GACHA_ROBUX_PRODUCT_ID = tonumber(ZoneConfig.GachaRobuxProductId) or 0
local hooked = {}
-- FOMO: лимитированная коллекция гачи (2 часа от старта сервера)
local GACHA_FOMO_DURATION = 2 * 60 * 60
local gachaSeasonEnd = os.time() + GACHA_FOMO_DURATION

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
local function getPlayerData(player)
	if _G.GetPlayerData then return _G.GetPlayerData(player) end
	return nil
end
local function isInsidePart(part, worldPos)
	if not part or not worldPos then return false end
	local localPos = part.CFrame:PointToObjectSpace(worldPos)
	local half = part.Size * 0.5
	return math.abs(localPos.X) <= half.X
		and math.abs(localPos.Y) <= half.Y
		and math.abs(localPos.Z) <= half.Z
end

local function isInSafeZone(player)
	-- ZoneDetail важнее: Genkan/Exit/Safe всегда хаб
	local detail = player:GetAttribute("ZoneDetail")
	if detail == "Genkan" or detail == "Safe" or detail == "Exit" or detail == "Spawn" then
		return true
	end
	if player:GetAttribute("CurrentZone") == "Safe" then
		return true
	end
	-- Защита от перекрытия Combat↔Safe: проверяем объём SafeZone по позиции
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local haven = workspace:FindFirstChild("OtakuHaven")
	local safeZone = haven and haven:FindFirstChild("Zones") and haven.Zones:FindFirstChild("SafeZone")
	if hrp and safeZone and isInsidePart(safeZone, hrp.Position) then
		return true
	end
	return false
end
local function notify(player, action, payload)
	havenEvent:FireClient(player, action, payload or {})
end
local function normalizeInventory(inventory)
	local byId = {}
	if type(inventory) == "table" then
		for _, inv in pairs(inventory) do
			if type(inv) == "table" then
				local id = tonumber(inv.Id) or tonumber(inv.id)
				local qty = math.floor(tonumber(inv.Quantity) or tonumber(inv.quantity) or 0)
				if id and qty > 0 then
					byId[id] = (byId[id] or 0) + qty
				end
			end
		end
	end
	local out = {}
	local ids = {}
	for id in pairs(byId) do
		table.insert(ids, id)
	end
	table.sort(ids)
	for _, id in ipairs(ids) do
		table.insert(out, { Id = id, Quantity = byId[id] })
	end
	return out
end

local function cloneInventory(inventory)
	return normalizeInventory(inventory)
end

local function giveInventoryItem(playerData, itemId, quantity)
	itemId = tonumber(itemId) or itemId
	quantity = math.max(1, math.floor(tonumber(quantity) or 1))
	playerData.Inventory = normalizeInventory(playerData.Inventory)
	for _, inv in ipairs(playerData.Inventory) do
		if inv.Id == itemId then
			inv.Quantity = inv.Quantity + quantity
			return inv.Quantity
		end
	end
	table.insert(playerData.Inventory, { Id = itemId, Quantity = quantity })
	return quantity
end
local function getFomoSecondsLeft()
	return math.max(0, gachaSeasonEnd - os.time())
end

local function grantGachaReward(player, playerData)
	-- Fair-combat: gacha (coins + Robux) = cosmetics only (см. docs/FAIR-COMBAT.md)
	local roll = math.random(1, 100)
	playerData.Cosmetics = playerData.Cosmetics or {}
	local rarity, title, stickerPrefix
	if roll <= 60 then
		rarity, title, stickerPrefix = "Common", "Фигурка", "Fig_"
	elseif roll <= 90 then
		rarity, title, stickerPrefix = "Rare", "Редкая фигурка", "FigRare_"
	else
		rarity, title, stickerPrefix = "Legendary", "Мифическая фигурка", "FigMyth_"
	end
	local stickerId = stickerPrefix .. math.random(1000, 9999)
	table.insert(playerData.Cosmetics, {
		Id = stickerId,
		Rarity = rarity,
		Name = title,
		ObtainedAt = os.time(),
	})
	return {
		Type = "Cosmetic",
		Title = title,
		Rarity = rarity,
		CosmeticId = stickerId,
		Message = title .. " (" .. rarity .. ") — только косметика, без бонусов в бою",
	}
end

-- Flex cosmetics (Safe-only visual; no combat stats)
local function findCosmetic(playerData, cosmeticId)
	if not playerData or not cosmeticId or cosmeticId == "" then
		return nil
	end
	playerData.Cosmetics = playerData.Cosmetics or {}
	for _, c in ipairs(playerData.Cosmetics) do
		if type(c) == "table" and c.Id == cosmeticId then
			return c
		end
	end
	return nil
end

local function rarityColor(rarity)
	if rarity == "Legendary" then
		return Color3.fromRGB(255, 200, 80)
	elseif rarity == "Rare" then
		return Color3.fromRGB(100, 160, 255)
	end
	return Color3.fromRGB(180, 180, 180)
end

local function clearFlexVisual(player)
	local char = player and player.Character
	if not char then
		return
	end
	local existing = char:FindFirstChild("FlexBillboard", true)
	if existing then
		existing:Destroy()
	end
end

local function applyFlexVisual(player)
	clearFlexVisual(player)
	if not isInSafeZone(player) then
		return
	end
	local playerData = getPlayerData(player)
	if not playerData then
		return
	end
	local cosmeticId = playerData.EquippedCosmeticId
	if not cosmeticId or cosmeticId == "" then
		return
	end
	local cosmetic = findCosmetic(playerData, cosmeticId)
	if not cosmetic then
		return
	end
	local char = player.Character
	if not char then
		return
	end
	local attach = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
	if not attach then
		return
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "FlexBillboard"
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.new(0, 160, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.MaxDistance = 80
	billboard.Parent = attach
	local label = Instance.new("TextLabel")
	label.Name = "FlexLabel"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextStrokeTransparency = 0.5
	label.Text = tostring(cosmetic.Name or "Cosmetic") .. " (" .. tostring(cosmetic.Rarity or "Common") .. ")"
	label.TextColor3 = rarityColor(cosmetic.Rarity)
	label.Parent = billboard
end

local function wardrobePayload(playerData)
	playerData.Cosmetics = playerData.Cosmetics or {}
	return {
		Cosmetics = playerData.Cosmetics,
		EquippedCosmeticId = playerData.EquippedCosmeticId,
	}
end

local function onEquipCosmetic(player, payload)
	payload = type(payload) == "table" and payload or {}
	if not isInSafeZone(player) then
		notify(player, "Toast", { Text = "Гардероб только в Haven" })
		return
	end
	local playerData = getPlayerData(player)
	if not playerData then
		return
	end
	playerData.Cosmetics = playerData.Cosmetics or {}
	local cosmeticId = payload.CosmeticId
	if type(cosmeticId) ~= "string" then
		cosmeticId = tostring(cosmeticId or "")
	end
	if cosmeticId == "" then
		playerData.EquippedCosmeticId = nil
		applyFlexVisual(player)
		notify(player, "EquipResult", { Message = "Косметика снята", EquippedCosmeticId = nil, Ok = true })
		notify(player, "OpenWardrobe", wardrobePayload(playerData))
		local dataEvent = RealmFolder:FindFirstChild("DataSync")
		if dataEvent then
			dataEvent:FireClient(player, "FullSync", playerData)
		end
		return
	end
	local owned = findCosmetic(playerData, cosmeticId)
	if not owned then
		notify(player, "EquipResult", { Message = "Нет такой косметики", Ok = false })
		return
	end
	playerData.EquippedCosmeticId = cosmeticId
	applyFlexVisual(player)
	notify(player, "EquipResult", {
		Message = "Надето: " .. tostring(owned.Name or cosmeticId),
		EquippedCosmeticId = cosmeticId,
		Ok = true,
	})
	notify(player, "OpenWardrobe", wardrobePayload(playerData))
	local dataEvent = RealmFolder:FindFirstChild("DataSync")
	if dataEvent then
		dataEvent:FireClient(player, "FullSync", playerData)
	end
end

local function rollGacha(player, playerData)
	local totalCopper = getTotalCopper(playerData)
	if totalCopper < GACHA_COST then return false, "Нужно " .. GACHA_COST .. " меди" end
	setFromTotalCopper(playerData, totalCopper - GACHA_COST)
	return true, grantGachaReward(player, playerData)
end

local function deliverGachaResult(player, playerData, reward, paidWith)
	reward.FomoSecondsLeft = getFomoSecondsLeft()
	reward.PaidWith = paidWith or "Coins"
	local inv = normalizeInventory(playerData.Inventory)
	playerData.Inventory = inv
	-- Плоские массивы — надёжнее вложенных таблиц по RemoteEvent
	reward.InvIds = {}
	reward.InvQtys = {}
	for i, item in ipairs(inv) do
		reward.InvIds[i] = item.Id
		reward.InvQtys[i] = item.Quantity
	end
	reward.Inventory = inv
	notify(player, "GachaResult", reward)
	local dataEvent = RealmFolder:FindFirstChild("DataSync")
	if dataEvent then
		dataEvent:FireClient(player, "InventorySync", {
			InvIds = reward.InvIds,
			InvQtys = reward.InvQtys,
			ItemId = reward.ItemId,
			Quantity = reward.Quantity,
			Type = reward.Type,
			CopperCoins = playerData.CopperCoins,
			SilverCoins = playerData.SilverCoins,
			GoldCoins = playerData.GoldCoins,
		})
		dataEvent:FireClient(player, "FullSync", playerData)
	end
end

local function MarkHubPrep(player)
	local ok, HubFunnel = pcall(function()
		return require(RealmFolder:WaitForChild("HubFunnel"))
	end)
	if ok and HubFunnel and HubFunnel.MarkPlayer then
		HubFunnel.MarkPlayer(player, "Prep")
	end
end

local function onMangaPrompt(player)
	MarkHubPrep(player)
	if not isInSafeZone(player) then notify(player, "Toast", { Text = "Читать мангу можно только в Otaku Haven" }); return end
	local playerData = getPlayerData(player); if not playerData then return end
	if BuffSystem.HasBuff(playerData, "MangaDamage") then
		for _, b in ipairs(BuffSystem.GetActiveBuffs(playerData)) do
			if b.Id == "MangaDamage" then notify(player, "Toast", { Text = "Бафф активен: ещё " .. math.ceil(b.SecondsLeft / 60) .. " мин" }); return end
		end
	end
	local ok, msg = BuffSystem.ApplyBuff(playerData, "MangaDamage")
	if ok then notify(player, "BuffApplied", { Name = "Сила манги", Multiplier = 1.15, Duration = 1800, Message = "+15% урона на 30 минут!" })
	else notify(player, "Toast", { Text = msg }) end
end

local function onGachaPrompt(player)
	MarkHubPrep(player)
	if not isInSafeZone(player) then notify(player, "Toast", { Text = "Гашапон только в Otaku Haven" }); return end
	local playerData = getPlayerData(player)
	if not playerData then
		notify(player, "Toast", { Text = "Данные игрока ещё загружаются…" })
		return
	end
	if getFomoSecondsLeft() <= 0 then
		-- Сезон по таймеру закончился — крутим дальше, но без FOMO-метки
		gachaSeasonEnd = os.time() + GACHA_FOMO_DURATION
	end
	local ok, result = rollGacha(player, playerData)
	if ok then
		deliverGachaResult(player, playerData, result, "Coins")
	else
		notify(player, "Toast", { Text = result })
	end
end

local function onGachaRobuxPrompt(player)
	if not isInSafeZone(player) then notify(player, "Toast", { Text = "Гашапон только в Otaku Haven" }); return end
	if getFomoSecondsLeft() <= 0 then
		gachaSeasonEnd = os.time() + GACHA_FOMO_DURATION
	end
	if GACHA_ROBUX_PRODUCT_ID <= 0 then
		notify(player, "Toast", { Text = "Robux-гача: задайте ZoneConfig.GachaRobuxProductId" })
		return
	end
	MarketplaceService:PromptProductPurchase(player, GACHA_ROBUX_PRODUCT_ID)
end

MarketplaceService.ProcessReceipt = function(receiptInfo)
	if GACHA_ROBUX_PRODUCT_ID <= 0 or receiptInfo.ProductId ~= GACHA_ROBUX_PRODUCT_ID then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local player = game:GetService("Players"):GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local playerData = getPlayerData(player)
	if not playerData then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	playerData.ProcessedReceipts = playerData.ProcessedReceipts or {}
	local purchaseId = tostring(receiptInfo.PurchaseId or "")
	if purchaseId ~= "" and playerData.ProcessedReceipts[purchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	-- Never PurchaseGranted without a reward (Robux loss). Renew FOMO window like coin gacha.
	if getFomoSecondsLeft() <= 0 then
		gachaSeasonEnd = os.time() + GACHA_FOMO_DURATION
	end
	local reward = grantGachaReward(player, playerData)
	if not reward then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if purchaseId ~= "" then
		playerData.ProcessedReceipts[purchaseId] = true
	end
	deliverGachaResult(player, playerData, reward, "Robux")
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

local function onFittingPrompt(player)
	if not isInSafeZone(player) then
		notify(player, "Toast", { Text = "Гардероб только в Haven" })
		return
	end
	local playerData = getPlayerData(player)
	if not playerData then return end
	playerData.Cosmetics = playerData.Cosmetics or {}
	notify(player, "OpenWardrobe", {
		Cosmetics = playerData.Cosmetics,
		EquippedCosmeticId = playerData.EquippedCosmeticId,
	})
end
local function hookPrompt(part, handler)
	if not part or hooked[part] then return end
	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
		or part:FindFirstChildWhichIsA("ProximityPrompt", true)
	if not prompt then return end
	prompt.Enabled = true
	prompt.RequiresLineOfSight = false
	hooked[part] = prompt.Triggered:Connect(function(plr) handler(plr) end)
end
local function setupHaven(model)
	if not model then return end
	for _, name in ipairs({ "MangaBuffStand", "GachaMachine", "FittingRoom" }) do
		local part = model:FindFirstChild(name, true)
		if part then
			local p = part:FindFirstChildOfClass("ProximityPrompt") or part:FindFirstChildWhichIsA("ProximityPrompt", true)
			if name == "MangaBuffStand" then
				if p then p.Enabled = true; p.ActionText = "Читать"; p.ObjectText = "Манга «Путь Меча»"; p.RequiresLineOfSight = false; p.MaxActivationDistance = 12 end
				hookPrompt(part, onMangaPrompt)
			elseif name == "GachaMachine" then
				if p then
					p.Enabled = true
					p.ActionText = "Крутить (" .. GACHA_COST .. " меди)"
					p.ObjectText = "Гашапон · только косметика"
					p.RequiresLineOfSight = false
					p.MaxActivationDistance = 12
					p.KeyboardKeyCode = Enum.KeyCode.E
				end
				hookPrompt(part, onGachaPrompt)
				local host = part:IsA("BasePart") and part or part:FindFirstChildWhichIsA("BasePart", true)
				if host then
					local robuxPrompt = host:FindFirstChild("GachaRobuxPrompt")
					if not robuxPrompt then
						robuxPrompt = Instance.new("ProximityPrompt")
						robuxPrompt.Name = "GachaRobuxPrompt"
						robuxPrompt.Parent = host
					end
					robuxPrompt.ActionText = "Крутить (Robux)"
					robuxPrompt.ObjectText = "Гашапон VIP · косметика"
					robuxPrompt.RequiresLineOfSight = false
					robuxPrompt.MaxActivationDistance = 12
					robuxPrompt.UIOffset = Vector2.new(0, 72)
					robuxPrompt.KeyboardKeyCode = Enum.KeyCode.R
					robuxPrompt.Enabled = true
					if not hooked[robuxPrompt] then
						hooked[robuxPrompt] = robuxPrompt.Triggered:Connect(function(plr)
							onGachaRobuxPrompt(plr)
						end)
					end
				end
			elseif name == "FittingRoom" then
				if p then p.Enabled = true; p.ActionText = "Гардероб"; p.ObjectText = "Примерочная · flex"; p.RequiresLineOfSight = false end
				hookPrompt(part, onFittingPrompt)
			end
		end
	end
end
task.spawn(function() setupHaven(workspace:WaitForChild("OtakuHaven", 60)) end)
workspace.ChildAdded:Connect(function(child) if child.Name == "OtakuHaven" then task.wait(0.3); setupHaven(child) end end)
havenEvent.OnServerEvent:Connect(function(player, action, payload)
	payload = type(payload) == "table" and payload or {}
	if action == "RequestBuffs" then
		local playerData = getPlayerData(player)
		if playerData then notify(player, "BuffList", { Buffs = BuffSystem.GetActiveBuffs(playerData) }) end
	elseif action == "RequestFomo" then
		notify(player, "GachaFomo", { SecondsLeft = getFomoSecondsLeft(), SeasonEnd = gachaSeasonEnd })
	elseif action == "RequestWardrobe" then
		MarkHubPrep(player)
		if not isInSafeZone(player) then
			notify(player, "Toast", { Text = "Гардероб только в Haven" })
			return
		end
		local playerData = getPlayerData(player)
		if not playerData then return end
		notify(player, "OpenWardrobe", wardrobePayload(playerData))
	elseif action == "EquipCosmetic" then
		onEquipCosmetic(player, payload)
	elseif action == "RequestSeason" then
		local playerData = getPlayerData(player)
		if not playerData then return end
		local ok, SeasonLiveOps = pcall(function()
			return require(script.Parent.SeasonLiveOps)
		end)
		if not ok or not SeasonLiveOps then
			notify(player, "Toast", { Text = "Сезон недоступен" })
			return
		end
		SeasonLiveOps.Ensure(playerData)
		notify(player, "SeasonState", SeasonLiveOps.GetClientSnapshot(playerData))
	elseif action == "BuySeasonOffer" then
		if not isInSafeZone(player) then
			notify(player, "Toast", { Text = "Сезонный магазин только в Haven" })
			return
		end
		local playerData = getPlayerData(player)
		if not playerData then return end
		local ok, SeasonLiveOps = pcall(function()
			return require(script.Parent.SeasonLiveOps)
		end)
		if not ok or not SeasonLiveOps then
			notify(player, "Toast", { Text = "Сезон недоступен" })
			return
		end
		local success, message = SeasonLiveOps.BuyEventShop(playerData, payload.OfferId)
		notify(player, "SeasonBuyResult", { Ok = success, Message = message, EventTokens = playerData.EventTokens })
		if success then
			local dataEvent = RealmFolder:FindFirstChild("DataSync")
			if dataEvent then
				dataEvent:FireClient(player, "FullSync", playerData)
			end
		end
	elseif action == "ClaimSeasonPass" then
		local playerData = getPlayerData(player)
		if not playerData then return end
		local ok, SeasonLiveOps = pcall(function()
			return require(script.Parent.SeasonLiveOps)
		end)
		if not ok or not SeasonLiveOps then
			notify(player, "Toast", { Text = "Сезон недоступен" })
			return
		end
		local success, message = SeasonLiveOps.ClaimPassLevel(playerData, tonumber(payload.LevelIndex))
		notify(player, "SeasonClaimResult", { Ok = success, Message = message, SeasonPass = playerData.SeasonPass })
		if success then
			local dataEvent = RealmFolder:FindFirstChild("DataSync")
			if dataEvent then
				dataEvent:FireClient(player, "FullSync", playerData)
			end
		end
	end
end)

local function hookPlayerFlex(player)
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		applyFlexVisual(player)
	end)
	if player.Character then
		task.defer(function()
			applyFlexVisual(player)
		end)
	end
	player:GetAttributeChangedSignal("CurrentZone"):Connect(function()
		applyFlexVisual(player)
	end)
	player:GetAttributeChangedSignal("ZoneDetail"):Connect(function()
		applyFlexVisual(player)
	end)
end

Players.PlayerAdded:Connect(hookPlayerFlex)
for _, plr in ipairs(Players:GetPlayers()) do
	hookPlayerFlex(plr)
end

task.spawn(function()
	while true do
		task.wait(2)
		for _, plr in ipairs(Players:GetPlayers()) do
			applyFlexVisual(plr)
		end
	end
end)

-- периодически пушим FOMO клиентам в Safe Zone
task.spawn(function()
	while true do
		task.wait(15)
		local left = getFomoSecondsLeft()
		for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
			if plr:GetAttribute("CurrentZone") == "Safe" then
				notify(plr, "GachaFomo", { SecondsLeft = left, SeasonEnd = gachaSeasonEnd })
			end
		end
	end
end)

print("Realm of Spirits - OtakuHavenService loaded!")

task.defer(function()
	local ok, err = pcall(function()
		require(script.Parent:WaitForChild("PlayerTradeSystem")).Start()
	end)
	if not ok then
		warn("[OtakuHaven] PlayerTradeSystem failed: ", err)
	end
end)

task.defer(function()
	local ok, err = pcall(function()
		require(script.Parent:WaitForChild("PvPDuelSystem")).Start()
	end)
	if not ok then
		warn("[OtakuHaven] PvPDuelSystem failed: ", err)
	end
end)
