-- EffectCatalog - battle status effect types
local EffectCatalog = {}

EffectCatalog.Types = {
	Burn = {
		Id = "Burn",
		DisplayName = "Горение",
		Target = "Enemy",
		Tick = "HP",
		Stack = "Max",
	},
	Stun = {
		Id = "Stun",
		DisplayName = "Оглушение",
		Target = "Enemy",
		Tick = "SkipAction",
		Stack = "Max",
	},
	BuffAttack = {
		Id = "BuffAttack",
		DisplayName = "Усиление атаки",
		Target = "Self",
		Stat = "AttackMul",
		Stack = "Max",
	},
	BuffDefense = {
		Id = "BuffDefense",
		DisplayName = "Усиление защиты",
		Target = "Self",
		Stat = "DefenseMul",
		Stack = "Max",
	},
	DebuffAttack = {
		Id = "DebuffAttack",
		DisplayName = "Ослабление атаки",
		Target = "Enemy",
		Stat = "AttackMul",
		Stack = "Min",
	},
	DebuffDefense = {
		Id = "DebuffDefense",
		DisplayName = "Ослабление защиты",
		Target = "Enemy",
		Stat = "DefenseMul",
		Stack = "Min",
	},
}

function EffectCatalog.Get(typeName)
	return EffectCatalog.Types[typeName]
end

function EffectCatalog.GetDisplayName(typeName)
	local t = EffectCatalog.Types[typeName]
	return t and t.DisplayName or typeName
end

function EffectCatalog.CreateState()
	return {
		AttackMul = 1,
		DefenseMul = 1,
		BurnDamage = 0,
		BurnLeft = 0,
		StunLeft = 0,
		BuffAttackLeft = 0,
		BuffDefenseLeft = 0,
		DebuffAttackLeft = 0,
		DebuffDefenseLeft = 0,
	}
end

function EffectCatalog.Apply(effect, sourceEffects, targetEffects)
	if not effect then return "" end
	local value = effect.Value or 0
	local duration = math.max(1, effect.Duration or 1)
	local meta = EffectCatalog.Types[effect.Type]
	if effect.Type == "Burn" then
		targetEffects.BurnDamage = math.max(targetEffects.BurnDamage, math.max(1, math.floor(value)))
		targetEffects.BurnLeft = math.max(targetEffects.BurnLeft, duration)
	elseif effect.Type == "Stun" then
		targetEffects.StunLeft = math.max(targetEffects.StunLeft, duration)
	elseif effect.Type == "BuffAttack" then
		sourceEffects.AttackMul = math.max(sourceEffects.AttackMul, 1 + value)
		sourceEffects.BuffAttackLeft = math.max(sourceEffects.BuffAttackLeft, duration)
	elseif effect.Type == "BuffDefense" then
		sourceEffects.DefenseMul = math.max(sourceEffects.DefenseMul, 1 + value)
		sourceEffects.BuffDefenseLeft = math.max(sourceEffects.BuffDefenseLeft, duration)
	elseif effect.Type == "DebuffAttack" then
		targetEffects.AttackMul = math.min(targetEffects.AttackMul, math.max(0.35, 1 - value))
		targetEffects.DebuffAttackLeft = math.max(targetEffects.DebuffAttackLeft, duration)
	elseif effect.Type == "DebuffDefense" then
		targetEffects.DefenseMul = math.min(targetEffects.DefenseMul, math.max(0.35, 1 - value))
		targetEffects.DebuffDefenseLeft = math.max(targetEffects.DebuffDefenseLeft, duration)
	else
		return ""
	end
	return meta and meta.DisplayName or effect.Type
end

function EffectCatalog.Step(effects)
	if effects.BurnLeft > 0 then effects.BurnLeft = effects.BurnLeft - 1 end
	if effects.BurnLeft <= 0 then effects.BurnDamage = 0 end
	if effects.StunLeft > 0 then effects.StunLeft = effects.StunLeft - 1 end
	if effects.BuffAttackLeft > 0 then effects.BuffAttackLeft = effects.BuffAttackLeft - 1 end
	if effects.BuffAttackLeft <= 0 and effects.AttackMul > 1 then effects.AttackMul = 1 end
	if effects.BuffDefenseLeft > 0 then effects.BuffDefenseLeft = effects.BuffDefenseLeft - 1 end
	if effects.BuffDefenseLeft <= 0 and effects.DefenseMul > 1 then effects.DefenseMul = 1 end
	if effects.DebuffAttackLeft > 0 then effects.DebuffAttackLeft = effects.DebuffAttackLeft - 1 end
	if effects.DebuffAttackLeft <= 0 and effects.AttackMul < 1 then effects.AttackMul = 1 end
	if effects.DebuffDefenseLeft > 0 then effects.DebuffDefenseLeft = effects.DebuffDefenseLeft - 1 end
	if effects.DebuffDefenseLeft <= 0 and effects.DefenseMul < 1 then effects.DefenseMul = 1 end
end

function EffectCatalog.ComputeDamage(baseDamage, attackerEffects, defenderEffects)
	local atkMul = attackerEffects and attackerEffects.AttackMul or 1
	local defMul = defenderEffects and defenderEffects.DefenseMul or 1
	return math.max(1, math.floor(baseDamage * atkMul / math.max(0.35, defMul)))
end

function EffectCatalog.ApplyBurnTick(currentHp, effects)
	if effects.BurnLeft > 0 and effects.BurnDamage > 0 then
		return math.max(0, currentHp - effects.BurnDamage), effects.BurnDamage
	end
	return currentHp, 0
end

return EffectCatalog
