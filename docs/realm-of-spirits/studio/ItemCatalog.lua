-- ItemCatalog - shop, loot, evolution materials
local ItemCatalog = {}

ItemCatalog.ById = {
	[1] = {Id = 1, Name = "Ловушка", Category = "Catch", Price = 25, SellPrice = 10, Description = "Для поимки духов", CombatUtility = true},
	[2] = {Id = 2, Name = "Зелье здоровья", Category = "Consumable", Price = 40, SellPrice = 15, Description = "Восстанавливает HP в бою", HealAmount = 40, CombatUtility = true},
	[3] = {Id = 3, Name = "Свиток опыта", Category = "Consumable", Price = 100, SellPrice = 40, Description = "+50 опыта игроку", ExpAmount = 50, CombatUtility = true},
	-- Evolution crystals (loot)
	[101] = {Id = 101, Name = "Огненный кристалл", Category = "Material", Element = "Fire", SellPrice = 8, Description = "Материал эволюции огненных духов", CombatUtility = false},
	[102] = {Id = 102, Name = "Ледяной кристалл", Category = "Material", Element = "Ice", SellPrice = 8, Description = "Материал эволюции ледяных духов", CombatUtility = false},
	[103] = {Id = 103, Name = "Теневой кристалл", Category = "Material", Element = "Dark", SellPrice = 10, Description = "Материал эволюции тёмных духов", CombatUtility = false},
	[104] = {Id = 104, Name = "Грозовой кристалл", Category = "Material", Element = "Lightning", SellPrice = 12, Description = "Материал эволюции грозовых духов", CombatUtility = false},
	[105] = {Id = 105, Name = "Световой кристалл", Category = "Material", Element = "Light", SellPrice = 15, Description = "Материал эволюции световых духов", CombatUtility = false},
	[106] = {Id = 106, Name = "Водный кристалл", Category = "Material", Element = "Water", SellPrice = 9, Description = "Материал эволюции водных духов", CombatUtility = false},
}

ItemCatalog.ShopIds = {1, 2, 3}

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

return ItemCatalog
