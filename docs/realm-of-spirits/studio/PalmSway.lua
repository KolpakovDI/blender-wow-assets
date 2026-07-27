-- PalmSway: gentle frond wind for CoastalShowcase palms (client visual)
local RunService = game:GetService("RunService")

local entries = {}
local registered = {}

local function getPivot(model)
	if not model then
		return nil
	end
	if model.PrimaryPart and not model.PrimaryPart.Name:match("^Frond_") then
		return model.PrimaryPart
	end
	local named = model:FindFirstChild("Root") or model:FindFirstChild("Trunk")
	if named and named:IsA("BasePart") then
		return named
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and not d.Name:match("^Frond_") then
			return d
		end
	end
	return nil
end

local function registerFrond(part)
	if registered[part] then
		return
	end
	if not part:IsA("BasePart") then
		return
	end
	if not part.Name:match("^Frond_") then
		return
	end
	local model = part:FindFirstAncestorOfClass("Model")
	if not model then
		return
	end
	-- Prefer palm model (may be nested under CoastalShowcase folders)
	local palm = model
	if not (palm.Name:find("Palm") or palm.Name:find("palm")) then
		local anc = model:FindFirstAncestorOfClass("Model")
		if anc and (anc.Name:find("Palm") or anc.Name:find("palm")) then
			palm = anc
		end
	end
	local pivot = getPivot(palm)
	if not pivot or not pivot:IsA("BasePart") or pivot == part then
		-- fallback: any non-frond sibling/ancestor part
		for _, d in ipairs(palm:GetDescendants()) do
			if d:IsA("BasePart") and not d.Name:match("^Frond_") then
				pivot = d
				break
			end
		end
	end
	if not pivot or not pivot:IsA("BasePart") then
		return
	end
	local seed = math.abs(part.Position.X * 12.3 + part.Position.Z * 7.1 + (#part.Name) * 3)
	registered[part] = true
	table.insert(entries, {
		part = part,
		pivot = pivot,
		baseLocal = pivot.CFrame:ToObjectSpace(part.CFrame),
		phase = seed % 6.28318,
		speed = 0.85 + (seed % 10) * 0.04,
		amp = 0.045 + (seed % 7) * 0.006, -- radians ~2.5–5°
	})
end

local function scan()
	table.clear(entries)
	table.clear(registered)
	local coast = workspace:FindFirstChild("CoastalShowcase")
	if not coast then
		return 0
	end
	for _, d in ipairs(coast:GetDescendants()) do
		registerFrond(d)
	end
	return #entries
end

-- Coast may stream in after LocalScript; poll until frond count stabilizes
task.spawn(function()
	local coast = workspace:FindFirstChild("CoastalShowcase") or workspace:WaitForChild("CoastalShowcase", 15)
	if not coast then
		print("Realm of Spirits - PalmSway loaded, fronds= 0 (no CoastalShowcase)")
		return
	end
	local deadline = os.clock() + 15
	local n, last, stable = 0, -1, 0
	while os.clock() < deadline do
		n = scan()
		if n > 0 and n == last then
			stable += 1
			if stable >= 3 or n >= 100 then
				break
			end
		else
			stable = 0
		end
		last = n
		task.wait(0.35)
	end
	print("Realm of Spirits - PalmSway loaded, fronds=", n)
end)

workspace.ChildAdded:Connect(function(child)
	if child.Name == "CoastalShowcase" then
		task.defer(function()
			print("Realm of Spirits - PalmSway rescan, fronds=", scan())
		end)
	end
end)

workspace.DescendantAdded:Connect(function(d)
	if d:IsA("BasePart") and d.Name:match("^Frond_") then
		local coast = d:FindFirstAncestor("CoastalShowcase")
		if coast then
			task.defer(function()
				registerFrond(d)
			end)
		end
	end
end)

-- light rescan (palms rebuilt in Studio)
task.spawn(function()
	while true do
		task.wait(8)
		if workspace:FindFirstChild("CoastalShowcase") and #entries == 0 then
			local n = scan()
			if n > 0 then
				print("Realm of Spirits - PalmSway delayed scan, fronds=", n)
			end
		end
	end
end)

RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for i = #entries, 1, -1 do
		local e = entries[i]
		local part = e.part
		local pivot = e.pivot
		if not part.Parent or not pivot.Parent then
			registered[part] = nil
			table.remove(entries, i)
		else
			local a = math.sin(t * e.speed + e.phase) * e.amp
			local b = math.sin(t * e.speed * 1.37 + e.phase * 1.7) * e.amp * 0.45
			part.CFrame = pivot.CFrame * e.baseLocal * CFrame.Angles(b, a * 0.35, a)
		end
	end
end)
