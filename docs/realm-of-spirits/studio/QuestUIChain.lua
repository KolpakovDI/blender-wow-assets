-- QuestUIChain: group quest list rows by prerequisite chains (client-only)
local QuestUIChain = {}

local TYPE_RANK = { Story = 1, Hunt = 2, Side = 3 }
local TYPE_LABEL = { Story = "Сюжет", Hunt = "Охота", Side = "Побочные" }

local questMetaLookup = {}

local function registerQuestMeta(q)
	if type(q) == "table" and q.Id ~= nil then
		local id = tonumber(q.Id)
		if id then
			questMetaLookup[id] = q
		end
	end
end

local function rebuildQuestMetaLookup(questCatalog, currentQuestData)
	table.clear(questMetaLookup)
	if questCatalog and type(questCatalog.Quests) == "table" then
		for _, q in pairs(questCatalog.Quests) do
			registerQuestMeta(q)
		end
	end
	for _, q in ipairs(currentQuestData.Available or {}) do
		registerQuestMeta(q)
	end
	for _, row in ipairs(currentQuestData.Active or {}) do
		registerQuestMeta(row.Quest)
	end
	for _, q in ipairs(currentQuestData.Completed or {}) do
		registerQuestMeta(q)
	end
end

local function getChainRootId(questId)
	local startQ = questMetaLookup[questId]
	local startType = (startQ and startQ.Type) or "Side"
	local cur = questId
	local visited = {}
	while true do
		if visited[cur] then
			return questId
		end
		visited[cur] = true
		local q = questMetaLookup[cur]
		if not q then
			return cur
		end
		local prereqs = q.Prerequisites or {}
		if #prereqs == 0 then
			return cur
		end
		local parent = nil
		for _, raw in ipairs(prereqs) do
			local p = tonumber(raw)
			if p then
				local pq = questMetaLookup[p]
				local pType = (pq and pq.Type) or startType
				if pType == startType then
					if not parent or p < parent then
						parent = p
					end
				end
			end
		end
		if not parent then
			return cur
		end
		cur = parent
	end
end

local function chainDepth(questId)
	local qType = (questMetaLookup[questId] and questMetaLookup[questId].Type) or "Side"
	local depth = 0
	local cur = questId
	local visited = {}
	while true do
		if visited[cur] then
			break
		end
		visited[cur] = true
		local q = questMetaLookup[cur]
		if not q then
			break
		end
		local prereqs = q.Prerequisites or {}
		if #prereqs == 0 then
			break
		end
		local parent = nil
		for _, raw in ipairs(prereqs) do
			local p = tonumber(raw)
			if p then
				local pq = questMetaLookup[p]
				if ((pq and pq.Type) or qType) == qType then
					if not parent or p < parent then
						parent = p
					end
				end
			end
		end
		if not parent then
			break
		end
		cur = parent
		depth += 1
	end
	return depth
end

local function isLinkedInChain(questId)
	local q = questMetaLookup[questId]
	if not q then
		return false
	end
	local qType = q.Type or "Side"
	for _, raw in ipairs(q.Prerequisites or {}) do
		local p = tonumber(raw)
		if p then
			local pq = questMetaLookup[p]
			if pq and (pq.Type or "Side") == qType then
				return true
			end
		end
	end
	for otherId, other in pairs(questMetaLookup) do
		if otherId ~= questId and (other.Type or "Side") == qType then
			for _, raw in ipairs(other.Prerequisites or {}) do
				if tonumber(raw) == questId then
					return true
				end
			end
		end
	end
	return false
end

local function chainTitle(rootId)
	local root = questMetaLookup[rootId]
	local t = (root and root.Type) or "Side"
	local label = TYPE_LABEL[t] or "Квесты"
	local name = (root and root.Name) or ("#" .. tostring(rootId))
	return label .. " · " .. name
end

local function questSortTuple(q)
	local id = tonumber(q.Id) or 0
	local t = q.Type or "Side"
	return TYPE_RANK[t] or 9, tonumber(q.Level) or 1, id
end

local function sortQuestRows(a, b, mode)
	local qa = (mode == "Active") and a.Quest or a
	local qb = (mode == "Active") and b.Quest or b
	local ida, idb = tonumber(qa.Id) or 0, tonumber(qb.Id) or 0
	local da, db = chainDepth(ida), chainDepth(idb)
	if da ~= db then
		return da < db
	end
	local ta, tb = questSortTuple(qa), questSortTuple(qb)
	if ta ~= tb then
		return ta < tb
	end
	return ida < idb
end

function QuestUIChain.renderGroupedList(items, mode, ctx, questCatalog, currentQuestData)
	rebuildQuestMetaLookup(questCatalog, currentQuestData)

	local buckets = {}
	local singletons = {}

	for _, item in ipairs(items) do
		local q = (mode == "Active") and item.Quest or item
		local id = tonumber(q and q.Id)
		if not id then
			continue
		end
		local root = getChainRootId(id)
		if isLinkedInChain(id) then
			local bucket = buckets[root]
			if not bucket then
				bucket = {}
				buckets[root] = bucket
			end
			table.insert(bucket, item)
		else
			table.insert(singletons, item)
		end
	end

	local roots = {}
	for root, _ in pairs(buckets) do
		table.insert(roots, root)
	end
	table.sort(roots, function(a, b)
		local ra = questMetaLookup[a]
		local rb = questMetaLookup[b]
		local ta = TYPE_RANK[(ra and ra.Type) or "Side"] or 9
		local tb = TYPE_RANK[(rb and rb.Type) or "Side"] or 9
		if ta ~= tb then
			return ta < tb
		end
		return a < b
	end)

	for _, root in ipairs(roots) do
		table.sort(buckets[root], function(a, b)
			return sortQuestRows(a, b, mode)
		end)
	end

	table.sort(singletons, function(a, b)
		return sortQuestRows(a, b, mode)
	end)

	local function addHeader(title, layoutOrder)
		local header = Instance.new("Frame")
		header.Name = "ChainHeader"
		header.Size = UDim2.new(1, -6, 0, 26)
		header.BackgroundColor3 = Color3.fromRGB(42, 34, 62)
		header.BackgroundTransparency = 0.15
		header.BorderSizePixel = 0
		header.LayoutOrder = layoutOrder
		header.ZIndex = 7
		header.Parent = ctx.questListFrame

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = header

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -12, 1, 0)
		lbl.Position = UDim2.new(0, 8, 0, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = title
		lbl.TextColor3 = ctx.colors.Accent
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 11
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextTruncate = Enum.TextTruncate.AtEnd
		lbl.ZIndex = 8
		lbl.Parent = header
	end

	local order = 0
	for _, root in ipairs(roots) do
		order += 1
		addHeader(chainTitle(root), order)
		for _, item in ipairs(buckets[root]) do
			order += 1
			local q = (mode == "Active") and item.Quest or item
			ctx.createEntry(
				q,
				mode == "Active",
				(mode == "Active") and item.Progress,
				order,
				(mode == "Active") and item.ReadyToTurnIn
			)
		end
	end

	for _, item in ipairs(singletons) do
		order += 1
		local q = (mode == "Active") and item.Quest or item
		ctx.createEntry(
			q,
			mode == "Active",
			(mode == "Active") and item.Progress,
			order,
			(mode == "Active") and item.ReadyToTurnIn
		)
	end
end

return QuestUIChain
