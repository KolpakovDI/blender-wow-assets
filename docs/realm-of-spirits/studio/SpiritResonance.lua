-- SpiritResonance: multi-track spirit progression (Bond / Temper / Dex / Stamina / Battle XP)
-- Shared ModuleScript under ReplicatedStorage.RealmOfSpirits

local SpiritResonance = {}

SpiritResonance.PARTY_SHARE = 0.20
SpiritResonance.BOND_MAX = 10
SpiritResonance.TEMPER_CAP = 30
SpiritResonance.STAMINA_MAX = 100
SpiritResonance.TEMPER_STAMINA_COST = 15
SpiritResonance.CARE_BOND_XP = 25
SpiritResonance.TREAT_ITEM_ID = 4
SpiritResonance.TEMPER_ITEM_ID = 5

local FOCUS = { Attack = true, Defense = true, Spirit = true }

function SpiritResonance.TodayKey()
	return os.date("!%Y-%m-%d")
end

function SpiritResonance.XpToNext(level)
	level = math.clamp(tonumber(level) or 1, 1, 100)
	return 40 + level * 45
end

function SpiritResonance.BondXpToNext(bond)
	bond = math.clamp(tonumber(bond) or 0, 0, SpiritResonance.BOND_MAX)
	return 30 + bond * 20
end

function SpiritResonance.EnsureSpirit(spirit)
	if type(spirit) ~= "table" then
		return spirit
	end
	spirit.Level = tonumber(spirit.Level) or 1
	spirit.Experience = tonumber(spirit.Experience) or 0
	spirit.Bond = math.clamp(tonumber(spirit.Bond) or 0, 0, SpiritResonance.BOND_MAX)
	spirit.BondXp = tonumber(spirit.BondXp) or 0
	if type(spirit.TemperPoints) ~= "table" then
		spirit.TemperPoints = { Attack = 0, Defense = 0, Spirit = 0 }
	else
		spirit.TemperPoints.Attack = math.clamp(tonumber(spirit.TemperPoints.Attack) or 0, 0, SpiritResonance.TEMPER_CAP)
		spirit.TemperPoints.Defense = math.clamp(tonumber(spirit.TemperPoints.Defense) or 0, 0, SpiritResonance.TEMPER_CAP)
		spirit.TemperPoints.Spirit = math.clamp(tonumber(spirit.TemperPoints.Spirit) or 0, 0, SpiritResonance.TEMPER_CAP)
	end
	if spirit.TemperFocus and not FOCUS[spirit.TemperFocus] then
		spirit.TemperFocus = nil
	end
	return spirit
end

function SpiritResonance.EnsurePlayer(data)
	if type(data) ~= "table" then
		return data
	end
	data.SpiritStamina = math.clamp(tonumber(data.SpiritStamina) or SpiritResonance.STAMINA_MAX, 0, SpiritResonance.STAMINA_MAX)
	local today = SpiritResonance.TodayKey()
	if type(data.ResonanceDaily) ~= "table" or data.ResonanceDaily.Date ~= today then
		data.ResonanceDaily = { Date = today, Care = false, Temper = false }
	end
	if type(data.Spirits) == "table" then
		for _, s in ipairs(data.Spirits) do
			SpiritResonance.EnsureSpirit(s)
		end
	end
	return data
end

local function applyXpToSpirit(spirit, amount)
	SpiritResonance.EnsureSpirit(spirit)
	if amount <= 0 or spirit.Level >= 100 then
		return false
	end
	spirit.Experience = spirit.Experience + amount
	local leveled = false
	local needed = SpiritResonance.XpToNext(spirit.Level)
	while spirit.Experience >= needed and spirit.Level < 100 do
		spirit.Experience = spirit.Experience - needed
		spirit.Level = spirit.Level + 1
		leveled = true
		needed = SpiritResonance.XpToNext(spirit.Level)
	end
	return leveled
end

-- Active spirit gets full XP; others in roster share PARTY_SHARE
function SpiritResonance.GrantBattleXp(playerData, activeSpiritId, baseXp)
	SpiritResonance.EnsurePlayer(playerData)
	baseXp = math.max(0, math.floor(tonumber(baseXp) or 0))
	if baseXp <= 0 or type(playerData.Spirits) ~= "table" then
		return 0
	end
	local maxLevel = 0
	for _, spirit in ipairs(playerData.Spirits) do
		SpiritResonance.EnsureSpirit(spirit)
		local share = (spirit.Id == activeSpiritId) and baseXp or math.floor(baseXp * SpiritResonance.PARTY_SHARE)
		applyXpToSpirit(spirit, share)
		maxLevel = math.max(maxLevel, spirit.Level)
	end
	return maxLevel
end

function SpiritResonance.BattleXpForSpirit(spirit)
	SpiritResonance.EnsureSpirit(spirit)
	return 25 + math.floor(spirit.Level * 2)
end

local function findInventory(data, itemId)
	if type(data.Inventory) ~= "table" then
		return nil
	end
	for _, slot in ipairs(data.Inventory) do
		if slot.Id == itemId then
			return slot
		end
	end
	return nil
end

local function consumeItem(data, itemId, qty)
	local slot = findInventory(data, itemId)
	if not slot or (slot.Quantity or 0) < qty then
		return false
	end
	slot.Quantity = slot.Quantity - qty
	if slot.Quantity <= 0 then
		for i, s in ipairs(data.Inventory) do
			if s == slot then
				table.remove(data.Inventory, i)
				break
			end
		end
	end
	return true
end

function SpiritResonance.AddBondXp(spirit, amount)
	SpiritResonance.EnsureSpirit(spirit)
	if spirit.Bond >= SpiritResonance.BOND_MAX then
		return false, "Максимальный резонанс"
	end
	spirit.BondXp = spirit.BondXp + math.max(0, amount)
	local gained = false
	local need = SpiritResonance.BondXpToNext(spirit.Bond)
	while spirit.BondXp >= need and spirit.Bond < SpiritResonance.BOND_MAX do
		spirit.BondXp = spirit.BondXp - need
		spirit.Bond = spirit.Bond + 1
		gained = true
		need = SpiritResonance.BondXpToNext(spirit.Bond)
	end
	return true, gained and ("Резонанс " .. spirit.Bond) or "Уход выполнен"
end

-- free once per day OR consume treat item
function SpiritResonance.Care(playerData, spiritIndex, useTreat)
	SpiritResonance.EnsurePlayer(playerData)
	local spirit = playerData.Spirits and playerData.Spirits[spiritIndex]
	if not spirit then
		return false, "Нет духа"
	end
	local daily = playerData.ResonanceDaily
	local freeOk = not daily.Care
	if not freeOk then
		if useTreat then
			if not consumeItem(playerData, SpiritResonance.TREAT_ITEM_ID, 1) then
				return false, "Нужно лакомство или бесплатный уход (1/день)"
			end
		else
			return false, "Бесплатный уход уже сегодня; купите лакомство"
		end
	else
		daily.Care = true
		if useTreat then
			consumeItem(playerData, SpiritResonance.TREAT_ITEM_ID, 1) -- optional extra
		end
	end
	local xpGain = SpiritResonance.CARE_BOND_XP + (useTreat and 15 or 0)
	do
		local okLive, SeasonLiveOps = pcall(function()
			return require(script.Parent.SeasonLiveOps)
		end)
		-- SeasonLiveOps lives under ServerScriptService; Care may run from SSS.GameManager path
		if not okLive then
			okLive, SeasonLiveOps = pcall(function()
				local sss = game:GetService("ServerScriptService")
				return require(sss.RealmOfSpirits.SeasonLiveOps)
			end)
		end
		if okLive and SeasonLiveOps and SeasonLiveOps.GetBondXpMultiplier then
			xpGain = math.floor(xpGain * SeasonLiveOps.GetBondXpMultiplier(playerData))
		end
	end
	local ok, msg = SpiritResonance.AddBondXp(spirit, xpGain)
	return ok, msg
end

function SpiritResonance.Temper(playerData, spiritIndex, focus)
	SpiritResonance.EnsurePlayer(playerData)
	if not FOCUS[focus] then
		return false, "Фокус: Attack / Defense / Spirit"
	end
	local spirit = playerData.Spirits and playerData.Spirits[spiritIndex]
	if not spirit then
		return false, "Нет духа"
	end
	SpiritResonance.EnsureSpirit(spirit)
	if (spirit.TemperPoints[focus] or 0) >= SpiritResonance.TEMPER_CAP then
		return false, "Фокус закалён до предела"
	end
	local usedItem = false
	if (playerData.SpiritStamina or 0) < SpiritResonance.TEMPER_STAMINA_COST then
		if consumeItem(playerData, SpiritResonance.TEMPER_ITEM_ID, 1) then
			usedItem = true
		else
			return false, "Мало выносливости духа (нужно 15) или камень закалки"
		end
	else
		playerData.SpiritStamina = playerData.SpiritStamina - SpiritResonance.TEMPER_STAMINA_COST
	end
	spirit.TemperFocus = focus
	spirit.TemperPoints[focus] = (spirit.TemperPoints[focus] or 0) + 1
	playerData.ResonanceDaily.Temper = true
	local msg = "Закалка +" .. focus
	if usedItem then
		msg = msg .. " (камень)"
	end
	return true, msg
end

function SpiritResonance.RegenStamina(playerData, amount)
	SpiritResonance.EnsurePlayer(playerData)
	playerData.SpiritStamina = math.min(
		SpiritResonance.STAMINA_MAX,
		(playerData.SpiritStamina or 0) + (amount or 10)
	)
end

-- Element set bonuses: 3 / 6 / 12 owned spirits of same element
function SpiritResonance.GetDexBonus(playerData, SpiritDatabase)
	local counts = {}
	if type(playerData.Spirits) ~= "table" then
		return { ByElement = {}, AttackPct = 0, DefensePct = 0 }
	end
	for _, s in ipairs(playerData.Spirits) do
		local cat = SpiritDatabase and SpiritDatabase.Get(s.Id)
		local el = cat and cat.Element or "Unknown"
		counts[el] = (counts[el] or 0) + 1
	end
	local atk, def = 0, 0
	for _, n in pairs(counts) do
		if n >= 3 then
			atk = atk + 0.02
		end
		if n >= 6 then
			def = def + 0.03
		end
		if n >= 12 then
			atk = atk + 0.03
			def = def + 0.03
		end
	end
	return { ByElement = counts, AttackPct = atk, DefensePct = def }
end

function SpiritResonance.GetTemperStatBonus(spirit)
	SpiritResonance.EnsureSpirit(spirit)
	local p = spirit.TemperPoints
	return {
		Attack = (p.Attack or 0) * 0.5,
		Defense = (p.Defense or 0) * 0.4,
		Spirit = (p.Spirit or 0) * 0.5, -- MP / CD soft
	}
end

function SpiritResonance.MeetsBondRequirement(spirit, requiredBond)
	SpiritResonance.EnsureSpirit(spirit)
	return (spirit.Bond or 0) >= (tonumber(requiredBond) or 0)
end

function SpiritResonance.GetClientSnapshot(playerData)
	SpiritResonance.EnsurePlayer(playerData)
	local spirits = {}
	for i, s in ipairs(playerData.Spirits or {}) do
		SpiritResonance.EnsureSpirit(s)
		spirits[i] = {
			Bond = s.Bond,
			BondXp = s.BondXp,
			BondNeed = SpiritResonance.BondXpToNext(s.Bond),
			TemperFocus = s.TemperFocus,
			TemperPoints = s.TemperPoints,
			Level = s.Level,
			Experience = s.Experience,
			XpNeed = SpiritResonance.XpToNext(s.Level),
		}
	end
	return {
		SpiritStamina = playerData.SpiritStamina,
		ResonanceDaily = playerData.ResonanceDaily,
		Spirits = spirits,
	}
end

return SpiritResonance
