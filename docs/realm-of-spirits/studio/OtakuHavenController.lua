-- OtakuHavenController
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local RealmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local havenEvent = RealmFolder:WaitForChild("OtakuHaven")
local tradeEvent = RealmFolder:WaitForChild("Trade")
local function getMainGui()
	return player:WaitForChild("PlayerGui"):FindFirstChild("RealmOfSpiritsUI")
end
local function showToast(text, color)
	local zoneGui = player.PlayerGui:FindFirstChild("ZoneUI")
	local toast = zoneGui and zoneGui:FindFirstChild("ZoneToast", true)
	if toast then
		toast.Text = text
		toast.TextColor3 = color or Color3.fromRGB(200, 255, 220)
		toast.Visible = true
		task.delay(3, function() if toast.Text == text then toast.Visible = false end end)
	else print("[OtakuHaven]", text) end
end
local function openTradePanel()
	local gui = getMainGui(); if not gui then return end
	local tradeFrame = gui:FindFirstChild("TradeFrame")
	if tradeFrame then tradeFrame.Visible = true; tradeEvent:FireServer("GetShop", {}) end
end
local pg = player:WaitForChild("PlayerGui")
local buffGui = Instance.new("ScreenGui")
buffGui.Name = "BuffTimerGui"
buffGui.ResetOnSpawn = false
buffGui.DisplayOrder = 20
buffGui.Parent = pg
local buffLabel = Instance.new("TextLabel")
buffLabel.Name = "BuffTimer"
buffLabel.AnchorPoint = Vector2.new(1, 0)
buffLabel.Position = UDim2.new(1, -12, 0, 52)
buffLabel.Size = UDim2.new(0, 240, 0, 32)
buffLabel.BackgroundColor3 = Color3.fromRGB(40, 30, 55)
buffLabel.BackgroundTransparency = 0.15
buffLabel.TextColor3 = Color3.fromRGB(255, 200, 120)
buffLabel.TextSize = 15
buffLabel.Font = Enum.Font.GothamBold
buffLabel.Visible = false
buffLabel.Parent = buffGui
local buffCorner = Instance.new("UICorner"); buffCorner.CornerRadius = UDim.new(0, 6); buffCorner.Parent = buffLabel
local function updateBuffLabel(payload)
	if not payload or not payload.Name then buffLabel.Visible = false; return end
	buffLabel.Visible = true
	task.spawn(function()
		local left = payload.Duration or 1800
		while left > 0 and buffLabel.Visible do
			buffLabel.Text = string.format("%s +15%% (%d:%02d)", payload.Name, math.floor(left/60), left%60)
			task.wait(1); left = left - 1
		end
		if left <= 0 then buffLabel.Visible = false end
	end)
end
local function formatFomo(seconds)
	seconds = math.max(0, math.floor(seconds or 0))
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = seconds % 60
	return string.format("%d:%02d:%02d", h, m, s)
end

local function updateWorldFomoLabel(secondsLeft)
	local haven = workspace:FindFirstChild("OtakuHaven")
	local gacha = haven and haven:FindFirstChild("GachaMachine", true)
	local label = gacha and gacha:FindFirstChild("FomoLabel", true)
	if label then
		if secondsLeft <= 0 then
			label.Text = "Коллекция закрыта"
		else
			label.Text = "Лимит: " .. formatFomo(secondsLeft)
		end
	end
end

havenEvent.OnClientEvent:Connect(function(action, data)
	data = data or {}
	if action == "OpenTrade" then openTradePanel(); showToast("Примерочная — магазин открыт", Color3.fromRGB(255,220,180))
	elseif action == "BuffApplied" then showToast(data.Message or "Бафф!", Color3.fromRGB(255,180,100)); updateBuffLabel(data)
	elseif action == "GachaResult" then
		showToast("Гача: " .. (data.Message or "???"), Color3.fromRGB(255,140,200))
		if data.FomoSecondsLeft then updateWorldFomoLabel(data.FomoSecondsLeft) end
	elseif action == "Toast" then showToast(data.Text or "")
	elseif action == "BuffList" then
		for _, b in ipairs(data.Buffs or {}) do if b.Id == "MangaDamage" then updateBuffLabel({Name=b.Name, Duration=b.SecondsLeft}) end end
	elseif action == "GachaFomo" then
		updateWorldFomoLabel(data.SecondsLeft or 0)
	end
end)
task.defer(function()
	havenEvent:FireServer("RequestBuffs")
	havenEvent:FireServer("RequestFomo")
end)
print("Realm of Spirits - OtakuHavenController loaded!")
