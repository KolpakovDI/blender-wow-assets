local ZoneConfig = {}

-- Магазин сдвинут на запад от Combat; Safe увеличен под 2x здание + Мику снаружи
ZoneConfig.HavenCenter = Vector3.new(-25, 0, 28)
ZoneConfig.AkihabaraOffset = Vector3.new(90, 0, 0)

ZoneConfig.Zones = {
	Genkan = {Center = Vector3.new(-25, 3, -6), Size = Vector3.new(12, 10, 8)},
	-- Safe увеличен на юг под Мику дальше от фасада
	Safe = {Center = Vector3.new(-25, 1, 28), Size = Vector3.new(100, 28, 160)},
	Exit = {Center = Vector3.new(-25, 1, 62), Size = Vector3.new(14, 10, 6)},
	-- Combat восточнее Safe (Safe X до ~25)
	Combat = {Center = Vector3.new(105, 1, 45), Size = Vector3.new(90, 20, 90)},
}

ZoneConfig.CounterPosition = Vector3.new(-30, 0, 0)
-- Мика снаружи, ещё ~20 studs от фасада (юг)
ZoneConfig.QuestMasterPosition = Vector3.new(-12, 0, -38)
ZoneConfig.QuestMasterHeightOffset = 0.25
ZoneConfig.SpawnPosition = Vector3.new(-25, 1, -45)
ZoneConfig.BattleArenaPosition = Vector3.new(236, 0, 40)

ZoneConfig.SpiritSpawnPositions = {
	[1] = Vector3.new(75, 0, 40),
	[2] = Vector3.new(95, 0, 30),
	[3] = Vector3.new(85, 0, 55),
	[4] = Vector3.new(115, 0, 50),
	[5] = Vector3.new(100, 0, 25),
}

function ZoneConfig.GetSpiritSpawnPositions()
	return ZoneConfig.SpiritSpawnPositions
end

ZoneConfig.Music = {
	Safe = {SoundId = "9043887091", Volume = 0.32},
	Genkan = {SoundId = "1848354536", Volume = 0.28},
	Exit = {SoundId = "9047104571", Volume = 0.34},
	Combat = {SoundId = "9047105584", Volume = 0.40},
}

ZoneConfig.GachaRobuxProductId = 0

return ZoneConfig