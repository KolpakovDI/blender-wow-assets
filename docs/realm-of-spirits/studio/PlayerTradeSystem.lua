-- PlayerTradeSystem - 1-slot P2P trade (Safe zone MVP)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RealmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local ItemCatalog = require(RealmFolder:WaitForChild("ItemCatalog"))

local PlayerTradeSystem = {}

local MAX_DISTANCE = 16
local tradeEvent = RealmFolder:FindFirstChild("PlayerTrade")
if not tradeEvent then
	tradeEvent = Instance.new("RemoteEvent")
	tradeEvent.Name = "PlayerTrade"
	tradeEvent.Parent = RealmFolder
end

-- sessions[userId] = {
--   PartnerId = number,
--   Offer = { ItemId = number?, Quantity = number? },
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
	for _, inv in ipairs(playerData.Inventory or {}) do
		if inv.Id == itemId then
			return inv
		end
	end
	return nil
end

local function takeItem(playerData, itemId, quantity)
	local inv = findInvEntry(playerData, itemId)
	if not inv or (inv.Quantity or 0) < quantity then
		return false
	end
	inv.Quantity = inv.Quantity - quantity
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
	local inv = findInvEntry(playerData, itemId)
	if inv then
		inv.Quantity = (inv.Quantity or 0) + quantity
		return
	end
	table.insert(playerData.Inventory, { Id = itemId, Quantity = quantity })
end

local function syncData(player, playerData)
	local dataEvent = RealmFolder:FindFirstChild("DataSync")
	if dataEvent then
		dataEvent:FireClient(player, "FullSync", playerData)
	end
end

local function cancelPair(playerA, playerB, reason)
	if playerA then
		clearSession(playerA.UserId)
		notify(playerA, "TradeCancelled", { Reason = reason or "cancelled" })
	end
	if playerB then
		clearSession(playerB.UserId)
		notify(playerB, "TradeCancelled", { Reason = reason or "cancelled" })
	end
end

local function tryComplete(playerA, playerB)
	local sa = sessions[playerA.UserId]
	local sb = sessions[playerB.UserId]
	if not bothReady(sa, sb) then
		return
	end
	if not isInSafeZone(playerA) or not isInSafeZone(playerB) or not withinRange(playerA, playerB) then
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
	local idA, qtyA = offerA.ItemId, offerA.Quantity or 0
	local idB, qtyB = offerB.ItemId, offerB.Quantity or 0

	-- Allow empty slot (gift) but require at least one side offering
	if (not idA or qtyA <= 0) and (not idB or qtyB <= 0) then
		notify(playerA, "Toast", { Text = "Нужно положить предмет" })
		notify(playerB, "Toast", { Text = "Нужно положить предмет" })
		sa.Ready = false
		sb.Ready = false
		notify(playerA, "TradeState", { Offer = sa.Offer, Ready = false, PartnerOffer = sb.Offer, PartnerReady = false })
		notify(playerB, "TradeState", { Offer = sb.Offer, Ready = false, PartnerOffer = sa.Offer, PartnerReady = false })
		return
	end

	if idA and qtyA > 0 then
		if not takeItem(dataA, idA, qtyA) then
			cancelPair(playerA, playerB, "missing_item")
			return
		end
	end
	if idB and qtyB > 0 then
		if not takeItem(dataB, idB, qtyB) then
			-- rollback A
			if idA and qtyA > 0 then
				giveItem(dataA, idA, qtyA)
			end
			cancelPair(playerA, playerB, "missing_item")
			return
		end
	end

	if idA and qtyA > 0 then
		giveItem(dataB, idA, qtyA)
	end
	if idB and qtyB > 0 then
		giveItem(dataA, idB, qtyB)
	end

	clearSession(playerA.UserId)
	clearSession(playerB.UserId)
	syncData(playerA, dataA)
	syncData(playerB, dataB)
	notify(playerA, "TradeComplete", { Received = offerB, Gave = offerA })
	notify(playerB, "TradeComplete", { Received = offerA, Gave = offerB })
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
				-- MVP: 1 slot
				session.Offer = { ItemId = itemId, Quantity = 1 }
			else
				session.Offer = {}
			end
			session.Ready = false
			sessions[partner.UserId].Ready = false
			pushState(player, partner)
			pushState(partner, player)
		elseif action == "Ready" then
			local session = sessions[player.UserId]
			if not session then
				return
			end
			local partner = Players:GetPlayerByUserId(session.PartnerId)
			if not partner then
				clearSession(player.UserId)
				return
			end
			session.Ready = payload.Ready == true
			pushState(player, partner)
			pushState(partner, player)
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

	print("Realm of Spirits - PlayerTradeSystem loaded!")
end

return PlayerTradeSystem
