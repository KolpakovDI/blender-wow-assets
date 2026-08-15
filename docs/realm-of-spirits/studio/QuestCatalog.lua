--!strict
-- QuestCatalog: shared quest + unique-item data (Q1 expansion)
-- Runtime accept/progress/turn-in stays in ServerScriptService.QuestSystem

local QuestCatalog = {}

QuestCatalog.UniqueItems = {
	[1] = {Id = 1, Name = "Амулет Древнего Мастера", Rarity = "Legendary", Description = "Увеличивает опыт на 15%"},
	[2] = {Id = 2, Name = "Кольцо Стихий", Rarity = "Epic", Description = "+10% урон всем духам"},
	[3] = {Id = 3, Name = "Свиток Призыва", Rarity = "Rare", Description = "Позволяет призвать случайного духа"},
	[4] = {Id = 4, Name = "Плащ Мудреца", Rarity = "Epic", Description = "+20% защита, +10% скорость"},
	[5] = {Id = 5, Name = "Корона Дракона", Rarity = "Legendary", Description = "+30% опыт, +15% репутация"},
	[6] = {Id = 6, Name = "Кристалл Удачи", Rarity = "Rare", Description = "Увеличивает шанс поимки духов"},
	[7] = {Id = 7, Name = "Посох Хранителя", Rarity = "Epic", Description = "+25% урон в боях"},
	-- Трофеи Пути Охотника (habitats)
	[8] = {Id = 8, Name = "Знак Угольного Двора", Rarity = "Uncommon", Description = "Трофей: Огненный Кот. +5% урон огнём"},
	[9] = {Id = 9, Name = "Перо Морозного Хребта", Rarity = "Uncommon", Description = "Трофей: Ледяная Птица. +5% скорость"},
	[10] = {Id = 10, Name = "Чешуя Прибрежного Моря", Rarity = "Rare", Description = "Трофей: Водный Карп. +5% защита"},
	[11] = {Id = 11, Name = "Клык Теневой Лощины", Rarity = "Rare", Description = "Трофей: Теневой Пёс. +8% крит"},
	[12] = {Id = 12, Name = "Искра Грозового Шпиля", Rarity = "Epic", Description = "Трофей: Грозовой Дракон. +10% урон"},
	[13] = {Id = 13, Name = "Корона Рассвета", Rarity = "Legendary", Description = "Трофей: Световой Единорог. +20% опыт, +10% репутация"},
	[14] = {Id = 14, Name = "Осколок Каменного Бассейна", Rarity = "Rare", Description = "Трофей: Каменный Голем. +8% защита"},
	[15] = {Id = 15, Name = "Уголёк Пепельного Сада", Rarity = "Rare", Description = "Трофей: Пепельный Саламандр. +8% урон огнём"},
	[16] = {Id = 16, Name = "Перо Ветряного Утёса", Rarity = "Rare", Description = "Трофей: Ветряной Лис. +8% скорость"},
	[17] = {Id = 17, Name = "Лист Моховой Поляны", Rarity = "Rare", Description = "Трофей: Моховой Олень. +8% защита"},
	[18] = {Id = 18, Name = "Осколок Лунного Колодца", Rarity = "Rare", Description = "Трофей: Лунный Кролик. +8% MP"},
	[19] = {Id = 19, Name = "Клык Ядовитого Ущелья", Rarity = "Rare", Description = "Трофей: Ядовитая Гадюка. +8% урон ядом"},
	[20] = {Id = 20, Name = "Клешня Песчаных Дюн", Rarity = "Rare", Description = "Трофей: Пустынный Скорпион. +8% урон песком"},
	[21] = {Id = 21, Name = "Панцирь Железных Пустошей", Rarity = "Rare", Description = "Трофей: Стальной Жук. +8% урон металлом"},
	[22] = {Id = 22, Name = "Секретный билет", Rarity = "Rare", Description = "Награда Мики: особый билет Otaku Haven"},
	[23] = {Id = 23, Name = "Осколок Кристальных Пещер", Rarity = "Rare", Description = "Трофей: Хрустальный Лис. +8% урон кристаллом"},
	[24] = {Id = 24, Name = "Скрижаль четырёх стихий", Rarity = "Rare", Description = "Огонь→Земля→Ветер→Вода→Огонь · ×1.5 / ×0.7"},
	[25] = {Id = 25, Name = "Клешня Лавового Разлома", Rarity = "Rare", Description = "Трофей: Лавовый Краб. +8% урон лавой"},
	[26] = {Id = 26, Name = "Осколок Туманной Низины", Rarity = "Rare", Description = "Трофей: Туманный Дух. +8% урон туманом"},
	[27] = {Id = 27, Name = "Перо Небесного Хребта", Rarity = "Rare", Description = "Трофей: Небесный Сокол. +8% урон небом"},
}

QuestCatalog.Quests = {
	-- Основная сюжетная линия
	[1] = {
		Id = 1,
		Name = "Первые шаги",
		Description = "Выйдите через Exit в Акихабару, подойдите к дикому духу и нажмите E (или кнопку Поймать)",
		Type = "Story",
		Level = 1,
		ZoneHint = "Акихабара · Exit → Combat",
		TargetZone = "Combat",
		Objectives = {
			{Type = "CatchSpirit", Count = 1}
		},
		Rewards = {
			Experience = 80,
			CopperCoins = 50,
			SilverCoins = 0,
			GoldCoins = 0,
			Reputation = 10,
			UniqueItems = {},
			Items = {{Id = 1, Quantity = 3}}
		},
		Prerequisites = {7}
	},
	[2] = {
		Id = 2,
		Name = "Тренировка",
		Description = "Победите 3 врагов: бой с диким духом (F) или на арене BattleArena",
		Type = "Story",
		Level = 2,
		ZoneHint = "Combat / BattleArena",
		TargetZone = "Combat",
		Objectives = {
			{Type = "DefeatEnemies", Count = 3}
		},
		Rewards = {
			Experience = 150,
			CopperCoins = 80,
			SilverCoins = 5,
			GoldCoins = 0,
			Reputation = 20,
			UniqueItems = {},
			Items = {{Id = 2, Quantity = 3}}
		},
		Prerequisites = {1}
	},
	[3] = {
		Id = 3,
		Name = "Коллекционер",
		Description = "Поймайте 3 разных духа (E / Поймать). Уже пойманные типы тоже считаются",
		Type = "Story",
		Level = 3,
		ZoneHint = "Combat и ближайшие хребты",
		TargetZone = "Combat",
		Objectives = {
			{Type = "CatchDifferentSpirits", Count = 3}
		},
		Rewards = {
			Experience = 220,
			CopperCoins = 100,
			SilverCoins = 8,
			GoldCoins = 0,
			Reputation = 30,
			UniqueItems = {{Id = 6, Quantity = 1}},
			Items = {{Id = 3, Quantity = 1}}
		},
		Prerequisites = {2}
	},
	[4] = {
		Id = 4,
		Name = "Боевое испытание",
		Description = "Победите 10 врагов в бою (F с диким духом или арена BattleArena)",
		Type = "Story",
		Level = 5,
		ZoneHint = "Combat / BattleArena",
		TargetZone = "Combat",
		Objectives = {
			{Type = "DefeatEnemies", Count = 10}
		},
		Rewards = {
			Experience = 500,
			CopperCoins = 200,
			SilverCoins = 25,
			GoldCoins = 1,
			Reputation = 50,
			UniqueItems = {{Id = 2, Quantity = 1}}, -- Кольцо Стихий
			Items = {{Id = 1, Quantity = 5}} -- ловушки (ItemCatalog)
		},
		Prerequisites = {2, 3}
	},
	[5] = {
		Id = 5,
		Name = "Мастер Духов",
		Description = "Прокачайте любого духа до 10 уровня (бои F дают XP духу)",
		Type = "Story",
		Level = 8,
		Objectives = {
			{Type = "LevelUpSpirit", TargetLevel = 10}
		},
		Rewards = {
			Experience = 800,
			CopperCoins = 300,
			SilverCoins = 50,
			GoldCoins = 3,
			Reputation = 100,
			UniqueItems = {{Id = 7, Quantity = 1}}, -- Посох Хранителя
			Items = {{Id = 2, Quantity = 3}} -- зелья
		},
		Prerequisites = {4}
	},
	[6] = {
		Id = 6,
		Name = "Легендарный Мастер",
		Description = "Поймайте 6 разных типов духов (E). Уже пойманные виды тоже идут в счёт",
		Type = "Story",
		Level = 10,
		Objectives = {
			{Type = "CatchDifferentSpirits", Count = 6}
		},
		Rewards = {
			Experience = 1500,
			CopperCoins = 500,
			SilverCoins = 100,
			GoldCoins = 10,
			Reputation = 250,
			UniqueItems = {{Id = 5, Quantity = 1}}, -- Корона Дракона
			Items = {{Id = 3, Quantity = 3}} -- свитки опыта
		},
		Prerequisites = {5}
	},
	[7] = {
		Id = 7,
		Name = "Украденная манга",
		Description = "Верните коробку редкой манги у Exit (выход в Акихабару) — украдена бандой Shadow у склада Мики",
		Type = "Story",
		Level = 1,
		ZoneHint = "Haven Exit · коробка манги",
		TargetZone = "Exit",
		Objectives = {
			{Type = "CollectItem", ItemId = 120, Count = 1}
		},
		Rewards = {
			Experience = 60,
			CopperCoins = 40,
			SilverCoins = 0,
			GoldCoins = 0,
			Reputation = 15,
			UniqueItems = {{Id = 22, Quantity = 1}},
			Items = {}
		},
		Prerequisites = {}
	},

	-- Побочные квесты
	[101] = {
		Id = 101,
		Name = "Помощь торговцу",
		Description = "Соберите 5 огненных кристаллов у EmberCourt (E) — оранжевое свечение у огненной зоны",
		Type = "Side",
		Level = 1,
		ZoneHint = "Угольный двор · Combat",
		TargetZone = "Combat",
		Objectives = {
			{Type = "CollectItem", ItemId = 101, Count = 5}
		},
		Rewards = {
			Experience = 40,
			CopperCoins = 45,
			SilverCoins = 0,
			GoldCoins = 0,
			Reputation = 5,
			UniqueItems = {},
			Items = {{Id = 2, Quantity = 2}}
		},
		Prerequisites = {}
	},
	[102] = {
		Id = 102,
		Name = "Охотник за сокровищами",
		Description = "Найдите 3 сундука в зонах (E) — золотые сундуки у троп стихий",
		Type = "Side",
		Level = 3,
		Objectives = {
			{Type = "FindChests", Count = 3}
		},
		Rewards = {
			Experience = 150,
			CopperCoins = 120,
			SilverCoins = 15,
			GoldCoins = 0,
			Reputation = 15,
			UniqueItems = {{Id = 3, Quantity = 1}}, -- Свиток Призыва
			Items = {}
		},
		Prerequisites = {}
	},
	[103] = {
		Id = 103,
		Name = "Тренер духов",
		Description = "Победите 20 врагов — F по диким духам или арена",
		Type = "Side",
		Level = 4,
		Objectives = {
			{Type = "DefeatEnemies", Count = 20}
		},
		Rewards = {
			Experience = 300,
			CopperCoins = 200,
			SilverCoins = 20,
			GoldCoins = 1,
			Reputation = 25,
			UniqueItems = {{Id = 7, Quantity = 1}}, -- Посох Хранителя (UniqueItemDatabase)
			Items = {{Id = 2, Quantity = 3}} -- зелья в инвентарь
		},
		Prerequisites = {}
	},
	[104] = {
		Id = 104,
		Name = "Хранитель мира",
		Description = "Поймайте 5 духов (E / Поймать) — любые виды идут в счёт",
		Type = "Side",
		Level = 5,
		Objectives = {
			{Type = "CatchSpirit", Count = 5}
		},
		Rewards = {
			Experience = 400,
			CopperCoins = 250,
			SilverCoins = 30,
			GoldCoins = 2,
			Reputation = 50,
			UniqueItems = {{Id = 4, Quantity = 1}}, -- Плащ Мудреца
			Items = {}
		},
		Prerequisites = {1}
	},
	[105] = {
		Id = 105,
		Name = "Легенда о Мастере",
		Description = "Финал побочек: после 101–104 победите 50 врагов (F / арена)",
		Type = "Side",
		Level = 10,
		Objectives = {
			{Type = "DefeatEnemies", Count = 50}
		},
		Rewards = {
			Experience = 2000,
			CopperCoins = 500,
			SilverCoins = 100,
			GoldCoins = 15,
			Reputation = 500,
			UniqueItems = {{Id = 1, Quantity = 1}}, -- Амулет Древнего Мастера
			Items = {{Id = 3, Quantity = 2}} -- свитки опыта
		},
		Prerequisites = {101, 102, 103, 104}
	},

	[106] = {
		Id = 106,
		Name = "Цикл стихий",
		Description = "Соберите по 2 Primary-кристалла (E): Огонь EmberCourt, Земля StoneBasin, Ветер GaleCliff, Вода MistPond. Цикл ×1.5/×0.7",
		Type = "Side",
		Level = 6,
		Objectives = {
			{Type = "CollectItem", ItemId = 101, Count = 2},
			{Type = "CollectItem", ItemId = 107, Count = 2},
			{Type = "CollectItem", ItemId = 109, Count = 2},
			{Type = "CollectItem", ItemId = 106, Count = 2},
		},
		Rewards = {
			Experience = 450,
			CopperCoins = 200,
			SilverCoins = 25,
			GoldCoins = 1,
			Reputation = 40,
			UniqueItems = {{Id = 24, Quantity = 1}},
			Items = {{Id = 3, Quantity = 1}},
		},
		Prerequisites = {101},
	},

	-- ============================================
	-- Путь Охотника: ловить духов по HuntOrder (ZoneConfig.SpiritHabitats)
	-- ============================================
	[201] = {
		Id = 201,
		Name = "Путь Охотника I: Огонь",
		Description = "Поймайте Огненного Кота у Угольного двора (Акихабара, восток от Haven)",
		Type = "Hunt",
		Level = 1,
		Objectives = {
			{Type = "CatchSpecificSpirit", SpiritId = 11, Count = 1, SpiritName = "Огненный Кот"}
		},
		Rewards = {
			Experience = 120,
			CopperCoins = 80,
			SilverCoins = 5,
			GoldCoins = 0,
			Reputation = 15,
			UniqueItems = {{Id = 8, Quantity = 1}},
			Items = {{Id = 101, Quantity = 2}, {Id = 1, Quantity = 2}}
		},
		Prerequisites = {}
	},
	[202] = {
		Id = 202,
		Name = "Путь Охотника II: Лёд",
		Description = "Поймайте Ледяную Птицу на Морозном хребте (северо-запад, у пруда)",
		Type = "Hunt",
		Level = 2,
		Objectives = {
			{Type = "CatchSpecificSpirit", SpiritId = 42, Count = 1, SpiritName = "Ледяная Птица"}
		},
		Rewards = {
			Experience = 180,
			CopperCoins = 100,
			SilverCoins = 8,
			GoldCoins = 0,
			Reputation = 20,
			UniqueItems = {{Id = 9, Quantity = 1}},
			Items = {{Id = 102, Quantity = 2}, {Id = 1, Quantity = 2}}
		},
		Prerequisites = {201}
	},
	[203] = {
		Id = 203,
		Name = "Путь Охотника III: Вода",
		Description = "Поймайте Водного Карпа в Прибрежном море (юг, за пальмами)",
		Type = "Hunt",
		Level = 3,
		Objectives = {
			{Type = "CatchSpecificSpirit", SpiritId = 41, Count = 1, SpiritName = "Водный Карп"}
		},
		Rewards = {
			Experience = 220,
			CopperCoins = 120,
			SilverCoins = 12,
			GoldCoins = 0,
			Reputation = 25,
			UniqueItems = {{Id = 10, Quantity = 1}},
			Items = {{Id = 106, Quantity = 3}, {Id = 2, Quantity = 2}}
		},
		Prerequisites = {202}
	},
	[204] = {
		Id = 204,
		Name = "Путь Охотника IV: Тень",
		Description = "Поймайте Теневого Пса в Теневой лощине (юг от арены)",
		Type = "Hunt",
		Level = 4,
		Objectives = {
			{Type = "CatchSpecificSpirit", SpiritId = 33, Count = 1, SpiritName = "Теневой Пёс"}
		},
		Rewards = {
			Experience = 320,
			CopperCoins = 160,
			SilverCoins = 18,
			GoldCoins = 1,
			Reputation = 35,
			UniqueItems = {{Id = 11, Quantity = 1}},
			Items = {{Id = 103, Quantity = 3}, {Id = 1, Quantity = 3}}
		},
		Prerequisites = {203}
	},
	[205] = {
		Id = 205,
		Name = "Путь Охотника V: Гроза",
		Description = "Поймайте Грозового Дракона у Грозового шпиля (север от арены)",
		Type = "Hunt",
		Level = 6,
		Objectives = {
			{Type = "CatchSpecificSpirit", SpiritId = 32, Count = 1, SpiritName = "Грозовой Дракон"}
		},
		Rewards = {
			Experience = 450,
			CopperCoins = 220,
			SilverCoins = 30,
			GoldCoins = 2,
			Reputation = 50,
			UniqueItems = {{Id = 12, Quantity = 1}},
			Items = {{Id = 104, Quantity = 3}, {Id = 2, Quantity = 3}}
		},
		Prerequisites = {204}
	},
	[206] = {
		Id = 206,
		Name = "Путь Охотника VI: Свет",
		Description = "Поймайте Светового Единорога на Лугу рассвета (далеко на северо-востоке)",
		Type = "Hunt",
		Level = 8,
		Objectives = {
			{Type = "CatchSpecificSpirit", SpiritId = 13, Count = 1, SpiritName = "Световой Единорог"}
		},
		Rewards = {
			Experience = 800,
			CopperCoins = 350,
			SilverCoins = 50,
			GoldCoins = 5,
			Reputation = 100,
			UniqueItems = {{Id = 13, Quantity = 1}},
			Items = {{Id = 105, Quantity = 5}, {Id = 3, Quantity = 2}}
		},
		Prerequisites = {205}
	},
	[207] = {
		Id = 207,
		Name = "Путь Охотника VII: Земля",
		Description = "Поймайте Каменного Голема в Каменном бассейне (юго-запад от Haven)",
		Type = "Hunt",
		Level = 5,
		Objectives = {
			{Type = "CatchSpecificSpirit", SpiritId = 21, Count = 1, SpiritName = "Каменный Голем"}
		},
		Rewards = {
			Experience = 380,
			CopperCoins = 180,
			SilverCoins = 22,
			GoldCoins = 1,
			Reputation = 40,
			UniqueItems = {{Id = 14, Quantity = 1}},
			Items = {{Id = 107, Quantity = 3}, {Id = 1, Quantity = 3}}
		},
		Prerequisites = {206}
	},
	[208] = {
		Id = 208,
		Name = "Путь Охотника VIII: Пепел",
		Description = "Поймайте Пепельного Саламандра в Пепельном саду (восток от Combat)",
		Type = "Hunt",
		Level = 5,
		Objectives = {
			{Type = "CatchSpecificSpirit", SpiritId = 12, Count = 1, SpiritName = "Пепельный Саламандр"}
		},
		Rewards = {
			Experience = 400,
			CopperCoins = 190,
			SilverCoins = 24,
			GoldCoins = 1,
			Reputation = 42,
			UniqueItems = {{Id = 15, Quantity = 1}},
			Items = {{Id = 108, Quantity = 3}, {Id = 1, Quantity = 3}}
		},
		Prerequisites = {207}
	},
	[209] = {
		Id = 209,
		Name = "Путь Охотника IX: Ветер",
		Description = "Поймайте Ветряного Лиса на Ветряном утёсе (западнее Морозного хребта)",
		Type = "Hunt",
		Level = 5,
		Objectives = {
			{Type = "CatchSpecificSpirit", SpiritId = 31, Count = 1, SpiritName = "Ветряной Лис"}
		},
		Rewards = {
			Experience = 420,
			CopperCoins = 200,
			SilverCoins = 26,
			GoldCoins = 1,
			Reputation = 44,
			UniqueItems = {{Id = 16, Quantity = 1}},
			Items = {{Id = 109, Quantity = 3}, {Id = 1, Quantity = 3}}
		},
		Prerequisites = {208}
	},
	[210] = {
		Id = 210,
		Name = "Путь Охотника X: Природа",
		Description = "Поймайте Мохового Оленя на Моховой поляне (юг от ShadowHollow)",
		Type = "Hunt",
		Level = 5,
		Objectives = {
			{Type = "CatchSpecificSpirit", SpiritId = 22, Count = 1, SpiritName = "Моховой Олень"}
		},
		Rewards = {
			Experience = 440,
			CopperCoins = 210,
			SilverCoins = 28,
			GoldCoins = 1,
			Reputation = 46,
			UniqueItems = {{Id = 17, Quantity = 1}},
			Items = {{Id = 110, Quantity = 3}, {Id = 1, Quantity = 3}}
		},
		Prerequisites = {209}
	},
	[211] = {
		Id = 211,
		Name = "Путь Охотника XI: Луна",
		Description = "Поймайте Лунного Кролика у Лунного колодца (запад от StoneBasin)",
		Type = "Hunt",
		Level = 5,
		Objectives = {
			{Type = "CatchSpecificSpirit", SpiritId = 43, Count = 1, SpiritName = "Лунный Кролик"}
		},
		Rewards = {
			Experience = 460,
			CopperCoins = 220,
			SilverCoins = 30,
			GoldCoins = 1,
			Reputation = 48,
			UniqueItems = {{Id = 18, Quantity = 1}},
			Items = {{Id = 111, Quantity = 3}, {Id = 1, Quantity = 3}}
		},
		Prerequisites = {210}
	},
	[212] = {
		Id = 212,
		Name = "Путь Охотника XII: Яд",
		Description = "Поймайте Ядовитую Гадюку в Ядовитом ущелье (восток от Moonwell)",
		Type = "Hunt",
		Level = 5,
		Objectives = {
			{Type = "CatchSpecificSpirit", SpiritId = 24, Count = 1, SpiritName = "Ядовитая Гадюка"}
		},
		Rewards = {
			Experience = 480,
			CopperCoins = 230,
			SilverCoins = 32,
			GoldCoins = 1,
			Reputation = 50,
			UniqueItems = {{Id = 19, Quantity = 1}},
			Items = {{Id = 112, Quantity = 3}, {Id = 1, Quantity = 3}}
		},
		Prerequisites = {211}
	},
	[213] = {
		Id = 213,
		Name = "[Архив] Путь Охотника XIII: Песок",
		Description = "Архив 4×4: Песок вне канона (дух #13 не спавнится). Новые игроки: сразу Металл (214) после Яда (212).",
		Type = "Hunt",
		Level = 5,
		Deprecated = true,
		Objectives = {
			{Type = "CatchSpecificSpirit", SpiritId = 25, Count = 1, SpiritName = "Пустынный Скорпион"}
		},
		Rewards = {
			Experience = 500,
			CopperCoins = 240,
			SilverCoins = 34,
			GoldCoins = 1,
			Reputation = 52,
			UniqueItems = {{Id = 20, Quantity = 1}},
			Items = {{Id = 113, Quantity = 3}, {Id = 1, Quantity = 3}}
		},
		Prerequisites = {212}
	},
	[214] = {
		Id = 214,
		Name = "Путь Охотника XIV: Металл",
		Description = "Поймайте Стального Жука в Железных пустошах (восток от DawnMeadow)",
		Type = "Hunt",
		Level = 5,
		Objectives = {
			{Type = "CatchSpecificSpirit", SpiritId = 23, Count = 1, SpiritName = "Стальной Жук"}
		},
		Rewards = {
			Experience = 520,
			CopperCoins = 250,
			SilverCoins = 36,
			GoldCoins = 1,
			Reputation = 54,
			UniqueItems = {{Id = 21, Quantity = 1}},
			Items = {{Id = 114, Quantity = 3}, {Id = 1, Quantity = 3}}
		},
		Prerequisites = {212} -- skip archived Sand 213 (4×4 canon)
	},
	[215] = {
		Id = 215,
		Name = "[Архив] Путь Охотника XV: Кристалл",
		Description = "Архив 4×4: Кристалл вне канона (дух #15 не спавнится). Новые игроки: Лава (216) сразу после Металла (214).",
		Type = "Hunt",
		Level = 5,
		Deprecated = true,
		Objectives = {
			{Type = "CatchSpecificSpirit", SpiritId = 26, Count = 1, SpiritName = "Хрустальный Лис"}
		},
		Rewards = {
			Experience = 540,
			CopperCoins = 260,
			SilverCoins = 38,
			GoldCoins = 1,
			Reputation = 56,
			UniqueItems = {{Id = 23, Quantity = 1}},
			Items = {{Id = 115, Quantity = 3}, {Id = 1, Quantity = 3}}
		},
		Prerequisites = {214}
	},
	[216] = {
		Id = 216,
		Name = "Путь Охотника XVI: Лава",
		Description = "Поймайте Лавового Краба в Лавовом разломе (восток от IronWastes)",
		Type = "Hunt",
		Level = 5,
		Objectives = {
			{Type = "CatchSpecificSpirit", SpiritId = 14, Count = 1, SpiritName = "Лавовый Краб"}
		},
		Rewards = {
			Experience = 560,
			CopperCoins = 270,
			SilverCoins = 40,
			GoldCoins = 1,
			Reputation = 58,
			UniqueItems = {{Id = 25, Quantity = 1}},
			Items = {{Id = 116, Quantity = 3}, {Id = 1, Quantity = 3}}
		},
		Prerequisites = {214} -- skip archived Crystal 215 (4×4 canon)
	},
	[217] = {
		Id = 217,
		Name = "Путь Охотника XVII: Туман",
		Description = "Поймайте Туманного Духа в Туманной низине (восток от MagmaFissure)",
		Type = "Hunt",
		Level = 5,
		Objectives = {
			{Type = "CatchSpecificSpirit", SpiritId = 44, Count = 1, SpiritName = "Туманный Дух"}
		},
		Rewards = {
			Experience = 580,
			CopperCoins = 280,
			SilverCoins = 42,
			GoldCoins = 1,
			Reputation = 60,
			UniqueItems = {{Id = 26, Quantity = 1}},
			Items = {{Id = 117, Quantity = 3}, {Id = 1, Quantity = 3}}
		},
		Prerequisites = {216}
	},
	[218] = {
		Id = 218,
		Name = "Путь Охотника XVIII: Небо",
		Description = "Поймайте Небесного Сокола на Небесном хребте (северо-запад, SkyRidge)",
		Type = "Hunt",
		Level = 5,
		Objectives = {
			{Type = "CatchSpecificSpirit", SpiritId = 34, Count = 1, SpiritName = "Небесный Сокол"}
		},
		Rewards = {
			Experience = 600,
			CopperCoins = 290,
			SilverCoins = 44,
			GoldCoins = 1,
			Reputation = 62,
			UniqueItems = {{Id = 27, Quantity = 1}},
			Items = {{Id = 118, Quantity = 3}, {Id = 1, Quantity = 3}}
		},
		Prerequisites = {217}
	},
	-- Spirit Resonance dailies (repeatable side — no hard prereq)
	[301] = {
		Id = 301,
		Name = "Уход за духом",
		Description = "Поухаживайте за активным духом в Otaku Haven (Spirit Resonance · Bond)",
		Type = "Side",
		Level = 1,
		Objectives = {
			{Type = "CareSpirit", Count = 1}
		},
		Rewards = {
			Experience = 40,
			CopperCoins = 30,
			SilverCoins = 2,
			GoldCoins = 0,
			Reputation = 5,
			UniqueItems = {},
			-- P2: do not print Bond fuel every day (30% chance)
			Items = {},
			ItemsChance = {{Id = 4, Quantity = 1, Chance = 0.3}},
		},
		Prerequisites = {}
	},
	[302] = {
		Id = 302,
		Name = "Закалка духа",
		Description = "Проведите одну тренировку Temper (Attack / Defense / Spirit)",
		Type = "Side",
		Level = 2,
		Objectives = {
			{Type = "TemperSpirit", Count = 1}
		},
		Rewards = {
			Experience = 60,
			CopperCoins = 40,
			SilverCoins = 4,
			GoldCoins = 0,
			Reputation = 8,
			UniqueItems = {},
			-- Stone is buy-capped; daily reward keeps 1 stone but no free print of extra fuel
			Items = {{Id = 5, Quantity = 1}},
		},
		Prerequisites = {301}
	},
	-- Note: Studio also has [303] Weekly Temper; mirror may lag — SoT is .rbxl
	[304] = {
		Id = 304,
		Name = "Звёзды трансформации",
		Description = "Откройте Святилище Ками у Мики (E). С 10 ур. — синтез и дезинтеграция; Звёзды усиливают Unique.",
		Type = "Side",
		Level = 10,
		Objectives = {
			{Type = "OpenKamiSanctum", Count = 1}
		},
		Rewards = {
			Experience = 100,
			CopperCoins = 50,
			SilverCoins = 5,
			GoldCoins = 0,
			Reputation = 12,
			UniqueItems = {},
			Items = {
				{Id = 310, Quantity = 2},
				{Id = 301, Quantity = 1},
			},
		},
		Prerequisites = {5}
	},

	-- ============================================
	-- Exploration story beats (Q1 expansion) — VisitZone / habitat
	-- ============================================
	[8] = {
		Id = 8,
		Name = "К хребту льда",
		Description = "Дойдите до Морозного хребта (FrostRidge) — северо-запад от Акихабары, у пруда",
		Type = "Story",
		Level = 2,
		ZoneHint = "Морозный хребет · северо-запад",
		TargetZone = "FrostRidge",
		Objectives = {
			{Type = "VisitZone", ZoneDetail = "FrostRidge", Count = 1}
		},
		Rewards = {
			Experience = 100,
			CopperCoins = 60,
			SilverCoins = 0,
			GoldCoins = 0,
			Reputation = 12,
			UniqueItems = {},
			Items = {{Id = 1, Quantity = 2}}
		},
		Prerequisites = {1}
	},
	[9] = {
		Id = 9,
		Name = "Пепел сада",
		Description = "Посетите Пепельный сад (AshGarden) — восток от Combat",
		Type = "Story",
		Level = 3,
		ZoneHint = "Пепельный сад · восток",
		TargetZone = "AshGarden",
		Objectives = {
			{Type = "VisitZone", ZoneDetail = "AshGarden", Count = 1}
		},
		Rewards = {
			Experience = 120,
			CopperCoins = 70,
			SilverCoins = 0,
			GoldCoins = 0,
			Reputation = 14,
			UniqueItems = {},
			Items = {{Id = 108, Quantity = 1}}
		},
		Prerequisites = {8}
	},
	[10] = {
		Id = 10,
		Name = "Каменный путь",
		Description = "Дойдите до Каменного бассейна (StoneBasin) — юго-запад от Haven",
		Type = "Story",
		Level = 3,
		ZoneHint = "Каменный бассейн · юго-запад",
		TargetZone = "StoneBasin",
		Objectives = {
			{Type = "VisitZone", ZoneDetail = "StoneBasin", Count = 1}
		},
		Rewards = {
			Experience = 130,
			CopperCoins = 75,
			SilverCoins = 0,
			GoldCoins = 0,
			Reputation = 15,
			UniqueItems = {},
			Items = {{Id = 107, Quantity = 1}}
		},
		Prerequisites = {9}
	},
	[11] = {
		Id = 11,
		Name = "Тень лощины",
		Description = "Поймайте Теневого Пса в Теневой лощине (ShadowHollow)",
		Type = "Story",
		Level = 4,
		ZoneHint = "Теневая лощина · юг от арены",
		TargetZone = "ShadowHollow",
		Objectives = {
			{Type = "CatchSpecificSpirit", SpiritId = 33, Count = 1, SpiritName = "Теневой Пёс"}
		},
		Rewards = {
			Experience = 200,
			CopperCoins = 110,
			SilverCoins = 5,
			GoldCoins = 0,
			Reputation = 25,
			UniqueItems = {},
			Items = {{Id = 1, Quantity = 3}}
		},
		Prerequisites = {10}
	},
	[12] = {
		Id = 12,
		Name = "Гроза шпиля",
		Description = "Дойдите до Грозового шпиля (StormSpire) — север от арены",
		Type = "Story",
		Level = 4,
		ZoneHint = "Грозовой шпиль · север",
		TargetZone = "StormSpire",
		Objectives = {
			{Type = "VisitZone", ZoneDetail = "StormSpire", Count = 1}
		},
		Rewards = {
			Experience = 150,
			CopperCoins = 85,
			SilverCoins = 0,
			GoldCoins = 0,
			Reputation = 18,
			UniqueItems = {},
			Items = {{Id = 104, Quantity = 1}}
		},
		Prerequisites = {11}
	},
	[13] = {
		Id = 13,
		Name = "Луг рассвета",
		Description = "Посетите Луг рассвета (DawnMeadow) — далеко на северо-востоке",
		Type = "Story",
		Level = 5,
		ZoneHint = "Луг рассвета · северо-восток",
		TargetZone = "DawnMeadow",
		Objectives = {
			{Type = "VisitZone", ZoneDetail = "DawnMeadow", Count = 1}
		},
		Rewards = {
			Experience = 180,
			CopperCoins = 95,
			SilverCoins = 5,
			GoldCoins = 0,
			Reputation = 20,
			UniqueItems = {},
			Items = {{Id = 105, Quantity = 1}}
		},
		Prerequisites = {12}
	},
	[14] = {
		Id = 14,
		Name = "Прибрежный зов",
		Description = "Дойдите до Прибрежного моря (MistPond) — юг, за пальмами",
		Type = "Story",
		Level = 5,
		ZoneHint = "Прибрежное море · юг",
		TargetZone = "MistPond",
		Objectives = {
			{Type = "VisitZone", ZoneDetail = "MistPond", Count = 1}
		},
		Rewards = {
			Experience = 190,
			CopperCoins = 100,
			SilverCoins = 5,
			GoldCoins = 0,
			Reputation = 22,
			UniqueItems = {},
			Items = {{Id = 106, Quantity = 2}}
		},
		Prerequisites = {13}
	},
	[15] = {
		Id = 15,
		Name = "Ветряной утёс",
		Description = "Посетите Ветряной утёс (GaleCliff) — западнее Морозного хребта",
		Type = "Story",
		Level = 5,
		ZoneHint = "Ветряной утёс · запад",
		TargetZone = "GaleCliff",
		Objectives = {
			{Type = "VisitZone", ZoneDetail = "GaleCliff", Count = 1}
		},
		Rewards = {
			Experience = 200,
			CopperCoins = 110,
			SilverCoins = 5,
			GoldCoins = 0,
			Reputation = 24,
			UniqueItems = {},
			Items = {{Id = 109, Quantity = 1}}
		},
		Prerequisites = {14}
	},
	[107] = {
		Id = 107,
		Name = "Разведка лагеря",
		Description = "Найдите Scout Camp у выхода в Combat (QuestLocations.ScoutPost)",
		Type = "Side",
		Level = 2,
		ZoneHint = "Scout Post · у Exit/Combat",
		TargetZone = "ScoutPost",
		Objectives = {
			{Type = "VisitZone", ZoneDetail = "ScoutPost", Count = 1}
		},
		Rewards = {
			Experience = 70,
			CopperCoins = 40,
			SilverCoins = 0,
			GoldCoins = 0,
			Reputation = 8,
			UniqueItems = {},
			Items = {{Id = 1, Quantity = 1}}
		},
		Prerequisites = {1}
	},
	[108] = {
		Id = 108,
		Name = "Каменный алтарь",
		Description = "Посетите Waystone у StoneBasin (QuestLocations.Waystone)",
		Type = "Side",
		Level = 3,
		ZoneHint = "Waystone · StoneBasin",
		TargetZone = "Waystone",
		Objectives = {
			{Type = "VisitZone", ZoneDetail = "Waystone", Count = 1}
		},
		Rewards = {
			Experience = 90,
			CopperCoins = 50,
			SilverCoins = 0,
			GoldCoins = 0,
			Reputation = 10,
			UniqueItems = {},
			Items = {{Id = 107, Quantity = 1}}
		},
		Prerequisites = {10}
	},
	[109] = {
		Id = 109,
		Name = "Сундучный грот",
		Description = "Найдите ChestCluster в Акихабаре (восток от Exit)",
		Type = "Side",
		Level = 2,
		ZoneHint = "ChestCluster · Combat",
		TargetZone = "ChestCluster",
		Objectives = {
			{Type = "VisitZone", ZoneDetail = "ChestCluster", Count = 1}
		},
		Rewards = {
			Experience = 75,
			CopperCoins = 45,
			SilverCoins = 0,
			GoldCoins = 0,
			Reputation = 8,
			UniqueItems = {},
			Items = {{Id = 2, Quantity = 1}}
		},
		Prerequisites = {1}
	},
	[110] = {
		Id = 110,
		Name = "Святилище стихий",
		Description = "Посетите ElementShrine у FrostRidge",
		Type = "Side",
		Level = 3,
		ZoneHint = "ElementShrine · FrostRidge",
		TargetZone = "ElementShrine",
		Objectives = {
			{Type = "VisitZone", ZoneDetail = "ElementShrine", Count = 1}
		},
		Rewards = {
			Experience = 95,
			CopperCoins = 55,
			SilverCoins = 0,
			GoldCoins = 0,
			Reputation = 11,
			UniqueItems = {},
			Items = {{Id = 102, Quantity = 1}}
		},
		Prerequisites = {8}
	},
	[111] = {
		Id = 111,
		Name = "Обзорный утёс",
		Description = "Дойдите до Overlook у StormSpire",
		Type = "Side",
		Level = 4,
		ZoneHint = "Overlook · StormSpire",
		TargetZone = "Overlook",
		Objectives = {
			{Type = "VisitZone", ZoneDetail = "Overlook", Count = 1}
		},
		Rewards = {
			Experience = 110,
			CopperCoins = 65,
			SilverCoins = 0,
			GoldCoins = 0,
			Reputation = 12,
			UniqueItems = {},
			Items = {{Id = 104, Quantity = 1}}
		},
		Prerequisites = {12}
	},
	[112] = {
		Id = 112,
		Name = "Придорожный стан",
		Description = "Найдите TrailCamp на пути к ShadowHollow",
		Type = "Side",
		Level = 3,
		ZoneHint = "TrailCamp · юг Combat",
		TargetZone = "TrailCamp",
		Objectives = {
			{Type = "VisitZone", ZoneDetail = "TrailCamp", Count = 1}
		},
		Rewards = {
			Experience = 85,
			CopperCoins = 50,
			SilverCoins = 0,
			GoldCoins = 0,
			Reputation = 9,
			UniqueItems = {},
			Items = {{Id = 1, Quantity = 2}}
		},
		Prerequisites = {1}
	},
}


function QuestCatalog.Get(questId)
	return QuestCatalog.Quests[questId]
end

function QuestCatalog.GetUniqueItem(itemId)
	return QuestCatalog.UniqueItems[itemId]
end

function QuestCatalog.GetAll()
	return QuestCatalog.Quests
end

-- Risk mitigation: every QuestLocations key must be a VisitZone target of ≥1 non-deprecated quest
function QuestCatalog.CollectVisitZoneDetails()
	local set = {}
	for _, quest in pairs(QuestCatalog.Quests) do
		if not quest.Deprecated then
			for _, obj in ipairs(quest.Objectives or {}) do
				if obj.Type == "VisitZone" and obj.ZoneDetail then
					set[tostring(obj.ZoneDetail)] = true
				end
			end
			if quest.TargetZone then
				-- TargetZone may be habitat/Combat; VisitZone keys are authoritative for locations
			end
		end
	end
	return set
end

return QuestCatalog
