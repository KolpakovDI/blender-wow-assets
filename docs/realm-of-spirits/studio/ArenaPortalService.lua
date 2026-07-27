-- ArenaPortalService: rebind arena enter/exit after place load
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local realm = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local portalEvent = realm:FindFirstChild("ArenaPortal")
if not portalEvent then
	portalEvent = Instance.new("RemoteEvent")
	portalEvent.Name = "ArenaPortal"
	portalEvent.Parent = realm
end

local function getBuilder()
	local mod = script.Parent:FindFirstChild("BattleArenaBuilder")
	if not mod then
		return nil
	end
	local ok, builder = pcall(require, mod)
	if ok then
		return builder
	end
	return nil
end

local function parseVec(attr)
	if typeof(attr) ~= "string" then
		return nil
	end
	local x, y, z = string.match(attr, "([^,]+),([^,]+),([^,]+)")
	if not x then
		return nil
	end
	return Vector3.new(tonumber(x), tonumber(y), tonumber(z))
end

local function teleportPlayer(player, dest)
	local char = player and player.Character
	if not char or typeof(dest) ~= "Vector3" then
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local cf = CFrame.new(dest)
	pcall(function()
		char:PivotTo(cf)
	end)
	if hrp then
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		hrp.CFrame = cf
	end
	print("[ArenaPortalService] remote teleport", player.Name, dest)
end

local function wire()
	local builder = getBuilder()
	if builder and builder.WirePortals then
		local ok = builder.WirePortals()
		if ok then
			print("[ArenaPortalService] BattleArena enter/exit portals wired")
		end
		return ok
	end
	return false
end

portalEvent.OnServerEvent:Connect(function(player, action)
	if typeof(action) ~= "string" then
		return
	end
	local arena = workspace:FindFirstChild("BattleArena")
	if not arena then
		return
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	local enter = arena:FindFirstChild("EntrancePortal", true)
	local exitP = arena:FindFirstChild("ExitPortal", true)
	local inside = parseVec(arena:GetAttribute("PortalInside")) or Vector3.new(194, 3, 40)
	local outside = parseVec(arena:GetAttribute("PortalOutside")) or Vector3.new(103, 3, 40)

	if action == "Enter" then
		if not enter or (hrp.Position - enter.Position).Magnitude > 28 then
			return
		end
		teleportPlayer(player, inside)
	elseif action == "Exit" then
		if not exitP or (hrp.Position - exitP.Position).Magnitude > 28 then
			return
		end
		teleportPlayer(player, outside)
	end
end)

wire()
task.defer(wire)
task.delay(1, wire)
task.delay(3, wire)

workspace.ChildAdded:Connect(function(child)
	if child.Name == "BattleArena" then
		task.defer(wire)
		task.delay(0.5, wire)
	end
end)
