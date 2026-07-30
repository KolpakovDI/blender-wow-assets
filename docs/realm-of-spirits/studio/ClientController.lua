-- ============================================
-- Realm of Spirits - Client Controller
-- Клиентская логика управления
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local character = player.Character or player.CharacterAdded:Wait()

local realmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local CatchSpiritEvent = realmFolder:WaitForChild("CatchSpirit")
local BattleEvent = realmFolder:WaitForChild("Battle")
local EvolveSpiritEvent = realmFolder:WaitForChild("EvolveSpirit")
local QuestEvent = realmFolder:WaitForChild("Quest")
local DataEvent = realmFolder:WaitForChild("DataSync")
local SpiritDatabaseModule = require(realmFolder:WaitForChild("SpiritDatabase"))

local MAX_TARGET_DISTANCE = 45
local isInBattle = false
local selectedSpirit = nil
local hoveredSpirit = nil
local activeQuests = {}
local caughtSpiritTypeIds = {}
local isPlayerAttackAnimating = false
local isCatchPending = false
local catchRequestId = 0
local suppressBattleUpdates = false

local selectionHighlight = Instance.new("Highlight")
selectionHighlight.Name = "SelectionHighlight"
selectionHighlight.FillTransparency = 0.65
selectionHighlight.OutlineTransparency = 0
selectionHighlight.Enabled = false
selectionHighlight.Parent = workspace

local function getSpiritsFolder()
	return workspace:FindFirstChild("Spirits")
end

local function getSpiritId(spiritModel)
	local v = spiritModel and spiritModel:FindFirstChild("SpiritId")
	return v and v.Value
end

local function getSpiritDisplayName(spiritModel)
	local id = getSpiritId(spiritModel)
	if id then
		local info = SpiritDatabaseModule.GetDisplay(id) or SpiritDatabaseModule.Get(id)
		if info then return info.Name end
	end
	return spiritModel and spiritModel.Name or "Дух"
end

local function ensureSpiritPrimaryPart(spiritModel)
	if spiritModel.PrimaryPart then return spiritModel.PrimaryPart end
	local body = spiritModel:FindFirstChild("body", true)
	if body then
		local geom = body:FindFirstChild("body_geom") or body:FindFirstChildWhichIsA("BasePart")
		if geom then
			spiritModel.PrimaryPart = geom
			return geom
		end
	end
	for _, desc in ipairs(spiritModel:GetDescendants()) do
		if desc:IsA("BasePart") then
			spiritModel.PrimaryPart = desc
			return desc
		end
	end
	return nil
end

local function getSpiritPosition(spiritModel)
	local part = ensureSpiritPrimaryPart(spiritModel)
	if part then return part.Position end
	return spiritModel:GetPivot().Position
end

local function isWithinRange(spiritModel)
	local char = character
	if not char or not char.PrimaryPart or not spiritModel then
		return false
	end
	return (char.PrimaryPart.Position - getSpiritPosition(spiritModel)).Magnitude <= MAX_TARGET_DISTANCE
end

local function isSpiritQuestRelevant(spiritId)
	if not spiritId then return false, nil end
	for _, questData in ipairs(activeQuests) do
		if not questData.ReadyToTurnIn and questData.Quest and questData.Progress then
			for i, objective in ipairs(questData.Quest.Objectives) do
				local progress = questData.Progress[i]
				local current = progress and progress.Current or 0
				local target = progress and progress.Target or objective.Count or 1
				if current < target then
					if objective.Type == "CatchSpirit" then
						return true, "catch"
					elseif objective.Type == "CatchSpecificSpirit" then
						if tonumber(objective.SpiritId) == tonumber(spiritId) then
							return true, "catch_hunt"
						end
					elseif objective.Type == "DefeatEnemies" then
						return true, "defeat"
					elseif objective.Type == "CatchDifferentSpirits" then
						if not caughtSpiritTypeIds[spiritId] then
							return true, "catch_unique"
						end
					end
				end
			end
		end
	end
	return false, nil
end

local function updateQuestMarker(spiritModel)
	if not spiritModel then return end
	local spiritId = getSpiritId(spiritModel)
	local relevant, questKind = isSpiritQuestRelevant(spiritId)
	local marker = spiritModel:FindFirstChild("QuestTargetMarker")
	if relevant then
		if not marker then
			marker = Instance.new("BillboardGui")
			marker.Name = "QuestTargetMarker"
			marker.Size = UDim2.new(0, 36, 0, 36)
			marker.StudsOffset = Vector3.new(0, 3, 0)
			marker.AlwaysOnTop = true
			marker.MaxDistance = 120
			if spiritModel.PrimaryPart then marker.Adornee = spiritModel.PrimaryPart else ensureSpiritPrimaryPart(spiritModel); if spiritModel.PrimaryPart then marker.Adornee = spiritModel.PrimaryPart end end
			marker.Parent = spiritModel
			local lbl = Instance.new("TextLabel")
			lbl.Name = "Icon"
			lbl.Size = UDim2.new(1, 0, 1, 0)
			lbl.BackgroundTransparency = 1
			lbl.Text = "?"
			lbl.TextColor3 = Color3.fromRGB(255, 220, 80)
			lbl.TextStrokeTransparency = 0.3
			lbl.Font = Enum.Font.FredokaOne
			lbl.TextScaled = true
			lbl.Parent = marker
		end
		local icon = marker:FindFirstChild("Icon")
		if icon then
			icon.Text = questKind == "defeat" and "⚔" or "?"
			icon.TextColor3 = questKind == "defeat" and Color3.fromRGB(255, 120, 120) or Color3.fromRGB(255, 220, 80)
		end
		marker.Enabled = true
	elseif marker then
		marker.Enabled = false
	end
end

local function refreshAllQuestMarkers()
	local folder = getSpiritsFolder()
	if not folder then return end
	for _, spirit in ipairs(folder:GetChildren()) do
		if spirit:IsA("Model") then updateQuestMarker(spirit) end
	end
end

local function setTargetHint(text)
	player:SetAttribute("TargetHint", text or "")
end

local function applySelectionVisual(spiritModel)
	if spiritModel then
		selectionHighlight.Adornee = spiritModel
		local spiritId = getSpiritId(spiritModel)
		local questRelevant = isSpiritQuestRelevant(spiritId)
		if questRelevant then
			selectionHighlight.FillColor = Color3.fromRGB(255, 210, 60)
			selectionHighlight.OutlineColor = Color3.fromRGB(255, 180, 0)
		else
			selectionHighlight.FillColor = Color3.fromRGB(90, 170, 255)
			selectionHighlight.OutlineColor = Color3.fromRGB(60, 140, 255)
		end
		selectionHighlight.FillTransparency = 0.65
		selectionHighlight.Enabled = true
	else
		selectionHighlight.Adornee = nil
		selectionHighlight.Enabled = false
	end
end

local function selectSpirit(spiritModel)
	if isInBattle then return end
	selectedSpirit = spiritModel
	applySelectionVisual(selectedSpirit)
	if selectedSpirit then
		local name = getSpiritDisplayName(selectedSpirit)
		local spiritId = getSpiritId(selectedSpirit)
		local relevant = isSpiritQuestRelevant(spiritId)
		local hint = "Выбран: " .. name
		if relevant then hint = hint .. "  [Квест]" end
		if isWithinRange(selectedSpirit) then
			local canCatch = (_G.GetTrapCount and _G.GetTrapCount() or 0) > 0
			if canCatch then
				hint = hint .. "  ·  E — поймать  ·  F — бой"
			else
				hint = hint .. "  ·  E — нет ловушек  ·  F — бой"
			end
		else
			hint = hint .. "  ·  Подойдите ближе (до " .. MAX_TARGET_DISTANCE .. " studs)"
		end
		setTargetHint(hint)
	else
		setTargetHint("")
	end
end

local function getSpiritModelFromInstance(inst)
	if not inst then return nil end
	local folder = getSpiritsFolder()
	if not folder then return nil end
	local model = inst:FindFirstAncestorOfClass("Model")
	if model and model.Parent == folder and not model:GetAttribute("Dying") and not model:GetAttribute("InteractionLocked") then
		return model
	end
	return nil
end

local function getSpiritFromRay(screenPoint)
	local camera = workspace.CurrentCamera
	if not camera then return nil end

	-- 1) Roblox mouse target (надёжнее при GUI поверх экрана)
	local model = getSpiritModelFromInstance(mouse.Target)
	if model then return model end

	-- 2) Raycast с учётом GuiInset
	local inset = GuiService:GetGuiInset()
	local ray = camera:ViewportPointToRay(screenPoint.X - inset.X, screenPoint.Y - inset.Y)
	local folder = getSpiritsFolder()
	if not folder then return nil end

	local include = {}
	for _, spirit in ipairs(folder:GetChildren()) do
		if spirit:IsA("Model") and not spirit:GetAttribute("Dying") and not spirit:GetAttribute("InteractionLocked") then
			for _, desc in ipairs(spirit:GetDescendants()) do
				if desc:IsA("BasePart") and desc.CanQuery then
					table.insert(include, desc)
				end
			end
		end
	end
	if #include == 0 then return nil end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = include
	local result = workspace:Raycast(ray.Origin, ray.Direction * 500, params)
	if not result then return nil end
	return getSpiritModelFromInstance(result.Instance)
end

local function getSpiritFromScreenProximity(screenPoint, maxPixels)
	local camera = workspace.CurrentCamera
	local folder = getSpiritsFolder()
	if not camera or not folder then return nil end
	local inset = GuiService:GetGuiInset()
	local px, py = screenPoint.X - inset.X, screenPoint.Y - inset.Y
	local best, bestDist = nil, maxPixels or 100
	for _, model in ipairs(folder:GetChildren()) do
		if model:IsA("Model") and not model:GetAttribute("Dying") and not model:GetAttribute("InteractionLocked") then
			local pos, onScreen = camera:WorldToViewportPoint(getSpiritPosition(model))
			if onScreen and pos.Z > 0 then
				local dx, dy = pos.X - px, pos.Y - py
				local dist = math.sqrt(dx * dx + dy * dy)
				if dist < bestDist then
					bestDist = dist
					best = model
				end
			end
		end
	end
	return best
end

local function pickSpiritAtMouse()
	local pos = UserInputService:GetMouseLocation()
	return getSpiritFromRay(pos) or getSpiritFromScreenProximity(pos, 90)
end

local function nearArenaEnterPortal()
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return false end
	local arena = workspace:FindFirstChild("BattleArena")
	local portal = arena and arena:FindFirstChild("EntrancePortal", true)
	if not portal or not portal:IsA("BasePart") then return false end
	return (root.Position - portal.Position).Magnitude <= 20
end

local function getTargetSpirit()
	if selectedSpirit and selectedSpirit.Parent and not selectedSpirit:GetAttribute("Dying") and not selectedSpirit:GetAttribute("InteractionLocked") then
		if isWithinRange(selectedSpirit) then return selectedSpirit end
	end
	return nil
end

-- ============================================
-- Управление персонажем
-- ============================================

-- Базовое движение уже встроено в Roblox
-- Мы добавляем дополнительные действия

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- E - Поймать выбранного духа
	if input.KeyCode == Enum.KeyCode.E then
		if nearArenaEnterPortal() then return end
		local target = getTargetSpirit()
		if target then TryCatchSpirit(target) end
	end

	-- Q - Смена духа
	if input.KeyCode == Enum.KeyCode.Q then
		CycleSpirits()
	end

	-- Tab - Меню
	if input.KeyCode == Enum.KeyCode.Tab then
		ToggleMenu()
	end

	-- F - Бой с выбранным духом
	if input.KeyCode == Enum.KeyCode.F then
		local target = getTargetSpirit()
		if target and not isInBattle then StartBattle(target) end
	end
end)

-- ============================================
-- Система ловли духов
-- ============================================

local function getNearestCatchableSpirit()
	local folder = getSpiritsFolder()
	if not folder then return nil end
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	local best, bestDist = nil, MAX_TARGET_DISTANCE
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("Model") and not child:GetAttribute("Dying") and not child:GetAttribute("InteractionLocked") and child:FindFirstChild("SpiritId") then
			local pos = child:GetPivot().Position
			local dist = (Vector3.new(pos.X, root.Position.Y, pos.Z) - root.Position).Magnitude
			if dist <= bestDist then
				bestDist = dist
				best = child
			end
		end
	end
	return best
end

function TryCatchSpirit(spirit)
	if not spirit or isInBattle or isCatchPending then return end
	if (_G.GetTrapCount and _G.GetTrapCount() or 0) <= 0 then
		if _G.ShowNoTrapMessage then _G.ShowNoTrapMessage() end
		if _G.UpdateCatchAvailability then _G.UpdateCatchAvailability() end
		setTargetHint("Нет ловушек — купите у торговца в Haven")
		return
	end
	if not isWithinRange(spirit) then
		setTargetHint("Слишком далеко для поимки!")
		return
	end
	local spiritId = spirit:FindFirstChild("SpiritId")
	if not spiritId then return end
	local instanceId = spirit:GetAttribute("SpiritInstanceId")

	isCatchPending = true
	catchRequestId = catchRequestId + 1
	local requestId = catchRequestId

	if _G.ConsumeLocalTrap then _G.ConsumeLocalTrap() end
	setTargetHint("Бросаем ловушку...")

	-- Сервер ставит ловушку под духа и играет анимацию поимки
	CatchSpiritEvent:FireServer(spiritId.Value, instanceId)

	task.delay(4.5, function()
		if isCatchPending and catchRequestId == requestId then
			isCatchPending = false
			selectSpirit(nil)
			setTargetHint("")
		end
	end)
end

-- ============================================
-- Система битв
-- ============================================

local function GetPlayerSpiritId()
	local idx = tonumber(player:GetAttribute("ActiveSpiritIndex"))
	if idx and idx >= 1 then
		return idx
	end
	return 1
end

local function exitNormalMode()
	isInBattle = false
	isCatchPending = false
	suppressBattleUpdates = true
	selectSpirit(nil)
end

local function computeBladeRestC0(char)
	local hand = char and (char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm"))
	if not hand then
		return CFrame.new(0, -0.1, 0) * CFrame.Angles(math.rad(90), math.rad(90), 0)
	end
	local lower = char:FindFirstChild("RightLowerArm")
	local grip = hand:FindFirstChild("RightGripAttachment")

	local bladeWorld
	if lower then
		local axis = hand.Position - lower.Position
		if axis.Magnitude > 0.05 then
			bladeWorld = axis.Unit
		end
	end
	if not bladeWorld then
		bladeWorld = -hand.CFrame.UpVector
	end

	local localZ = hand.CFrame:VectorToObjectSpace(bladeWorld)
	if localZ.Magnitude < 0.05 then
		localZ = Vector3.new(0, -1, 0)
	else
		localZ = localZ.Unit
	end

	local thumbWorld = hand.CFrame.RightVector
	local localDown = hand.CFrame:VectorToObjectSpace(Vector3.new(0, -1, 0))
	local localX = localDown:Cross(localZ)
	if localX.Magnitude < 0.2 then
		localX = hand.CFrame:VectorToObjectSpace(thumbWorld):Cross(localZ)
	end
	if localX.Magnitude < 0.05 then
		localX = Vector3.new(1, 0, 0)
	else
		localX = localX.Unit
	end
	local localY = localZ:Cross(localX).Unit
	localX = localY:Cross(localZ).Unit

	local pos = grip and grip.Position or Vector3.new(0, -0.08, 0)
	pos = pos + Vector3.new(0, 0.02, 0.02)
	return CFrame.fromMatrix(pos, localX, localY, localZ)
end

local function waitForBladeModel(char, timeoutSec)
	timeoutSec = timeoutSec or 0.7
	local t0 = os.clock()
	while os.clock() - t0 < timeoutSec do
		local model = char:FindFirstChild("RealmBlade")
		if model and model:IsA("Model") then
			local handle = model:FindFirstChild("Handle")
			local motor = handle and handle:FindFirstChild("BladeMotor")
			if motor and motor:IsA("Motor6D") then
				return model, motor
			end
		end
		task.wait()
	end
	return nil, nil
end

local function playSlashAnimation(char, humanoid)
	if not humanoid then
		return nil
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	local anim = Instance.new("Animation")
	if char:FindFirstChild("UpperTorso") then
		anim.AnimationId = "rbxassetid://522635514"
	else
		anim.AnimationId = "rbxassetid://941992724"
	end
	local ok, track = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	if ok and track then
		track.Priority = Enum.AnimationPriority.Action4
		track:Play(0.05, 1, 1.2)
		return track
	end
	return nil
end

local function tweenMotorC0(motor, goalC0, duration)
	local info = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tw = TweenService:Create(motor, info, { C0 = goalC0 })
	tw:Play()
	return tw
end

-- Выхватить меч → лицом к врагу → slash-анимация + взмах BladeMotor + выпад
local function playPlayerAttackAnimation(data)
	data = data or {}
	if isPlayerAttackAnimating then
		return
	end
	local char = player.Character or character
	if not char then
		return
	end
	local root = char:FindFirstChild("HumanoidRootPart")
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not root then
		return
	end

	task.spawn(function()
		isPlayerAttackAnimating = true

		local targetPos = data.TargetPosition
		local forward = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
		if typeof(targetPos) == "Vector3" then
			local flat = Vector3.new(targetPos.X - root.Position.X, 0, targetPos.Z - root.Position.Z)
			if flat.Magnitude > 0.05 then
				forward = flat.Unit
			end
		elseif forward.Magnitude < 0.05 then
			forward = Vector3.new(0, 0, -1)
		else
			forward = forward.Unit
		end

		root.CFrame = CFrame.lookAt(root.Position, root.Position + forward)

		local restC0 = computeBladeRestC0(char)
		local windupC0 = restC0 * CFrame.Angles(math.rad(35), math.rad(-15), math.rad(110))
		local slashC0 = restC0 * CFrame.Angles(math.rad(-110), math.rad(30), math.rad(-55))
		local _, motor = waitForBladeModel(char, 0.8)
		if motor then
			motor.C0 = restC0
		end

		playSlashAnimation(char, humanoid)

		local origin = root.CFrame
		local lungeCF = CFrame.lookAt(origin.Position + forward * 2.0, origin.Position + forward * 6)
		local outTween = TweenService:Create(root, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = lungeCF })
		local backTween = TweenService:Create(root, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = origin })
		outTween:Play()

		if motor then
			local windup = tweenMotorC0(motor, windupC0, 0.1)
			windup.Completed:Wait()
			local slash = tweenMotorC0(motor, slashC0, 0.11)
			slash.Completed:Wait()
			tweenMotorC0(motor, restC0, 0.14)
		else
			task.wait(0.25)
		end

		backTween:Play()
		backTween.Completed:Wait()
		isPlayerAttackAnimating = false
	end)
end

function StartBattle(spirit)
	if not spirit or isInBattle then return end
	suppressBattleUpdates = false
	if not isWithinRange(spirit) then
		setTargetHint("Слишком далеко для боя!")
		return
	end
	local spiritId = spirit:FindFirstChild("SpiritId")
	if not spiritId then return end
	player:SetAttribute("BattleEngaged", tick())
	BattleEvent:FireServer("Start", {
		EnemyId = spiritId.Value,
		PlayerSpiritId = GetPlayerSpiritId(),
		TargetInstanceId = spirit:GetAttribute("SpiritInstanceId"),
	})
end

function EndBattle()
	isInBattle = false
end

-- Слушаем ответы от сервера
BattleEvent.OnClientEvent:Connect(function(action, data)
	if action == "Update" then
		if suppressBattleUpdates then return end
		isInBattle = true
		isCatchPending = false
		local player = Players.LocalPlayer
		player:SetAttribute("BattleUpdate", game:GetService("HttpService"):JSONEncode(data))

	elseif action == "End" then
		exitNormalMode()
		local player = Players.LocalPlayer
		player:SetAttribute("BattleEnd", data.Winner or "Unknown")
		if data.Winner == "Player" then
			print("Вы победили!")
		else
			print("Вы проиграли!")
		end

	elseif action == "Error" then
		exitNormalMode()
		setTargetHint(data.Message or "Ошибка боя")

	elseif action == "Flee" then
		if data.Success then
			exitNormalMode()
			print("Удалось сбежать!")
		else
			print("Не удалось сбежать!")
		end

	elseif action == "PlayPlayerAttack" then
		playPlayerAttackAnimation(data)
	end
end)
-- ============================================

local currentSpiritIndex = 1

function CycleSpirits()
	if isInBattle or isCatchPending then
		return
	end
	EvolveSpiritEvent:FireServer("CycleActiveSpirit", {})
end

-- ============================================
-- Меню
-- ============================================

local menuOpen = false

function ToggleMenu()
	menuOpen = not menuOpen
	-- Здесь будет открытие/закрытие меню
	print("Меню: " .. (menuOpen and "Открыто" or "Закрыто"))
end

-- ============================================
-- Выбор цели мышью
-- ============================================

-- Выбор цели мышью (не блокируем gameProcessed — UI перекрывает весь экран)
local function onMouseSelect()
	if isInBattle then return end
	selectSpirit(pickSpiritAtMouse())
end

mouse.Button1Down:Connect(onMouseSelect)

RunService.RenderStepped:Connect(function()
	if isInBattle then return end
	local pos = UserInputService:GetMouseLocation()
	local spirit = pickSpiritAtMouse()
	if spirit == selectedSpirit then
		applySelectionVisual(selectedSpirit)
	elseif spirit then
		selectionHighlight.Adornee = spirit
		selectionHighlight.FillColor = Color3.fromRGB(180, 180, 220)
		selectionHighlight.OutlineColor = Color3.fromRGB(140, 140, 180)
		selectionHighlight.FillTransparency = 0.85
		selectionHighlight.Enabled = true
	elseif selectedSpirit then
		applySelectionVisual(selectedSpirit)
	else
		selectionHighlight.Enabled = false
		selectionHighlight.Adornee = nil
	end
	hoveredSpirit = spirit
end)

local function onSpiritRemoved(spiritModel)
	if selectedSpirit == spiritModel then
		selectSpirit(nil)
	end
end

task.spawn(function()
	local folder = getSpiritsFolder() or workspace:WaitForChild("Spirits")
	folder.ChildRemoved:Connect(onSpiritRemoved)
	folder.ChildAdded:Connect(function(child)
		task.defer(refreshAllQuestMarkers)
	end)
end)

-- ============================================
-- Инициализация клиента
-- ============================================

player.CharacterAdded:Connect(function(char)
	character = char
	isPlayerAttackAnimating = false
end)

-- ============================================
-- Система эволюции духов
-- ============================================

local pendingEvolution = nil -- {SpiritIndex, CurrentName, EvolveToName, CurrentId, EvolveToId}

EvolveSpiritEvent.OnClientEvent:Connect(function(action, data)
	if action == "CanEvolve" then
		pendingEvolution = data
		print(string.format("[Эволюция] %s может эволюционировать в %s! Нажмите R для эволюции.",
			data.CurrentName, data.EvolveToName))
		-- Уведомляем UI
		local p = Players.LocalPlayer
		p:SetAttribute("EvolveAvailable", true)
		p:SetAttribute("EvolveCurrentName", data.CurrentName)
		p:SetAttribute("EvolveToName", data.EvolveToName)

	elseif action == "EvolveResult" then
		if data.Success then
			print("[Эволюция] " .. data.Message)
			pendingEvolution = nil
			local p = Players.LocalPlayer
			p:SetAttribute("EvolveAvailable", nil)
			p:SetAttribute("EvolveMessage", data.Message)
		else
			print("[Эволюция] Ошибка: " .. (data.Message or "Неизвестно"))
		end

	elseif action == "PlayerStats" then
		local p = Players.LocalPlayer
		p:SetAttribute("PlayerStats", game:GetService("HttpService"):JSONEncode(data))

	elseif action == "SpiritLevelUp" then
		print(string.format("[Эволюция] Дух #%d повысил уровень до %d",
			data.SpiritIndex, data.NewLevel))

	elseif action == "SpiritList" then
		-- Передаём список духов в UI через атрибут
		local p = Players.LocalPlayer
		p:SetAttribute("SpiritListData", game:GetService("HttpService"):JSONEncode(data))

	elseif action == "ActiveSpiritChanged" then
		if data and data.Success ~= false then
			local name = (data.Spirit and data.Spirit.Name) or data.Name or "Дух"
			local idx = data.Index or player:GetAttribute("ActiveSpiritIndex") or 1
			setTargetHint("Активный дух: " .. name .. "  [" .. tostring(idx) .. "]  ·  Q — сменить")
			print("[Дух] Активный: " .. name)
		end
	end
end)

-- Клавиша R — подтвердить эволюцию
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.R then
		if pendingEvolution then
			print("[Эволюция] Отправляем запрос на эволюцию...")
			EvolveSpiritEvent:FireServer("Evolve", {SpiritIndex = pendingEvolution.SpiritIndex})
		end
	end
end)

-- При нажатии Tab — запрашиваем список духов
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.Tab then
		EvolveSpiritEvent:FireServer("GetSpiritList", {})
	end
end)

-- ============================================
-- Обработка запросов от UI кнопок
-- ============================================

player:GetAttributeChangedSignal("BattleEngaged"):Connect(function()
	suppressBattleUpdates = false
end)

player:GetAttributeChangedSignal("BattleRequest"):Connect(function()
	suppressBattleUpdates = false
	local target = getTargetSpirit()
	if target and not isInBattle then StartBattle(target) end
end)

player:GetAttributeChangedSignal("CatchRequest"):Connect(function()
	local target = getTargetSpirit() or getNearestCatchableSpirit()
	if target then
		if selectedSpirit ~= target then
			selectSpirit(target)
		end
		TryCatchSpirit(target)
	else
		setTargetHint("Нет духа рядом для поимки")
	end
end)

CatchSpiritEvent.OnClientEvent:Connect(function(success, spiritName)
	exitNormalMode()
	refreshAllQuestMarkers()
	if success then
		print("Ура! Вы поймали: " .. (spiritName or "духа") .. "!")
	else
		print("Не удалось поймать " .. (spiritName or "духа") .. "...")
	end
end)

QuestEvent.OnClientEvent:Connect(function(action, data)
	if action == "ActiveQuests" then
		activeQuests = data.Quests or {}
		refreshAllQuestMarkers()
		if selectedSpirit then selectSpirit(selectedSpirit) end
	elseif action == "QuestProgress" or action == "QuestAccepted" or action == "QuestCompleted" or action == "OpenQuestUI" then
		QuestEvent:FireServer("GetActiveQuests", {})
	end
end)

DataEvent.OnClientEvent:Connect(function(action, data)
	if action == "FullSync" then
		caughtSpiritTypeIds = {}
		for _, s in ipairs(data.Spirits or {}) do
			caughtSpiritTypeIds[s.Id] = true
		end
		if data.ActiveSpiritIndex then
			player:SetAttribute("ActiveSpiritIndex", data.ActiveSpiritIndex)
		end
		local spirits = data.Spirits or {}
		local idx = tonumber(data.ActiveSpiritIndex) or 1
		if spirits[idx] and spirits[idx].Name then
			player:SetAttribute("ActiveSpiritName", spirits[idx].Name)
		end
		refreshAllQuestMarkers()
	elseif action == "SpiritCaught" then
		exitNormalMode()
		QuestEvent:FireServer("GetActiveQuests", {})
	elseif action == "CatchFailed" then
		exitNormalMode()
		DataEvent:FireServer("RequestFullSync", {})
	elseif action == "Error" then
		exitNormalMode()
		setTargetHint(data and data.Message or "")
		-- Restore traps / inventory after failed optimistic consume
		DataEvent:FireServer("RequestFullSync", {})
	end
end)

task.defer(function()
	QuestEvent:FireServer("GetActiveQuests", {})
	setTargetHint("")
end)

print("Realm of Spirits - Client Controller загружен!")
