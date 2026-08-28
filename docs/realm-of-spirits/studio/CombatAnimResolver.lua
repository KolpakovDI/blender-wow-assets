--!strict
-- CombatAnimResolver: combat feel + body animation by SkillCatalog.CombatMeta
-- A1 restore (2026-08-28): Linked Sword free IDs · folder → DG_CLIPS → FALLBACK
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

-- Production free set (verified 2026-08-23). Proprietary DG IDs remain nil.
local DG_CLIPS: { [string]: string? } = {
	SlashR15 = "rbxassetid://522635514",
	LungeR15 = "rbxassetid://522638767",
	SpellTapR15 = "rbxassetid://522635514",
	SpellImpulseR15 = "rbxassetid://522638767",
	RangedShotR15 = "rbxassetid://522635514",
	SlashR6 = "rbxassetid://129967390",
}

local FALLBACK_IDS: { [string]: string } = {
	SlashR15 = "rbxassetid://522635514",
	LungeR15 = "rbxassetid://522638767",
	SpellTapR15 = "rbxassetid://522635514",
	SpellImpulseR15 = "rbxassetid://522638767",
	RangedShotR15 = "rbxassetid://522635514",
	SlashR6 = "rbxassetid://129967390",
}

local TRACK_ALIASES: { [string]: string } = {
	SpellTapR15 = "SlashR15",
	SpellImpulseR15 = "LungeR15",
	RangedShotR15 = "SlashR15",
}

local VERIFY_TRACKS = { "SlashR15", "LungeR15", "SpellTapR15", "SpellImpulseR15", "RangedShotR15", "SlashR6" }

local HEAVY_MELEE_PHYSICAL: { [number]: boolean } = {
	[119] = true,
}

local HEAVY_MELEE_SPELL: { [number]: boolean } = {
	[303] = true,
}

local trackCache: { [Humanoid]: { [AnimKind]: AnimationTrack } } = {}

type KindConfig = {
	folderR15: string,
	folderR6: string,
	speed: number,
	lunge: number,
	timing: AnimTiming,
}

local KIND_CONFIG: { [AnimKind]: KindConfig? } = {
	Slash = {
		folderR15 = "SlashR15",
		folderR6 = "SlashR6",
		speed = 1.55,
		lunge = 2.4,
		timing = { bladeWindup = 0.06, bladeSlash = 0.07, bladeRest = 0.10, lungeOut = 0.11, lungeBack = 0.13, spellHold = 0 },
	},
	Lunge = {
		folderR15 = "LungeR15",
		folderR6 = "SlashR6",
		speed = 0.9,
		lunge = 4.2,
		timing = { bladeWindup = 0.14, bladeSlash = 0.12, bladeRest = 0.18, lungeOut = 0.13, lungeBack = 0.17, spellHold = 0 },
	},
	SpellTap = {
		folderR15 = "SpellTapR15",
		folderR6 = "SlashR6",
		speed = 1.55,
		lunge = 2.0,
		timing = { bladeWindup = 0.05, bladeSlash = 0.06, bladeRest = 0.09, lungeOut = 0.10, lungeBack = 0.12, spellHold = 0 },
	},
	SpellImpulse = {
		folderR15 = "SpellImpulseR15",
		folderR6 = "SlashR6",
		speed = 0.92,
		lunge = 3.4,
		timing = { bladeWindup = 0.12, bladeSlash = 0.11, bladeRest = 0.16, lungeOut = 0.12, lungeBack = 0.15, spellHold = 0 },
	},
	RangedShot = {
		folderR15 = "RangedShotR15",
		folderR6 = "SlashR6",
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

local COMBAT_PRIORITY = Enum.AnimationPriority.Action4

local function normalizeAssetId(raw: string): string
	local trimmed = string.gsub(raw, "^%s+", "")
	trimmed = string.gsub(trimmed, "%s+$", "")
	if trimmed == "" then
		return ""
	end
	if string.find(trimmed, "rbxassetid://", 1, true) then
		return trimmed
	end
	if tonumber(trimmed) then
		return "rbxassetid://" .. trimmed
	end
	return trimmed
end

local function folderAnim(name: string): Animation?
	local folder = realmFolder:FindFirstChild("CombatAnimations")
	if not folder then
		return nil
	end
	local inst = folder:FindFirstChild(name)
	if inst and inst:IsA("Animation") then
		return inst
	end
	return nil
end

local function resolveTrackId(trackName: string): (string, "folder" | "DG_CLIPS" | "FALLBACK")
	local fromFolder = folderAnim(trackName)
	if fromFolder then
		local folderId = normalizeAssetId(fromFolder.AnimationId)
		if folderId ~= "" then
			return folderId, "folder"
		end
	end

	local dg = DG_CLIPS[trackName]
	if dg and dg ~= "" then
		return normalizeAssetId(dg), "DG_CLIPS"
	end

	local aliasTrack = TRACK_ALIASES[trackName]
	if aliasTrack then
		local aliasDg = DG_CLIPS[aliasTrack]
		if aliasDg and aliasDg ~= "" then
			return normalizeAssetId(aliasDg), "DG_CLIPS"
		end
	end

	local fallback = FALLBACK_IDS[trackName]
	if fallback then
		return fallback, "FALLBACK"
	end
	if aliasTrack then
		local aliasFallback = FALLBACK_IDS[aliasTrack]
		if aliasFallback then
			return aliasFallback, "FALLBACK"
		end
	end
	return FALLBACK_IDS.SlashR15, "FALLBACK"
end

local function configFor(kind: AnimKind): KindConfig?
	return KIND_CONFIG[kind]
end

local function isR15(char: Model): boolean
	return char:FindFirstChild("UpperTorso") ~= nil
end

local function getAnimator(humanoid: Humanoid): Animator
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	return animator
end

local function stopConflictingTracks(animator: Animator)
	for _, playing in animator:GetPlayingAnimationTracks() do
		if playing.Priority.Value < COMBAT_PRIORITY.Value then
			playing:Stop(0.04)
		end
	end
end

local function createSmokeHumanoid(): (Model, Humanoid)
	local existing = workspace:FindFirstChild("_CombatAnimSmokeDummy")
	if existing and existing:IsA("Model") then
		local hum = existing:FindFirstChildOfClass("Humanoid")
		if hum then
			return existing, hum
		end
		existing:Destroy()
	end

	local model = Instance.new("Model")
	model.Name = "_CombatAnimSmokeDummy"
	local hum = Instance.new("Humanoid")
	hum.Parent = model
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Anchored = true
	root.CanCollide = false
	root.Transparency = 1
	root.Parent = model
	model.PrimaryPart = root
	model.Parent = workspace
	return model, hum
end

function CombatAnimResolver.GetResolvedClipId(trackName: string): (string, "folder" | "DG_CLIPS" | "FALLBACK")
	return resolveTrackId(trackName)
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

function CombatAnimResolver.ShouldPlayBodyAnim(kind: AnimKind): boolean
	return kind ~= "None"
end

function CombatAnimResolver.VerifyClip(assetId: string, humanoid: Humanoid?): ClipVerifyResult
	local normalized = normalizeAssetId(assetId)
	if normalized == "" then
		return { assetId = "", length = 0, ok = false, error = "empty assetId" }
	end

	local hum = humanoid
	local createdDummy = false
	if not hum then
		_, hum = createSmokeHumanoid()
		createdDummy = true
	end

	local animator = getAnimator(hum)
	local anim = Instance.new("Animation")
	anim.AnimationId = normalized
	local okLoad, track = pcall(function()
		return animator:LoadAnimation(anim)
	end)

	if not okLoad or not track then
		if createdDummy then
			local dummy = workspace:FindFirstChild("_CombatAnimSmokeDummy")
			if dummy then
				dummy:Destroy()
			end
		end
		return {
			assetId = normalized,
			length = 0,
			ok = false,
			error = if typeof(track) == "string" then track else "LoadAnimation failed",
		}
	end

	local length = track.Length
	track:Stop(0)
	track:Destroy()

	if createdDummy then
		local dummy = workspace:FindFirstChild("_CombatAnimSmokeDummy")
		if dummy then
			dummy:Destroy()
		end
	end

	return {
		assetId = normalized,
		length = length,
		ok = length > 0,
		error = if length > 0 then nil else "Length == 0",
	}
end

function CombatAnimResolver.VerifyAllClips(humanoid: Humanoid?): { [string]: TrackVerifyResult }
	local hum = humanoid
	if not hum then
		_, hum = createSmokeHumanoid()
	end

	local results: { [string]: TrackVerifyResult } = {}
	for _, trackName in VERIFY_TRACKS do
		local assetId, source = resolveTrackId(trackName)
		local verify = CombatAnimResolver.VerifyClip(assetId, hum)
		results[trackName] = {
			track = trackName,
			assetId = assetId,
			length = verify.length,
			ok = verify.ok,
			source = source,
			error = verify.error,
		}
	end

	if not humanoid then
		local dummy = workspace:FindFirstChild("_CombatAnimSmokeDummy")
		if dummy then
			dummy:Destroy()
		end
	end

	return results
end

local function animationFor(char: Model, kind: AnimKind): Animation?
	local cfg = configFor(kind)
	if not cfg then
		return nil
	end
	local folderName = if isR15(char) then cfg.folderR15 else cfg.folderR6
	local fromFolder = folderAnim(folderName)
	if fromFolder then
		local folderId = normalizeAssetId(fromFolder.AnimationId)
		if folderId ~= "" then
			return fromFolder
		end
	end

	local resolvedId = resolveTrackId(folderName)
	local anim = Instance.new("Animation")
	anim.AnimationId = resolvedId
	return anim
end

local function getOrLoadTrack(humanoid: Humanoid, anim: Animation, kind: AnimKind): AnimationTrack?
	local humTracks = trackCache[humanoid]
	if humTracks then
		local cached = humTracks[kind]
		if cached then
			return cached
		end
	end
	local animator = getAnimator(humanoid)
	local ok, track = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	if ok and track then
		if not trackCache[humanoid] then
			trackCache[humanoid] = {}
		end
		trackCache[humanoid][kind] = track
		return track
	end
	return nil
end

function CombatAnimResolver.Play(char: Model, humanoid: Humanoid, skillId: number?): AnimationTrack?
	local kind = CombatAnimResolver.ResolveKind(skillId)
	if kind == "None" then
		return nil
	end
	local anim = animationFor(char, kind)
	if not anim or not humanoid then
		return nil
	end
	local track = getOrLoadTrack(humanoid, anim, kind)
	if track then
		local animator = getAnimator(humanoid)
		stopConflictingTracks(animator)
		track:Stop(0)
		track.Priority = COMBAT_PRIORITY
		local speed = CombatAnimResolver.GetPlaySpeed(kind)
		track:Play(0.05, 1, speed)
		track:AdjustWeight(1, 0.05)
		return track
	end
	return nil
end

return CombatAnimResolver
