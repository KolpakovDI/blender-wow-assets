-- On-screen drive + door buttons when seated in TourbillonCar
-- Mirror of StarterPlayer.StarterPlayerScripts.TourbillonDriveUI
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("TourbillonCarRemotes", 30)
if not remotes then
	return
end
local driveInput = remotes:WaitForChild("DriveInput")
local doorToggle = remotes:WaitForChild("DoorToggle")

local gui = Instance.new("ScreenGui")
gui.Name = "TourbillonDriveUI"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local function mkBtn(name, text, pos, size)
	local b = Instance.new("TextButton")
	b.Name = name
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 22
	b.TextColor3 = Color3.new(1, 1, 1)
	b.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
	b.BackgroundTransparency = 0.25
	b.BorderSizePixel = 0
	b.Size = size
	b.Position = pos
	b.Parent = gui
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = b
	return b
end

local throttle = 0
local steer = 0
local held = {}

local btnW = mkBtn("W", "▲", UDim2.new(0.78, 0, 0.62, 0), UDim2.fromOffset(64, 64))
local btnS = mkBtn("S", "▼", UDim2.new(0.78, 0, 0.78, 0), UDim2.fromOffset(64, 64))
local btnA = mkBtn("A", "◀", UDim2.new(0.70, 0, 0.70, 0), UDim2.fromOffset(64, 64))
local btnD = mkBtn("D", "▶", UDim2.new(0.86, 0, 0.70, 0), UDim2.fromOffset(64, 64))
local btnDoor = mkBtn("Door", "Двери", UDim2.new(0.05, 0, 0.78, 0), UDim2.fromOffset(110, 48))
local hint = Instance.new("TextLabel")
hint.BackgroundTransparency = 1
hint.Size = UDim2.new(0, 280, 0, 28)
hint.Position = UDim2.new(0.5, -140, 0.88, 0)
hint.Font = Enum.Font.Gotham
hint.TextSize = 16
hint.TextColor3 = Color3.fromRGB(230, 230, 230)
hint.Text = "WASD / кнопки · Space — выйти"
hint.Parent = gui

local function bindHold(btn, key, on, off)
	btn.MouseButton1Down:Connect(function()
		held[key] = true
		on()
	end)
	btn.MouseButton1Up:Connect(function()
		held[key] = false
		off()
	end)
	btn.MouseLeave:Connect(function()
		if held[key] then
			held[key] = false
			off()
		end
	end)
end

bindHold(btnW, "W", function()
	throttle = 1
end, function()
	if not held.S then
		throttle = 0
	end
end)
bindHold(btnS, "S", function()
	throttle = -1
end, function()
	if not held.W then
		throttle = 0
	end
end)
bindHold(btnA, "A", function()
	steer = -1
end, function()
	if not held.D then
		steer = 0
	end
end)
bindHold(btnD, "D", function()
	steer = 1
end, function()
	if not held.A then
		steer = 0
	end
end)

btnDoor.MouseButton1Click:Connect(function()
	doorToggle:FireServer("L")
	doorToggle:FireServer("R")
end)

local function inOurSeat()
	local char = player.Character
	if not char then
		return false
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or not hum.SeatPart then
		return false
	end
	local seat = hum.SeatPart
	return seat.Name == "DriveSeat" and seat.Parent and seat.Parent.Name == "TourbillonCar"
end

RunService.RenderStepped:Connect(function()
	local seated = inOurSeat()
	gui.Enabled = seated
	if seated then
		local kThrottle = 0
		local kSteer = 0
		if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
			kThrottle = 1
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then
			kThrottle = -1
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
			kSteer = -1
		end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
			kSteer = 1
		end
		local t = if math.abs(throttle) > 0 then throttle else kThrottle
		local s = if math.abs(steer) > 0 then steer else kSteer
		driveInput:FireServer(t, s)
	end
end)
