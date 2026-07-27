-- CoastWave: clear surf wash for CoastalShowcase (client)
local RunService = game:GetService("RunService")

local entries = {}

local function register(part, kind)
	if not part:IsA("BasePart") then
		return
	end
	local layer = 1
	local m = string.match(part.Name, "_(%d+)$")
	if m then
		layer = tonumber(m) or 1
	end
	table.insert(entries, {
		part = part,
		base = part.CFrame,
		baseSize = part.Size,
		baseT = part.Transparency,
		kind = kind,
		layer = layer,
		-- Shared wave front along coast + slight stagger by X
		phase = part.Position.X * 0.012 + (layer - 1) * 0.55,
	})
end

local function scan()
	table.clear(entries)
	local coast = workspace:FindFirstChild("CoastalShowcase")
	if not coast then
		return
	end
	local foam = coast:FindFirstChild("Foam")
	if foam then
		for _, p in ipairs(foam:GetDescendants()) do
			if p:IsA("BasePart") then
				register(p, "foam")
			end
		end
	end
	local sand = coast:FindFirstChild("Sand")
	if sand then
		for _, p in ipairs(sand:GetChildren()) do
			if p:IsA("BasePart") and string.find(p.Name, "WetSand") then
				register(p, "wet")
			end
		end
	end
	local water = coast:FindFirstChild("WaterVisual")
	if water then
		for _, p in ipairs(water:GetDescendants()) do
			if p:IsA("BasePart") and not string.find(p.Name, "Deep") then
				register(p, "water")
			end
		end
	end
	if #entries == 0 then
		for _, p in ipairs(coast:GetDescendants()) do
			if p:IsA("BasePart") then
				local n = p.Name
				if string.find(n, "Foam") then
					register(p, "foam")
				elseif string.find(n, "WetSand") then
					register(p, "wet")
				elseif string.find(n, "Water") and not string.find(n, "Deep") then
					register(p, "water")
				end
			end
		end
	end
end

local function scanUntilReady()
	for _ = 1, 40 do
		scan()
		if #entries > 0 then
			break
		end
		task.wait(0.25)
	end
	print("Realm of Spirits - CoastWave loaded", #entries)
end

task.spawn(scanUntilReady)
workspace.ChildAdded:Connect(function(c)
	if c.Name == "CoastalShowcase" then
		task.defer(scanUntilReady)
	end
end)

-- Asymmetric surf: rush onto beach, slower pullback
local function surfWave(t, phase)
	local s = math.sin(t * 1.05 + phase)
	local u = (s + 1) * 0.5 -- 0..1
	local rush = u * u
	local pull = (1 - u) * (1 - u)
	-- +1 = onto beach (against Look), smaller = seaward
	return rush * 1.0 - pull * 0.55
end

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for i = #entries, 1, -1 do
		local e = entries[i]
		if not e.part.Parent then
			table.remove(entries, i)
		else
			local w = surfWave(t, e.phase)
			local look = e.base.LookVector
			if e.kind == "foam" then
				local amp = 5.5
				if e.layer == 2 then
					amp = 4.0
				end
				local along = look * (-w * amp)
				local up = Vector3.yAxis * (0.08 + 0.12 * math.max(w, 0))
				e.part.CFrame = e.base + along + up
				local stretch = 1 + 0.85 * math.max(w, 0)
				e.part.Size = Vector3.new(e.baseSize.X, e.baseSize.Y, e.baseSize.Z * stretch)
				e.part.Transparency = math.clamp(e.baseT - 0.22 * math.max(w, 0), 0.05, 0.7)
			elseif e.kind == "wet" then
				local along = look * (-w * 2.2)
				e.part.CFrame = e.base + along
				local stretch = 1 + 0.35 * math.max(w, 0)
				e.part.Size = Vector3.new(e.baseSize.X, e.baseSize.Y, e.baseSize.Z * stretch)
			else -- water
				local along = look * (-w * 1.2)
				local up = Vector3.yAxis * (0.05 * w)
				e.part.CFrame = e.base + along + up
			end
		end
	end
end)
