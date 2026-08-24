--!strict
-- GuildPanelUI (F4 W10): fail-closed guild panel + bank write prep (live Locked)
-- Toggle: G key or chat /guildpanel · CreateOrJoin / Deposit / Withdraw stay gated server-side
-- Reads GuildEvent GetPanel / GuildBank; no Allow* flip · live bank writes fail-closed

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local RealmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local guildEventInst = RealmFolder:WaitForChild("GuildEvent", 30)
if not guildEventInst or not guildEventInst:IsA("RemoteEvent") then
	warn("[GuildPanelUI] GuildEvent missing")
	return
end
local guildEvent: RemoteEvent = guildEventInst :: RemoteEvent

local ExpansionGate: any = nil
pcall(function()
	ExpansionGate = require(RealmFolder:WaitForChild("ExpansionGate", 5))
end)

type BankSnap = {
	Copper: number?,
	ItemCount: number?,
	Locked: boolean?,
	WriteLocked: boolean?,
	InMemoryOnly: boolean?,
	MaxSlots: number?,
}

type PanelSnap = {
	HasMembership: boolean?,
	GateAllows: boolean?,
	CreateBlocked: boolean?,
	BankWriteLocked: boolean?,
	LockedMessage: string?,
	Membership: { Id: string?, Name: string?, Tag: string?, Role: string? }?,
	Roster: { { UserId: number?, Role: string? } }?,
	Bank: BankSnap?,
}

local panelGui: ScreenGui? = nil
local panelFrame: Frame? = nil
local bodyLabel: TextLabel? = nil
local rosterLabel: TextLabel? = nil
local bankLabel: TextLabel? = nil
local titleLabel: TextLabel? = nil
local visible = false
local lastSnap: PanelSnap? = nil

local function gateAllows(): boolean
	return ExpansionGate ~= nil and ExpansionGate.AllowGuilds == true
end

local function hasLocalMembership(): boolean
	local tag = player:GetAttribute("GuildTag")
	return typeof(tag) == "string" and #tostring(tag) >= 2
end

local function ensureGui()
	if panelGui and panelGui.Parent then
		return
	end
	local pg = player:WaitForChild("PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "GuildPanelGui"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 80
	gui.IgnoreGuiInset = true

	local frame = Instance.new("Frame")
	frame.Name = "GuildPanel"
	frame.Size = UDim2.fromOffset(360, 320)
	frame.Position = UDim2.new(0.5, -180, 0.5, -160)
	frame.BackgroundColor3 = Color3.fromRGB(28, 26, 38)
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(180, 150, 90)
	stroke.Thickness = 1.5
	stroke.Parent = frame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -48, 0, 32)
	title.Position = UDim2.fromOffset(12, 8)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 20
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Color3.fromRGB(255, 215, 120)
	title.Text = "ГИЛЬДИЯ"
	title.Parent = frame

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "Close"
	closeBtn.Size = UDim2.fromOffset(28, 28)
	closeBtn.Position = UDim2.new(1, -36, 0, 8)
	closeBtn.BackgroundColor3 = Color3.fromRGB(70, 50, 50)
	closeBtn.TextColor3 = Color3.fromRGB(255, 220, 220)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 16
	closeBtn.Text = "X"
	closeBtn.Parent = frame
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 4)
	closeCorner.Parent = closeBtn

	local body = Instance.new("TextLabel")
	body.Name = "Body"
	body.Size = UDim2.new(1, -24, 0, 72)
	body.Position = UDim2.fromOffset(12, 44)
	body.BackgroundTransparency = 1
	body.Font = Enum.Font.Gotham
	body.TextSize = 14
	body.TextWrapped = true
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextColor3 = Color3.fromRGB(220, 220, 230)
	body.Text = "Загрузка…"
	body.Parent = frame

	local roster = Instance.new("TextLabel")
	roster.Name = "Roster"
	roster.Size = UDim2.new(1, -24, 0, 110)
	roster.Position = UDim2.fromOffset(12, 120)
	roster.BackgroundColor3 = Color3.fromRGB(36, 34, 48)
	roster.Font = Enum.Font.Code
	roster.TextSize = 13
	roster.TextWrapped = true
	roster.TextXAlignment = Enum.TextXAlignment.Left
	roster.TextYAlignment = Enum.TextYAlignment.Top
	roster.TextColor3 = Color3.fromRGB(200, 205, 220)
	roster.Text = ""
	roster.Parent = frame
	local rosterPad = Instance.new("UIPadding")
	rosterPad.PaddingTop = UDim.new(0, 6)
	rosterPad.PaddingLeft = UDim.new(0, 8)
	rosterPad.PaddingRight = UDim.new(0, 8)
	rosterPad.Parent = roster
	local rosterCorner = Instance.new("UICorner")
	rosterCorner.CornerRadius = UDim.new(0, 4)
	rosterCorner.Parent = roster

	local bank = Instance.new("TextLabel")
	bank.Name = "Bank"
	bank.Size = UDim2.new(1, -24, 0, 48)
	bank.Position = UDim2.fromOffset(12, 240)
	bank.BackgroundColor3 = Color3.fromRGB(36, 34, 48)
	bank.Font = Enum.Font.Gotham
	bank.TextSize = 13
	bank.TextWrapped = true
	bank.TextXAlignment = Enum.TextXAlignment.Left
	bank.TextYAlignment = Enum.TextYAlignment.Top
	bank.TextColor3 = Color3.fromRGB(180, 190, 200)
	bank.Text = ""
	bank.Parent = frame
	local bankPad = Instance.new("UIPadding")
	bankPad.PaddingTop = UDim.new(0, 6)
	bankPad.PaddingLeft = UDim.new(0, 8)
	bankPad.Parent = bank
	local bankCorner = Instance.new("UICorner")
	bankCorner.CornerRadius = UDim.new(0, 4)
	bankCorner.Parent = bank

	local hint = Instance.new("TextLabel")
	hint.Name = "Hint"
	hint.Size = UDim2.new(1, -24, 0, 18)
	hint.Position = UDim2.fromOffset(12, 292)
	hint.BackgroundTransparency = 1
	hint.Font = Enum.Font.Gotham
	hint.TextSize = 11
	hint.TextColor3 = Color3.fromRGB(140, 140, 160)
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.Text = "G / /guildpanel — закрыть · create/deposit Locked (gate)"
	hint.Parent = frame

	closeBtn.MouseButton1Click:Connect(function()
		visible = false
		frame.Visible = false
	end)

	gui.Parent = pg
	panelGui = gui
	panelFrame = frame
	bodyLabel = body
	rosterLabel = roster
	bankLabel = bank
	titleLabel = title
end

local function formatRoster(roster: { { UserId: number?, Role: string? } }?): string
	if type(roster) ~= "table" or #roster == 0 then
		return "Состав: (пусто)"
	end
	local lines = { "Состав:" }
	for _, entry in ipairs(roster) do
		local uid = entry.UserId or 0
		local role = entry.Role or "Member"
		table.insert(lines, string.format("  · %d — %s", uid, tostring(role)))
	end
	return table.concat(lines, "\n")
end

local function formatBank(bank: BankSnap?): string
	if type(bank) ~= "table" then
		return "Банк: недоступен (нет гильдии)"
	end
	local copper = tonumber(bank.Copper) or 0
	local items = tonumber(bank.ItemCount) or 0
	local maxSlots = tonumber(bank.MaxSlots) or 20
	local writeLocked = bank.WriteLocked ~= false or bank.Locked ~= false
	if writeLocked then
		return string.format(
			"Банк (W10): Copper %d · слоты %d/%d · WRITE LOCKED (нет AllowGuilds)",
			copper,
			items,
			maxSlots
		)
	end
	return string.format("Банк: Copper %d · слоты %d/%d", copper, items, maxSlots)
end

local function applySnapshot(snap: PanelSnap)
	lastSnap = snap
	ensureGui()
	if not bodyLabel or not rosterLabel or not bankLabel or not titleLabel then
		return
	end

	if snap.HasMembership == true and type(snap.Membership) == "table" then
		local m = snap.Membership
		local name = tostring(m.Name or "?")
		local tag = tostring(m.Tag or "??")
		local role = tostring(m.Role or "Member")
		titleLabel.Text = string.format("[%s] %s", tag, name)
		bodyLabel.Text = string.format(
			"Роль: %s\nId: %s\nCreate/Join: %s",
			role,
			tostring(m.Id or ""),
			if snap.CreateBlocked then "закрыто (gate)" else "открыто"
		)
		bodyLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
		rosterLabel.Text = formatRoster(snap.Roster)
		bankLabel.Text = formatBank(snap.Bank)
	else
		titleLabel.Text = "ГИЛЬДИЯ"
		local msg = snap.LockedMessage
		if type(msg) ~= "string" or #msg == 0 then
			if gateAllows() then
				msg = "Нет гильдии"
			else
				msg = "Гильдии закрыты (ExpansionGate / dev-only)"
			end
		end
		bodyLabel.Text = msg
		bodyLabel.TextColor3 = Color3.fromRGB(255, 180, 140)
		rosterLabel.Text = "Состав: —"
		bankLabel.Text = "Банк: — (нужна гильдия)"
	end
end

local function applyLocalFallback()
	ensureGui()
	if hasLocalMembership() then
		applySnapshot({
			HasMembership = true,
			GateAllows = gateAllows(),
			CreateBlocked = not gateAllows(),
			Membership = {
				Name = tostring(player:GetAttribute("GuildName") or "?"),
				Tag = tostring(player:GetAttribute("GuildTag") or "??"),
				Role = tostring(player:GetAttribute("GuildRole") or "Member"),
				Id = "?",
			},
			Roster = {},
			Bank = { Copper = 0, ItemCount = 0, Locked = true, MaxSlots = 20 },
		})
	else
		applySnapshot({
			HasMembership = false,
			GateAllows = gateAllows(),
			CreateBlocked = not gateAllows(),
			LockedMessage = if gateAllows()
				then "Нет гильдии"
				else "Гильдии закрыты (ExpansionGate / dev-only)",
			Roster = {},
			Bank = nil,
		})
	end
end

local function requestPanel()
	ensureGui()
	applyLocalFallback()
	guildEvent:FireServer("GetPanel", {})
end

local function setVisible(on: boolean)
	ensureGui()
	visible = on
	if panelFrame then
		panelFrame.Visible = on
	end
	if on then
		requestPanel()
	end
end

local function toggle()
	setVisible(not visible)
end

guildEvent.OnClientEvent:Connect(function(action: any, payload: any)
	if typeof(action) ~= "string" then
		return
	end
	if action == "GuildPanel" and type(payload) == "table" then
		applySnapshot(payload :: PanelSnap)
	elseif action == "GuildState" or action == "GuildJoined" then
		if visible then
			requestPanel()
		end
	elseif action == "GuildLeft" then
		if visible then
			applySnapshot({
				HasMembership = false,
				GateAllows = gateAllows(),
				CreateBlocked = not gateAllows(),
				LockedMessage = "Гильдии закрыты (ExpansionGate / dev-only)",
				Roster = {},
				Bank = nil,
			})
		end
	elseif action == "GuildRoster" and visible and lastSnap and lastSnap.HasMembership then
		lastSnap.Roster = if type(payload) == "table" then payload else {}
		applySnapshot(lastSnap)
	elseif action == "GuildBank" and visible and lastSnap and lastSnap.HasMembership then
		lastSnap.Bank = if type(payload) == "table" then payload else nil
		applySnapshot(lastSnap)
	elseif action == "Error" and visible and type(payload) == "table" then
		local msg = tostring(payload.Message or "")
		if #msg > 0 and bodyLabel then
			bodyLabel.Text = string.format("Банк: %s", msg)
			bodyLabel.TextColor3 = Color3.fromRGB(255, 180, 140)
		end
	end
end)

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.G then
		toggle()
	end
end)

player.Chatted:Connect(function(msg: string)
	local lower = string.lower(msg)
	if lower == "/guildpanel" or lower == "/guildui" then
		toggle()
	end
end)

player:GetAttributeChangedSignal("GuildTag"):Connect(function()
	if visible then
		requestPanel()
	end
end)

print("[GuildPanelUI] W10 ready — G / /guildpanel (deposit fail-closed)")
