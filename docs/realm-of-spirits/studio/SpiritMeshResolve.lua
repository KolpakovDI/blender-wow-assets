-- SpiritMeshResolve: template/icon id / offline placeholder for Resonant
-- Prefer exact Id; else first ParentIds with SpiritTemplate; else geometric placeholder.
-- Online AI GenerationService / MeshAssetId: DEFERRED — docs/realm-of-spirits/SPIRIT-AI-MESH.md

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SpiritMeshResolve = {}

local function templatesFolder()
	return ReplicatedStorage:FindFirstChild("SpiritTemplates")
end

local function asIdList(spiritOrId)
	local ids = {}
	if type(spiritOrId) == "table" then
		local main = tonumber(spiritOrId.Id or spiritOrId.SpiritId)
		if main then
			table.insert(ids, main)
		end
		if type(spiritOrId.ParentIds) == "table" then
			for _, pid in ipairs(spiritOrId.ParentIds) do
				local n = tonumber(pid)
				if n then
					table.insert(ids, n)
				end
			end
		end
	else
		local n = tonumber(spiritOrId)
		if n then
			table.insert(ids, n)
		end
	end
	return ids
end

function SpiritMeshResolve.ResolveTemplateId(spiritOrId)
	local folder = templatesFolder()
	if not folder then
		return nil
	end
	for _, id in ipairs(asIdList(spiritOrId)) do
		if folder:FindFirstChild("SpiritTemplate" .. tostring(id)) then
			return id
		end
	end
	return nil
end

function SpiritMeshResolve.FindTemplate(spiritOrId)
	local folder = templatesFolder()
	if not folder then
		return nil, nil
	end
	local id = SpiritMeshResolve.ResolveTemplateId(spiritOrId)
	if not id then
		return nil, nil
	end
	return folder:FindFirstChild("SpiritTemplate" .. tostring(id)), id
end

function SpiritMeshResolve.IconLookupId(spiritOrId)
	return asIdList(spiritOrId)
end

function SpiritMeshResolve.CreatePlaceholder(spiritOrId, displayName)
	local name = displayName
	if type(name) ~= "string" or name == "" then
		if type(spiritOrId) == "table" and type(spiritOrId.Name) == "string" then
			name = spiritOrId.Name
		else
			name = "Ками-форма"
		end
	end

	local model = Instance.new("Model")
	model.Name = name
	model:SetAttribute("IsMeshPlaceholder", true)

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(2.2, 2.2, 2.2)
	root.Anchored = true
	root.CanCollide = false
	root.CanTouch = false
	root.CanQuery = true
	root.Massless = true
	root.Material = Enum.Material.Neon
	root.Color = Color3.fromRGB(180, 140, 255)
	root.CastShadow = false
	root.Parent = model

	local accent = Instance.new("Part")
	accent.Name = "Accent"
	accent.Shape = Enum.PartType.Ball
	accent.Size = Vector3.new(1.1, 1.1, 1.1)
	accent.Anchored = true
	accent.CanCollide = false
	accent.CanTouch = false
	accent.CanQuery = false
	accent.Massless = true
	accent.Material = Enum.Material.Glass
	accent.Color = Color3.fromRGB(255, 220, 140)
	accent.Transparency = 0.35
	accent.CFrame = root.CFrame * CFrame.new(0, 1.4, 0)
	accent.Parent = model

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = accent
	weld.Parent = root

	model.PrimaryPart = root
	return model
end

function SpiritMeshResolve.CloneResolvedModel(spiritOrId, displayName)
	local template, id = SpiritMeshResolve.FindTemplate(spiritOrId)
	if template and template:IsA("Model") then
		local clone = template:Clone()
		clone:SetAttribute("IsMeshPlaceholder", false)
		if id then
			clone:SetAttribute("ResolvedTemplateId", id)
		end
		return clone, id, false
	end
	return SpiritMeshResolve.CreatePlaceholder(spiritOrId, displayName), nil, true
end

return SpiritMeshResolve
