--!strict
-- RatedPvPSystem (F4 W14–W18): rated PvP track — prep -> ladder -> MM -> season -> wrap
-- Gate: ExpansionGate.AllowNewPvPFeatures (same as PvPDuelSystem.pvpExtraAllowed)
-- Live APIs Locked until gate ON; QA via Smoke*Mock only
-- Phase: F4-W18-wrap · AllowNewPvPFeatures=false · no Publish
-- Mirror: docs/realm-of-spirits/studio/RatedPvPSystem.lua
-- Client: StarterPlayerScripts.RatedPvPPanelUI (P / /ratedpanel, read-only)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RatedPvPSystem = {}
RatedPvPSystem._started = false

RatedPvPSystem.DefaultRating = 1000
RatedPvPSystem.RatingSchemaVersion = 1
RatedPvPSystem.SeasonIdStub = "S0-dev"
RatedPvPSystem.KFactorStub = 32
RatedPvPSystem.SmokeUserA = 900002001
RatedPvPSystem.SmokeUserB = 900002002
RatedPvPSystem.SmokeUserC = 900002003
RatedPvPSystem.FutureStoreName = "RealmOfSpirits_RatedPvP_v1"
RatedPvPSystem.LadderMaxEntries = 50
RatedPvPSystem.QueueMaxStub = 64
RatedPvPSystem.PartyMaxStub = 2
RatedPvPSystem.Phase = "F4-W18-wrap"

export type RatingRecord = {
	UserId: number,
	Rating: number,
	Wins: number,
	Losses: number,
	SeasonId: string,
	Locked: boolean,
	SchemaVersion: number,
	Rank: number?,
}

export type QueueEntry = {
	UserId: number,
	EnqueuedAt: number,
	PartyId: string?,
}

local RealmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local remoteInst = RealmFolder:FindFirstChild("RatedPvP")
local remote: RemoteEvent
if remoteInst and remoteInst:IsA("RemoteEvent") then
	remote = remoteInst :: RemoteEvent
else
	if remoteInst then
		remoteInst:Destroy()
	end
	local created = Instance.new("RemoteEvent")
	created.Name = "RatedPvP"
	created.Parent = RealmFolder
	remote = created
end

local ratingsByUserId: { [number]: RatingRecord } = {}
local matchesById: { [string]: any } = {}
local nextMatchId = 1
local queueByUserId: { [number]: QueueEntry } = {}
local partiesById: { [string]: { LeaderUserId: number, Members: { number } } } = {}
local nextPartyId = 1

local function gateAllowsRated(): boolean
	local okGate, ExpansionGate = pcall(function()
		return require(RealmFolder:WaitForChild("ExpansionGate", 5))
	end)
	if not okGate or not ExpansionGate then
		return false
	end
	if type(ExpansionGate.RefreshFromAttributes) == "function" then
		ExpansionGate.RefreshFromAttributes()
	end
	return ExpansionGate.AllowNewPvPFeatures == true
end

local function allowRatedAttr(): boolean
	return gateAllowsRated()
end

local function emptyRating(userId: number): RatingRecord
	return {
		UserId = userId,
		Rating = RatedPvPSystem.DefaultRating,
		Wins = 0,
		Losses = 0,
		SeasonId = RatedPvPSystem.SeasonIdStub,
		Locked = true,
		SchemaVersion = RatedPvPSystem.RatingSchemaVersion,
		Rank = nil,
	}
end

local function ensureRating(userId: number): RatingRecord
	local existing = ratingsByUserId[userId]
	if existing then
		if existing.Locked == nil then
			existing.Locked = true
		end
		return existing
	end
	local rec = emptyRating(userId)
	ratingsByUserId[userId] = rec
	return rec
end

local function snapshotRating(rec: RatingRecord): any
	return {
		UserId = rec.UserId,
		Rating = rec.Rating,
		Wins = rec.Wins,
		Losses = rec.Losses,
		SeasonId = rec.SeasonId,
		Rank = rec.Rank,
		Locked = rec.Locked == true,
		WriteLocked = rec.Locked == true or not gateAllowsRated(),
		SchemaVersion = rec.SchemaVersion,
	}
end

function RatedPvPSystem.GetRating(userId: number): any?
	if type(userId) ~= "number" then
		return nil
	end
	return snapshotRating(ensureRating(userId))
end

function RatedPvPSystem.GetRatingSchema(): any
	return {
		Fields = { "UserId", "Rating", "Wins", "Losses", "SeasonId", "Rank", "Locked", "SchemaVersion" },
		DefaultRating = RatedPvPSystem.DefaultRating,
		SeasonIdStub = RatedPvPSystem.SeasonIdStub,
		SchemaVersion = RatedPvPSystem.RatingSchemaVersion,
		FutureStore = RatedPvPSystem.FutureStoreName,
		Note = "Optional player save key deferred — schema v1 locked; in-memory only under F4 rated track",
	}
end

function RatedPvPSystem.DeclareRated(player: any, targetUserId: any): (boolean, string)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		if type(player) ~= "table" or type(player.UserId) ~= "number" then
			return false, "BadPlayer"
		end
	end
	local uid = (player :: any).UserId
	if type(uid) ~= "number" then
		return false, "BadPlayer"
	end
	local target = tonumber(targetUserId)
	if target == nil or target <= 0 then
		return false, "BadTarget"
	end
	if target == uid then
		return false, "SelfTarget"
	end
	if not gateAllowsRated() then
		return false, "Locked"
	end
	local rec = ensureRating(uid)
	if rec.Locked then
		return false, "Locked"
	end
	return false, "NotImplemented"
end

function RatedPvPSystem.MatchRated(player: any, opponentUserId: any): (boolean, string)
	if type(player) ~= "table" and (typeof(player) ~= "Instance" or not (player :: any):IsA("Player")) then
		return false, "BadPlayer"
	end
	local uid = (player :: any).UserId
	if type(uid) ~= "number" then
		return false, "BadPlayer"
	end
	local opp = tonumber(opponentUserId)
	if opp == nil or opp <= 0 then
		return false, "BadOpponent"
	end
	if opp == uid then
		return false, "SelfTarget"
	end
	if not gateAllowsRated() then
		return false, "Locked"
	end
	local rec = ensureRating(uid)
	if rec.Locked then
		return false, "Locked"
	end
	return false, "NotImplemented"
end

local function applyRatedMatch(winnerId: number, loserId: number): (boolean, any?, string?)
	if winnerId == loserId then
		return false, nil, "SelfTarget"
	end
	local w = ensureRating(winnerId)
	local l = ensureRating(loserId)
	local k = RatedPvPSystem.KFactorStub
	local expectedW = 1 / (1 + 10 ^ ((l.Rating - w.Rating) / 400))
	local delta = math.floor(k * (1 - expectedW) + 0.5)
	if delta < 1 then
		delta = 1
	end
	w.Rating += delta
	w.Wins += 1
	l.Rating = math.max(100, l.Rating - delta)
	l.Losses += 1
	local matchId = string.format("m_rated_%d", nextMatchId)
	nextMatchId += 1
	local match = {
		Id = matchId,
		WinnerId = winnerId,
		LoserId = loserId,
		Delta = delta,
		SeasonId = RatedPvPSystem.SeasonIdStub,
		InMemoryOnly = true,
	}
	matchesById[matchId] = match
	return true, match, nil
end

local function recomputeRanks()
	local list: { RatingRecord } = {}
	for _, rec in pairs(ratingsByUserId) do
		table.insert(list, rec)
	end
	table.sort(list, function(a, b)
		if a.Rating == b.Rating then
			return a.UserId < b.UserId
		end
		return a.Rating > b.Rating
	end)
	for i, rec in ipairs(list) do
		rec.Rank = i
	end
	return list
end

function RatedPvPSystem.GetLadder(limit: number?): any
	local maxN = math.clamp(tonumber(limit) or 20, 1, RatedPvPSystem.LadderMaxEntries)
	local sorted = recomputeRanks()
	local rows = {}
	for i = 1, math.min(maxN, #sorted) do
		local rec = sorted[i]
		table.insert(rows, {
			Rank = i,
			UserId = rec.UserId,
			Rating = rec.Rating,
			Wins = rec.Wins,
			Losses = rec.Losses,
			SeasonId = rec.SeasonId,
			WriteLocked = true,
		})
	end
	return {
		SeasonId = RatedPvPSystem.SeasonIdStub,
		Count = #rows,
		Entries = rows,
		Locked = true,
		WriteLocked = true,
		InMemoryOnly = true,
		GateAllows = gateAllowsRated(),
	}
end

function RatedPvPSystem.GetLadderAudit(): any
	local ladder = RatedPvPSystem.GetLadder(10)
	return {
		Phase = RatedPvPSystem.Phase,
		LadderPrep = true,
		LiveLadderWrites = false,
		LiveRankWritesFailClosed = true,
		InMemoryOnly = true,
		GateAllows = gateAllowsRated(),
		AllowNewPvPFeatures = allowRatedAttr(),
		SampleCount = ladder.Count,
		SeasonIdStub = RatedPvPSystem.SeasonIdStub,
		Note = "W15 ladder — in-memory ranks; live rank writes Locked",
	}
end

-- Live rank mutate fail-closed
function RatedPvPSystem.SetRank(player: any, newRating: any): (boolean, string)
	if type(player) ~= "table" and (typeof(player) ~= "Instance" or not (player :: any):IsA("Player")) then
		return false, "BadPlayer"
	end
	local uid = (player :: any).UserId
	if type(uid) ~= "number" then
		return false, "BadPlayer"
	end
	local rating = tonumber(newRating)
	if rating == nil or rating < 100 or rating > 5000 then
		return false, "BadRating"
	end
	if not gateAllowsRated() then
		return false, "Locked"
	end
	local rec = ensureRating(uid)
	if rec.Locked then
		return false, "Locked"
	end
	return false, "NotImplemented"
end

function RatedPvPSystem.GetPanelSnapshot(player: any): any
	local uid = if type(player) == "table" or typeof(player) == "Instance" then (player :: any).UserId else nil
	local rating = if type(uid) == "number" then RatedPvPSystem.GetRating(uid) else nil
	local ladder = RatedPvPSystem.GetLadder(5)
	return {
		HasRating = rating ~= nil,
		Rating = rating,
		LadderTop = ladder.Entries,
		GateAllows = gateAllowsRated(),
		WriteLocked = true,
		MatchmakingLocked = true,
		SeasonId = RatedPvPSystem.SeasonIdStub,
		LockedMessage = if gateAllowsRated()
			then "Rated live deferred"
			else "Rated PvP закрыт (ExpansionGate / dev-only)",
		Phase = RatedPvPSystem.Phase,
	}
end

-- W16 matchmaking — live fail-closed
function RatedPvPSystem.Enqueue(player: any): (boolean, string)
	if type(player) ~= "table" and (typeof(player) ~= "Instance" or not (player :: any):IsA("Player")) then
		return false, "BadPlayer"
	end
	local uid = (player :: any).UserId
	if type(uid) ~= "number" then
		return false, "BadPlayer"
	end
	if not gateAllowsRated() then
		return false, "Locked"
	end
	return false, "NotImplemented"
end

function RatedPvPSystem.Dequeue(player: any): (boolean, string)
	if type(player) ~= "table" and (typeof(player) ~= "Instance" or not (player :: any):IsA("Player")) then
		return false, "BadPlayer"
	end
	local uid = (player :: any).UserId
	if type(uid) ~= "number" then
		return false, "BadPlayer"
	end
	if not gateAllowsRated() then
		return false, "Locked"
	end
	return false, "NotImplemented"
end

function RatedPvPSystem.PartyInvite(player: any, targetUserId: any): (boolean, string)
	if type(player) ~= "table" and (typeof(player) ~= "Instance" or not (player :: any):IsA("Player")) then
		return false, "BadPlayer"
	end
	local uid = (player :: any).UserId
	if type(uid) ~= "number" then
		return false, "BadPlayer"
	end
	local target = tonumber(targetUserId)
	if target == nil or target <= 0 then
		return false, "BadTarget"
	end
	if target == uid then
		return false, "SelfTarget"
	end
	if not gateAllowsRated() then
		return false, "Locked"
	end
	return false, "NotImplemented"
end

local function applyEnqueue(userId: number, partyId: string?): (boolean, string?)
	if queueByUserId[userId] then
		return false, "AlreadyQueued"
	end
	local count = 0
	for _ in pairs(queueByUserId) do
		count += 1
	end
	if count >= RatedPvPSystem.QueueMaxStub then
		return false, "QueueFull"
	end
	queueByUserId[userId] = {
		UserId = userId,
		EnqueuedAt = os.time(),
		PartyId = partyId,
	}
	return true, nil
end

local function applyDequeue(userId: number): boolean
	if queueByUserId[userId] == nil then
		return false
	end
	queueByUserId[userId] = nil
	return true
end

local function applyPartyInvite(leaderId: number, memberId: number): (boolean, string?, string?)
	if leaderId == memberId then
		return false, "SelfTarget", nil
	end
	local partyId = string.format("p_mm_%d", nextPartyId)
	nextPartyId += 1
	partiesById[partyId] = {
		LeaderUserId = leaderId,
		Members = { leaderId, memberId },
	}
	return true, nil, partyId
end

function RatedPvPSystem.GetQueueSnapshot(): any
	local entries = {}
	for _, e in pairs(queueByUserId) do
		table.insert(entries, {
			UserId = e.UserId,
			EnqueuedAt = e.EnqueuedAt,
			PartyId = e.PartyId,
		})
	end
	local partyCount = 0
	for _ in pairs(partiesById) do
		partyCount += 1
	end
	return {
		Count = #entries,
		Entries = entries,
		PartyCount = partyCount,
		Locked = true,
		WriteLocked = true,
		InMemoryOnly = true,
		GateAllows = gateAllowsRated(),
	}
end

function RatedPvPSystem.GetMatchmakingAudit(): any
	local q = RatedPvPSystem.GetQueueSnapshot()
	return {
		Phase = RatedPvPSystem.Phase,
		MatchmakingPrep = true,
		LiveQueueFailClosed = true,
		LivePartyFailClosed = true,
		LiveMatchmaking = false,
		QueueCount = q.Count,
		PartyCount = q.PartyCount,
		GateAllows = gateAllowsRated(),
		AllowNewPvPFeatures = allowRatedAttr(),
		Note = "W16 matchmaking stub — Enqueue/Dequeue/PartyInvite Locked; SmokeMatchmakingMock only",
	}
end

-- W17 season / meta
function RatedPvPSystem.GetSeasonAudit(): any
	return {
		Phase = RatedPvPSystem.Phase,
		SeasonId = RatedPvPSystem.SeasonIdStub,
		LiveSeasons = false,
		SeasonPrep = true,
		SoftResetPlan = {
			"Keep AllowNewPvPFeatures=false until owner unlock",
			"On season flip: snapshot ladder -> archive · reset Rating to DefaultRating · keep Wins/Losses optional wipe",
			"Bump SeasonId (S0-dev -> S1) only after owner + schema note",
			"No live reward grant / pool swap in W17",
		},
		MetaRotationNote = "Fair duel pool unchanged; rated meta deferred — no SkillCatalog swap",
		GateAllows = gateAllowsRated(),
		AllowNewPvPFeatures = allowRatedAttr(),
		DefaultRating = RatedPvPSystem.DefaultRating,
		Note = "W17 season stub — audit only; no live season flip",
	}
end

function RatedPvPSystem.StartSeason(_seasonId: any): (boolean, string)
	if not gateAllowsRated() then
		return false, "Locked"
	end
	return false, "NotImplemented"
end

-- W18 wrap audit
function RatedPvPSystem.GetWrapAudit(): any
	return {
		Phase = "F4-W18-wrap",
		DevOnly = true,
		NumberedTrack = "F4-W1..W18",
		ExitChecklist = {
			"W1–W4 ProfileService prep (gates OFF)",
			"W5–W13 Guild MVP bank/warfare/transfer (AllowGuilds=false)",
			"W14 Rated schema + Declare/Match Locked + SmokeRatedPvPMock",
			"W15 Ladder in-memory + GetLadderAudit + panel read-only",
			"W16 Matchmaking queue/party stub + SmokeMatchmakingMock",
			"W17 SeasonId + soft-reset plan + GetSeasonAudit",
			"W18 Wrap docs + backlog map + NEXT post-W18",
		},
		BacklogMap = {
			LiveGuildDS = "owner unlock + AllowGuilds",
			ProfileServiceCutover = "owner unlock + W4 FlipChecklist",
			B1PvPSlice3 = "named backlog / owner call",
			OnlineAiMesh = "AllowAiMeshOnline",
			HavenDecorPhase2 = "explicit owner command",
			LiveRatedSeasons = "AllowNewPvPFeatures + season flip",
		},
		GateAllows = gateAllowsRated(),
		AllowNewPvPFeatures = allowRatedAttr(),
		WrapComplete = true,
		Note = "Phase 4 numbered track closed under dev-only; live cutover still owner unlock",
	}
end

function RatedPvPSystem.GetRatedAudit(): any
	local count = 0
	for _ in pairs(ratingsByUserId) do
		count += 1
	end
	local matchCount = 0
	for _ in pairs(matchesById) do
		matchCount += 1
	end
	local q = RatedPvPSystem.GetQueueSnapshot()
	return {
		Phase = RatedPvPSystem.Phase,
		DevOnly = true,
		GateAllows = gateAllowsRated(),
		AllowNewPvPFeatures = allowRatedAttr(),
		InMemoryRatingCount = count,
		InMemoryMatchCount = matchCount,
		QueueCount = q.Count,
		RemoteName = remote.Name,
		DefaultRating = RatedPvPSystem.DefaultRating,
		SeasonIdStub = RatedPvPSystem.SeasonIdStub,
		RatingSchemaVersion = RatedPvPSystem.RatingSchemaVersion,
		FutureStoreName = RatedPvPSystem.FutureStoreName,
		LiveDeclareMatchFailClosed = true,
		LiveLadderWritesFailClosed = true,
		LiveMatchmakingFailClosed = true,
		LiveSeasons = false,
		RatedPrep = true,
		LadderPrep = true,
		MatchmakingPrep = true,
		SeasonPrep = true,
		WrapComplete = true,
		LiveRatedWrites = false,
		UiPanel = "RatedPvPPanelUI",
		Apis = {
			"GetRatedAudit",
			"GetRating",
			"GetRatingSchema",
			"DeclareRated",
			"MatchRated",
			"GetLadder",
			"GetLadderAudit",
			"SetRank",
			"GetPanelSnapshot",
			"Enqueue",
			"Dequeue",
			"PartyInvite",
			"GetQueueSnapshot",
			"GetMatchmakingAudit",
			"GetSeasonAudit",
			"StartSeason",
			"GetWrapAudit",
			"SmokeRatedPvPMock",
			"SmokeLadderMock",
			"SmokeMatchmakingMock",
			"SmokeSeasonMock",
			"SmokeWrapMock",
		},
		NextSteps = {
			"Keep AllowNewPvPFeatures=false under dev-only",
			"Post-W18: owner unlock OR named backlog (Guild DS / PS / B1 / mesh)",
		},
		Note = "F4 W14–W18 rated track — live APIs Locked; Smoke*Mock QA only",
	}
end

function RatedPvPSystem.SmokeRatedPvPMock(): any
	ratingsByUserId[RatedPvPSystem.SmokeUserA] = nil
	ratingsByUserId[RatedPvPSystem.SmokeUserB] = nil
	for id in pairs(matchesById) do
		if string.sub(id, 1, 8) == "m_rated_" or string.sub(id, 1, 6) == "m_w14_" then
			matchesById[id] = nil
		end
	end

	local fakeA = { UserId = RatedPvPSystem.SmokeUserA }
	local okDec, decErr = RatedPvPSystem.DeclareRated(fakeA, RatedPvPSystem.SmokeUserB)
	local liveDeclareBlocked = okDec == false and decErr == "Locked"
	local okMatch, matchErr = RatedPvPSystem.MatchRated(fakeA, RatedPvPSystem.SmokeUserB)
	local liveMatchBlocked = okMatch == false and matchErr == "Locked"
	local okSelf, selfErr = RatedPvPSystem.DeclareRated(fakeA, RatedPvPSystem.SmokeUserA)
	local selfBlocked = okSelf == false and selfErr == "SelfTarget"
	local okApply, matchRec = applyRatedMatch(RatedPvPSystem.SmokeUserA, RatedPvPSystem.SmokeUserB)
	local a = RatedPvPSystem.GetRating(RatedPvPSystem.SmokeUserA)
	local b = RatedPvPSystem.GetRating(RatedPvPSystem.SmokeUserB)
	local schema = RatedPvPSystem.GetRatingSchema()
	local audit = RatedPvPSystem.GetRatedAudit()

	local ratingOk = a ~= nil
		and b ~= nil
		and a.Rating > RatedPvPSystem.DefaultRating
		and b.Rating < RatedPvPSystem.DefaultRating
		and a.Wins == 1
		and b.Losses == 1
		and a.Locked == true
		and a.WriteLocked == true

	local success = liveDeclareBlocked
		and liveMatchBlocked
		and selfBlocked
		and okApply
		and matchRec ~= nil
		and ratingOk
		and audit.GateAllows == false
		and schema.SchemaVersion == 1

	return {
		Success = success,
		LiveDeclareBlocked = liveDeclareBlocked,
		LiveMatchBlocked = liveMatchBlocked,
		LiveDeclareError = decErr,
		LiveMatchError = matchErr,
		SelfTargetBlocked = selfBlocked,
		WinnerRating = a and a.Rating or nil,
		LoserRating = b and b.Rating or nil,
		WinnerWins = a and a.Wins or nil,
		LoserLosses = b and b.Losses or nil,
		MatchDelta = matchRec and matchRec.Delta or nil,
		WriteLocked = a and a.WriteLocked or nil,
		GateAllows = audit.GateAllows,
		AllowNewPvPFeatures = audit.AllowNewPvPFeatures,
		Phase = audit.Phase,
		RatedPrep = audit.RatedPrep == true,
		InMemoryOnly = true,
	}
end

function RatedPvPSystem.SmokeLadderMock(): any
	ratingsByUserId[RatedPvPSystem.SmokeUserA] = nil
	ratingsByUserId[RatedPvPSystem.SmokeUserB] = nil
	ratingsByUserId[RatedPvPSystem.SmokeUserC] = nil
	applyRatedMatch(RatedPvPSystem.SmokeUserA, RatedPvPSystem.SmokeUserB)
	applyRatedMatch(RatedPvPSystem.SmokeUserA, RatedPvPSystem.SmokeUserC)
	local fake = { UserId = RatedPvPSystem.SmokeUserA }
	local okSet, setErr = RatedPvPSystem.SetRank(fake, 1500)
	local liveRankBlocked = okSet == false and setErr == "Locked"
	local ladder = RatedPvPSystem.GetLadder(10)
	local audit = RatedPvPSystem.GetLadderAudit()
	local panel = RatedPvPSystem.GetPanelSnapshot(fake)
	local top = ladder.Entries[1]
	local success = liveRankBlocked
		and ladder.Count >= 3
		and top ~= nil
		and top.UserId == RatedPvPSystem.SmokeUserA
		and top.Rank == 1
		and ladder.WriteLocked == true
		and audit.GateAllows == false
		and panel.WriteLocked == true

	return {
		Success = success,
		LiveRankBlocked = liveRankBlocked,
		LiveRankError = setErr,
		LadderCount = ladder.Count,
		TopUserId = top and top.UserId or nil,
		TopRank = top and top.Rank or nil,
		TopRating = top and top.Rating or nil,
		WriteLocked = ladder.WriteLocked,
		PanelWriteLocked = panel.WriteLocked,
		GateAllows = audit.GateAllows,
		Phase = audit.Phase,
		LadderPrep = audit.LadderPrep == true,
		InMemoryOnly = true,
	}
end

function RatedPvPSystem.SmokeMatchmakingMock(): any
	queueByUserId = {}
	partiesById = {}
	local fakeA = { UserId = RatedPvPSystem.SmokeUserA }
	local fakeB = { UserId = RatedPvPSystem.SmokeUserB }
	local okEnq, enqErr = RatedPvPSystem.Enqueue(fakeA)
	local liveEnqueueBlocked = okEnq == false and enqErr == "Locked"
	local okDeq, deqErr = RatedPvPSystem.Dequeue(fakeA)
	local liveDequeueBlocked = okDeq == false and deqErr == "Locked"
	local okParty, partyErr = RatedPvPSystem.PartyInvite(fakeA, RatedPvPSystem.SmokeUserB)
	local livePartyBlocked = okParty == false and partyErr == "Locked"
	local okSelf, selfErr = RatedPvPSystem.PartyInvite(fakeA, RatedPvPSystem.SmokeUserA)
	local selfBlocked = okSelf == false and selfErr == "SelfTarget"
	local okPartyMem, _, partyId = applyPartyInvite(RatedPvPSystem.SmokeUserA, RatedPvPSystem.SmokeUserB)
	local okQ1 = applyEnqueue(RatedPvPSystem.SmokeUserA, partyId)
	local okQ2 = applyEnqueue(RatedPvPSystem.SmokeUserB, partyId)
	local snap = RatedPvPSystem.GetQueueSnapshot()
	local audit = RatedPvPSystem.GetMatchmakingAudit()
	local okDup, dupErr = applyEnqueue(RatedPvPSystem.SmokeUserA, partyId)
	local dupBlocked = okDup == false and dupErr == "AlreadyQueued"

	local success = liveEnqueueBlocked
		and liveDequeueBlocked
		and livePartyBlocked
		and selfBlocked
		and okPartyMem
		and okQ1
		and okQ2
		and snap.Count == 2
		and snap.PartyCount == 1
		and dupBlocked
		and audit.GateAllows == false

	return {
		Success = success,
		LiveEnqueueBlocked = liveEnqueueBlocked,
		LiveDequeueBlocked = liveDequeueBlocked,
		LivePartyBlocked = livePartyBlocked,
		SelfTargetBlocked = selfBlocked,
		AlreadyQueuedBlocked = dupBlocked,
		QueueCount = snap.Count,
		PartyCount = snap.PartyCount,
		PartyId = partyId,
		GateAllows = audit.GateAllows,
		Phase = audit.Phase,
		MatchmakingPrep = audit.MatchmakingPrep == true,
		InMemoryOnly = true,
		LiveEnqueueError = enqErr,
		LiveDequeueError = deqErr,
		LivePartyError = partyErr,
	}
end

function RatedPvPSystem.SmokeSeasonMock(): any
	local okStart, startErr = RatedPvPSystem.StartSeason("S1")
	local liveSeasonBlocked = okStart == false and startErr == "Locked"
	local audit = RatedPvPSystem.GetSeasonAudit()
	local planOk = type(audit.SoftResetPlan) == "table" and #audit.SoftResetPlan >= 3
	local success = liveSeasonBlocked
		and audit.SeasonId == RatedPvPSystem.SeasonIdStub
		and audit.LiveSeasons == false
		and audit.SeasonPrep == true
		and planOk
		and audit.GateAllows == false

	return {
		Success = success,
		LiveSeasonBlocked = liveSeasonBlocked,
		LiveSeasonError = startErr,
		SeasonId = audit.SeasonId,
		LiveSeasons = audit.LiveSeasons,
		SoftResetPlanCount = if type(audit.SoftResetPlan) == "table" then #audit.SoftResetPlan else 0,
		GateAllows = audit.GateAllows,
		Phase = audit.Phase,
		SeasonPrep = audit.SeasonPrep == true,
	}
end

function RatedPvPSystem.SmokeWrapMock(): any
	local wrap = RatedPvPSystem.GetWrapAudit()
	local rated = RatedPvPSystem.SmokeRatedPvPMock()
	local ladder = RatedPvPSystem.SmokeLadderMock()
	local mm = RatedPvPSystem.SmokeMatchmakingMock()
	local season = RatedPvPSystem.SmokeSeasonMock()
	local success = wrap.WrapComplete == true
		and wrap.Phase == "F4-W18-wrap"
		and type(wrap.ExitChecklist) == "table"
		and #wrap.ExitChecklist >= 7
		and type(wrap.BacklogMap) == "table"
		and rated.Success == true
		and ladder.Success == true
		and mm.Success == true
		and season.Success == true
		and wrap.GateAllows == false

	return {
		Success = success,
		WrapComplete = wrap.WrapComplete,
		ChecklistCount = if type(wrap.ExitChecklist) == "table" then #wrap.ExitChecklist else 0,
		BacklogKeys = if type(wrap.BacklogMap) == "table" then {
			"LiveGuildDS",
			"ProfileServiceCutover",
			"B1PvPSlice3",
			"OnlineAiMesh",
			"HavenDecorPhase2",
			"LiveRatedSeasons",
		} else {},
		RatedOk = rated.Success,
		LadderOk = ladder.Success,
		MatchmakingOk = mm.Success,
		SeasonOk = season.Success,
		GateAllows = wrap.GateAllows,
		Phase = wrap.Phase,
	}
end

local function onRemote(player: Player, action: any, payload: any)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return
	end
	if type(action) ~= "string" then
		return
	end
	if action == "GetRating" then
		remote:FireClient(player, "Rating", RatedPvPSystem.GetRating(player.UserId))
		return
	end
	if action == "GetLadder" then
		local limit = if type(payload) == "table" then payload.Limit else payload
		remote:FireClient(player, "Ladder", RatedPvPSystem.GetLadder(limit))
		return
	end
	if action == "GetPanel" then
		remote:FireClient(player, "Panel", RatedPvPSystem.GetPanelSnapshot(player))
		return
	end
	if action == "GetAudit" then
		remote:FireClient(player, "Audit", RatedPvPSystem.GetRatedAudit())
		return
	end
	if action == "GetSeason" then
		remote:FireClient(player, "Season", RatedPvPSystem.GetSeasonAudit())
		return
	end
	if action == "DeclareRated" then
		local targetId = if type(payload) == "table" then payload.TargetUserId else payload
		local ok, err = RatedPvPSystem.DeclareRated(player, targetId)
		remote:FireClient(player, "DeclareResult", { Ok = ok, Error = err })
		return
	end
	if action == "MatchRated" then
		local oppId = if type(payload) == "table" then payload.OpponentUserId else payload
		local ok, err = RatedPvPSystem.MatchRated(player, oppId)
		remote:FireClient(player, "MatchResult", { Ok = ok, Error = err })
		return
	end
	if action == "Enqueue" then
		local ok, err = RatedPvPSystem.Enqueue(player)
		remote:FireClient(player, "EnqueueResult", { Ok = ok, Error = err })
		return
	end
	if action == "Dequeue" then
		local ok, err = RatedPvPSystem.Dequeue(player)
		remote:FireClient(player, "DequeueResult", { Ok = ok, Error = err })
		return
	end
	if action == "PartyInvite" then
		local targetId = if type(payload) == "table" then payload.TargetUserId else payload
		local ok, err = RatedPvPSystem.PartyInvite(player, targetId)
		remote:FireClient(player, "PartyResult", { Ok = ok, Error = err })
		return
	end
	if action == "SetRank" then
		local rating = if type(payload) == "table" then payload.Rating else payload
		local ok, err = RatedPvPSystem.SetRank(player, rating)
		remote:FireClient(player, "SetRankResult", { Ok = ok, Error = err })
		return
	end
end

function RatedPvPSystem.Start()
	if RatedPvPSystem._started then
		return
	end
	RatedPvPSystem._started = true
	remote.OnServerEvent:Connect(onRemote)
	if RunService:IsStudio() then
		Players.PlayerAdded:Connect(function(plr: Player)
			plr.Chatted:Connect(function(msg: string)
				local lower = string.lower(msg)
				if lower == "/ratedpanel" or lower == "/ladder" then
					return -- client UI
				end
			end)
		end)
	end
	print("[RatedPvPSystem] " .. RatedPvPSystem.Phase .. " started · gate=" .. tostring(gateAllowsRated()) .. " · live Locked")
end

return RatedPvPSystem
