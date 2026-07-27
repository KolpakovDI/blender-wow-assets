-- SpiritAnimation - ground walk + flying hover + swim (tail wag)
local RunService = game:GetService("RunService")

local SpiritAnimation = {}
local SpiritAnimData = {}

local PLAYER_HEIGHT = 5.0
local MIN_FLY_HOVER = 2.0
local MAX_FLY_HOVER = 4.2
local FLYING_SPIRIT_IDS = { [2] = true, [102] = true, [104] = true }
local SWIM_SPIRIT_IDS = { [6] = true, [106] = true }

function SpiritAnimation.GetMovementType(spiritInfo)
	if spiritInfo then
		if spiritInfo.MovementType then
			return spiritInfo.MovementType
		end
		if spiritInfo.Id and FLYING_SPIRIT_IDS[spiritInfo.Id] then
			return "Fly"
		end
		if spiritInfo.Id and SWIM_SPIRIT_IDS[spiritInfo.Id] then
			return "Swim"
		end
	end
	return "Walk"
end

function SpiritAnimation.ComputeHoverHeight(spirit, _groundY)
	local _, bboxSize = spirit:GetBoundingBox()
	local half = bboxSize.Y * 0.5
	local cap = PLAYER_HEIGHT - half - 0.2
	cap = math.max(MIN_FLY_HOVER, cap)
	return math.clamp(3.2, MIN_FLY_HOVER, math.min(MAX_FLY_HOVER, cap))
end

local function applyWings(data, elapsed)
	if not data.wings then
		return
	end
	local body = data.body
	local flap = math.sin(elapsed * 12) * math.rad(28)
	local tilt = math.sin(elapsed * 6) * math.rad(4)
	data.wings.part.CFrame = body.CFrame * data.wings.baseLocal * CFrame.Angles(flap, 0, tilt)
end

local function applyLegs(data, elapsed, moving)
	if not data.legs or data.movementType ~= "Walk" then
		return
	end
	local body = data.body
	if moving then
		local stride = math.sin(elapsed * 9)
		local angle = stride * math.rad(7)
		local hip = data.legs.hipOffset
		data.legs.part.CFrame = body.CFrame
			* data.legs.baseLocal
			* CFrame.new(0, hip, 0)
			* CFrame.Angles(angle, 0, stride * math.rad(2))
			* CFrame.new(0, -hip, 0)
	else
		data.legs.part.CFrame = body.CFrame * data.legs.baseLocal
	end
end

local function applyTail(data, elapsed)
	if not data.tailParts or #data.tailParts == 0 then
		return
	end
	local body = data.body
	-- continuous swim: stronger wag while moving
	local amp = data.moving and math.rad(22) or math.rad(12)
	local wag = math.sin(elapsed * (data.moving and 11 or 7)) * amp
	local roll = math.sin(elapsed * 5.5) * math.rad(4)
	for _, entry in ipairs(data.tailParts) do
		if entry.part and entry.part.Parent then
			entry.part.CFrame = body.CFrame * entry.baseLocal * CFrame.Angles(roll * 0.35, wag, 0)
		end
	end
end

function SpiritAnimation.ApplyFrame(spirit)
	local data = SpiritAnimData[spirit]
	if not data or not data.body or not data.body.Parent then
		return
	end
	local elapsed = os.clock() - (data.startTime or os.clock())
	if data.movementType == "Fly" then
		applyWings(data, elapsed)
	elseif data.movementType == "Swim" then
		applyTail(data, elapsed)
	else
		applyLegs(data, elapsed, data.moving)
	end
end

function SpiritAnimation.SetMoving(spirit, moving)
	local data = SpiritAnimData[spirit]
	if data then
		data.moving = moving
	end
end

function SpiritAnimation.Setup(spirit, spiritInfo, getGroundPosition)
	local bodyGeom = spirit:FindFirstChild("body_geom", true)
	if not bodyGeom then
		return
	end

	local movementType = SpiritAnimation.GetMovementType(spiritInfo)
	spirit:SetAttribute("MovementType", movementType)

	local data = {
		movementType = movementType,
		body = bodyGeom,
		wings = nil,
		legs = nil,
		tailParts = {},
		moving = false,
		startTime = os.clock(),
		conn = nil,
		loopRunning = false,
	}

	local wingsGeom = spirit:FindFirstChild("wings_geom", true)
	if wingsGeom then
		data.wings = {
			part = wingsGeom,
			baseLocal = bodyGeom.CFrame:ToObjectSpace(wingsGeom.CFrame),
		}
	end

	local legsGeom = spirit:FindFirstChild("legs_geom", true)
	if legsGeom then
		data.legs = {
			part = legsGeom,
			baseLocal = bodyGeom.CFrame:ToObjectSpace(legsGeom.CFrame),
			hipOffset = math.min(legsGeom.Size.Y * 0.35, 0.45),
		}
	end

	for _, desc in ipairs(spirit:GetDescendants()) do
		if desc:IsA("BasePart") then
			local n = desc.Name
			if n:find("Tail") or n:find("Lobe") or n:find("Web") then
				table.insert(data.tailParts, {
					part = desc,
					baseLocal = bodyGeom.CFrame:ToObjectSpace(desc.CFrame),
				})
			end
		end
	end

	SpiritAnimData[spirit] = data

	if movementType == "Fly" and getGroundPosition then
		local p = spirit:GetPivot().Position
		local ground = getGroundPosition(p.X, p.Z, { spirit })
		local hover = SpiritAnimation.ComputeHoverHeight(spirit, ground.Y)
		spirit:SetAttribute("HoverHeight", hover)
	end

	if movementType == "Swim" then
		local water = workspace:FindFirstChild("MistPond") and workspace.MistPond:FindFirstChild("PondWater")
		local waterY = (water and water.Position.Y + water.Size.Y * 0.15) or 1.4
		spirit:SetAttribute("SwimWaterY", waterY)
		local center = water and Vector3.new(water.Position.X, 0, water.Position.Z)
			or Vector3.new(30, 0, -880)
		local halfX = water and (water.Size.X * 0.35) or 14
		local halfZ = water and (water.Size.Z * 0.35) or 10
		spirit:SetAttribute("SwimCenter", center)
		spirit:SetAttribute("SwimRadius", math.min(halfX, halfZ))
	end
end

function SpiritAnimation.ResetPose(spirit)
	local data = SpiritAnimData[spirit]
	if not data or not data.body or not data.body.Parent then
		return
	end
	local body = data.body
	if data.wings then
		data.wings.part.CFrame = body.CFrame * data.wings.baseLocal
	end
	if data.legs then
		data.legs.part.CFrame = body.CFrame * data.legs.baseLocal
	end
	if data.tailParts then
		for _, entry in ipairs(data.tailParts) do
			if entry.part and entry.part.Parent then
				entry.part.CFrame = body.CFrame * entry.baseLocal
			end
		end
	end
end

function SpiritAnimation.StartLoop(spirit)
	local data = SpiritAnimData[spirit]
	if not data or data.conn then
		return
	end
	data.loopRunning = true
	data.conn = RunService.Heartbeat:Connect(function()
		if not spirit.Parent or spirit:GetAttribute("Dying") then
			if data.conn then
				data.conn:Disconnect()
				data.conn = nil
			end
			data.loopRunning = false
			return
		end
		SpiritAnimation.ApplyFrame(spirit)
	end)
end

function SpiritAnimation.Clear(spirit)
	local data = SpiritAnimData[spirit]
	if data and data.conn then
		data.conn:Disconnect()
		data.conn = nil
	end
	SpiritAnimData[spirit] = nil
end

function SpiritAnimation.Place(spirit, targetPos, placeOnGround, getGroundPosition)
	local movementType = spirit:GetAttribute("MovementType") or "Walk"
	if movementType == "Fly" then
		local ground = getGroundPosition(targetPos.X, targetPos.Z, { spirit })
		local hoverY = spirit:GetAttribute("HoverHeight") or SpiritAnimation.ComputeHoverHeight(spirit, ground.Y)
		hoverY = math.clamp(hoverY, MIN_FLY_HOVER, SpiritAnimation.ComputeHoverHeight(spirit, ground.Y))
		local rotation = spirit:GetPivot() - spirit:GetPivot().Position
		spirit:PivotTo(CFrame.new(targetPos.X, ground.Y + hoverY, targetPos.Z) * rotation)
	elseif movementType == "Swim" then
		local waterY = spirit:GetAttribute("SwimWaterY") or targetPos.Y
		local center = spirit:GetAttribute("SwimCenter")
		local radius = spirit:GetAttribute("SwimRadius") or 12
		local x, z = targetPos.X, targetPos.Z
		if typeof(center) == "Vector3" then
			local flat = Vector3.new(x - center.X, 0, z - center.Z)
			if flat.Magnitude > radius then
				flat = flat.Unit * radius
				x = center.X + flat.X
				z = center.Z + flat.Z
			end
		end
		local look = spirit:GetPivot().LookVector
		local flatLook = Vector3.new(look.X, 0, look.Z)
		if flatLook.Magnitude < 0.05 then
			flatLook = Vector3.new(0, 0, -1)
		end
		spirit:PivotTo(CFrame.lookAt(Vector3.new(x, waterY, z), Vector3.new(x, waterY, z) + flatLook.Unit))
	else
		placeOnGround(spirit, targetPos)
	end
	SpiritAnimation.ResetPose(spirit)
end

function SpiritAnimation.MoveStep(spirit, startCF, targetXZ, alpha, placeOnGround, getGroundPosition)
	local movementType = spirit:GetAttribute("MovementType") or "Walk"
	local startPos = startCF.Position
	local endPos = Vector3.new(targetXZ.X, startPos.Y, targetXZ.Z)
	local flatPos = startPos:Lerp(endPos, alpha)
	local moveDir = Vector3.new(endPos.X - startPos.X, 0, endPos.Z - startPos.Z)

	local look = if moveDir.Magnitude > 0.05 then moveDir.Unit else Vector3.new(0, 0, -1)
	local rotation = CFrame.lookAt(Vector3.zero, look, Vector3.yAxis)

	if movementType == "Fly" then
		local ground = getGroundPosition(flatPos.X, flatPos.Z, { spirit })
		local hover = spirit:GetAttribute("HoverHeight") or SpiritAnimation.ComputeHoverHeight(spirit, ground.Y)
		local bob = math.sin(os.clock() * 8) * 0.1
		spirit:PivotTo(CFrame.new(flatPos.X, ground.Y + hover + bob, flatPos.Z) * rotation)
	elseif movementType == "Swim" then
		local waterY = spirit:GetAttribute("SwimWaterY") or startPos.Y
		local bob = math.sin(os.clock() * 6) * 0.08
		spirit:PivotTo(CFrame.new(flatPos.X, waterY + bob, flatPos.Z) * rotation)
	else
		spirit:PivotTo(CFrame.new(flatPos.X, startPos.Y, flatPos.Z) * rotation)
		placeOnGround(spirit, flatPos)
	end
end

return SpiritAnimation
