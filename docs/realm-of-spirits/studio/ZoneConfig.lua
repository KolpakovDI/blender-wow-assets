local ZoneConfig = {}

-- Магазин сдвинут на запад от Combat; Safe увеличен под 2x здание + Мику снаружи
ZoneConfig.HavenCenter = Vector3.new(-25, 0, 28)
ZoneConfig.AkihabaraOffset = Vector3.new(90, 0, 0)

ZoneConfig.Zones = {
	Genkan = {Center = Vector3.new(-25, 3, -6), Size = Vector3.new(12, 10, 8)},
	-- Safe увеличен на юг под Мику дальше от фасада
	Safe = {Center = Vector3.new(-25, 1, 28), Size = Vector3.new(100, 28, 160)},
	Exit = {Center = Vector3.new(-25, 1, 62), Size = Vector3.new(14, 10, 6)},
	-- Akihabara Combat (стартовый дух #1 Огненный Кот)
	Combat = {Center = Vector3.new(105, 1, 45), Size = Vector3.new(90, 20, 90)},
	-- PvE-карманы духов (разнесены для hunt-квестов)
	MistPond = {Center = Vector3.new(105, 1, 125), Size = Vector3.new(70, 18, 55)},
	FrostRidge = {Center = Vector3.new(20, 1, 160), Size = Vector3.new(55, 22, 50)},
	-- Вне купола BattleArena (RoofRing ~220×190 @ 236,40)
	ShadowHollow = {Center = Vector3.new(155, 1, -80), Size = Vector3.new(55, 20, 50)},
	StormSpire = {Center = Vector3.new(230, 1, 175), Size = Vector3.new(55, 24, 50)},
	DawnMeadow = {Center = Vector3.new(340, 1, 220), Size = Vector3.new(55, 20, 50)},
}

ZoneConfig.CounterPosition = Vector3.new(-30, 0, 0)
-- Мика снаружи, ещё ~20 studs от фасада (юг)
ZoneConfig.QuestMasterPosition = Vector3.new(-12, 0, -38)
ZoneConfig.QuestMasterHeightOffset = 0.25
ZoneConfig.SpawnPosition = Vector3.new(-25, 1, -45)
ZoneConfig.BattleArenaPosition = Vector3.new(236, 0, 40)
ZoneConfig.MistPondCenter = Vector3.new(105, 0, 125)

-- Базовые духи разнесены ≥~80 studs (под будущие hunt-квесты по очереди)
ZoneConfig.SpiritSpawnPositions = {
	[1] = Vector3.new(70, 0, 30), -- EmberCourt / Fire
	[2] = Vector3.new(20, 0, 160), -- FrostRidge / Ice
	[3] = Vector3.new(155, 0, -80), -- ShadowHollow / Dark
	[4] = Vector3.new(230, 0, 175), -- StormSpire / Lightning
	[5] = Vector3.new(340, 0, 220), -- DawnMeadow / Light
	[6] = Vector3.new(105, 1.5, 125), -- MistPond / Water
}

-- Метаданные для будущей цепочки «ловить по очереди»
ZoneConfig.SpiritHabitats = {
	[1] = {ZoneKey = "Combat", Label = "Угольный двор", HuntOrder = 1, Element = "Fire"},
	[2] = {ZoneKey = "FrostRidge", Label = "Морозный хребет", HuntOrder = 2, Element = "Ice"},
	[6] = {ZoneKey = "MistPond", Label = "Туманный пруд", HuntOrder = 3, Element = "Water"},
	[3] = {ZoneKey = "ShadowHollow", Label = "Теневая лощина", HuntOrder = 4, Element = "Dark"},
	[4] = {ZoneKey = "StormSpire", Label = "Грозовой шпиль", HuntOrder = 5, Element = "Lightning"},
	[5] = {ZoneKey = "DawnMeadow", Label = "Луг рассвета", HuntOrder = 6, Element = "Light"},
}

function ZoneConfig.GetSpiritSpawnPositions()
	return ZoneConfig.SpiritSpawnPositions
end

function ZoneConfig.GetSpiritHabitats()
	return ZoneConfig.SpiritHabitats
end

ZoneConfig.Music = {
	Safe = {SoundId = "9043887091", Volume = 0.32},
	Genkan = {SoundId = "1848354536", Volume = 0.28},
	Exit = {SoundId = "9047104571", Volume = 0.34},
	Combat = {SoundId = "9047105584", Volume = 0.40},
	MistPond = {SoundId = "9047105584", Volume = 0.36},
	FrostRidge = {SoundId = "9047105584", Volume = 0.36},
	ShadowHollow = {SoundId = "9047105584", Volume = 0.38},
	StormSpire = {SoundId = "9047105584", Volume = 0.40},
	DawnMeadow = {SoundId = "9047105584", Volume = 0.34},
}

ZoneConfig.GachaRobuxProductId = 0

return ZoneConfig
