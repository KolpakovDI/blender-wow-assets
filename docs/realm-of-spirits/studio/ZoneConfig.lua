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
	-- Водный Карп: прибрежное море (CoastalShowcase), не пруд у Combat
	MistPond = {Center = Vector3.new(30, 2, -880), Size = Vector3.new(120, 24, 100)},
	FrostRidge = {Center = Vector3.new(20, 1, 160), Size = Vector3.new(55, 22, 50)},
	-- Вне купола BattleArena (RoofRing ~220×190 @ 236,40)
	ShadowHollow = {Center = Vector3.new(155, 1, -80), Size = Vector3.new(55, 20, 50)},
	StormSpire = {Center = Vector3.new(230, 1, 175), Size = Vector3.new(55, 24, 50)},
	DawnMeadow = {Center = Vector3.new(340, 1, 220), Size = Vector3.new(55, 20, 50)},
	StoneBasin = {Center = Vector3.new(-80, 1, -120), Size = Vector3.new(55, 22, 50)},
	AshGarden = {Center = Vector3.new(175, 1, 50), Size = Vector3.new(55, 22, 50)},
	-- Wind (#9 Ветряной Лис) — западнее FrostRidge
	GaleCliff = {Center = Vector3.new(-140, 1, 180), Size = Vector3.new(55, 22, 50)},
	-- Nature (#10 Моховой Олень)
	MossGlade = {Center = Vector3.new(50, 1, -200), Size = Vector3.new(55, 22, 50)},
	-- Moon (#11 Лунный Кролик)
	Moonwell = {Center = Vector3.new(-220, 1, -160), Size = Vector3.new(55, 22, 50)},
	-- Poison (#12 Ядовитая Гадюка)
	VenomHollow = {Center = Vector3.new(280, 1, -160), Size = Vector3.new(55, 22, 50)},
	-- Sand (#13 Пустынный Скорпион)
	SandDunes = {Center = Vector3.new(360, 1, -40), Size = Vector3.new(55, 22, 50)},
}

ZoneConfig.CounterPosition = Vector3.new(-30, 0, 0)
-- Мика снаружи, ещё ~20 studs от фасада (юг)
ZoneConfig.QuestMasterPosition = Vector3.new(-12, 0, -38)
ZoneConfig.QuestMasterHeightOffset = 0.25
-- Пол Haven (ближе к центру Safe / магазину)
ZoneConfig.SpawnPosition = Vector3.new(-25, 1, 18)
ZoneConfig.BattleArenaPosition = Vector3.new(236, 0, 40)
ZoneConfig.MistPondCenter = Vector3.new(30, 1, -880)

-- Базовые духи разнесены ≥~80 studs (под будущие hunt-квесты по очереди)
ZoneConfig.SpiritSpawnPositions = {
	[1] = Vector3.new(70, 0, 30), -- EmberCourt / Fire
	[2] = Vector3.new(20, 0, 160), -- FrostRidge / Ice
	[3] = Vector3.new(155, 0, -80), -- ShadowHollow / Dark
	[4] = Vector3.new(230, 0, 175), -- StormSpire / Lightning
	[5] = Vector3.new(340, 0, 220), -- DawnMeadow / Light
	[6] = Vector3.new(30, 2, -880), -- MistPond / coastal sea / Water
	[7] = Vector3.new(-80, 0, -120), -- StoneBasin / Earth
	[8] = Vector3.new(175, 0, 50), -- AshGarden / Fire ash
	[9] = Vector3.new(-140, 0, 180), -- GaleCliff / Wind
	[10] = Vector3.new(50, 0, -200), -- MossGlade / Nature
	[11] = Vector3.new(-220, 0, -160), -- Moonwell / Moon
	[12] = Vector3.new(280, 0, -160), -- VenomHollow / Poison
	[13] = Vector3.new(360, 0, -40), -- SandDunes / Sand
}

-- Метаданные для будущей цепочки «ловить по очереди»
ZoneConfig.SpiritHabitats = {
	[1] = {ZoneKey = "Combat", Label = "Угольный двор", HuntOrder = 1, Element = "Fire"},
	[2] = {ZoneKey = "FrostRidge", Label = "Морозный хребет", HuntOrder = 2, Element = "Ice"},
	[6] = {ZoneKey = "MistPond", Label = "Прибрежное море", HuntOrder = 3, Element = "Water"},
	[3] = {ZoneKey = "ShadowHollow", Label = "Теневая лощина", HuntOrder = 4, Element = "Dark"},
	[4] = {ZoneKey = "StormSpire", Label = "Грозовой шпиль", HuntOrder = 5, Element = "Lightning"},
	[5] = {ZoneKey = "DawnMeadow", Label = "Луг рассвета", HuntOrder = 6, Element = "Light"},
	[7] = {ZoneKey = "StoneBasin", Label = "Каменный бассейн", HuntOrder = 7, Element = "Earth"},
	[8] = {ZoneKey = "AshGarden", Label = "Пепельный сад", HuntOrder = 8, Element = "Fire"},
	[9] = {ZoneKey = "GaleCliff", Label = "Ветряной утёс", HuntOrder = 9, Element = "Wind"},
	[10] = {ZoneKey = "MossGlade", Label = "Моховая поляна", HuntOrder = 10, Element = "Nature"},
	[11] = {ZoneKey = "Moonwell", Label = "Лунный колодец", HuntOrder = 11, Element = "Moon"},
	[12] = {ZoneKey = "VenomHollow", Label = "Ядовитое ущелье", HuntOrder = 12, Element = "Poison"},
	[13] = {ZoneKey = "SandDunes", Label = "Песчаные дюны", HuntOrder = 13, Element = "Sand"},
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
	StoneBasin = {SoundId = "9047105584", Volume = 0.36},
	AshGarden = {SoundId = "9047105584", Volume = 0.38},
	GaleCliff = {SoundId = "9047105584", Volume = 0.36},
	MossGlade = {SoundId = "9047105584", Volume = 0.34},
	Moonwell = {SoundId = "9047105584", Volume = 0.36},
	VenomHollow = {SoundId = "9047105584", Volume = 0.35},
	SandDunes = {SoundId = "9047105584", Volume = 0.35},
}

ZoneConfig.GachaRobuxProductId = 0

return ZoneConfig
