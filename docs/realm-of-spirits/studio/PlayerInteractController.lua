-- PlayerInteractController — shared near-player actions (Trade + Duel)
-- Replaces overlapping ProximityPrompts with one panel: buttons side-by-side, desc below.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local RealmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local ZoneConfig = require(RealmFolder:WaitForChild("ZoneConfig"))
local tradeEvent = RealmFolder:WaitForChild("PlayerTrade", 30)
local duelEvent = RealmFolder:WaitForChild("PvPDuel", 30)

local INTERACT_DISTANCE = 22
local ARENA_RADIUS = 130
local ARENA_BBOX_PAD = 30
local HAVEN_BBOX_PAD = 50
local CHALLENGE_FROM_ARENA = 300

local currentTarget = nil
local selectedAction = "Trade" -- Trade | Duel
local guiRoot
local nameLabel
local tradeBtn
local duelBtn
local descLabel

local DESCS = {
	Trade = "Обмен: 1 слот — предмет или косметика (оба в Safe-зоне).",
	Duel = "Дуэль духов: телепорт на плиты арены, бой навыками.",
	TradeOff = "Обмен недоступен: нужна Safe-зона (Haven) у обоих.",
	DuelOff = "Дуэль недоступна: оба должны быть у Haven / дороги / арены.",
	Idle = "Подойдите к игроку, чтобы обменяться или вызвать на дуэль.",
}

local function getHRP(plr)
	local char = plr and plr.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function arenaCenter()
	local arena = workspace:FindFirstChild("BattleArena")
	if arena then
		local ok, cf = pcall(function()
			return arena:GetBoundingBox()
		end)
		if ok and typeof(cf) == "CFrame" then
			return Vector3.new(cf.Position.X, 0, cf.Position.Z)
		end
	end
	local pos = ZoneConfig.BattleArenaPosition
	if typeof(pos) == "Vector3" then
		return pos
	end
	return Vector3.new(236, 0, 40)
end

local function nearArena(plr)
	local hrp = getHRP(plr)
	if not hrp then
		return false
	end
	local arena = workspace:FindFirstChild("BattleArena")
	if arena then
		local cf, size
		local okBox = pcall(function()
			cf, size = arena:GetBoundingBox()
		end)
		if okBox and typeof(cf) == "CFrame" and typeof(size) == "Vector3" then
			local localPos = cf:PointToObjectSpace(hrp.Position)
			if math.abs(localPos.X) <= (size.X * 0.5 + ARENA_BBOX_PAD)
				and math.abs(localPos.Z) <= (size.Z * 0.5 + ARENA_BBOX_PAD) then
				return true
			end
		end
	end
	local c = arenaCenter()
	local flat = Vector3.new(hrp.Position.X - c.X, 0, hrp.Position.Z - c.Z)
	return flat.Magnitude <= ARENA_RADIUS
end

local function nearHaven(plr)
	local hrp = getHRP(plr)
	if not hrp then
		return false
	end
	local haven = workspace:FindFirstChild("OtakuHaven")
	if not haven then
		return false
	end
	local cf, size
	local okBox = pcall(function()
		cf, size = haven:GetBoundingBox()
	end)
	if not okBox or typeof(cf) ~= "CFrame" or typeof(size) ~= "Vector3" then
		return false
	end
	local localPos = cf:PointToObjectSpace(hrp.Position)
	return math.abs(localPos.X) <= (size.X * 0.5 + HAVEN_BBOX_PAD)
		and math.abs(localPos.Z) <= (size.Z * 0.5 + HAVEN_BBOX_PAD)
end

local function inChallengeZone(plr)
	if nearArena(plr) or nearHaven(plr) then
		return true
	end
	local hrp = getHRP(plr)
	if not hrp then
		return false
	end
	local c = arenaCenter()
	local flat = Vector3.new(hrp.Position.X - c.X, 0, hrp.Position.Z - c.Z)
	return flat.Magnitude <= CHALLENGE_FROM_ARENA
end

local function canTradeWith(other)
	return player:GetAttribute("CurrentZone") == "Safe"
		and other:GetAttribute("CurrentZone") == "Safe"
		and not player:GetAttribute("InPlayerTrade")
		and not other:GetAttribute("InPlayerTrade")
end

local function canDuelWith(other)
	return inChallengeZone(player)
		and inChallengeZone(other)
		and not player:GetAttribute("InPvPDuel")
		and not other:GetAttribute("InPvPDuel")
end

local function isBusyLocal()
	if player:GetAttribute("InPvPDuel") or player:GetAttribute("InPlayerTrade") then
		return true
	end
	local pg = player:FindFirstChild("PlayerGui")
	if not pg then
		return false
	end
	local tradeGui = pg:FindFirstChild("PlayerTradeGui")
	if tradeGui and tradeGui.Enabled then
		local panel = tradeGui:FindFirstChild("Panel")
		if panel and panel.Visible then
			return true
		end
	end
	local challenge = pg:FindFirstChild("PvPDuelChallengeGui")
	if challenge and challenge.Enabled then
		return true
	end
	return false
end

local function styleBtn(btn, active, enabled)
	if not enabled then
		btn.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
		btn.TextColor3 = Color3.fromRGB(140, 140, 150)
		btn.BackgroundTransparency = 0.25
		return
	end
	btn.BackgroundTransparency = 0
	btn.TextColor3 = Color3.new(1, 1, 1)
	if active then
		btn.BackgroundColor3 = Color3.fromRGB(70, 120, 200)
	else
		btn.BackgroundColor3 = Color3.fromRGB(40, 48, 70)
	end
end

local function refreshDesc(tradeOk, duelOk)
	if selectedAction == "Trade" then
		descLabel.Text = tradeOk and DESCS.Trade or DESCS.TradeOff
	elseif selectedAction == "Duel" then
		descLabel.Text = duelOk and DESCS.Duel or DESCS.DuelOff
	else
		descLabel.Text = DESCS.Idle
	end
end

local function ensureGui()
	local pg = player:WaitForChild("PlayerGui")
	guiRoot = pg:FindFirstChild("PlayerInteractGui")
	if guiRoot then
		nameLabel = guiRoot.Panel:FindFirstChild("TargetName")
		tradeBtn = guiRoot.Panel:FindFirstChild("TradeBtn")
		duelBtn = guiRoot.Panel:FindFirstChild("DuelBtn")
		descLabel = guiRoot.Panel:FindFirstChild("Desc")
		return guiRoot
	end

	guiRoot = Instance.new("ScreenGui")
	guiRoot.Name = "PlayerInteractGui"
	guiRoot.ResetOnSpawn = false
	guiRoot.DisplayOrder = 480
	guiRoot.IgnoreGuiInset = true
	guiRoot.Enabled = false
	guiRoot.Parent = pg

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Position = UDim2.new(0.5, 0, 1, -28)
	panel.Size = UDim2.new(0, 360, 0, 118)
	panel.BackgroundColor3 = Color3.fromRGB(18, 16, 28)
	panel.BackgroundTransparency = 0.12
	panel.BorderSizePixel = 0
	panel.Parent = guiRoot
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = panel
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(90, 80, 140)
	stroke.Thickness = 1.2
	stroke.Transparency = 0.35
	stroke.Parent = panel

	nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "TargetName"
	nameLabel.BackgroundTransparency = 1
	nameLabel.Position = UDim2.new(0, 14, 0, 8)
	nameLabel.Size = UDim2.new(1, -28, 0, 22)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 16
	nameLabel.TextColor3 = Color3.fromRGB(255, 230, 180)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Text = "Игрок"
	nameLabel.Parent = panel

	tradeBtn = Instance.new("TextButton")
	tradeBtn.Name = "TradeBtn"
	tradeBtn.Size = UDim2.new(0, 156, 0, 40)
	tradeBtn.Position = UDim2.new(0, 14, 0, 36)
	tradeBtn.Font = Enum.Font.GothamBold
	tradeBtn.TextSize = 16
	tradeBtn.Text = "Обмен  [T]"
	tradeBtn.AutoButtonColor = true
	tradeBtn.Parent = panel
	local tc = Instance.new("UICorner")
	tc.CornerRadius = UDim.new(0, 8)
	tc.Parent = tradeBtn

	duelBtn = Instance.new("TextButton")
	duelBtn.Name = "DuelBtn"
	duelBtn.Size = UDim2.new(0, 156, 0, 40)
	duelBtn.Position = UDim2.new(1, -170, 0, 36)
	duelBtn.Font = Enum.Font.GothamBold
	duelBtn.TextSize = 16
	duelBtn.Text = "Дуэль  [Y]"
	duelBtn.AutoButtonColor = true
	duelBtn.Parent = panel
	local dc = Instance.new("UICorner")
	dc.CornerRadius = UDim.new(0, 8)
	dc.Parent = duelBtn

	descLabel = Instance.new("TextLabel")
	descLabel.Name = "Desc"
	descLabel.BackgroundTransparency = 1
	descLabel.Position = UDim2.new(0, 14, 0, 82)
	descLabel.Size = UDim2.new(1, -28, 0, 28)
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 13
	descLabel.TextWrapped = true
	descLabel.TextColor3 = Color3.fromRGB(190, 200, 220)
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Text = DESCS.Idle
	descLabel.Parent = panel

	tradeBtn.MouseEnter:Connect(function()
		selectedAction = "Trade"
		if currentTarget then
			refreshDesc(canTradeWith(currentTarget), canDuelWith(currentTarget))
			styleBtn(tradeBtn, true, canTradeWith(currentTarget))
			styleBtn(duelBtn, false, canDuelWith(currentTarget))
		end
	end)
	duelBtn.MouseEnter:Connect(function()
		selectedAction = "Duel"
		if currentTarget then
			refreshDesc(canTradeWith(currentTarget), canDuelWith(currentTarget))
			styleBtn(tradeBtn, false, canTradeWith(currentTarget))
			styleBtn(duelBtn, true, canDuelWith(currentTarget))
		end
	end)

	tradeBtn.MouseButton1Click:Connect(function()
		if not currentTarget or not canTradeWith(currentTarget) or not tradeEvent then
			return
		end
		tradeEvent:FireServer("Request", { TargetUserId = currentTarget.UserId })
	end)
	duelBtn.MouseButton1Click:Connect(function()
		if not currentTarget or not canDuelWith(currentTarget) or not duelEvent then
			return
		end
		duelEvent:FireServer("Request", { TargetUserId = currentTarget.UserId })
	end)

	return guiRoot
end

local function hidePanel()
	currentTarget = nil
	if guiRoot then
		guiRoot.Enabled = false
	end
end

local function showFor(other)
	ensureGui()
	currentTarget = other
	local tradeOk = canTradeWith(other)
	local duelOk = canDuelWith(other)
	if not tradeOk and not duelOk then
		hidePanel()
		return
	end
	if selectedAction == "Trade" and not tradeOk and duelOk then
		selectedAction = "Duel"
	elseif selectedAction == "Duel" and not duelOk and tradeOk then
		selectedAction = "Trade"
	end
	nameLabel.Text = "С " .. (other.DisplayName or other.Name)
	styleBtn(tradeBtn, selectedAction == "Trade", tradeOk)
	styleBtn(duelBtn, selectedAction == "Duel", duelOk)
	refreshDesc(tradeOk, duelOk)
	guiRoot.Enabled = true
end

local function findNearest()
	local myHrp = getHRP(player)
	if not myHrp then
		return nil
	end
	local best, bestDist = nil, INTERACT_DISTANCE
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			local hrp = getHRP(other)
			if hrp then
				local d = (hrp.Position - myHrp.Position).Magnitude
				if d <= bestDist then
					bestDist = d
					best = other
				end
			end
		end
	end
	return best
end

ensureGui()

RunService.Heartbeat:Connect(function()
	if isBusyLocal() then
		hidePanel()
		return
	end
	local other = findNearest()
	if other then
		showFor(other)
	else
		hidePanel()
	end
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp or not currentTarget or not guiRoot or not guiRoot.Enabled then
		return
	end
	if input.KeyCode == Enum.KeyCode.T then
		if canTradeWith(currentTarget) and tradeEvent then
			tradeEvent:FireServer("Request", { TargetUserId = currentTarget.UserId })
		end
	elseif input.KeyCode == Enum.KeyCode.Y then
		if canDuelWith(currentTarget) and duelEvent then
			duelEvent:FireServer("Request", { TargetUserId = currentTarget.UserId })
		end
	end
end)

print("Realm of Spirits - PlayerInteractController loaded!")
