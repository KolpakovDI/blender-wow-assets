-- GuildSystem (Q4 thin): tag + roster only — no bank/warfare
-- Start() from OtakuHavenService / GameManager after DataStore ready

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GuildSystem = {}

local RealmFolder = ReplicatedStorage:WaitForChild("RealmOfSpirits")
local remote = RealmFolder:FindFirstChild("GuildEvent")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "GuildEvent"
	remote.Parent = RealmFolder
end

local membership = {}

local function getData(player)
	local getter = rawget(_G, "GetPlayerData")
	if type(getter) == "function" then
		return getter(player)
	end
	return nil
end

function GuildSystem.GetMembership(player)
	return membership[player.UserId]
end

function GuildSystem.CreateOrJoin(player, guildName, tag)
	guildName = tostring(guildName or ""):sub(1, 24)
	tag = tostring(tag or ""):upper():gsub("[^A-Z0-9]", ""):sub(1, 4)
	if #guildName < 2 or #tag < 2 then
		return false, "Имя (2+) и тег (2–4)"
	end
	local id = "g_" .. string.lower(tag)
	membership[player.UserId] = { Id = id, Name = guildName, Tag = tag }
	player:SetAttribute("GuildTag", tag)
	player:SetAttribute("GuildName", guildName)
	local data = getData(player)
	if data then
		data.Guild = { Id = id, Name = guildName, Tag = tag }
	end
	remote:FireClient(player, "GuildJoined", membership[player.UserId])
	return true, membership[player.UserId]
end

function GuildSystem.Leave(player)
	membership[player.UserId] = nil
	player:SetAttribute("GuildTag", nil)
	player:SetAttribute("GuildName", nil)
	local data = getData(player)
	if data then
		data.Guild = nil
	end
	remote:FireClient(player, "GuildLeft", {})
	return true
end

function GuildSystem.Start()
	if GuildSystem._started then
		return
	end
	GuildSystem._started = true

	remote.OnServerEvent:Connect(function(player, action, payload)
		if typeof(action) ~= "string" then
			return
		end
		payload = type(payload) == "table" and payload or {}
		if action == "CreateOrJoin" then
			local ok, res = GuildSystem.CreateOrJoin(player, payload.Name, payload.Tag)
			if not ok then
				remote:FireClient(player, "Error", { Message = res })
			end
		elseif action == "Leave" then
			GuildSystem.Leave(player)
		elseif action == "Get" then
			remote:FireClient(player, "GuildState", GuildSystem.GetMembership(player) or {})
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		membership[player.UserId] = nil
	end)

	if game:GetService("RunService"):IsStudio() then
		Players.PlayerAdded:Connect(function(plr)
			plr.Chatted:Connect(function(msg)
				local lower = string.lower(msg)
				if string.sub(lower, 1, 6) == "/guild" then
					local tag = string.match(msg, "/guild%s+(%S+)") or "ROS"
					local name = string.match(msg, "/guild%s+%S+%s+(.+)") or "Realm Scouts"
					local ok, err = GuildSystem.CreateOrJoin(plr, name, tag)
					if not ok then
						warn("[Guild]", err)
					end
				elseif lower == "/guildleave" then
					GuildSystem.Leave(plr)
				end
			end)
		end)
	end

	print("Realm of Spirits - GuildSystem thin loaded")
end

return GuildSystem
