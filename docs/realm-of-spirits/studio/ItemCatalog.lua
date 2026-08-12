-- ItemCatalog - shop, loot, evolution materials, gold sinks
local ItemCatalog = {}

ItemCatalog.ById = {
	[1] = {Id = 1, Name = "Ловушка", Category = "Catch", Price = 25, SellPrice = 10, Description = "Для поимки духов", CombatUtility = true},
	[2] = {Id = 2, Name = "Зелье здоровья", Category = "Consumable", Price = 40, SellPrice = 15, Description = "Восстанавливает HP в бою", HealAmount = 40, CombatUtility = true},
	-- P0: scroll ROI fixed vs free battle XP (+50 XP / 30c)
	[3] = {Id = 3, Name = "Свиток опыта", Category = "Consumable", Price = 80, SellPrice = 30, Description = "+120 опыта игроку", ExpAmount = 120, CombatUtility = true},
	[4] = {Id = 4, Name = "Лакомство духа", Category = "Consumable", Price = 35, SellPrice = 12, Description = "Уход: +Bond XP (Spirit Resonance)", BondTreat = true, CombatUtility = false},
	-- P0: temper stone scarce; DailyBuyCap enforced in TradeSystem
	[5] = {Id = 5, Name = "Камень закалки", Category = "Consumable", Price = 200, SellPrice = 40, Description = "Temper без выносливости (лимит 3/день)", TemperStone = true, DailyBuyCap = 3, CombatUtility = false},
	-- P1: gold sinks (Haven / identity) — price in GoldCoins
	[201] = {Id = 201, Name = "Фонарь Haven", Category = "Cosmetic", Price = 0, GoldPrice = 1, SellPrice = 0, Unsellable = true, Description = "Косметика для Haven (1 золото)", CosmeticGrant = "HavenLantern", CombatUtility = false},
	[202] = {Id = 202, Name = "Слот витрины", Category = "Service", Price = 0, GoldPrice = 2, SellPrice = 0, Unsellable = true, Description = "+1 слот Showcase в Haven (2 золота)", Grant = "ShowcaseSlot", CombatUtility = false},
	[203] = {Id = 203, Name = "Жетон имени", Category = "Service", Price = 0, GoldPrice = 1, SellPrice = 0, Unsellable = true, Description = "Переименовать духа (1 золото)", Grant = "RenameToken", CombatUtility = false},
	-- Evolution crystals (loot) — P1: unsellable (preserve rarity)
	[101] = {Id = 101, Name = "Огненный кристалл", Category = "Material", Element = "Fire", SellPrice = 0, Unsellable = true, Description = "Материал эволюции огненных духов", CombatUtility = false},
	[102] = {Id = 102, Name = "Ледяной кристалл", Category = "Material", Element = "Ice", SellPrice = 0, Unsellable = true, Description = "Материал эволюции ледяных духов", CombatUtility = false},
	[103] = {Id = 103, Name = "Теневой кристалл", Category = "Material", Element = "Dark", SellPrice = 0, Unsellable = true, Description = "Материал эволюции тёмных духов", CombatUtility = false},
	[104] = {Id = 104, Name = "Грозовой кристалл", Category = "Material", Element = "Lightning", SellPrice = 0, Unsellable = true, Description = "Материал эволюции грозовых духов", CombatUtility = false},
	[105] = {Id = 105, Name = "Световой кристалл", Category = "Material", Element = "Light", SellPrice = 0, Unsellable = true, Description = "Материал эволюции световых духов", CombatUtility = false},
	[106] = {Id = 106, Name = "Водный кристалл", Category = "Material", Element = "Water", SellPrice = 0, Unsellable = true, Description = "Материал эволюции водных духов", CombatUtility = false},
	[107] = {Id = 107, Name = "Земляной кристалл", Category = "Material", Element = "Earth", SellPrice = 0, Unsellable = true, Description = "Материал эволюции земляных духов", CombatUtility = false},
	[108] = {Id = 108, Name = "Пепельный кристалл", Category = "Material", Element = "Fire", SellPrice = 0, Unsellable = true, Description = "Материал эволюции пепельных духов", CombatUtility = false},
	[109] = {Id = 109, Name = "Ветряной кристалл", Category = "Material", Element = "Wind", SellPrice = 0, Unsellable = true, Description = "Материал эволюции ветряных духов", CombatUtility = false},
	[110] = {Id = 110, Name = "Природный кристалл", Category = "Material", Element = "Nature", SellPrice = 0, Unsellable = true, Description = "Материал эволюции природных духов", CombatUtility = false},
	[111] = {Id = 111, Name = "Лунный кристалл", Category = "Material", Element = "Moon", SellPrice = 0, Unsellable = true, Description = "Материал эволюции лунных духов", CombatUtility = false},
	[112] = {Id = 112, Name = "Ядовитый кристалл", Category = "Material", Element = "Poison", SellPrice = 0, Unsellable = true, Description = "Материал эволюции ядовитых духов", CombatUtility = false},
	[113] = {Id = 113, Name = "Песчаный кристалл", Category = "Material", Element = "Sand", SellPrice = 0, Unsellable = true, Description = "Материал эволюции песчаных духов", CombatUtility = false},
	[114] = {Id = 114, Name = "Металлический кристалл", Category = "Material", Element = "Metal", SellPrice = 0, Unsellable = true, Description = "Материал эволюции металлических духов", CombatUtility = false},
	[115] = {Id = 115, Name = "Кристальный кристалл", Category = "Material", Element = "Crystal", SellPrice = 0, Unsellable = true, Description = "Материал эволюции кристальных духов", CombatUtility = false},
	[116] = {Id = 116, Name = "Лавовый кристалл", Category = "Material", Element = "Magma", SellPrice = 0, Unsellable = true, Description = "Материал эволюции лавовых духов", CombatUtility = false},
	[117] = {Id = 117, Name = "Туманный кристалл", Category = "Material", Element = "Mist", SellPrice = 0, Unsellable = true, Description = "Материал эволюции туманных духов", CombatUtility = false},
	[118] = {Id = 118, Name = "Небесный кристалл", Category = "Material", Element = "Sky", SellPrice = 0, Unsellable = true, Description = "Материал эволюции небесных духов", CombatUtility = false},
	[120] = {Id = 120, Name = "Коробка редкой манги", Category = "Quest", SellPrice = 0, Unsellable = true, WhyTag = "квест Мики", Description = "Украденная партия манги для Мики (квест)", CombatUtility = false},
	-- Kami Sanctum materials
	[301] = {Id = 301, Name = "Осколок Ками", Category = "SanctumMaterial", SellPrice = 0, Unsellable = true, Description = "Базовый катализатор синтеза в Святилище Ками", CombatUtility = false},
	[302] = {Id = 302, Name = "Камень Гармонии", Category = "SanctumMaterial", SellPrice = 0, Unsellable = true, Description = "Стабилизирует Primary при синтезе", CombatUtility = false},
	[303] = {Id = 303, Name = "Ядро Разлома", Category = "SanctumMaterial", SellPrice = 0, Unsellable = true, Description = "Усиливает Unique при разнородных донорах", CombatUtility = false},
	[304] = {Id = 304, Name = "Печать Мики", Category = "SanctumMaterial", SellPrice = 0, Unsellable = true, Description = "Ивент/квест: шанс Rare+ Unique", CombatUtility = false},
	[310] = {Id = 310, Name = "Звезда трансформации I", Category = "SanctumMaterial", SellPrice = 0, Unsellable = true, Description = "Сдвигает веса Unique и силу синтеза", CombatUtility = false},
	[311] = {Id = 311, Name = "Звезда трансформации II", Category = "SanctumMaterial", SellPrice = 0, Unsellable = true, Description = "Сильнее Звезды I", CombatUtility = false},
	[312] = {Id = 312, Name = "Звезда трансформации III", Category = "SanctumMaterial", SellPrice = 0, Unsellable = true, Description = "Макс. тир; редкий лут Resonant-дезинтеграции", CombatUtility = false},
	[320] = {Id = 320, Name = "Эссенция Огня", Category = "SanctumMaterial", Element = "Fire", SellPrice = 0, Unsellable = true, Description = "Дезинтеграция / квесты Святилища", CombatUtility = false},
	[321] = {Id = 321, Name = "Эссенция Земли", Category = "SanctumMaterial", Element = "Earth", SellPrice = 0, Unsellable = true, Description = "Дезинтеграция / квесты Святилища", CombatUtility = false},
	[322] = {Id = 322, Name = "Эссенция Ветра", Category = "SanctumMaterial", Element = "Wind", SellPrice = 0, Unsellable = true, Description = "Дезинтеграция / квесты Святилища", CombatUtility = false},
	[323] = {Id = 323, Name = "Эссенция Воды", Category = "SanctumMaterial", Element = "Water", SellPrice = 0, Unsellable = true, Description = "Дезинтеграция / квесты Святилища", CombatUtility = false},
}

-- Copper shop + gold sinks (201–203)
ItemCatalog.ShopIds = {1, 2, 3, 4, 5, 201, 202, 203}

function ItemCatalog.Get(id)
	local n = tonumber(id)
	if n ~= nil then
		return ItemCatalog.ById[n]
	end
	return ItemCatalog.ById[id]
end

--- Short bag tag: why the player holds this (UI package A)
function ItemCatalog.GetWhyTag(id)
	local item = ItemCatalog.Get(id)
	if not item then
		return nil
	end
	if type(item.WhyTag) == "string" and item.WhyTag ~= "" then
		return item.WhyTag
	end
	local cat = item.Category
	if cat == "Material" then
		return "эволюция"
	end
	if cat == "Quest" then
		return "квест Мики"
	end
	if cat == "SanctumMaterial" then
		return "святилище"
	end
	if cat == "Catch" then
		return "ловля"
	end
	if cat == "Consumable" and item.HealAmount then
		return "бой"
	end
	return nil
end

--- Emoji icon for bag grid (UI package D)
function ItemCatalog.GetIconEmoji(id)
	local item = ItemCatalog.Get(id)
	if not item then
		return "📦"
	end
	local el = item.Element
	if el == "Fire" or el == "Magma" then
		return "🔥"
	end
	if el == "Ice" or el == "Water" or el == "Mist" then
		return "❄️"
	end
	if el == "Earth" or el == "Sand" or el == "Metal" or el == "Crystal" then
		return "🪨"
	end
	if el == "Wind" or el == "Sky" or el == "Lightning" then
		return "💨"
	end
	if el == "Dark" or el == "Poison" then
		return "🌑"
	end
	if el == "Light" or el == "Moon" or el == "Nature" then
		return "✨"
	end
	local cat = item.Category
	if cat == "Catch" then
		return "🎯"
	end
	if cat == "Consumable" then
		if item.HealAmount then
			return "❤️"
		end
		if item.ExpAmount then
			return "📜"
		end
		if item.TemperStone then
			return "🪨"
		end
		if item.BondTreat then
			return "🍬"
		end
		return "🧪"
	end
	if cat == "Quest" then
		return "📚"
	end
	if cat == "SanctumMaterial" then
		return "⛩️"
	end
	if cat == "Cosmetic" or cat == "Service" then
		return "🏮"
	end
	if cat == "Material" then
		return "💎"
	end
	return "📦"
end

--- Rarity tone for bag cell stroke (UI package D)
function ItemCatalog.GetRarityColor(id)
	local item = ItemCatalog.Get(id)
	if not item then
		return Color3.fromRGB(140, 140, 150)
	end
	local cat = item.Category
	if cat == "Material" then
		return Color3.fromRGB(90, 170, 255)
	end
	if cat == "Quest" then
		return Color3.fromRGB(255, 200, 80)
	end
	if cat == "SanctumMaterial" then
		return Color3.fromRGB(190, 120, 255)
	end
	if cat == "Cosmetic" or cat == "Service" then
		return Color3.fromRGB(255, 215, 120)
	end
	if cat == "Catch" then
		return Color3.fromRGB(90, 220, 120)
	end
	if cat == "Consumable" then
		return Color3.fromRGB(180, 230, 180)
	end
	return Color3.fromRGB(170, 170, 180)
end

function ItemCatalog.GetShopItems()
	local list = {}
	for _, id in ipairs(ItemCatalog.ShopIds) do
		local item = ItemCatalog.ById[id]
		if item then table.insert(list, item) end
	end
	return list
end

function ItemCatalog.IsCombatUtility(id)
	local item = ItemCatalog.ById[id]
	return item ~= nil and item.CombatUtility == true
end

function ItemCatalog.CanSell(id)
	local item = ItemCatalog.ById[id]
	if not item then return false end
	if item.Unsellable == true then return false end
	local sell = tonumber(item.SellPrice) or 0
	return sell > 0
end

--- Battle copper reward: 30 early → 20 mid (P2 diminishing)
function ItemCatalog.BattleCoinReward(playerLevel)
	local level = math.max(1, math.floor(tonumber(playerLevel) or 1))
	return math.clamp(30 - math.floor((level - 1) * 0.8), 20, 30)
end

return ItemCatalog
