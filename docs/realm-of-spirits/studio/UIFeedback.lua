local TweenService = game:GetService("TweenService")

local UIFeedback = {}
local centerFlashFrame
local centerFlashLabel
local centerFlashToken = 0

function UIFeedback.init(screenGui)
	centerFlashFrame = Instance.new("Frame")
	centerFlashFrame.Name = "CenterFlashFrame"
	centerFlashFrame.Size = UDim2.new(0, 440, 0, 72)
	centerFlashFrame.Position = UDim2.new(0.5, -220, 0.45, -36)
	centerFlashFrame.BackgroundColor3 = Color3.fromRGB(20, 12, 35)
	centerFlashFrame.BackgroundTransparency = 0.08
	centerFlashFrame.Visible = false
	centerFlashFrame.ZIndex = 50
	centerFlashFrame.Parent = screenGui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = centerFlashFrame
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 120, 60)
	stroke.Thickness = 2
	stroke.Parent = centerFlashFrame
	centerFlashLabel = Instance.new("TextLabel")
	centerFlashLabel.Name = "CenterFlashLabel"
	centerFlashLabel.Size = UDim2.new(1, 0, 1, 0)
	centerFlashLabel.BackgroundTransparency = 1
	centerFlashLabel.Text = ""
	centerFlashLabel.TextColor3 = Color3.fromRGB(255, 240, 210)
	centerFlashLabel.Font = Enum.Font.GothamBlack
	centerFlashLabel.TextSize = 28
	centerFlashLabel.TextStrokeTransparency = 0.35
	centerFlashLabel.Parent = centerFlashFrame
end

function UIFeedback.showCenter(_text, _duration)
	-- Center flash toasts disabled (UX cleanup 2026-08-28)
end

function UIFeedback.showDamage(popups)
	if type(popups) ~= "table" then return end
	for _, popup in ipairs(popups) do
		local amount = math.floor(tonumber(popup.Amount) or 0)
		local worldPos = popup.Position
		if amount <= 0 or typeof(worldPos) ~= "Vector3" then continue end
		local color = popup.Target == "Player"
			and Color3.fromRGB(190, 25, 35)
			or Color3.fromRGB(255, 255, 255)
		local anchor = Instance.new("Part")
		anchor.Name = "DamagePopup"
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.CanQuery = false
		anchor.CanTouch = false
		anchor.Transparency = 1
		anchor.Size = Vector3.new(0.2, 0.2, 0.2)
		anchor.CFrame = CFrame.new(worldPos)
		anchor.Parent = workspace
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(0, 96, 0, 44)
		bb.AlwaysOnTop = true
		bb.LightInfluence = 0
		bb.Parent = anchor
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.Text = "-" .. tostring(amount)
		lbl.TextColor3 = color
		lbl.Font = Enum.Font.GothamBlack
		lbl.TextScaled = true
		lbl.TextStrokeTransparency = 0.25
		lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
		lbl.Parent = bb
		TweenService:Create(anchor, TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = CFrame.new(worldPos + Vector3.new(0, 2.2, 0)),
		}):Play()
		TweenService:Create(lbl, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, 0, true), {
			TextTransparency = 0.45,
		}):Play()
		task.delay(0.85, function()
			TweenService:Create(lbl, TweenInfo.new(0.35), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end)
		task.delay(1.25, function()
			if anchor.Parent then anchor:Destroy() end
		end)
	end
end

return UIFeedback
