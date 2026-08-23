--!strict
-- CombatAnimResolver: combat feel timing by SkillCatalog.CombatMeta
-- Body sword-swing animations removed (2026-08-23): blade tween + root lunge only.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local realmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local SkillCatalog = require(realmFolder:WaitForChild("SkillCatalog"))

local CombatAnimResolver = {}

export type AnimKind = "Slash" | "Lunge" | "SpellTap" | "SpellImpulse" | "RangedShot" | "None"

export type AnimTiming = {
	bladeWindup: number,
	bladeSlash: number,
	bladeRest: number,
	lungeOut: number,
	lungeBack: number,
	spellHold: number,
}

export type ClipVerifyResult = {
	assetId: string,
	length: number,
	ok: boolean,
	error: string?,
}

export type TrackVerifyResult = {
	track: string,
	assetId: string,
	length: number,
	ok: boolean,
	source: "folder" | "DG_CLIPS" | "FALLBACK",
	error: string?,
}

local HEAVY_MELEE_PHYSICAL: { [number]: boolean } = {
	[119] = true,
}

local HEAVY_MELEE_SPELL: { [number]: boolean } = {
	[303] = true,
}

type KindConfig = {
	speed: number,
	lunge: number,
	timing: AnimTiming,
}

local KIND_CONFIG: { [AnimKind]: KindConfig? } = {
	Slash = {
		speed = 1.55,
		lunge = 2.4,
		timing = { bladeWindup = 0.06, bladeSlash = 0.07, bladeRest = 0.10, lungeOut = 0.11, lungeBack = 0.13, spellHold = 0 },
	},
	Lunge = {
		speed = 0.9,
		lunge = 4.2,
		timing = { bladeWindup = 0.14, bladeSlash = 0.12, bladeRest = 0.18, lungeOut = 0.13, lungeBack = 0.17, spellHold = 0 },
	},
	SpellTap = {
		speed = 1.55,
		lunge = 2.0,
		timing = { bladeWindup = 0.05, bladeSlash = 0.06, bladeRest = 0.09, lungeOut = 0.10, lungeBack = 0.12, spellHold = 0 },
	},
	SpellImpulse = {
		speed = 0.92,
		lunge = 3.4,
		timing = { bladeWindup = 0.12, bladeSlash = 0.11, bladeRest = 0.16, lungeOut = 0.12, lungeBack = 0.15, spellHold = 0 },
	},
	RangedShot = {
		speed = 1.4,
		lunge = 0,
		timing = { bladeWindup = 0.05, bladeSlash = 0.06, bladeRest = 0.08, lungeOut = 0, lungeBack = 0, spellHold = 0 },
	},
}

local DEFAULT_TIMING: AnimTiming = {
	bladeWindup = 0.1,
	bladeSlash = 0.11,
	bladeRest = 0.14,
	lungeOut = 0.12,
	lungeBack = 0.18,
	spellHold = 0.12,
}

local function configFor(kind: AnimKind): KindConfig?
	return KIND_CONFIG[kind]
end

function CombatAnimResolver.GetResolvedClipId(_trackName: string): (string, "folder" | "DG_CLIPS" | "FALLBACK")
	return "", "FALLBACK"
end

function CombatAnimResolver.ResolveKind(skillId: number?): AnimKind
	local id = tonumber(skillId)
	if not id then
		return "Slash"
	end
	local meta = SkillCatalog.GetCombatMeta(id)
	if not meta then
		return "Slash"
	end
	if meta.Range == "Melee" and meta.DamageKind == "Physical" then
		if HEAVY_MELEE_PHYSICAL[id] then
			return "Lunge"
		end
		return "Slash"
	end
	if meta.Range == "Melee" and meta.DamageKind == "Spell" then
		if HEAVY_MELEE_SPELL[id] then
			return "SpellImpulse"
		end
		return "SpellTap"
	end
	if meta.Range == "Ranged" and meta.DamageKind == "Physical" then
		return "RangedShot"
	end
	return "None"
end

function CombatAnimResolver.GetLungeDistance(kind: AnimKind): number
	if kind == "None" then
		return 0
	end
	local cfg = configFor(kind)
	return cfg and cfg.lunge or 0
end

function CombatAnimResolver.GetPlaySpeed(kind: AnimKind): number
	local cfg = configFor(kind)
	return cfg and cfg.speed or 1.2
end

function CombatAnimResolver.GetTiming(kind: AnimKind): AnimTiming
	if kind == "None" then
		return DEFAULT_TIMING
	end
	local cfg = configFor(kind)
	return cfg and cfg.timing or DEFAULT_TIMING
end

function CombatAnimResolver.ShouldRootLunge(kind: AnimKind): boolean
	return kind ~= "None" and CombatAnimResolver.GetLungeDistance(kind) > 0.05
end

function CombatAnimResolver.ShouldBladeTween(kind: AnimKind): boolean
	return kind ~= "None"
end

function CombatAnimResolver.IsHeavyKind(kind: AnimKind): boolean
	return kind == "Lunge" or kind == "SpellImpulse"
end

function CombatAnimResolver.ShouldPlayBodyAnim(_kind: AnimKind): boolean
	return false
end

function CombatAnimResolver.VerifyClip(assetId: string, _humanoid: Humanoid?): ClipVerifyResult
	return {
		assetId = assetId,
		length = 0,
		ok = false,
		error = "body sword swing disabled",
	}
end

function CombatAnimResolver.VerifyAllClips(_humanoid: Humanoid?): { [string]: TrackVerifyResult }
	return {}
end

function CombatAnimResolver.Play(_char: Model, _humanoid: Humanoid, _skillId: number?): AnimationTrack?
	return nil
end

return CombatAnimResolver
