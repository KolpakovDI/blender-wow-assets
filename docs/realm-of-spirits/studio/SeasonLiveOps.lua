-- SeasonLiveOps - event tokens, Activity Pass, seasonal form, crystal pity (Phase 4)
local SeasonLiveOps = {}

SeasonLiveOps.Current = {
	Id = "S1_Pilot",
	Name = "Пилот сезона духов",
	EndsAt = nil,
}

SeasonLiveOps.TokenName = "Жетон сезона"
SeasonLiveOps.CRYSTAL_PITY_THRESHOLD = 10
SeasonLiveOps.CRYSTAL_DROP_CHANCE = 0.28
SeasonLiveOps.CRYSTAL_POOL = { 101, 102, 103, 104, 105, 107, 108, 111, 112 }

SeasonLiveOps.EventShop = {
	{ Id = "trail_ember", Name = "След: Угли", CostTokens = 25, Kind = "Cosmetic", CosmeticPrefix = "Trail_Ember_" },
	{ Id = "frame_haven", Name = "Рамка Haven", CostTokens = 40, Kind = "Cosmetic", CosmeticPrefix = "Frame_Haven_" },
	{ Id = "sticker_bond", Name = "Стикер Bond", CostTokens = 15, Kind = "Cosmetic", CosmeticPrefix = "Sticker_Bond_" },
	{ Id = "bond_boost_1d", Name = "Ускорение Bond (1 день)", CostTokens = 60, Kind = "Soft", Soft = { BondXpMult = 1.25, DurationHours = 24 } },
	{ Id = "seasonal_form", Name = "Сезонная форма духа", CostTokens = 50, Kind = "SeasonalForm" },
}

SeasonLiveOps.BattlePass = {
	SoftPowerOnly = true,
	Levels = {
		{ Need = 100, Reward = { Tokens = 10, Note = "Жетоны сезона" } },
		{ Need = 250, Reward = { CosmeticPrefix = "BP_Badge_", Note = "Значок пропуска" } },
		{ Need = 400, Reward = { Soft = { BondXpMult = 1.1, DurationHours = 48 }, Note = "Мягкий Bond boost" } },
		{ Need = 600, Reward = { SeasonalForm = true, Note = "Сезонная форма (активный дух)" } },
		{ Need = 800, Reward = { CosmeticPrefix = "BP_Aura_", Note = "Аура пропуска (косметика)" } },
	},
}

function SeasonLiveOps.Ensure(playerData)
	playerData.EventTokens = math.max(0, math.floor(tonumber(playerData.EventTokens) or 0))
	if type(playerData.SeasonPass) ~= "table" then
		playerData.SeasonPass = { SeasonId = SeasonLiveOps.Current.Id, Xp = 0, Claimed = {} }
	end
	if playerData.SeasonPass.SeasonId ~= SeasonLiveOps.Current.Id then
		playerData.SeasonPass = { SeasonId = SeasonLiveOps.Current.Id, Xp = 0, Claimed = {} }
	end
	if type(playerData.SeasonPass.Claimed) ~= "table" then
		playerData.SeasonPass.Claimed = {}
	end
	if type(playerData.SoftBuffs) ~= "table" then
		playerData.SoftBuffs = {}
	end
	if type(playerData.CrystalPity) ~= "table" then
		playerData.CrystalPity = { Misses = 0 }
	end
	playerData.CrystalPity.Misses = math.max(0, math.floor(tonumber(playerData.CrystalPity.Misses) or 0))
end

function SeasonLiveOps.GrantTokens(playerData, amount, reason)
	SeasonLiveOps.Ensure(playerData)
	amount = math.max(0, math.floor(tonumber(amount) or 0))
	if amount <= 0 then return playerData.EventTokens end
	playerData.EventTokens += amount
	return playerData.EventTokens
end

function SeasonLiveOps.AddPassXp(playerData, amount)
	SeasonLiveOps.Ensure(playerData)
	amount = math.max(0, math.floor(tonumber(amount) or 0))
	playerData.SeasonPass.Xp = (tonumber(playerData.SeasonPass.Xp) or 0) + amount
	return playerData.SeasonPass.Xp
end

local function applySoft(playerData, soft)
	if type(soft) ~= "table" then return end
	local hours = tonumber(soft.DurationHours) or 24
	local expires = os.time() + math.floor(hours * 3600)
	playerData.SoftBuffs = playerData.SoftBuffs or {}
	if soft.BondXpMult then
		playerData.SoftBuffs.BondXpMult = soft.BondXpMult
		playerData.SoftBuffs.BondXpExpires = expires
	end
end

local function grantCosmetic(playerData, prefix, name)
	playerData.Cosmetics = playerData.Cosmetics or {}
	local cid = tostring(prefix or "Season_") .. tostring(os.time()) .. "_" .. tostring(math.random(100, 999))
	table.insert(playerData.Cosmetics, {
		Id = cid,
		Name = name or "Сезонная косметика",
		Rarity = "Rare",
		ObtainedAt = os.time(),
		Source = "Season",
	})
	return cid
end

function SeasonLiveOps.GrantSeasonalForm(playerData, spiritIndex)
	SeasonLiveOps.Ensure(playerData)
	local spirits = playerData.Spirits
	if type(spirits) ~= "table" then
		return false, "Нет духов"
	end
	local idx = math.floor(tonumber(spiritIndex) or tonumber(playerData.ActiveSpiritIndex) or 1)
	local spirit = spirits[idx] or spirits[1]
	if not spirit then
		return false, "Нет духа"
	end
	spirit.SeasonalFormId = SeasonLiveOps.Current.Id
	spirit.SeasonalForm = true
	return true, "Сезонная форма: " .. (SeasonLiveOps.Current.Name or SeasonLiveOps.Current.Id)
end

function SeasonLiveOps.HasActiveSeasonalForm(spirit)
	if type(spirit) ~= "table" then return false end
	if spirit.SeasonalFormId == SeasonLiveOps.Current.Id then
		return true
	end
	return false
end

function SeasonLiveOps.ShouldForceCrystal(playerData)
	SeasonLiveOps.Ensure(playerData)
	return (playerData.CrystalPity.Misses or 0) >= SeasonLiveOps.CRYSTAL_PITY_THRESHOLD
end

function SeasonLiveOps.RegisterCrystalHit(playerData)
	SeasonLiveOps.Ensure(playerData)
	playerData.CrystalPity.Misses = 0
end

function SeasonLiveOps.RegisterCrystalMiss(playerData)
	SeasonLiveOps.Ensure(playerData)
	playerData.CrystalPity.Misses = (playerData.CrystalPity.Misses or 0) + 1
	return playerData.CrystalPity.Misses
end

--- Returns itemId, forcedPity
function SeasonLiveOps.RollCrystalDrop(playerData)
	SeasonLiveOps.Ensure(playerData)
	local force = SeasonLiveOps.ShouldForceCrystal(playerData)
	if force or math.random() < SeasonLiveOps.CRYSTAL_DROP_CHANCE then
		SeasonLiveOps.RegisterCrystalHit(playerData)
		local pool = SeasonLiveOps.CRYSTAL_POOL
		local id = pool[math.random(1, #pool)]
		return id, force
	end
	SeasonLiveOps.RegisterCrystalMiss(playerData)
	return nil, false
end

function SeasonLiveOps.GetPitySnapshot(playerData)
	SeasonLiveOps.Ensure(playerData)
	return {
		Misses = playerData.CrystalPity.Misses or 0,
		Threshold = SeasonLiveOps.CRYSTAL_PITY_THRESHOLD,
		Remaining = math.max(0, SeasonLiveOps.CRYSTAL_PITY_THRESHOLD - (playerData.CrystalPity.Misses or 0)),
	}
end

function SeasonLiveOps.BuyEventShop(playerData, offerId)
	SeasonLiveOps.Ensure(playerData)
	local offer
	for _, row in ipairs(SeasonLiveOps.EventShop) do
		if row.Id == offerId then
			offer = row
			break
		end
	end
	if not offer then
		return false, "Товар сезона не найден"
	end
	local cost = math.floor(tonumber(offer.CostTokens) or 0)
	if (playerData.EventTokens or 0) < cost then
		return false, "Недостаточно жетонов сезона"
	end
	playerData.EventTokens -= cost
	if offer.Kind == "Cosmetic" then
		grantCosmetic(playerData, offer.CosmeticPrefix, offer.Name)
	elseif offer.Kind == "Soft" then
		applySoft(playerData, offer.Soft)
	elseif offer.Kind == "SeasonalForm" then
		local ok, msg = SeasonLiveOps.GrantSeasonalForm(playerData, playerData.ActiveSpiritIndex)
		if not ok then
			playerData.EventTokens += cost
			return false, msg
		end
	end
	return true, "Куплено за жетоны: " .. offer.Name
end

function SeasonLiveOps.ClaimPassLevel(playerData, levelIndex)
	SeasonLiveOps.Ensure(playerData)
	local row = SeasonLiveOps.BattlePass.Levels[levelIndex]
	if not row then
		return false, "Нет такого уровня пропуска"
	end
	if playerData.SeasonPass.Claimed[levelIndex] then
		return false, "Уже получено"
	end
	if (tonumber(playerData.SeasonPass.Xp) or 0) < (tonumber(row.Need) or 0) then
		return false, "Недостаточно XP пропуска"
	end
	local reward = row.Reward or {}
	if reward.Tokens then
		SeasonLiveOps.GrantTokens(playerData, reward.Tokens, "BP")
	end
	if reward.CosmeticPrefix then
		grantCosmetic(playerData, reward.CosmeticPrefix, reward.Note or "BP cosmetic")
	end
	if reward.Soft then
		applySoft(playerData, reward.Soft)
	end
	if reward.SeasonalForm then
		SeasonLiveOps.GrantSeasonalForm(playerData, playerData.ActiveSpiritIndex)
	end
	playerData.SeasonPass.Claimed[levelIndex] = true
	return true, reward.Note or "Награда пропуска"
end

function SeasonLiveOps.OnDailyCare(playerData)
	SeasonLiveOps.GrantTokens(playerData, 2, "Care")
	SeasonLiveOps.AddPassXp(playerData, 15)
end

function SeasonLiveOps.OnDailyTemper(playerData)
	SeasonLiveOps.GrantTokens(playerData, 3, "Temper")
	SeasonLiveOps.AddPassXp(playerData, 20)
end

function SeasonLiveOps.OnBattleWin(playerData)
	SeasonLiveOps.GrantTokens(playerData, 1, "Battle")
	SeasonLiveOps.AddPassXp(playerData, 5)
end

function SeasonLiveOps.GetBondXpMultiplier(playerData)
	SeasonLiveOps.Ensure(playerData)
	local mult = 1
	local soft = playerData.SoftBuffs
	if type(soft) == "table" then
		local exp = tonumber(soft.BondXpExpires) or 0
		if exp > 0 and os.time() > exp then
			soft.BondXpMult = nil
			soft.BondXpExpires = nil
		else
			mult = tonumber(soft.BondXpMult) or 1
		end
	end
	local idx = tonumber(playerData.ActiveSpiritIndex) or 1
	local spirit = playerData.Spirits and playerData.Spirits[idx]
	if spirit and spirit.SeasonalFormId == SeasonLiveOps.Current.Id then
		mult = mult * 1.05
	end
	return mult
end

function SeasonLiveOps.GetClientSnapshot(playerData)
	SeasonLiveOps.Ensure(playerData)
	return {
		Season = SeasonLiveOps.Current,
		TokenName = SeasonLiveOps.TokenName,
		EventTokens = playerData.EventTokens,
		EventShop = SeasonLiveOps.EventShop,
		BattlePass = SeasonLiveOps.BattlePass,
		SeasonPass = playerData.SeasonPass,
		CrystalPity = SeasonLiveOps.GetPitySnapshot(playerData),
	}
end

return SeasonLiveOps
