-- OtakuHavenService - Scene 3 interactions
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RealmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local BuffSystem = require(script.Parent.BuffSystem)
local havenEvent = RealmFolder:FindFirstChild("OtakuHaven")
if not havenEvent then
	havenEvent = Instance.new("RemoteEvent")
	havenEvent.Name = "OtakuHaven"
	havenEvent.Parent = RealmFolder
end
local MarketplaceService = game:GetService("MarketplaceService")
local ZoneConfig = require(RealmFolder:WaitForChild("ZoneConfig"))
local GACHA_COST = 50
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
local function isInSafeZone(player)
	return player:GetAttribute("CurrentZone") == "Safe"
end
local function notify(player, action, payload)
	havenEvent:FireClient(player, action, payload or {})
end
local function giveInventoryItem(playerData, itemId, quantity)
	for _, inv in ipairs(playerData.Inventory) do
		if inv.Id == itemId then inv.Quantity = inv.Quantity + quantity; return end
	end
	table.insert(playerData.Inventory, { Id = itemId, Quantity = quantity })
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
local function rollGacha(playerData)
	local totalCopper = getTotalCopper(playerData)
	if totalCopper < GACHA_COST then return false, "Need " .. GACHA_COST .. " copper coins" end
	setFromTotalCopper(playerData, totalCopper - GACHA_COST)
	return true, grantGachaReward(nil, playerData)
end
local function onMangaPrompt(player)
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
local function getFomoSecondsLeft()
	return math.max(0, gachaSeasonEnd - os.time())
end

local function onGachaPrompt(player)
	if not isInSafeZone(player) then notify(player, "Toast", { Text = "Гашапон только в Otaku Haven" }); return end
	if getFomoSecondsLeft() <= 0 then
		notify(player, "Toast", { Text = "Лимитированная коллекция закончилась" })
		return
	end
	local playerData = getPlayerData(player); if not playerData then return end
	local ok, result = rollGacha(playerData)
	if ok then
		result.FomoSecondsLeft = getFomoSecondsLeft()
		notify(player, "GachaResult", result)
		local dataEvent = RealmFolder:FindFirstChild("DataSync")
		if dataEvent then dataEvent:FireClient(player, "FullSync", playerData) end
	else notify(player, "Toast", { Text = result }) end
end

local function deliverGachaResult(player, playerData, reward, paidWith)
	reward.FomoSecondsLeft = getFomoSecondsLeft()
	reward.PaidWith = paidWith or "Coins"
	notify(player, "GachaResult", reward)
	local dataEvent = RealmFolder:FindFirstChild("DataSync")
	if dataEvent then dataEvent:FireClient(player, "FullSync", playerData) end
end

local function onGachaRobuxPrompt(player)
	if not isInSafeZone(player) then notify(player, "Toast", { Text = "Гашапон только в Otaku Haven" }); return end
	if getFomoSecondsLeft() <= 0 then
		notify(player, "Toast", { Text = "Лимитированная коллекция закончилась" })
		return
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
	if getFomoSecondsLeft() <= 0 then
		notify(player, "Toast", { Text = "Сезон гачи закончился" })
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local reward = grantGachaReward(player, playerData)
	deliverGachaResult(player, playerData, reward, "Robux")
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

local function onFittingPrompt(player)
	if isInSafeZone(player) then notify(player, "OpenTrade", {}) end
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
				if p then p.Enabled = true; p.ActionText = "Крутить (" .. GACHA_COST .. " меди)"; p.ObjectText = "Гашапон · только косметика"; p.RequiresLineOfSight = false; p.KeyboardKeyCode = Enum.KeyCode.E end
				hookPrompt(part, onGachaPrompt)
				local robuxPrompt = part:FindFirstChild("GachaRobuxPrompt")
				if not robuxPrompt then
					robuxPrompt = Instance.new("ProximityPrompt")
					robuxPrompt.Name = "GachaRobuxPrompt"
					local host = part:IsA("BasePart") and part or (part.PrimaryPart or part:FindFirstChildWhichIsA("BasePart", true) or part)
					robuxPrompt.Parent = host
				end
				robuxPrompt.ActionText = "Крутить (Robux)"
				robuxPrompt.ObjectText = "Гашапон VIP · косметика"
				robuxPrompt.RequiresLineOfSight = false
				robuxPrompt.MaxActivationDistance = 12
				robuxPrompt.UIOffset = Vector2.new(0, 80)
				robuxPrompt.KeyboardKeyCode = Enum.KeyCode.R
				robuxPrompt.Enabled = true
				if not hooked[robuxPrompt] then
					hooked[robuxPrompt] = robuxPrompt.Triggered:Connect(function(plr) onGachaRobuxPrompt(plr) end)
				end
			elseif name == "FittingRoom" then
				if p then p.Enabled = true; p.ActionText = "Магазин / Трейд"; p.ObjectText = "Примерочная"; p.RequiresLineOfSight = false end
				hookPrompt(part, onFittingPrompt)
			end
		end
	end
end
task.spawn(function() setupHaven(workspace:WaitForChild("OtakuHaven", 60)) end)
workspace.ChildAdded:Connect(function(child) if child.Name == "OtakuHaven" then task.wait(0.3); setupHaven(child) end end)
havenEvent.OnServerEvent:Connect(function(player, action)
	if action == "RequestBuffs" then
		local playerData = getPlayerData(player)
		if playerData then notify(player, "BuffList", { Buffs = BuffSystem.GetActiveBuffs(playerData) }) end
	elseif action == "RequestFomo" then
		notify(player, "GachaFomo", { SecondsLeft = getFomoSecondsLeft(), SeasonEnd = gachaSeasonEnd })
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


task.defer(function()
	local ok, err = pcall(function()
		require(script.Parent:WaitForChild("PlayerTradeSystem")).Start()
	end)
	if not ok then
		warn("[OtakuHaven] PlayerTradeSystem failed: ", err)
	end
end)

print("Realm of Spirits - OtakuHavenService loaded!")
