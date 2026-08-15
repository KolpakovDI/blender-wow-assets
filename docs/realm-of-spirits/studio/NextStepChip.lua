-- NextStepChip: FTUE one-line objective (UI package B)
-- Steps: Mika → Exit → funnel loot (E) → hide
-- Q1 polish: after FTUE (or with active quest), show ZoneHint from QuestCatalog
-- Client-only; does not change server remotes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local realm = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local zoneChanged = realm:WaitForChild("ZoneChanged")
local QuestEvent = realm:WaitForChild("Quest")
local DataEvent = realm:WaitForChild("DataSync")
local HavenEvent = realm:FindFirstChild("OtakuHaven")

local STEP = {
	Mika = "mika",
	Exit = "exit",
	Loot = "loot",
	Done = "done",
}

local STEP_TEXT = {
	[STEP.Mika] = "Поговори с Микой",
	[STEP.Exit] = "Выход в Акихабару",
	[STEP.Loot] = "Подбери лут у двери (E)",
}

local current = STEP.Mika
local gui, frame, label
local zoneHintOverride = nil -- string from active quest ZoneHint

-- Stack under ResonanceActivityBar (Y=8, H=28). Match RealmOfSpiritsUI inset space.
local CHIP_TOP = 44

local function syncGuiInsets()
	if not gui then
		return
	end
	local pg = player:FindFirstChild("PlayerGui")
	local ros = pg and pg:FindFirstChild("RealmOfSpiritsUI")
	if ros then
		gui.IgnoreGuiInset = ros.IgnoreGuiInset
		pcall(function()
			gui.ScreenInsets = ros.ScreenInsets
		end)
	else
		gui.IgnoreGuiInset = true
		pcall(function()
			gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
		end)
	end
end

local function layoutChip()
	if not gui or not frame then
		return
	end
	syncGuiInsets()
	gui.DisplayOrder = 110
	local top = CHIP_TOP
	local pg = player:FindFirstChild("PlayerGui")
	local ros = pg and pg:FindFirstChild("RealmOfSpiritsUI")
	local bar = ros and ros:FindFirstChild("ResonanceActivityBar")
	if bar then
		local barH = bar.Size.Y.Offset
		if barH <= 0 then
			barH = 28
		end
		top = bar.Position.Y.Offset + barH + 8
	end
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.new(0.5, 0, 0, top)
	frame.Size = UDim2.new(0, 420, 0, 36)
	frame.BackgroundTransparency = 0.05
end

local function ensureGui()
	local pg = player:WaitForChild("PlayerGui")
	gui = pg:FindFirstChild("RoS_NextStepChip")
	if gui then
		frame = gui:FindFirstChild("Chip")
		label = frame and frame:FindFirstChild("Label")
		layoutChip()
		return
	end
	gui = Instance.new("ScreenGui")
	gui.Name = "RoS_NextStepChip"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 110
	pcall(function()
		gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	end)
	gui.Parent = pg

	frame = Instance.new("Frame")
	frame.Name = "Chip"
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.Position = UDim2.new(0.5, 0, 0, CHIP_TOP)
	frame.Size = UDim2.new(0, 420, 0, 36)
	frame.BackgroundColor3 = Color3.fromRGB(32, 28, 44)
	frame.BackgroundTransparency = 0.05
	frame.BorderSizePixel = 0
	frame.ClipsDescendants = true
	frame.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(210, 180, 120)
	stroke.Thickness = 1.2
	stroke.Transparency = 0.35
	stroke.Parent = frame

	label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, -16, 1, 0)
	label.Position = UDim2.new(0, 8, 0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 15
	label.TextColor3 = Color3.fromRGB(245, 235, 215)
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = STEP_TEXT[STEP.Mika]
	label.Parent = frame

	layoutChip()
end

local function refresh()
	ensureGui()
	-- ZoneHint wins after FTUE Done, or alongside Exit/Loot when quest points somewhere
	if type(zoneHintOverride) == "string" and zoneHintOverride ~= "" then
		frame.Visible = true
		label.Text = "→  " .. zoneHintOverride
		return
	end
	if current == STEP.Done then
		frame.Visible = false
		return
	end
	frame.Visible = true
	label.Text = "→  " .. (STEP_TEXT[current] or "")
end

local function setStep(nextStep)
	if current == STEP.Done then
		return
	end
	local order = { [STEP.Mika] = 1, [STEP.Exit] = 2, [STEP.Loot] = 3, [STEP.Done] = 4 }
	if (order[nextStep] or 0) <= (order[current] or 0) then
		return
	end
	current = nextStep
	refresh()
end

local function setZoneHint(hint)
	if type(hint) == "string" and hint ~= "" then
		zoneHintOverride = hint
	else
		zoneHintOverride = nil
	end
	refresh()
end

local function extractZoneHintFromEntry(entry)
	if type(entry) ~= "table" then
		return nil
	end
	local quest = entry.Quest or entry
	if type(quest) ~= "table" then
		return nil
	end
	if type(quest.ZoneHint) == "string" and quest.ZoneHint ~= "" then
		return quest.ZoneHint
	end
	return nil
end

local function applyActiveQuestHints(data)
	if type(data) ~= "table" then
		return
	end
	local list = data.Quests or data.Active or data
	if type(list) ~= "table" then
		return
	end
	-- Prefer first active not ready to turn in
	for _, entry in ipairs(list) do
		if type(entry) == "table" and entry.ReadyToTurnIn ~= true then
			local hint = extractZoneHintFromEntry(entry)
			if hint then
				setZoneHint(hint)
				return
			end
		end
	end
	for _, entry in ipairs(list) do
		local hint = extractZoneHintFromEntry(entry)
		if hint then
			setZoneHint(hint)
			return
		end
	end
end

local function inventoryHasFunnelLoot(data)
	if type(data) ~= "table" or type(data.Inventory) ~= "table" then
		return false
	end
	for _, item in ipairs(data.Inventory) do
		local id = tonumber(item.Id)
		if id == 101 or id == 102 or id == 120 then
			local q = tonumber(item.Quantity) or 0
			if q > 0 then
				return true
			end
		end
	end
	return false
end

local function onZone(zoneType, detail)
	detail = detail or zoneType
	if detail == "Exit" or zoneType == "Combat" or detail == "Combat" or detail == "Akihabara" then
		if current == STEP.Mika then
			setStep(STEP.Exit)
		end
		setStep(STEP.Loot)
	end
end

zoneChanged.OnClientEvent:Connect(onZone)

player:GetAttributeChangedSignal("CurrentZone"):Connect(function()
	local z = player:GetAttribute("CurrentZone")
	local d = player:GetAttribute("ZoneDetail")
	if type(z) == "string" then
		onZone(z, d)
	end
end)

QuestEvent.OnClientEvent:Connect(function(action, data)
	if action == "QuestAccepted" then
		setStep(STEP.Exit)
		if type(data) == "table" and type(data.ZoneHint) == "string" then
			setZoneHint(data.ZoneHint)
		end
		return
	end
	if action == "OpenQuestUI" then
		setStep(STEP.Exit)
		if type(data) == "table" then
			applyActiveQuestHints(data)
		end
		return
	end
	if action == "ActiveQuests" or action == "QuestList" then
		local n = 0
		if type(data) == "table" then
			if type(data.Quests) == "table" then
				n = #data.Quests
				applyActiveQuestHints(data)
			elseif type(data.Active) == "table" then
				n = #data.Active
				applyActiveQuestHints(data)
			else
				for k, v in pairs(data) do
					if type(k) == "number" or v == true then
						n += 1
					end
				end
			end
		end
		if n > 0 then
			setStep(STEP.Exit)
		end
	end
	if action == "QuestCompleted" or action == "QuestTurnedIn" then
		-- Refresh from server list next GetActiveQuests
		zoneHintOverride = nil
		refresh()
		QuestEvent:FireServer("GetActiveQuests", {})
	end
end)

DataEvent.OnClientEvent:Connect(function(action, data)
	if action == "FullSync" and inventoryHasFunnelLoot(data) then
		if current == STEP.Loot or current == STEP.Exit then
			setStep(STEP.Done)
		end
	end
end)

if HavenEvent then
	HavenEvent.OnClientEvent:Connect(function(action, data)
		if action == "Toast" and type(data) == "table" and type(data.Text) == "string" then
			if string.find(data.Text, "Собран", 1, true) or string.find(data.Text, "Сундук", 1, true) then
				setStep(STEP.Done)
			end
		end
	end)
end

ensureGui()
refresh()

task.defer(function()
	local z = player:GetAttribute("CurrentZone")
	local d = player:GetAttribute("ZoneDetail")
	if type(z) == "string" then
		onZone(z, d)
	end
	QuestEvent:FireServer("GetActiveQuests", {})
end)

-- Relayout after UIController builds ResonanceActivityBar
task.spawn(function()
	local pg = player:WaitForChild("PlayerGui")
	local ros = pg:WaitForChild("RealmOfSpiritsUI", 15)
	if ros then
		ros:WaitForChild("ResonanceActivityBar", 5)
	end
	layoutChip()
	refresh()
end)

print("[RoS] NextStepChip ready (UI package B + ZoneHint)")
