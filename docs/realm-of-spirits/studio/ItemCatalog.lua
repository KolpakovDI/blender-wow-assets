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
	[120] = {Id = 120, Name = "Коробка редкой манги", Category = "Quest", SellPrice = 0, Unsellable = true, Description = "Украденная партия манги для Мики (квест)", CombatUtility = false},
}

-- Copper shop + gold sinks (201–203)
ItemCatalog.ShopIds = {1, 2, 3, 4, 5, 201, 202, 203}

function ItemCatalog.Get(id)
	return ItemCatalog.ById[id]
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
