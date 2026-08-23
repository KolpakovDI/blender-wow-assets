-- ProfileServiceAdapter (Q4): migration shim — BLOCKED by ExpansionGate until Q4 unlock
-- Phase 4 W1: read-only audit + schema inventory; live Load/Save still DataStoreManager
-- Phase 4 W2: ProfileService vendored + shadow dual-read (legacy GetAsync, log only)
-- Phase 4 W3: one-way migrate sample key (Mock target only; gate locked)

local DataStoreService = game:GetService("DataStoreService")

local ProfileServiceAdapter = {}

ProfileServiceAdapter.Enabled = false -- hard default; never flip without ExpansionGate
ProfileServiceAdapter.ShadowReadEnabled = true -- W2: audit-only while gate locked
ProfileServiceAdapter.StoreName = "RealmOfSpirits_Profiles_v1"
ProfileServiceAdapter.LegacyDatastoreName = "RealmOfSpirits_v2"
ProfileServiceAdapter.MigrateFromKeyPrefix = "Player_"
ProfileServiceAdapter.SchemaVersion = 1
ProfileServiceAdapter.MigrateSampleUserId = 900000001 -- F4-W3 sentinel; NOT production
ProfileServiceAdapter.MigrateSampleEnabled = true -- W3 sample only; flip false to disable

-- Top-level keys mirrored from DataStoreManager:GetDefaultData (Phase 4 W1 inventory)
ProfileServiceAdapter.ExpectedTopLevelKeys = {
	"Level",
	"Experience",
	"SkillPoints",
	"BonusHP",
	"BonusAttack",
	"BonusDefense",
	"BonusSpeed",
	"BonusMP",
	"Rank",
	"RankTitle",
	"CopperCoins",
	"SilverCoins",
	"GoldCoins",
	"Reputation",
	"Crystals",
	"Spirits",
	"CurrentSpiritId",
	"ActiveSpiritIndex",
	"SpiritStamina",
	"ResonanceDaily",
	"DailyBoard",
	"ShopDaily",
	"ShowcaseSlots",
	"Showcase",
	"EventTokens",
	"SeasonPass",
	"SoftBuffs",
	"CrystalPity",
	"Inventory",
	"UniqueItems",
	"Buffs",
	"Cosmetics",
	"ProcessedReceipts",
	"ActiveQuests",
	"CompletedQuests",
	"QuestProgress",
	"Stats",
	"Settings",
	"LastLogin",
	"FirstJoin",
	"TotalJoins",
	"HubFunnel",
}

ProfileServiceAdapter.OptionalTopLevelKeys = {
	"Guild", -- GuildSystem thin (Q4)
	"_Session", -- ephemeral; stripped on save
}

local SHADOW_MAX_RETRIES = 2
local MIGRATE_MAX_RETRIES = 3
local _profileServiceModule: any = nil

local function legacyKey(userId: number): string
	return ProfileServiceAdapter.MigrateFromKeyPrefix .. tostring(userId)
end

local function deepCopy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in pairs(value) do
		copy[k] = deepCopy(v)
	end
	return copy
end

local function stripEphemeralForMigration(data: any): any
	if type(data) ~= "table" then
		return data
	end
	local out = deepCopy(data)
	out._Session = nil
	out._DoNotSave = nil
	out._MigrationSampleSeed = nil
	return out
end

function ProfileServiceAdapter.ComputeDataChecksum(data: any): number
	if type(data) ~= "table" then
		return 0
	end
	local parts: { string } = {}
	for _, key in ipairs(ProfileServiceAdapter.ExpectedTopLevelKeys) do
		local v = data[key]
		if type(v) == "number" or type(v) == "string" or type(v) == "boolean" then
			table.insert(parts, key .. "=" .. tostring(v))
		elseif type(v) == "table" then
			local n = 0
			for _ in pairs(v) do
				n += 1
			end
			table.insert(parts, key .. "=t" .. tostring(n))
		end
	end
	table.sort(parts)
	local s = table.concat(parts, "|")
	local hash = 2166136261
	for i = 1, #s do
		hash = bit32.bxor(hash, string.byte(s, i))
		hash = (hash * 16777619) % 4294967296
	end
	return hash
end

local function readLegacyData(userId: number): (boolean, any?, string?)
	local store: GlobalDataStore? = nil
	pcall(function()
		store = DataStoreService:GetDataStore(ProfileServiceAdapter.LegacyDatastoreName)
	end)
	if not store then
		return false, nil, "datastore_unavailable"
	end
	local key = legacyKey(userId)
	for attempt = 1, MIGRATE_MAX_RETRIES do
		local ok, dataOrErr = pcall(function()
			return store:GetAsync(key)
		end)
		if ok then
			if type(dataOrErr) == "table" then
				return true, dataOrErr, nil
			end
			return true, nil, "no_saved_row"
		end
		if attempt == MIGRATE_MAX_RETRIES then
			return false, nil, tostring(dataOrErr)
		end
		task.wait(0.25 * attempt)
	end
	return false, nil, "read_failed"
end

local function buildSyntheticSeedData(): any
	local ok, DSM = pcall(function()
		return require(script.Parent:WaitForChild("DataStoreManager"))
	end)
	if not ok or not DSM then
		return nil
	end
	local seed = DSM.new():GetDefaultData()
	seed.Level = 99
	seed._MigrationSampleSeed = true
	return seed
end

local function gateAllows(): boolean
	local ok, ExpansionGate = pcall(function()
		return require(game:GetService("ReplicatedStorage").RealmOfSpirits:WaitForChild("ExpansionGate"))
	end)
	if not ok or not ExpansionGate then
		return false
	end
	return ExpansionGate.AssertProfileServiceBlocked() == true
end

local function countTopLevelKeys(data: any): number
	if type(data) ~= "table" then
		return 0
	end
	local n = 0
	for key in pairs(data) do
		if type(key) == "string" then
			n += 1
		end
	end
	return n
end

local function getProfileServiceModule(): any
	if _profileServiceModule ~= nil then
		return _profileServiceModule
	end
	local sss = game:GetService("ServerScriptService"):FindFirstChild("RealmOfSpirits")
	if not sss then
		return nil
	end
	local mod = sss:FindFirstChild("ProfileService")
	if not mod or not mod:IsA("ModuleScript") then
		return nil
	end
	local ok, ps = pcall(require, mod)
	if ok then
		_profileServiceModule = ps
	end
	return _profileServiceModule
end

function ProfileServiceAdapter.IsProfileServiceVendored(): boolean
	return getProfileServiceModule() ~= nil
end

function ProfileServiceAdapter.GetSchemaInventory()
	return {
		SchemaVersion = ProfileServiceAdapter.SchemaVersion,
		StoreName = ProfileServiceAdapter.StoreName,
		LegacyDatastoreName = ProfileServiceAdapter.LegacyDatastoreName,
		MigrateFromKeyPrefix = ProfileServiceAdapter.MigrateFromKeyPrefix,
		ExpectedTopLevelKeys = ProfileServiceAdapter.ExpectedTopLevelKeys,
		OptionalTopLevelKeys = ProfileServiceAdapter.OptionalTopLevelKeys,
		ExpectedKeyCount = #ProfileServiceAdapter.ExpectedTopLevelKeys,
	}
end

function ProfileServiceAdapter.ValidateDataShape(data: any): (boolean, string?)
	if type(data) ~= "table" then
		return false, "not_table"
	end
	local missing = {}
	for _, key in ipairs(ProfileServiceAdapter.ExpectedTopLevelKeys) do
		if data[key] == nil then
			table.insert(missing, key)
		end
	end
	if #missing > 0 then
		return false, "missing_keys:" .. table.concat(missing, ",")
	end
	if type(data.Spirits) ~= "table" then
		return false, "spirits_not_table"
	end
	if type(data.Inventory) ~= "table" then
		return false, "inventory_not_table"
	end
	return true, nil
end

-- W2: read-only legacy key via GetAsync — never writes ProfileService store
function ProfileServiceAdapter.ShadowReadLegacyKey(userId: number): { [string]: any }
	local result: { [string]: any } = {
		UserId = userId,
		Key = legacyKey(userId),
		ReadOk = false,
		DataPresent = false,
		ShapeOk = false,
		ShapeReason = nil :: string?,
		TopLevelKeyCount = 0,
		Error = nil :: string?,
	}

	if ProfileServiceAdapter.ShouldUse() then
		result.Error = "skipped_live_cutover"
		return result
	end

	local store: GlobalDataStore? = nil
	pcall(function()
		store = DataStoreService:GetDataStore(ProfileServiceAdapter.LegacyDatastoreName)
	end)
	if not store then
		result.Error = "datastore_unavailable"
		return result
	end

	local legacyData: any = nil
	for attempt = 1, SHADOW_MAX_RETRIES do
		local ok, dataOrErr = pcall(function()
			return store:GetAsync(result.Key)
		end)
		if ok then
			result.ReadOk = true
			legacyData = dataOrErr
			break
		end
		result.Error = tostring(dataOrErr)
		task.wait(0.25 * attempt)
	end

	if not result.ReadOk then
		return result
	end

	if type(legacyData) == "table" then
		result.DataPresent = true
		result.TopLevelKeyCount = countTopLevelKeys(legacyData)
		local shapeOk, shapeReason = ProfileServiceAdapter.ValidateDataShape(legacyData)
		result.ShapeOk = shapeOk
		result.ShapeReason = shapeReason
	else
		result.DataPresent = false
		result.ShapeOk = true
		result.ShapeReason = "no_saved_row"
	end

	return result
end

function ProfileServiceAdapter.ShadowAuditPlayer(player: Player, loadedData: any): { [string]: any }
	local audit: { [string]: any } = {
		UserId = player.UserId,
		PlayerName = player.Name,
		ShadowEnabled = ProfileServiceAdapter.ShadowReadEnabled,
		Vendored = ProfileServiceAdapter.IsProfileServiceVendored(),
		LiveShapeOk = false,
		LiveShapeReason = nil :: string?,
		Legacy = nil :: { [string]: any }?,
		LiveLegacyMatch = nil :: boolean?,
	}

	if not ProfileServiceAdapter.ShadowReadEnabled or ProfileServiceAdapter.ShouldUse() then
		audit.Skipped = true
		return audit
	end

	local liveOk, liveReason = ProfileServiceAdapter.ValidateDataShape(loadedData)
	audit.LiveShapeOk = liveOk
	audit.LiveShapeReason = liveReason

	local legacyAudit = ProfileServiceAdapter.ShadowReadLegacyKey(player.UserId)
	audit.Legacy = legacyAudit

	if legacyAudit.ReadOk and legacyAudit.DataPresent and liveOk then
		audit.LiveLegacyMatch = legacyAudit.TopLevelKeyCount == countTopLevelKeys(loadedData)
	end

	print(string.format(
		"[ProfileServiceAdapter] shadow user=%s vendored=%s liveShape=%s legacyRead=%s legacyShape=%s match=%s",
		player.Name,
		tostring(audit.Vendored),
		tostring(liveOk),
		tostring(legacyAudit.ReadOk),
		tostring(legacyAudit.ShapeOk),
		tostring(audit.LiveLegacyMatch)
	))

	if not liveOk and liveReason then
		warn("[ProfileServiceAdapter] shadow live shape FAIL: " .. liveReason)
	end
	if legacyAudit.ReadOk and legacyAudit.DataPresent and not legacyAudit.ShapeOk and legacyAudit.ShapeReason then
		warn("[ProfileServiceAdapter] shadow legacy shape FAIL: " .. legacyAudit.ShapeReason)
	end

	return audit
end

-- W3: seed legacy store row for sentinel UserId (Studio smoke only; whitelisted id)
function ProfileServiceAdapter.SeedMigrateSampleLegacy(userId: number?): { [string]: any }
	local uid = userId or ProfileServiceAdapter.MigrateSampleUserId
	local audit: { [string]: any } = {
		Phase = "F4-W3-seed",
		UserId = uid,
		Success = false,
		Error = nil :: string?,
	}

	if uid ~= ProfileServiceAdapter.MigrateSampleUserId then
		audit.Error = "not_whitelisted_user"
		return audit
	end
	if ProfileServiceAdapter.ShouldUse() then
		audit.Error = "gate_live_cutover"
		return audit
	end

	local seed = buildSyntheticSeedData()
	if not seed then
		audit.Error = "seed_build_failed"
		return audit
	end

	local shapeOk, shapeReason = ProfileServiceAdapter.ValidateDataShape(seed)
	audit.SourceShapeOk = shapeOk
	audit.SourceShapeReason = shapeReason
	if not shapeOk then
		audit.Error = shapeReason
		return audit
	end

	local store: GlobalDataStore? = nil
	pcall(function()
		store = DataStoreService:GetDataStore(ProfileServiceAdapter.LegacyDatastoreName)
	end)
	if not store then
		audit.Error = "datastore_unavailable"
		audit.SyntheticOnly = true
		return audit
	end

	local key = legacyKey(uid)
	local writeOk = false
	for attempt = 1, MIGRATE_MAX_RETRIES do
		local ok, err = pcall(function()
			store:UpdateAsync(key, function(_old)
				return stripEphemeralForMigration(seed)
			end)
		end)
		if ok then
			writeOk = true
			break
		end
		audit.Error = tostring(err)
		task.wait(0.25 * attempt)
	end

	audit.Success = writeOk
	audit.Key = key
	if writeOk then
		print(string.format("[ProfileServiceAdapter] seed legacy user=%d key=%s shape=%s", uid, key, tostring(shapeOk)))
	end
	return audit
end

-- W3: one-way migrate Player_{id} legacy → RealmOfSpirits_Profiles_v1 (Mock target; gate locked)
function ProfileServiceAdapter.MigrateSampleKey(userId: number?): { [string]: any }
	local uid = userId or ProfileServiceAdapter.MigrateSampleUserId
	local audit: { [string]: any } = {
		Phase = "F4-W3-migrate",
		UserId = uid,
		Key = legacyKey(uid),
		Success = false,
		MockTarget = true,
		SourceOrigin = nil :: string?,
		LegacyReadOk = false,
		SourceShapeOk = false,
		SourceShapeReason = nil :: string?,
		TargetShapeOk = false,
		TargetShapeReason = nil :: string?,
		SourceChecksum = 0,
		TargetChecksum = 0,
		ChecksumMatch = false,
		Error = nil :: string?,
	}

	if not ProfileServiceAdapter.MigrateSampleEnabled then
		audit.Error = "migrate_sample_disabled"
		return audit
	end
	if ProfileServiceAdapter.ShouldUse() then
		audit.Error = "gate_live_cutover"
		return audit
	end
	if uid ~= ProfileServiceAdapter.MigrateSampleUserId then
		audit.Error = "not_whitelisted_user"
		return audit
	end

	local PS = getProfileServiceModule()
	if not PS then
		audit.Error = "profile_service_not_vendored"
		return audit
	end

	local okDSM, DSM = pcall(function()
		return require(script.Parent:WaitForChild("DataStoreManager"))
	end)
	if not okDSM or not DSM then
		audit.Error = "dsm_unavailable"
		return audit
	end

	local readOk, legacyData, readReason = readLegacyData(uid)
	audit.LegacyReadOk = readOk
	local sourceData: any = nil

	if readOk and type(legacyData) == "table" then
		sourceData = legacyData
		audit.SourceOrigin = "legacy_store"
	elseif readReason == "no_saved_row" or readReason == "datastore_unavailable" then
		sourceData = buildSyntheticSeedData()
		audit.SourceOrigin = "synthetic_seed"
		audit.LegacyReadOk = false
	else
		audit.Error = readReason or "legacy_read_failed"
		return audit
	end

	if type(sourceData) ~= "table" then
		audit.Error = "source_data_missing"
		return audit
	end

	local prepared = stripEphemeralForMigration(sourceData)
	local sourceShapeOk, sourceShapeReason = ProfileServiceAdapter.ValidateDataShape(prepared)
	audit.SourceShapeOk = sourceShapeOk
	audit.SourceShapeReason = sourceShapeReason
	audit.SourceChecksum = ProfileServiceAdapter.ComputeDataChecksum(prepared)

	if not sourceShapeOk then
		audit.Error = sourceShapeReason
		return audit
	end

	local template = DSM.new():GetDefaultData()
	local profileStore = PS.GetProfileStore(ProfileServiceAdapter.StoreName, template)
	local mockStore = profileStore.Mock
	local key = audit.Key

	pcall(function()
		mockStore:WipeProfileAsync(key)
	end)

	local profile = mockStore:LoadProfileAsync(key, "ForceLoad")
	if not profile then
		audit.Error = "target_load_failed"
		return audit
	end

	profile:AddUserId(uid)
	for k, v in pairs(prepared) do
		profile.Data[k] = deepCopy(v)
	end
	profile:Reconcile()
	profile:Release()

	local viewProfile = mockStore:ViewProfileAsync(key)
	if not viewProfile then
		audit.Error = "target_view_failed"
		return audit
	end

	local targetPrepared = stripEphemeralForMigration(viewProfile.Data)
	local targetShapeOk, targetShapeReason = ProfileServiceAdapter.ValidateDataShape(targetPrepared)
	audit.TargetShapeOk = targetShapeOk
	audit.TargetShapeReason = targetShapeReason
	audit.TargetChecksum = ProfileServiceAdapter.ComputeDataChecksum(targetPrepared)
	audit.ChecksumMatch = audit.SourceChecksum == audit.TargetChecksum
	audit.Success = sourceShapeOk and targetShapeOk and audit.ChecksumMatch

	print(string.format(
		"[ProfileServiceAdapter] migrate sample user=%d origin=%s shape=%s checksum=%s match=%s mock=true",
		uid,
		tostring(audit.SourceOrigin),
		tostring(audit.Success),
		tostring(audit.SourceChecksum),
		tostring(audit.ChecksumMatch)
	))

	if not audit.Success then
		warn(string.format(
			"[ProfileServiceAdapter] migrate sample FAIL user=%d srcShape=%s tgtShape=%s checksumMatch=%s",
			uid,
			tostring(sourceShapeOk),
			tostring(targetShapeOk),
			tostring(audit.ChecksumMatch)
		))
	end

	return audit
end

function ProfileServiceAdapter.GetMigrationAudit()
	local gate = gateAllows()
	local shouldUse = ProfileServiceAdapter.ShouldUse()
	local vendored = ProfileServiceAdapter.IsProfileServiceVendored()
	return {
		Phase = "F4-W3-migrate",
		LiveBlocked = not shouldUse,
		GateAllows = gate,
		Enabled = ProfileServiceAdapter.Enabled,
		ShouldUse = shouldUse,
		ShadowReadEnabled = ProfileServiceAdapter.ShadowReadEnabled,
		MigrateSampleEnabled = ProfileServiceAdapter.MigrateSampleEnabled,
		MigrateSampleUserId = ProfileServiceAdapter.MigrateSampleUserId,
		ProfileServiceVendored = vendored,
		CurrentBackend = "DataStoreManager",
		TargetBackend = "ProfileService",
		TargetStore = ProfileServiceAdapter.StoreName,
		SourceDatastore = ProfileServiceAdapter.LegacyDatastoreName,
		SourceKeyPrefix = ProfileServiceAdapter.MigrateFromKeyPrefix,
		SchemaVersion = ProfileServiceAdapter.SchemaVersion,
		TopLevelKeyCount = #ProfileServiceAdapter.ExpectedTopLevelKeys,
		NextSteps = {
			"W4: flip AllowProfileService + UseProfileServiceAdapter after owner + live DS smoke",
		},
		Rollback = {
			"Set MigrateSampleEnabled=false in ProfileServiceAdapter (mirror + Studio)",
			"WipeProfileAsync on mock key Player_900000001 if re-smoking",
			"Remove ProfileService ModuleScript from SSS.RealmOfSpirits (W2 rollback)",
			"Set ShadowReadEnabled=false in ProfileServiceAdapter (mirror + Studio)",
			"DataStoreManager remains live — no Allow* flip required",
		},
	}
end

function ProfileServiceAdapter.GetStatus()
	return {
		Enabled = ProfileServiceAdapter.Enabled,
		GateAllows = gateAllows(),
		ShadowReadEnabled = ProfileServiceAdapter.ShadowReadEnabled,
		ProfileServiceVendored = ProfileServiceAdapter.IsProfileServiceVendored(),
		StoreName = ProfileServiceAdapter.StoreName,
		SchemaVersion = ProfileServiceAdapter.SchemaVersion,
		Note = "Blocked until ExpansionGate.AllowProfileService + Enabled — keep DataStoreManager",
	}
end

function ProfileServiceAdapter.ShouldUse(): boolean
	if not ProfileServiceAdapter.Enabled then
		return false
	end
	if not gateAllows() then
		warn("[ProfileServiceAdapter] blocked by ExpansionGate (AllowProfileService=false)")
		return false
	end
	local sss = game:GetService("ServerScriptService"):FindFirstChild("RealmOfSpirits")
	if not sss then
		return false
	end
	return sss:GetAttribute("UseProfileServiceAdapter") == true
end

function ProfileServiceAdapter.LoadPlayerData(_userId: number)
	if not ProfileServiceAdapter.ShouldUse() then
		return nil
	end
	warn("[ProfileServiceAdapter] Load not implemented — use DataStoreManager")
	return nil
end

function ProfileServiceAdapter.SavePlayerData(_userId: number, _data: any): boolean
	if not ProfileServiceAdapter.ShouldUse() then
		return false
	end
	warn("[ProfileServiceAdapter] Save not implemented — use DataStoreManager")
	return false
end

return ProfileServiceAdapter
