-- GuildSystem (F4 W7): join restore data.Guild → in-memory membership
-- Restore path does NOT require AllowGuilds (continuity / in-memory only)
-- CreateOrJoin remains fail-closed behind ExpansionGate.AllowGuilds
-- SmokeJoinRestoreMock + SmokeGuildRosterMock — no Allow* flip
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
GuildSystem.GuildStoreNameFuture = "RealmOfSpirits_Guilds_v1"
GuildSystem.PlayerGuildKey = "Guild" -- optional schema v1
GuildSystem.RosterSchemaVersion = 1
GuildSystem.SmokeGuildId = "g_w6smoke"
GuildSystem.SmokeRestoreGuildId = "g_w7restore"

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

-- Read-only MVP persistence design (no live DS writes).
function GuildSystem.GetMvpDesign()
	return {
		Phase = "F4-W7-guild-restore",
		DevOnly = true,
		InMemoryOnly = true,
		AllowGuildsRequiredForCreate = true,
		AllowGuildsRequiredForRestore = false,
		PlayerProfileKey = GuildSystem.PlayerGuildKey,
		PlayerShape = { "Id", "Name", "Tag", "Role" },
		RosterShape = { "Id", "Name", "Tag", "LeaderUserId", "Members", "CreatedAt", "SchemaVersion" },
		MemberEntryShape = { "UserId", "Role", "JoinedAt" },
		Roles = { "Leader", "Officer", "Member" },
		MaxNameLen = GuildSystem.MaxNameLen,
		MaxTagLen = GuildSystem.MaxTagLen,
		MaxMembersPerGuild = GuildSystem.MaxMembersPerGuild,
		FutureStoreName = GuildSystem.GuildStoreNameFuture,
		PersistencePlan = {
			"A. Player optional Guild {Id,Name,Tag,Role} — schema v1 locked; no full roster in profile",
			"B. Future DS RealmOfSpirits_Guilds_v1 keyed by guild Id (owner unlock + AllowGuilds)",
			"C. Join = upsert roster record + set player Guild; Leave = remove member / dissolve if empty",
			"D. W6 = in-memory guildsById + membership only (server restart wipes)",
			"E. W7 = restore data.Guild → membership/roster on load (no AllowGuilds); CreateOrJoin still gated",
			"F. No bank / warfare / UI panel in W7",
		},
		Note = "Restore works with gate OFF; CreateOrJoin fail-closed until AllowGuilds",
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
		Phase = "F4-W7-guild-restore",
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
		CreateRequiresAllowGuilds = true,
		ChatCommands = { "/guild", "/guildleave", "/expansiongate" },
		Apis = {
			"GetGuildAudit",
			"GetMvpDesign",
			"GetRoster",
			"GetGuildRecord",
			"RestoreMembershipFromGuildTable",
			"RestoreFromPlayerData",
			"SmokeGuildRosterMock",
			"SmokeJoinRestoreMock",
			"CreateOrJoin",
			"Leave",
		},
		NextSteps = {
			"Keep AllowGuilds=false under dev-only",
			"W8+: optional Leave persist + multi-player roster merge (still gate OFF = no create)",
			"Owner unlock required before live guild DS + AllowGuilds",
		},
		Note = "W7 join restore from data.Guild - CreateOrJoin fail-closed until ExpansionGate.AllowGuilds",
	}
end

local function ensureGuildRecord(id, guildName, tag, leaderUserId)
	local existing = guildsById[id]
	if existing then
		return existing
	end
	local record = {
		Id = id,
		Name = guildName,
		Tag = tag,
		LeaderUserId = leaderUserId,
		Members = {},
		CreatedAt = os.time(),
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

-- Gate-independent restore: upsert in-memory roster/membership from persisted Guild shape.
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
	-- Prefer persisted Name/Tag if record already existed under same Id
	record.Name = parsed.Name
	record.Tag = parsed.Tag
	if parsed.Role == "Leader" or record.LeaderUserId == 0 then
		record.LeaderUserId = uid
	end

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

function GuildSystem.Leave(player)
	local info = membership[player.UserId]
	if info then
		removeMemberFromRecord(info.Id, player.UserId)
	end
	membership[player.UserId] = nil
	player:SetAttribute("GuildTag", nil)
	player:SetAttribute("GuildName", nil)
	player:SetAttribute("GuildRole", nil)
	local data = getData(player)
	if data then
		data.Guild = nil
	end
	remote:FireClient(player, "GuildLeft", {})
	return true
end

-- Studio/dev smoke: in-memory roster without AllowGuilds flip or DataStore.
function GuildSystem.SmokeGuildRosterMock()
	local smokeId = GuildSystem.SmokeGuildId
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
	local createBlocked = not gateAllowsGuilds()
	local createMsg = nil
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

	print("Realm of Spirits - GuildSystem W7 restore (in-memory) loaded")
end

return GuildSystem
