local ZoneConfig = {}

-- Магазин сдвинут на запад от Combat; Safe увеличен под 2x здание + Мику снаружи
ZoneConfig.HavenCenter = Vector3.new(-25, 0, 28)
ZoneConfig.AkihabaraOffset = Vector3.new(90, 0, 0)

ZoneConfig.Zones = {
	Genkan = {Center = Vector3.new(-25, 3, -6), Size = Vector3.new(12, 10, 8)},
	-- Safe увеличен на юг под Мику дальше от фасада
	Safe = {Center = Vector3.new(-25, 1, 28), Size = Vector3.new(100, 28, 160)},
	Exit = {Center = Vector3.new(-25, 1, 62), Size = Vector3.new(14, 10, 6)},
	-- Akihabara Combat (стартовый дух #1 Огненный Кот) — Q2 enlarged footprint
	Combat = {Center = Vector3.new(105, 1, 45), Size = Vector3.new(110, 24, 110)},
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
	-- Metal (#14 Стальной Жук)
	IronWastes = {Center = Vector3.new(450, 1, 200), Size = Vector3.new(55, 22, 50)},
	-- Crystal (#15 Хрустальный Лис)
	CrystalCaves = {Center = Vector3.new(520, 1, 280), Size = Vector3.new(55, 22, 50)},
	-- Magma (#16 Лавовый Краб)
	MagmaFissure = {Center = Vector3.new(590, 1, 240), Size = Vector3.new(55, 22, 50)},
	-- Mist (#17 Туманный Дух)
	FogBasin = {Center = Vector3.new(660, 1, 200), Size = Vector3.new(55, 22, 50)},
	-- Sky (#18 Небесный Сокол)
	SkyRidge = {Center = Vector3.new(-200, 1, 220), Size = Vector3.new(55, 22, 50)},
}

ZoneConfig.CounterPosition = Vector3.new(-30, 0, 0)
-- Мика снаружи, ещё ~20 studs от фасада (юг)
ZoneConfig.QuestMasterPosition = Vector3.new(-12, 0, -38)
ZoneConfig.QuestMasterHeightOffset = 0.25
-- Пол Haven (ближе к центру Safe / магазину)
ZoneConfig.SpawnPosition = Vector3.new(-2, 0, -38) -- снаружи у земли, 10 стад напротив Мики (FaceDir +X)
ZoneConfig.BattleArenaPosition = Vector3.new(236, 0, 40)
ZoneConfig.MistPondCenter = Vector3.new(30, 1, -880)

-- Базовые духи разнесены ≥~80 studs (под будущие hunt-квесты по очереди)
ZoneConfig.SpiritSpawnPositions = {
	[11] = Vector3.new(70, 0, 30), -- EmberCourt / Fire
	[42] = Vector3.new(20, 0, 160), -- FrostRidge / Ice
	[33] = Vector3.new(155, 0, -80), -- ShadowHollow / Dark
	[32] = Vector3.new(230, 0, 175), -- StormSpire / Lightning
	[13] = Vector3.new(340, 0, 220), -- DawnMeadow / Light
	[41] = Vector3.new(30, 2, -880), -- MistPond / coastal sea / Water
	[21] = Vector3.new(-80, 0, -120), -- StoneBasin / Earth
	[12] = Vector3.new(175, 0, 50), -- AshGarden / Fire ash
	[31] = Vector3.new(-140, 0, 180), -- GaleCliff / Wind
	[22] = Vector3.new(50, 0, -200), -- MossGlade / Nature
	[43] = Vector3.new(-220, 0, -160), -- Moonwell / Moon
	[24] = Vector3.new(280, 0, -160), -- VenomHollow / Poison
	-- [25] Sand deprecated (4×4 canon)
	[23] = Vector3.new(450, 0, 200), -- IronWastes / Metal
	-- [26] Crystal deprecated (4×4 canon)
	[14] = Vector3.new(590, 0, 240), -- MagmaFissure / Magma
	[44] = Vector3.new(660, 0, 200), -- FogBasin / Mist
	[34] = Vector3.new(-200, 0, 220), -- SkyRidge / Sky
}

-- Метаданные для будущей цепочки «ловить по очереди»
ZoneConfig.SpiritHabitats = {
	[11] = {ZoneKey = "Combat", Label = "Угольный двор", HuntOrder = 1, Element = "Fire"},
	[42] = {ZoneKey = "FrostRidge", Label = "Морозный хребет", HuntOrder = 2, Element = "Ice"},
	[41] = {ZoneKey = "MistPond", Label = "Прибрежное море", HuntOrder = 3, Element = "Water"},
	[33] = {ZoneKey = "ShadowHollow", Label = "Теневая лощина", HuntOrder = 4, Element = "Dark"},
	[32] = {ZoneKey = "StormSpire", Label = "Грозовой шпиль", HuntOrder = 5, Element = "Lightning"},
	[13] = {ZoneKey = "DawnMeadow", Label = "Луг рассвета", HuntOrder = 6, Element = "Light"},
	[21] = {ZoneKey = "StoneBasin", Label = "Каменный бассейн", HuntOrder = 7, Element = "Earth"},
	[12] = {ZoneKey = "AshGarden", Label = "Пепельный сад", HuntOrder = 8, Element = "Fire"},
	[31] = {ZoneKey = "GaleCliff", Label = "Ветряной утёс", HuntOrder = 9, Element = "Wind"},
	[22] = {ZoneKey = "MossGlade", Label = "Моховая поляна", HuntOrder = 10, Element = "Nature"},
	[43] = {ZoneKey = "Moonwell", Label = "Лунный колодец", HuntOrder = 11, Element = "Moon"},
	[24] = {ZoneKey = "VenomHollow", Label = "Ядовитое ущелье", HuntOrder = 12, Element = "Poison"},
	-- Sand #13 / Crystal #15 soft-deprecated from 4×4 canon spawn
	[23] = {ZoneKey = "IronWastes", Label = "Железные пустоши", HuntOrder = 14, Element = "Metal"},
	[14] = {ZoneKey = "MagmaFissure", Label = "Лавовый разлом", HuntOrder = 16, Element = "Magma"},
	[44] = {ZoneKey = "FogBasin", Label = "Туманная низина", HuntOrder = 17, Element = "Mist"},
	[34] = {ZoneKey = "SkyRidge", Label = "Небесный хребет", HuntOrder = 18, Element = "Sky"},
}

-- Q2: named quest locations (VisitZone TargetZone) — each has ≥1 quest
ZoneConfig.QuestLocations = {
	ScoutPost = {
		Center = Vector3.new(40, 1, 55),
		Size = Vector3.new(24, 16, 24),
		Label = "Лагерь разведки",
		Color = Color3.fromRGB(90, 140, 200),
	},
	Waystone = {
		Center = Vector3.new(-70, 1, -100),
		Size = Vector3.new(20, 18, 20),
		Label = "Каменный алтарь",
		Color = Color3.fromRGB(160, 150, 130),
	},
	ChestCluster = {
		Center = Vector3.new(130, 1, 20),
		Size = Vector3.new(28, 14, 28),
		Label = "Сундучный грот",
		Color = Color3.fromRGB(200, 160, 60),
	},
	ElementShrine = {
		Center = Vector3.new(25, 1, 145),
		Size = Vector3.new(22, 16, 22),
		Label = "Святилище стихий",
		Color = Color3.fromRGB(140, 200, 255),
	},
	Overlook = {
		Center = Vector3.new(200, 1, 160),
		Size = Vector3.new(26, 16, 26),
		Label = "Обзорный утёс",
		Color = Color3.fromRGB(180, 120, 90),
	},
	TrailCamp = {
		Center = Vector3.new(90, 1, -50),
		Size = Vector3.new(24, 14, 24),
		Label = "Придорожный стан",
		Color = Color3.fromRGB(100, 160, 90),
	},
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
	IronWastes = {SoundId = "9047105584", Volume = 0.36},
	CrystalCaves = {SoundId = "9047105584", Volume = 0.36},
	MagmaFissure = {SoundId = "9047105584", Volume = 0.38},
	FogBasin = {SoundId = "9047105584", Volume = 0.36},
	SkyRidge = {SoundId = "9047105584", Volume = 0.36},
}

ZoneConfig.GachaRobuxProductId = 0

return ZoneConfig
