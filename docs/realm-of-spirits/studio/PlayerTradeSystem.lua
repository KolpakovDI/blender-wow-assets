-- PlayerTradeSystem - 1-slot P2P trade (item OR cosmetic), Safe zone MVP
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RealmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local ItemCatalog = require(RealmFolder:WaitForChild("ItemCatalog"))

local PlayerTradeSystem = {}

local MAX_DISTANCE = 22
local tradeEvent = RealmFolder:FindFirstChild("PlayerTrade")
if not tradeEvent then
	tradeEvent = Instance.new("RemoteEvent")
	tradeEvent.Name = "PlayerTrade"
	tradeEvent.Parent = RealmFolder
end

-- sessions[userId] = {
--   PartnerId = number,
--   Offer = { ItemId?, Quantity?, CosmeticId?, Name?, Rarity? },
--   Ready = boolean,
-- }
local sessions = {}

local function getPlayerData(player)
	if _G.GetPlayerData then
		return _G.GetPlayerData(player)
	end
	return nil
end

local function isInSafeZone(player)
	local detail = player:GetAttribute("ZoneDetail")
	if detail == "Genkan" or detail == "Safe" or detail == "Exit" or detail == "Spawn" then
		return true
	end
	return player:GetAttribute("CurrentZone") == "Safe"
end

local function getHRP(player)
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function withinRange(a, b)
	local ha, hb = getHRP(a), getHRP(b)
	if not ha or not hb then
		return false
	end
	return (ha.Position - hb.Position).Magnitude <= MAX_DISTANCE
end

local function notify(player, action, payload)
	tradeEvent:FireClient(player, action, payload or {})
end

local function clearSession(userId)
	sessions[userId] = nil
end

local function bothReady(sessionA, sessionB)
	return sessionA and sessionB and sessionA.Ready and sessionB.Ready
end

local function findInvEntry(playerData, itemId)
	itemId = tonumber(itemId)
	if not itemId or not playerData then
		return nil
	end
	playerData.Inventory = playerData.Inventory or {}
	for _, inv in ipairs(playerData.Inventory) do
		if tonumber(inv.Id) == itemId then
			return inv
		end
	end
	return nil
end

local function takeItem(playerData, itemId, quantity)
	itemId = tonumber(itemId)
	quantity = math.max(0, math.floor(tonumber(quantity) or 0))
	local inv = findInvEntry(playerData, itemId)
	if not itemId or quantity <= 0 or not inv or (tonumber(inv.Quantity) or 0) < quantity then
		return false
	end
	inv.Id = itemId
	inv.Quantity = (tonumber(inv.Quantity) or 0) - quantity
	if inv.Quantity <= 0 then
		for i, entry in ipairs(playerData.Inventory) do
			if entry == inv then
				table.remove(playerData.Inventory, i)
				break
			end
		end
	end
	return true
end

local function giveItem(playerData, itemId, quantity)
	itemId = tonumber(itemId)
	quantity = math.max(0, math.floor(tonumber(quantity) or 0))
	if not itemId or quantity <= 0 or not playerData then
		return
	end
	-- Prefer GameManager helper when available (keeps inventory normalized)
	if _G.AddInventoryItem then
		-- AddInventoryItem needs a player; fall through to local mutate when only data is known
	end
	local inv = findInvEntry(playerData, itemId)
	if inv then
		inv.Id = itemId
		inv.Quantity = (tonumber(inv.Quantity) or 0) + quantity
		return
	end
	playerData.Inventory = playerData.Inventory or {}
	table.insert(playerData.Inventory, { Id = itemId, Quantity = quantity })
end

local function findCosmetic(playerData, cosmeticId)
	if not playerData or type(cosmeticId) ~= "string" or cosmeticId == "" then
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

local function takeCosmetic(playerData, cosmeticId)
	playerData.Cosmetics = playerData.Cosmetics or {}
	for i, c in ipairs(playerData.Cosmetics) do
		if type(c) == "table" and c.Id == cosmeticId then
			local removed = table.remove(playerData.Cosmetics, i)
			if playerData.EquippedCosmeticId == cosmeticId then
				playerData.EquippedCosmeticId = nil
			end
			return removed
		end
	end
	return nil
end

local function giveCosmetic(playerData, cosmetic)
	if type(cosmetic) ~= "table" or type(cosmetic.Id) ~= "string" or cosmetic.Id == "" then
		return
	end
	playerData.Cosmetics = playerData.Cosmetics or {}
	-- avoid duplicate Id
	if findCosmetic(playerData, cosmetic.Id) then
		return
	end
	table.insert(playerData.Cosmetics, {
		Id = cosmetic.Id,
		Name = cosmetic.Name,
		Rarity = cosmetic.Rarity,
		ObtainedAt = cosmetic.ObtainedAt or os.time(),
	})
end

local function offerHasContent(offer)
	offer = offer or {}
	if type(offer.CosmeticId) == "string" and offer.CosmeticId ~= "" then
		return true
	end
	local id = tonumber(offer.ItemId)
	local qty = tonumber(offer.Quantity) or 0
	return id ~= nil and qty > 0
end

local function syncData(player, playerData)
	local dataEvent = RealmFolder:FindFirstChild("DataSync")
	if dataEvent then
		dataEvent:FireClient(player, "FullSync", playerData)
	end
end

local function pushState(player, partner)
	local sa = sessions[player.UserId]
	local sb = sessions[partner.UserId]
	if not sa or not sb then
		return
	end
	notify(player, "TradeState", {
		Offer = sa.Offer,
		Ready = sa.Ready,
		PartnerId = partner.UserId,
		PartnerName = partner.DisplayName or partner.Name,
		PartnerOffer = sb.Offer,
		PartnerReady = sb.Ready,
	})
end

local CANCEL_REASON_TEXT = {
	out_of_range = "Обмен не удался: отойдите ближе (до 22 studs)",
	no_data = "Обмен не удался: нет данных игрока",
	missing_item = "Обмен не удался: предмета нет в инвентаре",
	missing_cosmetic = "Обмен не удался: косметика не найдена",
	not_safe = "Обмен не удался: только в Safe Zone",
	cancelled = "Обмен отменён",
	left = "Обмен отменён: игрок вышел",
}

local function cancelPair(playerA, playerB, reason)
	reason = reason or "cancelled"
	local text = CANCEL_REASON_TEXT[reason] or ("Обмен не удался: " .. tostring(reason))
	if playerA then
		clearSession(playerA.UserId)
		notify(playerA, "Toast", { Text = text })
		notify(playerA, "TradeCancelled", { Reason = reason, Text = text })
	end
	if playerB then
		clearSession(playerB.UserId)
		notify(playerB, "Toast", { Text = text })
		notify(playerB, "TradeCancelled", { Reason = reason, Text = text })
	end
end

local function formatOfferServer(offer)
	offer = offer or {}
	if type(offer.CosmeticId) == "string" and offer.CosmeticId ~= "" then
		return tostring(offer.Name or offer.CosmeticId)
	end
	local id = tonumber(offer.ItemId)
	if id and (tonumber(offer.Quantity) or 0) > 0 then
		local def = ItemCatalog.Get(id)
		local name = def and def.Name or ("#" .. tostring(id))
		return string.format("%s x%d", name, tonumber(offer.Quantity) or 1)
	end
	return "ничего"
end

local function tryComplete(playerA, playerB)
	local sa = sessions[playerA.UserId]
	local sb = sessions[playerB.UserId]
	if not bothReady(sa, sb) then
		return
	end
	if not isInSafeZone(playerA) or not isInSafeZone(playerB) then
		cancelPair(playerA, playerB, "not_safe")
		return
	end
	if not withinRange(playerA, playerB) then
		cancelPair(playerA, playerB, "out_of_range")
		return
	end

	local dataA = getPlayerData(playerA)
	local dataB = getPlayerData(playerB)
	if not dataA or not dataB then
		cancelPair(playerA, playerB, "no_data")
		return
	end

	local offerA = sa.Offer or {}
	local offerB = sb.Offer or {}

	if not offerHasContent(offerA) or not offerHasContent(offerB) then
		local msg = "Оба должны положить предмет или косметику"
		notify(playerA, "Toast", { Text = msg })
		notify(playerB, "Toast", { Text = msg })
		sa.Ready = false
		sb.Ready = false
		pushState(playerA, playerB)
		pushState(playerB, playerA)
		return
	end

	local idA = tonumber(offerA.ItemId)
	local qtyA = math.max(0, math.floor(tonumber(offerA.Quantity) or 0))
	local idB = tonumber(offerB.ItemId)
	local qtyB = math.max(0, math.floor(tonumber(offerB.Quantity) or 0))
	local cosA = (type(offerA.CosmeticId) == "string" and offerA.CosmeticId ~= "") and offerA.CosmeticId or nil
	local cosB = (type(offerB.CosmeticId) == "string" and offerB.CosmeticId ~= "") and offerB.CosmeticId or nil

	local takenCosA, takenCosB

	if cosA then
		takenCosA = takeCosmetic(dataA, cosA)
		if not takenCosA then
			cancelPair(playerA, playerB, "missing_cosmetic")
			return
		end
	elseif idA and qtyA > 0 then
		if not takeItem(dataA, idA, qtyA) then
			cancelPair(playerA, playerB, "missing_item")
			return
		end
	end

	if cosB then
		takenCosB = takeCosmetic(dataB, cosB)
		if not takenCosB then
			if takenCosA then
				giveCosmetic(dataA, takenCosA)
			elseif idA and qtyA > 0 then
				giveItem(dataA, idA, qtyA)
			end
			cancelPair(playerA, playerB, "missing_cosmetic")
			return
		end
	elseif idB and qtyB > 0 then
		if not takeItem(dataB, idB, qtyB) then
			if takenCosA then
				giveCosmetic(dataA, takenCosA)
			elseif idA and qtyA > 0 then
				giveItem(dataA, idA, qtyA)
			end
			cancelPair(playerA, playerB, "missing_item")
			return
		end
	end

	if takenCosA then
		giveCosmetic(dataB, takenCosA)
	elseif idA and qtyA > 0 then
		if _G.AddInventoryItem then
			_G.AddInventoryItem(playerB, idA, qtyA)
		else
			giveItem(dataB, idA, qtyA)
		end
	end
	if takenCosB then
		giveCosmetic(dataA, takenCosB)
	elseif idB and qtyB > 0 then
		if _G.AddInventoryItem then
			_G.AddInventoryItem(playerA, idB, qtyB)
		else
			giveItem(dataA, idB, qtyB)
		end
	end

	-- Re-read data after AddInventoryItem (same table usually)
	dataA = getPlayerData(playerA) or dataA
	dataB = getPlayerData(playerB) or dataB

	clearSession(playerA.UserId)
	clearSession(playerB.UserId)
	syncData(playerA, dataA)
	syncData(playerB, dataB)

	local gaveA, gotA = formatOfferServer(offerA), formatOfferServer(offerB)
	local gaveB, gotB = formatOfferServer(offerB), formatOfferServer(offerA)
	local textA = string.format("✓ Обмен успешен! Отдали: %s · Получили: %s", gaveA, gotA)
	local textB = string.format("✓ Обмен успешен! Отдали: %s · Получили: %s", gaveB, gotB)
	notify(playerA, "TradeComplete", { Received = offerB, Gave = offerA, Text = textA })
	notify(playerB, "TradeComplete", { Received = offerA, Gave = offerB, Text = textB })
	notify(playerA, "Toast", { Text = textA })
	notify(playerB, "Toast", { Text = textB })
	print("[PlayerTrade] complete", playerA.Name, "<->", playerB.Name, gaveA, "<->", gotA)
end

function PlayerTradeSystem.Start()
	tradeEvent.OnServerEvent:Connect(function(player, action, payload)
		payload = payload or {}
		if action == "Request" then
			local targetId = tonumber(payload.TargetUserId)
			local target = targetId and Players:GetPlayerByUserId(targetId)
			if not target or target == player then
				notify(player, "Toast", { Text = "Игрок не найден" })
				return
			end
			if not isInSafeZone(player) or not isInSafeZone(target) then
				notify(player, "Toast", { Text = "Обмен только в Safe" })
				return
			end
			if not withinRange(player, target) then
				notify(player, "Toast", { Text = "Подойдите ближе" })
				return
			end
			if sessions[player.UserId] or sessions[target.UserId] then
				notify(player, "Toast", { Text = "Уже в обмене" })
				return
			end
			sessions[player.UserId] = {
				PartnerId = target.UserId,
				Offer = {},
				Ready = false,
			}
			sessions[target.UserId] = {
				PartnerId = player.UserId,
				Offer = {},
				Ready = false,
			}
			notify(target, "TradeIncoming", {
				FromUserId = player.UserId,
				FromName = player.DisplayName or player.Name,
			})
			notify(player, "TradeOpened", {
				PartnerId = target.UserId,
				PartnerName = target.DisplayName or target.Name,
			})
			pushState(player, target)
			pushState(target, player)
		elseif action == "SetOffer" then
			local session = sessions[player.UserId]
			if not session then
				return
			end
			local partner = Players:GetPlayerByUserId(session.PartnerId)
			if not partner then
				clearSession(player.UserId)
				return
			end

			local cosmeticId = payload.CosmeticId
			if type(cosmeticId) ~= "string" then
				cosmeticId = tostring(cosmeticId or "")
			end

			if cosmeticId ~= "" then
				local data = getPlayerData(player)
				local owned = data and findCosmetic(data, cosmeticId)
				if not owned then
					notify(player, "Toast", { Text = "Нет такой косметики" })
					return
				end
				session.Offer = {
					CosmeticId = cosmeticId,
					Quantity = 0,
					Name = owned.Name,
					Rarity = owned.Rarity,
				}
			else
				local itemId = tonumber(payload.ItemId)
				local quantity = math.max(0, math.floor(tonumber(payload.Quantity) or 0))
				if itemId and quantity > 0 then
					local def = ItemCatalog.Get(itemId)
					if not def then
						notify(player, "Toast", { Text = "Неизвестный предмет" })
						return
					end
					local data = getPlayerData(player)
					local inv = data and findInvEntry(data, itemId)
					if not inv or (inv.Quantity or 0) < quantity then
						notify(player, "Toast", { Text = "Недостаточно предметов" })
						return
					end
					-- MVP: 1 slot; clear CosmeticId
					session.Offer = { ItemId = itemId, Quantity = 1 }
				else
					session.Offer = {}
				end
			end
			session.Ready = false
			sessions[partner.UserId].Ready = false
			pushState(player, partner)
			pushState(partner, player)
		elseif action == "Ready" then
			local session = sessions[player.UserId]
			if not session then
				notify(player, "Toast", { Text = "Нет активного обмена" })
				return
			end
			local partner = Players:GetPlayerByUserId(session.PartnerId)
			if not partner then
				clearSession(player.UserId)
				notify(player, "Toast", { Text = "Партнёр вышел" })
				return
			end
			session.Ready = payload.Ready == true
			pushState(player, partner)
			pushState(partner, player)
			if session.Ready and not (sessions[partner.UserId] and sessions[partner.UserId].Ready) then
				notify(player, "Toast", { Text = "Готов! Ждём партнёра…" })
			end
			tryComplete(player, partner)
		elseif action == "Cancel" then
			local session = sessions[player.UserId]
			local partner = session and Players:GetPlayerByUserId(session.PartnerId)
			cancelPair(player, partner, "cancelled")
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		local session = sessions[player.UserId]
		if not session then
			return
		end
		local partner = Players:GetPlayerByUserId(session.PartnerId)
		cancelPair(player, partner, "left")
	end)

	-- Studio-only: /tradetest выдаёт ловушку + тестовую косметику для 2p QA
	local RunService = game:GetService("RunService")
	if RunService:IsStudio() then
		local function grantTradeTestKit(player)
			local data = getPlayerData(player)
			if not data then
				notify(player, "Toast", { Text = "/tradetest: нет PlayerData" })
				return
			end
			giveItem(data, 1, 1) -- Ловушка
			giveItem(data, 2, 1) -- Зелье
			data.Cosmetics = data.Cosmetics or {}
			local cid = "TradeTest_" .. player.UserId .. "_" .. tostring(os.time() % 100000)
			table.insert(data.Cosmetics, {
				Id = cid,
				Name = "Тест-фигурка",
				Rarity = "Rare",
				ObtainedAt = os.time(),
			})
			syncData(player, data)
			notify(player, "Toast", { Text = "QA kit: ловушка + зелье + косметика" })
		end
		local function hookChat(player)
			player.Chatted:Connect(function(msg)
				if string.lower(string.gsub(msg or "", "%s+", "")) == "/tradetest" then
					grantTradeTestKit(player)
				end
			end)
		end
		Players.PlayerAdded:Connect(hookChat)
		for _, plr in ipairs(Players:GetPlayers()) do
			hookChat(plr)
		end
		print("Realm of Spirits - PlayerTradeSystem Studio /tradetest enabled")
	end

	print("Realm of Spirits - PlayerTradeSystem loaded (item/cosmetic 1-slot)!")
end

return PlayerTradeSystem
