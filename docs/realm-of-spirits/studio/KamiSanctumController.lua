-- KamiSanctumController — client UI for synthesize / disintegrate
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local realm = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local remote = realm:WaitForChild("KamiSanctum")
local ItemCatalog = require(realm:WaitForChild("ItemCatalog"))
local SpiritMeshResolve = require(realm:WaitForChild("SpiritMeshResolve"))

local PlayerData = nil
local function formatKamiError(data)
	data = type(data) == "table" and data or {}
	local err = tostring(data.Error or data.Message or "unknown")
	if err == "copper" then
		local need = tonumber(data.Need) or 0
		local have = tonumber(data.Have)
		if have then
			return string.format("Недостаточно монет: нужно %d меди (есть %d)", need, have)
		end
		return string.format("Недостаточно монет: нужно %d меди (считаются медь+серебро+золото)", need)
	elseif err == "need_shard" then
		return "Нужен Осколок Ками (предмет #301)"
	elseif err == "level" then
		return "Нужен уровень " .. tostring(data.Need or "?")
	elseif err == "count" then
		return string.format("Выберите от %d до %d духов", data.Min or 2, data.Max or 6)
	elseif err == "daily_cap" then
		return "Дневной лимит слияний исчерпан (" .. tostring(data.Cap or "?") .. ")"
	elseif err == "last_spirit" then
		return "Нельзя разобрать последнего духа"
	elseif err == "too_far" then
		return "Подойдите ближе к святилищу"
	end
	return err
end
local selected = {} -- indices for synth
local disIndex = nil
local gui = nil

local function notify(text)
	local trMod = realm:FindFirstChild("ToastRouter")
	if trMod then
		local ok, tr = pcall(require, trMod)
		if ok and tr and tr.Reward then
			tr.Reward(tostring(text), 4.5)
			return
		end
	end
	local fb = realm:FindFirstChild("UIFeedback")
	if fb then
		local ok, mod = pcall(require, fb)
		if ok and mod and mod.Toast then
			mod.Toast(text)
			return
		end
	end
	print("[KamiSanctum]", text)
end

local function showLookMesh(spiritOrId)
	if not (gui and gui.Parent) then
		return
	end
	local main = gui:FindFirstChild("Main")
	local vp = main and main:FindFirstChild("LookPreview")
	if not vp then
		return
	end
	for _, ch in ipairs(vp:GetChildren()) do
		if ch:IsA("WorldModel") or ch:IsA("Model") then
			ch:Destroy()
		end
	end
	local world = Instance.new("WorldModel")
	world.Name = "World"
	world.Parent = vp
	local clone = SpiritMeshResolve.CloneResolvedModel(spiritOrId, "Look")
	if clone then
		clone.Parent = world
	end
	local cam = vp:FindFirstChildOfClass("Camera")
	if not cam then
		cam = Instance.new("Camera")
		cam.Name = "LookCam"
		cam.Parent = vp
		vp.CurrentCamera = cam
	end
	local cf, size = CFrame.new(), Vector3.new(2, 2, 2)
	if clone and clone:IsA("Model") then
		cf, size = clone:GetBoundingBox()
	end
	local dist = math.max(size.X, size.Y, size.Z) * 1.8 + 1
	cam.CFrame = CFrame.new(cf.Position + Vector3.new(dist * 0.7, dist * 0.35, dist * 0.7), cf.Position)
	vp.Visible = true
	local cap = main:FindFirstChild("LookCaption")
	if cap then
		cap.Visible = true
	end
end

local function rebuildList(scroll, onPick)
	for _, c in ipairs(scroll:GetChildren()) do
		if c:IsA("TextButton") then
			c:Destroy()
		end
	end
	local spirits = (PlayerData and PlayerData.Spirits) or {}
	local y = 0
	for i, sp in ipairs(spirits) do
		local btn = Instance.new("TextButton")
		btn.Name = "Spirit_" .. i
		btn.Size = UDim2.new(1, -8, 0, 36)
		btn.Position = UDim2.new(0, 4, 0, y)
		btn.BackgroundColor3 = Color3.fromRGB(40, 32, 56)
		btn.TextColor3 = Color3.fromRGB(240, 230, 255)
		btn.Font = Enum.Font.Gotham
		btn.TextSize = 14
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.TextTruncate = Enum.TextTruncate.AtEnd
		local mark = ""
		if mode == "Synthesize" and table.find(selected, i) then
			mark = "✓ "
			btn.BackgroundColor3 = Color3.fromRGB(70, 48, 100)
		elseif mode == "Disintegrate" and disIndex == i then
			mark = "✓ "
			btn.BackgroundColor3 = Color3.fromRGB(100, 40, 50)
		end
		local kindTag = (tostring(sp.Kind) == "Resonant") and "[R] " or ""
		btn.Text = string.format("  %s%s%d. %s  Lv%d", mark, kindTag, i, tostring(sp.Name or "?"), tonumber(sp.Level) or 1)
		btn.Parent = scroll
		btn.MouseButton1Click:Connect(function()
			onPick(i)
		end)
		y += 40
	end
	scroll.CanvasSize = UDim2.new(0, 0, 0, y + 8)
end

local function ensureGui()
	if gui and gui.Parent then
		return gui
	end
	gui = Instance.new("ScreenGui")
	gui.Name = "KamiSanctumGui"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "Main"
	frame.Size = UDim2.fromOffset(440, 480)
	frame.Position = UDim2.new(0.5, -220, 0.5, -240)
	frame.BackgroundColor3 = Color3.fromRGB(24, 18, 36)
	frame.BorderSizePixel = 0
	frame.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -80, 0, 36)
	title.Position = UDim2.fromOffset(12, 8)
	title.BackgroundTransparency = 1
	title.Text = "Святилище Ками"
	title.TextColor3 = Color3.fromRGB(230, 200, 255)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 22
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = frame

	local close = Instance.new("TextButton")
	close.Name = "Close"
	close.Size = UDim2.fromOffset(36, 36)
	close.Position = UDim2.new(1, -44, 0, 8)
	close.BackgroundColor3 = Color3.fromRGB(60, 40, 50)
	close.Text = "X"
	close.TextColor3 = Color3.new(1, 1, 1)
	close.Font = Enum.Font.GothamBold
	close.Parent = frame
	close.MouseButton1Click:Connect(function()
		gui.Enabled = false
	end)

	local tabSynth = Instance.new("TextButton")
	tabSynth.Name = "TabSynth"
	tabSynth.Size = UDim2.fromOffset(140, 28)
	tabSynth.Position = UDim2.fromOffset(12, 48)
	tabSynth.Text = "Синтез (2–6)"
	tabSynth.Font = Enum.Font.GothamBold
	tabSynth.TextSize = 13
	tabSynth.BackgroundColor3 = Color3.fromRGB(90, 60, 130)
	tabSynth.TextColor3 = Color3.new(1, 1, 1)
	tabSynth.Parent = frame

	local tabDis = Instance.new("TextButton")
	tabDis.Name = "TabDis"
	tabDis.Size = UDim2.fromOffset(160, 28)
	tabDis.Position = UDim2.fromOffset(160, 48)
	tabDis.Text = "Дезинтеграция"
	tabDis.Font = Enum.Font.GothamBold
	tabDis.TextSize = 13
	tabDis.BackgroundColor3 = Color3.fromRGB(50, 40, 60)
	tabDis.TextColor3 = Color3.new(1, 1, 1)
	tabDis.Parent = frame

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "SpiritList"
	scroll.Size = UDim2.new(1, -120, 0, 200)
	scroll.Position = UDim2.fromOffset(12, 88)
	scroll.BackgroundColor3 = Color3.fromRGB(16, 12, 28)
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.ClipsDescendants = true
	scroll.Parent = frame

	local lookVp = Instance.new("ViewportFrame")
	lookVp.Name = "LookPreview"
	lookVp.Size = UDim2.fromOffset(88, 88)
	lookVp.Position = UDim2.new(1, -100, 0, 88)
	lookVp.BackgroundColor3 = Color3.fromRGB(16, 12, 28)
	lookVp.BorderSizePixel = 0
	lookVp.Visible = false
	lookVp.Parent = frame
	local lookCorner = Instance.new("UICorner")
	lookCorner.CornerRadius = UDim.new(0, 8)
	lookCorner.Parent = lookVp
	local lookCam = Instance.new("Camera")
	lookCam.Name = "LookCam"
	lookCam.Parent = lookVp
	lookVp.CurrentCamera = lookCam

	local lookCap = Instance.new("TextLabel")
	lookCap.Name = "LookCaption"
	lookCap.Size = UDim2.fromOffset(88, 20)
	lookCap.Position = UDim2.new(1, -100, 0, 180)
	lookCap.BackgroundTransparency = 1
	lookCap.Text = "LOOK"
	lookCap.TextColor3 = Color3.fromRGB(170, 150, 200)
	lookCap.Font = Enum.Font.Gotham
	lookCap.TextSize = 11
	lookCap.Visible = false
	lookCap.Parent = frame

	local hint = Instance.new("TextLabel")
	hint.Name = "Hint"
	hint.Size = UDim2.new(1, -24, 0, 72)
	hint.Position = UDim2.fromOffset(12, 298)
	hint.BackgroundTransparency = 1
	hint.Text = "Выберите 2–6 духов. Нужен Осколок Ками (301). Звёзды трансформации усиливают Unique."
	hint.TextColor3 = Color3.fromRGB(190, 180, 210)
	hint.Font = Enum.Font.Gotham
	hint.TextSize = 13
	hint.TextWrapped = true
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.TextYAlignment = Enum.TextYAlignment.Top
	hint.Parent = frame

	local previewBtn = Instance.new("TextButton")
	previewBtn.Name = "Preview"
	previewBtn.Size = UDim2.new(0.48, -8, 0, 40)
	previewBtn.Position = UDim2.fromOffset(12, 380)
	previewBtn.BackgroundColor3 = Color3.fromRGB(60, 80, 120)
	previewBtn.Text = "Превью"
	previewBtn.TextColor3 = Color3.new(1, 1, 1)
	previewBtn.Font = Enum.Font.GothamBold
	previewBtn.Parent = frame

	local goBtn = Instance.new("TextButton")
	goBtn.Name = "Go"
	goBtn.Size = UDim2.new(0.48, -8, 0, 40)
	goBtn.Position = UDim2.new(0.52, 0, 0, 380)
	goBtn.BackgroundColor3 = Color3.fromRGB(120, 70, 160)
	goBtn.Text = "Слить"
	goBtn.TextColor3 = Color3.new(1, 1, 1)
	goBtn.Font = Enum.Font.GothamBold
	goBtn.Parent = frame

	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Size = UDim2.new(1, -24, 0, 40)
	status.Position = UDim2.fromOffset(12, 428)
	status.BackgroundTransparency = 1
	status.Text = ""
	status.TextColor3 = Color3.fromRGB(180, 255, 200)
	status.Font = Enum.Font.Gotham
	status.TextSize = 13
	status.TextWrapped = true
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.TextTruncate = Enum.TextTruncate.AtEnd
	status.Parent = frame

	local function refresh()
		rebuildList(scroll, function(i)
			if mode == "Synthesize" then
				local at = table.find(selected, i)
				if at then
					table.remove(selected, at)
				else
					if #selected >= 6 then
						notify("Максимум 6 духов")
						return
					end
					table.insert(selected, i)
				end
			else
				disIndex = i
			end
			refresh()
		end)
	end

	tabSynth.MouseButton1Click:Connect(function()
		mode = "Synthesize"
		tabSynth.BackgroundColor3 = Color3.fromRGB(90, 60, 130)
		tabDis.BackgroundColor3 = Color3.fromRGB(50, 40, 60)
		goBtn.Text = "Слить"
		hint.Text = "Выберите 2–6 духов. Нужен Осколок Ками. Звёзды трансформации усиливают Unique."
		refresh()
	end)
	tabDis.MouseButton1Click:Connect(function()
		mode = "Disintegrate"
		tabDis.BackgroundColor3 = Color3.fromRGB(120, 50, 60)
		tabSynth.BackgroundColor3 = Color3.fromRGB(50, 40, 60)
		goBtn.Text = "Разобрать"
		hint.Text = "Выберите одного духа. Получите осколки / Звёзды / эссенции. Нельзя разобрать последнего."
		refresh()
	end)

	previewBtn.MouseButton1Click:Connect(function()
		if mode == "Synthesize" then
			remote:FireServer("PreviewSynthesize", {
				SpiritIndices = selected,
				Components = {[301] = 1, [310] = 0},
			})
		else
			remote:FireServer("PreviewDisintegrate", {SpiritIndex = disIndex})
		end
	end)

	goBtn.MouseButton1Click:Connect(function()
		if mode == "Synthesize" then
			if #selected < 2 then
				notify("Нужно минимум 2 духа")
				return
			end
			remote:FireServer("Synthesize", {
				SpiritIndices = selected,
				Components = {[301] = 1},
			})
		else
			if not disIndex then
				notify("Выберите духа")
				return
			end
			remote:FireServer("Disintegrate", {SpiritIndex = disIndex})
		end
	end)

	gui:SetAttribute("Refresh", true)
	gui.AncestryChanged:Connect(function() end)
	-- store refresh
	gui:SetAttribute("_ready", true)
	rawset(_G, "__KamiSanctumRefresh", refresh)
	refresh()
	return gui
end

local function openUi()
	local g = ensureGui()
	g.Enabled = true
	if _G.__KamiSanctumRefresh then
		_G.__KamiSanctumRefresh()
	end
end

-- Sync player data from DataSync
local dataSync = realm:WaitForChild("DataSync")
dataSync.OnClientEvent:Connect(function(action, data)
	if action == "FullSync" and type(data) == "table" then
		PlayerData = data
		if gui and gui.Enabled and _G.__KamiSanctumRefresh then
			_G.__KamiSanctumRefresh()
		end
	end
end)

-- Also try UIController PlayerData if exposed later
task.spawn(function()
	for _ = 1, 20 do
		if _G.RoS_PlayerData then
			PlayerData = _G.RoS_PlayerData
			break
		end
		task.wait(0.5)
	end
end)

remote.OnClientEvent:Connect(function(action, data)
	data = type(data) == "table" and data or {}
	if action == "Open" then
		openUi()
		do
			local g = ensureGui()
			if g and g:FindFirstChild("Main") and g.Main:FindFirstChild("Status") then
				-- Clear sticky Error (e.g. too_far) after successful Open
				g.Main.Status.Text = "Выберите 2–6 духов · Осколок Ками (301)"
			end
		end
	elseif action == "PreviewSynthesize" then
		local g = ensureGui()
		local st = g.Main.Status
		if data.Ok then
			st.Text = string.format(
				"Сила %.2f · Unique ~%d%% · тир %s · медь %d · осталось %d",
				data.ResonancePower or 0,
				math.floor((data.UniqueChance or 0) * 100),
				tostring(data.TierHint),
				data.CopperCost or 0,
				data.DailyLeft or 0
			)
			st.Text = st.Text .. " | vid " .. tostring(data.CoreParentName or data.NameHint or "-")
			showLookMesh({ Id = data.CoreParentId, Name = data.CoreParentName, ParentIds = { data.CoreParentId } })
		else
			st.Text = "Превью: " .. formatKamiError(data)
		end
	elseif action == "PreviewDisintegrate" then
		local g = ensureGui()
		local st = g.Main.Status
		if data.Ok then
			local names = {}
			for _, row in ipairs(data.LootTable or {}) do
				table.insert(names, string.format("%s×%d", row.Name, row.Quantity))
			end
			st.Text = "Возможный лут: " .. table.concat(names, ", ")
		else
			st.Text = "Превью: " .. formatKamiError(data)
		end
	elseif action == "SynthesizeResult" then
		selected = {}
		local sp = data.Spirit
		local skills = {}
		if type(sp) == "table" then
			local names = type(sp.Skills) == "table" and sp.Skills or {}
			for i = 1, 3 do
				local tag = names[i]
				if tag == nil and type(sp.SkillIds) == "table" then
					tag = "#" .. tostring(sp.SkillIds[i] or i)
				end
				if tag then
					tag = tostring(tag)
					if i == 1 then
						tag = tag .. " *"
					end
					table.insert(skills, tag)
				end
			end
		end
		local look = ""
		if type(sp) == "table" and type(sp.ParentIds) == "table" and sp.ParentIds[1] then
			look = " vid #" .. tostring(sp.ParentIds[1])
		end
		local toastName = tostring(sp and sp.Name or "Ками")
		notify(toastName .. (skills[1] and (" | " .. skills[1]) or ""))
		local g = ensureGui()
		local skillLine = (#skills > 0) and table.concat(skills, " | ") or "-"
		g.Main.Status.Text = toastName .. look .. " | " .. skillLine
		showLookMesh(sp)
		if _G.__KamiSanctumRefresh then
			_G.__KamiSanctumRefresh()
		end
	elseif action == "DisintegrateResult" then
		disIndex = nil
		local parts = {}
		for _, g in ipairs(data.Granted or {}) do
			local item = ItemCatalog.Get(g.Id)
			table.insert(parts, string.format("%s×%d", item and item.Name or g.Id, g.Quantity))
		end
		notify("Дезинтеграция: " .. table.concat(parts, ", "))
		local g = ensureGui()
		g.Main.Status.Text = "Получено: " .. table.concat(parts, ", ") .. " +" .. tostring(data.CopperGain) .. "c"
		if _G.__KamiSanctumRefresh then
			_G.__KamiSanctumRefresh()
		end
	elseif action == "Error" then
		local msg = formatKamiError(data)
		notify("Ошибка: " .. msg)
		local g = ensureGui()
		if g and g:FindFirstChild("Main") and g.Main:FindFirstChild("Status") then
			g.Main.Status.Text = "Ошибка: " .. msg
		end
	end
end)

print("[KamiSanctum] Controller ready")
