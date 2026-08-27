-- GuildSystem (F4 W13): inventory↔bank transfer prep (in-memory, gate OFF)
-- Restore + Leave do NOT require AllowGuilds (in-memory session only)
-- CreateOrJoin remains fail-closed behind ExpansionGate.AllowGuilds
-- Live bank writes + Declare/Join + inventory transfers fail-closed (Locked) until AllowGuilds
-- Smoke mutates synthetic inventory↔bank without unlocking live remotes
-- Start() from OtakuHavenService / GameManager after DataStore ready
-- Mirror: re-export from Studio SoT after Ctrl+S if this file drifts.
-- Runtime SoT = ServerScriptService.RealmOfSpirits.GuildSystem in place .rbxl
-- W13 APIs: TransferItemToBank/FromBank, TransferCopperToBank/FromBank, SmokeInventoryBankTransferMock
-- Client companion: StarterPlayerScripts.GuildPanelUI (G / /guildpanel, fail-closed)
-- Phase: F4-W13-guild-inv-bank · AllowGuilds=false · CreateOrJoin gated

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GuildSystem = {}
GuildSystem._started = false

-- Design constants (MVP; live DS deferred under dev-only)
GuildSystem.MaxNameLen = 24
GuildSystem.MaxTagLen = 4
GuildSystem.MaxMembersPerGuild = 20
GuildSystem.GuildStoreNameFuture = "RealmOfSpirits_Guilds_v1"
GuildSystem.PlayerGuildKey = "Guild" -- optional schema v1
GuildSystem.RosterSchemaVersion = 1
GuildSystem.MaxBankSlots = 20
GuildSystem.BankSchemaVersion = 1
GuildSystem.SmokeGuildId = "g_w6smoke"
GuildSystem.SmokeRestoreGuildId = "g_w7restore"
GuildSystem.SmokeLeaveGuildId = "g_w8leave"
GuildSystem.SmokeMergeGuildId = "g_w8merge"
GuildSystem.SmokeBankGuildId = "g_w9bank"
GuildSystem.SmokeDepositGuildId = "g_w10deposit"
GuildSystem.SmokeItemGuildId = "g_w11items"
GuildSystem.SmokeWarfareGuildId = "g_w12war"
GuildSystem.SmokeWarfareTargetGuildId = "g_w12target"
GuildSystem.SmokeTransferGuildId = "g_w13xfer"
GuildSystem.WarfareSchemaVersion = 1
GuildSystem.MaxWarfareParticipants = 20
GuildSystem.MaxBankCopperTxn = 1000000
GuildSystem.MaxBankCopperBalance = 100000000
GuildSystem.MaxStackPerSlot = 99
GuildSystem.MaxItemQtyTxn = 999

local RealmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local remoteInst = RealmFolder:FindFirstChild("GuildEvent")
local remote
if remoteInst and remoteInst:IsA("RemoteEvent") then
	remote = remoteInst
else
	if remoteInst then
		remoteInst:Destroy()
	end
	local created = Instance.new("RemoteEvent")
	created.Name = "GuildEvent"
	created.Parent = RealmFolder
	remote = created
end

local membership = {}
local guildsById = {}

local function getData(player)
	local getter = rawget(_G, "GetPlayerData")
	if type(getter) == "function" then
		return getter(player)
	end
	return nil
end

local function gateAllowsGuilds()
	local okGate, ExpansionGate = pcall(function()
		return require(RealmFolder:WaitForChild("ExpansionGate", 5))
	end)
	if not okGate or not ExpansionGate or type(ExpansionGate.AssertGuildsAllowed) ~= "function" then
		return false
	end
	return ExpansionGate.AssertGuildsAllowed() == true
end

local function allowGuildsAttr()
	local okGate, ExpansionGate = pcall(function()
		return require(RealmFolder:WaitForChild("ExpansionGate", 5))
	end)
	if okGate and ExpansionGate then
		return ExpansionGate.AllowGuilds == true
	end
	return false
end

local function emptyBank()
	return {
		Copper = 0,
		Items = {},
		SchemaVersion = GuildSystem.BankSchemaVersion,
		MaxSlots = GuildSystem.MaxBankSlots,
		Locked = true, -- live deposit/withdraw deferred until AllowGuilds + guild DS
	}
end

local function emptyWarfare()
	return {
		State = "Idle", -- Idle | Declared (Active deferred)
		TargetGuildId = nil,
		DeclaredByUserId = nil,
		DeclaredAt = nil,
		Participants = {},
		SchemaVersion = GuildSystem.WarfareSchemaVersion,
		Locked = true, -- live declare/join deferred until AllowGuilds
	}
end

-- Occupied slots keyed by 1..MaxSlots: { ItemId, Qty }. Legacy dicts without Slot are compacted.
local function normalizeBankItems(rawItems)
	local slots = {}
	if type(rawItems) ~= "table" then
		return slots
	end
	local pending = {}
	for key, entry in pairs(rawItems) do
		if type(entry) == "table" then
			local itemId = tonumber(entry.ItemId or entry.Id)
			local qty = tonumber(entry.Qty or entry.Count or entry.Amount)
			local slot = tonumber(entry.Slot or key)
			if itemId and itemId == itemId and itemId >= 1 and qty and qty == qty and qty >= 1 then
				itemId = math.floor(itemId)
				qty = math.floor(qty)
				table.insert(pending, {
					Slot = if type(slot) == "number" and slot >= 1 then math.floor(slot) else nil,
					ItemId = itemId,
					Qty = math.min(qty, GuildSystem.MaxStackPerSlot),
				})
			end
		end
	end
	table.sort(pending, function(a, b)
		local sa = a.Slot or 9999
		local sb = b.Slot or 9999
		if sa ~= sb then
			return sa < sb
		end
		return a.ItemId < b.ItemId
	end)
	local used = {}
	local nextFree = 1
	local function allocSlot(preferred)
		if preferred and preferred >= 1 and preferred <= GuildSystem.MaxBankSlots and used[preferred] ~= true then
			used[preferred] = true
			return preferred
		end
		while nextFree <= GuildSystem.MaxBankSlots do
			if used[nextFree] ~= true then
				local s = nextFree
				used[s] = true
				nextFree += 1
				return s
			end
			nextFree += 1
		end
		return nil
	end
	for _, row in ipairs(pending) do
		local slot = allocSlot(row.Slot)
		if slot then
			slots[slot] = { ItemId = row.ItemId, Qty = row.Qty }
		end
	end
	return slots
end

local function snapshotBankSlots(bank)
	local list = {}
	if type(bank) ~= "table" or type(bank.Items) ~= "table" then
		return list
	end
	for slot, entry in pairs(bank.Items) do
		if type(entry) == "table" then
			table.insert(list, {
				Slot = tonumber(slot) or 0,
				ItemId = entry.ItemId,
				Qty = entry.Qty,
			})
		end
	end
	table.sort(list, function(a, b)
		return a.Slot < b.Slot
	end)
	return list
end

local function catalogHasItem(itemId)
	local okCat, ItemCatalog = pcall(function()
		return require(RealmFolder:WaitForChild("ItemCatalog", 2))
	end)
	if not okCat or not ItemCatalog or type(ItemCatalog.Get) ~= "function" then
		return true
	end
	return ItemCatalog.Get(itemId) ~= nil
end

local function ensureBank(record)
	if type(record.Bank) ~= "table" then
		record.Bank = emptyBank()
	end
	if type(record.Bank.Items) ~= "table" then
		record.Bank.Items = {}
	end
	record.Bank.Items = normalizeBankItems(record.Bank.Items)
	if type(record.Bank.Copper) ~= "number" then
		record.Bank.Copper = 0
	end
	if type(record.Bank.MaxSlots) ~= "number" then
		record.Bank.MaxSlots = GuildSystem.MaxBankSlots
	end
	if type(record.Bank.SchemaVersion) ~= "number" then
		record.Bank.SchemaVersion = GuildSystem.BankSchemaVersion
	end
	if record.Bank.Locked == nil then
		record.Bank.Locked = true
	end
	return record.Bank
end

local function ensureWarfare(record)
	if type(record.Warfare) ~= "table" then
		record.Warfare = emptyWarfare()
	end
	local w = record.Warfare
	if type(w.Participants) ~= "table" then
		w.Participants = {}
	end
	if type(w.SchemaVersion) ~= "number" then
		w.SchemaVersion = GuildSystem.WarfareSchemaVersion
	end
	if w.Locked == nil then
		w.Locked = true
	end
	local state = tostring(w.State or "Idle")
	if state ~= "Idle" and state ~= "Declared" then
		state = "Idle"
	end
	w.State = state
	return w
end

local function snapshotWarfareParticipants(warfare)
	local list = {}
	for _, entry in pairs(warfare.Participants) do
		if type(entry) == "table" and type(entry.UserId) == "number" then
			table.insert(list, {
				UserId = entry.UserId,
				JoinedAt = entry.JoinedAt,
			})
		end
	end
	table.sort(list, function(a, b)
		return a.UserId < b.UserId
	end)
	return list
end

local function countMembers(record)
	local n = 0
	for _ in pairs(record.Members) do
		n += 1
	end
	return n
end

local function rosterArray(record)
	local list = {}
	for _, entry in pairs(record.Members) do
		table.insert(list, entry)
	end
	table.sort(list, function(a, b)
		return a.UserId < b.UserId
	end)
	return list
end

local function normalizeRole(role)
	local r = tostring(role or "Member")
	if r == "Leader" or r == "Officer" or r == "Member" then
		return r
	end
	return "Member"
end

local function parseGuildTable(guildTable)
	if type(guildTable) ~= "table" then
		return nil, "NoGuild"
	end
	local id = tostring(guildTable.Id or "")
	local nameStr = tostring(guildTable.Name or ""):sub(1, GuildSystem.MaxNameLen)
	local tagStr = tostring(guildTable.Tag or ""):upper():gsub("[^A-Z0-9]", ""):sub(1, GuildSystem.MaxTagLen)
	if #id < 2 or #nameStr < 2 or #tagStr < 2 then
		return nil, "InvalidGuildShape"
	end
	local role = normalizeRole(guildTable.Role)
	return {
		Id = id,
		Name = nameStr,
		Tag = tagStr,
		Role = role,
	}, nil
end

function GuildSystem.GetMembership(player)
	return membership[player.UserId]
end

function GuildSystem.GetGuildRecord(guildId)
	return guildsById[guildId]
end

function GuildSystem.GetRoster(guildId)
	local record = guildsById[guildId]
	if not record then
		return nil
	end
	return rosterArray(record)
end

-- In-memory bank snapshot. Live deposit/withdraw fail-closed while Locked / !AllowGuilds.
function GuildSystem.GetBank(guildId)
	local record = guildsById[guildId]
	if not record then
		return nil
	end
	local bank = ensureBank(record)
	local slots = snapshotBankSlots(bank)
	local writeLocked = (bank.Locked == true) or (not gateAllowsGuilds())
	return {
		Copper = bank.Copper,
		ItemCount = #slots,
		SlotCount = #slots,
		Items = slots,
		MaxSlots = bank.MaxSlots,
		MaxStackPerSlot = GuildSystem.MaxStackPerSlot,
		SchemaVersion = bank.SchemaVersion,
		Locked = bank.Locked == true,
		WriteLocked = writeLocked,
		InMemoryOnly = true,
	}
end

-- In-memory warfare snapshot. Live declare/join fail-closed while Locked / !AllowGuilds.
function GuildSystem.GetWarfare(guildId)
	local record = guildsById[guildId]
	if not record then
		return nil
	end
	local warfare = ensureWarfare(record)
	local participants = snapshotWarfareParticipants(warfare)
	local writeLocked = (warfare.Locked == true) or (not gateAllowsGuilds())
	return {
		State = warfare.State,
		TargetGuildId = warfare.TargetGuildId,
		DeclaredByUserId = warfare.DeclaredByUserId,
		DeclaredAt = warfare.DeclaredAt,
		ParticipantCount = #participants,
		Participants = participants,
		MaxParticipants = GuildSystem.MaxWarfareParticipants,
		SchemaVersion = warfare.SchemaVersion,
		Locked = warfare.Locked == true,
		WriteLocked = writeLocked,
		InMemoryOnly = true,
	}
end

local function resolveUserId(player)
	if typeof(player) == "Instance" and player:IsA("Player") then
		return player.UserId, player
	end
	if type(player) == "table" then
		return tonumber(player.UserId), nil
	end
	return nil, nil
end

local function normalizeCopperAmount(amountRaw)
	local amount = tonumber(amountRaw)
	if type(amount) ~= "number" or amount ~= amount or amount <= 0 then
		return nil, "InvalidAmount"
	end
	amount = math.floor(amount)
	if amount < 1 or amount > GuildSystem.MaxBankCopperTxn then
		return nil, "InvalidAmount"
	end
	return amount, nil
end

-- In-memory copper delta (QA / smoke). Does NOT bypass live Deposit/Withdraw gates.
local function applyBankCopperDelta(guildId, delta)
	local record = guildsById[guildId]
	if not record then
		return false, "NoGuild"
	end
	local bank = ensureBank(record)
	local d = tonumber(delta)
	if type(d) ~= "number" or d ~= d or d == 0 then
		return false, "InvalidAmount"
	end
	d = math.floor(d)
	local nextCopper = bank.Copper + d
	if nextCopper < 0 then
		return false, "InsufficientFunds"
	end
	if nextCopper > GuildSystem.MaxBankCopperBalance then
		return false, "CapExceeded"
	end
	bank.Copper = nextCopper
	return true, GuildSystem.GetBank(guildId)
end

-- Live path: fail-closed until AllowGuilds AND bank.Locked=false.
function GuildSystem.DepositCopper(player, amountRaw)
	local userId, realPlayer = resolveUserId(player)
	if not userId then
		return false, "InvalidPlayer"
	end
	local amount, amountErr = normalizeCopperAmount(amountRaw)
	if not amount then
		return false, amountErr or "InvalidAmount"
	end
	local info = membership[userId]
	if not info then
		return false, "NoMembership"
	end
	if not gateAllowsGuilds() then
		return false, "Locked"
	end
	local record = guildsById[info.Id]
	if not record then
		return false, "NoGuild"
	end
	local bank = ensureBank(record)
	if bank.Locked then
		return false, "Locked"
	end
	local ok, res = applyBankCopperDelta(info.Id, amount)
	if not ok then
		return false, res
	end
	if realPlayer then
		pcall(function()
			remote:FireClient(realPlayer, "GuildBank", res)
		end)
	end
	return true, res
end

function GuildSystem.WithdrawCopper(player, amountRaw)
	local userId, realPlayer = resolveUserId(player)
	if not userId then
		return false, "InvalidPlayer"
	end
	local amount, amountErr = normalizeCopperAmount(amountRaw)
	if not amount then
		return false, amountErr or "InvalidAmount"
	end
	local info = membership[userId]
	if not info then
		return false, "NoMembership"
	end
	if not gateAllowsGuilds() then
		return false, "Locked"
	end
	local record = guildsById[info.Id]
	if not record then
		return false, "NoGuild"
	end
	local bank = ensureBank(record)
	if bank.Locked then
		return false, "Locked"
	end
	local ok, res = applyBankCopperDelta(info.Id, -amount)
	if not ok then
		return false, res
	end
	if realPlayer then
		pcall(function()
			remote:FireClient(realPlayer, "GuildBank", res)
		end)
	end
	return true, res
end

local function normalizeItemId(itemRaw)
	local itemId = tonumber(itemRaw)
	if type(itemId) ~= "number" or itemId ~= itemId or itemId < 1 then
		return nil, "InvalidItem"
	end
	itemId = math.floor(itemId)
	if itemId < 1 or itemId > 9999 then
		return nil, "InvalidItem"
	end
	if not catalogHasItem(itemId) then
		return nil, "InvalidItem"
	end
	return itemId, nil
end

local function normalizeItemQty(qtyRaw)
	local qty = tonumber(qtyRaw)
	if type(qty) ~= "number" or qty ~= qty or qty <= 0 then
		return nil, "InvalidAmount"
	end
	qty = math.floor(qty)
	if qty < 1 or qty > GuildSystem.MaxItemQtyTxn then
		return nil, "InvalidAmount"
	end
	return qty, nil
end

local function countOccupiedSlots(bank)
	local n = 0
	for _ in pairs(bank.Items) do
		n += 1
	end
	return n
end

-- In-memory item slot delta (QA / smoke). Does NOT bypass live DepositItem/WithdrawItem gates.
-- Positive qty = deposit into slots (stack then empty); negative = withdraw matching ItemId.
local function applyBankItemDelta(guildId, itemId, qtyDelta)
	local record = guildsById[guildId]
	if not record then
		return false, "NoGuild"
	end
	local bank = ensureBank(record)
	local id = tonumber(itemId)
	local d = tonumber(qtyDelta)
	if type(id) ~= "number" or id ~= id or id < 1 then
		return false, "InvalidItem"
	end
	if type(d) ~= "number" or d ~= d or d == 0 then
		return false, "InvalidAmount"
	end
	id = math.floor(id)
	d = math.floor(d)

	if d > 0 then
		local remaining = d
		-- Stack into existing slots first
		for slot = 1, bank.MaxSlots do
			local entry = bank.Items[slot]
			if entry and entry.ItemId == id and entry.Qty < GuildSystem.MaxStackPerSlot then
				local room = GuildSystem.MaxStackPerSlot - entry.Qty
				local add = math.min(room, remaining)
				entry.Qty += add
				remaining -= add
				if remaining <= 0 then
					break
				end
			end
		end
		while remaining > 0 do
			if countOccupiedSlots(bank) >= bank.MaxSlots then
				return false, "SlotsFull"
			end
			local emptySlot = nil
			for slot = 1, bank.MaxSlots do
				if bank.Items[slot] == nil then
					emptySlot = slot
					break
				end
			end
			if not emptySlot then
				return false, "SlotsFull"
			end
			local put = math.min(GuildSystem.MaxStackPerSlot, remaining)
			bank.Items[emptySlot] = { ItemId = id, Qty = put }
			remaining -= put
		end
		return true, GuildSystem.GetBank(guildId)
	end

	-- Withdraw
	local need = -d
	local available = 0
	for slot = 1, bank.MaxSlots do
		local entry = bank.Items[slot]
		if entry and entry.ItemId == id then
			available += entry.Qty
		end
	end
	if available < need then
		return false, "InsufficientItems"
	end
	local left = need
	for slot = 1, bank.MaxSlots do
		if left <= 0 then
			break
		end
		local entry = bank.Items[slot]
		if entry and entry.ItemId == id then
			local take = math.min(entry.Qty, left)
			entry.Qty -= take
			left -= take
			if entry.Qty <= 0 then
				bank.Items[slot] = nil
			end
		end
	end
	return true, GuildSystem.GetBank(guildId)
end

-- Live path: fail-closed until AllowGuilds AND bank.Locked=false. Does not touch player inventory (W11 prep).
function GuildSystem.DepositItem(player, itemRaw, qtyRaw)
	local userId, realPlayer = resolveUserId(player)
	if not userId then
		return false, "InvalidPlayer"
	end
	local itemId, itemErr = normalizeItemId(itemRaw)
	if not itemId then
		return false, itemErr or "InvalidItem"
	end
	local qty, qtyErr = normalizeItemQty(qtyRaw)
	if not qty then
		return false, qtyErr or "InvalidAmount"
	end
	local info = membership[userId]
	if not info then
		return false, "NoMembership"
	end
	if not gateAllowsGuilds() then
		return false, "Locked"
	end
	local record = guildsById[info.Id]
	if not record then
		return false, "NoGuild"
	end
	local bank = ensureBank(record)
	if bank.Locked then
		return false, "Locked"
	end
	local ok, res = applyBankItemDelta(info.Id, itemId, qty)
	if not ok then
		return false, res
	end
	if realPlayer then
		pcall(function()
			remote:FireClient(realPlayer, "GuildBank", res)
		end)
	end
	return true, res
end

function GuildSystem.WithdrawItem(player, itemRaw, qtyRaw)
	local userId, realPlayer = resolveUserId(player)
	if not userId then
		return false, "InvalidPlayer"
	end
	local itemId, itemErr = normalizeItemId(itemRaw)
	if not itemId then
		return false, itemErr or "InvalidItem"
	end
	local qty, qtyErr = normalizeItemQty(qtyRaw)
	if not qty then
		return false, qtyErr or "InvalidAmount"
	end
	local info = membership[userId]
	if not info then
		return false, "NoMembership"
	end
	if not gateAllowsGuilds() then
		return false, "Locked"
	end
	local record = guildsById[info.Id]
	if not record then
		return false, "NoGuild"
	end
	local bank = ensureBank(record)
	if bank.Locked then
		return false, "Locked"
	end
	local ok, res = applyBankItemDelta(info.Id, itemId, -qty)
	if not ok then
		return false, res
	end
	if realPlayer then
		pcall(function()
			remote:FireClient(realPlayer, "GuildBank", res)
		end)
	end
	return true, res
end

-- Player inventory shape (DataStoreManager / GameManager): list of { Id, Quantity }
-- Wallet copper for transfer prep: CopperCoins (total copper units).
local function ensureInventoryList(bag)
	if type(bag) ~= "table" then
		return nil
	end
	if type(bag.Inventory) ~= "table" then
		bag.Inventory = {}
	end
	return bag.Inventory
end

local function countPlayerInventoryQty(inventory, itemId)
	local id = tonumber(itemId)
	if type(inventory) ~= "table" or type(id) ~= "number" then
		return 0
	end
	id = math.floor(id)
	local total = 0
	for _, entry in ipairs(inventory) do
		if type(entry) == "table" and tonumber(entry.Id) == id then
			total += math.max(0, math.floor(tonumber(entry.Quantity) or 0))
		end
	end
	return total
end

-- Positive = add to bag; negative = remove. Mutates inventory list in place.
local function applyPlayerInventoryItemDelta(inventory, itemId, qtyDelta)
	local id = tonumber(itemId)
	local d = tonumber(qtyDelta)
	if type(inventory) ~= "table" then
		return false, "NoInventory"
	end
	if type(id) ~= "number" or id ~= id or id < 1 then
		return false, "InvalidItem"
	end
	if type(d) ~= "number" or d ~= d or d == 0 then
		return false, "InvalidAmount"
	end
	id = math.floor(id)
	d = math.floor(d)

	if d > 0 then
		for _, entry in ipairs(inventory) do
			if type(entry) == "table" and tonumber(entry.Id) == id then
				entry.Quantity = math.floor(tonumber(entry.Quantity) or 0) + d
				return true, nil
			end
		end
		table.insert(inventory, { Id = id, Quantity = d })
		return true, nil
	end

	local need = -d
	if countPlayerInventoryQty(inventory, id) < need then
		return false, "InsufficientItems"
	end
	local left = need
	local i = 1
	while i <= #inventory do
		local entry = inventory[i]
		if type(entry) == "table" and tonumber(entry.Id) == id then
			local have = math.max(0, math.floor(tonumber(entry.Quantity) or 0))
			local take = math.min(have, left)
			entry.Quantity = have - take
			left -= take
			if entry.Quantity <= 0 then
				table.remove(inventory, i)
			else
				i += 1
			end
			if left <= 0 then
				break
			end
		else
			i += 1
		end
	end
	return true, nil
end

local function getBagCopper(bag)
	if type(bag) ~= "table" then
		return 0
	end
	return math.max(0, math.floor(tonumber(bag.CopperCoins) or 0))
end

local function applyPlayerCopperDelta(bag, delta)
	if type(bag) ~= "table" then
		return false, "NoBag"
	end
	local d = tonumber(delta)
	if type(d) ~= "number" or d ~= d or d == 0 then
		return false, "InvalidAmount"
	end
	d = math.floor(d)
	local nextCopper = getBagCopper(bag) + d
	if nextCopper < 0 then
		return false, "InsufficientFunds"
	end
	bag.CopperCoins = nextCopper
	return true, nil
end

-- In-memory item transfer inventory→bank (QA / smoke). Does NOT bypass live Transfer gates.
local function applyTransferItemToBank(guildId, bag, itemId, qty)
	local inventory = ensureInventoryList(bag)
	if not inventory then
		return false, "NoInventory"
	end
	local id, itemErr = normalizeItemId(itemId)
	if not id then
		return false, itemErr or "InvalidItem"
	end
	local amount, qtyErr = normalizeItemQty(qty)
	if not amount then
		return false, qtyErr or "InvalidAmount"
	end
	if countPlayerInventoryQty(inventory, id) < amount then
		return false, "InsufficientItems"
	end
	local okInv, invErr = applyPlayerInventoryItemDelta(inventory, id, -amount)
	if not okInv then
		return false, invErr
	end
	local okBank, bankRes = applyBankItemDelta(guildId, id, amount)
	if not okBank then
		applyPlayerInventoryItemDelta(inventory, id, amount) -- rollback
		return false, bankRes
	end
	return true, {
		Bank = bankRes,
		InventoryQty = countPlayerInventoryQty(inventory, id),
		CopperCoins = getBagCopper(bag),
	}
end

local function applyTransferItemFromBank(guildId, bag, itemId, qty)
	local inventory = ensureInventoryList(bag)
	if not inventory then
		return false, "NoInventory"
	end
	local id, itemErr = normalizeItemId(itemId)
	if not id then
		return false, itemErr or "InvalidItem"
	end
	local amount, qtyErr = normalizeItemQty(qty)
	if not amount then
		return false, qtyErr or "InvalidAmount"
	end
	local okBank, bankRes = applyBankItemDelta(guildId, id, -amount)
	if not okBank then
		return false, bankRes
	end
	local okInv, invErr = applyPlayerInventoryItemDelta(inventory, id, amount)
	if not okInv then
		applyBankItemDelta(guildId, id, amount) -- rollback bank
		return false, invErr
	end
	return true, {
		Bank = bankRes,
		InventoryQty = countPlayerInventoryQty(inventory, id),
		CopperCoins = getBagCopper(bag),
	}
end

local function applyTransferCopperToBank(guildId, bag, amountRaw)
	local amount, amountErr = normalizeCopperAmount(amountRaw)
	if not amount then
		return false, amountErr or "InvalidAmount"
	end
	if getBagCopper(bag) < amount then
		return false, "InsufficientFunds"
	end
	local okBag, bagErr = applyPlayerCopperDelta(bag, -amount)
	if not okBag then
		return false, bagErr
	end
	local okBank, bankRes = applyBankCopperDelta(guildId, amount)
	if not okBank then
		applyPlayerCopperDelta(bag, amount) -- rollback
		return false, bankRes
	end
	return true, {
		Bank = bankRes,
		CopperCoins = getBagCopper(bag),
	}
end

local function applyTransferCopperFromBank(guildId, bag, amountRaw)
	local amount, amountErr = normalizeCopperAmount(amountRaw)
	if not amount then
		return false, amountErr or "InvalidAmount"
	end
	local okBank, bankRes = applyBankCopperDelta(guildId, -amount)
	if not okBank then
		return false, bankRes
	end
	local okBag, bagErr = applyPlayerCopperDelta(bag, amount)
	if not okBag then
		applyBankCopperDelta(guildId, amount) -- rollback
		return false, bagErr
	end
	return true, {
		Bank = bankRes,
		CopperCoins = getBagCopper(bag),
	}
end

local function resolvePlayerBag(player)
	local _, realPlayer = resolveUserId(player)
	if not realPlayer then
		return nil, "InvalidPlayer"
	end
	local data = getData(realPlayer)
	if type(data) ~= "table" then
		return nil, "NoPlayerData"
	end
	ensureInventoryList(data)
	if data.CopperCoins == nil then
		data.CopperCoins = 0
	end
	return data, nil
end

local function assertTransferUnlocked(player)
	local userId, realPlayer = resolveUserId(player)
	if not userId then
		return nil, nil, "InvalidPlayer"
	end
	local info = membership[userId]
	if not info then
		return nil, nil, "NoMembership"
	end
	if not gateAllowsGuilds() then
		return nil, nil, "Locked"
	end
	local record = guildsById[info.Id]
	if not record then
		return nil, nil, "NoGuild"
	end
	local bank = ensureBank(record)
	if bank.Locked then
		return nil, nil, "Locked"
	end
	return info, realPlayer, nil
end

-- Live path: fail-closed until AllowGuilds AND bank.Locked=false. Moves player Inventory ↔ bank.
function GuildSystem.TransferItemToBank(player, itemRaw, qtyRaw)
	local info, realPlayer, err = assertTransferUnlocked(player)
	if not info then
		return false, err
	end
	local bag, bagErr = resolvePlayerBag(realPlayer or player)
	if not bag then
		return false, bagErr or "NoPlayerData"
	end
	local ok, res = applyTransferItemToBank(info.Id, bag, itemRaw, qtyRaw)
	if not ok then
		return false, res
	end
	if realPlayer then
		pcall(function()
			remote:FireClient(realPlayer, "GuildBank", res.Bank)
			remote:FireClient(realPlayer, "InventoryTransfer", {
				Direction = "ToBank",
				Kind = "Item",
				InventoryQty = res.InventoryQty,
				CopperCoins = res.CopperCoins,
			})
		end)
	end
	return true, res
end

function GuildSystem.TransferItemFromBank(player, itemRaw, qtyRaw)
	local info, realPlayer, err = assertTransferUnlocked(player)
	if not info then
		return false, err
	end
	local bag, bagErr = resolvePlayerBag(realPlayer or player)
	if not bag then
		return false, bagErr or "NoPlayerData"
	end
	local ok, res = applyTransferItemFromBank(info.Id, bag, itemRaw, qtyRaw)
	if not ok then
		return false, res
	end
	if realPlayer then
		pcall(function()
			remote:FireClient(realPlayer, "GuildBank", res.Bank)
			remote:FireClient(realPlayer, "InventoryTransfer", {
				Direction = "FromBank",
				Kind = "Item",
				InventoryQty = res.InventoryQty,
				CopperCoins = res.CopperCoins,
			})
		end)
	end
	return true, res
end

function GuildSystem.TransferCopperToBank(player, amountRaw)
	local info, realPlayer, err = assertTransferUnlocked(player)
	if not info then
		return false, err
	end
	local bag, bagErr = resolvePlayerBag(realPlayer or player)
	if not bag then
		return false, bagErr or "NoPlayerData"
	end
	local ok, res = applyTransferCopperToBank(info.Id, bag, amountRaw)
	if not ok then
		return false, res
	end
	if realPlayer then
		pcall(function()
			remote:FireClient(realPlayer, "GuildBank", res.Bank)
			remote:FireClient(realPlayer, "InventoryTransfer", {
				Direction = "ToBank",
				Kind = "Copper",
				CopperCoins = res.CopperCoins,
			})
		end)
	end
	return true, res
end

function GuildSystem.TransferCopperFromBank(player, amountRaw)
	local info, realPlayer, err = assertTransferUnlocked(player)
	if not info then
		return false, err
	end
	local bag, bagErr = resolvePlayerBag(realPlayer or player)
	if not bag then
		return false, bagErr or "NoPlayerData"
	end
	local ok, res = applyTransferCopperFromBank(info.Id, bag, amountRaw)
	if not ok then
		return false, res
	end
	if realPlayer then
		pcall(function()
			remote:FireClient(realPlayer, "GuildBank", res.Bank)
			remote:FireClient(realPlayer, "InventoryTransfer", {
				Direction = "FromBank",
				Kind = "Copper",
				CopperCoins = res.CopperCoins,
			})
		end)
	end
	return true, res
end

-- In-memory warfare declare (QA / smoke). Does NOT bypass live DeclareWarfare gates.
local function applyWarfareDeclare(guildId, targetGuildId, declaredByUserId)
	local record = guildsById[guildId]
	if not record then
		return false, "NoGuild"
	end
	local targetId = tostring(targetGuildId or "")
	if #targetId < 2 then
		return false, "InvalidTarget"
	end
	if targetId == tostring(guildId) then
		return false, "SelfTarget"
	end
	local warfare = ensureWarfare(record)
	if warfare.State == "Declared" and warfare.TargetGuildId == targetId then
		-- idempotent redeclare same target
		return true, GuildSystem.GetWarfare(guildId)
	end
	if warfare.State ~= "Idle" then
		return false, "AlreadyActive"
	end
	local now = os.time()
	warfare.State = "Declared"
	warfare.TargetGuildId = targetId
	warfare.DeclaredByUserId = tonumber(declaredByUserId)
	warfare.DeclaredAt = now
	warfare.Participants = {}
	if type(declaredByUserId) == "number" then
		warfare.Participants[declaredByUserId] = {
			UserId = declaredByUserId,
			JoinedAt = now,
		}
	end
	return true, GuildSystem.GetWarfare(guildId)
end

local function applyWarfareJoin(guildId, userId)
	local record = guildsById[guildId]
	if not record then
		return false, "NoGuild"
	end
	local uid = tonumber(userId)
	if type(uid) ~= "number" then
		return false, "InvalidPlayer"
	end
	local warfare = ensureWarfare(record)
	if warfare.State ~= "Declared" then
		return false, "NoWarfare"
	end
	if warfare.Participants[uid] then
		return true, GuildSystem.GetWarfare(guildId)
	end
	local count = 0
	for _ in pairs(warfare.Participants) do
		count += 1
	end
	if count >= GuildSystem.MaxWarfareParticipants then
		return false, "Full"
	end
	warfare.Participants[uid] = {
		UserId = uid,
		JoinedAt = os.time(),
	}
	return true, GuildSystem.GetWarfare(guildId)
end

-- Live path: fail-closed until AllowGuilds AND warfare.Locked=false.
function GuildSystem.DeclareWarfare(player, targetGuildIdRaw)
	local userId, realPlayer = resolveUserId(player)
	if not userId then
		return false, "InvalidPlayer"
	end
	local targetId = tostring(targetGuildIdRaw or "")
	if #targetId < 2 then
		return false, "InvalidTarget"
	end
	local info = membership[userId]
	if not info then
		return false, "NoMembership"
	end
	if not gateAllowsGuilds() then
		return false, "Locked"
	end
	local record = guildsById[info.Id]
	if not record then
		return false, "NoGuild"
	end
	local warfare = ensureWarfare(record)
	if warfare.Locked then
		return false, "Locked"
	end
	local ok, res = applyWarfareDeclare(info.Id, targetId, userId)
	if not ok then
		return false, res
	end
	if realPlayer then
		pcall(function()
			remote:FireClient(realPlayer, "GuildWarfare", res)
		end)
	end
	return true, res
end

function GuildSystem.JoinWarfare(player)
	local userId, realPlayer = resolveUserId(player)
	if not userId then
		return false, "InvalidPlayer"
	end
	local info = membership[userId]
	if not info then
		return false, "NoMembership"
	end
	if not gateAllowsGuilds() then
		return false, "Locked"
	end
	local record = guildsById[info.Id]
	if not record then
		return false, "NoGuild"
	end
	local warfare = ensureWarfare(record)
	if warfare.Locked then
		return false, "Locked"
	end
	local ok, res = applyWarfareJoin(info.Id, userId)
	if not ok then
		return false, res
	end
	if realPlayer then
		pcall(function()
			remote:FireClient(realPlayer, "GuildWarfare", res)
		end)
	end
	return true, res
end

function GuildSystem.GetBankAudit()
	local bankGuildCount = 0
	local totalItems = 0
	local totalCopper = 0
	for _, record in pairs(guildsById) do
		local bank = ensureBank(record)
		bankGuildCount += 1
		totalCopper += bank.Copper
		totalItems += countOccupiedSlots(bank)
	end
	return {
		Phase = "F4-W13-guild-inv-bank",
		DevOnly = true,
		GateAllows = gateAllowsGuilds(),
		AllowGuildsAttr = allowGuildsAttr(),
		InMemoryOnly = true,
		LiveBankWrites = false,
		DepositWithdrawPrep = true,
		ItemSlotsPrep = true,
		InventoryTransferPrep = true,
		LiveDepositRequiresAllowGuilds = true,
		LiveDepositRequiresUnlocked = true,
		LiveItemWrites = false,
		LiveInventoryTransfer = false,
		BankSchemaVersion = GuildSystem.BankSchemaVersion,
		MaxBankSlots = GuildSystem.MaxBankSlots,
		MaxStackPerSlot = GuildSystem.MaxStackPerSlot,
		MaxBankCopperTxn = GuildSystem.MaxBankCopperTxn,
		MaxItemQtyTxn = GuildSystem.MaxItemQtyTxn,
		BankShape = { "Copper", "Items", "MaxSlots", "SchemaVersion", "Locked" },
		ItemSlotShape = { "Slot", "ItemId", "Qty" },
		PlayerInventoryShape = { "Id", "Quantity" },
		PlayerWalletKey = "CopperCoins",
		GuildsWithBank = bankGuildCount,
		TotalBankItems = totalItems,
		TotalBankCopper = totalCopper,
		Note = "W13 inventory↔bank prep: live Transfer* fail-closed Locked; smoke mutates synthetic bag + bank",
	}
end

function GuildSystem.GetWarfareAudit()
	local warfareGuildCount = 0
	local declaredCount = 0
	for _, record in pairs(guildsById) do
		local warfare = ensureWarfare(record)
		warfareGuildCount += 1
		if warfare.State == "Declared" then
			declaredCount += 1
		end
	end
	return {
		Phase = "F4-W13-guild-inv-bank",
		DevOnly = true,
		GateAllows = gateAllowsGuilds(),
		AllowGuildsAttr = allowGuildsAttr(),
		InMemoryOnly = true,
		LiveWarfareWrites = false,
		WarfarePrep = true,
		LiveDeclareRequiresAllowGuilds = true,
		LiveDeclareRequiresUnlocked = true,
		WarfareSchemaVersion = GuildSystem.WarfareSchemaVersion,
		MaxWarfareParticipants = GuildSystem.MaxWarfareParticipants,
		WarfareShape = {
			"State",
			"TargetGuildId",
			"DeclaredByUserId",
			"DeclaredAt",
			"Participants",
			"SchemaVersion",
			"Locked",
		},
		States = { "Idle", "Declared" },
		GuildsWithWarfare = warfareGuildCount,
		DeclaredCount = declaredCount,
		Note = "W12 warfare stub retained; phase advanced to W13 inv↔bank (warfare still Locked)",
	}
end

-- Client panel snapshot: membership + roster + bank + warfare (fail-closed create / writes).
function GuildSystem.GetPanelSnapshot(player)
	local info = GuildSystem.GetMembership(player)
	local gateOk = gateAllowsGuilds()
	if not info then
		return {
			HasMembership = false,
			GateAllows = gateOk,
			CreateBlocked = not gateOk,
			BankWriteLocked = true,
			WarfareWriteLocked = true,
			LockedMessage = if gateOk
				then "Нет гильдии — вступите через /guild (когда открыто)"
				else "Гильдии закрыты (ExpansionGate / dev-only)",
			Roster = {},
			Bank = nil,
			Warfare = nil,
		}
	end
	local roster = GuildSystem.GetRoster(info.Id) or {}
	local bank = GuildSystem.GetBank(info.Id)
	local warfare = GuildSystem.GetWarfare(info.Id)
	return {
		HasMembership = true,
		GateAllows = gateOk,
		CreateBlocked = not gateOk,
		BankWriteLocked = (bank == nil) or (bank.WriteLocked == true),
		WarfareWriteLocked = (warfare == nil) or (warfare.WriteLocked == true),
		Membership = info,
		Roster = roster,
		Bank = bank,
		Warfare = warfare,
		LockedMessage = nil,
	}
end

-- Read-only MVP persistence design (no live DS writes).
function GuildSystem.GetMvpDesign()
	return {
		Phase = "F4-W13-guild-inv-bank",
		DevOnly = true,
		InMemoryOnly = true,
		AllowGuildsRequiredForCreate = true,
		AllowGuildsRequiredForRestore = false,
		AllowGuildsRequiredForLeave = false,
		AllowGuildsRequiredForBankWrite = true,
		AllowGuildsRequiredForWarfare = true,
		AllowGuildsRequiredForInventoryTransfer = true,
		LiveDepositWithdrawFailClosed = true,
		LiveItemWritesFailClosed = true,
		LiveWarfareFailClosed = true,
		LiveInventoryTransferFailClosed = true,
		PlayerProfileKey = GuildSystem.PlayerGuildKey,
		PlayerShape = { "Id", "Name", "Tag", "Role" },
		PlayerInventoryShape = { "Id", "Quantity" },
		PlayerWalletKey = "CopperCoins",
		RosterShape = { "Id", "Name", "Tag", "LeaderUserId", "Members", "CreatedAt", "SchemaVersion", "Bank", "Warfare" },
		MemberEntryShape = { "UserId", "Role", "JoinedAt" },
		BankShape = { "Copper", "Items", "MaxSlots", "SchemaVersion", "Locked" },
		ItemSlotShape = { "Slot", "ItemId", "Qty" },
		WarfareShape = {
			"State",
			"TargetGuildId",
			"DeclaredByUserId",
			"DeclaredAt",
			"Participants",
			"SchemaVersion",
			"Locked",
		},
		Roles = { "Leader", "Officer", "Member" },
		MaxNameLen = GuildSystem.MaxNameLen,
		MaxTagLen = GuildSystem.MaxTagLen,
		MaxMembersPerGuild = GuildSystem.MaxMembersPerGuild,
		MaxBankSlots = GuildSystem.MaxBankSlots,
		MaxStackPerSlot = GuildSystem.MaxStackPerSlot,
		MaxBankCopperTxn = GuildSystem.MaxBankCopperTxn,
		MaxItemQtyTxn = GuildSystem.MaxItemQtyTxn,
		MaxWarfareParticipants = GuildSystem.MaxWarfareParticipants,
		FutureStoreName = GuildSystem.GuildStoreNameFuture,
		PersistencePlan = {
			"A. Player optional Guild {Id,Name,Tag,Role} — schema v1 locked; no full roster in profile",
			"B. Future DS RealmOfSpirits_Guilds_v1 keyed by guild Id (owner unlock + AllowGuilds)",
			"C. Join = upsert roster record + set player Guild; Leave = remove member / dissolve if empty",
			"D. W6 = in-memory guildsById + membership only (server restart wipes)",
			"E. W7 = restore data.Guild → membership/roster on load (no AllowGuilds); CreateOrJoin still gated",
			"F. W8 = Leave clears data.Guild + membership; same guild Id restores merge roster",
			"G. W9 = GuildPanelUI + empty Bank on guild record (in-memory, Locked=true); no live bank DS",
			"H. W10 = DepositCopper/WithdrawCopper fail-closed Locked; SmokeBankDepositMock in-memory mutate",
			"I. W11 = DepositItem/WithdrawItem fail-closed Locked; SmokeBankItemSlotsMock slot stack/fill",
			"J. W12 = DeclareWarfare/JoinWarfare fail-closed Locked; SmokeWarfareMock in-memory declare/join",
			"K. W13 = TransferItem/Copper To/FromBank fail-closed Locked; SmokeInventoryBankTransferMock synthetic bag↔bank",
		},
		Note = "Restore/Leave/UI read work with gate OFF; CreateOrJoin + live bank/warfare/transfer fail-closed until AllowGuilds",
	}
end

function GuildSystem.GetGuildAudit()
	local memberCount = 0
	for _ in pairs(membership) do
		memberCount += 1
	end
	local guildCount = 0
	for _ in pairs(guildsById) do
		guildCount += 1
	end
	return {
		Phase = "F4-W13-guild-inv-bank",
		DevOnly = true,
		GateAllows = gateAllowsGuilds(),
		AllowGuildsAttr = allowGuildsAttr(),
		InMemoryMembershipCount = memberCount,
		InMemoryGuildCount = guildCount,
		RemoteName = remote.Name,
		PersistedShape = { "Id", "Name", "Tag", "Role" },
		SchemaOptionalKey = GuildSystem.PlayerGuildKey,
		FutureStoreName = GuildSystem.GuildStoreNameFuture,
		RestoreRequiresAllowGuilds = false,
		LeaveRequiresAllowGuilds = false,
		CreateRequiresAllowGuilds = true,
		BankWriteRequiresAllowGuilds = true,
		WarfareRequiresAllowGuilds = true,
		InventoryTransferRequiresAllowGuilds = true,
		LiveDepositWithdrawFailClosed = true,
		LiveItemWritesFailClosed = true,
		LiveWarfareFailClosed = true,
		LiveInventoryTransferFailClosed = true,
		UiPanel = "GuildPanelUI",
		ChatCommands = { "/guild", "/guildleave", "/guildpanel", "/expansiongate" },
		Apis = {
			"GetGuildAudit",
			"GetMvpDesign",
			"GetRoster",
			"GetGuildRecord",
			"GetBank",
			"GetBankAudit",
			"GetWarfare",
			"GetWarfareAudit",
			"GetPanelSnapshot",
			"DepositCopper",
			"WithdrawCopper",
			"DepositItem",
			"WithdrawItem",
			"TransferItemToBank",
			"TransferItemFromBank",
			"TransferCopperToBank",
			"TransferCopperFromBank",
			"DeclareWarfare",
			"JoinWarfare",
			"RestoreMembershipFromGuildTable",
			"RestoreFromPlayerData",
			"ClearGuildMembership",
			"SmokeGuildRosterMock",
			"SmokeJoinRestoreMock",
			"SmokeGuildLeaveMock",
			"SmokeRosterMergeMock",
			"SmokeGuildBankMock",
			"SmokeGuildPanelPrepMock",
			"SmokeBankDepositMock",
			"SmokeBankItemSlotsMock",
			"SmokeWarfareMock",
			"SmokeInventoryBankTransferMock",
			"CreateOrJoin",
			"Leave",
		},
		NextSteps = {
			"Keep AllowGuilds=false under dev-only",
			"W14+: rated PvP prep or owner unlock — still gate OFF until owner",
			"Owner unlock required before live guild DS + AllowGuilds + unlock Bank/Warfare.Locked",
		},
		Note = "W13 inventory↔bank — live Transfer* Locked; CreateOrJoin fail-closed until AllowGuilds",
	}
end

local function ensureGuildRecord(id, guildName, tag, leaderUserId)
	local existing = guildsById[id]
	if existing then
		ensureBank(existing)
		ensureWarfare(existing)
		return existing
	end
	local now = os.time()
	local record = {
		Id = id,
		Name = guildName,
		Tag = tag,
		LeaderUserId = leaderUserId,
		Members = {},
		Bank = emptyBank(),
		Warfare = emptyWarfare(),
		CreatedAt = now,
		SchemaVersion = GuildSystem.RosterSchemaVersion,
	}
	guildsById[id] = record
	return record
end

local function addMemberToRecord(record, userId, role)
	local existingMember = record.Members[userId]
	if existingMember then
		existingMember.Role = role
		return true, nil
	end
	if countMembers(record) >= GuildSystem.MaxMembersPerGuild then
		return false, "Гильдия полна"
	end
	record.Members[userId] = {
		UserId = userId,
		Role = role,
		JoinedAt = os.time(),
	}
	return true, nil
end

local function removeMemberFromRecord(guildId, userId)
	local record = guildsById[guildId]
	if not record then
		return
	end
	record.Members[userId] = nil
	if countMembers(record) == 0 then
		guildsById[guildId] = nil
		return
	end
	if record.LeaderUserId == userId then
		local nextLeader = nil
		for uid, entry in pairs(record.Members) do
			if entry.Role == "Officer" then
				nextLeader = uid
				break
			end
		end
		if not nextLeader then
			for uid, _ in pairs(record.Members) do
				nextLeader = uid
				break
			end
		end
		if nextLeader then
			record.LeaderUserId = nextLeader
			local entry = record.Members[nextLeader]
			if entry then
				entry.Role = "Leader"
			end
		end
	end
end

local function mergeGuildMetadata(record, parsed, userId)
	-- Multi-player merge: union members under same guild Id; Leader wins Name/Tag.
	if parsed.Role == "Leader" then
		record.LeaderUserId = userId
		record.Name = parsed.Name
		record.Tag = parsed.Tag
	elseif record.LeaderUserId == 0 or not record.Members[record.LeaderUserId] then
		if countMembers(record) == 0 then
			record.Name = parsed.Name
			record.Tag = parsed.Tag
			if parsed.Role == "Leader" then
				record.LeaderUserId = userId
			end
		end
	end
	if #parsed.Tag >= 2 then
		record.Tag = parsed.Tag
	end
	if #parsed.Name >= 2 and (record.LeaderUserId == userId or countMembers(record) <= 1) then
		record.Name = parsed.Name
	end
end

-- Gate-independent restore: upsert in-memory roster/membership from persisted Guild shape.
-- Merges into existing guild record when multiple players restore the same Id.
-- Does NOT create via CreateOrJoin path; AllowGuilds stays required for create/join chat/remote.
function GuildSystem.RestoreMembershipFromGuildTable(userId, guildTable, playerOpt)
	local uid = tonumber(userId)
	if not uid then
		return false, "InvalidUserId"
	end
	local parsed, err = parseGuildTable(guildTable)
	if not parsed then
		return false, err or "InvalidGuildShape"
	end

	local leaderHint = if parsed.Role == "Leader" then uid else 0
	local record = ensureGuildRecord(parsed.Id, parsed.Name, parsed.Tag, leaderHint)
	mergeGuildMetadata(record, parsed, uid)

	local okAdd, errAdd = addMemberToRecord(record, uid, parsed.Role)
	if not okAdd then
		return false, errAdd or "Не удалось восстановить"
	end

	local info = {
		Id = parsed.Id,
		Name = record.Name,
		Tag = record.Tag,
		Role = parsed.Role,
	}
	membership[uid] = info

	local player = playerOpt
	if player and typeof(player) == "Instance" and player:IsA("Player") then
		player:SetAttribute("GuildTag", record.Tag)
		player:SetAttribute("GuildName", record.Name)
		player:SetAttribute("GuildRole", parsed.Role)
		pcall(function()
			remote:FireClient(player, "GuildState", info)
		end)
	end

	return true, info
end

-- Called after player data load. Restore does NOT require AllowGuilds.
function GuildSystem.RestoreFromPlayerData(player, dataOpt)
	if not player or typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "InvalidPlayer"
	end
	local data = dataOpt
	if type(data) ~= "table" then
		data = getData(player)
	end
	if type(data) ~= "table" then
		return false, "NoData"
	end
	if type(data.Guild) ~= "table" then
		return false, "NoGuild"
	end
	return GuildSystem.RestoreMembershipFromGuildTable(player.UserId, data.Guild, player)
end

function GuildSystem.CreateOrJoin(player, guildName, tag)
	-- Fail-closed: missing gate = blocked
	if not gateAllowsGuilds() then
		return false, "Гильдии закрыты ExpansionGate (Q4)"
	end
	local nameStr = tostring(guildName or ""):sub(1, GuildSystem.MaxNameLen)
	local tagStr = tostring(tag or ""):upper():gsub("[^A-Z0-9]", ""):sub(1, GuildSystem.MaxTagLen)
	if #nameStr < 2 or #tagStr < 2 then
		return false, "Имя (2+) и тег (2–4)"
	end
	local id = "g_" .. string.lower(tagStr)
	local record = guildsById[id]
	local role = "Member"
	if not record then
		record = ensureGuildRecord(id, nameStr, tagStr, player.UserId)
		role = "Leader"
	elseif countMembers(record) == 0 then
		record.LeaderUserId = player.UserId
		role = "Leader"
	end
	local okAdd, errAdd = addMemberToRecord(record, player.UserId, role)
	if not okAdd then
		return false, errAdd or "Не удалось вступить"
	end
	local info = { Id = id, Name = record.Name, Tag = record.Tag, Role = role }
	membership[player.UserId] = info
	player:SetAttribute("GuildTag", record.Tag)
	player:SetAttribute("GuildName", record.Name)
	player:SetAttribute("GuildRole", role)
	local data = getData(player)
	if data then
		data.Guild = { Id = id, Name = record.Name, Tag = record.Tag, Role = role }
	end
	remote:FireClient(player, "GuildJoined", info)
	return true, info
end

function GuildSystem.ClearGuildMembership(userId, dataOpt)
	local uid = tonumber(userId)
	if not uid then
		return false, "InvalidUserId"
	end
	local info = membership[uid]
	local guildId = info and info.Id or nil
	if info then
		removeMemberFromRecord(info.Id, uid)
	end
	membership[uid] = nil

	local data = dataOpt
	if type(data) ~= "table" and uid then
		-- Sentinel smokes pass explicit data; live path uses _G.GetPlayerData via Player
		data = nil
	end
	if type(data) == "table" then
		data.Guild = nil
	end

	return true, {
		HadMembership = info ~= nil,
		GuildId = guildId,
		DataGuildCleared = type(data) == "table",
	}
end

function GuildSystem.Leave(player, dataOpt)
	if not player or typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "InvalidPlayer"
	end
	local data = dataOpt
	if type(data) ~= "table" then
		data = getData(player)
	end
	local ok, res = GuildSystem.ClearGuildMembership(player.UserId, data)
	if not ok then
		return false, res
	end
	player:SetAttribute("GuildTag", nil)
	player:SetAttribute("GuildName", nil)
	player:SetAttribute("GuildRole", nil)
	remote:FireClient(player, "GuildLeft", {})
	return true, res
end

-- Studio/dev smoke: in-memory roster without AllowGuilds flip or DataStore.
function GuildSystem.SmokeGuildRosterMock()
	local smokeId = GuildSystem.SmokeGuildId
	-- Wipe prior smoke
	guildsById[smokeId] = nil
	for uid, info in pairs(membership) do
		if info.Id == smokeId then
			membership[uid] = nil
		end
	end

	local leaderId = 900000101
	local memberId = 900000102
	local record = ensureGuildRecord(smokeId, "W6 Smoke Guild", "W6S", leaderId)
	addMemberToRecord(record, leaderId, "Leader")
	addMemberToRecord(record, memberId, "Member")
	membership[leaderId] = { Id = smokeId, Name = record.Name, Tag = record.Tag, Role = "Leader" }
	membership[memberId] = { Id = smokeId, Name = record.Name, Tag = record.Tag, Role = "Member" }

	local roster = GuildSystem.GetRoster(smokeId)
	local createBlocked = false
	local createMsg = nil
	-- Fake Player table is not available; probe gate via CreateOrJoin path using gate helper
	createBlocked = not gateAllowsGuilds()
	if createBlocked then
		createMsg = "Гильдии закрыты ExpansionGate (Q4)"
	end

	local rosterOk = roster ~= nil and #roster == 2
	local design = GuildSystem.GetMvpDesign()
	return {
		Success = rosterOk == true and createBlocked == true,
		SmokeGuildId = smokeId,
		RosterCount = roster and #roster or 0,
		RosterOk = rosterOk,
		CreateOrJoinBlocked = createBlocked,
		CreateOrJoinMessage = createMsg,
		GateAllows = gateAllowsGuilds(),
		AllowGuildsAttr = allowGuildsAttr(),
		Phase = design.Phase,
		InMemoryOnly = true,
	}
end

-- Studio/dev smoke: restore from Guild table without AllowGuilds; create stays blocked.
function GuildSystem.SmokeJoinRestoreMock()
	local smokeId = GuildSystem.SmokeRestoreGuildId
	guildsById[smokeId] = nil
	for uid, info in pairs(membership) do
		if info.Id == smokeId then
			membership[uid] = nil
		end
	end

	local userId = 900000201
	local payload = {
		Id = smokeId,
		Name = "W7 Restore Guild",
		Tag = "W7R",
		Role = "Officer",
	}
	local okRestore, info = GuildSystem.RestoreMembershipFromGuildTable(userId, payload, nil)
	local mem = membership[userId]
	local roster = GuildSystem.GetRoster(smokeId)
	local createBlocked = not gateAllowsGuilds()
	local noGuildOk = select(1, GuildSystem.RestoreMembershipFromGuildTable(900000202, nil, nil)) == false
	local restoreOk = okRestore == true
		and mem ~= nil
		and mem.Id == smokeId
		and mem.Role == "Officer"
		and roster ~= nil
		and #roster == 1
		and createBlocked == true
		and noGuildOk == true

	local design = GuildSystem.GetMvpDesign()
	return {
		Success = restoreOk,
		SmokeGuildId = smokeId,
		Restored = okRestore,
		MembershipRole = mem and mem.Role or nil,
		RosterCount = roster and #roster or 0,
		CreateOrJoinBlocked = createBlocked,
		GateAllows = gateAllowsGuilds(),
		AllowGuildsAttr = allowGuildsAttr(),
		RestoreRequiresAllowGuilds = false,
		NoGuildRejected = noGuildOk,
		Phase = design.Phase,
		Info = info,
		InMemoryOnly = true,
	}
end

-- Studio/dev smoke: Leave clears data.Guild + membership (gate-independent).
function GuildSystem.SmokeGuildLeaveMock()
	local smokeId = GuildSystem.SmokeLeaveGuildId
	local userId = 900000301
	guildsById[smokeId] = nil
	for uid, info in pairs(membership) do
		if info.Id == smokeId then
			membership[uid] = nil
		end
	end

	local mockData = {
		Guild = {
			Id = smokeId,
			Name = "W8 Leave Guild",
			Tag = "W8L",
			Role = "Member",
		},
	}
	local okRestore = GuildSystem.RestoreMembershipFromGuildTable(userId, mockData.Guild, nil)
	local rosterBefore = GuildSystem.GetRoster(smokeId)
	local okLeave, leaveInfo = GuildSystem.ClearGuildMembership(userId, mockData)
	local memAfter = membership[userId]
	local rosterAfter = GuildSystem.GetRoster(smokeId)
	local createBlocked = not gateAllowsGuilds()

	local leaveOk = okRestore == true
		and okLeave == true
		and mockData.Guild == nil
		and memAfter == nil
		and leaveInfo ~= nil
		and leaveInfo.HadMembership == true
		and leaveInfo.DataGuildCleared == true
		and (rosterBefore ~= nil and #rosterBefore == 1)
		and (rosterAfter == nil or #rosterAfter == 0)
		and createBlocked == true

	local design = GuildSystem.GetMvpDesign()
	return {
		Success = leaveOk,
		SmokeGuildId = smokeId,
		RestoredBeforeLeave = okRestore,
		LeaveOk = okLeave,
		DataGuildNil = mockData.Guild == nil,
		MembershipCleared = memAfter == nil,
		RosterCountBefore = rosterBefore and #rosterBefore or 0,
		RosterCountAfter = rosterAfter and #rosterAfter or 0,
		CreateOrJoinBlocked = createBlocked,
		GateAllows = gateAllowsGuilds(),
		AllowGuildsAttr = allowGuildsAttr(),
		LeaveRequiresAllowGuilds = false,
		Phase = design.Phase,
		LeaveInfo = leaveInfo,
		InMemoryOnly = true,
	}
end

-- Studio/dev smoke: two restores with same guild Id merge into one roster.
function GuildSystem.SmokeRosterMergeMock()
	local smokeId = GuildSystem.SmokeMergeGuildId
	local leaderId = 900000401
	local memberId = 900000402
	guildsById[smokeId] = nil
	for uid, info in pairs(membership) do
		if info.Id == smokeId then
			membership[uid] = nil
		end
	end

	local okA = GuildSystem.RestoreMembershipFromGuildTable(leaderId, {
		Id = smokeId,
		Name = "W8 Merge Alpha",
		Tag = "W8M",
		Role = "Leader",
	}, nil)
	local okB = GuildSystem.RestoreMembershipFromGuildTable(memberId, {
		Id = smokeId,
		Name = "W8 Merge Beta",
		Tag = "W8M",
		Role = "Member",
	}, nil)

	local roster = GuildSystem.GetRoster(smokeId)
	local record = GuildSystem.GetGuildRecord(smokeId)
	local memA = membership[leaderId]
	local memB = membership[memberId]
	local createBlocked = not gateAllowsGuilds()
	local guildCount = 0
	for gid in pairs(guildsById) do
		if gid == smokeId then
			guildCount += 1
		end
	end

	local mergeOk = okA == true
		and okB == true
		and roster ~= nil
		and #roster == 2
		and memA ~= nil
		and memB ~= nil
		and memA.Id == smokeId
		and memB.Id == smokeId
		and record ~= nil
		and record.LeaderUserId == leaderId
		and guildCount == 1
		and createBlocked == true

	local design = GuildSystem.GetMvpDesign()
	return {
		Success = mergeOk,
		SmokeGuildId = smokeId,
		RosterCount = roster and #roster or 0,
		RosterMerged = mergeOk,
		LeaderUserId = record and record.LeaderUserId or nil,
		SharedGuildCount = guildCount,
		CreateOrJoinBlocked = createBlocked,
		GateAllows = gateAllowsGuilds(),
		AllowGuildsAttr = allowGuildsAttr(),
		Phase = design.Phase,
		InMemoryOnly = true,
	}
end

-- Studio/dev smoke: empty locked bank on guild record; create still blocked.
function GuildSystem.SmokeGuildBankMock()
	local smokeId = GuildSystem.SmokeBankGuildId
	guildsById[smokeId] = nil
	for uid, info in pairs(membership) do
		if info.Id == smokeId then
			membership[uid] = nil
		end
	end

	local userId = 900000501
	local okRestore = GuildSystem.RestoreMembershipFromGuildTable(userId, {
		Id = smokeId,
		Name = "W9 Bank Guild",
		Tag = "W9B",
		Role = "Leader",
	}, nil)
	local record = GuildSystem.GetGuildRecord(smokeId)
	local bank = GuildSystem.GetBank(smokeId)
	local audit = GuildSystem.GetBankAudit()
	local createBlocked = not gateAllowsGuilds()

	local bankOk = okRestore == true
		and record ~= nil
		and type(record.Bank) == "table"
		and bank ~= nil
		and bank.Copper == 0
		and bank.ItemCount == 0
		and bank.Locked == true
		and bank.InMemoryOnly == true
		and audit.LiveBankWrites == false
		and createBlocked == true

	local design = GuildSystem.GetMvpDesign()
	return {
		Success = bankOk,
		SmokeGuildId = smokeId,
		BankCopper = bank and bank.Copper or nil,
		BankItemCount = bank and bank.ItemCount or 0,
		BankLocked = bank and bank.Locked or nil,
		LiveBankWrites = audit.LiveBankWrites,
		CreateOrJoinBlocked = createBlocked,
		GateAllows = gateAllowsGuilds(),
		AllowGuildsAttr = allowGuildsAttr(),
		Phase = design.Phase,
		InMemoryOnly = true,
	}
end

-- Studio/dev smoke: panel snapshot fail-closed without membership + roster when restored.
function GuildSystem.SmokeGuildPanelPrepMock()
	local smokeId = GuildSystem.SmokeBankGuildId .. "_panel"
	guildsById[smokeId] = nil
	for uid, info in pairs(membership) do
		if info.Id == smokeId then
			membership[uid] = nil
		end
	end

	local fakeNoGuild = { UserId = 900000601 }
	local snapLocked = GuildSystem.GetPanelSnapshot(fakeNoGuild)
	local lockedOk = snapLocked.HasMembership == false
		and type(snapLocked.LockedMessage) == "string"
		and #snapLocked.LockedMessage > 0
		and snapLocked.CreateBlocked == true

	local userId = 900000602
	GuildSystem.RestoreMembershipFromGuildTable(userId, {
		Id = smokeId,
		Name = "W9 Panel Guild",
		Tag = "W9P",
		Role = "Member",
	}, nil)
	local fakeMember = { UserId = userId }
	local snapMember = GuildSystem.GetPanelSnapshot(fakeMember)
	local memberOk = snapMember.HasMembership == true
		and snapMember.Membership ~= nil
		and snapMember.Membership.Id == smokeId
		and type(snapMember.Roster) == "table"
		and #snapMember.Roster == 1
		and snapMember.Bank ~= nil
		and snapMember.Bank.Locked == true
		and snapMember.CreateBlocked == true

	local createBlocked = not gateAllowsGuilds()
	local design = GuildSystem.GetMvpDesign()
	return {
		Success = lockedOk == true and memberOk == true and createBlocked == true,
		LockedOk = lockedOk,
		MemberOk = memberOk,
		LockedMessage = snapLocked.LockedMessage,
		RosterCount = snapMember.Roster and #snapMember.Roster or 0,
		BankLocked = snapMember.Bank and snapMember.Bank.Locked or nil,
		CreateOrJoinBlocked = createBlocked,
		GateAllows = gateAllowsGuilds(),
		AllowGuildsAttr = allowGuildsAttr(),
		Phase = design.Phase,
		InMemoryOnly = true,
	}
end

-- Studio/dev smoke: live Deposit/Withdraw Locked; in-memory copper mutate for QA.
function GuildSystem.SmokeBankDepositMock()
	local smokeId = GuildSystem.SmokeDepositGuildId
	guildsById[smokeId] = nil
	for uid, info in pairs(membership) do
		if info.Id == smokeId then
			membership[uid] = nil
		end
	end

	local userId = 900000701
	local okRestore = GuildSystem.RestoreMembershipFromGuildTable(userId, {
		Id = smokeId,
		Name = "W10 Deposit Guild",
		Tag = "W10D",
		Role = "Leader",
	}, nil)
	local fakeMember = { UserId = userId }

	local okDep, depErr = GuildSystem.DepositCopper(fakeMember, 100)
	local liveDepositBlocked = okDep == false and depErr == "Locked"

	local okWd, wdErr = GuildSystem.WithdrawCopper(fakeMember, 50)
	local liveWithdrawBlocked = okWd == false and wdErr == "Locked"

	local okMutIn, bankAfterIn = applyBankCopperDelta(smokeId, 500)
	local okMutOut, bankAfterOut = applyBankCopperDelta(smokeId, -200)
	local bankFinal = GuildSystem.GetBank(smokeId)
	local panel = GuildSystem.GetPanelSnapshot(fakeMember)
	local createBlocked = not gateAllowsGuilds()

	local mutateOk = okRestore == true
		and liveDepositBlocked == true
		and liveWithdrawBlocked == true
		and okMutIn == true
		and okMutOut == true
		and bankAfterIn ~= nil
		and bankAfterIn.Copper == 500
		and bankAfterOut ~= nil
		and bankAfterOut.Copper == 300
		and bankFinal ~= nil
		and bankFinal.Copper == 300
		and bankFinal.Locked == true
		and bankFinal.WriteLocked == true
		and panel.BankWriteLocked == true
		and createBlocked == true

	local design = GuildSystem.GetMvpDesign()
	return {
		Success = mutateOk,
		SmokeGuildId = smokeId,
		LiveDepositBlocked = liveDepositBlocked,
		LiveWithdrawBlocked = liveWithdrawBlocked,
		LiveDepositError = depErr,
		LiveWithdrawError = wdErr,
		CopperAfterDepositMock = bankAfterIn and bankAfterIn.Copper or nil,
		CopperAfterWithdrawMock = bankFinal and bankFinal.Copper or nil,
		BankLocked = bankFinal and bankFinal.Locked or nil,
		WriteLocked = bankFinal and bankFinal.WriteLocked or nil,
		PanelWriteLocked = panel.BankWriteLocked,
		CreateOrJoinBlocked = createBlocked,
		GateAllows = gateAllowsGuilds(),
		AllowGuildsAttr = allowGuildsAttr(),
		Phase = design.Phase,
		InMemoryOnly = true,
	}
end

-- Studio/dev smoke: live DepositItem/WithdrawItem Locked; in-memory slot stack/fill for QA.
function GuildSystem.SmokeBankItemSlotsMock()
	local smokeId = GuildSystem.SmokeItemGuildId
	guildsById[smokeId] = nil
	for uid, info in pairs(membership) do
		if info.Id == smokeId then
			membership[uid] = nil
		end
	end

	local userId = 900000801
	local okRestore = GuildSystem.RestoreMembershipFromGuildTable(userId, {
		Id = smokeId,
		Name = "W11 Item Guild",
		Tag = "W11I",
		Role = "Leader",
	}, nil)
	local fakeMember = { UserId = userId }

	local okDep, depErr = GuildSystem.DepositItem(fakeMember, 101, 2)
	local liveDepositBlocked = okDep == false and depErr == "Locked"

	local okWd, wdErr = GuildSystem.WithdrawItem(fakeMember, 101, 1)
	local liveWithdrawBlocked = okWd == false and wdErr == "Locked"

	local okMutIn, bankAfterIn = applyBankItemDelta(smokeId, 101, 3)
	local okMutOut, bankAfterOut = applyBankItemDelta(smokeId, 101, -1)
	local bankFinal = GuildSystem.GetBank(smokeId)
	local panel = GuildSystem.GetPanelSnapshot(fakeMember)
	local createBlocked = not gateAllowsGuilds()

	local slot0 = bankFinal and bankFinal.Items and bankFinal.Items[1] or nil
	local qtyOk = slot0 ~= nil and slot0.ItemId == 101 and slot0.Qty == 2

	-- Fill remaining slots to MaxSlots then expect SlotsFull
	local fillOk = true
	local bank = guildsById[smokeId] and ensureBank(guildsById[smokeId])
	if bank then
		for slot = 1, bank.MaxSlots do
			if bank.Items[slot] == nil then
				bank.Items[slot] = { ItemId = 102, Qty = 1 }
			end
		end
	end
	local okFull, fullErr = applyBankItemDelta(smokeId, 103, 1)
	local slotsFullOk = okFull == false and fullErr == "SlotsFull"

	local mutateOk = okRestore == true
		and liveDepositBlocked == true
		and liveWithdrawBlocked == true
		and okMutIn == true
		and okMutOut == true
		and bankAfterIn ~= nil
		and bankAfterIn.ItemCount == 1
		and bankAfterIn.Items[1] ~= nil
		and bankAfterIn.Items[1].Qty == 3
		and bankAfterOut ~= nil
		and bankAfterOut.Items[1] ~= nil
		and bankAfterOut.Items[1].Qty == 2
		and bankFinal ~= nil
		and bankFinal.ItemCount == 1
		and qtyOk == true
		and bankFinal.Locked == true
		and bankFinal.WriteLocked == true
		and panel.BankWriteLocked == true
		and createBlocked == true
		and slotsFullOk == true
		and fillOk == true

	local design = GuildSystem.GetMvpDesign()
	return {
		Success = mutateOk,
		SmokeGuildId = smokeId,
		LiveDepositBlocked = liveDepositBlocked,
		LiveWithdrawBlocked = liveWithdrawBlocked,
		LiveDepositError = depErr,
		LiveWithdrawError = wdErr,
		ItemId = 101,
		QtyAfterDepositMock = bankAfterIn and bankAfterIn.Items[1] and bankAfterIn.Items[1].Qty or nil,
		QtyAfterWithdrawMock = bankFinal and bankFinal.Items[1] and bankFinal.Items[1].Qty or nil,
		SlotCountAfter = bankFinal and bankFinal.ItemCount or nil,
		SlotsFullBlocked = slotsFullOk,
		BankLocked = bankFinal and bankFinal.Locked or nil,
		WriteLocked = bankFinal and bankFinal.WriteLocked or nil,
		PanelWriteLocked = panel.BankWriteLocked,
		CreateOrJoinBlocked = createBlocked,
		GateAllows = gateAllowsGuilds(),
		AllowGuildsAttr = allowGuildsAttr(),
		Phase = design.Phase,
		InMemoryOnly = true,
	}
end

-- Studio/dev smoke: live DeclareWarfare/JoinWarfare Locked; in-memory declare/join for QA.
function GuildSystem.SmokeWarfareMock()
	local smokeId = GuildSystem.SmokeWarfareGuildId
	local targetId = GuildSystem.SmokeWarfareTargetGuildId
	guildsById[smokeId] = nil
	guildsById[targetId] = nil
	for uid, info in pairs(membership) do
		if info.Id == smokeId or info.Id == targetId then
			membership[uid] = nil
		end
	end

	-- Ensure target guild record exists (shape only; no membership needed for declare target)
	ensureGuildRecord(targetId, "W12 Target Guild", "W12T", 900000912)

	local userId = 900000901
	local joinerId = 900000902
	local okRestore = GuildSystem.RestoreMembershipFromGuildTable(userId, {
		Id = smokeId,
		Name = "W12 Warfare Guild",
		Tag = "W12W",
		Role = "Leader",
	}, nil)
	local okRestore2 = GuildSystem.RestoreMembershipFromGuildTable(joinerId, {
		Id = smokeId,
		Name = "W12 Warfare Guild",
		Tag = "W12W",
		Role = "Member",
	}, nil)
	local fakeLeader = { UserId = userId }
	local fakeJoiner = { UserId = joinerId }

	local okDec, decErr = GuildSystem.DeclareWarfare(fakeLeader, targetId)
	local liveDeclareBlocked = okDec == false and decErr == "Locked"

	local okJoin, joinErr = GuildSystem.JoinWarfare(fakeJoiner)
	local liveJoinBlocked = okJoin == false and joinErr == "Locked"

	local okMutDec, warAfterDec = applyWarfareDeclare(smokeId, targetId, userId)
	local okMutJoin, warAfterJoin = applyWarfareJoin(smokeId, joinerId)
	local warFinal = GuildSystem.GetWarfare(smokeId)
	local panel = GuildSystem.GetPanelSnapshot(fakeLeader)
	local createBlocked = not gateAllowsGuilds()

	local selfOk, selfErr = applyWarfareDeclare(smokeId, smokeId, userId)
	local selfBlocked = selfOk == false and selfErr == "SelfTarget"

	local mutateOk = okRestore == true
		and okRestore2 == true
		and liveDeclareBlocked == true
		and liveJoinBlocked == true
		and okMutDec == true
		and okMutJoin == true
		and warAfterDec ~= nil
		and warAfterDec.State == "Declared"
		and warAfterDec.TargetGuildId == targetId
		and warAfterDec.ParticipantCount == 1
		and warAfterJoin ~= nil
		and warAfterJoin.ParticipantCount == 2
		and warFinal ~= nil
		and warFinal.State == "Declared"
		and warFinal.TargetGuildId == targetId
		and warFinal.ParticipantCount == 2
		and warFinal.Locked == true
		and warFinal.WriteLocked == true
		and panel.WarfareWriteLocked == true
		and panel.Warfare ~= nil
		and panel.Warfare.State == "Declared"
		and createBlocked == true
		and selfBlocked == true

	local design = GuildSystem.GetMvpDesign()
	local warAudit = GuildSystem.GetWarfareAudit()
	return {
		Success = mutateOk,
		SmokeGuildId = smokeId,
		TargetGuildId = targetId,
		LiveDeclareBlocked = liveDeclareBlocked,
		LiveJoinBlocked = liveJoinBlocked,
		LiveDeclareError = decErr,
		LiveJoinError = joinErr,
		StateAfter = warFinal and warFinal.State or nil,
		ParticipantCount = warFinal and warFinal.ParticipantCount or nil,
		WarfareLocked = warFinal and warFinal.Locked or nil,
		WriteLocked = warFinal and warFinal.WriteLocked or nil,
		PanelWarfareWriteLocked = panel.WarfareWriteLocked,
		PanelState = panel.Warfare and panel.Warfare.State or nil,
		SelfTargetBlocked = selfBlocked,
		CreateOrJoinBlocked = createBlocked,
		GateAllows = gateAllowsGuilds(),
		AllowGuildsAttr = allowGuildsAttr(),
		WarfarePrep = warAudit.WarfarePrep == true,
		Phase = design.Phase,
		InMemoryOnly = true,
	}
end

-- Studio/dev smoke: live Transfer* Locked; synthetic Inventory/CopperCoins ↔ bank for QA.
function GuildSystem.SmokeInventoryBankTransferMock()
	local smokeId = GuildSystem.SmokeTransferGuildId
	guildsById[smokeId] = nil
	for uid, info in pairs(membership) do
		if info.Id == smokeId then
			membership[uid] = nil
		end
	end

	local userId = 900001001
	local okRestore = GuildSystem.RestoreMembershipFromGuildTable(userId, {
		Id = smokeId,
		Name = "W13 Transfer Guild",
		Tag = "W13X",
		Role = "Leader",
	}, nil)
	local fakeMember = { UserId = userId }

	local okLiveItemIn, liveItemInErr = GuildSystem.TransferItemToBank(fakeMember, 101, 1)
	local liveItemToBlocked = okLiveItemIn == false and liveItemInErr == "Locked"
	local okLiveItemOut, liveItemOutErr = GuildSystem.TransferItemFromBank(fakeMember, 101, 1)
	local liveItemFromBlocked = okLiveItemOut == false and liveItemOutErr == "Locked"
	local okLiveCuIn, liveCuInErr = GuildSystem.TransferCopperToBank(fakeMember, 50)
	local liveCopperToBlocked = okLiveCuIn == false and liveCuInErr == "Locked"
	local okLiveCuOut, liveCuOutErr = GuildSystem.TransferCopperFromBank(fakeMember, 50)
	local liveCopperFromBlocked = okLiveCuOut == false and liveCuOutErr == "Locked"

	local bag = {
		CopperCoins = 1000,
		Inventory = {
			{ Id = 101, Quantity = 5 },
		},
	}

	local okToBank, resToBank = applyTransferItemToBank(smokeId, bag, 101, 2)
	local okFromBank, resFromBank = applyTransferItemFromBank(smokeId, bag, 101, 1)
	local okCuTo, resCuTo = applyTransferCopperToBank(smokeId, bag, 200)
	local okCuFrom, resCuFrom = applyTransferCopperFromBank(smokeId, bag, 50)

	local bankFinal = GuildSystem.GetBank(smokeId)
	local panel = GuildSystem.GetPanelSnapshot(fakeMember)
	local createBlocked = not gateAllowsGuilds()

	local invQty = countPlayerInventoryQty(bag.Inventory, 101)
	local copperOk = getBagCopper(bag) == 850
	local bankItem = bankFinal and bankFinal.Items and bankFinal.Items[1] or nil
	local bankItemOk = bankItem ~= nil and bankItem.ItemId == 101 and bankItem.Qty == 1
	local bankCopperOk = bankFinal ~= nil and bankFinal.Copper == 150

	-- InsufficientItems on over-withdraw from bag
	local okShort, shortErr = applyTransferItemToBank(smokeId, bag, 101, 99)
	local shortBlocked = okShort == false and shortErr == "InsufficientItems"

	local mutateOk = okRestore == true
		and liveItemToBlocked == true
		and liveItemFromBlocked == true
		and liveCopperToBlocked == true
		and liveCopperFromBlocked == true
		and okToBank == true
		and okFromBank == true
		and okCuTo == true
		and okCuFrom == true
		and resToBank ~= nil
		and resToBank.InventoryQty == 3
		and resFromBank ~= nil
		and resFromBank.InventoryQty == 4
		and invQty == 4
		and copperOk == true
		and bankItemOk == true
		and bankCopperOk == true
		and bankFinal ~= nil
		and bankFinal.Locked == true
		and bankFinal.WriteLocked == true
		and panel.BankWriteLocked == true
		and createBlocked == true
		and shortBlocked == true

	local design = GuildSystem.GetMvpDesign()
	local bankAudit = GuildSystem.GetBankAudit()
	return {
		Success = mutateOk,
		SmokeGuildId = smokeId,
		LiveItemToBankBlocked = liveItemToBlocked,
		LiveItemFromBankBlocked = liveItemFromBlocked,
		LiveCopperToBankBlocked = liveCopperToBlocked,
		LiveCopperFromBankBlocked = liveCopperFromBlocked,
		LiveItemToError = liveItemInErr,
		LiveCopperToError = liveCuInErr,
		InventoryQtyAfter = invQty,
		CopperAfter = getBagCopper(bag),
		BankItemQtyAfter = bankItem and bankItem.Qty or nil,
		BankCopperAfter = bankFinal and bankFinal.Copper or nil,
		InsufficientItemsBlocked = shortBlocked,
		BankLocked = bankFinal and bankFinal.Locked or nil,
		WriteLocked = bankFinal and bankFinal.WriteLocked or nil,
		PanelWriteLocked = panel.BankWriteLocked,
		CreateOrJoinBlocked = createBlocked,
		GateAllows = gateAllowsGuilds(),
		AllowGuildsAttr = allowGuildsAttr(),
		InventoryTransferPrep = bankAudit.InventoryTransferPrep == true,
		Phase = design.Phase,
		InMemoryOnly = true,
	}
end

local function deferRestoreWhenDataReady(player)
	task.spawn(function()
		for _ = 1, 40 do
			if not player.Parent then
				return
			end
			local data = getData(player)
			if type(data) == "table" then
				if type(data.Guild) == "table" then
					GuildSystem.RestoreFromPlayerData(player, data)
				end
				return
			end
			task.wait(0.25)
		end
	end)
end

function GuildSystem.Start()
	if GuildSystem._started then
		return
	end
	GuildSystem._started = true

	remote.OnServerEvent:Connect(function(player, action, payload)
		if typeof(action) ~= "string" then
			return
		end
		payload = type(payload) == "table" and payload or {}
		if action == "CreateOrJoin" then
			local ok, res = GuildSystem.CreateOrJoin(player, payload.Name, payload.Tag)
			if not ok then
				remote:FireClient(player, "Error", { Message = res })
			end
		elseif action == "Leave" then
			GuildSystem.Leave(player)
		elseif action == "Get" then
			remote:FireClient(player, "GuildState", GuildSystem.GetMembership(player) or {})
		elseif action == "GetRoster" then
			local info = GuildSystem.GetMembership(player)
			local list = info and GuildSystem.GetRoster(info.Id) or {}
			remote:FireClient(player, "GuildRoster", list or {})
		elseif action == "GetBank" then
			local info = GuildSystem.GetMembership(player)
			local bank = info and GuildSystem.GetBank(info.Id) or nil
			remote:FireClient(player, "GuildBank", bank or { Locked = true, Copper = 0, ItemCount = 0, Items = {}, InMemoryOnly = true })
		elseif action == "GetPanel" then
			remote:FireClient(player, "GuildPanel", GuildSystem.GetPanelSnapshot(player))
		elseif action == "Deposit" then
			local ok, res = GuildSystem.DepositCopper(player, payload.Amount)
			if not ok then
				remote:FireClient(player, "Error", { Message = tostring(res), Action = "Deposit" })
			end
		elseif action == "Withdraw" then
			local ok, res = GuildSystem.WithdrawCopper(player, payload.Amount)
			if not ok then
				remote:FireClient(player, "Error", { Message = tostring(res), Action = "Withdraw" })
			end
		elseif action == "DepositItem" then
			local ok, res = GuildSystem.DepositItem(player, payload.ItemId, payload.Amount or payload.Qty)
			if not ok then
				remote:FireClient(player, "Error", { Message = tostring(res), Action = "DepositItem" })
			end
		elseif action == "WithdrawItem" then
			local ok, res = GuildSystem.WithdrawItem(player, payload.ItemId, payload.Amount or payload.Qty)
			if not ok then
				remote:FireClient(player, "Error", { Message = tostring(res), Action = "WithdrawItem" })
			end
		elseif action == "TransferItemToBank" then
			local ok, res = GuildSystem.TransferItemToBank(player, payload.ItemId, payload.Amount or payload.Qty)
			if not ok then
				remote:FireClient(player, "Error", { Message = tostring(res), Action = "TransferItemToBank" })
			end
		elseif action == "TransferItemFromBank" then
			local ok, res = GuildSystem.TransferItemFromBank(player, payload.ItemId, payload.Amount or payload.Qty)
			if not ok then
				remote:FireClient(player, "Error", { Message = tostring(res), Action = "TransferItemFromBank" })
			end
		elseif action == "TransferCopperToBank" then
			local ok, res = GuildSystem.TransferCopperToBank(player, payload.Amount)
			if not ok then
				remote:FireClient(player, "Error", { Message = tostring(res), Action = "TransferCopperToBank" })
			end
		elseif action == "TransferCopperFromBank" then
			local ok, res = GuildSystem.TransferCopperFromBank(player, payload.Amount)
			if not ok then
				remote:FireClient(player, "Error", { Message = tostring(res), Action = "TransferCopperFromBank" })
			end
		elseif action == "GetWarfare" then
			local info = GuildSystem.GetMembership(player)
			local warfare = info and GuildSystem.GetWarfare(info.Id) or nil
			remote:FireClient(player, "GuildWarfare", warfare or {
				State = "Idle",
				Locked = true,
				WriteLocked = true,
				ParticipantCount = 0,
				Participants = {},
				InMemoryOnly = true,
			})
		elseif action == "DeclareWarfare" then
			local ok, res = GuildSystem.DeclareWarfare(player, payload.TargetGuildId or payload.TargetId)
			if not ok then
				remote:FireClient(player, "Error", { Message = tostring(res), Action = "DeclareWarfare" })
			end
		elseif action == "JoinWarfare" then
			local ok, res = GuildSystem.JoinWarfare(player)
			if not ok then
				remote:FireClient(player, "Error", { Message = tostring(res), Action = "JoinWarfare" })
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		-- Session membership only; do not dissolve guild record (other members may remain)
		membership[player.UserId] = nil
	end)

	Players.PlayerAdded:Connect(function(plr)
		deferRestoreWhenDataReady(plr)
	end)
	for _, plr in ipairs(Players:GetPlayers()) do
		deferRestoreWhenDataReady(plr)
	end

	if RunService:IsStudio() then
		Players.PlayerAdded:Connect(function(plr)
			plr.Chatted:Connect(function(msg)
				local lower = string.lower(msg)
				if lower == "/expansiongate" then
					local ok, ExpansionGate = pcall(function()
						return require(RealmFolder:WaitForChild("ExpansionGate"))
					end)
					if ok and ExpansionGate then
						ExpansionGate.PrintStatus()
					end
					return
				end
				if lower == "/guildleave" then
					GuildSystem.Leave(plr)
				elseif lower == "/guildpanel" or lower == "/guildui" then
					-- Client GuildPanelUI toggles panel; server no-op
					return
				elseif string.sub(lower, 1, 6) == "/guild" then
					if not gateAllowsGuilds() then
						warn("[Guild] blocked - set SSS.RealmOfSpirits.AllowGuilds=true after E1")
						return
					end
					local tag = string.match(msg, "/guild%s+(%S+)") or "ROS"
					local name = string.match(msg, "/guild%s+%S+%s+(.+)") or "Realm Scouts"
					local ok, err = GuildSystem.CreateOrJoin(plr, name, tag)
					if not ok then
						warn("[Guild]", err)
					end
				end
			end)
		end)
	end

	print("Realm of Spirits - GuildSystem W13 inventory↔bank transfer prep (in-memory) loaded")
end

return GuildSystem
