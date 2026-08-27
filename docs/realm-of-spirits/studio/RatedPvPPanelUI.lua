--!strict
-- RatedPvPPanelUI (F4 W15+): read-only rated ladder panel (fail-closed)
-- Toggle: P key or chat /ratedpanel · live writes stay gated server-side
-- Reads RatedPvP GetPanel / Ladder; no AllowNewPvPFeatures flip

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local RealmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local ratedInst = RealmFolder:WaitForChild("RatedPvP", 30)
if not ratedInst or not ratedInst:IsA("RemoteEvent") then
	warn("[RatedPvPPanelUI] RatedPvP remote missing")
	return
end
local ratedEvent: RemoteEvent = ratedInst :: RemoteEvent

local ExpansionGate: any = nil
pcall(function()
	ExpansionGate = require(RealmFolder:WaitForChild("ExpansionGate", 5))
end)

local panelGui: ScreenGui? = nil
local bodyLabel: TextLabel? = nil
local visible = false

local function gateAllows(): boolean
	return ExpansionGate ~= nil and ExpansionGate.AllowNewPvPFeatures == true
end

local function ensureGui()
	if panelGui and panelGui.Parent then
		return
	end
	local pg = player:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui")
	gui.Name = "RatedPvPPanelGui"
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.Parent = pg

	local frame = Instance.new("Frame")
	frame.Name = "Panel"
	frame.Size = UDim2.fromOffset(360, 280)
	frame.Position = UDim2.new(0.5, -180, 0.5, -140)
	frame.BackgroundColor3 = Color3.fromRGB(24, 28, 36)
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -16, 0, 28)
	title.Position = UDim2.fromOffset(8, 8)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.TextColor3 = Color3.fromRGB(230, 230, 240)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "Rated PvP (LOCKED)"
	title.Parent = frame

	local body = Instance.new("TextLabel")
	body.Name = "Body"
	body.Size = UDim2.new(1, -16, 1, -48)
	body.Position = UDim2.fromOffset(8, 40)
	body.BackgroundTransparency = 1
	body.Font = Enum.Font.Gotham
	body.TextSize = 14
	body.TextColor3 = Color3.fromRGB(200, 205, 215)
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextWrapped = true
	body.Text = "Loading..."
	body.Parent = frame

	panelGui = gui
	bodyLabel = body
end

local function renderPanel(snap: any)
	ensureGui()
	if not bodyLabel then
		return
	end
	local lines = {}
	table.insert(lines, if gateAllows() then "Gate: ON (still deferred)" else "Gate: OFF (dev-only)")
	table.insert(lines, "Season: " .. tostring(snap and snap.SeasonId or "?"))
	table.insert(lines, "WriteLocked: " .. tostring(snap and snap.WriteLocked))
	table.insert(lines, "MM Locked: " .. tostring(snap and snap.MatchmakingLocked))
	if snap and snap.LockedMessage then
		table.insert(lines, tostring(snap.LockedMessage))
	end
	if snap and snap.Rating then
		table.insert(lines, string.format("You: rating=%s wins=%s losses=%s",
			tostring(snap.Rating.Rating), tostring(snap.Rating.Wins), tostring(snap.Rating.Losses)))
	end
	table.insert(lines, "Top ladder (read-only):")
	local top = snap and snap.LadderTop
	if type(top) == "table" then
		for _, row in ipairs(top) do
			table.insert(lines, string.format("  #%s uid=%s r=%s",
				tostring(row.Rank), tostring(row.UserId), tostring(row.Rating)))
		end
	end
	bodyLabel.Text = table.concat(lines, "\n")
end

local function toggle()
	ensureGui()
	if not panelGui then
		return
	end
	visible = not visible
	panelGui.Enabled = visible
	if visible then
		ratedEvent:FireServer("GetPanel")
	end
end

ratedEvent.OnClientEvent:Connect(function(kind: any, payload: any)
	if kind == "Panel" then
		renderPanel(payload)
	end
end)

UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.P then
		toggle()
	end
end)

player.Chatted:Connect(function(msg: string)
	local lower = string.lower(msg)
	if lower == "/ratedpanel" or lower == "/ladder" then
		toggle()
	end
end)

print("[RatedPvPPanelUI] ready (P / /ratedpanel) — read-only Locked")
