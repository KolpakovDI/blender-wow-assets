# -*- coding: utf-8 -*-
"""Build QuestCatalog.lua from QuestSystem.lua and patch QuestSystem to require it."""
from pathlib import Path
import re

studio = Path(r"C:\Users\Asus\Projects\blender-wow-assets\docs\realm-of-spirits\studio")
src_path = studio / "QuestSystem.lua"
src = src_path.read_text(encoding="utf-8")

u0 = src.index("local UniqueItemDatabase = {")
u1 = src.index("-- ============================================\n-- Данные квестов")
unique_block = src[u0:u1].rstrip()

q0 = src.index("local QuestDatabase = {")
q1 = src.index("\n}\n\n-- ============================================\n-- Система квестов игрока")
quest_table = src[q0 + len("local QuestDatabase = ") : q1 + 2]  # from { to }

# Rebalance story 1-3 + ZoneHint inside quest table text via replacements
replacements = [
    (
        '''[1] = {
		Id = 1,
		Name = "Первые шаги",
		Description = "Выйдите через Exit в Акихабару, подойдите к дикому духу и нажмите E (или кнопку Поймать)",
		Type = "Story",
		Level = 1,
		Objectives = {
			{Type = "CatchSpirit", Count = 1}
		},
		Rewards = {
			Experience = 100,
			CopperCoins = 50,
			SilverCoins = 5,
			GoldCoins = 0,
			Reputation = 10,
			UniqueItems = {},
			Items = {{Id = 1, Quantity = 3}}
		},
		Prerequisites = {7}
	},''',
        '''[1] = {
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
	},''',
    ),
    (
        '''[2] = {
		Id = 2,
		Name = "Тренировка",
		Description = "Победите 5 врагов: бой с диким духом (F) или на арене BattleArena",
		Type = "Story",
		Level = 2,
		Objectives = {
			{Type = "DefeatEnemies", Count = 5}
		},
		Rewards = {
			Experience = 200,
			CopperCoins = 100,
			SilverCoins = 10,
			GoldCoins = 0,
			Reputation = 20,
			UniqueItems = {},
			Items = {{Id = 2, Quantity = 5}}
		},
		Prerequisites = {1}
	},''',
        '''[2] = {
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
	},''',
    ),
    (
        '''[3] = {
		Id = 3,
		Name = "Коллекционер",
		Description = "Поймайте 3 разных духа (E / Поймать). Уже пойманные типы тоже считаются",
		Type = "Story",
		Level = 3,
		Objectives = {
			{Type = "CatchDifferentSpirits", Count = 3}
		},
		Rewards = {
			Experience = 350,
			CopperCoins = 150,
			SilverCoins = 15,
			GoldCoins = 0,
			Reputation = 30,
			UniqueItems = {{Id = 6, Quantity = 1}}, -- Кристалл Удачи
			Items = {{Id = 3, Quantity = 1}}
		},
		Prerequisites = {2}
	},''',
        '''[3] = {
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
	},''',
    ),
    (
        '''[7] = {
		Id = 7,
		Name = "Украденная манга",
		Description = "Верните коробку редкой манги у Exit (выход в Акихабару) — украдена бандой Shadow у склада Мики",
		Type = "Story",
		Level = 1,
		Objectives = {
			{Type = "CollectItem", ItemId = 120, Count = 1}
		},
		Rewards = {
			Experience = 80,
			CopperCoins = 500,
			SilverCoins = 0,
			GoldCoins = 0,
			Reputation = 15,
			UniqueItems = {{Id = 22, Quantity = 1}},
			Items = {}
		},
		Prerequisites = {}
	},''',
        '''[7] = {
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
	},''',
    ),
]

for old, new in replacements:
    if old not in quest_table:
        raise SystemExit("replacement miss:\n" + old[:120])
    quest_table = quest_table.replace(old, new)

# Side rebalance light touches
side_patches = [
    (
        '''[101] = {
		Id = 101,
		Name = "Помощь торговцу",
		Description = "Соберите 5 огненных кристаллов у EmberCourt (E) — оранжевое свечение у огненной зоны",
		Type = "Side",
		Level = 1,
		Objectives = {
			{Type = "CollectItem", ItemId = 101, Count = 5}
		},
		Rewards = {
			Experience = 50,
			CopperCoins = 80,
			SilverCoins = 5,
			GoldCoins = 0,
			Reputation = 5,
			UniqueItems = {},
			Items = {{Id = 2, Quantity = 2}}
		},
		Prerequisites = {}
	},''',
        '''[101] = {
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
	},''',
    ),
]
for old, new in side_patches:
    if old not in quest_table:
        raise SystemExit("side miss")
    quest_table = quest_table.replace(old, new)

# Insert new quests before closing of table (before final })
new_quests = '''
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
'''

# Insert before final closing brace of quest table
# quest_table ends with "}\n" for the table - find last "}\n" of outer
if not quest_table.rstrip().endswith("}"):
    raise SystemExit("quest table end unexpected")
quest_table = quest_table.rstrip()
assert quest_table.endswith("}")
quest_table = quest_table[:-1] + new_quests + "}\n"

# unique_block currently starts with "local UniqueItemDatabase = {"
# Rename for module export
unique_inner = unique_block.replace("local UniqueItemDatabase = ", "QuestCatalog.UniqueItems = ", 1)

catalog = f'''--!strict
-- QuestCatalog: shared quest + unique-item data (Q1 expansion)
-- Runtime accept/progress/turn-in stays in ServerScriptService.QuestSystem

local QuestCatalog = {{}}

{unique_inner}

QuestCatalog.Quests = {quest_table}

function QuestCatalog.Get(questId: number)
	return QuestCatalog.Quests[questId]
end

function QuestCatalog.GetUniqueItem(itemId: number)
	return QuestCatalog.UniqueItems[itemId]
end

function QuestCatalog.GetAll()
	return QuestCatalog.Quests
end

return QuestCatalog
'''

# Fix strict typing - Luau might not like number annotations if old studio - use without types for compatibility
catalog = catalog.replace("function QuestCatalog.Get(questId: number)", "function QuestCatalog.Get(questId)")
catalog = catalog.replace("function QuestCatalog.GetUniqueItem(itemId: number)", "function QuestCatalog.GetUniqueItem(itemId)")

out = studio / "QuestCatalog.lua"
out.write_text(catalog, encoding="utf-8")
print("Wrote", out, "bytes", out.stat().st_size)

# Patch QuestSystem: remove UniqueItemDatabase and QuestDatabase, add require
head_end = src.index("local UniqueItemDatabase = {")
runtime_start = src.index("-- ============================================\n-- Система квестов игрока")
prefix = src[: src.index("-- ============================================\n-- Уникальные предметы")]
# Keep remotes setup from start through Unique section header removal
# Actually keep from line 1 until Unique items section, then inject require

# Rebuild QuestSystem: everything before UniqueItemDatabase, then require, then from QuestSystem = {}
before = src[:u0]
# Trim trailing comments about unique items section header
# Find the section header before UniqueItemDatabase
header = src.rfind("-- ============================================\n-- Уникальные предметы", 0, u0)
if header != -1:
    before = src[:header]

after = src[runtime_start:]

# Replace UniqueItemDatabase and QuestDatabase references
after = after.replace("UniqueItemDatabase[", "QuestCatalog.UniqueItems[")
after = after.replace("QuestDatabase[", "QuestCatalog.Quests[")
after = after.replace("pairs(QuestDatabase)", "pairs(QuestCatalog.Quests)")

inject = '''-- ============================================
-- Quest catalog (data) — ReplicatedStorage.RealmOfSpirits.QuestCatalog
-- ============================================
local QuestCatalog = require(realmFolder:WaitForChild("QuestCatalog"))

'''

# Add VisitZone handling in UpdateProgress
visit_snip_old = '''					elseif progressType == "CareSpirit" or progressType == "TemperSpirit"
						or progressType == "OpenKamiSanctum"
						or progressType == "KamiSynthesize"
						or progressType == "KamiDisintegrate" then'''

visit_snip_new = '''					elseif progressType == "VisitZone" then
						local want = objective.ZoneDetail
						local got = data and data.ZoneDetail
						if want and got and tostring(want) == tostring(got) then
							objective.Current = (objective.Current or 0) + (data.Count or 1)
						end
					elseif progressType == "CareSpirit" or progressType == "TemperSpirit"
						or progressType == "OpenKamiSanctum"
						or progressType == "KamiSynthesize"
						or progressType == "KamiDisintegrate" then'''

if visit_snip_old not in after:
    raise SystemExit("VisitZone inject point missing")
after = after.replace(visit_snip_old, visit_snip_new)

# Skip Deprecated in GetAvailableQuests if present
# Find GetAvailableQuests loop
avail_old = "\tfor questId, quest in pairs(QuestCatalog.Quests) do\n"
# may already be replaced
if "for questId, quest in pairs(QuestCatalog.Quests) do" in after:
    after = after.replace(
        "for questId, quest in pairs(QuestCatalog.Quests) do\n\t\tif not self.ActiveQuests[questId] and not self.CompletedQuests[questId] then",
        "for questId, quest in pairs(QuestCatalog.Quests) do\n\t\tif quest.Deprecated then\n\t\t\tcontinue\n\t\tend\n\t\tif not self.ActiveQuests[questId] and not self.CompletedQuests[questId] then",
        1,
    )

new_qs = before + inject + after
src_path.write_text(new_qs, encoding="utf-8")
print("Patched QuestSystem.lua", src_path.stat().st_size)

# Sanity: no leftover local QuestDatabase
if "local QuestDatabase" in new_qs:
    raise SystemExit("QuestDatabase still defined")
if "local UniqueItemDatabase" in new_qs:
    raise SystemExit("UniqueItemDatabase still defined")
print("OK")
PY
