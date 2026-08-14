-- BattleOrchestrator - skill validation + resolve + effects for Realm of Spirits
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local realmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local SkillCatalog = require(realmFolder:WaitForChild("SkillCatalog"))
local EffectCatalog = require(realmFolder:WaitForChild("EffectCatalog"))
local SpiritDatabase = require(realmFolder:WaitForChild("SpiritDatabase"))
local SpiritResonance = require(realmFolder:WaitForChild("SpiritResonance"))

local function applyTemperDamage(damage, attackerSpirit, defenderSpirit, battle)
	damage = math.max(1, math.floor(tonumber(damage) or 1))
	if attackerSpirit then
		local b = SpiritResonance.GetTemperStatBonus(attackerSpirit)
		damage = damage + math.floor(tonumber(b.Attack) or 0)
	end
	if defenderSpirit then
		local b = SpiritResonance.GetTemperStatBonus(defenderSpirit)
		damage = math.max(1, damage - math.floor(tonumber(b.Defense) or 0))
	end
	if battle then
		local isPlayerAtk = attackerSpirit and battle.PlayerSpirit and attackerSpirit == battle.PlayerSpirit
		local isPlayerDef = defenderSpirit and battle.PlayerSpirit and defenderSpirit == battle.PlayerSpirit
		local atkPct, defPct = 0, 0
		if isPlayerAtk then
			atkPct = (tonumber(battle.DexAttackPct) or 0) + (tonumber(battle.ElementPassiveAtkPct) or 0)
		else
			atkPct = tonumber(battle.EnemyElementPassiveAtkPct) or 0
		end
		if isPlayerDef then
			defPct = (tonumber(battle.DexDefensePct) or 0) + (tonumber(battle.ElementPassiveDefPct) or 0)
		else
			defPct = tonumber(battle.EnemyElementPassiveDefPct) or 0
		end
		if atkPct ~= 0 then
			damage = math.max(1, math.floor(damage * (1 + atkPct)))
		end
		if defPct ~= 0 then
			damage = math.max(1, math.floor(damage * (1 - defPct)))
		end
	end
	return damage
end

local function applyTemperHeal(heal, spirit)
	heal = math.max(1, math.floor(tonumber(heal) or 1))
	if spirit then
		local b = SpiritResonance.GetTemperStatBonus(spirit)
		heal = heal + math.floor((tonumber(b.Spirit) or 0) * 0.5)
	end
	return heal
end

local function battleEnemyRef(battle)
	if battle.EnemyInfo and battle.EnemyInfo.Id then
		return battle.EnemyInfo.Id
	end
	if battle.EnemySpirit and battle.EnemySpirit.Id then
		return battle.EnemySpirit.Id
	end
	return battle.EnemyInfo or battle.EnemySpirit
end

local function battlePlayerRef(battle)
	if battle.PlayerSpirit and battle.PlayerSpirit.Id then
		return battle.PlayerSpirit.Id
	end
	return battle.PlayerSpirit or battle.SpiritInfo
end

local function applyElementDamage(damage, attackerRef, defenderRef)
	local mult = SpiritDatabase.GetElementMultiplier(attackerRef, defenderRef)
	damage = math.max(1, math.floor((tonumber(damage) or 1) * mult))
	local tip = SpiritDatabase.FormatElementMatchup(attackerRef, defenderRef)
	return damage, tip, mult
end

local function appendMatchup(msg, tip)
	if tip and tip ~= "" then
		return msg .. " • " .. tip
	end
	return msg
end

local BattleOrchestrator = {}

function BattleOrchestrator.CreateEffectsState()
	return EffectCatalog.CreateState()
end

function BattleOrchestrator.BuildAbilities(spiritInfo, maxSlots)
	return SkillCatalog.BuildAbilities(spiritInfo, maxSlots or 3)
end

local function sideFields(side)
	if side == "Enemy" then
		return "EnemyAbilities", "EnemyCooldowns", "EnemyMP", "EnemyEffects", "PlayerEffects", "EnemyHP", "PlayerHP"
	end
	return "PlayerAbilities", "PlayerCooldowns", "PlayerMP", "PlayerEffects", "EnemyEffects", "PlayerHP", "EnemyHP"
end

function BattleOrchestrator.CanUseSkill(battle, side, skillIndex, now)
	now = now or os.clock()
	skillIndex = math.floor(tonumber(skillIndex) or 0)
	if skillIndex < 1 then
		return false, "Навык недоступен", nil
	end
	local abKey, cdKey, mpKey, selfFxKey = sideFields(side)
	local abilities = battle[abKey]
	local ability = abilities and abilities[skillIndex]
	if not ability then
		return false, "Навык недоступен", nil
	end
	local cooldownUntil = (battle[cdKey] and battle[cdKey][skillIndex]) or 0
	if now < cooldownUntil then
		local left = math.max(0, cooldownUntil - now)
		return false, string.format("%s перезаряжается: %.1fс", ability.Name, left), ability
	end
	local selfFx = battle[selfFxKey]
	if selfFx and (selfFx.StunLeft or 0) > 0 then
		return false, "Stun", ability
	end
	if (battle[mpKey] or 0) < (ability.Cost or 0) then
		return false, "Недостаточно маны", ability
	end
	return true, nil, ability
end

function BattleOrchestrator.RegenMana(battle, playerDelta, enemyDelta)
	battle.PlayerMP = math.min(100, (battle.PlayerMP or 0) + (playerDelta or 0))
	battle.EnemyMP = math.min(100, (battle.EnemyMP or 0) + (enemyDelta or 0))
end

--- First enemy skill ready by CD+MP (stun is handled in ExecuteEnemySkill).
function BattleOrchestrator.PickReadyEnemySkill(battle, now)
	now = now or os.clock()
	for i, ability in ipairs(battle.EnemyAbilities or {}) do
		local cooldownUntil = (battle.EnemyCooldowns and battle.EnemyCooldowns[i]) or 0
		if now >= cooldownUntil and (battle.EnemyMP or 0) >= (ability.Cost or 0) then
			return i, ability
		end
	end
	return nil, nil
end

local function spendAndCooldown(battle, side, skillIndex, ability, now)
	now = now or os.clock()
	local _, cdKey, mpKey = sideFields(side)
	battle[mpKey] = math.max(0, (battle[mpKey] or 0) - (ability.Cost or 0))
	battle[cdKey] = battle[cdKey] or {}
	battle[cdKey][skillIndex] = now + math.max(0, ability.Cooldown or 0)
end

--- Execute a player skill. opts: { DamageMultiplier = number }
function BattleOrchestrator.ExecutePlayerSkill(battle, skillIndex, opts)
	opts = opts or {}
	local now = opts.Now or os.clock()
	local ok, reason, ability = BattleOrchestrator.CanUseSkill(battle, "Player", skillIndex, now)
	if not ok then
		if reason == "Stun" then
			EffectCatalog.Step(battle.PlayerEffects)
			return { Ok = false, Kind = "Stun", Message = "Вы оглушены и пропускаете ход!", Ability = ability }
		end
		return { Ok = false, Kind = "Blocked", Message = reason or "Навык недоступен", Ability = ability }
	end

	spendAndCooldown(battle, "Player", skillIndex, ability, now)
	local playerSpirit = battle.PlayerSpirit

	if ability.Type == "Heal" then
		local heal = math.max(1, math.floor((ability.HealAmount or 20) + ((playerSpirit.Level or 1) * 1.5)))
		battle.PlayerHP = math.min(battle.PlayerMaxHP, battle.PlayerHP + heal)
		local effectText = EffectCatalog.Apply(ability.Effect, battle.PlayerEffects, battle.EnemyEffects)
		EffectCatalog.Step(battle.PlayerEffects)
		EffectCatalog.Step(battle.EnemyEffects)
		battle.Turn = (battle.Turn or 1) + 1
		local msg = "Вы восстановили " .. heal .. " HP! (" .. ability.Name .. ")"
		if effectText ~= "" then msg = msg .. " • " .. effectText end
		return { Ok = true, Kind = "Heal", Message = msg, Ability = ability, Ended = false }
	end

	local spiritAtk = 10
	do
		local info = SpiritDatabase.Get(playerSpirit.Id)
		if info and info.BaseStats then
			spiritAtk = info.BaseStats.Attack or 10
		end
	end
	local damage = (ability.Damage or 15)
		+ ((playerSpirit.Level or 1) * 3)
		+ math.floor(spiritAtk * 0.55)
		+ math.random(0, 6)
	if opts.DamageMultiplier then
		damage = math.floor(damage * opts.DamageMultiplier)
	end
	local elementTip
	damage, elementTip = applyElementDamage(damage, battlePlayerRef(battle), battleEnemyRef(battle))
	damage = applyTemperDamage(damage, playerSpirit, nil, battle)
	damage = EffectCatalog.ComputeDamage(damage, battle.PlayerEffects, battle.EnemyEffects)
	battle.EnemyHP = math.max(0, battle.EnemyHP - damage)
	local effectText = EffectCatalog.Apply(ability.Effect, battle.PlayerEffects, battle.EnemyEffects)

	local burnDamage
	battle.EnemyHP, burnDamage = EffectCatalog.ApplyBurnTick(battle.EnemyHP, battle.EnemyEffects)
	EffectCatalog.Step(battle.PlayerEffects)
	EffectCatalog.Step(battle.EnemyEffects)

	if battle.EnemyHP <= 0 then
		return {
			Ok = true,
			Kind = "Attack",
			Message = appendMatchup("Вы нанесли " .. damage .. " урона! (" .. ability.Name .. ")", elementTip),
			Ability = ability,
			Damage = damage,
			BurnDamage = burnDamage,
			EffectText = effectText,
			ElementTip = elementTip,
			Ended = true,
			Winner = "Player",
		}
	end

	battle.Turn = (battle.Turn or 1) + 1
	local msg = appendMatchup("Вы нанесли " .. damage .. " урона! (" .. ability.Name .. ")", elementTip)
	if effectText ~= "" then msg = msg .. " • " .. effectText end
	if burnDamage and burnDamage > 0 then msg = msg .. " • Горение: -" .. burnDamage .. " HP" end
	return {
		Ok = true,
		Kind = "Attack",
		Message = msg,
		Ability = ability,
		Damage = damage,
		BurnDamage = burnDamage,
		EffectText = effectText,
		ElementTip = elementTip,
		Ended = false,
	}
end

--- Fair PvP skill for either side (same formula; no PvE early-game nerf).
--- side: "Player" | "Enemy". opts: { DamageMultiplier = number, Now = number }
function BattleOrchestrator.ExecuteFairSkill(battle, side, skillIndex, opts)
	opts = opts or {}
	local now = opts.Now or os.clock()
	local ok, reason, ability = BattleOrchestrator.CanUseSkill(battle, side, skillIndex, now)
	if not ok then
		if reason == "Stun" then
			EffectCatalog.Step(battle.PlayerEffects)
			EffectCatalog.Step(battle.EnemyEffects)
			return { Ok = false, Kind = "Stun", Message = "Оглушение — ход пропущен", Ability = ability }
		end
		return { Ok = false, Kind = "Blocked", Message = reason or "Навык недоступен", Ability = ability }
	end

	spendAndCooldown(battle, side, skillIndex, ability, now)

	local attackerSpirit = (side == "Player") and battle.PlayerSpirit or battle.EnemySpirit
	local attackerInfo = (side == "Player") and battle.SpiritInfo or battle.EnemyInfo
	if not attackerSpirit then
		attackerSpirit = { Id = (attackerInfo and attackerInfo.Id) or 1, Level = 1 }
	end

	if ability.Type == "Heal" then
		local heal = math.max(1, math.floor((ability.HealAmount or 20) + ((attackerSpirit.Level or 1) * 1.5)))
		if side == "Player" then
			battle.PlayerHP = math.min(battle.PlayerMaxHP, battle.PlayerHP + heal)
			local effectText = EffectCatalog.Apply(ability.Effect, battle.PlayerEffects, battle.EnemyEffects)
			EffectCatalog.Step(battle.PlayerEffects)
			EffectCatalog.Step(battle.EnemyEffects)
			battle.Turn = (battle.Turn or 1) + 1
			local msg = "Восстановлено " .. heal .. " HP! (" .. ability.Name .. ")"
			if effectText ~= "" then msg = msg .. " • " .. effectText end
			return { Ok = true, Kind = "Heal", Message = msg, Ability = ability, Ended = false, Side = side }
		else
			battle.EnemyHP = math.min(battle.EnemyMaxHP, battle.EnemyHP + heal)
			local effectText = EffectCatalog.Apply(ability.Effect, battle.EnemyEffects, battle.PlayerEffects)
			EffectCatalog.Step(battle.PlayerEffects)
			EffectCatalog.Step(battle.EnemyEffects)
			battle.Turn = (battle.Turn or 1) + 1
			local msg = "Соперник восстановил " .. heal .. " HP! (" .. ability.Name .. ")"
			if effectText ~= "" then msg = msg .. " • " .. effectText end
			return { Ok = true, Kind = "Heal", Message = msg, Ability = ability, Ended = false, Side = side }
		end
	end

	local spiritAtk = 10
	do
		local info = SpiritDatabase.Get(attackerSpirit.Id)
		if info and info.BaseStats then
			spiritAtk = info.BaseStats.Attack or 10
		end
	end
	local damage = (ability.Damage or 15)
		+ ((attackerSpirit.Level or 1) * 3)
		+ math.floor(spiritAtk * 0.55)
		+ math.random(0, 6)
	if opts.DamageMultiplier then
		damage = math.floor(damage * opts.DamageMultiplier)
	end

	local defenderSpirit = (side == "Player") and battle.EnemySpirit or battle.PlayerSpirit
	damage = applyTemperDamage(damage, attackerSpirit, defenderSpirit, battle)
	local atkRef = (side == "Player") and battlePlayerRef(battle) or battleEnemyRef(battle)
	local defRef = (side == "Player") and battleEnemyRef(battle) or battlePlayerRef(battle)
	local elementTip
	damage, elementTip = applyElementDamage(damage, atkRef, defRef)

	local effectText
	local burnDamage
	if side == "Player" then
		damage = EffectCatalog.ComputeDamage(damage, battle.PlayerEffects, battle.EnemyEffects)
		battle.EnemyHP = math.max(0, battle.EnemyHP - damage)
		effectText = EffectCatalog.Apply(ability.Effect, battle.PlayerEffects, battle.EnemyEffects)
		battle.EnemyHP, burnDamage = EffectCatalog.ApplyBurnTick(battle.EnemyHP, battle.EnemyEffects)
	else
		damage = EffectCatalog.ComputeDamage(damage, battle.EnemyEffects, battle.PlayerEffects)
		battle.PlayerHP = math.max(0, battle.PlayerHP - damage)
		effectText = EffectCatalog.Apply(ability.Effect, battle.EnemyEffects, battle.PlayerEffects)
		battle.PlayerHP, burnDamage = EffectCatalog.ApplyBurnTick(battle.PlayerHP, battle.PlayerEffects)
	end
	EffectCatalog.Step(battle.PlayerEffects)
	EffectCatalog.Step(battle.EnemyEffects)

	local winner = nil
	if battle.EnemyHP <= 0 then
		winner = "Player"
	elseif battle.PlayerHP <= 0 then
		winner = "Enemy"
	end

	local actor = (side == "Player") and "Вы" or (battle.EnemyInfo and battle.EnemyInfo.Name or "Соперник")
	local msg = appendMatchup(actor .. ": " .. ability.Name .. "! -" .. damage .. " HP", elementTip)
	if effectText and effectText ~= "" then msg = msg .. " • " .. effectText end
	if burnDamage and burnDamage > 0 then msg = msg .. " • Горение: -" .. burnDamage .. " HP" end

	if winner then
		return {
			Ok = true,
			Kind = "Attack",
			Message = msg,
			Ability = ability,
			Damage = damage,
			BurnDamage = burnDamage,
			EffectText = effectText,
			ElementTip = elementTip,
			Ended = true,
			Winner = winner,
			Side = side,
		}
	end

	battle.Turn = (battle.Turn or 1) + 1
	return {
		Ok = true,
		Kind = "Attack",
		Message = msg,
		Ability = ability,
		Damage = damage,
		BurnDamage = burnDamage,
		EffectText = effectText,
		ElementTip = elementTip,
		Ended = false,
		Side = side,
	}
end

--- Execute an enemy skill against the player.
function BattleOrchestrator.ExecuteEnemySkill(battle, skillIndex, opts)
	opts = opts or {}
	local now = opts.Now or os.clock()
	local ok, reason, ability = BattleOrchestrator.CanUseSkill(battle, "Enemy", skillIndex, now)
	if not ok then
		if reason == "Stun" then
			EffectCatalog.Step(battle.PlayerEffects)
			EffectCatalog.Step(battle.EnemyEffects)
			local name = battle.EnemyInfo and battle.EnemyInfo.Name or "Враг"
			return { Ok = false, Kind = "Stun", Message = name .. " оглушен и пропускает ход", Ability = ability }
		end
		return { Ok = false, Kind = "Blocked", Message = reason, Ability = ability }
	end

	spendAndCooldown(battle, "Enemy", skillIndex, ability, now)

	local playerDef = 10
	do
		local pInfo = battle.PlayerSpirit and SpiritDatabase.Get(battle.PlayerSpirit.Id)
		if pInfo and pInfo.BaseStats then
			playerDef = pInfo.BaseStats.Defense or 10
		end
	end
	local rawEnemy = (ability.Damage or 10) + math.random(-2, 2)
	local level = (battle.PlayerSpirit and battle.PlayerSpirit.Level) or 1
	local earlyFactor = (level <= 5) and 0.65 or 0.85
	local elementTip
	local preDmg = math.max(3, math.floor(rawEnemy * earlyFactor) - math.floor(playerDef * 0.3))
	preDmg, elementTip = applyElementDamage(preDmg, battleEnemyRef(battle), battlePlayerRef(battle))
	local damage = EffectCatalog.ComputeDamage(
		preDmg,
		battle.EnemyEffects,
		battle.PlayerEffects
	)
	battle.PlayerHP = math.max(0, battle.PlayerHP - damage)
	local effectText = EffectCatalog.Apply(ability.Effect, battle.EnemyEffects, battle.PlayerEffects)

	local burnDamage
	battle.PlayerHP, burnDamage = EffectCatalog.ApplyBurnTick(battle.PlayerHP, battle.PlayerEffects)
	EffectCatalog.Step(battle.PlayerEffects)
	EffectCatalog.Step(battle.EnemyEffects)

	local name = battle.EnemyInfo and battle.EnemyInfo.Name or "Враг"
	if battle.PlayerHP <= 0 then
		return {
			Ok = true,
			Kind = "Attack",
			Message = appendMatchup(name .. ": " .. ability.Name .. "! -" .. damage .. " HP", elementTip),
			Ability = ability,
			Damage = damage,
			BurnDamage = burnDamage,
			EffectText = effectText,
			ElementTip = elementTip,
			Ended = true,
			Winner = "Enemy",
		}
	end

	local msg = appendMatchup(name .. ": " .. ability.Name .. "! -" .. damage .. " HP", elementTip)
	if effectText ~= "" then msg = msg .. " • " .. effectText end
	if burnDamage and burnDamage > 0 then msg = msg .. " • Горение: -" .. burnDamage .. " HP" end
	return {
		Ok = true,
		Kind = "Attack",
		Message = msg,
		Ability = ability,
		Damage = damage,
		BurnDamage = burnDamage,
		EffectText = effectText,
		Ended = false,
	}
end

return BattleOrchestrator
