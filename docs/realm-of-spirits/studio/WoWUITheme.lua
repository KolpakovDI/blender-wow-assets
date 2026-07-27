-- WoWUITheme - dark fantasy MMO UI helpers (WoW-inspired)
local WoWUITheme = {}

WoWUITheme.Colors = {
	Gold = Color3.fromRGB(212, 175, 55),
	GoldDark = Color3.fromRGB(140, 110, 35),
	Wood = Color3.fromRGB(45, 32, 24),
	WoodLight = Color3.fromRGB(62, 44, 32),
	Stone = Color3.fromRGB(38, 36, 42),
	Parchment = Color3.fromRGB(72, 58, 42),
	ParchmentLight = Color3.fromRGB(110, 90, 62),
	HP = Color3.fromRGB(180, 28, 28),
	HPBright = Color3.fromRGB(220, 60, 45),
	MP = Color3.fromRGB(35, 85, 180),
	MPBright = Color3.fromRGB(55, 120, 220),
	Rune = Color3.fromRGB(80, 200, 255),
	TextGold = Color3.fromRGB(255, 220, 120),
}

-- Optional rbxassetid after upload (empty = procedural)
WoWUITheme.Assets = {
	SkillFrame = "",
	UnitPortrait = "",
	BarHP = "",
	BarMP = "",
	MinimapRing = "",
}

local function addStroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or WoWUITheme.Colors.Gold
	s.Thickness = thickness or 2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function addGradient(parent, c0, c1, rot)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(c0, c1)
	g.Rotation = rot or 90
	g.Parent = parent
	return g
end

function WoWUITheme.StylePanel(frame, variant)
	variant = variant or "wood"
	local c = WoWUITheme.Colors
	frame.BorderSizePixel = 0
	if variant == "parchment" then
		frame.BackgroundColor3 = c.Parchment
		addGradient(frame, c.ParchmentLight, c.Parchment, 90)
	elseif variant == "stone" then
		frame.BackgroundColor3 = c.Stone
	else
		frame.BackgroundColor3 = c.Wood
		addGradient(frame, c.WoodLight, c.Wood, 90)
	end
	addStroke(frame, c.GoldDark, 2)
	local inner = Instance.new("UIStroke")
	inner.Color = c.Gold
	inner.Thickness = 1
	inner.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	inner.Parent = frame
	return frame
end

function WoWUITheme.CreateGem(parent, color, position, size)
	local gem = Instance.new("Frame")
	gem.Name = "Gem"
	gem.Size = size or UDim2.fromOffset(10, 10)
	gem.Position = position or UDim2.new(1, -12, 0.5, -5)
	gem.BackgroundColor3 = color
	gem.BorderSizePixel = 0
	gem.ZIndex = parent.ZIndex + 2
	gem.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 2)
	corner.Parent = gem
	addStroke(gem, WoWUITheme.Colors.Gold, 1)
	return gem
end

function WoWUITheme.CreateResourceBar(parent, name, position, size, fillColor, brightColor)
	local c = WoWUITheme.Colors
	local bar = Instance.new("Frame")
	bar.Name = name
	bar.Position = position
	bar.Size = size
	bar.BackgroundColor3 = c.Stone
	bar.BorderSizePixel = 0
	bar.ClipsDescendants = true
	bar.Parent = parent
	addStroke(bar, c.GoldDark, 2)

	local fill = Instance.new("Frame")
	fill.Name = name .. "Fill"
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = fillColor
	fill.BorderSizePixel = 0
	fill.ZIndex = bar.ZIndex + 1
	fill.Parent = bar
	addGradient(fill, brightColor or fillColor, fillColor, 0)

	WoWUITheme.CreateGem(bar, fillColor)
	return bar, fill
end

function WoWUITheme.CreateSkillSlot(parent, name, position, size, assetId)
	size = size or UDim2.fromOffset(64, 64)
	local slot = Instance.new("Frame")
	slot.Name = name
	slot.Position = position
	slot.Size = size
	slot.BackgroundColor3 = WoWUITheme.Colors.Stone
	slot.BorderSizePixel = 0
	slot.Parent = parent
	WoWUITheme.StylePanel(slot, "stone")

	if assetId and assetId ~= "" then
		local img = Instance.new("ImageLabel")
		img.Size = UDim2.fromScale(1, 1)
		img.BackgroundTransparency = 1
		img.Image = assetId
		img.ScaleType = Enum.ScaleType.Stretch
		img.ZIndex = slot.ZIndex + 1
		img.Parent = slot
	end
	return slot
end

function WoWUITheme.CreatePortraitRing(parent, name, position, size)
	size = size or UDim2.fromOffset(72, 72)
	local ring = Instance.new("Frame")
	ring.Name = name
	ring.Position = position
	ring.Size = size
	ring.BackgroundColor3 = Color3.fromRGB(15, 12, 18)
	ring.BorderSizePixel = 0
	ring.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = ring

	addStroke(ring, WoWUITheme.Colors.Gold, 3)
	local inner = Instance.new("Frame")
	inner.Name = "PortraitInner"
	inner.Size = UDim2.new(1, -8, 1, -8)
	inner.Position = UDim2.fromOffset(4, 4)
	inner.BackgroundColor3 = Color3.fromRGB(25, 20, 30)
	inner.BorderSizePixel = 0
	inner.Parent = ring
	local ic = Instance.new("UICorner")
	ic.CornerRadius = UDim.new(1, 0)
	ic.Parent = inner

	local crown = Instance.new("TextLabel")
	crown.Name = "Ornament"
	crown.Size = UDim2.new(1, 0, 0, 16)
	crown.Position = UDim2.new(0, 0, 0, -10)
	crown.BackgroundTransparency = 1
	crown.Text = "🐉"
	crown.TextSize = 14
	crown.ZIndex = ring.ZIndex + 2
	crown.Parent = ring

	return ring
end

function WoWUITheme.CreateMinimap(parent, name, position, size)
	size = size or UDim2.fromOffset(200, 200)
	local outer = Instance.new("Frame")
	outer.Name = name
	outer.Position = position
	outer.Size = size
	outer.BackgroundTransparency = 1
	outer.Parent = parent

	local ring = Instance.new("Frame")
	ring.Name = "Ring"
	ring.Size = UDim2.fromScale(1, 1)
	ring.BackgroundColor3 = WoWUITheme.Colors.Stone
	ring.BorderSizePixel = 0
	ring.Parent = outer
	local rc = Instance.new("UICorner")
	rc.CornerRadius = UDim.new(1, 0)
	rc.Parent = ring
	addStroke(ring, WoWUITheme.Colors.Gold, 3)

	local map = Instance.new("Frame")
	map.Name = "Container"
	map.Size = UDim2.new(1, -16, 1, -16)
	map.Position = UDim2.fromOffset(8, 8)
	map.BackgroundColor3 = Color3.fromRGB(28, 45, 32)
	map.BorderSizePixel = 0
	map.ClipsDescendants = true
	map.ZIndex = ring.ZIndex + 1
	map.Parent = outer
	local mc = Instance.new("UICorner")
	mc.CornerRadius = UDim.new(1, 0)
	mc.Parent = map

	local rune = Instance.new("TextLabel")
	rune.Size = UDim2.new(1, 0, 0, 18)
	rune.Position = UDim2.new(0, 0, 1, -8)
	rune.BackgroundTransparency = 1
	rune.Text = "✦ ✧ ✦"
	rune.TextColor3 = WoWUITheme.Colors.Rune
	rune.TextSize = 12
	rune.ZIndex = ring.ZIndex + 3
	rune.Parent = outer

	return outer, map
end

function WoWUITheme.StyleActionButton(button)
	WoWUITheme.StylePanel(button, "stone")
	button.AutoButtonColor = true
	local label = button:FindFirstChild("ButtonLabel")
	if label then
		label.TextColor3 = WoWUITheme.Colors.TextGold
	end
	return button
end

return WoWUITheme
