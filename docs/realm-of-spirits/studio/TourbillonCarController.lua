-- Hypercar: doors, enter/exit, arcade drive (no brand marks)
-- Mirror of ServerScriptService.TourbillonCarController
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local car = workspace:WaitForChild("TourbillonCar")
local chassis = car:WaitForChild("Chassis")
local seat = car:WaitForChild("DriveSeat")
local doorL = car:WaitForChild("DoorL")
local doorR = car:WaitForChild("DoorR")

local remotes = ReplicatedStorage:FindFirstChild("TourbillonCarRemotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "TourbillonCarRemotes"
	remotes.Parent = ReplicatedStorage
end
local function ensureRemote(name)
	local r = remotes:FindFirstChild(name)
	if not r then
		r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = remotes
	end
	return r
end
local driveInput = ensureRemote("DriveInput")
local doorToggle = ensureRemote("DoorToggle")

local POWER = 90000
local TURN = 2.8
local MAX_SPEED = 90

local att = chassis:FindFirstChild("DriveAtt") or Instance.new("Attachment")
att.Name = "DriveAtt"
att.Parent = chassis

local force = chassis:FindFirstChild("DriveForce") or Instance.new("VectorForce")
force.Name = "DriveForce"
force.Attachment0 = att
force.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
force.ApplyAtCenterOfMass = true
force.Force = Vector3.zero
force.Parent = chassis

local ang = chassis:FindFirstChild("DriveAng") or Instance.new("AngularVelocity")
ang.Name = "DriveAng"
ang.Attachment0 = att
ang.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
ang.MaxTorque = 1e6
ang.AngularVelocity = Vector3.zero
ang.Parent = chassis

local uiThrottle = 0
local uiSteer = 0

local function toggleDoor(door)
	local hinge = door:FindFirstChild("DoorHinge")
	if not hinge then
		return
	end
	local open = door:GetAttribute("IsOpen") == true
	local openAngle = door:GetAttribute("OpenAngle") or 70
	if open then
		hinge.TargetAngle = 0
		door:SetAttribute("IsOpen", false)
	else
		hinge.TargetAngle = openAngle
		door:SetAttribute("IsOpen", true)
	end
end

for _, door in ipairs({ doorL, doorR }) do
	local prompt = door:FindFirstChild("DoorPrompt")
	if prompt then
		prompt.Triggered:Connect(function()
			toggleDoor(door)
		end)
	end
end

doorToggle.OnServerEvent:Connect(function(player, side)
	if typeof(side) ~= "string" then
		return
	end
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp or (hrp.Position - chassis.Position).Magnitude > 22 then
		return
	end
	if side == "L" then
		toggleDoor(doorL)
	elseif side == "R" then
		toggleDoor(doorR)
	end
end)

local enterPrompt = chassis:FindFirstChild("EnterPrompt")
if enterPrompt then
	enterPrompt.Triggered:Connect(function(player)
		local char = player.Character
		if not char then
			return
		end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum then
			return
		end
		if seat.Occupant then
			return
		end
		if doorL:GetAttribute("IsOpen") ~= true then
			toggleDoor(doorL)
		end
		task.wait(0.35)
		seat:Sit(hum)
		pcall(function()
			chassis:SetNetworkOwner(player)
		end)
	end)
end

seat:GetPropertyChangedSignal("Occupant"):Connect(function()
	if not seat.Occupant then
		uiThrottle = 0
		uiSteer = 0
		force.Force = Vector3.zero
		ang.AngularVelocity = Vector3.zero
		pcall(function()
			chassis:SetNetworkOwner(nil)
		end)
	end
end)

driveInput.OnServerEvent:Connect(function(player, throttle, steer)
	local occ = seat.Occupant
	if not occ then
		return
	end
	local char = occ.Parent
	if not char or Players:GetPlayerFromCharacter(char) ~= player then
		return
	end
	if typeof(throttle) ~= "number" or typeof(steer) ~= "number" then
		return
	end
	uiThrottle = math.clamp(throttle, -1, 1)
	uiSteer = math.clamp(steer, -1, 1)
end)

local wheelHinges = {}
for _, name in ipairs({ "WheelFL", "WheelFR", "WheelRL", "WheelRR" }) do
	local w = car:FindFirstChild(name)
	if w then
		local h = w:FindFirstChildOfClass("HingeConstraint")
		if h then
			table.insert(wheelHinges, h)
		end
	end
end

RunService.Heartbeat:Connect(function()
	if not seat.Occupant then
		force.Force = Vector3.zero
		ang.AngularVelocity = Vector3.zero
		for _, h in ipairs(wheelHinges) do
			h.AngularVelocity = 0
		end
		return
	end
	local throttle = seat.Throttle
	if math.abs(uiThrottle) > 0.05 then
		throttle = uiThrottle
	end
	local steer = seat.Steer
	if math.abs(uiSteer) > 0.05 then
		steer = uiSteer
	end
	local speed = chassis.AssemblyLinearVelocity.Magnitude
	local damp = if speed > MAX_SPEED and throttle > 0 then 0.15 else 1
	force.Force = Vector3.new(0, 0, -throttle * POWER * damp)
	ang.AngularVelocity = Vector3.new(0, -steer * TURN * math.clamp(math.abs(throttle) + 0.25, 0.25, 1), 0)
	local spin = throttle * 25
	for _, h in ipairs(wheelHinges) do
		h.AngularVelocity = spin
	end
end)
