-- MusicController
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local RealmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local zoneChanged = RealmFolder:WaitForChild("ZoneChanged")
local ZoneConfig = require(RealmFolder:WaitForChild("ZoneConfig"))

local FADE = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local DEFAULT_ZONE_KEY = "Safe"

local musicFolder = Instance.new("Folder")
musicFolder.Name = "ZoneMusic"
musicFolder.Parent = player:WaitForChild("PlayerGui")

local function normalizeSoundId(raw)
	if type(raw) ~= "string" then
		return ""
	end
	if raw == "" then
		return ""
	end
	if string.find(raw, "rbxassetid://", 1, true) then
		return raw
	end
	if tonumber(raw) then
		return "rbxassetid://" .. raw
	end
	return ""
end

local function resolveMusicEntry(key)
	local cfg = ZoneConfig.Music or {}
	local entry = cfg[key]
	if type(entry) == "table" then
		return {
			SoundId = normalizeSoundId(entry.SoundId or ""),
			Volume = tonumber(entry.Volume) or 0.35,
		}
	end
	if type(entry) == "string" then
		return {
			SoundId = normalizeSoundId(entry),
			Volume = 0.35,
		}
	end
	return {
		SoundId = "",
		Volume = 0.35,
	}
end

local tracks = {}
for zoneName in pairs(ZoneConfig.Music or {}) do
	local entry = resolveMusicEntry(zoneName)
	local sound = Instance.new("Sound")
	sound.Name = zoneName .. "BGM"
	sound.Looped = true
	sound.Volume = 0
	sound.SoundId = entry.SoundId
	sound.Parent = musicFolder
	tracks[zoneName] = {
		Sound = sound,
		Volume = entry.Volume,
	}
end

if not tracks[DEFAULT_ZONE_KEY] then
	local fallback = Instance.new("Sound")
	fallback.Name = DEFAULT_ZONE_KEY .. "BGM"
	fallback.Looped = true
	fallback.Volume = 0
	fallback.SoundId = ""
	fallback.Parent = musicFolder
	tracks[DEFAULT_ZONE_KEY] = {
		Sound = fallback,
		Volume = 0.35,
	}
end

local function fadeTo(sound, targetVolume)
	if sound.SoundId == "" then
		return
	end
	if targetVolume > 0 and not sound.IsPlaying then
		local ok, err = pcall(function()
			sound:Play()
		end)
		if not ok then
			warn("[MusicController] Play failed for", sound.Name, err)
			return
		end
	end
	TweenService:Create(sound, FADE, {Volume = targetVolume}):Play()
	if targetVolume <= 0 then
		task.delay(FADE.Time + 0.1, function()
			if sound.Volume <= 0.01 then
				sound:Stop()
			end
		end)
	end
end

local warnedTracks = {}
local function watchTrackLoad(zoneName, sound)
	if sound.SoundId == "" then return end
	task.spawn(function()
		local t0 = os.clock()
		while sound.Parent and not sound.IsLoaded and os.clock() - t0 < 8 do
			task.wait(0.25)
		end
		if sound.Parent and not sound.IsLoaded and not warnedTracks[zoneName] then
			warnedTracks[zoneName] = true
			warn("[MusicController] SoundId не загрузился для зоны", zoneName, sound.SoundId, "— замените в ZoneConfig.Music (privacy/одобрение ассета)")
		end
	end)
end

for zoneName, track in pairs(tracks) do
	watchTrackLoad(zoneName, track.Sound)
end

-- ZoneDetail keys (Genkan/Exit/Safe/Spawn) map to ZoneConfig.Music tracks when present
local function resolveZoneKey(zoneType, detail)
	local key = detail or zoneType
	if key == "MistPond" and tracks.MistPond then
		return "MistPond"
	end
	if key == "Akihabara" or (zoneType == "Combat" and key ~= "MistPond") then
		return "Combat"
	end
	if tracks[key] then
		return key
	end
	if tracks[zoneType] then
		return zoneType
	end
	return DEFAULT_ZONE_KEY
end

local function applyZoneMusic(zoneType, detail)
	local key = resolveZoneKey(zoneType, detail)
	for zoneName, track in pairs(tracks) do
		local volume = (zoneName == key and track.Sound.SoundId ~= "") and track.Volume or 0
		fadeTo(track.Sound, volume)
	end
end

zoneChanged.OnClientEvent:Connect(function(zoneType, detail)
	applyZoneMusic(zoneType, detail)
end)
player:GetAttributeChangedSignal("CurrentZone"):Connect(function()
	applyZoneMusic(player:GetAttribute("CurrentZone") or DEFAULT_ZONE_KEY, player:GetAttribute("ZoneDetail"))
end)
player:GetAttributeChangedSignal("ZoneDetail"):Connect(function()
	applyZoneMusic(player:GetAttribute("CurrentZone") or DEFAULT_ZONE_KEY, player:GetAttribute("ZoneDetail"))
end)

task.defer(function()
	applyZoneMusic(player:GetAttribute("CurrentZone") or DEFAULT_ZONE_KEY, player:GetAttribute("ZoneDetail"))
end)

print("Realm of Spirits - MusicController loaded!")
