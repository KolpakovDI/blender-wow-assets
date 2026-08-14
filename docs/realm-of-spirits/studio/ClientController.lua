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
local ArenaPortalEvent = realmFolder:WaitForChild("ArenaPortal", 15)
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
	local char = player.Character or character
	if not char or not spiritModel then
		return false
	end
	local root = char.PrimaryPart or char:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	return (root.Position - getSpiritPosition(spiritModel)).Magnitude <= MAX_TARGET_DISTANCE
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

-- Info billboards: hidden by default, flash 1.5s on mouse hover. No permanent markers/pointers.
local HOVER_LABEL_SEC = 1.5
local KEEP_VISIBLE_BB = {
	EntranceTitle = true,
	Emblem = true,
	NeonLabel = true,
	QuestIndicator = true,
	ShowcaseLabel = true,
	ShowcaseToast = true,
	ShowcaseDisplay = true,
	ExitWayfindBillboard = true,
}
local POINTER_INSTANCE_NAMES = {
	QuestTargetMarker = true,
	WayBillboard = true,
	WayMika = true,
	WayManga = true,
	WayExit = true,
	WaySpawnMika = true,
	MangaFloorArrow = true,
	HabitatMarker = true,
}
local hoverLabelToken = 0
local lastHoverLabelKey = ""

local function shouldManageWorldBillboard(bb)
	if not bb:IsA("BillboardGui") then
		return false
	end
	if KEEP_VISIBLE_BB[bb.Name] or bb:GetAttribute("KeepVisible") == true or bb:GetAttribute("HubWayfind") == true or bb.Name == "QuestIndicator" then
		return false
	end
	local p = bb.Parent
	if not p then
		return false
	end
	if p.Name == "DamagePopup" or p.Name == "CatchTrapFX" then
		return false
	end
	if p:FindFirstAncestor("CatchTrapFX") then
		return false
	end
	if bb:FindFirstAncestorOfClass("PlayerGui") then
		return false
	end
	return true
end

local function stripPointersAndMarkers(root)
	root = root or workspace
	for _, d in ipairs(root:GetDescendants()) do
		if POINTER_INSTANCE_NAMES[d.Name] then
			d:Destroy()
		end
	end
end

local function hideAllWorldInfoLabels()
	stripPointersAndMarkers()
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("BillboardGui") and shouldManageWorldBillboard(d) then
			d.Enabled = false
		end
	end
end

local HOVER_STOP_ROOTS = {
	OtakuHaven = true,
	BattleArena = true,
	Akihabara = true,
	SpiritHabitats = true,
	WorldLoot = true,
	Spirits = true,
	Transition = true,
	Coastal = true,
}

local function resolveHoverScope(inst)
	local cur = inst
	local lastModel = nil
	while cur and cur ~= workspace do
		if HOVER_STOP_ROOTS[cur.Name] == true then
			break
		end
		if cur:IsA("Model") then
			lastModel = cur
		end
		cur = cur.Parent
	end
	return lastModel or inst
end

local function collectHoverBillboards(inst)
	local list = {}
	if not inst then
		return list
	end
	local scope = resolveHoverScope(inst)
	local seen = {}
	local function add(bb)
		if bb and shouldManageWorldBillboard(bb) and not seen[bb] then
			seen[bb] = true
			table.insert(list, bb)
		end
	end
	if scope:IsA("BillboardGui") then
		add(scope)
	end
	for _, d in ipairs(scope:GetDescendants()) do
		if d:IsA("BillboardGui") then
			add(d)
		end
	end
	if #list == 0 then
		for _, c in ipairs(inst:GetChildren()) do
			if c:IsA("BillboardGui") then
				add(c)
			end
		end
	end
	return list
end

local function flashHoverLabels(inst)
	local list = collectHoverBillboards(inst)
	if #list == 0 then
		return
	end
	hoverLabelToken += 1
	local token = hoverLabelToken
	for _, bb in ipairs(list) do
		bb.Enabled = true
	end
	task.delay(HOVER_LABEL_SEC, function()
		if token ~= hoverLabelToken then
			return
		end
		for _, bb in ipairs(list) do
			if bb.Parent then
				bb.Enabled = false
			end
		end
	end)
end

local hintClearToken = 0
local function setTargetHint(text, autoClearSec)
	text = text or ""
	player:SetAttribute("TargetHint", text)
	hintClearToken += 1
	local token = hintClearToken
	if text ~= "" and type(autoClearSec) == "number" and autoClearSec > 0 then
		task.delay(autoClearSec, function()
			if token == hintClearToken and player:GetAttribute("TargetHint") == text then
				player:SetAttribute("TargetHint", "")
			end
		end)
	end
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
			setTargetHint(hint, 1.5)
		else
			hint = hint .. "  ·  Подойдите ближе (до " .. MAX_TARGET_DISTANCE .. " studs)"
			setTargetHint(hint, 1.5)
		end
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
	local char = player.Character or character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return false end
	local arena = workspace:FindFirstChild("BattleArena")
	if not arena then return false end
	local portal = arena:FindFirstChild("EntrancePortal", true)
	local exitP = arena:FindFirstChild("ExitPortal", true)
	local function near(p)
		return p and p:IsA("BasePart") and (root.Position - p.Position).Magnitude <= 26
	end
	if near(portal) then return "Enter" end
	if near(exitP) then return "Exit" end
	return false
end

local function getNearestCatchableSpirit()
	local folder = getSpiritsFolder()
	if not folder then return nil end
	local char = player.Character or character
	local root = char and char:FindFirstChild("HumanoidRootPart")
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

local function getTargetSpirit()
	if selectedSpirit and selectedSpirit.Parent and not selectedSpirit:GetAttribute("Dying") and not selectedSpirit:GetAttribute("InteractionLocked") then
		if isWithinRange(selectedSpirit) then return selectedSpirit end
	end
	-- Без клика: ближайший дух в радиусе (E / F / кнопки)
	return getNearestCatchableSpirit()
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
		local portalAction = nearArenaEnterPortal()
		if portalAction then
			if ArenaPortalEvent then
				ArenaPortalEvent:FireServer(portalAction)
			end
			return
		end
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

	-- F/V - Бой с выбранным духом (V = silent MCP alias; Studio VirtualInput blocks F)
	if input.KeyCode == Enum.KeyCode.F or input.KeyCode == Enum.KeyCode.V then
		local target = getTargetSpirit()
		if target and not isInBattle then StartBattle(target) end
	end
end)

-- ============================================
-- Система ловли духов
-- ============================================

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

-- Выхватить меч → лицом к врагу → slash + tween взмах BladeMotor + выпад
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

-- Подсказка + активация кнопки Поймать при приближении (без обязательного клика)
local lastProximityHintKey = ""
RunService.Heartbeat:Connect(function()
	if isInBattle or isCatchPending then
		if player:GetAttribute("CatchUiActive") then
			player:SetAttribute("CatchUiActive", false)
		end
		return
	end
	local target = getTargetSpirit()
	local active = target ~= nil
	if player:GetAttribute("CatchUiActive") ~= active then
		player:SetAttribute("CatchUiActive", active)
	end
	if selectedSpirit and selectedSpirit.Parent then
		-- явный выбор обновляет hint через selectSpirit
		return
	end
	if target then
		local name = getSpiritDisplayName(target)
		local relevant = isSpiritQuestRelevant(getSpiritId(target))
		local canCatch = (_G.GetTrapCount and _G.GetTrapCount() or 0) > 0
		local key = tostring(target) .. tostring(canCatch) .. tostring(relevant)
		if key ~= lastProximityHintKey then
			lastProximityHintKey = key
			local hint = "Рядом: " .. name
			if relevant then hint = hint .. "  [Квест]" end
			if canCatch then
				hint = hint .. "  ·  E — поймать  ·  F — бой"
			else
				hint = hint .. "  ·  нет ловушек  ·  F — бой"
			end
			setTargetHint(hint, 1.5)
			applySelectionVisual(target)
		end
	else
		if lastProximityHintKey ~= "" then
			lastProximityHintKey = ""
			setTargetHint("")
			if not selectedSpirit then
				applySelectionVisual(nil)
			end
		end
	end
end)

RunService.RenderStepped:Connect(function()
	if isInBattle then return end
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

	local worldHit = spirit or mouse.Target
	local hoverKey = ""
	if spirit then
		hoverKey = "S:" .. tostring(spirit)
	elseif worldHit then
		local model = worldHit:FindFirstAncestorOfClass("Model")
		hoverKey = "W:" .. tostring(model or worldHit)
	end
	if hoverKey ~= lastHoverLabelKey then
		lastHoverLabelKey = hoverKey
		if worldHit then
			flashHoverLabels(worldHit)
		end
	end
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
		task.defer(function()
			stripPointersAndMarkers(child)
			local hud = child:FindFirstChild("StatsHUD")
			if hud and hud:IsA("BillboardGui") then
				hud.Enabled = false
			end
		end)
	end)
end)

task.defer(hideAllWorldInfoLabels)
workspace.DescendantAdded:Connect(function(d)
	if POINTER_INSTANCE_NAMES[d.Name] then
		task.defer(function()
			if d.Parent then
				d:Destroy()
			end
		end)
	elseif d:IsA("BillboardGui") and shouldManageWorldBillboard(d) then
		d.Enabled = false
	end
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
	if success then
		print("Ура! Вы поймали: " .. (spiritName or "духа") .. "!")
	else
		print("Не удалось поймать " .. (spiritName or "духа") .. "...")
	end
end)

QuestEvent.OnClientEvent:Connect(function(action, data)
	if action == "ActiveQuests" then
		activeQuests = data.Quests or {}
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

-- Studio play-test: LeftAlt+B (F9 = Developer Console в Studio — не работает)
if RunService:IsStudio() then
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.B and UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) then
			print("[DevBoost] LeftAlt+B → DevBoostIdentity")
			EvolveSpiritEvent:FireServer("DevBoostIdentity", {})
		end
	end)
	EvolveSpiritEvent.OnClientEvent:Connect(function(action, data)
		if action == "DevBoostReady" then
			print(string.format("[DevBoost] Identity ready: lvl=%s wins=%s crystals=%s", tostring(data and data.Level), tostring(data and data.Wins), tostring(data and data.Crystals)))
		end
	end)
end

-- Arena entrance FX: 1.5s approach hint + Spirit Arena banner
do
	local portalHintGui = Instance.new("ScreenGui")
	portalHintGui.Name = "ArenaPortalHint"
	portalHintGui.ResetOnSpawn = false
	portalHintGui.DisplayOrder = 160
	portalHintGui.IgnoreGuiInset = true
	portalHintGui.Parent = player:WaitForChild("PlayerGui")

	local hint = Instance.new("TextLabel")
	hint.Name = "Hint"
	hint.AnchorPoint = Vector2.new(0.5, 0.5)
	hint.Position = UDim2.fromScale(0.5, 0.72)
	hint.Size = UDim2.fromOffset(280, 42)
	hint.BackgroundColor3 = Color3.fromRGB(15, 35, 50)
	hint.BackgroundTransparency = 0.25
	hint.TextColor3 = Color3.fromRGB(120, 255, 230)
	hint.Font = Enum.Font.GothamBold
	hint.TextScaled = true
	hint.Visible = false
	hint.Parent = portalHintGui
	do local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = hint end

	local lastPortal = nil
	local hintToken = 0
	local function flashPortalHint(text)
		hintToken += 1
		local token = hintToken
		hint.Text = text
		hint.Visible = true
		hint.TextTransparency = 0
		hint.BackgroundTransparency = 0.25
		task.delay(1.5, function()
			if token ~= hintToken then return end
			local tw = TweenService:Create(hint, TweenInfo.new(0.35), { TextTransparency = 1, BackgroundTransparency = 1 })
			tw:Play()
			tw.Completed:Connect(function()
				if token == hintToken then hint.Visible = false end
			end)
		end)
	end

	local function bindArenaFX()
		local arena = workspace:FindFirstChild("BattleArena")
		if not arena then return end
		local sign = arena:FindFirstChild("EntranceSign", true)
		local lintel = arena:FindFirstChild("OuterLintel", true)
		if sign and sign:IsA("BasePart") then
			local width = (lintel and lintel.Size.Z) or 30
			local signH = 3.2
			sign.Size = Vector3.new(1.2, signH, width)
			sign.Color = Color3.fromRGB(48, 105, 118)
			sign.Material = Enum.Material.SmoothPlastic
			sign.Reflectance = 0.05
			if lintel and lintel:IsA("BasePart") then
				sign.Position = Vector3.new(
					lintel.Position.X,
					lintel.Position.Y + lintel.Size.Y * 0.5 + signH * 0.5 + 0.6,
					lintel.Position.Z
				)
			end
			for _, d in ipairs(sign:GetDescendants()) do
				if d:IsA("PointLight") or d:IsA("SpotLight") then
					d.Brightness = math.min(d.Brightness, 0.45)
					d.Color = Color3.fromRGB(48, 105, 118)
				end
			end
		end
		local titleBb = arena:FindFirstChild("EntranceTitle", true)
		if titleBb and titleBb:IsA("BillboardGui") then
			local clip = titleBb:FindFirstChild("MarqueeClip")
			local title = titleBb:FindFirstChild("TitleText", true) or titleBb:FindFirstChildWhichIsA("TextLabel", true)
			if clip and title and title:IsDescendantOf(clip) then
				title.Parent = titleBb
				clip:Destroy()
			end
			if title then
				title:SetAttribute("ArenaTitleFXBound", nil)
				title.Rotation = 0
				title.Position = UDim2.fromScale(0, 0)
				title.Size = UDim2.fromScale(1, 1)
				title.AutomaticSize = Enum.AutomaticSize.None
				title.Text = "Spirit Arena"
				title.TextScaled = true
				title.TextColor3 = Color3.fromRGB(210, 235, 240)
				title.Font = Enum.Font.GothamBold
				local grad = title:FindFirstChildOfClass("UIGradient")
				if grad then grad:Destroy() end
			end
			titleBb.StudsOffset = Vector3.new(0, 0, 0)
			local width = (lintel and lintel.Size.Z) or 30
			titleBb.Size = UDim2.fromOffset(math.floor(width * 18), 56)
		end
		for _, portal in ipairs({ arena:FindFirstChild("EntrancePortal", true), arena:FindFirstChild("ExitPortal", true) }) do
			if portal then
				local bb = portal:FindFirstChild("PortalBillboard")
				if bb then bb:Destroy() end
				for _, pr in ipairs(portal:GetChildren()) do
					if pr:IsA("ProximityPrompt") then
						pr.Style = Enum.ProximityPromptStyle.Custom
					end
				end
			end
		end
	end

	bindArenaFX()
	workspace.ChildAdded:Connect(function(ch)
		if ch.Name == "BattleArena" then task.defer(bindArenaFX) end
	end)

	RunService.Heartbeat:Connect(function()
		local action = nearArenaEnterPortal()
		if action and action ~= lastPortal then
			flashPortalHint(if action == "Enter" then "Войти [E]" else "Выйти [E]")
		end
		lastPortal = action or nil
	end)
end

print("Realm of Spirits - Client Controller загружен!")

