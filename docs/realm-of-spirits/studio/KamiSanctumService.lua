-- KamiSanctumService: shrine + remote handlers
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local realm = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local sssRealm = ServerScriptService:WaitForChild("RealmOfSpirits")

local KamiSanctumSystem = require(sssRealm:WaitForChild("KamiSanctumSystem"))
local KamiSanctumConfig = require(realm:WaitForChild("KamiSanctumConfig"))
local ItemCatalog = require(realm:WaitForChild("ItemCatalog"))

local remote = realm:FindFirstChild("KamiSanctum")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "KamiSanctum"
	remote.Parent = realm
end

local PEDESTAL_NAME = "KamiSanctumShrine"
local MESH_TEMPLATE_NAME = "CyberShintoLabShrine"
local lastOpen = {}
local openSanctum

local function findMeshTemplate()
	local haven = workspace:FindFirstChild("OtakuHaven")
	local decor = haven and haven:FindFirstChild("Decor")
	if decor then
		local mesh = decor:FindFirstChild(MESH_TEMPLATE_NAME)
		if mesh and mesh:IsA("Model") then
			return mesh
		end
		-- After first bind the Decor mesh may keep mesh name or become pedestal.
		local named = decor:FindFirstChild(PEDESTAL_NAME)
		if named and named:IsA("Model") and named:GetAttribute("IsKamiSanctumMesh") then
			return named
		end
	end
	local loose = workspace:FindFirstChild(MESH_TEMPLATE_NAME)
	if loose and loose:IsA("Model") then
		return loose
	end
	local pedestal = workspace:FindFirstChild(PEDESTAL_NAME)
	if pedestal and pedestal:IsA("Model") and pedestal:GetAttribute("IsKamiSanctumMesh") then
		return pedestal
	end
	return nil
end

local function placeModelOnGround(model, groundPos)
	-- Bounds from visible mesh only (ignore invisible Base prompt anchor).
	local minY, maxY = math.huge, -math.huge
	local minX, maxX = math.huge, -math.huge
	local minZ, maxZ = math.huge, -math.huge
	local any = false
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d.Name ~= "Base" and d.Transparency < 1 then
			any = true
			local p, s = d.Position, d.Size
			minX = math.min(minX, p.X - s.X * 0.5)
			maxX = math.max(maxX, p.X + s.X * 0.5)
			minY = math.min(minY, p.Y - s.Y * 0.5)
			maxY = math.max(maxY, p.Y + s.Y * 0.5)
			minZ = math.min(minZ, p.Z - s.Z * 0.5)
			maxZ = math.max(maxZ, p.Z + s.Z * 0.5)
		end
	end
	local pivot = model:GetPivot()
	local centerX, centerZ, bottomY
	if any then
		centerX = (minX + maxX) * 0.5
		centerZ = (minZ + maxZ) * 0.5
		bottomY = minY
	else
		local cf, size = model:GetBoundingBox()
		centerX = cf.Position.X
		centerZ = cf.Position.Z
		bottomY = cf.Position.Y - size.Y * 0.5
	end
	local delta = Vector3.new(
		groundPos.X - centerX,
		groundPos.Y - bottomY,
		groundPos.Z - centerZ
	)
	model:PivotTo(pivot + delta)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
		end
	end
end

local function ensureInteract(base)
	if not base then
		return
	end
	if not base:FindFirstChild("SanctumLabel") then
		local bill = Instance.new("BillboardGui")
		bill.Name = "SanctumLabel"
		bill.Size = UDim2.fromOffset(220, 44)
		bill.StudsOffset = Vector3.new(0, 6.5, 0)
		bill.AlwaysOnTop = true
		bill.Enabled = false
		bill.Parent = base
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = "Святилище Ками · E"
		label.TextColor3 = Color3.fromRGB(230, 200, 255)
		label.Font = Enum.Font.GothamBold
		label.TextSize = 18
		label.TextStrokeTransparency = 0.35
		label.Parent = bill
	end
	if not base:FindFirstChild("SanctumPrompt") then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "SanctumPrompt"
		prompt.ActionText = "Открыть"
		prompt.ObjectText = "Святилище Ками"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 16
		prompt.RequiresLineOfSight = false
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.Parent = base
		prompt.Triggered:Connect(function(player)
			openSanctum(player)
		end)
	end
	if not base:FindFirstChildWhichIsA("ClickDetector") then
		local cd = Instance.new("ClickDetector")
		cd.MaxActivationDistance = 16
		cd.Parent = base
		cd.MouseClick:Connect(function(player)
			openSanctum(player)
		end)
	end
end

local function attachMeshShrine(model, groundPos)
	model:SetAttribute("IsKamiSanctumMesh", true)
	-- Keep mesh name in Decor so rebuilds still find it; also alias attribute for lookups.
	if model.Name ~= MESH_TEMPLATE_NAME and model.Name ~= PEDESTAL_NAME then
		model.Name = MESH_TEMPLATE_NAME
	end
	placeModelOnGround(model, groundPos)

	local base = model:FindFirstChild("Base")
	if not (base and base:IsA("BasePart")) then
		base = Instance.new("Part")
		base.Name = "Base"
		base.Size = Vector3.new(6, 1, 6)
		base.Transparency = 1
		base.Anchored = true
		base.CanCollide = false
		base.CanQuery = true
		base.CFrame = CFrame.new(groundPos + Vector3.new(0, 0.5, 0))
		base.Parent = model
	end
	model.PrimaryPart = base
	ensureInteract(base)
	return true
end

local function playerData(player)
	if _G.GetPlayerData then
		return _G.GetPlayerData(player)
	end
	local bf = sssRealm:FindFirstChild("GetPlayerDataBF")
	if bf then
		return bf:Invoke(player.UserId)
	end
	return nil
end

local function invQty(data, itemId)
	itemId = tonumber(itemId)
	if not data or type(data.Inventory) ~= "table" or not itemId then
		return 0
	end
	for _, inv in ipairs(data.Inventory) do
		if tonumber(inv.Id) == itemId then
			return tonumber(inv.Quantity) or 0
		end
	end
	return 0
end

local function ensureStarterShard(player, data)
	if not player or not data then
		return false
	end
	local shardId = KamiSanctumConfig.ShardId
	if invQty(data, shardId) >= 1 then
		return false
	end
	if type(data.KamiSanctumMeta) ~= "table" then
		data.KamiSanctumMeta = {}
	end
	if data.KamiSanctumMeta.StarterShardGranted then
		return false
	end
	if _G.AddInventoryItem then
		_G.AddInventoryItem(player, shardId, 1)
	else
		data.Inventory = data.Inventory or {}
		table.insert(data.Inventory, { Id = shardId, Quantity = 1 })
	end
	data.KamiSanctumMeta.StarterShardGranted = true
	return true
end

local function sync(player)
	local data = playerData(player)
	local DataEvent = realm:FindFirstChild("DataSync")
	if DataEvent and data then
		DataEvent:FireClient(player, "FullSync", data)
	end
	if player and data then
		local idx = tonumber(data.ActiveSpiritIndex) or #((data.Spirits) or {})
		local sp = data.Spirits and data.Spirits[idx]
		if sp then
			player:SetAttribute("ActiveSpiritIndex", idx)
			player:SetAttribute("ActiveSpiritName", sp.Name or "")
		end
	end
end

openSanctum = function(player)
	if not player then
		return
	end
	local uid = player.UserId
	local now = os.clock()
	if lastOpen[uid] and (now - lastOpen[uid]) < 0.6 then
		return
	end
	lastOpen[uid] = now
	local data = playerData(player)
	if data and ensureStarterShard(player, data) then
		sync(player)
		local item = ItemCatalog.Get(KamiSanctumConfig.ShardId)
		local DataEvent = realm:FindFirstChild("DataSync")
		if DataEvent then
			DataEvent:FireClient(player, "Toast", {
				Text = "Стартовый " .. (item and item.Name or "Осколок Ками") .. " · хватит на первый синтез",
			})
		end
	end
	remote:FireClient(player, "Open", {})
	if _G.UpdateQuestProgress then
		_G.UpdateQuestProgress(player, "OpenKamiSanctum", {Count = 1})
	else
		local qbf = sssRealm:FindFirstChild("UpdateQuestProgressBF")
		if qbf then
			qbf:Invoke(player, "OpenKamiSanctum", {Count = 1})
		end
	end
end

local function buildShrine()
	local qm = workspace:FindFirstChild("QuestMaster")
	if not qm then
		return false
	end

	local pivot = qm:GetPivot().Position
	local groundPos = Vector3.new(pivot.X + 40, 0, pivot.Z + 16)
	local meshTemplate = findMeshTemplate()
	if meshTemplate then
		-- Remove procedural pedestal only; keep the mesh shrine in place.
		local existing = workspace:FindFirstChild(PEDESTAL_NAME)
		if existing and existing ~= meshTemplate and not existing:GetAttribute("IsKamiSanctumMesh") then
			existing:Destroy()
		end
		return attachMeshShrine(meshTemplate, groundPos)
	end

	local existing = workspace:FindFirstChild(PEDESTAL_NAME)
	if existing then
		existing:Destroy()
	end

	local pos = Vector3.new(groundPos.X, 0.55, groundPos.Z)

	local model = Instance.new("Model")
	model.Name = PEDESTAL_NAME

	local base = Instance.new("Part")
	base.Name = "Base"
	base.Size = Vector3.new(8, 0.7, 8)
	base.Anchored = true
	base.CanCollide = true
	base.Material = Enum.Material.SmoothPlastic
	base.Color = Color3.fromRGB(48, 36, 64)
	base.CFrame = CFrame.new(pos)
	base.Parent = model

	-- torii-like posts
	for _, ox in ipairs({-2.8, 2.8}) do
		local post = Instance.new("Part")
		post.Name = "ToriiPost"
		post.Size = Vector3.new(0.55, 7, 0.55)
		post.Anchored = true
		post.CanCollide = false
		post.Material = Enum.Material.Wood
		post.Color = Color3.fromRGB(160, 40, 48)
		post.CFrame = CFrame.new(pos + Vector3.new(ox, 3.5, -2.5))
		post.Parent = model
	end
	local beam = Instance.new("Part")
	beam.Name = "ToriiBeam"
	beam.Size = Vector3.new(6.4, 0.45, 0.55)
	beam.Anchored = true
	beam.CanCollide = false
	beam.Material = Enum.Material.Wood
	beam.Color = Color3.fromRGB(180, 50, 55)
	beam.CFrame = CFrame.new(pos + Vector3.new(0, 6.6, -2.5))
	beam.Parent = model

	-- reactor glass
	local reactor = Instance.new("Part")
	reactor.Name = "Reactor"
	reactor.Shape = Enum.PartType.Cylinder
	reactor.Size = Vector3.new(4.2, 3.2, 3.2)
	reactor.Anchored = true
	reactor.CanCollide = false
	reactor.Material = Enum.Material.Glass
	reactor.Transparency = 0.35
	reactor.Color = Color3.fromRGB(160, 220, 255)
	reactor.CFrame = CFrame.new(pos + Vector3.new(0, 2.4, 0.5)) * CFrame.Angles(0, 0, math.rad(90))
	reactor.Parent = model

	local core = Instance.new("Part")
	core.Name = "Core"
	core.Shape = Enum.PartType.Ball
	core.Size = Vector3.new(1.4, 1.4, 1.4)
	core.Anchored = true
	core.CanCollide = false
	core.Material = Enum.Material.Neon
	core.Color = Color3.fromRGB(200, 120, 255)
	core.CFrame = CFrame.new(pos + Vector3.new(0, 2.4, 0.5))
	core.Parent = model

	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(190, 130, 255)
	glow.Brightness = 2
	glow.Range = 16
	glow.Parent = core

	local bill = Instance.new("BillboardGui")
	bill.Name = "SanctumLabel"
	bill.Size = UDim2.fromOffset(220, 44)
	bill.StudsOffset = Vector3.new(0, 5.2, 0)
	bill.AlwaysOnTop = true
	bill.Enabled = false
	bill.Parent = base
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "Святилище Ками · E"
	label.TextColor3 = Color3.fromRGB(230, 200, 255)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 18
	label.TextStrokeTransparency = 0.35
	label.Parent = bill

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "SanctumPrompt"
	prompt.ActionText = "Открыть"
	prompt.ObjectText = "Святилище Ками"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 16
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = base
	prompt.Triggered:Connect(function(player)
		openSanctum(player)
	end)

	local cd = Instance.new("ClickDetector")
	cd.MaxActivationDistance = 16
	cd.Parent = base
	cd.MouseClick:Connect(function(player)
		openSanctum(player)
	end)

	model.PrimaryPart = base
	model.Parent = workspace
	return true
end

remote.OnServerEvent:Connect(function(player, action, payload)
	if typeof(action) ~= "string" then
		return
	end
	payload = type(payload) == "table" and payload or {}
	local data = playerData(player)
	if not data then
		remote:FireClient(player, "Error", {Error = "no_data"})
		return
	end

	if action == "Open" or action == "RequestOpen" then
		openSanctum(player)
		return
	end

	if action == "PreviewSynthesize" then
		local res = KamiSanctumSystem.PreviewSynthesize(data, payload.SpiritIndices, payload.Components)
		remote:FireClient(player, "PreviewSynthesize", res)
		return
	end

	if action == "Synthesize" then
		local res = KamiSanctumSystem.Synthesize(data, payload.SpiritIndices, payload.Components, Random.new())
		if res.Ok then
			sync(player)
			remote:FireClient(player, "SynthesizeResult", res)
			if _G.UpdateQuestProgress then
				_G.UpdateQuestProgress(player, "KamiSynthesize", {Count = 1})
			end
		else
			remote:FireClient(player, "Error", res)
		end
		return
	end

	if action == "PreviewDisintegrate" then
		local res = KamiSanctumSystem.PreviewDisintegrate(data, payload.SpiritIndex)
		remote:FireClient(player, "PreviewDisintegrate", res)
		return
	end

	if action == "Disintegrate" then
		local res = KamiSanctumSystem.Disintegrate(data, payload.SpiritIndex, Random.new())
		if res.Ok then
			sync(player)
			remote:FireClient(player, "DisintegrateResult", res)
			if _G.UpdateQuestProgress then
				_G.UpdateQuestProgress(player, "KamiDisintegrate", {Count = 1})
			end
		else
			remote:FireClient(player, "Error", res)
		end
		return
	end
end)

-- Studio QA
local bf = Instance.new("BindableFunction")
bf.Name = "KamiSanctumBF"
bf.Parent = sssRealm
bf.OnInvoke = function(userId, action, payload)
	if not game:GetService("RunService"):IsStudio() then
		return false, "studio only"
	end
	local player = Players:GetPlayerByUserId(tonumber(userId) or 0)
	local data = player and playerData(player)
	if not data then
		return false, "no data"
	end
	payload = type(payload) == "table" and payload or {}
	if action == "Synthesize" then
		local res = KamiSanctumSystem.Synthesize(data, payload.SpiritIndices, payload.Components, Random.new())
		if res.Ok and player then
			sync(player)
		end
		return res
	elseif action == "Disintegrate" then
		local res = KamiSanctumSystem.Disintegrate(data, payload.SpiritIndex, Random.new())
		if res.Ok and player then
			sync(player)
		end
		return res
	elseif action == "GrantStars" then
		-- grant starter components for QA
		local inv = data.Inventory or {}
		data.Inventory = inv
		local function add(id, q)
			for _, row in ipairs(inv) do
				if tonumber(row.Id) == id then
					row.Quantity = (row.Quantity or 0) + q
					return
				end
			end
			table.insert(inv, {Id = id, Quantity = q})
		end
		add(301, 5)
		add(310, 2)
		if player then
			sync(player)
		end
		return true
	elseif action == "SeedQA" then
		-- Studio smoke: Lv10 + copper + shards/stars
		data.Level = math.max(tonumber(data.Level) or 0, 10)
		data.CopperCoins = math.max(tonumber(data.CopperCoins) or 0, 250)
		local inv = data.Inventory or {}
		data.Inventory = inv
		local function add(id, q)
			for _, row in ipairs(inv) do
				if tonumber(row.Id) == id then
					row.Quantity = (row.Quantity or 0) + q
					return
				end
			end
			table.insert(inv, {Id = id, Quantity = q})
		end
		add(301, 5)
		add(310, 2)
		if player then
			sync(player)
		end
		return true, data.Level, data.CopperCoins
	end
	return false, "unknown"
end

task.defer(function()
	for _ = 1, 30 do
		if buildShrine() then
			break
		end
		task.wait(1)
	end
end)

print("[KamiSanctum] Service ready")
