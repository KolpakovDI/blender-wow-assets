-- ZoneSystem - tracks Safe / Combat zones (GDD v2.0)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RealmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
require(RealmFolder:WaitForChild("ZoneConfig"))

local zoneChanged = RealmFolder:FindFirstChild("ZoneChanged")
if not zoneChanged then
	zoneChanged = Instance.new("RemoteEvent")
	zoneChanged.Name = "ZoneChanged"
	zoneChanged.Parent = RealmFolder
end

local playerZone = {}
local playerDetail = {}

-- Приоритет при перекрытии объёмов (Safe большой и пересекает Genkan/Exit)
local DETAIL_PRIORITY = {
	Combat = 40,
	Akihabara = 40,
	MistPond = 45,
	FrostRidge = 45,
	ShadowHollow = 45,
	StormSpire = 45,
	DawnMeadow = 45,
	StoneBasin = 45,
	AshGarden = 45,
	Moonwell = 45,
	VenomHollow = 45,
	SandDunes = 45,
	IronWastes = 45,
	CrystalCaves = 45,
	MagmaFissure = 45,
	FogBasin = 45,
	SkyRidge = 45,
	Exit = 30,
	Genkan = 20,
	Safe = 10,
	Spawn = 0,
}

local function setPlayerZone(player, zoneType, detail)
	detail = detail or zoneType
	if playerZone[player] == zoneType and playerDetail[player] == detail then
		return
	end
	playerZone[player] = zoneType
	playerDetail[player] = detail
	player:SetAttribute("CurrentZone", zoneType)
	player:SetAttribute("ZoneDetail", detail)
	zoneChanged:FireClient(player, zoneType, detail)
end

local function classifyDetail(detail)
	if detail == "Genkan" or detail == "Safe" or detail == "Exit" or detail == "Spawn" then
		return "Safe", detail
	end
	local combatDetails = {
		Combat = true,
		Akihabara = true,
		MistPond = true,
		FrostRidge = true,
		ShadowHollow = true,
		StormSpire = true,
		DawnMeadow = true,
		StoneBasin = true,
		AshGarden = true,
		Moonwell = true,
		VenomHollow = true,
		SandDunes = true,
		IronWastes = true,
		CrystalCaves = true,
		MagmaFissure = true,
		FogBasin = true,
		SkyRidge = true,
	}
	if combatDetails[detail] then
		if detail == "Combat" then
			return "Combat", "Akihabara"
		end
		return "Combat", detail
	end
	return nil, nil
end

local function ensureZonePartsQueryable()
	for _, d in ipairs(Workspace:GetDescendants()) do
		if d:IsA("BasePart") and d:GetAttribute("ZoneType") then
			d.CanQuery = true
		end
	end
end

ensureZonePartsQueryable()
Workspace.DescendantAdded:Connect(function(d)
	if d:IsA("BasePart") and d:GetAttribute("ZoneType") then
		d.CanQuery = true
	end
end)

local overlapParams = OverlapParams.new()
overlapParams.FilterType = Enum.RaycastFilterType.Exclude

local function sampleZoneAt(position)
	local parts = Workspace:GetPartBoundsInBox(CFrame.new(position - Vector3.new(0, 1.5, 0)), Vector3.new(3, 10, 3), overlapParams)
	local bestDetail = nil
	local bestScore = -1
	for _, part in ipairs(parts) do
		local zt = part:GetAttribute("ZoneType")
		if zt then
			local score = DETAIL_PRIORITY[zt] or 0
			if score > bestScore then
				bestScore = score
				bestDetail = zt
			end
		end
	end
	if not bestDetail then
		return nil, nil
	end
	return classifyDetail(bestDetail)
end

local function onCharacterAdded(player, character)
	local hrp = character:WaitForChild("HumanoidRootPart", 10)
	if not hrp then return end

	setPlayerZone(player, "Safe", "Spawn")

	local running = true
	character.AncestryChanged:Connect(function(_, parent)
		if not parent then
			running = false
		end
	end)

	task.spawn(function()
		while running and character.Parent and hrp.Parent do
			local zone, detail = sampleZoneAt(hrp.Position)
			if zone and detail then
				setPlayerZone(player, zone, detail)
			end
			task.wait(0.2)
		end
	end)
end

local function onPlayerAdded(player)
	playerZone[player] = nil
	playerDetail[player] = nil
	player:SetAttribute("CurrentZone", "Safe")
	player:SetAttribute("ZoneDetail", "Spawn")
	player.CharacterAdded:Connect(function(char)
		onCharacterAdded(player, char)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do
	onPlayerAdded(p)
end

print("Realm of Spirits - ZoneSystem loaded!")
