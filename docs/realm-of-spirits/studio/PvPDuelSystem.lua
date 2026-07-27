-- PvPDuelSystem — fair Arena duel vertical slice (challenge → accept → shared battle UI)
-- Design: characters stay on pads; combat is SPIRIT battle via skill buttons (not melee).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RealmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local SpiritDatabase = require(RealmFolder:WaitForChild("SpiritDatabase"))
local ZoneConfig = require(RealmFolder:WaitForChild("ZoneConfig"))

local BattleOrchestrator = require(script.Parent:WaitForChild("BattleOrchestrator"))
local BuffSystem = require(script.Parent:WaitForChild("BuffSystem"))

local PvPDuelSystem = {}

-- Pads A/B are ~56 studs apart — challenge range must cover rematch on pads.
-- Challenge zone = Arena OR Otaku Haven (fight always teleports to pads).
local ARENA_RADIUS = 130
local ARENA_BBOX_PAD = 30
local HAVEN_BBOX_PAD = 50
local CHALLENGE_FROM_ARENA = 300 -- Haven center ~257 from arena
local MAX_DISTANCE = 80
local WIN_COPPER = 15
local CHALLENGE_TTL = 30
local REMATCH_TTL = 20

local duelEvent = RealmFolder:FindFirstChild("PvPDuel")
if not duelEvent then
	duelEvent = Instance.new("RemoteEvent")
	duelEvent.Name = "PvPDuel"
	duelEvent.Parent = RealmFolder
end

local battleEvent = RealmFolder:FindFirstChild("Battle")

local pending = {}
local rematchPending = {} -- [userId] = rematch session
local byUser = {}
local duels = {}
local nextDuelId = 1
local savedMovement = {} -- [userId] = { WalkSpeed, JumpPower/JumpHeight }

local function getPlayerData(player)
	if _G.GetPlayerData then
		return _G.GetPlayerData(player)
	end
	return nil
end

local function getHRP(player)
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function arenaCenter()
	local pos = ZoneConfig.BattleArenaPosition
	if typeof(pos) == "Vector3" then
		return pos
	end
	return Vector3.new(236, 0, 40)
end

local function nearArena(player)
	local hrp = getHRP(player)
	if not hrp then
		return false
	end
	local arena = workspace:FindFirstChild("BattleArena")
	if arena then
		local cf, size
		local okBox = pcall(function()
			cf, size = arena:GetBoundingBox()
		end)
		if okBox and typeof(cf) == "CFrame" and typeof(size) == "Vector3" then
			local localPos = cf:PointToObjectSpace(hrp.Position)
			if math.abs(localPos.X) <= (size.X * 0.5 + ARENA_BBOX_PAD)
				and math.abs(localPos.Z) <= (size.Z * 0.5 + ARENA_BBOX_PAD) then
				return true
			end
		end
	end
	local c = arenaCenter()
	local flat = Vector3.new(hrp.Position.X - c.X, 0, hrp.Position.Z - c.Z)
	return flat.Magnitude <= ARENA_RADIUS
end

local function nearHaven(player)
	local hrp = getHRP(player)
	if not hrp then
		return false
	end
	local haven = workspace:FindFirstChild("OtakuHaven")
	if not haven then
		return false
	end
	local cf, size
	local okBox = pcall(function()
		cf, size = haven:GetBoundingBox()
	end)
	if not okBox or typeof(cf) ~= "CFrame" or typeof(size) ~= "Vector3" then
		return false
	end
	local localPos = cf:PointToObjectSpace(hrp.Position)
	return math.abs(localPos.X) <= (size.X * 0.5 + HAVEN_BBOX_PAD)
		and math.abs(localPos.Z) <= (size.Z * 0.5 + HAVEN_BBOX_PAD)
end

-- Challenge anywhere in Haven / near arena / along the road corridor.
-- Actual fight still teleports both to SpawnPad A/B.
local function inChallengeZone(player)
	if nearArena(player) or nearHaven(player) then
		return true
	end
	local hrp = getHRP(player)
	if not hrp then
		return false
	end
	local c = arenaCenter()
	local flat = Vector3.new(hrp.Position.X - c.X, 0, hrp.Position.Z - c.Z)
	return flat.Magnitude <= CHALLENGE_FROM_ARENA
end

local function withinRange(a, b)
	local ha, hb = getHRP(a), getHRP(b)
	if not ha or not hb then
		return false
	end
	return (ha.Position - hb.Position).Magnitude <= MAX_DISTANCE
end

local function notify(player, action, payload)
	duelEvent:FireClient(player, action, payload or {})
end

local function toast(player, text)
	notify(player, "Toast", { Message = text })
end

local function clearPendingPair(userA, userB)
	if pending[userA] and pending[userA].PartnerId == userB then
		pending[userA] = nil
	end
	if pending[userB] and pending[userB].PartnerId == userA then
		pending[userB] = nil
	end
end

local function isBusy(player)
	if not player then
		return true
	end
	if byUser[player.UserId] then
		return true
	end
	if pending[player.UserId] then
		return true
	end
	if rematchPending[player.UserId] then
		return true
	end
	if player:GetAttribute("InPvPDuel") then
		return true
	end
	return false
end

function PvPDuelSystem.IsBusy(player)
	return isBusy(player)
end

local function findNearestOpponent(challenger)
	local best, bestDist = nil, MAX_DISTANCE
	local ha = getHRP(challenger)
	if not ha then
		return nil
	end
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= challenger and inChallengeZone(other) and not isBusy(other) then
			local hb = getHRP(other)
			if hb then
				local d = (ha.Position - hb.Position).Magnitude
				if d <= bestDist then
					bestDist = d
					best = other
				end
			end
		end
	end
	return best
end

local function teleportToPad(player, padName)
	local arena = workspace:FindFirstChild("BattleArena")
	local pad = arena and arena:FindFirstChild(padName)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	local pos
	if pad and pad:IsA("BasePart") then
		pos = pad.Position + Vector3.new(0, 3, 0)
	else
		local c = arenaCenter()
		pos = c + (padName == "SpawnPadA" and Vector3.new(-28, 3, 0) or Vector3.new(28, 3, 0))
	end
	hrp.CFrame = CFrame.new(pos)
end

local function facePlayers(a, b)
	local ha, hb = getHRP(a), getHRP(b)
	if not ha or not hb then
		return
	end
	local pa, pb = ha.Position, hb.Position
	ha.CFrame = CFrame.lookAt(pa, Vector3.new(pb.X, pa.Y, pb.Z))
	hb.CFrame = CFrame.lookAt(pb, Vector3.new(pa.X, pb.Y, pa.Z))
end

local function freezePlayer(player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end
	savedMovement[player.UserId] = {
		WalkSpeed = hum.WalkSpeed,
		JumpPower = hum.JumpPower,
		JumpHeight = hum.JumpHeight,
	}
	hum.WalkSpeed = 0
	hum.JumpPower = 0
	pcall(function()
		hum.JumpHeight = 0
	end)
end

local function unfreezePlayer(player)
	local saved = savedMovement[player.UserId]
	savedMovement[player.UserId] = nil
	local char = player and player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or not saved then
		return
	end
	hum.WalkSpeed = saved.WalkSpeed or 16
	hum.JumpPower = saved.JumpPower or 50
	pcall(function()
		hum.JumpHeight = saved.JumpHeight or 7.2
	end)
end

local function teleportToCFrame(player, cf)
	if typeof(cf) ~= "CFrame" then
		return
	end
	local hrp = getHRP(player)
	if hrp then
		hrp.CFrame = cf
	end
end

local function clearRematchPair(userA, userB)
	if rematchPending[userA] then
		rematchPending[userA] = nil
	end
	if rematchPending[userB] then
		rematchPending[userB] = nil
	end
end

local function returnPlayersToOrigin(challenger, target, originA, originB)
	if challenger and challenger.Parent then
		unfreezePlayer(challenger)
		teleportToCFrame(challenger, originA)
		notify(challenger, "ReturnedHome", {})
		toast(challenger, "Возврат на точку вызова")
	end
	if target and target.Parent then
		unfreezePlayer(target)
		teleportToCFrame(target, originB)
		notify(target, "ReturnedHome", {})
		toast(target, "Возврат на точку вызова")
	end
end

local startDuel -- forward: rematch → startDuel

local finishRematch
local offerRematch

finishRematch = function(session, accepted)
	if not session then
		return
	end
	local challenger = Players:GetPlayerByUserId(session.ChallengerId)
	local target = Players:GetPlayerByUserId(session.TargetId)
	clearRematchPair(session.ChallengerId, session.TargetId)
	if accepted and challenger and target then
		toast(challenger, "Реванш принят!")
		toast(target, "Реванш принят!")
		task.defer(function()
			startDuel(challenger, target, {
				A = session.OriginA,
				B = session.OriginB,
			})
		end)
		return
	end
	returnPlayersToOrigin(challenger, target, session.OriginA, session.OriginB)
	if challenger then
		notify(challenger, "RematchClosed", { Accepted = false })
	end
	if target then
		notify(target, "RematchClosed", { Accepted = false })
	end
end

offerRematch = function(challenger, target, originA, originB)
	if not challenger or not target or not challenger.Parent or not target.Parent then
		returnPlayersToOrigin(challenger, target, originA, originB)
		return
	end
	local session = {
		ChallengerId = challenger.UserId,
		TargetId = target.UserId,
		OriginA = originA,
		OriginB = originB,
		Expires = tick() + REMATCH_TTL,
		Answers = {},
	}
	rematchPending[challenger.UserId] = session
	rematchPending[target.UserId] = session
	notify(challenger, "RematchOffer", {
		OpponentName = target.DisplayName,
		OpponentUserId = target.UserId,
		Seconds = REMATCH_TTL,
	})
	notify(target, "RematchOffer", {
		OpponentName = challenger.DisplayName,
		OpponentUserId = challenger.UserId,
		Seconds = REMATCH_TTL,
	})
	toast(challenger, "Реванш? Принять / Отклонить (" .. REMATCH_TTL .. "с)")
	toast(target, "Реванш? Принять / Отклонить (" .. REMATCH_TTL .. "с)")
	local expires = session.Expires
	task.delay(REMATCH_TTL + 0.25, function()
		local still = rematchPending[challenger.UserId]
		if still and still.Expires == expires then
			finishRematch(still, false)
			if challenger.Parent then
				toast(challenger, "Время реванша вышло")
			end
			if target.Parent then
				toast(target, "Время реванша вышло")
			end
		end
	end)
end

local function acceptRematch(player)
	local session = rematchPending[player.UserId]
	if not session then
		toast(player, "Нет предложения реванша")
		return
	end
	session.Answers[player.UserId] = true
	notify(player, "RematchWaiting", {})
	toast(player, "Ждём ответа соперника...")
	local otherId = (player.UserId == session.ChallengerId) and session.TargetId or session.ChallengerId
	if session.Answers[otherId] == true then
		finishRematch(session, true)
	elseif session.Answers[otherId] == false then
		finishRematch(session, false)
	end
end

local function declineRematch(player)
	local session = rematchPending[player.UserId]
	if not session then
		return
	end
	session.Answers[player.UserId] = false
	finishRematch(session, false)
end

local function spiritColor(info)
	local t = info and string.lower(tostring(info.Type or info.Element or ""))
	if t:find("fire") or t:find("огн") then
		return Color3.fromRGB(255, 90, 40)
	end
	if t:find("ice") or t:find("вод") or t:find("water") then
		return Color3.fromRGB(80, 180, 255)
	end
	if t:find("earth") or t:find("зем") then
		return Color3.fromRGB(140, 110, 60)
	end
	if t:find("wind") or t:find("вет") then
		return Color3.fromRGB(160, 255, 180)
	end
	if t:find("dark") or t:find("тем") then
		return Color3.fromRGB(140, 80, 200)
	end
	return Color3.fromRGB(255, 210, 90)
end

local function createSpiritVisual(folder, name, info, position, lookAt)
	local model = Instance.new("Model")
	model.Name = "DuelSpirit_" .. tostring(name):gsub("%s+", "_")

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(5, 5, 5)
	body.Anchored = true
	body.CanCollide = false
	body.Material = Enum.Material.Neon
	body.Color = spiritColor(info)
	body.CFrame = CFrame.lookAt(position, Vector3.new(lookAt.X, position.Y, lookAt.Z))
	body.Parent = model
	model.PrimaryPart = body

	local glow = Instance.new("PointLight")
	glow.Brightness = 2
	glow.Range = 14
	glow.Color = body.Color
	glow.Parent = body

	local bb = Instance.new("BillboardGui")
	bb.Name = "Hud"
	bb.Size = UDim2.new(0, 160, 0, 54)
	bb.StudsOffset = Vector3.new(0, 4.2, 0)
	bb.AlwaysOnTop = true
	bb.Parent = body

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 28)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextStrokeTransparency = 0.4
	title.Text = (info and info.Name) or name
	title.Parent = bb

	local hp = Instance.new("TextLabel")
	hp.Name = "HP"
	hp.Size = UDim2.new(1, 0, 0, 22)
	hp.Position = UDim2.new(0, 0, 0, 28)
	hp.BackgroundTransparency = 1
	hp.Font = Enum.Font.Gotham
	hp.TextSize = 14
	hp.TextColor3 = Color3.fromRGB(180, 255, 180)
	hp.TextStrokeTransparency = 0.5
	hp.Text = "HP —"
	hp.Parent = bb

	model.Parent = folder
	return model
end

local function updateSpiritHud(model, hp, maxHp)
	if not model or not model.Parent then
		return
	end
	local body = model.PrimaryPart or model:FindFirstChild("Body")
	local bb = body and body:FindFirstChild("Hud")
	local label = bb and bb:FindFirstChild("HP")
	if label then
		label.Text = string.format("HP %d/%d", math.max(0, math.floor(hp or 0)), math.max(1, math.floor(maxHp or 1)))
	end
end

local function destroyDuelVisuals(duel)
	if duel and duel.VisualFolder and duel.VisualFolder.Parent then
		duel.VisualFolder:Destroy()
	end
	if duel then
		duel.VisualFolder = nil
		duel.SpiritVisualA = nil
		duel.SpiritVisualB = nil
	end
end

local function setupDuelVisuals(duel, infoA, infoB)
	destroyDuelVisuals(duel)
	local folder = Instance.new("Folder")
	folder.Name = "PvPDuel_" .. tostring(duel.Id)
	folder.Parent = workspace

	local padA = workspace.BattleArena and workspace.BattleArena:FindFirstChild("SpawnPadA")
	local padB = workspace.BattleArena and workspace.BattleArena:FindFirstChild("SpawnPadB")
	local posA = padA and (padA.Position + Vector3.new(10, 4, 0)) or (arenaCenter() + Vector3.new(-18, 4, 0))
	local posB = padB and (padB.Position + Vector3.new(-10, 4, 0)) or (arenaCenter() + Vector3.new(18, 4, 0))

	local banner = Instance.new("Part")
	banner.Name = "DuelBanner"
	banner.Anchored = true
	banner.CanCollide = false
	banner.Transparency = 1
	banner.Size = Vector3.new(1, 1, 1)
	banner.Position = arenaCenter() + Vector3.new(0, 18, 0)
	banner.Parent = folder
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0, 420, 0, 70)
	bb.AlwaysOnTop = true
	bb.Parent = banner
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundColor3 = Color3.fromRGB(20, 14, 30)
	label.BackgroundTransparency = 0.25
	label.Font = Enum.Font.GothamBold
	label.TextSize = 22
	label.TextColor3 = Color3.fromRGB(255, 220, 140)
	label.Text = string.format(
		"ДУЭЛЬ ДУХОВ\n%s  vs  %s",
		duel.Challenger.DisplayName or duel.Challenger.Name,
		duel.Target.DisplayName or duel.Target.Name
	)
	label.Parent = bb
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label

	duel.SpiritVisualA = createSpiritVisual(folder, infoA.Name, infoA, posA, posB)
	duel.SpiritVisualB = createSpiritVisual(folder, infoB.Name, infoB, posB, posA)
	duel.VisualFolder = folder
	updateSpiritHud(duel.SpiritVisualA, duel.Battle.PlayerHP, duel.Battle.PlayerMaxHP)
	updateSpiritHud(duel.SpiritVisualB, duel.Battle.EnemyHP, duel.Battle.EnemyMaxHP)
end

local function pulseSpirit(model)
	if not model or not model.PrimaryPart then
		return
	end
	local part = model.PrimaryPart
	local base = part.Size
	part.Size = base * 1.25
	task.delay(0.15, function()
		if part.Parent then
			part.Size = base
		end
	end)
end

local function buildStateFor(viewer, duel, message)
	local battle = duel.Battle
	local isChallenger = viewer.UserId == duel.Challenger.UserId
	local selfAbilities = isChallenger and battle.PlayerAbilities or battle.EnemyAbilities
	local selfCds = isChallenger and battle.PlayerCooldowns or battle.EnemyCooldowns
	local selfHP = isChallenger and battle.PlayerHP or battle.EnemyHP
	local selfMax = isChallenger and battle.PlayerMaxHP or battle.EnemyMaxHP
	local selfMP = isChallenger and battle.PlayerMP or battle.EnemyMP
	local foeHP = isChallenger and battle.EnemyHP or battle.PlayerHP
	local foeMax = isChallenger and battle.EnemyMaxHP or battle.PlayerMaxHP
	local foeMP = isChallenger and battle.EnemyMP or battle.PlayerMP

	local playerCooldowns = {}
	local playerSkills = {}
	for i, ability in ipairs(selfAbilities or {}) do
		local remaining = (selfCds[i] or 0) - os.clock()
		playerCooldowns[i] = math.max(0, remaining)
		playerSkills[i] = {
			Name = ability.Name,
			Type = ability.Type,
			Cost = ability.Cost or 0,
			Cooldown = playerCooldowns[i],
		}
	end

	local foeName = isChallenger and (battle.EnemyInfo and battle.EnemyInfo.Name) or (battle.SpiritInfo and battle.SpiritInfo.Name)

	return {
		Mode = "PvP",
		PlayerHP = selfHP,
		PlayerMaxHP = selfMax,
		EnemyHP = foeHP,
		EnemyMaxHP = foeMax,
		PlayerMP = math.floor(selfMP),
		PlayerMaxMP = 100,
		EnemyMP = math.floor(foeMP),
		EnemyMaxMP = 100,
		PlayerCooldowns = playerCooldowns,
		PlayerSkills = playerSkills,
		PotionCount = 0,
		PotionCooldown = 0,
		PotionHeal = 0,
		Turn = battle.Turn or 1,
		Message = message or "",
		OpponentName = isChallenger and duel.Target.DisplayName or duel.Challenger.DisplayName,
		EnemyName = foeName,
		IsPvP = true,
	}
end

local function sendBattleUpdate(duel, message)
	if not battleEvent or not duel or not duel.Active then
		return
	end
	if message and message ~= "" then
		duel.Battle.LastMessage = message
	end
	updateSpiritHud(duel.SpiritVisualA, duel.Battle.PlayerHP, duel.Battle.PlayerMaxHP)
	updateSpiritHud(duel.SpiritVisualB, duel.Battle.EnemyHP, duel.Battle.EnemyMaxHP)
	for _, plr in ipairs({ duel.Challenger, duel.Target }) do
		if plr and plr.Parent then
			battleEvent:FireClient(plr, "Update", buildStateFor(plr, duel, duel.Battle.LastMessage or ""))
		end
	end
end

local function endDuel(duel, absoluteWinner, reason)
	if not duel or not duel.Active then
		return
	end
	duel.Active = false
	duel.Battle.Active = false

	local challenger = duel.Challenger
	local target = duel.Target
	local winnerPlr = (absoluteWinner == "Player") and challenger or target
	local loserPlr = (absoluteWinner == "Player") and target or challenger

	byUser[challenger.UserId] = nil
	byUser[target.UserId] = nil
	duels[duel.Id] = nil

	destroyDuelVisuals(duel)

	for _, plr in ipairs({ challenger, target }) do
		if plr then
			plr:SetAttribute("InPvPDuel", nil)
			plr:SetAttribute("BattleEngaged", nil)
			unfreezePlayer(plr)
			if _G.HideBattleBlade then
				_G.HideBattleBlade(plr)
			end
			notify(plr, "DuelEnd", { Reason = reason or "end" })
		end
	end

	local rewards = {}
	if winnerPlr and winnerPlr.Parent then
		local data = getPlayerData(winnerPlr)
		if data then
			data.CopperCoins = (tonumber(data.CopperCoins) or 0) + WIN_COPPER
			rewards.CopperCoins = WIN_COPPER
			local dataEvent = RealmFolder:FindFirstChild("DataSync")
			if dataEvent then
				dataEvent:FireClient(winnerPlr, "FullSync", data)
			end
		end
	end

	if battleEvent then
		if winnerPlr and winnerPlr.Parent then
			battleEvent:FireClient(winnerPlr, "End", {
				Winner = "Player",
				Rewards = rewards,
				Mode = "PvP",
				Reason = reason,
			})
		end
		if loserPlr and loserPlr.Parent then
			battleEvent:FireClient(loserPlr, "End", {
				Winner = "Enemy",
				Rewards = {},
				Mode = "PvP",
				Reason = reason,
			})
		end
	end

	if winnerPlr then
		toast(winnerPlr, "✓ Дуэль духов: победа! +" .. WIN_COPPER .. " 🥉")
	end
	if loserPlr then
		toast(loserPlr, "Дуэль духов: поражение")
	end

	local originA, originB = duel.OriginA, duel.OriginB
	local offer = (reason == "ko" or reason == "flee")
		and challenger
		and target
		and challenger.Parent
		and target.Parent
	if offer then
		offerRematch(challenger, target, originA, originB)
	else
		returnPlayersToOrigin(challenger, target, originA, originB)
	end
	print("[PvPDuel] end", challenger and challenger.Name, "vs", target and target.Name, "winner=", absoluteWinner, reason or "")
end

local function startManaLoop(duel)
	task.spawn(function()
		local tickN = 0
		while duel.Active do
			task.wait(0.35)
			if not duel.Active then
				break
			end
			BattleOrchestrator.RegenMana(duel.Battle, 0.45, 0.45)
			tickN = tickN + 1
			if tickN % 3 == 0 then
				sendBattleUpdate(duel, duel.Battle.LastMessage or "")
			end
		end
	end)
end

startDuel = function(challenger, target, savedOrigins)
	local dataA = getPlayerData(challenger)
	local dataB = getPlayerData(target)
	if not dataA or not dataB then
		toast(challenger, "Данные игрока недоступны")
		toast(target, "Данные игрока недоступны")
		return
	end
	if not dataA.Spirits or #dataA.Spirits == 0 then
		toast(challenger, "Нужен дух для дуэли")
		toast(target, "У соперника нет духа")
		return
	end
	if not dataB.Spirits or #dataB.Spirits == 0 then
		toast(target, "Нужен дух для дуэли")
		toast(challenger, "У соперника нет духа")
		return
	end

	savedOrigins = savedOrigins or {}
	local hrpA, hrpB = getHRP(challenger), getHRP(target)
	local originA = savedOrigins.A or (hrpA and hrpA.CFrame)
	local originB = savedOrigins.B or (hrpB and hrpB.CFrame)

	local spiritA = dataA.Spirits[tonumber(dataA.ActiveSpiritIndex) or 1] or dataA.Spirits[1]
	local spiritB = dataB.Spirits[tonumber(dataB.ActiveSpiritIndex) or 1] or dataB.Spirits[1]
	local infoA = SpiritDatabase.Get(spiritA.Id)
	local infoB = SpiritDatabase.Get(spiritB.Id)
	if not infoA or not infoB then
		toast(challenger, "Ошибка духа")
		return
	end

	local maxA = infoA.BaseStats.HP + (spiritA.Level * 12) + 15 + (spiritA.BonusHP or 0)
	local maxB = infoB.BaseStats.HP + (spiritB.Level * 12) + 15 + (spiritB.BonusHP or 0)

	local battle = {
		Mode = "PvP",
		PlayerSpiritId = spiritA.Id,
		EnemyId = spiritB.Id,
		PlayerHP = maxA,
		PlayerMaxHP = maxA,
		EnemyHP = maxB,
		EnemyMaxHP = maxB,
		PlayerMP = 100,
		EnemyMP = 100,
		Turn = 1,
		Active = true,
		PlayerSpirit = spiritA,
		EnemySpirit = spiritB,
		EnemyInfo = infoB,
		SpiritInfo = infoA,
		PlayerAbilities = BattleOrchestrator.BuildAbilities(infoA, 3),
		PlayerCooldowns = {},
		EnemyAbilities = BattleOrchestrator.BuildAbilities(infoB, 3),
		EnemyCooldowns = {},
		PlayerEffects = BattleOrchestrator.CreateEffectsState(),
		EnemyEffects = BattleOrchestrator.CreateEffectsState(),
		LastMessage = "",
	}

	local id = nextDuelId
	nextDuelId = nextDuelId + 1
	local duel = {
		Id = id,
		Challenger = challenger,
		Target = target,
		Battle = battle,
		Active = true,
		OriginA = originA,
		OriginB = originB,
	}
	duels[id] = duel
	byUser[challenger.UserId] = id
	byUser[target.UserId] = id
	challenger:SetAttribute("InPvPDuel", true)
	target:SetAttribute("InPvPDuel", true)
	challenger:SetAttribute("BattleEngaged", tick())
	target:SetAttribute("BattleEngaged", tick())

	teleportToPad(challenger, "SpawnPadA")
	teleportToPad(target, "SpawnPadB")
	facePlayers(challenger, target)
	freezePlayer(challenger)
	freezePlayer(target)
	setupDuelVisuals(duel, infoA, infoB)

	-- No character blades in spirit duel — visuals are the spirit orbs
	if _G.HideBattleBlade then
		_G.HideBattleBlade(challenger)
		_G.HideBattleBlade(target)
	end

	local msg = "Бой духов! " .. infoA.Name .. " vs " .. infoB.Name .. " — жмите навыки внизу"
	battle.LastMessage = msg
	notify(challenger, "DuelStart", {
		OpponentName = target.DisplayName,
		OpponentUserId = target.UserId,
		SpiritName = infoA.Name,
		EnemySpiritName = infoB.Name,
		Hint = "Персонажи стоят на плитах. Дерутся ДУХИ — кнопки навыков внизу экрана.",
	})
	notify(target, "DuelStart", {
		OpponentName = challenger.DisplayName,
		OpponentUserId = challenger.UserId,
		SpiritName = infoB.Name,
		EnemySpiritName = infoA.Name,
		Hint = "Персонажи стоят на плитах. Дерутся ДУХИ — кнопки навыков внизу экрана.",
	})
	sendBattleUpdate(duel, msg)
	startManaLoop(duel)
	print("[PvPDuel] start", challenger.Name, "vs", target.Name)
end

local function handleAttack(player, data)
	local duelId = byUser[player.UserId]
	local duel = duelId and duels[duelId]
	if not duel or not duel.Active then
		return false
	end

	local side = (player.UserId == duel.Challenger.UserId) and "Player" or "Enemy"
	local skillIndex = (data and tonumber(data.SkillIndex)) or 1
	local playerData = getPlayerData(player)
	local dmgMul = playerData and BuffSystem.GetDamageMultiplier(playerData) or 1
	local result = BattleOrchestrator.ExecuteFairSkill(duel.Battle, side, skillIndex, {
		DamageMultiplier = dmgMul,
	})
	if not result.Ok then
		duel.Battle.LastMessage = result.Message or "Навык недоступен"
		sendBattleUpdate(duel, duel.Battle.LastMessage)
		return true
	end

	if side == "Player" then
		pulseSpirit(duel.SpiritVisualA)
	else
		pulseSpirit(duel.SpiritVisualB)
	end

	if battleEvent then
		battleEvent:FireClient(player, "PlayPlayerAttack", { Mode = "Battle" })
	end

	duel.Battle.LastMessage = result.Message or ""
	if result.Ended then
		sendBattleUpdate(duel, duel.Battle.LastMessage)
		endDuel(duel, result.Winner or "Player", "ko")
	else
		sendBattleUpdate(duel, duel.Battle.LastMessage)
	end
	return true
end

local function handleFlee(player)
	local duelId = byUser[player.UserId]
	local duel = duelId and duels[duelId]
	if not duel or not duel.Active then
		return false
	end
	local absoluteWinner = (player.UserId == duel.Challenger.UserId) and "Enemy" or "Player"
	if battleEvent then
		battleEvent:FireClient(player, "Flee", { Success = true })
	end
	endDuel(duel, absoluteWinner, "flee")
	return true
end

function PvPDuelSystem.HandleBattleAction(player, action, data)
	if not byUser[player.UserId] then
		return false
	end
	if action == "Attack" then
		return handleAttack(player, data)
	end
	if action == "Flee" then
		return handleFlee(player)
	end
	if action == "UsePotion" then
		local duelId = byUser[player.UserId]
		local duel = duelId and duels[duelId]
		if duel then
			sendBattleUpdate(duel, "В дуэли зелья отключены")
			return true
		end
	end
	if action == "Start" then
		toast(player, "Сначала завершите дуэль")
		return true
	end
	return true
end

local function requestChallenge(challenger, targetUserId)
	targetUserId = tonumber(targetUserId)
	if not targetUserId then
		toast(challenger, "Цель не указана")
		return
	end
	local target = Players:GetPlayerByUserId(targetUserId)
	if not target or target == challenger then
		toast(challenger, "Игрок не найден")
		return
	end
	if isBusy(challenger) or isBusy(target) then
		toast(challenger, "Игрок занят (дождитесь конца вызова/дуэли)")
		return
	end
	if not inChallengeZone(challenger) or not inChallengeZone(target) then
		toast(challenger, "Дуэль: у Haven / по дороге / у арены")
		return
	end
	if not withinRange(challenger, target) then
		toast(challenger, "Подойдите ближе к сопернику")
		return
	end
	local dataA = getPlayerData(challenger)
	local dataB = getPlayerData(target)
	if not dataA or not dataA.Spirits or #dataA.Spirits == 0 then
		toast(challenger, "Нужен дух для дуэли")
		return
	end
	if not dataB or not dataB.Spirits or #dataB.Spirits == 0 then
		toast(challenger, "У соперника нет духа")
		return
	end

	local expires = os.clock() + CHALLENGE_TTL
	pending[challenger.UserId] = { PartnerId = target.UserId, Role = "Challenger", ExpiresAt = expires }
	pending[target.UserId] = { PartnerId = challenger.UserId, Role = "Target", ExpiresAt = expires }
	notify(challenger, "ChallengeSent", { TargetName = target.DisplayName, TargetUserId = target.UserId })
	notify(target, "ChallengeIncoming", {
		FromName = challenger.DisplayName,
		FromUserId = challenger.UserId,
		ExpiresIn = CHALLENGE_TTL,
	})
	toast(challenger, "Вызов отправлен: " .. (target.DisplayName or target.Name))
	toast(target, "Входящий вызов на дуэль!")
	print("[PvPDuel] challenge", challenger.Name, "->", target.Name)
end

local function acceptChallenge(player)
	local pend = pending[player.UserId]
	if not pend or pend.Role ~= "Target" then
		toast(player, "Нет входящего вызова")
		return
	end
	if os.clock() > (pend.ExpiresAt or 0) then
		clearPendingPair(player.UserId, pend.PartnerId)
		toast(player, "Вызов истёк")
		return
	end
	local challenger = Players:GetPlayerByUserId(pend.PartnerId)
	if not challenger then
		clearPendingPair(player.UserId, pend.PartnerId)
		toast(player, "Соперник вышел")
		return
	end
	if byUser[challenger.UserId] or byUser[player.UserId] then
		clearPendingPair(player.UserId, challenger.UserId)
		toast(player, "Игрок занят")
		return
	end
	if not inChallengeZone(player) or not inChallengeZone(challenger) then
		toast(player, "Оба должны быть у Haven или арены")
		return
	end
	clearPendingPair(player.UserId, challenger.UserId)
	print("[PvPDuel] accept", player.Name, "vs", challenger.Name)
	startDuel(challenger, player)
end

local function declineChallenge(player)
	local pend = pending[player.UserId]
	if not pend then
		return
	end
	local other = Players:GetPlayerByUserId(pend.PartnerId)
	clearPendingPair(player.UserId, pend.PartnerId)
	toast(player, "Вызов отклонён")
	if other then
		toast(other, (player.DisplayName or player.Name) .. " отклонил дуэль")
		notify(other, "ChallengeDeclined", { Name = player.DisplayName })
	end
end

local function cancelChallenge(player)
	local pend = pending[player.UserId]
	if not pend or pend.Role ~= "Challenger" then
		return
	end
	local other = Players:GetPlayerByUserId(pend.PartnerId)
	clearPendingPair(player.UserId, pend.PartnerId)
	toast(player, "Вызов отменён")
	if other then
		toast(other, "Вызов отменён")
		notify(other, "ChallengeCancelled", {})
	end
end

local function ensureDuelHost()
	local arena = workspace:FindFirstChild("BattleArena")
	if not arena then
		return
	end
	local host = arena:FindFirstChild("PvPDuelHost")
	if host then
		return
	end
	host = Instance.new("Part")
	host.Name = "PvPDuelHost"
	host.Size = Vector3.new(8, 1.2, 8)
	host.Anchored = true
	host.CanCollide = false
	host.Material = Enum.Material.Neon
	host.Color = Color3.fromRGB(255, 200, 80)
	host.CFrame = CFrame.new(arenaCenter() + Vector3.new(0, 1.2, 0))
	host.Parent = arena

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.new(0, 260, 0, 48)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = host
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 18
	label.TextColor3 = Color3.fromRGB(255, 240, 200)
	label.Text = "PvP ДУЭЛЬ ДУХОВ (Y)"
	label.Parent = billboard

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "PvPDuelHostPrompt"
	prompt.ActionText = "Вызвать ближайшего"
	prompt.ObjectText = "Дуэль духов"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 28
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.Y
	prompt.Parent = host
	prompt.Triggered:Connect(function(who)
		if not inChallengeZone(who) then
			toast(who, "Дуэль: у Haven / по дороге / у арены")
			return
		end
		local other = findNearestOpponent(who)
		if not other then
			toast(who, "Рядом нет соперника для дуэли")
			return
		end
		requestChallenge(who, other.UserId)
	end)
end

function PvPDuelSystem.Start()
	if PvPDuelSystem._started then
		return
	end
	PvPDuelSystem._started = true

	_G.PvPDuelHandleBattleAction = PvPDuelSystem.HandleBattleAction
	_G.PvPDuelIsBusy = PvPDuelSystem.IsBusy

	ensureDuelHost()

	duelEvent.OnServerEvent:Connect(function(player, action, data)
		if typeof(action) ~= "string" then
			return
		end
		if action == "Request" then
			requestChallenge(player, data and data.TargetUserId)
		elseif action == "RequestNearest" then
			local other = findNearestOpponent(player)
			if not other then
				toast(player, "Рядом нет соперника для дуэли")
				return
			end
			requestChallenge(player, other.UserId)
		elseif action == "Accept" then
			acceptChallenge(player)
		elseif action == "Decline" then
			declineChallenge(player)
		elseif action == "Cancel" then
			cancelChallenge(player)
		elseif action == "RematchAccept" then
			acceptRematch(player)
		elseif action == "RematchDecline" then
			declineRematch(player)
		end
	end)

	Players.PlayerRemoving:Connect(function(plr)
		unfreezePlayer(plr)
		local rem = rematchPending[plr.UserId]
		if rem then
			finishRematch(rem, false)
		end
		local pend = pending[plr.UserId]
		if pend then
			local other = Players:GetPlayerByUserId(pend.PartnerId)
			clearPendingPair(plr.UserId, pend.PartnerId)
			if other then
				toast(other, "Соперник вышел")
			end
		end
		local duelId = byUser[plr.UserId]
		local duel = duelId and duels[duelId]
		if duel and duel.Active then
			local absoluteWinner = (plr.UserId == duel.Challenger.UserId) and "Enemy" or "Player"
			endDuel(duel, absoluteWinner, "leave")
		end
	end)

	if game:GetService("RunService"):IsStudio() then
		local function bindHelp(plr)
			plr.Chatted:Connect(function(msg)
				local lower = string.lower(msg)
				if lower == "/pvp" then
					toast(plr, "PvP: дуэль ДУХОВ. Плиты = стойка. Навыки внизу. Реванш с плит ок.")
				elseif lower == "/pvpqa" then
					local hrp = getHRP(plr)
					if not hrp then
						return
					end
					-- Haven / у дома — challenge zone; fight still on arena pads
					local haven = workspace:FindFirstChild("OtakuHaven")
					local pos = Vector3.new(-10, 5, 28)
					if haven then
						local ok, cf = pcall(function()
							return haven:GetBoundingBox()
						end)
						if ok and typeof(cf) == "CFrame" then
							pos = cf.Position + Vector3.new(0, 4, 0)
						end
					end
					hrp.CFrame = CFrame.new(pos)
					toast(plr, "QA: у Haven. Y на сопернике → бой на плитах → Реванш/Уйти")
				end
			end)
		end
		Players.PlayerAdded:Connect(bindHelp)
		for _, plr in ipairs(Players:GetPlayers()) do
			bindHelp(plr)
		end
	end

	print("Realm of Spirits - PvPDuelSystem loaded (Arena spirit duel)!")
end

return PvPDuelSystem
