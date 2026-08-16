--!strict
-- Studio MCP QA: BindableFunctions share Server DataModel (MCP execute_luau _G is isolated)
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

if not RunService:IsStudio() then
	return
end

local realm = script.Parent

local function ensureBF(name: string): BindableFunction
	local bf = realm:FindFirstChild(name)
	if bf and not bf:IsA("BindableFunction") then
		bf:Destroy()
		bf = nil
	end
	if not bf then
		bf = Instance.new("BindableFunction")
		bf.Name = name
		bf.Parent = realm
	end
	return bf :: BindableFunction
end

local function waitQs()
	local t0 = os.clock()
	while type(_G.GetOrCreateQuestSystem) ~= "function" and os.clock() - t0 < 30 do
		task.wait(0.1)
	end
	return _G.GetOrCreateQuestSystem
end

task.defer(function()
	local getQs = waitQs()
	if type(getQs) ~= "function" then
		warn("[QuestQaBF] GetOrCreateQuestSystem missing")
		return
	end

	local function resolvePlayer(userIdOrPlayer)
		if typeof(userIdOrPlayer) == "Instance" and userIdOrPlayer:IsA("Player") then
			return userIdOrPlayer
		end
		return Players:GetPlayerByUserId(tonumber(userIdOrPlayer) or 0)
	end

	ensureBF("QuestSeedCompletedBF").OnInvoke = function(userId, questIds)
		local player = resolvePlayer(userId)
		if not player then return false, "no player" end
		local qs = getQs(player)
		if type(questIds) ~= "table" then return false, "bad ids" end
		for _, id in ipairs(questIds) do
			local n = tonumber(id) or id
			qs.CompletedQuests[n] = true
			qs.CompletedQuests[tostring(n)] = true
		end
		return true
	end

	ensureBF("QuestAcceptBF").OnInvoke = function(userId, questId)
		local player = resolvePlayer(userId)
		if not player then return false, "no player" end
		local qs = getQs(player)
		return qs:AcceptQuest(tonumber(questId) or questId)
	end

	ensureBF("UpdateQuestProgressBF").OnInvoke = function(userId, progressType, data)
		local player = resolvePlayer(userId)
		if not player then return false, "no player" end
		if type(_G.UpdateQuestProgress) == "function" then
			_G.UpdateQuestProgress(player, progressType, data)
			return true
		end
		return false, "no UpdateQuestProgress"
	end

	ensureBF("QuestProgressBF").OnInvoke = function(userId, questId)
		local player = resolvePlayer(userId)
		if not player then return nil, "no player" end
		local qs = getQs(player)
		local qid = tonumber(questId) or questId
		local prog = qs.QuestProgress[qid] or qs.QuestProgress[tostring(qid)]
		if not prog or not prog[1] then return nil, "no progress" end
		return { Current = prog[1].Current, Target = prog[1].Target, Type = prog[1].Type }
	end

	print("[QuestQaBF] ready")
end)
