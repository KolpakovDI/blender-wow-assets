local ZoneConfig = {}

ZoneConfig.HavenCenter = Vector3.new(0, 0, 35)
ZoneConfig.AkihabaraOffset = Vector3.new(70, 0, 0)

ZoneConfig.Zones = {
	Genkan = {Center = Vector3.new(0, 1, 28), Size = Vector3.new(8, 6, 6)},
	Safe = {Center = Vector3.new(0, 1, 35), Size = Vector3.new(36, 12, 36)},
	Exit = {Center = Vector3.new(0, 1, 52), Size = Vector3.new(10, 8, 4)},
	Combat = {Center = Vector3.new(70, 1, 35), Size = Vector3.new(120, 20, 120)},
}

ZoneConfig.CounterPosition = Vector3.new(-6, 0, 38)
ZoneConfig.QuestMasterPosition = Vector3.new(-30, 0, 35)
ZoneConfig.QuestMasterHeightOffset = 0.25
ZoneConfig.SpawnPosition = Vector3.new(0, 1, 11)

ZoneConfig.SpiritSpawnPositions = {
	[1] = Vector3.new(55, 0, 40),
	[2] = Vector3.new(75, 0, 30),
	[3] = Vector3.new(65, 0, 50),
	[4] = Vector3.new(85, 0, 45),
	[5] = Vector3.new(70, 0, 25),
}

function ZoneConfig.GetSpiritSpawnPositions()
	return ZoneConfig.SpiritSpawnPositions
end

-- Заполняйте SoundId числом или rbxassetid://<id> (можно заменить своими треками)
ZoneConfig.Music = {
	Safe = {SoundId = "9043887091", Volume = 0.32}, -- Lo-Fi chill
	Genkan = {SoundId = "1848354536", Volume = 0.28}, -- relaxed
	Exit = {SoundId = "9047104571", Volume = 0.34}, -- transition
	Combat = {SoundId = "9047105584", Volume = 0.40}, -- J-Rock-ish energy
}

return ZoneConfig
