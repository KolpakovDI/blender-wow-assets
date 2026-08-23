-- PvPDuelController — Arena challenge prompt + accept UI (fair duel slice)
-- Combat is spirit-vs-spirit via battle UI; characters stay on pads.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local RealmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local ZoneConfig = require(RealmFolder:WaitForChild("ZoneConfig"))
local duelEvent = RealmFolder:WaitForChild("PvPDuel", 30)
if not duelEvent then
	warn("[PvPDuelController] RemoteEvent PvPDuel missing")
	return
end
local battleEvent = RealmFolder:FindFirstChild("Battle")

local ARENA_RADIUS = 130
local ARENA_BBOX_PAD = 30
local HAVEN_BBOX_PAD = 50
local CHALLENGE_FROM_ARENA = 300 -- Haven ~257 from arena

local inDuel = false
local incomingFrom = nil
local challengeGui
local duelHudGui
local rematchCountdownGen = 0

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

local function getHRP(plr)
	local char = plr.Character
	return char and char:FindFirstChild("HumanoidRootPart")
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

local function showToast(text)
	if not text or text == "" then
		return
	end
	local pg = player:WaitForChild("PlayerGui")
	local gui = pg:FindFirstChild("PvPDuelToastGui")
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "PvPDuelToastGui"
		gui.ResetOnSpawn = false
		gui.DisplayOrder = 510
		gui.IgnoreGuiInset = true
		gui.Parent = pg
	end
	local label = gui:FindFirstChild("Toast")
	if not label then
		label = Instance.new("TextLabel")
		label.Name = "Toast"
		label.AnchorPoint = Vector2.new(0.5, 0)
		label.Position = UDim2.new(0.5, 0, 0.18, 0)
		label.Size = UDim2.new(0, 520, 0, 52)
		label.BackgroundColor3 = Color3.fromRGB(28, 22, 40)
		label.BackgroundTransparency = 0.08
		label.Font = Enum.Font.GothamBold
		label.TextSize = 17
		label.TextWrapped = true
		label.TextColor3 = Color3.fromRGB(255, 230, 200)
		label.Parent = gui
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 8)
		c.Parent = label
	end
	label.Text = text
	label.Visible = true
	task.delay(5, function()
		if label.Parent and label.Text == text then
			label.Visible = false
		end
	end)
end

local function hideChallengeGui()
	if challengeGui then
		challengeGui.Enabled = false
	end
	incomingFrom = nil
end

local function hideDuelHud()
	if duelHudGui then
		duelHudGui.Enabled = false
	end
end

local function clearDuelFlags()
	inDuel = false
	hideDuelHud()
end

local function showDuelHud(opponentName, mySpirit, foeSpirit)
	local pg = player:WaitForChild("PlayerGui")
	duelHudGui = pg:FindFirstChild("PvPDuelHudGui")
	if not duelHudGui then
		duelHudGui = Instance.new("ScreenGui")
		duelHudGui.Name = "PvPDuelHudGui"
		duelHudGui.ResetOnSpawn = false
		duelHudGui.DisplayOrder = 530
		duelHudGui.IgnoreGuiInset = true
		duelHudGui.Parent = pg

		local bar = Instance.new("Frame")
		bar.Name = "Bar"
		bar.AnchorPoint = Vector2.new(0.5, 0)
		bar.Position = UDim2.new(0.5, 0, 0.04, 0)
		bar.Size = UDim2.new(0, 520, 0, 64)
		bar.BackgroundColor3 = Color3.fromRGB(18, 12, 28)
		bar.BackgroundTransparency = 0.08
		bar.Parent = duelHudGui
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 10)
		c.Parent = bar

		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.Size = UDim2.new(1, -20, 0, 28)
		title.Position = UDim2.new(0, 10, 0, 4)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBold
		title.TextSize = 20
		title.TextColor3 = Color3.fromRGB(255, 220, 140)
		title.Text = "ДУЭЛЬ ДУХОВ"
		title.Parent = bar

		local sub = Instance.new("TextLabel")
		sub.Name = "Sub"
		sub.Size = UDim2.new(1, -20, 0, 24)
		sub.Position = UDim2.new(0, 10, 0, 34)
		sub.BackgroundTransparency = 1
		sub.Font = Enum.Font.Gotham
		sub.TextSize = 14
		sub.TextColor3 = Color3.fromRGB(200, 220, 240)
		sub.Text = "жмите навыки внизу — персонажи на плитах"
		sub.Parent = bar
	end
	local bar = duelHudGui:FindFirstChild("Bar")
	local title = bar and bar:FindFirstChild("Title")
	local sub = bar and bar:FindFirstChild("Sub")
	if title then
		title.Text = "ДУЭЛЬ ДУХОВ · " .. tostring(opponentName or "")
	end
	if sub then
		local myS = mySpirit or "?"
		local foeS = foeSpirit or "?"
		sub.Text = myS .. "  vs  " .. foeS .. "  —  жмите навыки внизу, персонажи на плитах"
	end
	duelHudGui.Enabled = true
end

local function ensureChallengeGui()
	if challengeGui and challengeGui.Parent then
		return challengeGui
	end
	local pg = player:WaitForChild("PlayerGui")
	challengeGui = pg:FindFirstChild("PvPDuelChallengeGui")
	if not challengeGui then
		challengeGui = Instance.new("ScreenGui")
		challengeGui.Name = "PvPDuelChallengeGui"
		challengeGui.ResetOnSpawn = false
		challengeGui.DisplayOrder = 520
		challengeGui.IgnoreGuiInset = true
		challengeGui.Parent = pg
	end
	local frame = challengeGui:FindFirstChild("Panel")
	if not frame then
		frame = Instance.new("Frame")
		frame.Name = "Panel"
		frame.AnchorPoint = Vector2.new(0.5, 0.5)
		frame.Position = UDim2.new(0.5, 0, 0.42, 0)
		frame.Size = UDim2.new(0, 360, 0, 140)
		frame.BackgroundColor3 = Color3.fromRGB(24, 18, 34)
		frame.BackgroundTransparency = 0.05
		frame.Parent = challengeGui
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = frame

		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.Size = UDim2.new(1, -24, 0, 28)
		title.Position = UDim2.new(0, 12, 0, 12)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBold
		title.TextSize = 18
		title.TextColor3 = Color3.fromRGB(255, 220, 160)
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Text = "Вызов на дуэль"
		title.Parent = frame

		local body = Instance.new("TextLabel")
		body.Name = "Body"
		body.Size = UDim2.new(1, -24, 0, 40)
		body.Position = UDim2.new(0, 12, 0, 44)
		body.BackgroundTransparency = 1
		body.Font = Enum.Font.Gotham
		body.TextSize = 15
		body.TextWrapped = true
		body.TextColor3 = Color3.fromRGB(220, 230, 245)
		body.TextXAlignment = Enum.TextXAlignment.Left
		body.Text = ""
		body.Parent = frame

		local accept = Instance.new("TextButton")
		accept.Name = "Accept"
		accept.Size = UDim2.new(0, 140, 0, 36)
		accept.Position = UDim2.new(0, 12, 1, -48)
		accept.BackgroundColor3 = Color3.fromRGB(50, 140, 90)
		accept.Font = Enum.Font.GothamBold
		accept.TextSize = 16
		accept.TextColor3 = Color3.new(1, 1, 1)
		accept.Text = "Принять"
		accept.Parent = frame
		local ac = Instance.new("UICorner")
		ac.CornerRadius = UDim.new(0, 8)
		ac.Parent = accept

		local decline = Instance.new("TextButton")
		decline.Name = "Decline"
		decline.Size = UDim2.new(0, 140, 0, 36)
		decline.Position = UDim2.new(1, -152, 1, -48)
		decline.BackgroundColor3 = Color3.fromRGB(140, 55, 55)
		decline.Font = Enum.Font.GothamBold
		decline.TextSize = 16
		decline.TextColor3 = Color3.new(1, 1, 1)
		decline.Text = "Отклонить"
		decline.Parent = frame
		local dc = Instance.new("UICorner")
		dc.CornerRadius = UDim.new(0, 8)
		dc.Parent = decline

		accept.MouseButton1Click:Connect(function()
			local mode = challengeGui:GetAttribute("Mode") or "Challenge"
			if mode == "Rematch" then
				duelEvent:FireServer("RematchAccept", {})
			else
				duelEvent:FireServer("Accept", {})
			end
			hideChallengeGui()
		end)
		decline.MouseButton1Click:Connect(function()
			local mode = challengeGui:GetAttribute("Mode") or "Challenge"
			if mode == "Rematch" then
				duelEvent:FireServer("RematchDecline", {})
			else
				duelEvent:FireServer("Decline", {})
			end
			hideChallengeGui()
		end)
	end
	return challengeGui
end

local function showIncoming(fromName)
	local gui = ensureChallengeGui()
	gui:SetAttribute("Mode", "Challenge")
	gui.Enabled = true
	local panel = gui:FindFirstChild("Panel")
	local title = panel and panel:FindFirstChild("Title")
	local body = panel and panel:FindFirstChild("Body")
	local accept = panel and panel:FindFirstChild("Accept")
	local decline = panel and panel:FindFirstChild("Decline")
	if title then
		title.Text = "Вызов на дуэль"
	end
	if body then
		body.Text = (fromName or "Игрок") .. " вызывает вас на честную дуэль духов (бой на арене)."
	end
	if accept then
		accept.Text = "Принять"
	end
	if decline then
		decline.Text = "Отклонить"
	end
	showToast("Входящий вызов на дуэль!")
end

local function stopRematchCountdown()
	rematchCountdownGen += 1
end

local function showRematchOffer(fromName, seconds, wins, losses)
	stopRematchCountdown()
	local ttl = math.max(1, math.floor(tonumber(seconds) or 20))
	local gen = rematchCountdownGen
	local expiresAt = tick() + ttl
	local gui = ensureChallengeGui()
	gui:SetAttribute("Mode", "Rematch")
	gui.Enabled = true
	local panel = gui:FindFirstChild("Panel")
	local title = panel and panel:FindFirstChild("Title")
	local body = panel and panel:FindFirstChild("Body")
	local accept = panel and panel:FindFirstChild("Accept")
	local decline = panel and panel:FindFirstChild("Decline")
	if title then
		title.Text = "Реванш?"
	end
	local function refreshBody(leftSec)
		if not body then
			return
		end
		body.Text = string.format(
			"Ещё раунд с %s?\nСчёт сессии: %dW / %dL · осталось %dс\nОтказ — возврат на точку вызова.",
			tostring(fromName or "соперником"),
			math.max(0, math.floor(tonumber(wins) or 0)),
			math.max(0, math.floor(tonumber(losses) or 0)),
			math.max(0, leftSec)
		)
	end
	refreshBody(ttl)
	if accept then
		accept.Text = "Реванш"
	end
	if decline then
		decline.Text = "Уйти"
	end
	showToast("Реванш? «Реванш» или «Уйти» — " .. ttl .. "с")
	task.spawn(function()
		while gen == rematchCountdownGen and gui.Enabled and gui:GetAttribute("Mode") == "Rematch" do
			local left = math.ceil(expiresAt - tick())
			if left <= 0 then
				break
			end
			refreshBody(left)
			task.wait(1)
		end
	end)
end

duelEvent.OnClientEvent:Connect(function(action, data)
	data = data or {}
	if action == "Toast" then
		showToast(data.Message)
	elseif action == "ChallengeSent" then
		showToast("Вызов отправлен: " .. tostring(data.TargetName or ""))
	elseif action == "ChallengeIncoming" then
		incomingFrom = data.FromUserId
		showIncoming(data.FromName)
	elseif action == "ChallengeDeclined" or action == "ChallengeCancelled" then
		hideChallengeGui()
		showToast(action == "ChallengeDeclined" and "Вызов отклонён" or "Вызов отменён")
	elseif action == "DuelStart" then
		inDuel = true
		hideChallengeGui()
		player:SetAttribute("BattleEngaged", tick())
		showDuelHud(data.OpponentName, data.SpiritName, data.EnemySpiritName)
		showToast("ДУЭЛЬ ДУХОВ vs " .. tostring(data.OpponentName or "соперник"))
		if data.Hint then
			task.delay(1.2, function()
				showToast(tostring(data.Hint))
			end)
		end
	elseif action == "DuelEnd" then
		clearDuelFlags()
	elseif action == "RematchOffer" then
		clearDuelFlags()
		showRematchOffer(data.OpponentName, data.Seconds, data.Wins, data.Losses)
	elseif action == "RematchWaiting" then
		hideChallengeGui()
		showToast("Ждём ответа соперника...")
	elseif action == "RematchClosed" or action == "ReturnedHome" then
		stopRematchCountdown()
		hideChallengeGui()
		clearDuelFlags()
	end
end)

player:GetAttributeChangedSignal("InPvPDuel"):Connect(function()
	if not player:GetAttribute("InPvPDuel") then
		clearDuelFlags()
	end
end)

if battleEvent then
	battleEvent.OnClientEvent:Connect(function(action)
		if action == "End" or action == "Flee" then
			clearDuelFlags()
		end
	end)
end

ensureChallengeGui()
hideChallengeGui()
print("Realm of Spirits - PvPDuelController loaded!")
