-- GuildSystem (F4 W9): guild UI panel / bank prep (in-memory, gate OFF)
-- Restore + Leave do NOT require AllowGuilds (in-memory session only)
-- CreateOrJoin remains fail-closed behind ExpansionGate.AllowGuilds
-- Bank = empty in-memory shape only — no live guild DS / Allow* flip
-- Start() from OtakuHavenService / GameManager after DataStore ready

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GuildSystem = {}
GuildSystem._started = false

-- Design constants (MVP; live DS deferred under dev-only)
GuildSystem.MaxNameLen = 24
GuildSystem.MaxTagLen = 4
GuildSystem.MaxMembersPerGuild = 20
GuildSystem.MaxBankSlots = 20
GuildSystem.GuildStoreNameFuture = "RealmOfSpirits_Guilds_v1"
GuildSystem.PlayerGuildKey = "Guild" -- optional schema v1
GuildSystem.RosterSchemaVersion = 1
GuildSystem.BankSchemaVersion = 1
GuildSystem.SmokeGuildId = "g_w6smoke"
GuildSystem.SmokeRestoreGuildId = "g_w7restore"
GuildSystem.SmokeLeaveGuildId = "g_w8leave"
GuildSystem.SmokeMergeGuildId = "g_w8merge"
GuildSystem.SmokeBankGuildId = "g_w9bank"

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

local function ensureBank(record)
	if type(record.Bank) ~= "table" then
		record.Bank = emptyBank()
	end
	if type(record.Bank.Items) ~= "table" then
		record.Bank.Items = {}
	end
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

-- In-memory bank snapshot (empty / locked). No deposit/withdraw until AllowGuilds + DS.
function GuildSystem.GetBank(guildId)
	local record = guildsById[guildId]
	if not record then
		return nil
	end
	local bank = ensureBank(record)
	local itemCount = 0
	for _ in pairs(bank.Items) do
		itemCount += 1
	end
	return {
		Copper = bank.Copper,
		ItemCount = itemCount,
		Items = bank.Items,
		MaxSlots = bank.MaxSlots,
		SchemaVersion = bank.SchemaVersion,
		Locked = bank.Locked == true,
		InMemoryOnly = true,
	}
end

function GuildSystem.GetBankAudit()
	local bankGuildCount = 0
	local totalItems = 0
	for _, record in pairs(guildsById) do
		local bank = ensureBank(record)
		bankGuildCount += 1
		for _ in pairs(bank.Items) do
			totalItems += 1
		end
	end
	return {
		Phase = "F4-W9-guild-ui-bank",
		DevOnly = true,
		GateAllows = gateAllowsGuilds(),
		AllowGuildsAttr = allowGuildsAttr(),
		InMemoryOnly = true,
		LiveBankWrites = false,
		BankSchemaVersion = GuildSystem.BankSchemaVersion,
		MaxBankSlots = GuildSystem.MaxBankSlots,
		BankShape = { "Copper", "Items", "MaxSlots", "SchemaVersion", "Locked" },
		GuildsWithBank = bankGuildCount,
		TotalBankItems = totalItems,
		Note = "Bank prep only — empty in-memory table; no AllowGuilds / guild DS",
	}
end

-- Client panel snapshot: membership + roster + bank (fail-closed create still gated).
function GuildSystem.GetPanelSnapshot(player)
	local info = GuildSystem.GetMembership(player)
	local gateOk = gateAllowsGuilds()
	if not info then
		return {
			HasMembership = false,
			GateAllows = gateOk,
			CreateBlocked = not gateOk,
			LockedMessage = if gateOk
				then "Нет гильдии — вступите через /guild (когда открыто)"
				else "Гильдии закрыты (ExpansionGate / dev-only)",
			Roster = {},
			Bank = nil,
		}
	end
	local roster = GuildSystem.GetRoster(info.Id) or {}
	local bank = GuildSystem.GetBank(info.Id)
	return {
		HasMembership = true,
		GateAllows = gateOk,
		CreateBlocked = not gateOk,
		Membership = info,
		Roster = roster,
		Bank = bank,
		LockedMessage = nil,
	}
end

-- Read-only MVP persistence design (no live DS writes).
function GuildSystem.GetMvpDesign()
	return {
		Phase = "F4-W9-guild-ui-bank",
		DevOnly = true,
		InMemoryOnly = true,
		AllowGuildsRequiredForCreate = true,
		AllowGuildsRequiredForRestore = false,
		AllowGuildsRequiredForLeave = false,
		AllowGuildsRequiredForBankWrite = true,
		PlayerProfileKey = GuildSystem.PlayerGuildKey,
		PlayerShape = { "Id", "Name", "Tag", "Role" },
		RosterShape = { "Id", "Name", "Tag", "LeaderUserId", "Members", "CreatedAt", "SchemaVersion", "Bank" },
		MemberEntryShape = { "UserId", "Role", "JoinedAt" },
		BankShape = { "Copper", "Items", "MaxSlots", "SchemaVersion", "Locked" },
		Roles = { "Leader", "Officer", "Member" },
		MaxNameLen = GuildSystem.MaxNameLen,
		MaxTagLen = GuildSystem.MaxTagLen,
		MaxMembersPerGuild = GuildSystem.MaxMembersPerGuild,
		MaxBankSlots = GuildSystem.MaxBankSlots,
		FutureStoreName = GuildSystem.GuildStoreNameFuture,
		PersistencePlan = {
			"A. Player optional Guild {Id,Name,Tag,Role} — schema v1 locked; no full roster in profile",
			"B. Future DS RealmOfSpirits_Guilds_v1 keyed by guild Id (owner unlock + AllowGuilds)",
			"C. Join = upsert roster record + set player Guild; Leave = remove member / dissolve if empty",
			"D. W6 = in-memory guildsById + membership only (server restart wipes)",
			"E. W7 = restore data.Guild → membership/roster on load (no AllowGuilds); CreateOrJoin still gated",
			"F. W8 = Leave clears data.Guild + membership; same guild Id restores merge roster",
			"G. W9 = GuildPanelUI + empty Bank on guild record (in-memory, Locked=true); no live bank DS",
		},
		Note = "Restore/Leave/UI read work with gate OFF; CreateOrJoin + bank writes fail-closed until AllowGuilds",
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
		Phase = "F4-W9-guild-ui-bank",
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
		UiPanel = "GuildPanelUI",
		ChatCommands = { "/guild", "/guildleave", "/guildpanel", "/expansiongate" },
		Apis = {
			"GetGuildAudit",
			"GetMvpDesign",
			"GetRoster",
			"GetGuildRecord",
			"GetBank",
			"GetBankAudit",
			"GetPanelSnapshot",
			"RestoreMembershipFromGuildTable",
			"RestoreFromPlayerData",
			"ClearGuildMembership",
			"SmokeGuildRosterMock",
			"SmokeJoinRestoreMock",
			"SmokeGuildLeaveMock",
			"SmokeRosterMergeMock",
			"SmokeGuildBankMock",
			"SmokeGuildPanelPrepMock",
			"CreateOrJoin",
			"Leave",
		},
		NextSteps = {
			"Keep AllowGuilds=false under dev-only",
			"W10+: bank deposit/withdraw + warfare (owner unlock + AllowGuilds for live DS)",
			"Owner unlock required before live guild DS + AllowGuilds",
		},
		Note = "W9 UI panel + bank prep — CreateOrJoin fail-closed until ExpansionGate.AllowGuilds",
	}
end

local function ensureGuildRecord(id, guildName, tag, leaderUserId)
	local existing = guildsById[id]
	if existing then
		ensureBank(existing)
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

	-- No membership → locked message (smoke stub only needs UserId)
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

	print("Realm of Spirits - GuildSystem W9 UI+bank prep (in-memory) loaded")
end

return GuildSystem
