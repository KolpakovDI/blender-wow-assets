-- ToastRouter: one on-screen alert at a time (UI package A)
-- Priorities: Critical > Reward > Tip. Does not interrupt the visible toast.
-- Client-only. Bind UIController NotificationFrame or use fallback GUI.

local Players = game:GetService("Players")

local ToastRouter = {}

ToastRouter.Priority = {
	Critical = 3,
	Reward = 2,
	Tip = 1,
}

local queue = {}
local showing = false
local boundLabel = nil
local boundFrame = nil
local fallbackGui = nil

local function ensureFallback()
	if boundLabel and boundFrame then
		return boundLabel, boundFrame
	end
	local player = Players.LocalPlayer
	if not player then
		return nil, nil
	end
	local pg = player:FindFirstChildOfClass("PlayerGui")
	if not pg then
		return nil, nil
	end
	if not fallbackGui or not fallbackGui.Parent then
		local gui = Instance.new("ScreenGui")
		gui.Name = "RoS_ToastRouterGui"
		gui.ResetOnSpawn = false
		gui.DisplayOrder = 250
		gui.IgnoreGuiInset = true
		pcall(function()
			gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
		end)
		gui.Parent = pg

		local frame = Instance.new("Frame")
		frame.Name = "ToastFrame"
		frame.AnchorPoint = Vector2.new(0.5, 0)
		-- Below ResonanceActivityBar + NextStepChip top stack
		frame.Position = UDim2.new(0.5, 0, 0, 88)
		frame.Size = UDim2.new(0, 420, 0, 44)
		frame.BackgroundColor3 = Color3.fromRGB(28, 24, 40)
		frame.BackgroundTransparency = 1
		frame.BorderSizePixel = 0
		frame.Visible = false
		frame.Parent = gui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = frame

		local label = Instance.new("TextLabel")
		label.Name = "ToastLabel"
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.GothamBold
		label.TextSize = 16
		label.TextColor3 = Color3.fromRGB(255, 230, 120)
		label.TextStrokeTransparency = 0.35
		label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		label.TextWrapped = true
		label.Parent = frame

		fallbackGui = gui
		boundFrame = frame
		boundLabel = label
	end
	return boundLabel, boundFrame
end

function ToastRouter.Bind(frame, label)
	if fallbackGui and fallbackGui.Parent then
		fallbackGui:Destroy()
	end
	fallbackGui = nil
	-- Drop mid-show state tied to destroyed fallback
	showing = false
	boundFrame = frame
	boundLabel = label
	if boundFrame then
		boundFrame.BackgroundTransparency = 1
	end
	if boundLabel and boundLabel:IsA("TextLabel") then
		boundLabel.BackgroundTransparency = 1
		boundLabel.TextStrokeTransparency = 0.35
		boundLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	end
	task.defer(pump)
end

local function normalizePriority(priority)
	if type(priority) == "number" then
		return priority
	end
	if type(priority) == "string" then
		return ToastRouter.Priority[priority] or ToastRouter.Priority.Tip
	end
	return ToastRouter.Priority.Tip
end

local function enqueue(entry)
	local idx = 1
	while idx <= #queue and queue[idx].priority >= entry.priority do
		idx += 1
	end
	table.insert(queue, idx, entry)
end

local pump

pump = function()
	if showing then
		return
	end
	if #queue == 0 then
		return
	end
	local entry = table.remove(queue, 1)
	local label, frame = ensureFallback()
	if not label or not frame then
		return
	end
	showing = true
	label.Text = entry.text or ""
	if entry.color and label:IsA("TextLabel") then
		label.TextColor3 = entry.color
	end
	frame.Visible = true
	local duration = tonumber(entry.duration) or 3.5
	task.delay(duration, function()
		if frame.Parent then
			frame.Visible = false
		end
		showing = false
		pump()
	end)
end

-- text, durationSeconds?, priority (number|"Critical"|"Reward"|"Tip")?, color?
function ToastRouter.Notify(text, duration, priority, color)
	if type(text) ~= "string" or text == "" then
		return
	end
	enqueue({
		text = text,
		duration = duration,
		priority = normalizePriority(priority),
		color = typeof(color) == "Color3" and color or nil,
	})
	pump()
end

function ToastRouter.Critical(text, duration)
	ToastRouter.Notify(text, duration or 3.5, ToastRouter.Priority.Critical)
end

function ToastRouter.Reward(text, duration)
	ToastRouter.Notify(text, duration or 4, ToastRouter.Priority.Reward)
end

function ToastRouter.Tip(text, duration)
	ToastRouter.Notify(text, duration or 3.5, ToastRouter.Priority.Tip)
end

return ToastRouter
